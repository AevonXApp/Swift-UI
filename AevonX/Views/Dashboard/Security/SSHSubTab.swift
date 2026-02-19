//
//  SSHSubTab.swift
//  AevonX
//
//  SSH configuration & login logs management
//  All data fetched from real server via SSH commands
//

import SwiftUI
import AevonXCore
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

    private let sshService = SSHService.shared

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
                } else {
                    loginLogsContent
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

        // SSH Status
        if let result = try? await sshService.execute(
            CommandTemplate.security(.sshStatus).build(), serverId: serverId
        ) {
            await MainActor.run {
                sshEnabled = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "active"
            }
        }

        // SSH Config
        if let result = try? await sshService.execute(
            CommandTemplate.security(.sshConfig).build(), serverId: serverId
        ) {
            await MainActor.run {
                parseSSHConfig(result.stdout)
            }
        }

        // SSH Stats
        if let result = try? await sshService.execute(
            CommandTemplate.security(.sshLoginStats).build(), serverId: serverId
        ) {
            await MainActor.run {
                parseSSHStats(result.stdout)
            }
        }

        // Public key
        if let result = try? await sshService.execute(
            CommandTemplate.security(.readSSHPublicKey).build(), serverId: serverId
        ) {
            await MainActor.run {
                let key = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                publicKey = key == "no-key" ? nil : key
            }
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

        if let result = try? await sshService.execute(
            CommandTemplate.security(.sshLoginLogs(count: 100)).build(), serverId: serverId
        ) {
            await MainActor.run {
                loginLogs = parseLoginLogs(result.stdout)
            }
        }
    }

    private func parseLoginLogs(_ raw: String) -> [SSHLoginLog] {
        guard raw != "no-logs" else { return [] }
        var logs: [SSHLoginLog] = []
        for line in raw.components(separatedBy: "\n") {
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
        HStack(spacing: 0) {
            ForEach(["Basic Setup", "SSH Login Logs"], id: \.self) { tab in
                let index = tab == "Basic Setup" ? 0 : 1
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { innerTab = index }
                }) {
                    Text(tab)
                        .font(AXTypography.headline)
                        .foregroundColor(innerTab == index ? .axTextPrimary : .axTextMuted)
                        .padding(.horizontal, AXSpacing.xl)
                        .padding(.vertical, AXSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(innerTab == index ? Color.axSurface : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(innerTab == index ? Color.axBorder : Color.clear, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()
        }
    }

    // MARK: - Basic Setup

    private var basicSetupContent: some View {
        VStack(spacing: AXSpacing.lg) {
            // Authentication
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    sectionHeader(icon: "key.fill", title: "Authentication")
                    Divider().background(Color.axBorder)

                    HStack {
                        toggleRow(icon: "lock.fill", label: "SSH Password Login", isOn: $passwordLogin, color: .axAccentBlue) {
                            Task {
                                let cmd = CommandTemplate.security(.setSSHPasswordAuth(enabled: passwordLogin))
                                _ = try? await sshService.execute(cmd.build(), serverId: serverId)
                            }
                        }
                        Spacer()
                        toggleRow(icon: "key.horizontal", label: "SSH Key Login", isOn: $keyLogin, color: .axAccentGreen) {
                            Task {
                                let cmd = CommandTemplate.security(.setSSHKeyAuth(enabled: keyLogin))
                                _ = try? await sshService.execute(cmd.build(), serverId: serverId)
                            }
                        }
                        Spacer()
                    }
                }
            }

            // SSH Port
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    sectionHeader(icon: "number", title: "SSH Port")
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
                                let cmd = CommandTemplate.security(.setSSHPort(port: sshPort))
                                _ = try? await sshService.execute(cmd.build(), serverId: serverId)
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
                    sectionHeader(icon: "person.badge.shield.checkmark", title: "Root Login Settings")
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
                                let cmd = CommandTemplate.security(.setSSHRootLogin(mode: rootLoginSetting))
                                _ = try? await sshService.execute(cmd.build(), serverId: serverId)
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
                    sectionHeader(icon: "key.horizontal.fill", title: "SSH Key Management")
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
                Button(action: {
                    Task { await refreshLogs() }
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                        }
                        Text("Refresh")
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
            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("IP:Port")
                            .frame(width: 200, alignment: .leading)
                        Text("User")
                            .frame(width: 120, alignment: .leading)
                        Text("Status")
                            .frame(width: 120, alignment: .leading)
                        Text("Time")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
                    .background(Color.axBackgroundTertiary.opacity(0.5))

                    Divider().background(Color.axBorder)

                    if filteredLogs.isEmpty {
                        VStack(spacing: AXSpacing.md) {
                            Image(systemName: isLoading ? "hourglass" : "doc.text")
                                .font(.system(size: 28))
                                .foregroundColor(.axTextMuted)
                            Text(isLoading ? "Loading logs..." : "No login logs found")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.xxxxl)
                    } else {
                        ForEach(Array(filteredLogs.enumerated()), id: \.element.id) { index, log in
                            VStack(spacing: 0) {
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
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))

                                if index < filteredLogs.count - 1 {
                                    Divider().background(Color.axBorder.opacity(0.3))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.axAccentBlue)
            Text(title)
                .font(AXTypography.title3)
                .foregroundColor(.axTextPrimary)
        }
    }

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

        if let result = try? await sshService.execute(
            CommandTemplate.security(.generateSSHKey).build(), serverId: serverId
        ) {
            let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed != "FAILED" {
                await MainActor.run {
                    publicKey = trimmed
                }
            }
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
