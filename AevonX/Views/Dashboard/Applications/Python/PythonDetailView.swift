//
//  PythonDetailView.swift
//  AevonX
//
//  Full detail view for Python application management.
//  Supports Gunicorn/Supervisor process control, venv management,
//  pip packages, framework detection, version management.
//

import SwiftUI
import AevonXCoreBridge

@MainActor
struct PythonDetailView: View {
    let application: ApplicationInstance
    let serverId: String
    let onBack: (() -> Void)?

    init(application: ApplicationInstance, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.serverId = serverId
        self.onBack = onBack
    }

    @State private var selectedSection: PythonSection = .overview
    @State private var isLoading = true

    // Data
    @State private var pythonVersion: String?
    @State private var pipVersion: String?
    @State private var hasPyenv = false
    @State private var hasGunicorn = false
    @State private var hasSupervisor = false

    // Framework
    @State private var frameworkInfo: PythonFrameworkService.FrameworkInfo?

    // Virtual Envs
    @State private var venvs: [PythonVenvService.VenvInfo] = []

    // Packages
    @State private var packages: [PythonPackageService.PipPackage] = []
    @State private var outdatedPackages: [PythonPackageService.PipPackage] = []

    // Processes
    @State private var gunicornStatus: PythonProcessService.GunicornStatus?
    @State private var supervisorPrograms: [PythonProcessService.SupervisorProgram] = []

    // Versions
    @State private var installedVersions: [String] = []
    @State private var availableVersions: [String] = []

    // Env vars
    @State private var envVariables: [PythonConfigService.EnvVariable] = []

    // Services
    private let versionService = PythonVersionService()
    private let venvService = PythonVenvService()
    private let packageService = PythonPackageService()
    private let processService = PythonProcessService()
    private let frameworkService = PythonFrameworkService()
    private let configService = PythonConfigService()

    // Step installer for versions
    @StateObject private var installerVM = AXStepInstallerViewModel(steps: [])
    @State private var installerTitle: String = ""
    @State private var showVersionInstaller = false

    // Create Venv dialog
    @State private var showCreateVenvSheet = false
    @State private var newVenvName: String = ""
    @State private var newVenvPath: String = "/var/www"
    @State private var isCreatingVenv = false

    var body: some View {
        ServiceDetailContainer(
            application: application,
            brandColor: Color(hex: "#3776AB"),
            iconName: "chevron.left.forwardslash.chevron.right",
            selectedSection: $selectedSection,
            sections: PythonSection.allCases.map { $0 },
            isLoading: isLoading,
            loadingMessage: "Syncing Python Data…",
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
        case .virtualenvs:
            virtualEnvsSection
        case .packages:
            packagesSection
        case .processes:
            processesSection
        case .configuration:
            configurationSection
        case .versions:
            versionsSection
        case .logs:
            logsSection
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(spacing: AXSpacing.lg) {
            // Framework badge
            if let fw = frameworkInfo, fw.framework != .unknown {
                AXCard {
                    HStack(spacing: AXSpacing.md) {
                        Image(systemName: fw.framework.icon)
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: fw.framework.color))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(fw.framework.rawValue)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            if let ver = fw.version {
                                Text("v\(ver)")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                            }
                        }

                        Spacer()

                        if fw.hasCelery {
                            Text("Celery")
                                .font(AXTypography.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#37B24D"))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                }
            }

            // Status
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Python Environment")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    AXInfoRow(label: "Python", value: pythonVersion ?? "Not Detected",
                              valueColor: pythonVersion != nil ? .axAccentGreen : .axError)
                    AXInfoRow(label: "pip", value: pipVersion ?? "Not Detected")
                    AXInfoRow(label: "pyenv", value: hasPyenv ? "Available" : "Not Installed",
                              valueColor: hasPyenv ? .axSuccess : .axTextMuted)
                    AXInfoRow(label: "Gunicorn", value: hasGunicorn ? "Installed" : "Not Found",
                              valueColor: hasGunicorn ? .axSuccess : .axTextMuted)
                    AXInfoRow(label: "Supervisor", value: hasSupervisor ? "Available" : "Not Found",
                              valueColor: hasSupervisor ? .axSuccess : .axTextMuted)
                }
            }

            // Quick Actions — always show relevant contextual actions
            if !quickActions.isEmpty {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("Quick Actions")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.sm) {
                            ForEach(quickActions, id: \.title) { action in
                                quickActionCard(title: action.title, icon: action.icon, color: action.color) {
                                    Task { await action.handler() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Action Card

    private struct QuickAction {
        let title: String
        let icon: String
        let color: Color
        let handler: () async -> Void
    }

    private var quickActions: [QuickAction] {
        var actions: [QuickAction] = []

        // Setup actions
        if !hasPyenv {
            actions.append(QuickAction(title: "Install pyenv", icon: "arrow.down.circle.fill", color: Color(hex: "#3776AB")) {
                do {
                    try await self.versionService.installPyenv(serverId: self.serverId)
                    GlobalToastManager.shared.showSuccess("pyenv installed")
                    await self.loadData()
                } catch {
                    GlobalToastManager.shared.showError("Failed: \(error.localizedDescription)")
                }
            })
        }

        if !hasGunicorn {
            actions.append(QuickAction(title: "Install Gunicorn", icon: "bolt.circle.fill", color: Color(hex: "#499848")) {
                do {
                    _ = try await SSHService.shared.execute("pip3 install gunicorn 2>&1", serverId: self.serverId)
                    GlobalToastManager.shared.showSuccess("Gunicorn installed")
                    await self.loadData()
                } catch {
                    GlobalToastManager.shared.showError("Failed: \(error.localizedDescription)")
                }
            })
        }

        // Always useful
        actions.append(QuickAction(title: "Create Venv", icon: "folder.badge.plus", color: Color(hex: "#3776AB")) {
            await MainActor.run { self.showCreateVenvSheet = true }
        })

        actions.append(QuickAction(title: "Audit Packages", icon: "shield.checkered", color: Color(hex: "#E07C24")) {
            do {
                let report = try await self.packageService.auditPackages(serverId: self.serverId)
                GlobalToastManager.shared.showSuccess(report.isEmpty ? "No vulnerabilities found" : "Audit complete")
            } catch {
                GlobalToastManager.shared.showError("Audit failed")
            }
        })

        // Framework-specific
        if frameworkInfo?.framework == .django {
            actions.append(QuickAction(title: "Django Migrate", icon: "arrow.right.circle.fill", color: Color(hex: "#092E20")) {
                await self.runDjangoMigrate()
            })
            actions.append(QuickAction(title: "Collect Static", icon: "doc.on.doc.fill", color: Color(hex: "#092E20")) {
                await self.runDjangoCollectStatic()
            })
        }

        // Running service actions
        if hasGunicorn {
            actions.append(QuickAction(title: "Reload Gunicorn", icon: "arrow.clockwise.circle.fill", color: Color(hex: "#499848")) {
                await self.reloadGunicorn()
            })
        }

        return actions
    }

    @ViewBuilder
    private func quickActionCard(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(AXSpacing.sm)
            .background(color.opacity(0.08))
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Virtual Envs

    private var virtualEnvsSection: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack {
                Text("Virtual Environments")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                AXActionButton(label: "Create New", icon: "plus.circle", style: .primary) {
                    newVenvName = ""
                    newVenvPath = "/var/www"
                    showCreateVenvSheet = true
                }
            }

            if venvs.isEmpty {
                AXPlaceholder(
                    icon: "folder.badge.questionmark",
                    title: "No Virtual Environments Found",
                    subtitle: "Create a new virtual environment or scan the server"
                )
            } else {
                ForEach(venvs) { venv in
                    AXCard {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(Color(hex: "#3776AB"))
                                Text(venv.name)
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)

                                Spacer()

                                if let pyVer = venv.pythonVersion {
                                    Text("Python \(pyVer)")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axAccentBlue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.axAccentBlue.opacity(0.1))
                                        .cornerRadius(AXCornerRadius.sm)
                                }
                            }

                            AXInfoRow(label: "Path", value: venv.path)
                            AXInfoRow(label: "Packages", value: "\(venv.packageCount)")
                            AXInfoRow(label: "Size", value: AXFormatter.formatBytes(venv.sizeBytes))

                            HStack(spacing: AXSpacing.sm) {
                                AXActionButton(label: "View Packages", icon: "shippingbox", style: .ghost, size: .small) {
                                    selectedSection = .packages
                                }
                                Spacer()
                                AXActionButton(label: "Delete", icon: "trash", style: .destructive, size: .small) {
                                    Task { await deleteVenv(venv) }
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateVenvSheet) {
            createVenvSheet
        }
    }

    // MARK: - Create Venv Sheet

    private var createVenvSheet: some View {
        VStack(spacing: AXSpacing.lg) {
            // Header
            HStack {
                Text("Create Virtual Environment")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button { showCreateVenvSheet = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: AXSpacing.md) {
                // Name field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Environment Name")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    TextField("myproject-env", text: $newVenvName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                // Path field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Project Path")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    TextField("/var/www/myproject", text: $newVenvPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                // Info
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.axAccentBlue)
                    Text("The venv will be created at: \(newVenvPath)/\(newVenvName.isEmpty ? "venv" : newVenvName)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .padding(AXSpacing.sm)
                .background(Color.axAccentBlue.opacity(0.05))
                .cornerRadius(AXCornerRadius.sm)
            }

            Spacer()

            // Actions
            HStack {
                AXActionButton(label: "Cancel", style: .ghost) {
                    showCreateVenvSheet = false
                }

                Spacer()

                AXActionButton(label: isCreatingVenv ? "Creating…" : "Create", icon: "folder.badge.plus", style: .primary) {
                    guard !newVenvName.isEmpty, !newVenvPath.isEmpty else {
                        GlobalToastManager.shared.showError("Please enter a name and path")
                        return
                    }
                    Task { await createVenv() }
                }
                .disabled(newVenvName.isEmpty || isCreatingVenv)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 480, height: 360)
        .background(Color.axBackground)
    }

    // MARK: - Packages

    private var packagesSection: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack {
                Text("pip Packages")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                if !outdatedPackages.isEmpty {
                    Text("\(outdatedPackages.count) outdated")
                        .font(AXTypography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange)
                        .cornerRadius(AXCornerRadius.sm)
                }

                Spacer()

                AXActionButton(label: "Refresh", icon: "arrow.clockwise", style: .ghost, size: .small) {
                    Task { await loadPackages() }
                }
            }

            if packages.isEmpty && !isLoading {
                AXPlaceholder(
                    icon: "shippingbox",
                    title: "No Packages Found",
                    subtitle: "Install packages via pip or from requirements.txt"
                )
            } else {
                // Package list
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        // Header
                        HStack {
                            Text("Package")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Version")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .frame(width: 100)
                            Text("Latest")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .frame(width: 100)
                            Text("")
                                .frame(width: 80)
                        }
                        .padding(.bottom, 4)

                        Divider()

                        ForEach(packages) { pkg in
                            HStack {
                                Text(pkg.name)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(pkg.version)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                    .frame(width: 100)

                                if let latest = pkg.latestVersion, latest != pkg.version {
                                    Text(latest)
                                        .font(AXTypography.caption)
                                        .foregroundColor(.orange)
                                        .frame(width: 100)
                                } else {
                                    Text("✓")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axSuccess)
                                        .frame(width: 100)
                                }

                                AXActionButton(label: "Update", style: .ghost, size: .small) {
                                    Task { await updatePackage(pkg.name) }
                                }
                                .frame(width: 80)
                                .opacity(pkg.isOutdated ? 1 : 0.3)
                                .disabled(!pkg.isOutdated)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Processes

    private var processesSection: some View {
        VStack(spacing: AXSpacing.lg) {
            // Gunicorn
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(Color(hex: "#3776AB"))
                        Text("Gunicorn Workers")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Spacer()

                        if let status = gunicornStatus {
                            Text(status.isRunning ? "Running" : "Stopped")
                                .font(AXTypography.caption)
                                .foregroundColor(status.isRunning ? .axSuccess : .axError)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background((status.isRunning ? Color.axSuccess : Color.axError).opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }

                    if let status = gunicornStatus, !status.workers.isEmpty {
                        ForEach(status.workers) { worker in
                            HStack {
                                Circle()
                                    .fill(Color.axSuccess)
                                    .frame(width: 8, height: 8)

                                Text("PID: \(worker.pid)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)

                                Spacer()

                                Text("\(String(format: "%.1f", worker.memoryMB)) MB")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)

                                Text(worker.status)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axAccentBlue)
                            }
                        }

                        HStack(spacing: AXSpacing.md) {
                            if let masterPID = status.masterPID {
                                AXActionButton(label: "Scale Up (+1)", icon: "plus.circle", style: .primary, size: .small) {
                                    Task {
                                        try? await processService.scaleGunicornWorkers(serverId: serverId, masterPID: masterPID, increment: true)
                                        await loadProcesses()
                                    }
                                }
                                AXActionButton(label: "Scale Down (-1)", icon: "minus.circle", style: .ghost, size: .small) {
                                    Task {
                                        try? await processService.scaleGunicornWorkers(serverId: serverId, masterPID: masterPID, increment: false)
                                        await loadProcesses()
                                    }
                                }
                                AXActionButton(label: "Graceful Reload", icon: "arrow.clockwise", style: .ghost, size: .small) {
                                    Task {
                                        try? await processService.reloadGunicorn(serverId: serverId, masterPID: masterPID)
                                        GlobalToastManager.shared.showSuccess("Gunicorn reloaded")
                                    }
                                }
                            }
                        }
                    } else {
                        AXPlaceholder(
                            icon: "cpu",
                            title: "Gunicorn Not Running",
                            subtitle: hasGunicorn ? "Start your app via Gunicorn or Supervisor" : "Gunicorn not installed"
                        )
                    }
                }
            }

            // Supervisor programs
            if hasSupervisor && !supervisorPrograms.isEmpty {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("Supervisor Programs")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        ForEach(supervisorPrograms) { program in
                            HStack {
                                Circle()
                                    .fill(program.status == "RUNNING" ? Color.axSuccess : Color.axError)
                                    .frame(width: 8, height: 8)

                                Text(program.name)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)

                                Spacer()

                                Text(program.status)
                                    .font(AXTypography.caption)
                                    .foregroundColor(program.status == "RUNNING" ? .axSuccess : .axError)

                                AXActionButton(label: program.status == "RUNNING" ? "Restart" : "Start", style: .ghost, size: .small) {
                                    Task {
                                        let action = program.status == "RUNNING" ? "restart" : "start"
                                        try? await processService.controlSupervisor(program: program.name, action: action, serverId: serverId)
                                        await loadProcesses()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Configuration (Env Vars)

    private var configurationSection: some View {
        VStack(spacing: AXSpacing.lg) {
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Text("Environment Variables (.env)")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Spacer()

                        AXActionButton(label: "Refresh", icon: "arrow.clockwise", style: .ghost, size: .small) {
                            Task { await loadEnvVars() }
                        }
                    }

                    if envVariables.isEmpty {
                        AXPlaceholder(
                            icon: "key.fill",
                            title: "No .env File Found",
                            subtitle: "Create a .env file in your project root"
                        )
                    } else {
                        ForEach(envVariables, id: \.key) { envVar in
                            HStack {
                                Text(envVar.key)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if envVar.isSensitive {
                                    Text("•••••••")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)
                                } else {
                                    Text(envVar.value)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.axAccentBlue)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Versions

    private var versionsSection: some View {
        UnifiedVersionsView(
            title: "Python Versions",
            serviceName: "Python",
            currentVersion: pythonVersion,
            versions: buildPythonVersionItems(),
            isLoading: isLoading && installedVersions.isEmpty,
            serviceIcon: "chevron.left.forwardslash.chevron.right",
            accentColor: Color(hex: "#3776AB"),
            onRefresh: { await loadData() },
            onInstall: { version in Task { await installPythonVersion(version) } },
            onSwitch: { version in Task { await switchVersion(version) } },
            onUninstall: hasPyenv ? { version in Task { await uninstallPythonVersion(version) } } : nil,
            installerVM: installerVM,
            installerTitle: installerTitle,
            showInstaller: showVersionInstaller,
            onDismissInstaller: {
                showVersionInstaller = false
                Task { await loadData() }
            }
        )
    }

    // MARK: - Logs

    private var logsSection: some View {
        VStack(spacing: AXSpacing.lg) {
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Application Logs")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    AXPlaceholder(
                        icon: "doc.text",
                        title: "Log Viewer",
                        subtitle: "View Gunicorn, Supervisor, and application logs"
                    )
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                self.pythonVersion = try? await self.versionService.detectCurrentVersion(serverId: self.serverId)
            }
            group.addTask { @MainActor in
                self.pipVersion = try? await self.versionService.detectPipVersion(serverId: self.serverId)
            }
            group.addTask { @MainActor in
                self.hasPyenv = (try? await self.versionService.isPyenvInstalled(serverId: self.serverId)) ?? false
            }
            group.addTask { @MainActor in
                self.hasGunicorn = (try? await self.processService.isGunicornInstalled(serverId: self.serverId)) ?? false
            }
            group.addTask { @MainActor in
                self.hasSupervisor = (try? await self.processService.isSupervisorInstalled(serverId: self.serverId)) ?? false
            }
            group.addTask { @MainActor in
                self.installedVersions = (try? await self.versionService.getInstalledVersions(serverId: self.serverId)) ?? []
            }
            group.addTask { @MainActor in
                self.availableVersions = (try? await self.versionService.getAvailableVersions(serverId: self.serverId)) ?? []
            }
        }

        // Load section-specific data
        await loadProcesses()
        await loadPackages()
    }

    private func loadProcesses() async {
        gunicornStatus = try? await processService.getGunicornStatus(serverId: serverId)
        if hasSupervisor {
            supervisorPrograms = (try? await processService.getSupervisorPrograms(serverId: serverId)) ?? []
        }
    }

    private func loadPackages() async {
        packages = (try? await packageService.listPackages(serverId: serverId)) ?? []
        outdatedPackages = (try? await packageService.listOutdatedPackages(serverId: serverId)) ?? []

        // Merge outdated info: build a lookup for quick access
        let outdatedLookup = Dictionary(uniqueKeysWithValues: outdatedPackages.map { ($0.name, $0) })
        // Replace packages with outdated ones that have latestVersion set
        for i in packages.indices {
            if let outdated = outdatedLookup[packages[i].name] {
                packages[i] = outdated
            }
        }
    }

    private func loadEnvVars() async {
        // Try common project paths
        envVariables = (try? await configService.readEnvFile(path: "/var/www", serverId: serverId)) ?? []
    }

    // MARK: - Service Control

    private func controlService(action: ServiceControlButtons.ServiceAction) async {
        do {
            switch action {
            case .start: try await GoApplicationService.shared.startService(type: .python, serverId: serverId)
            case .stop: try await GoApplicationService.shared.stopService(type: .python, serverId: serverId)
            case .restart: try await GoApplicationService.shared.restartService(type: .python, serverId: serverId)
            }
            GlobalToastManager.shared.showSuccess("Python service \(action) completed")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Version Actions

    private func buildPythonVersionItems() -> [VersionItem] {
        var allVersions: [String] = installedVersions
        for v in availableVersions where !allVersions.contains(v) {
            allVersions.append(v)
        }

        return allVersions.map { version in
            let isCurrent = version == pythonVersion
            let isInstalled = installedVersions.contains(version)
            let badge: String? = {
                if version.hasSuffix(".0") { return "Latest" }
                return nil
            }()

            return VersionItem(
                version: version,
                isCurrent: isCurrent,
                isInstalled: isInstalled,
                badge: isCurrent ? nil : badge,
                badgeColor: .axAccentBlue
            )
        }
    }

    private func installPythonVersion(_ version: String) async {
        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Install Python \(version)", description: hasPyenv ? "Using pyenv" : "Using system packages", icon: "arrow.down.circle"),
            AXInstallStep(title: "Verify Installation", description: "Confirming Python \(version) is ready", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Installing Python \(version)"
        showVersionInstaller = true

        let sshService = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case let t where t.starts(with: "Install Python"):
                try await versionService.installVersion(version, serverId: sid)
                return "Installed"

            case "Verify Installation":
                let result = try await sshService.execute("python\(version.split(separator: ".").prefix(2).joined(separator: ".")) --version 2>/dev/null || python3 --version 2>/dev/null", serverId: sid)
                return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

            default:
                return nil
            }
        }
    }

    private func switchVersion(_ version: String) async {
        do {
            try await versionService.switchVersion(version, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Switched to Python \(version)")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError("Switch failed: \(error.localizedDescription)")
        }
    }

    private func uninstallPythonVersion(_ version: String) async {
        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Uninstall Python \(version)", description: "Removing", icon: "trash"),
            AXInstallStep(title: "Verify Removal", description: "Confirming", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Uninstalling Python \(version)"
        showVersionInstaller = true

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case let t where t.starts(with: "Uninstall"):
                try await versionService.uninstallVersion(version, serverId: sid)
                return "Uninstalled"
            case "Verify Removal":
                let versions = try await versionService.getInstalledVersions(serverId: sid)
                return "Remaining: \(versions.joined(separator: ", "))"
            default:
                return nil
            }
        }
    }

    // MARK: - Django Actions

    private func runDjangoMigrate() async {
        guard let fw = frameworkInfo, fw.framework == .django else { return }
        do {
            let output = try await frameworkService.runDjangoMigrations(projectPath: "/var/www", serverId: serverId)
            GlobalToastManager.shared.showSuccess("Migrations applied")
            print(output)
        } catch {
            GlobalToastManager.shared.showError("Migration failed: \(error.localizedDescription)")
        }
    }

    private func runDjangoCollectStatic() async {
        guard let fw = frameworkInfo, fw.framework == .django else { return }
        do {
            let output = try await frameworkService.runDjangoCollectStatic(projectPath: "/var/www", serverId: serverId)
            GlobalToastManager.shared.showSuccess("Static files collected")
            print(output)
        } catch {
            GlobalToastManager.shared.showError("Collectstatic failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Package Actions

    private func updatePackage(_ name: String) async {
        do {
            try await packageService.updatePackage(name: name, serverId: serverId)
            GlobalToastManager.shared.showSuccess("\(name) updated")
            await loadPackages()
        } catch {
            GlobalToastManager.shared.showError("Update failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Venv Actions

    private func deleteVenv(_ venv: PythonVenvService.VenvInfo) async {
        do {
            try await venvService.deleteVenv(path: venv.path, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Virtual environment deleted")
            venvs.removeAll { $0.id == venv.id }
        } catch {
            GlobalToastManager.shared.showError("Delete failed: \(error.localizedDescription)")
        }
    }

    private func createVenv() async {
        isCreatingVenv = true
        defer { isCreatingVenv = false }

        do {
            try await venvService.createVenv(
                path: newVenvPath,
                name: newVenvName,
                serverId: serverId
            )
            GlobalToastManager.shared.showSuccess("Virtual environment '\(newVenvName)' created")
            showCreateVenvSheet = false

            // Refresh venv list
            venvs = (try? await venvService.listVenvs(projectPath: newVenvPath, serverId: serverId)) ?? []
        } catch {
            GlobalToastManager.shared.showError("Failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Process Actions

    private func reloadGunicorn() async {
        guard let status = gunicornStatus, let pid = status.masterPID else { return }
        do {
            try await processService.reloadGunicorn(serverId: serverId, masterPID: pid)
            GlobalToastManager.shared.showSuccess("Gunicorn reloaded (zero-downtime)")
            await loadProcesses()
        } catch {
            GlobalToastManager.shared.showError("Reload failed: \(error.localizedDescription)")
        }
    }

}
