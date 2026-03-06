//
//  NodeJSDetailView.swift
//  AevonX
//
//  Full detail view for Node.js application management.
//  Supports PM2 process control, version management, environment vars,
//  Git deployment, framework detection, NPM operations, Nginx proxy,
//  security auditing, and advanced PM2 settings.
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

    // Framework + Deploy detection
    @State private var frameworkInfo: NodeJSFrameworkService.FrameworkInfo?
    @State private var packageManagerName: String = "npm"
    @State private var gitBranch: String?

    // Services
    private let versionService = NodeJSVersionService()
    private let processService = NodeJSProcessService()
    private let configService = NodeJSConfigService()
    private let frameworkService = NodeJSFrameworkService()
    private let deployService = NodeJSDeployService()

    // Step installer for versions AND tools (PM2/NVM)
    @StateObject private var installerVM = AXStepInstallerViewModel(steps: [])
    @State private var installerTitle: String = ""
    @State private var showVersionInstaller = false
    @State private var showToolInstaller = false

    // Process management
    @State private var showStartProcessSheet = false
    @State private var newProcessName = ""
    @State private var newProcessScript = "index.js"
    @State private var newProcessInstances = 1
    @State private var useClusterMode = false

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
        case .deployment:
            DeploymentSection(serverId: serverId, appPath: application.installPath)
        case .frameworks:
            FrameworksSection(serverId: serverId, appPath: application.installPath)
        case .packages:
            packagesSection
        case .npm:
            NPMOperationsSection(serverId: serverId, appPath: application.installPath)
        case .environment:
            EnvVariableEditor(serverId: serverId, appPath: application.installPath)
        case .reverseProxy:
            ReverseProxySection(serverId: serverId, appPath: application.installPath)
        case .versions:
            versionsSection
        case .security:
            SecuritySection(serverId: serverId, appPath: application.installPath)
        case .logs:
            NodeJSLogsSection(serverId: serverId, hasPM2: hasPM2, processes: processes)
        case .settings:
            NodeJSSettingsSection(serverId: serverId)
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

            // Framework Badge (if detected)
            if let fw = frameworkInfo, fw.framework != .unknown {
                AXCard {
                    HStack(spacing: AXSpacing.md) {
                        Image(systemName: fw.framework.icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Color(hex: fw.framework.color))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(fw.framework.rawValue)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.axTextPrimary)

                            HStack(spacing: AXSpacing.sm) {
                                if let ver = fw.version {
                                    Text("v\(ver)")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.axAccentBlue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.axAccentBlue.opacity(0.1))
                                        .cornerRadius(4)
                                }

                                if fw.hasTypeScript {
                                    HStack(spacing: 2) {
                                        Text("TS")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    .foregroundColor(Color(hex: "#3178C6"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "#3178C6").opacity(0.1))
                                    .cornerRadius(4)
                                }

                                // Package manager badge
                                HStack(spacing: 2) {
                                    Image(systemName: "shippingbox.fill")
                                        .font(.system(size: 8))
                                    Text(packageManagerName)
                                        .font(.system(size: 9, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "#CB3837"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#CB3837").opacity(0.1))
                                .cornerRadius(4)
                            }
                        }

                        Spacer()

                        // Git branch badge
                        if let branch = gitBranch {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 10))
                                Text(branch)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            }
                            .foregroundColor(Color(hex: "#F05032"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#F05032").opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                }
            }

            // Status Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Node.js Environment")
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
                    AXInfoRow(label: "Auto-start", value: application.autoStart ? "Enabled" : "Disabled",
                              valueColor: application.autoStart ? .axSuccess : .axTextMuted)
                }
            }

            // Metrics
            if hasPM2 && !processes.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AXSpacing.sm) {
                    AXStatCard(icon: "cpu", label: "Online",
                               value: "\(processes.filter { $0.status == .online }.count)/\(processes.count)",
                               color: .axAccentGreen)
                    AXStatCard(icon: "memorychip", label: "Memory",
                               value: totalMemoryFormatted,
                               color: .axWarning)
                    AXStatCard(icon: "bolt.fill", label: "CPU",
                               value: totalCPUFormatted,
                               color: .axAccentBlue)
                    AXStatCard(icon: "arrow.clockwise", label: "Restarts",
                               value: "\(processes.reduce(0) { $0 + $1.restarts })",
                               color: processes.reduce(0, { $0 + $1.restarts }) > 10 ? .axError : .axTextSecondary)
                }
            }

            // Contextual Quick Actions
            if !showToolInstaller {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("Quick Actions")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AXSpacing.sm) {
                            // Setup actions
                            if !hasPM2 {
                                quickActionCard(title: "Install PM2", icon: "cpu", color: .axSuccess) {
                                    await installPM2()
                                }
                            }
                            if !hasNvm {
                                quickActionCard(title: "Install NVM", icon: "arrow.triangle.branch", color: Color(hex: "#339933")) {
                                    await installNvm()
                                }
                            }

                            // Common actions
                            if hasPM2 {
                                quickActionCard(title: "PM2 Save", icon: "square.and.arrow.down", color: Color(hex: "#8B5CF6")) {
                                    await pm2Save()
                                }
                                quickActionCard(title: "Restart All", icon: "arrow.clockwise", color: .axAccentBlue) {
                                    await pm2RestartAll()
                                }
                                quickActionCard(title: "Stop All", icon: "stop.fill", color: .axError) {
                                    await pm2StopAll()
                                }
                                quickActionCard(title: "Reload All", icon: "arrow.2.circlepath", color: Color(hex: "#06B6D4")) {
                                    await pm2ReloadAll()
                                }
                            }

                            // NPM actions
                            quickActionCard(title: "NPM Install", icon: "shippingbox", color: Color(hex: "#CB3837")) {
                                await npmInstall()
                            }
                            quickActionCard(title: "NPM Audit", icon: "shield.checkered", color: .axWarning) {
                                await npmAudit()
                            }

                            // Always show refresh
                            quickActionCard(title: "Refresh", icon: "arrow.clockwise", color: .axTextSecondary) {
                                await loadData()
                            }
                        }
                    }
                }
            }
        }
    }

    private func quickActionCard(title: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(color.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(color.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Processes (Enhanced)

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
            } else {
                // Process Control Bar
                AXCard {
                    HStack(spacing: AXSpacing.md) {
                        Text("PM2 Processes")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Spacer()

                        // Bulk actions
                        Button {
                            showStartProcessSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 11))
                                Text("New Process")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task { await pm2ReloadAll() }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.2.circlepath")
                                    .font(.system(size: 11))
                                Text("Reload All")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "#06B6D4"))
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task { await generateEcosystem() }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.badge.gearshape")
                                    .font(.system(size: 11))
                                Text("Ecosystem")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "#8B5CF6"))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Process list
                if processes.isEmpty {
                    AXPlaceholder(
                        icon: "cpu",
                        title: "No Processes",
                        subtitle: "Start a new PM2 process to begin"
                    )
                } else {
                    ForEach(processes) { process in
                        processCard(process)
                    }
                }
            }
        }
        .sheet(isPresented: $showStartProcessSheet) { startProcessSheet }
    }

    private func processCard(_ process: PM2Process) -> some View {
        AXCard {
            VStack(spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.lg) {
                    // Status
                    Circle()
                        .fill(process.status == .online ? Color.axSuccess :
                              process.status == .errored ? Color.axError : Color.axTextMuted)
                        .frame(width: 10, height: 10)
                        .shadow(color: process.status == .online ? .axSuccess.opacity(0.4) : .clear, radius: 4)

                    // Info
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        HStack(spacing: AXSpacing.sm) {
                            Text(process.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.axTextPrimary)
                        }

                        HStack(spacing: AXSpacing.md) {
                            if let pid = process.pid {
                                Text("PID: \(pid)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axTextMuted)
                            }
                            Text(process.cpuFormatted)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                            Text(process.memoryFormatted)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                            if let uptime = process.uptimeFormatted {
                                Text("↑ \(uptime)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axTextMuted)
                            }

                            // Restarts badge
                            if process.restarts > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 8))
                                    Text("\(process.restarts)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(process.restarts > 10 ? .axError : .axWarning)
                            }
                        }
                    }

                    Spacer()

                    // Actions
                    HStack(spacing: AXSpacing.sm) {
                        if process.status == .online {
                            processActionBtn(icon: "arrow.2.circlepath", color: Color(hex: "#06B6D4"), tooltip: "Reload") {
                                await reloadProcess(process.name)
                            }
                            processActionBtn(icon: "stop.fill", color: .axError, tooltip: "Stop") {
                                await stopProcess(process.name)
                            }
                            processActionBtn(icon: "arrow.clockwise", color: .axAccentBlue, tooltip: "Restart") {
                                await restartProcess(process.name)
                            }
                        } else {
                            processActionBtn(icon: "play.fill", color: .axSuccess, tooltip: "Start") {
                                await startProcessByName(process.name)
                            }
                        }

                        processActionBtn(icon: "chart.bar.fill", color: Color(hex: "#8B5CF6"), tooltip: "Scale") {
                            await scaleProcess(process.name, instances: 2)
                        }

                        processActionBtn(icon: "trash", color: .axError.opacity(0.7), tooltip: "Delete") {
                            await deleteProcess(process.name)
                        }
                    }
                }
            }
        }
    }

    private func processActionBtn(icon: String, color: Color, tooltip: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    // MARK: - Start Process Sheet

    private var startProcessSheet: some View {
        VStack(spacing: AXSpacing.lg) {
            Text("Start New Process")
                .font(AXTypography.title3)
                .foregroundColor(.axTextPrimary)

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Process Name")
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                TextField("my-app", text: $newProcessName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Entry Script")
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                TextField("index.js", text: $newProcessScript)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: AXSpacing.lg) {
                Toggle("Cluster Mode", isOn: $useClusterMode)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#8B5CF6")))

                if useClusterMode {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Instances")
                            .font(AXTypography.caption).foregroundColor(.axTextMuted)
                        Stepper("\(newProcessInstances)", value: $newProcessInstances, in: 1...16)
                    }
                }
            }

            HStack {
                Button("Cancel") { showStartProcessSheet = false }
                    .buttonStyle(.plain)
                Spacer()
                AXActionButton(label: "Start", icon: "play.fill", style: .success) {
                    Task { await startNewProcess() }
                }
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 420)
    }

    // MARK: - Packages (Enhanced)

    private var packagesSection: some View {
        VStack(spacing: AXSpacing.lg) {
            if let pkg = packageJSON {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        HStack {
                            Text("Package Info")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            Spacer()
                            // NPM install button
                            AXActionButton(label: "npm install", icon: "shippingbox", style: .ghost) {
                                Task { await npmInstall() }
                            }
                        }

                        AXInfoRow(label: "Name", value: pkg.name ?? "Unknown", valueColor: .axAccentBlue)
                        AXInfoRow(label: "Version", value: pkg.version ?? "0.0.0")
                        if let desc = pkg.description {
                            AXInfoRow(label: "Description", value: desc)
                        }
                        AXInfoRow(label: "Entry", value: pkg.entryFile)
                        AXInfoRow(label: "Dependencies", value: "\(pkg.dependencyCount)")
                    }
                }

                // Scripts with run buttons
                if let scripts = pkg.scripts, !scripts.isEmpty {
                    AXCard {
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            Text("NPM Scripts")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            ForEach(scripts.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.axAccentBlue)

                                    Spacer()

                                    Text(value)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.axTextMuted)
                                        .lineLimit(1)

                                    Button {
                                        Task { await runNPMScript(key) }
                                    } label: {
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(.axSuccess)
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(.plain)
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
        var allVersions: [String] = installedVersions
        for v in availableVersions where !allVersions.contains(v) {
            allVersions.append(v)
        }

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
            // LTS badge for even major versions
            let major = Int(version.split(separator: ".").first ?? "") ?? 0
            let isLTS = major % 2 == 0

            return VersionItem(
                version: version,
                isCurrent: isCurrent,
                isInstalled: isInstalled,
                badge: isLTS ? "LTS" : nil,
                badgeColor: isLTS ? .axSuccess : .axAccentBlue
            )
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
                availableVersions = (try? await versionService.getAvailableVersions(serverId: serverId)) ?? []
            }

            if let appPath = application.installPath {
                packageJSON = try? await configService.readPackageJSON(appPath: appPath, serverId: serverId)
                envVariables = (try? await configService.readEnvFile(appPath: appPath, serverId: serverId)) ?? []

                // Framework detection
                frameworkInfo = try? await frameworkService.detectFramework(projectPath: appPath, serverId: serverId)

                // Package manager detection
                packageManagerName = ((try? await deployService.detectPackageManager(path: appPath, serverId: serverId)) ?? .npm).rawValue

                // Git branch
                if let info = try? await deployService.getDeploymentInfo(path: appPath, serverId: serverId) {
                    gitBranch = info.branch
                }
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

    private func reloadProcess(_ name: String) async {
        do {
            try await processService.reloadProcess(name: name, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(name) reloaded (zero-downtime)")
            processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    private func scaleProcess(_ name: String, instances: Int) async {
        do {
            try await processService.scaleProcess(name: name, instances: instances, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(name) scaled to \(instances) instances")
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

    private func startNewProcess() async {
        guard !newProcessName.isEmpty else { return }
        guard let path = application.installPath else { return }

        do {
            if useClusterMode {
                try await processService.startCluster(
                    name: newProcessName,
                    entryFile: newProcessScript,
                    instances: newProcessInstances,
                    cwd: path,
                    serverId: serverId
                )
            } else {
                _ = try await processService.startProcess(
                    name: newProcessName,
                    entryFile: newProcessScript,
                    cwd: path,
                    serverId: serverId
                )
            }
            GlobalToastManager.shared.showSuccess("\(newProcessName) started")
            showStartProcessSheet = false
            newProcessName = ""
            processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    private func generateEcosystem() async {
        guard let path = application.installPath else { return }
        let appName = application.name
        let entryFile = packageJSON?.entryFile ?? "index.js"
        do {
            try await processService.generateEcosystemConfig(
                name: appName,
                script: entryFile,
                cwd: path,
                serverId: serverId
            )
            GlobalToastManager.shared.showSuccess("ecosystem.config.js generated")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    // MARK: - PM2 Bulk Actions

    private func pm2Save() async {
        do {
            try await processService.saveProcessList(serverId: serverId)
            GlobalToastManager.shared.showSuccess("Process list saved")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    private func pm2RestartAll() async {
        let ssh = SSHService.shared
        _ = try? await ssh.execute("source ~/.nvm/nvm.sh 2>/dev/null; pm2 restart all 2>&1", serverId: serverId)
        GlobalToastManager.shared.showSuccess("All processes restarted")
        processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
    }

    private func pm2StopAll() async {
        let ssh = SSHService.shared
        _ = try? await ssh.execute("source ~/.nvm/nvm.sh 2>/dev/null; pm2 stop all 2>&1", serverId: serverId)
        GlobalToastManager.shared.showSuccess("All processes stopped")
        processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
    }

    private func pm2ReloadAll() async {
        let ssh = SSHService.shared
        _ = try? await ssh.execute("source ~/.nvm/nvm.sh 2>/dev/null; pm2 reload all 2>&1", serverId: serverId)
        GlobalToastManager.shared.showSuccess("All processes reloaded (zero-downtime)")
        processes = (try? await processService.listProcesses(serverId: serverId)) ?? []
    }

    // MARK: - NPM Actions

    private func npmInstall() async {
        guard let path = application.installPath else { return }
        let ssh = SSHService.shared
        _ = try? await ssh.execute("source ~/.nvm/nvm.sh 2>/dev/null; cd \"\(path)\" && npm install 2>&1", serverId: serverId)
        GlobalToastManager.shared.showSuccess("npm install complete")
    }

    private func npmAudit() async {
        selectedSection = .security
    }

    private func runNPMScript(_ script: String) async {
        guard let path = application.installPath else { return }
        do {
            _ = try await deployService.runScript(path: path, script: script, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Script '\(script)' completed")
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

    private var totalCPUFormatted: String {
        let total = processes.reduce(0.0) { $0 + $1.cpu }
        return String(format: "%.1f%%", total)
    }
}
