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
    let id: Int; let user: String; let ip: String; let since: String
    init(_ i: Int, _ s: (user: String, ip: String, since: String)) {
        self.id = i; self.user = s.user; self.ip = s.ip; self.since = s.since
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
    @State private var publicKey: String? = nil
    @State private var isGeneratingKey = false
    @State private var showKeyCopied = false
    @State private var showKeySheet = false

    // Phase 2: Authorized Keys Manager
    @State private var authorizedKeys: [String] = []
    @State private var newKeyText = ""
    @State private var isAddingKey = false
    @State private var keyToRemoveIndex: Int? = nil

    // Phase 2: Session Monitor
    @State private var sessions: [(user: String, ip: String, since: String)] = []
    @State private var isLoadingSessions = false

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

        // Public key (from Core)
        let key = await securityManager.readSSHPublicKey(serverId: serverId)
        await MainActor.run { publicKey = key }

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

                    Text("SSH Service")
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
                            Text(sshEnabled ? "Active" : "Inactive")
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
                            Text("Total Success")
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                        }

                        Divider().frame(height: 30)

                        VStack(alignment: .center, spacing: AXSpacing.xxxs) {
                            Text(formatNumber(failedCount))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.axError)
                            Text("Total Failed")
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                        }

                        Divider().frame(height: 30)

                        VStack(alignment: .center, spacing: AXSpacing.xxxs) {
                            Text(formatNumber(todayFailedCount))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.axWarning)
                            Text("Today Failed")
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
                            Task {
                                let _ = await securityManager.setSSHPort(port: sshPort, serverId: serverId)
                            }
                        }) {
                            Text("Save")
                                .font(AXTypography.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .fill(Color.axAccentGreen)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("Default port is 22. Changing it requires updating client configs.")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }
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
                            Text("Apply")
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

            // SSH Key Management
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    AXSectionTitle(title: "SSH Key Management", icon: "key.horizontal.fill")
                    Divider().background(Color.axBorder)

                    if let key = publicKey {
                        // Key exists
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.axSuccess)
                                Text("SSH key pair exists")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axSuccess)
                            }

                            // Public key display
                            Text(key)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axTextSecondary)
                                .padding(AXSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .fill(Color.axBackgroundTertiary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .stroke(Color.axBorder, lineWidth: 1)
                                        )
                                )
                                .lineLimit(3)

                            HStack(spacing: AXSpacing.md) {
                                Button(action: {
                                    #if os(macOS)
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(key, forType: .string)
                                    #endif
                                    showKeyCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showKeyCopied = false
                                    }
                                }) {
                                    HStack(spacing: AXSpacing.xs) {
                                        Image(systemName: showKeyCopied ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 11))
                                        Text(showKeyCopied ? "Copied!" : "Copy Public Key")
                                            .font(AXTypography.headline)
                                    }
                                    .padding(.horizontal, AXSpacing.lg)
                                    .padding(.vertical, AXSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .fill(Color.axAccentBlue)
                                    )
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Button(action: {
                                    downloadKey(key)
                                }) {
                                    HStack(spacing: AXSpacing.xs) {
                                        Image(systemName: "arrow.down.circle")
                                            .font(.system(size: 11))
                                        Text("Download Key")
                                            .font(AXTypography.headline)
                                    }
                                    .padding(.horizontal, AXSpacing.lg)
                                    .padding(.vertical, AXSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .fill(Color.axAccentGreen)
                                    )
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    } else {
                        // No key
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.axWarning)
                                Text("No SSH key pair found")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                            }

                            Text("Generate a new ED25519 SSH key pair to enable key-based authentication.")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)

                            Button(action: {
                                Task { await generateKey() }
                            }) {
                                HStack(spacing: AXSpacing.xs) {
                                    if isGeneratingKey {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "key.fill")
                                            .font(.system(size: 11))
                                    }
                                    Text(isGeneratingKey ? "Generating..." : "Generate SSH Key Pair")
                                        .font(AXTypography.headline)
                                }
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .fill(isGeneratingKey ? Color.axTextMuted : Color.axAccentBlue)
                                )
                                .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isGeneratingKey)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Login Logs

    private var loginLogsContent: some View {
        VStack(spacing: AXSpacing.lg) {
            // Filter bar
            HStack(spacing: AXSpacing.md) {
                AXRefreshButton(label: "Refresh", isLoading: isRefreshing) {
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

                    Text("Paste a public SSH key (e.g. ssh-ed25519 AAAA... user@host)")
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
                                Text("Add Key")
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
                            Text("Authorized Keys")
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
                            Text("No authorized keys found")
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

                                Button(action: { keyToRemoveIndex = index }) {
                                    HStack(spacing: AXSpacing.xxs) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 10))
                                        Text("Remove")
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
        .alert("Remove Key", isPresented: Binding(
            get: { keyToRemoveIndex != nil },
            set: { if !$0 { keyToRemoveIndex = nil } }
        )) {
            Button("Cancel", role: .cancel) { keyToRemoveIndex = nil }
            Button("Remove", role: .destructive) {
                if let idx = keyToRemoveIndex {
                    Task {
                        let _ = await securityManager.removeAuthorizedKey(index: idx, serverId: serverId)
                        await loadAuthorizedKeys()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to remove this authorized key? The associated user will lose SSH access.")
        }
    }

    private func loadAuthorizedKeys() async {
        let keys = await securityManager.readAuthorizedKeys(serverId: serverId)
        await MainActor.run { authorizedKeys = keys }
    }

    // MARK: - Sessions Content (Phase 2)

    private var sessionsContent: some View {
        AXDataTable(
            title: "Active SSH Sessions",
            icon: "person.3.fill",
            accentColor: sessions.isEmpty ? .axSuccess : .axAccentBlue,
            badgeText: "\(sessions.count) active",
            columns: [
                AXDataColumn(title: "User", width: 120),
                AXDataColumn(title: "IP Address", width: nil),
                AXDataColumn(title: "Since", width: 140),
                AXDataColumn(title: "Action", width: 100, alignment: .center),
            ],
            items: sessions.enumerated().map { SSHSessionItem($0.offset, $0.element) },
            isLoading: isLoadingSessions,
            emptyIcon: "person.crop.circle.badge.xmark",
            emptyTitle: "No active SSH sessions"
        ) { item, _ in
            HStack(spacing: 0) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.axAccentBlue)
                    Text(item.user)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                }
                .frame(width: 120, alignment: .leading)

                Text(item.ip)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.since)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
                    .frame(width: 140, alignment: .leading)

                AXActionButton(label: "Kill", icon: "xmark.circle", style: .destructive, size: .small) {
                    Task {
                        let _ = await securityManager.killSession(user: item.user, serverId: serverId)
                        await loadSessions()
                    }
                }
                .frame(width: 100, alignment: .center)
            }
        } trailingContent: {
            AXRefreshButton(isLoading: isLoadingSessions) {
                await loadSessions()
            }
        }
        .task { await loadSessions() }
    }

    private func loadSessions() async {
        isLoadingSessions = true
        defer { Task { @MainActor in isLoadingSessions = false } }
        let results = await securityManager.activeSessions(serverId: serverId)
        await MainActor.run { sessions = results }
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

    private func generateKey() async {
        isGeneratingKey = true
        defer { Task { @MainActor in isGeneratingKey = false } }

        let key = await securityManager.generateSSHKey(serverId: serverId)
        if let key = key {
            await MainActor.run { publicKey = key }
        }
    }

    private func downloadKey(_ key: String) {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "id_ed25519.pub"
        panel.allowedContentTypes = [.plainText]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? key.write(to: url, atomically: true, encoding: .utf8)
            }
        }
        #endif
    }
}
