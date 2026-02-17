
import SwiftUI
import AevonXCore

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
    
    @State private var showQuickCreate = false
    @State private var showTemplateDeploy = false
    
    @State private var containerWorkingDir: String?
    
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
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.axTextMuted)
                    TextField("Search containers...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                
                Spacer()
                
                // Show All Toggle
                HStack(spacing: 8) {
                    Toggle("Show All", isOn: $showAll)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                        .onChange(of: showAll) { old, new in refreshData() }
                    
                    Text(showAll ? "All" : "Running")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 4)
                
                // Creation Buttons
                Button(action: { showQuickCreate = true }) {
                    Label("Quick Create", systemImage: "plus")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                
                Button(action: { showTemplateDeploy = true }) {
                    Label("Deploy Template", systemImage: "square.stack.3d.up.fill")
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
                ProgressView("Loading containers...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredContainers.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 48))
                        .foregroundColor(.axTextMuted)
                    Text("No containers found")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.axSurface.opacity(0.3))
                .cornerRadius(AXCornerRadius.md)
            } else {
                ScrollView {
                    LazyVStack(spacing: AXSpacing.sm) {
                        ForEach(filteredContainers) { container in
                            ContainerRow(
                                container: container,
                                isActionInProgress: actionInProgress == container.id,
                                onAction: { action in
                                    if action == "logs" {
                                        selectedContainerForLogs = container
                                    } else if action == "terminal" {
                                        selectedContainerForTerminal = container
                                    } else {
                                        handleContainerAction(id: container.id, action: action)
                                    }
                                }
                            )
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
        .sheet(isPresented: $showQuickCreate) {
            DockerQuickCreateView(serverId: serverId) {
                refreshData()
            }
        }
        .sheet(isPresented: $showTemplateDeploy) {
            DockerTemplateDeployView(serverId: serverId) {
                refreshData()
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                containers = try await DockerManager.shared.getContainers(serverId: serverId, all: showAll)
            } catch {
                errorMessage = "Failed to fetch containers: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func handleContainerAction(id: String, action: String) {
        guard actionInProgress == nil else { return }
        actionInProgress = id
        
        Task {
            do {
                switch action {
                case "start":
                    try await DockerManager.shared.startContainer(id: id, serverId: serverId)
                case "stop":
                    try await DockerManager.shared.stopContainer(id: id, serverId: serverId)
                case "restart":
                    try await DockerManager.shared.restartContainer(id: id, serverId: serverId)
                case "remove":
                    try await DockerManager.shared.removeContainer(id: id, force: false, serverId: serverId)
                case "terminal":
                    if let container = containers.first(where: { $0.id == id }) {
                        containerWorkingDir = try? await DockerManager.shared.getContainerWorkingDir(id: id, serverId: serverId)
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
                    
                    HStack(spacing: 8) {
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
                            ContainerActionButton(icon: "stop.fill", color: .axTextSecondary, hoverColor: .axError) {
                                onAction("stop")
                            }
                            .help("Stop")
                            
                            ContainerActionButton(icon: "arrow.clockwise", color: .axTextSecondary, hoverColor: .axWarning) {
                                onAction("restart")
                            }
                            .help("Restart")
                            
                            ContainerActionButton(icon: "text.alignleft", color: .axTextSecondary, hoverColor: .axAccentBlue) {
                                onAction("logs")
                            }
                            .help("View Logs")
                            
                            ContainerActionButton(icon: "terminal.fill", color: .axTextSecondary, hoverColor: .axSuccess) {
                                onAction("terminal")
                            }
                            .help("Open Terminal")
                        } else {
                            ContainerActionButton(icon: "play.fill", color: .axSuccess, hoverColor: .axSuccess) {
                                onAction("start")
                            }
                            .help("Start")
                            
                            ContainerActionButton(icon: "text.alignleft", color: .axTextSecondary, hoverColor: .axAccentBlue) {
                                onAction("logs")
                            }
                            .help("View Logs")
                            
                            ContainerActionButton(icon: "trash", color: .axTextSecondary, hoverColor: .axError) {
                                onAction("remove")
                            }
                            .help("Remove")
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
