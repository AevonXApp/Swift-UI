//
//  NodeJSDetailView.swift
//  AevonX
//
//  Full detail view for Node.js application management
//  Supports PM2 process control, version management, environment vars
//

import SwiftUI
import AevonXCore

@MainActor
struct NodeJSDetailView: View {
    let application: ApplicationInstance
    let serverId: String
    let onBack: (() -> Void)?

    init(application: ApplicationInstance, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.serverId = serverId
        self.onBack = onBack
    }

    @State private var selectedSection: NodeJSSection = .overview
    @State private var isLoading = true

    // Data
    @State private var nodeVersion: String?
    @State private var npmVersion: String?
    @State private var hasNvm = false
    @State private var hasPM2 = false
    @State private var processes: [PM2Process] = []
    @State private var installedVersions: [String] = []
    @State private var availableVersions: [String] = []
    @State private var packageJSON: PackageJSON?
    @State private var envVariables: [EnvironmentVariable] = []

    // Services
    private let versionService = NodeJSVersionService()
    private let processService = NodeJSProcessService()
    private let configService = NodeJSConfigService()

    // Step installer for versions AND tools (PM2/NVM)
    @StateObject private var installerVM = AXStepInstallerViewModel(steps: [])
    @State private var installerTitle: String = ""
    @State private var showVersionInstaller = false
    @State private var showToolInstaller = false

    var body: some View {
        ServiceDetailContainer(
            application: application,
            brandColor: Color(hex: "#339933"),
            iconName: "server.rack",
            selectedSection: $selectedSection,
            sections: NodeJSSection.allCases.map { $0 },
            isLoading: isLoading,
            loadingMessage: "Syncing Node.js Data…",
            onBack: onBack,
            onControl: { action in
                Task { await controlService(action: action) }
            }
        ) {
            contentForSection
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Content Router

    @ViewBuilder
    private var contentForSection: some View {
        switch selectedSection {
        case .overview:
            overviewSection
        case .processes:
            processesSection
        case .packages:
            packagesSection
        case .environment:
            environmentSection
        case .versions:
            versionsSection
        case .logs:
            logsSection
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(spacing: AXSpacing.lg) {
            // Tool Installer (PM2 / NVM)
            if showToolInstaller {
                AXStepInstallerView(
                    viewModel: installerVM,
                    title: installerTitle,
                    icon: "shippingbox.fill",
                    accentColor: Color(hex: "#339933"),
                    onDismiss: {
                        showToolInstaller = false
                        Task { await loadData() }
                    }
                )
                .frame(maxWidth: .infinity, minHeight: 260)
            }

            // Status Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Node.js Status")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    AXInfoRow(label: "Status", value: application.isRunning ? "Running" : "Stopped",
                              valueColor: application.isRunning ? .axSuccess : .axError)
                    AXInfoRow(label: "Node Version", value: nodeVersion ?? "Not detected",
                              valueColor: nodeVersion != nil ? .axAccentBlue : .axTextMuted)
                    AXInfoRow(label: "NPM Version", value: npmVersion ?? "Not detected")
                    AXInfoRow(label: "NVM", value: hasNvm ? "Installed" : "Not installed",
                              valueColor: hasNvm ? .axSuccess : .axTextMuted)
                    AXInfoRow(label: "PM2", value: hasPM2 ? "Installed" : "Not installed",
                              valueColor: hasPM2 ? .axSuccess : .axWarning)
                }
            }

            // Metrics
            if hasPM2 && !processes.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AXSpacing.lg) {
                    AXStatCard(icon: "cpu", label: "Processes",
                               value: "\(processes.filter { $0.status == .online }.count)/\(processes.count)",
                               color: .axAccentGreen)
                    AXStatCard(icon: "memorychip", label: "Total Memory",
                               value: totalMemoryFormatted,
                               color: .axWarning)
                    AXStatCard(icon: "arrow.clockwise", label: "Total Restarts",
                               value: "\(processes.reduce(0) { $0 + $1.restarts })",
                               color: .axAccentBlue)
                }
            }

            // Quick Actions
            if !showToolInstaller {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("Quick Actions")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        HStack(spacing: AXSpacing.md) {
                            if !hasPM2 {
                                AXActionButton(label: "Install PM2", icon: "cpu", style: .success) {
                                    Task { await installPM2() }
                                }
                            }

                            if !hasNvm {
                                AXActionButton(label: "Install NVM", icon: "arrow.triangle.branch", style: .primary) {
                                    Task { await installNvm() }
                                }
                            }

                            AXActionButton(label: "Refresh", icon: "arrow.clockwise", style: .ghost) {
                                Task { await loadData() }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Processes

    private var processesSection: some View {
        VStack(spacing: AXSpacing.lg) {
            if !hasPM2 {
                AXPlaceholder(
                    icon: "cpu",
                    title: "PM2 Not Installed",
                    subtitle: "Install PM2 to manage Node.js processes",
                    action: AXPlaceholderAction(label: "Install PM2") {
                        await installPM2()
                    }
                )
            } else if processes.isEmpty {
                AXPlaceholder(
                    icon: "cpu",
                    title: "No Processes",
                    subtitle: "No PM2 processes found on this server"
                )
            } else {
                ForEach(processes) { process in
                    AXCard {
                        HStack(spacing: AXSpacing.lg) {
                            // Status indicator
                            Circle()
                                .fill(process.status == .online ? Color.axSuccess : Color.axError)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                Text(process.name)
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)

                                HStack(spacing: AXSpacing.md) {
                                    Text("PID: \(process.pid ?? 0)")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)

                                    Text(process.cpuFormatted)
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)

                                    Text(process.memoryFormatted)
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)

                                    if let uptime = process.uptimeFormatted {
                                        Text("↑ \(uptime)")
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextMuted)
                                    }
                                }
                            }

                            Spacer()

                            // Process Actions
                            HStack(spacing: AXSpacing.sm) {
                                if process.status == .online {
                                    Button {
                                        Task { await stopProcess(process.name) }
                                    } label: {
                                        Image(systemName: "stop.fill")
                                            .foregroundColor(.axError)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        Task { await restartProcess(process.name) }
                                    } label: {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(.axAccentBlue)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        Task { await startProcessByName(process.name) }
                                    } label: {
                                        Image(systemName: "play.fill")
                                            .foregroundColor(.axSuccess)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    Task { await deleteProcess(process.name) }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.axError.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Packages

    private var packagesSection: some View {
        VStack(spacing: AXSpacing.lg) {
            if let pkg = packageJSON {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("Package Info")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        AXInfoRow(label: "Name", value: pkg.name ?? "Unknown", valueColor: .axAccentBlue)
                        AXInfoRow(label: "Version", value: pkg.version ?? "0.0.0")
                        if let desc = pkg.description {
                            AXInfoRow(label: "Description", value: desc)
                        }
                        AXInfoRow(label: "Entry", value: pkg.entryFile)
                        AXInfoRow(label: "Dependencies", value: "\(pkg.dependencyCount)")
                    }
                }

                // Scripts
                if let scripts = pkg.scripts, !scripts.isEmpty {
                    AXCard {
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            Text("NPM Scripts")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            ForEach(scripts.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .font(AXTypography.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.axAccentBlue)

                                    Spacer()

                                    Text(value)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.axTextMuted)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            } else {
                AXPlaceholder(
                    icon: "shippingbox",
                    title: "No Package Info",
                    subtitle: "package.json not found in this application"
                )
            }
        }
    }

    // MARK: - Environment

    private var environmentSection: some View {
        VStack(spacing: AXSpacing.lg) {
            if envVariables.isEmpty {
                AXPlaceholder(
                    icon: "key",
                    title: "No Environment Variables",
                    subtitle: "No .env file found for this application"
                )
            } else {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("Environment Variables (.env)")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        ForEach(envVariables) { envVar in
                            HStack {
                                Text(envVar.key)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axAccentBlue)

                                Spacer()

                                if envVar.isSecret {
                                    Text("••••••••")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.axWarning)
                                } else {
                                    Text(envVar.value)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.axTextMuted)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, AXSpacing.xxs)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Versions

    private var versionsSection: some View {
        UnifiedVersionsView(
            title: "Node.js Versions",
            serviceName: "Node",
            currentVersion: nodeVersion,
            versions: buildNodeVersionItems(),
            isLoading: isLoading && installedVersions.isEmpty,
            serviceIcon: "n.circle.fill",
            accentColor: Color(hex: "#339933"),
            onRefresh: { await loadData() },
            onInstall: { version in Task { await installNodeVersion(version) } },
            onSwitch: { version in Task { await switchVersion(version) } },
            onUninstall: hasNvm ? { version in Task { await uninstallNodeVersion(version) } } : nil,
            installerVM: installerVM,
            installerTitle: installerTitle,
            showInstaller: showVersionInstaller,
            onDismissInstaller: {
                showVersionInstaller = false
                Task { await loadData() }
            }
        )
    }

    private func buildNodeVersionItems() -> [VersionItem] {
        // Combine installed + available, dedup
        var allVersions: [String] = installedVersions
        for v in availableVersions where !allVersions.contains(v) {
            allVersions.append(v)
        }

        // Sort newest first (semantic version comparison)
        allVersions.sort { a, b in
            let aParts = a.split(separator: ".").compactMap { Int($0) }
            let bParts = b.split(separator: ".").compactMap { Int($0) }
            for i in 0..<min(aParts.count, bParts.count) {
                if aParts[i] != bParts[i] { return aParts[i] > bParts[i] }
            }
            return aParts.count > bParts.count
        }

        return allVersions.map { version in
            let isCurrent = version == nodeVersion
            let isInstalled = installedVersions.contains(version)

            return VersionItem(
                version: version,
                isCurrent: isCurrent,
                isInstalled: isInstalled,
                badge: nil,
                badgeColor: .axAccentBlue
            )
        }
    }

    private func installNodeVersion(_ version: String) async {
        guard hasNvm else {
            GlobalToastManager.shared.showError("NVM is required to install Node versions")
            return
        }

        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Install Node \(version)", description: "Using NVM to install", icon: "arrow.down.circle"),
            AXInstallStep(title: "Verify Installation", description: "Confirming Node \(version) is ready", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Installing Node.js \(version)"
        showVersionInstaller = true

        let sshService = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case let t where t.starts(with: "Install Node"):
                let result = try await sshService.execute(
                    "source ~/.nvm/nvm.sh 2>/dev/null; nvm install \(version) 2>&1",
                    serverId: sid
                )
                guard result.exitCode == 0 else {
                    throw NSError(domain: "NodeInstall", code: 1, userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? "Installation failed" : result.stderr])
                }
                return "Installed"

            case "Verify Installation":
                let result = try await sshService.execute(
                    "source ~/.nvm/nvm.sh 2>/dev/null; nvm ls \(version) 2>/dev/null | head -1",
                    serverId: sid
                )
                return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

            default:
                return nil
            }
        }
    }

    private func uninstallNodeVersion(_ version: String) async {
        guard hasNvm else { return }

        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Uninstall Node \(version)", description: "Removing via NVM", icon: "trash"),
            AXInstallStep(title: "Verify Removal", description: "Confirming removal", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Uninstalling Node.js \(version)"
        showVersionInstaller = true

        let sshService = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case let t where t.starts(with: "Uninstall"):
                let result = try await sshService.execute(
                    "source ~/.nvm/nvm.sh 2>/dev/null; nvm uninstall \(version) 2>&1",
                    serverId: sid
                )
                return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

            case "Verify Removal":
                let result = try await sshService.execute(
                    "source ~/.nvm/nvm.sh 2>/dev/null; nvm ls 2>/dev/null",
                    serverId: sid
                )
                return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

            default:
                return nil
            }
        }
    }

    // MARK: - Logs

    private var logsSection: some View {
        VStack(spacing: AXSpacing.lg) {
            if !hasPM2 || processes.isEmpty {
                AXPlaceholder(
                    icon: "doc.text",
                    title: "No Logs Available",
                    subtitle: "PM2 process logs will appear here when processes are running"
                )
            } else {
                Text("Select a process to view logs")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)

                ForEach(processes) { process in
                    AXCard {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text(process.name)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Text("Tap to view logs for this process")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        do {
            async let version = versionService.detectCurrentVersion(serverId: serverId)
            async let npm = versionService.detectNPMVersion(serverId: serverId)
            async let nvm = versionService.isNvmInstalled(serverId: serverId)
            async let pm2 = processService.isPM2Installed(serverId: serverId)

            nodeVersion = try await version
            npmVersion = try await npm
            hasNvm = try await nvm
            hasPM2 = try await pm2

            if hasPM2 {
                processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
            }

            if hasNvm {
                installedVersions = (try? await versionService.getInstalledVersions(serverId: serverId)) ?? []
            }

            if let appPath = application.installPath {
                packageJSON = try? await configService.readPackageJSON(appPath: appPath, serverId: serverId)
                envVariables = (try? await configService.readEnvFile(appPath: appPath, serverId: serverId)) ?? []
            }
        } catch {
            GlobalToastManager.shared.showError("Failed to load Node.js data: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Service Control

    private func controlService(action: ServiceControlButtons.ServiceAction) async {
        do {
            switch action {
            case .start:
                try await ApplicationManager.shared.startService(type: .nodejs, serverId: serverId)
                GlobalToastManager.shared.showSuccess("Node.js started")
            case .stop:
                try await ApplicationManager.shared.stopService(type: .nodejs, serverId: serverId)
                GlobalToastManager.shared.showSuccess("Node.js stopped")
            case .restart:
                try await ApplicationManager.shared.restartService(type: .nodejs, serverId: serverId)
                GlobalToastManager.shared.showSuccess("Node.js restarted")
            }
            await loadData()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    // MARK: - Process Actions

    private func startProcessByName(_ name: String) async {
        do {
            _ = try await processService.startProcess(name: name, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(name) started")
            processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    private func stopProcess(_ name: String) async {
        do {
            try await processService.stopProcess(name: name, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(name) stopped")
            processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    private func restartProcess(_ name: String) async {
        do {
            try await processService.restartProcess(name: name, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(name) restarted")
            processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    private func deleteProcess(_ name: String) async {
        do {
            try await processService.deleteProcess(name: name, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(name) deleted")
            processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    // MARK: - Version Actions

    private func switchVersion(_ version: String) async {
        do {
            try await versionService.switchVersion(version, serverId: serverId)
            nodeVersion = try await versionService.detectCurrentVersion(serverId: serverId)
            GlobalToastManager.shared.showSuccess("Switched to Node.js \(version)")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    // MARK: - Setup Actions (Live Progress)

    private func installPM2() async {
        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Check Node.js", description: "Verifying Node.js and npm are available", icon: "magnifyingglass"),
            AXInstallStep(title: "Install PM2", description: "Running npm install -g pm2", icon: "arrow.down.circle"),
            AXInstallStep(title: "Verify PM2", description: "Confirming PM2 is ready", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Installing PM2"
        showToolInstaller = true

        let ssh = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case "Check Node.js":
                let result = try await ssh.execute(
                    "source ~/.nvm/nvm.sh 2>/dev/null; node --version 2>&1 && npm --version 2>&1",
                    serverId: sid
                )
                let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !output.isEmpty, result.exitCode == 0 else {
                    throw NSError(domain: "PM2", code: 1, userInfo: [NSLocalizedDescriptionKey: "Node.js or npm not found. Install Node.js first."])
                }
                return "Node: \(output.components(separatedBy: .newlines).first ?? "?"), npm: \(output.components(separatedBy: .newlines).last ?? "?")"

            case "Install PM2":
                let result = try await ssh.execute(
                    "source ~/.nvm/nvm.sh 2>/dev/null; npm install -g pm2 2>&1",
                    serverId: sid
                )
                guard result.exitCode == 0 else {
                    let errMsg = result.stderr.isEmpty ? result.stdout : result.stderr
                    throw NSError(domain: "PM2", code: 1, userInfo: [NSLocalizedDescriptionKey: errMsg])
                }
                // Extract version from output
                let lines = result.stdout.components(separatedBy: .newlines)
                let addedLine = lines.first { $0.contains("+ pm2@") || $0.contains("added") }
                return addedLine ?? "Installed"

            case "Verify PM2":
                let result = try await ssh.execute(
                    "source ~/.nvm/nvm.sh 2>/dev/null; pm2 --version 2>&1",
                    serverId: sid
                )
                let version = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !version.isEmpty, result.exitCode == 0 else {
                    throw NSError(domain: "PM2", code: 1, userInfo: [NSLocalizedDescriptionKey: "PM2 verification failed"])
                }
                return "PM2 v\(version)"

            default:
                return nil
            }
        }

        if installerVM.isComplete {
            hasPM2 = true
        }
    }

    private func installNvm() async {
        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Download NVM", description: "Fetching NVM install script", icon: "arrow.down.circle"),
            AXInstallStep(title: "Install NVM", description: "Running NVM installer", icon: "hammer"),
            AXInstallStep(title: "Verify NVM", description: "Confirming NVM is ready", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Installing NVM"
        showToolInstaller = true

        let ssh = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case "Download NVM":
                let result = try await ssh.execute(
                    "command -v curl >/dev/null 2>&1 && echo 'curl available' || echo 'curl not found'",
                    serverId: sid
                )
                guard result.stdout.contains("available") else {
                    throw NSError(domain: "NVM", code: 1, userInfo: [NSLocalizedDescriptionKey: "curl is required but not found"])
                }
                return "Prerequisites OK"

            case "Install NVM":
                let result = try await ssh.execute(
                    "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash 2>&1",
                    serverId: sid
                )
                guard result.exitCode == 0 else {
                    throw NSError(domain: "NVM", code: 1, userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr])
                }
                return "NVM installed"

            case "Verify NVM":
                let result = try await ssh.execute(
                    "export NVM_DIR=\"$HOME/.nvm\"; [ -s \"$NVM_DIR/nvm.sh\" ] && source \"$NVM_DIR/nvm.sh\" && nvm --version 2>&1",
                    serverId: sid
                )
                let version = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !version.isEmpty, result.exitCode == 0 else {
                    throw NSError(domain: "NVM", code: 1, userInfo: [NSLocalizedDescriptionKey: "NVM verification failed"])
                }
                return "NVM v\(version)"

            default:
                return nil
            }
        }

        if installerVM.isComplete {
            hasNvm = true
        }
    }

    // MARK: - Helpers

    private var totalMemoryFormatted: String {
        let totalBytes = processes.reduce(Int64(0)) { $0 + $1.memory }
        let mb = Double(totalBytes) / 1_048_576
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.1f MB", mb)
    }
}
