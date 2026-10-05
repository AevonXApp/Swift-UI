//
//  SSHSubTab.swift
//  AevonX
//
//  SSH configuration & login logs management
//  All data fetched from real server via SSH commands
//

import SwiftUI
import AevonXCoreBridge

private struct SSHSessionItem: Identifiable {
    let id: Int; let user: String; let ip: String; let since: String; let pid: String; let tty: String; let isCurrentDevice: Bool
    init(_ i: Int, _ s: (user: String, ip: String, since: String, pid: String, tty: String), currentIP: String) {
        self.id = i; self.user = s.user; self.ip = s.ip; self.since = s.since
        self.pid = s.pid; self.tty = s.tty
        self.isCurrentDevice = !currentIP.isEmpty && s.ip == currentIP
    }
}
#if os(macOS)
import UniformTypeIdentifiers
#endif

// MARK: - Data Models

struct SSHLoginLog: Identifiable {
    let id = UUID()
    let ipPort: String
    let location: String
    let user: String
    let success: Bool
    let timestamp: String
}

// MARK: - View

struct SSHSubTab: View {
    let serverId: String

    @EnvironmentObject var settings: AppSettingsManager
    @State private var sshEnabled = false
    @State private var innerTab: Int = 0
    @State private var passwordLogin = false
    @State private var keyLogin = false
    @State private var sshPort = "22"
    @State private var rootLoginSetting = "yes"
    @State private var logFilter: LogFilter = .all
    @State private var logSearch = ""
    @State private var loginLogs: [SSHLoginLog] = []
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var successCount = 0
    @State private var failedCount = 0
    @State private var todayFailedCount = 0
    // Multi-key listing — replaces the single-publicKey property.
    @State private var serverKeys: [KeygenAuthorizedKey] = []
    @State private var isLoadingServerKeys = false
    @State private var copiedFingerprint: String? = nil
    @State private var showGenerateSheet = false
    @State private var portDetectionMethod: KeygenPortMethod? = nil

    // Phase 2: Authorized Keys Manager
    @State private var authorizedKeys: [String] = []
    @State private var newKeyText = ""
    @State private var isAddingKey = false
    @State private var keyToRemoveIndex: Int? = nil

    // Phase 2: Session Monitor
    @State private var sessions: [(user: String, ip: String, since: String, pid: String, tty: String)] = []
    @State private var isLoadingSessions = false
    @State private var currentSessionIP = ""
    @State private var sessionToKill: SSHSessionItem? = nil
    @State private var isSavingPort = false
    @State private var showPortSavedToast = false
    @State private var showPortChangeWarning = false
    @State private var pendingPort = ""

    private let securityManager = SecurityManager.shared

    private let rootLoginOptions = [
        "yes",
        "without-password",
        "no"
    ]

    enum LogFilter: String, CaseIterable {
        case all = "All"
        case success = "Success"
        case failure = "Failure"
    }

    private var filteredLogs: [SSHLoginLog] {
        loginLogs.filter { log in
            let matchesFilter: Bool = {
                switch logFilter {
                case .all: return true
                case .success: return log.success
                case .failure: return !log.success
                }
            }()
            let matchesSearch = logSearch.isEmpty ||
                log.ipPort.contains(logSearch) ||
                log.user.localizedCaseInsensitiveContains(logSearch)
            return matchesFilter && matchesSearch
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                sshHeaderCard
                innerTabSwitcher

                if innerTab == 0 {
                    basicSetupContent
                } else if innerTab == 1 {
                    loginLogsContent
                } else if innerTab == 2 {
                    authorizedKeysContent
                } else {
                    sessionsContent
                }
            }
            .padding(AXSpacing.xxl)
        }
        .task { await loadSSHData() }
    }

    // MARK: - Load Data

    private func loadSSHData() async {
        isLoading = true
        defer { isLoading = false }

        // SSH Status (from Core)
        let isActive = await securityManager.sshStatus(serverId: serverId)
        await MainActor.run { sshEnabled = isActive }

        // SSH Config (from Core)
        let config = await securityManager.sshConfig(serverId: serverId)
        await MainActor.run {
            sshPort = config.port
            passwordLogin = (config.passwordAuth == "yes")
            keyLogin = (config.pubkeyAuth == "yes")
            rootLoginSetting = config.permitRootLogin
        }

        // SSH Stats (from Core)
        let stats = await securityManager.sshLoginStats(serverId: serverId)
        await MainActor.run {
            successCount = stats.success
            failedCount = stats.failed
            todayFailedCount = stats.todayFailed
        }

        // Login logs
        await refreshLogs()
    }

    private func parseSSHConfig(_ raw: String) {
        for line in raw.components(separatedBy: "\n") {
            let parts = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
            guard parts.count >= 2 else { continue }
            let key = parts[0]
            let value = parts[1]
            switch key {
            case "Port": sshPort = value
            case "PasswordAuthentication": passwordLogin = (value == "yes")
            case "PubkeyAuthentication": keyLogin = (value == "yes")
            case "PermitRootLogin": rootLoginSetting = value
            default: break
            }
        }
    }

    private func parseSSHStats(_ raw: String) {
        for line in raw.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("success:") {
                successCount = Int(trimmed.replacingOccurrences(of: "success:", with: "")) ?? 0
            } else if trimmed.hasPrefix("failed:") {
                failedCount = Int(trimmed.replacingOccurrences(of: "failed:", with: "")) ?? 0
            } else if trimmed.hasPrefix("today_failed:") {
                todayFailedCount = Int(trimmed.replacingOccurrences(of: "today_failed:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }
    }

    private func refreshLogs() async {
        isRefreshing = true
        defer { Task { @MainActor in isRefreshing = false } }

        let logLines = await securityManager.sshLoginLogs(count: 100, serverId: serverId)
        await MainActor.run {
            loginLogs = parseLoginLogs(logLines)
        }
    }

    private func parseLoginLogs(_ lines: [String]) -> [SSHLoginLog] {
        var logs: [SSHLoginLog] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let isSuccess = trimmed.contains("Accepted")
            let isFailed = trimmed.contains("Failed")
            guard isSuccess || isFailed else { continue }

            // Extract IP and port
            var ip = "unknown"
            var port = ""
            if let fromRange = trimmed.range(of: "from ") {
                let afterFrom = String(trimmed[fromRange.upperBound...])
                let parts = afterFrom.components(separatedBy: " ")
                if parts.count >= 1 { ip = parts[0] }
                if parts.count >= 3, parts[1] == "port" { port = parts[2] }
            }

            // Extract user
            var user = "unknown"
            if let forRange = trimmed.range(of: "for ") {
                let afterFor = String(trimmed[forRange.upperBound...])
                let parts = afterFor.components(separatedBy: " ")
                if let u = parts.first { user = u }
            }

            // Extract timestamp (first 15 chars of syslog format)
            let timestamp = String(trimmed.prefix(15))

            logs.append(SSHLoginLog(
                ipPort: port.isEmpty ? ip : "\(ip):\(port)",
                location: "",
                user: user,
                success: isSuccess,
                timestamp: timestamp
            ))
        }
        return logs.reversed()
    }

    // MARK: - Header Card

    private var sshHeaderCard: some View {
        AXCard {
            HStack {
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(sshEnabled ? .axAccentBlue : .axTextMuted)

                    Text(L10n.Security.sshService)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        HStack(spacing: AXSpacing.xs) {
                            Circle()
                                .fill(sshEnabled ? Color.axSuccess : Color.axError)
                                .frame(width: 7, height: 7)
                                .shadow(color: sshEnabled ? .axSuccess.opacity(0.5) : .clear, radius: 3)
                            Text(sshEnabled ? L10n.Status.active : L10n.Status.inactive)
                                .font(AXTypography.caption)
                                .foregroundColor(sshEnabled ? .axSuccess : .axError)
                        }
                    }
                }

                Spacer()

                // Stats from real data
                if !isLoading {
                    HStack(spacing: AXSpacing.xl) {
                        VStack(alignment: .center, spacing: AXSpacing.xxxs) {
                            Text(formatNumber(successCount))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.axSuccess)
                            Text(L10n.Security.totalSuccess)
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                        }

                        Divider().frame(height: 30)

                        VStack(alignment: .center, spacing: AXSpacing.xxxs) {
                            Text(formatNumber(failedCount))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.axError)
                            Text(L10n.Security.totalFailed)
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                        }

                        Divider().frame(height: 30)

                        VStack(alignment: .center, spacing: AXSpacing.xxxs) {
                            Text(formatNumber(todayFailedCount))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.axWarning)
                            Text(L10n.Security.todayFailed)
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Inner Tab Switcher

    private var innerTabSwitcher: some View {
        AXTabSwitcher(
            labels: ["Basic Setup", "Login Logs", "Keys", "Sessions"],
            selected: $innerTab
        )
    }

    // MARK: - Basic Setup

    private var basicSetupContent: some View {
        VStack(spacing: AXSpacing.lg) {
            // Authentication
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    AXSectionTitle(title: "Authentication", icon: "key.fill")
                    Divider().background(Color.axBorder)

                    HStack {
                        toggleRow(icon: "lock.fill", label: "SSH Password Login", isOn: $passwordLogin, color: .axAccentBlue) {
                            Task {
                                let _ = await securityManager.setSSHPasswordAuth(enabled: passwordLogin, serverId: serverId)
                            }
                        }
                        Spacer()
                        toggleRow(icon: "key.horizontal", label: "SSH Key Login", isOn: $keyLogin, color: .axAccentGreen) {
                            Task {
                                let _ = await securityManager.setSSHKeyAuth(enabled: keyLogin, serverId: serverId)
                            }
                        }
                        Spacer()
                    }
                }
            }

            // SSH Port
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    AXSectionTitle(title: "SSH Port", icon: "number")
                    Divider().background(Color.axBorder)

                    HStack(spacing: AXSpacing.md) {
                        TextField("22", text: $sshPort)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .frame(width: 80)
                            .padding(AXSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(Color.axBackgroundTertiary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                            )
                            .onChange(of: sshPort) { _, newValue in
                                sshPort = newValue.filter { $0.isASCII && $0.isNumber }
                            }

                        Button(action: {
                            pendingPort = sshPort
                            showPortChangeWarning = true
                        }) {
                            HStack(spacing: AXSpacing.xs) {
                                if isSavingPort {
                                    ProgressView().scaleEffect(0.7)
                                }
                                Text(L10n.Button.save)
                                    .font(AXTypography.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(isSavingPort ? Color.axTextMuted : Color.axAccentGreen)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isSavingPort)

                        if showPortSavedToast {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.axSuccess)
                                Text(L10n.Security.portUpdatedSshRestarting)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axSuccess)
                            }
                            .transition(.opacity)
                        } else {
                            Text(L10n.Security.defaultPortIsChangingItWillRestartSshAndMayDisconnectYou)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                    }
                }
            }
            .alert("Change SSH Port?", isPresented: $showPortChangeWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Change Port", role: .destructive) {
                    Task { await applySSHPort() }
                }
            } message: {
                Text("This will change the SSH port to \(pendingPort) and restart the SSH service.\n\nThe new port will be automatically opened in the firewall. Your current connection will be interrupted.\n\nMake sure you can reconnect on port \(pendingPort) before proceeding.")
            }

            // Root Login
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    AXSectionTitle(title: "Root Login Settings", icon: "person.badge.shield.checkmark")
                    Divider().background(Color.axBorder)

                    HStack(spacing: AXSpacing.md) {
                        Picker("Root Login", selection: $rootLoginSetting) {
                            ForEach(rootLoginOptions, id: \.self) { option in
                                Text(rootLoginLabel(option)).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 300)

                        Button(action: {
                            Task {
                                let _ = await securityManager.setSSHRootLogin(mode: rootLoginSetting, serverId: serverId)
                            }
                        }) {
                            Text(L10n.Button.apply)
                                .font(AXTypography.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .fill(Color.axAccentBlue)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            // SSH Key Management — multi-key listing
            sshKeyManagementCard
        }
        .task { await loadServerKeys() }
        .sheet(isPresented: $showGenerateSheet) {
            GenerateSSHKeySheet(
                serverId: serverId,
                username: usernameForKeyOps,
                onCompleted: {
                    Task {
                        await loadServerKeys()
                        await loadSSHData()
                    }
                }
            )
        }
    }

    // MARK: - SSH Key Management Card

    private var sshKeyManagementCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                HStack {
                    AXSectionTitle(title: "SSH Key Management", icon: "key.horizontal.fill")
                    Spacer()
                    Button {
                        showGenerateSheet = true
                    } label: {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .semibold))
                            Text(L10n.Security.generateNewKey)
                                .font(AXTypography.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(Color.axAccentBlue)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        Task { await loadServerKeys() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.axTextMuted)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }

                Divider().background(Color.axBorder)

                if isLoadingServerKeys && serverKeys.isEmpty {
                    HStack(spacing: AXSpacing.sm) {
                        ProgressView().scaleEffect(0.6)
                        Text("Loading keys…")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.lg)
                } else if serverKeys.isEmpty {
                    emptyKeysState
                } else {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(serverKeys) { key in
                            sshKeyRow(key)
                        }
                    }
                }
            }
        }
    }

    private var emptyKeysState: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "key.slash")
                    .foregroundColor(.axTextMuted)
                Text(L10n.Security.noSshKeyPairFound)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
            }
            Text("Generate a new key pair locally — the public half is injected into authorized_keys, the private half stays in the Keychain.")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
    }

    private func sshKeyRow(_ key: KeygenAuthorizedKey) -> some View {
        let isCopied = copiedFingerprint == key.fingerprint
        return HStack(alignment: .top, spacing: AXSpacing.md) {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(key.displayAlgorithm)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.axAccentPurple)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Capsule().fill(Color.axAccentPurple.opacity(0.12)))

                    Text(key.suggestedFilename)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.axTextPrimary)

                    if key.isAuthorizedEntry {
                        Text("authorized_keys")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextMuted)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Capsule().fill(Color.axTextMuted.opacity(0.12)))
                    }
                }

                Text(key.publicKey)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if !key.fingerprint.isEmpty {
                    Text(key.fingerprint)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if !key.comment.isEmpty {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 9))
                            .foregroundColor(.axTextMuted)
                        Text(key.comment)
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }

            Spacer(minLength: AXSpacing.sm)

            HStack(spacing: AXSpacing.xs) {
                Button {
                    copyKey(key)
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(isCopied ? "Copied" : "Copy")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(isCopied ? Color.axSuccess : Color.axAccentBlue)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    downloadKey(key.publicKey, suggestedName: key.suggestedFilename)
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 10))
                        Text(L10n.Dashboard.download)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(Color.axAccentGreen)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axBackgroundTertiary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder.opacity(0.6), lineWidth: 1)
                )
        )
    }

    // MARK: - Server Keys Loading

    private func loadServerKeys() async {
        isLoadingServerKeys = true
        defer { Task { @MainActor in isLoadingServerKeys = false } }

        let cmd = KeygenBridge.shared.listAllKeysCmd(home: homeForCurrentUser)
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsed = KeygenBridge.shared.parseAllKeys(output: output)
        await MainActor.run {
            serverKeys = parsed
        }
    }

    private func copyKey(_ key: KeygenAuthorizedKey) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(key.publicKey, forType: .string)
        #endif
        copiedFingerprint = key.fingerprint
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedFingerprint == key.fingerprint {
                copiedFingerprint = nil
            }
        }
    }

    private var homeForCurrentUser: String {
        // The Security view always operates as root via the existing
        // SSH session. If that ever changes, fetch the username from the
        // server registry instead.
        "/root"
    }

    /// Username to use for new-key injection in the Generate sheet.
    /// Currently mirrors `homeForCurrentUser` — root.
    private var usernameForKeyOps: String { "root" }

    // MARK: - Login Logs

    private var loginLogsContent: some View {
        VStack(spacing: AXSpacing.lg) {
            // Filter bar
            HStack(spacing: AXSpacing.md) {
                AXRefreshButton(label: L10n.Button.refresh, isLoading: isRefreshing) {
                    await refreshLogs()
                }

                Spacer()

                // Filter buttons
                HStack(spacing: 0) {
                    ForEach(LogFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { logFilter = filter }
                        }) {
                            Text(filter.rawValue)
                                .font(AXTypography.caption)
                                .foregroundColor(logFilter == filter ? .axTextPrimary : .axTextMuted)
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, AXSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .fill(logFilter == filter ? Color.axAccentBlue.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                )

                // Search
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextMuted)

                    TextField("Search IP or user…", text: $logSearch)
                        .font(AXTypography.body)
                        .textFieldStyle(.plain)
                        .frame(width: 150)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                )
            }

            // Logs table
            AXDataTable(
                title: "Login Logs",
                icon: "doc.text.fill",
                accentColor: .axAccentBlue,
                badgeText: "\(filteredLogs.count) entries",
                columns: [
                    AXDataColumn(title: "IP:Port", width: 200),
                    AXDataColumn(title: "User", width: 120),
                    AXDataColumn(title: "Status", width: 120),
                    AXDataColumn(title: "Time", width: nil),
                ],
                items: filteredLogs,
                totalCount: loginLogs.count,
                pageSize: 50,
                isLoading: isLoading,
                emptyIcon: "doc.text",
                emptyTitle: isLoading ? "Loading logs..." : "No login logs found"
            ) { log, _ in
                HStack(spacing: 0) {
                    Text(log.ipPort)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 200, alignment: .leading)

                    Text(log.user)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                        .frame(width: 120, alignment: .leading)

                    HStack(spacing: AXSpacing.xxs) {
                        Circle()
                            .fill(log.success ? Color.axSuccess : Color.axError)
                            .frame(width: 5, height: 5)
                        Text(log.success ? "Success" : "Login failure")
                            .font(AXTypography.caption)
                            .foregroundColor(log.success ? .axSuccess : .axError)
                    }
                    .frame(width: 120, alignment: .leading)

                    Text(log.timestamp)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Authorized Keys Content (Phase 2)

    private var authorizedKeysContent: some View {
        VStack(spacing: AXSpacing.lg) {
            // Add key card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    AXSectionTitle(title: "Add Authorized Key", icon: "key.horizontal.fill")
                    Divider().background(Color.axBorder)

                    Text(L10n.Security.pasteAPublicSshKeyEGSshEd25519AaaaUserHost)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)

                    HStack(spacing: AXSpacing.md) {
                        TextField("ssh-ed25519 AAAA...", text: $newKeyText)
                            .font(.system(size: 12, design: .monospaced))
                            .textFieldStyle(.plain)
                            .padding(AXSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(Color.axBackgroundTertiary.opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                                    )
                            )

                        Button(action: {
                            guard !newKeyText.isEmpty else { return }
                            Task {
                                isAddingKey = true
                                let _ = await securityManager.addAuthorizedKey(key: newKeyText, serverId: serverId)
                                await MainActor.run { newKeyText = "" }
                                isAddingKey = false
                                await loadAuthorizedKeys()
                            }
                        }) {
                            HStack(spacing: AXSpacing.xxs) {
                                if isAddingKey {
                                    ProgressView().scaleEffect(0.6)
                                } else {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                Text(L10n.Security.addKey)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(newKeyText.isEmpty ? Color.axTextMuted : Color.axAccentGreen)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(newKeyText.isEmpty || isAddingKey)
                    }
                }
            }

            // Keys list
            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    HStack {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 14))
                                .foregroundColor(.axAccentBlue)
                            Text(L10n.Security.authorizedKeys)
                                .font(AXTypography.title3)
                                .foregroundColor(.axTextPrimary)
                        }
                        Spacer()
                        Text("\(authorizedKeys.count) keys")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Capsule().fill(Color.axAccentBlue))

                        Button(action: { Task { await loadAuthorizedKeys() } }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                                .foregroundColor(.axTextMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(AXSpacing.lg)

                    Divider().background(Color.axBorder)

                    if authorizedKeys.isEmpty {
                        VStack(spacing: AXSpacing.md) {
                            Image(systemName: "key.slash")
                                .font(.system(size: 28))
                                .foregroundColor(.axTextMuted)
                            Text(L10n.Security.noAuthorizedKeysFound)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.xxxl)
                    } else {
                        ForEach(Array(authorizedKeys.enumerated()), id: \.offset) { index, key in
                            let parts = key.components(separatedBy: " ")
                            let keyType = parts.first ?? "unknown"
                            let keyComment = parts.count >= 3 ? parts.dropFirst(2).joined(separator: " ") : "—"
                            let fingerprint = String(parts.count >= 2 ? String(parts[1].prefix(20)) + "…" : "—")

                            HStack(spacing: AXSpacing.md) {
                                Image(systemName: "key.horizontal")
                                    .font(.system(size: 11))
                                    .foregroundColor(.axAccentBlue)

                                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                                    Text(keyComment)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.axTextPrimary)
                                        .lineLimit(1)
                                    HStack(spacing: AXSpacing.sm) {
                                        Text(keyType)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.axAccentPurple)
                                        Text(fingerprint)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.axTextMuted)
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    if settings.shouldConfirm(for: SettingsKey.confirmDeleteSSHKey) {
                                        keyToRemoveIndex = index
                                    } else {
                                        Task {
                                            let _ = await securityManager.removeAuthorizedKey(index: index, serverId: serverId)
                                            await loadAuthorizedKeys()
                                        }
                                    }
                                }) {
                                    HStack(spacing: AXSpacing.xxs) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 10))
                                        Text(L10n.Button.remove)
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(.axError)
                                    .padding(.horizontal, AXSpacing.sm)
                                    .padding(.vertical, AXSpacing.xxxs)
                                    .background(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                            .fill(Color.axError.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                                    .stroke(Color.axError.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                        }
                    }
                }
            }
        }
        .task { await loadAuthorizedKeys() }
        .overlay {
            if let idx = keyToRemoveIndex {
                AXDeleteConfirmation(
                    title: "Remove Key",
                    itemName: "Authorized Key #\(idx)",
                    icon: "key.slash",
                    warning: "The associated user will lose SSH access.",
                    confirmLabel: "Remove",
                    onConfirm: {
                        keyToRemoveIndex = nil
                        Task {
                            let _ = await securityManager.removeAuthorizedKey(index: idx, serverId: serverId)
                            await loadAuthorizedKeys()
                        }
                    },
                    onCancel: { keyToRemoveIndex = nil }
                )
            }
        }
    }

    private func loadAuthorizedKeys() async {
        let keys = await securityManager.readAuthorizedKeys(serverId: serverId)
        await MainActor.run { authorizedKeys = keys }
    }

    // MARK: - Sessions Content (Phase 2)

    private var sessionsContent: some View {
        let sessionItems = sessions.enumerated().map { SSHSessionItem($0.offset, $0.element, currentIP: currentSessionIP) }
        return AXDataTable(
            title: "Active SSH Sessions",
            icon: "person.3.fill",
            accentColor: sessions.isEmpty ? .axSuccess : .axAccentBlue,
            badgeText: "\(sessions.count) active",
            columns: [
                AXDataColumn(title: "User", width: 120),
                AXDataColumn(title: "IP Address", width: nil),
                AXDataColumn(title: "Since", width: 140),
                AXDataColumn(title: "PID", width: 80),
                AXDataColumn(title: "Action", width: 120, alignment: .center),
            ],
            items: sessionItems,
            isLoading: isLoadingSessions,
            emptyIcon: "person.crop.circle.badge.xmark",
            emptyTitle: "No active SSH sessions"
        ) { item, _ in
            HStack(spacing: 0) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: item.isCurrentDevice ? "laptopcomputer" : "person.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(item.isCurrentDevice ? .axAccentGreen : .axAccentBlue)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.user)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axTextPrimary)
                        if item.isCurrentDevice {
                            Text(L10n.Security.thisDevice)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.axAccentGreen)
                        }
                    }
                }
                .frame(width: 120, alignment: .leading)

                Text(item.ip)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(item.isCurrentDevice ? .axAccentGreen : .axTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.since)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
                    .frame(width: 140, alignment: .leading)

                Text(item.pid)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .frame(width: 80, alignment: .leading)

                Group {
                    if item.isCurrentDevice {
                        Text(L10n.Security.current)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.axAccentGreen)
                    } else {
                        AXActionButton(label: "Kill", icon: "xmark.circle", style: .destructive, size: .small) {
                            sessionToKill = item
                        }
                    }
                }
                .frame(width: 120, alignment: .center)
            }
        } trailingContent: {
            AXRefreshButton(isLoading: isLoadingSessions) {
                await loadSessions()
            }
        }
        .task { await loadSessions() }
        .alert("Kill Session?", isPresented: Binding(
            get: { sessionToKill != nil },
            set: { if !$0 { sessionToKill = nil } }
        )) {
            Button("Cancel", role: .cancel) { sessionToKill = nil }
            Button("Kill Session", role: .destructive) {
                guard let session = sessionToKill else { return }
                sessionToKill = nil
                Task {
                    let _ = await securityManager.killSessionByPID(pid: session.pid, serverId: serverId)
                    await loadSessions()
                }
            }
        } message: {
            if let s = sessionToKill {
                Text("Terminate SSH session for user '\(s.user)' from \(s.ip) (PID: \(s.pid))? This will disconnect that session immediately.")
            }
        }
    }

    private func loadSessions() async {
        isLoadingSessions = true
        defer { Task { @MainActor in isLoadingSessions = false } }
        async let sessionsResult = securityManager.activeSessions(serverId: serverId)
        async let ipResult = securityManager.currentSessionIP(serverId: serverId)
        let results = await sessionsResult
        let ip = await ipResult
        await MainActor.run {
            sessions = results
            currentSessionIP = ip
        }
    }

    private func applySSHPort() async {
        isSavingPort = true
        let success = await securityManager.setSSHPort(port: pendingPort, serverId: serverId)
        isSavingPort = false
        if success {
            withAnimation { showPortSavedToast = true }
            try? await Task.sleep(for: .seconds(4))
            withAnimation { showPortSavedToast = false }
        }
    }

    // MARK: - Helpers

    private func toggleRow(icon: String, label: String, isOn: Binding<Bool>, color: Color, onChange: @escaping () -> Void) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isOn.wrappedValue ? color : .axTextMuted)

            Text(label)
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)

            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
                .labelsHidden()
                .frame(width: 40)
                .onChange(of: isOn.wrappedValue) { _, _ in
                    onChange()
                }
        }
    }

    private func rootLoginLabel(_ value: String) -> String {
        switch value {
        case "yes": return "yes — keys and passwords"
        case "without-password": return "without-password — keys only"
        case "no": return "no — disabled"
        default: return value
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func downloadKey(_ key: String, suggestedName: String) {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [.plainText]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? key.write(to: url, atomically: true, encoding: .utf8)
            }
        }
        #endif
    }
}
