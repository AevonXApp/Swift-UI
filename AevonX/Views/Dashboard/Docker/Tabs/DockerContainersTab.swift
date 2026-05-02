
import SwiftUI
import AevonXCoreBridge

struct DockerContainersTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    
    @State private var containers: [DockerContainer] = []
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var showAll: Bool = true // Show all (including stopped) vs Running only
    @State private var errorMessage: String?
    @State private var actionInProgress: String? // ID of container being acted upon
    
    @State private var selectedContainerForLogs: DockerContainer?
    @State private var selectedContainerForTerminal: DockerContainer?
    
    @State private var showContainerWizard = false
    @State private var showTemplateDeploy = false
    @State private var selectedContainerForInspector: DockerContainer?
    @State private var selectedContainerForAILog: DockerContainer?
    @State private var selectedContainerForStats: DockerContainer?
    @State private var selectedContainerIds: Set<String> = []
    @State private var containerToRemove: String?
    @EnvironmentObject var settings: AppSettingsManager
    @State private var showRenameAlert = false
    @State private var renameContainerId: String = ""
    @State private var newContainerName: String = ""
    @State private var selectedContainerForLimits: DockerContainer?
    @State private var selectedContainerForRestart: DockerContainer?
    @State private var selectedContainerForDiff: DockerContainer?
    @State private var selectedContainerForDomain: DockerContainer?
    @State private var connectedDomains: [String: String] = [:] // containerId -> domain
    
    @State private var containerWorkingDir: String?
    
    // New Feature States
    @State private var selectedContainerForRollback: DockerContainer?
    @State private var selectedContainerForClone: DockerContainer?
    @State private var selectedContainerForSecurity: DockerContainer?
    @State private var selectedContainerForBackup: DockerContainer?
    
    // Filtered containers
    var filteredContainers: [DockerContainer] {
        var result = containers
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { 
                $0.names.localizedCaseInsensitiveContains(searchText) ||
                $0.image.localizedCaseInsensitiveContains(searchText) ||
                $0.id.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by status if needed (though we fetch all/running from API usually)
        if !showAll {
            result = result.filter { $0.isRunning }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.md) {
            // Toolbar
            HStack(spacing: AXSpacing.md) {
                // Search
                AXSearchBar(text: $searchText, placeholder: "Search containers...")
                
                Spacer()
                
                // Show All Toggle
                HStack(spacing: AXSpacing.sm) {
                    Toggle("Show All", isOn: $showAll)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                        .onChange(of: showAll) { old, new in refreshData() }
                    
                    Text(showAll ? "All" : L10n.Status.running)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 4)
                
                // Creation Buttons
                Button(action: { showContainerWizard = true }) {
                    Label(L10n.Docker.newContainer, systemImage: "plus")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                
                Button(action: { showTemplateDeploy = true }) {
                    Label(L10n.Docker.deployTemplate, systemImage: "square.stack.3d.up.fill")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.axAccentBlue)
                .foregroundColor(.white)
                .cornerRadius(AXCornerRadius.sm)
            }
            .padding(.horizontal, AXSpacing.sm)
            
            // Containers List
            if isLoading && containers.isEmpty {
                AXLoadingState(message: "Loading containers...")
            } else if filteredContainers.isEmpty {
                AXPlaceholder(
                    icon: "shippingbox",
                    title: "No containers found"
                )
            } else {
                VStack(spacing: 0) {
                    // Bulk Actions Bar
                    if !selectedContainerIds.isEmpty {
                        DockerBulkActionsBar(
                            selectedContainers: selectedContainerIds,
                            serverId: serverId,
                            onComplete: {
                                selectedContainerIds.removeAll()
                                refreshData()
                            }
                        )
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.bottom, AXSpacing.xs)
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: AXSpacing.sm) {
                            ForEach(filteredContainers) { container in
                                VStack(spacing: 0) {
                                    HStack(spacing: AXSpacing.sm) {
                                        // Selection checkbox
                                        Button(action: {
                                            if selectedContainerIds.contains(container.id) {
                                                selectedContainerIds.remove(container.id)
                                            } else {
                                                selectedContainerIds.insert(container.id)
                                            }
                                        }) {
                                            Image(systemName: selectedContainerIds.contains(container.id) ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 14))
                                                .foregroundColor(selectedContainerIds.contains(container.id) ? .axAccentBlue : .axTextMuted)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        ContainerRow(
                                            container: container,
                                            isActionInProgress: actionInProgress == container.id,
                                            connectedDomain: connectedDomains[container.id],
                                            onAction: { action in
                                                handleContainerAction(id: container.id, action: action)
                                            }
                                        )
                                    }
                                    .contextMenu {
                                        // Quick Actions Context Menu
                                        if container.isRunning {
                                            Button { handleContainerAction(id: container.id, action: "stop") } label: {
                                                Label(L10n.Button.stop, systemImage: "stop.fill")
                                            }
                                            Button { handleContainerAction(id: container.id, action: "restart") } label: {
                                                Label(L10n.Button.restart, systemImage: "arrow.clockwise")
                                            }
                                            Divider()
                                            Button { handleContainerAction(id: container.id, action: "logs") } label: {
                                                Label(L10n.Docker.viewLogs, systemImage: "text.alignleft")
                                            }
                                            Button { handleContainerAction(id: container.id, action: "terminal") } label: {
                                                Label(L10n.Docker.openTerminal, systemImage: "terminal.fill")
                                            }
                                            Button { handleContainerAction(id: container.id, action: "inspect") } label: {
                                                Label(L10n.Docker.inspect, systemImage: "doc.text.magnifyingglass")
                                            }
                                        } else {
                                            Button { handleContainerAction(id: container.id, action: "start") } label: {
                                                Label(L10n.Button.start, systemImage: "play.fill")
                                            }
                                        }
                                        Divider()
                                        Button { handleContainerAction(id: container.id, action: "rollback") } label: {
                                            Label(L10n.Docker.rollback, systemImage: "arrow.uturn.backward.circle")
                                        }
                                        Button { handleContainerAction(id: container.id, action: "clone") } label: {
                                            Label(L10n.Docker.clone, systemImage: "doc.on.doc")
                                        }
                                        Button { handleContainerAction(id: container.id, action: "backup") } label: {
                                            Label(L10n.Docker.backup, systemImage: "externaldrive.badge.plus")
                                        }
                                        Button { handleContainerAction(id: container.id, action: "security") } label: {
                                            Label(L10n.Docker.securityAudit, systemImage: "shield.checkered")
                                        }
                                        Button { handleContainerAction(id: container.id, action: "auto_update") } label: {
                                            Label(L10n.Docker.autoUpdate, systemImage: "arrow.triangle.2.circlepath")
                                        }
                                        Divider()
                                        Button { handleContainerAction(id: container.id, action: "rename") } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }
                                        Button { handleContainerAction(id: container.id, action: "diff") } label: {
                                            Label("Filesystem Changes", systemImage: "doc.badge.plus")
                                        }
                                        Button { handleContainerAction(id: container.id, action: "connect_domain") } label: {
                                            Label("Connect Domain", systemImage: "globe")
                                        }
                                        if !container.isRunning {
                                            Divider()
                                            Button(role: .destructive) { handleContainerAction(id: container.id, action: "remove") } label: {
                                                Label(L10n.Button.remove, systemImage: "trash")
                                            }
                                        }
                                    }

                                    // Inline stats for running containers
                                    if container.isRunning {
                                        DockerContainerStats(container: container, serverId: serverId)
                                            .padding(.leading, 30)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            refreshData()
        }
        .sheet(item: $selectedContainerForLogs) { container in
             DockerLogsView(
                 container: container,
                 serverId: serverId,
                 isPresented: Binding(
                     get: { selectedContainerForLogs != nil },
                     set: { if !$0 { selectedContainerForLogs = nil } }
                 )
             )
        }
        .sheet(item: $selectedContainerForTerminal) { container in
            DockerTerminalView(
                containerId: container.id,
                containerName: container.names,
                serverId: serverId,
                workingDir: containerWorkingDir,
                isPresented: Binding(
                    get: { selectedContainerForTerminal != nil },
                    set: { if !$0 { selectedContainerForTerminal = nil } }
                )
            )
        }
        .sheet(isPresented: $showContainerWizard) {
            DockerContainerWizard(serverId: serverId) {
                refreshData()
            }
        }
        .sheet(isPresented: $showTemplateDeploy) {
            DockerTemplateDeployView(serverId: serverId) {
                refreshData()
            }
        }
        .sheet(item: $selectedContainerForInspector) { container in
            DockerContainerInspector(
                container: container,
                serverId: serverId
            )
        }
        .sheet(item: $selectedContainerForAILog) { container in
            DockerAILogAnalyzer(
                container: container,
                serverId: serverId
            )
        }
        .sheet(item: $selectedContainerForLimits) { container in
            DockerResourceLimitsEditor(
                container: container,
                serverId: serverId
            )
        }
        .sheet(item: $selectedContainerForRestart) { container in
            DockerRestartPolicyEditor(
                container: container,
                serverId: serverId
            )
        }
        .sheet(item: $selectedContainerForDiff) { container in
            DockerContainerDiff(
                container: container,
                serverId: serverId
            )
        }
        .sheet(item: $selectedContainerForDomain) { container in
            DockerConnectDomainSheet(
                container: container,
                serverId: serverId,
                existingDomain: connectedDomains[container.id]
            )
        }
        .alert("Rename Container", isPresented: $showRenameAlert) {
            TextField("New name", text: $newContainerName)
            Button("Rename") {
                guard !newContainerName.isEmpty else { return }
                Task {
                    do {
                        try await DockerService.shared.renameContainer(
                            id: renameContainerId,
                            newName: newContainerName,
                            serverId: serverId
                        )
                        refreshData()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            Button(L10n.Button.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Docker.enterANewNameForThisContainer)
        }
        .sheet(item: $selectedContainerForRollback) { container in
            DockerRollbackSheet(container: container, serverId: serverId) {
                refreshData()
            }
        }
        .sheet(item: $selectedContainerForClone) { container in
            DockerCloneSheet(container: container, serverId: serverId) {
                refreshData()
            }
        }
        .sheet(item: $selectedContainerForSecurity) { container in
            DockerSecurityAuditView(container: container, serverId: serverId)
        }
        .sheet(item: $selectedContainerForBackup) { container in
            DockerBackupSheet(container: container, serverId: serverId)
        }
        .overlay {
            if let id = containerToRemove {
                AXDeleteConfirmation(
                    title: "Remove Container",
                    itemName: containers.first(where: { $0.id == id })?.names ?? id,
                    icon: "shippingbox",
                    warning: "This will permanently remove the container.",
                    confirmLabel: "Remove",
                    onConfirm: {
                        containerToRemove = nil
                        actionInProgress = id
                        Task {
                            do {
                                try await DockerService.shared.removeContainer(id: id, force: false, serverId: serverId)
                                refreshData()
                            } catch {
                                errorMessage = "Failed to remove container: \(error.localizedDescription)"
                            }
                            actionInProgress = nil
                        }
                    },
                    onCancel: { containerToRemove = nil }
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                containers = try await DockerService.shared.getContainers(serverId: serverId, all: showAll)
                
                // Load connected domains for running containers
                await loadConnectedDomains()
            } catch {
                errorMessage = "Failed to fetch containers: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func loadConnectedDomains() async {
        // Domain tracking is handled via UI state, not a DockerService query
        // Domains are shown when user explicitly connects them via DockerConnectDomainSheet
    }
    
    private func handleContainerAction(id: String, action: String) {
        // Intercept remove with confirmation
        if action == "remove" && settings.shouldConfirm(for: SettingsKey.confirmDeleteDockerContainer) {
            containerToRemove = id
            return
        }

        // Sheet-based actions (no progress indicator)
        if let container = containers.first(where: { $0.id == id }) {
            switch action {
            case "logs":
                selectedContainerForLogs = container
                return
            case "inspect":
                selectedContainerForInspector = container
                return
            case "ai_log":
                selectedContainerForAILog = container
                return
            case "rename":
                renameContainerId = id
                newContainerName = container.names
                showRenameAlert = true
                return
            case "limits":
                selectedContainerForLimits = container
                return
            case "restart_policy":
                selectedContainerForRestart = container
                return
            case "diff":
                selectedContainerForDiff = container
                return
            case "connect_domain":
                selectedContainerForDomain = container
                return
            case "rollback":
                selectedContainerForRollback = container
                return
            case "clone":
                selectedContainerForClone = container
                return
            case "security":
                selectedContainerForSecurity = container
                return
            case "backup":
                selectedContainerForBackup = container
                return
            default: break
            }
        }
        
        guard actionInProgress == nil else { return }
        actionInProgress = id
        
        Task {
            do {
                switch action {
                case "start":
                    try await DockerService.shared.startContainer(id: id, serverId: serverId)
                case "stop":
                    try await DockerService.shared.stopContainer(id: id, serverId: serverId)
                case "restart":
                    try await DockerService.shared.restartContainer(id: id, serverId: serverId)
                case "remove":
                    try await DockerService.shared.removeContainer(id: id, force: false, serverId: serverId)
                case "terminal":
                    if let container = containers.first(where: { $0.id == id }) {
                        containerWorkingDir = try? await DockerService.shared.getContainerWorkingDir(id: id, serverId: serverId)
                        selectedContainerForTerminal = container
                    }
                default:
                    break
                }
                
                // Refresh after action
                try await Task.sleep(nanoseconds: 1_000_000_000)
                refreshData()
                
            } catch {
                errorMessage = "Action failed: \(error.localizedDescription)"
            }
            
            actionInProgress = nil
        }
    }
}

// MARK: - Subviews

private struct ContainerRow: View {
    let container: DockerContainer
    let isActionInProgress: Bool
    let connectedDomain: String?
    let onAction: (String) -> Void
    
    var body: some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                // Status Icon
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .help(container.status)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(container.names)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    HStack(spacing: AXSpacing.sm) {
                        Label(container.image, systemImage: "photo")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                        
                        Text("•")
                            .foregroundColor(.axTextMuted)
                        
                        Text(container.shortId)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                            .monospaced()
                    }
                }
                
                Spacer()
                
                // Details (Ports / Created)
                VStack(alignment: .trailing, spacing: 4) {
                    if !container.ports.isEmpty {
                        Text(container.ports)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(1)
                            .frame(maxWidth: 200, alignment: .trailing)
                    }
                    
                    Text(container.created)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                
                // Actions
                HStack(spacing: AXSpacing.xs) {
                    if isActionInProgress {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 32)
                    } else {
                        if container.isRunning {
                            // 4 primary actions
                            ContainerActionButton(icon: "stop.fill", color: .axTextSecondary, hoverColor: .axError) {
                                onAction("stop")
                            }
                            .help(L10n.Button.stop)

                            ContainerActionButton(icon: "arrow.clockwise", color: .axTextSecondary, hoverColor: .axWarning) {
                                onAction("restart")
                            }
                            .help(L10n.Button.restart)

                            ContainerActionButton(icon: "text.alignleft", color: .axTextSecondary, hoverColor: .axAccentBlue) {
                                onAction("logs")
                            }
                            .help(L10n.Docker.viewLogs)

                            ContainerActionButton(icon: "terminal.fill", color: .axTextSecondary, hoverColor: .axSuccess) {
                                onAction("terminal")
                            }
                            .help(L10n.Docker.openTerminal)
                            
                            // Domain indicator
                            if let domain = connectedDomain {
                                ContainerActionButton(icon: "globe", color: .axSuccess, hoverColor: .axSuccess) {
                                    onAction("connect_domain")
                                }
                                .help("Domain: \(domain)")
                            }
                            
                            // More menu (AXActionMenu popover)
                            AXActionMenu.dockerContainerActions(
                                isRunning: container.isRunning,
                                hasDomain: connectedDomain != nil,
                                onInspect: { onAction("inspect") },
                                onAILog: { onAction("ai_log") },
                                onRename: { onAction("rename") },
                                onLimits: { onAction("limits") },
                                onRestartPolicy: { onAction("restart_policy") },
                                onDiff: { onAction("diff") },
                                onDomain: { onAction("connect_domain") },
                                onRollback: { onAction("rollback") },
                                onClone: { onAction("clone") },
                                onBackup: { onAction("backup") },
                                onRemove: container.isRunning ? nil : { onAction("remove") }
                            )
                            .frame(width: 32)
                        } else {
                            // Stopped container: Start + Logs + More
                            ContainerActionButton(icon: "play.fill", color: .axSuccess, hoverColor: .axSuccess) {
                                onAction("start")
                            }
                            .help(L10n.Button.start)

                            ContainerActionButton(icon: "text.alignleft", color: .axTextSecondary, hoverColor: .axAccentBlue) {
                                onAction("logs")
                            }
                            .help(L10n.Docker.viewLogs)

                            Menu {
                                Button { onAction("inspect") } label: {
                                    Label(L10n.Docker.inspect, systemImage: "doc.text.magnifyingglass")
                                }
                                Button { onAction("rename") } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button { onAction("rollback") } label: {
                                    Label(L10n.Docker.rollback, systemImage: "arrow.uturn.backward")
                                }
                                Button { onAction("clone") } label: {
                                    Label(L10n.Docker.clone, systemImage: "doc.on.doc")
                                }
                                Divider()
                                Button(role: .destructive) { onAction("remove") } label: {
                                    Label(L10n.Button.remove, systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14))
                                    .foregroundColor(.axTextSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.axSurface.opacity(0.5))
                                    .cornerRadius(AXCornerRadius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                            .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                                    )
                            }
                            .menuStyle(.borderlessButton)
                            .frame(width: 32)
                        }
                    }
                }
            }
        }
    }
    
    private var statusColor: Color {
        if container.status.lowercased().contains("up") { return .axSuccess }
        if container.status.lowercased().contains("exited") { return .axTextMuted }
        if container.status.lowercased().contains("paused") { return .axWarning }
        return .axTextSecondary
    }
}

    private struct ContainerActionButton: View {
        let icon: String
        let color: Color
        let hoverColor: Color
        let action: () -> Void
        
        @State private var isHovered = false
        
        var body: some View {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isHovered ? hoverColor : color)
                    .frame(width: 32, height: 32)
                    .background(Color.axSurface.opacity(0.5))
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
