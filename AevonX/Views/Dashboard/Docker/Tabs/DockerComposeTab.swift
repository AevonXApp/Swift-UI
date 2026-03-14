
import SwiftUI
import AevonXCoreBridge

struct DockerComposeTab: View {
    let serverId: String
    
    @State private var projects: [DockerComposeProject] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var actionInProgress: String?
    
    // For logs, editor, env, and scale
    @State private var showingLogsForProject: DockerComposeProject?
    @State private var showingEditorForProject: DockerComposeProject?
    @State private var showingEnvForProject: DockerComposeProject?
    @State private var showingScaleForProject: DockerComposeProject?
    @State private var showingValidatorForProject: DockerComposeProject?
    
    var body: some View {
        VStack(spacing: AXSpacing.md) {
            // Header
            HStack {
                Text("Docker Compose Projects")
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                AXRefreshIconButton(isLoading: isLoading) {
                    refreshData()
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.top, AXSpacing.md)
            
            // Error Message
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.axError)
                    Text(errorMessage)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                    Spacer()
                    Button(action: { self.errorMessage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.sm)
                .background(Color.axError.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
                .padding(.horizontal, AXSpacing.md)
            }
            
            // Content
            if isLoading && projects.isEmpty {
                AXLoadingState(message: "Loading projects...")
            } else if projects.isEmpty {
                AXPlaceholder(
                    icon: "square.stack.3d.up",
                    title: "No Compose projects found",
                    subtitle: "Projects are detected via 'docker compose ls'"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AXSpacing.sm) {
                        ForEach(projects) { project in
                            ComposeProjectRow(
                                project: project,
                                isActionInProgress: actionInProgress == project.name,
                                onAction: { action in
                                    handleProjectAction(project: project, action: action)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AXSpacing.md)
                }
            }
        }
        .onAppear {
            refreshData()
        }
        .sheet(item: $showingLogsForProject) { project in
            DockerComposeLogsView(
                project: project,
                serverId: serverId,
                isPresented: Binding(
                    get: { showingLogsForProject != nil },
                    set: { if !$0 { showingLogsForProject = nil } }
                )
            )
        }
        .sheet(item: $showingEditorForProject) { project in
            DockerComposeEditor(project: project, serverId: serverId)
        }
        .sheet(item: $showingEnvForProject) { project in
            DockerComposeEnvEditor(project: project, serverId: serverId)
        }
        .sheet(item: $showingScaleForProject) { project in
            DockerComposeScaleView(project: project, serverId: serverId)
        }
        .sheet(item: $showingValidatorForProject) { project in
            DockerComposeValidator(serverId: serverId, workingDir: project.workingDir)
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                projects = try await DockerService.shared.listComposeProjects(serverId: serverId)
            } catch {
                errorMessage = "Failed to fetch projects: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func handleProjectAction(project: DockerComposeProject, action: String) {
        guard actionInProgress == nil else { return }
        
        if action == "logs" {
            showingLogsForProject = project
            return
        }
        
        if action == "edit" {
            showingEditorForProject = project
            return
        }
        
        if action == "env" {
            showingEnvForProject = project
            return
        }
        
        if action == "scale" {
            showingScaleForProject = project
            return
        }
        
        if action == "validate" {
            showingValidatorForProject = project
            return
        }
        
        actionInProgress = project.name
        
        Task {
            do {
                switch action {
                case "up":
                    try await DockerService.shared.composeUp(workingDir: project.workingDir, serverId: serverId)
                case "down":
                    try await DockerService.shared.composeDown(workingDir: project.workingDir, serverId: serverId)
                case "restart":
                    try await DockerService.shared.composeRestart(workingDir: project.workingDir, serverId: serverId)
                default:
                    break
                }
                
                // Refresh after short delay
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

private struct ComposeProjectRow: View {
    let project: DockerComposeProject
    let isActionInProgress: Bool
    let onAction: (String) -> Void
    
    var body: some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                // Status Icon
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(project.configFiles)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                // Status Text
                Text(project.status)
                    .font(AXTypography.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(4)
                
                // Actions
                HStack(spacing: AXSpacing.xs) {
                    if isActionInProgress {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 32)
                    } else {
                        ComposeActionButton(icon: "play.fill", color: .axTextSecondary, hoverColor: .axSuccess) {
                            onAction("up")
                        }
                        .help("Up")
                        
                        ComposeActionButton(icon: "stop.fill", color: .axTextSecondary, hoverColor: .axError) {
                            onAction("down")
                        }
                        .help("Down")
                        
                        ComposeActionButton(icon: "arrow.clockwise", color: .axTextSecondary, hoverColor: .axWarning) {
                            onAction("restart")
                        }
                        .help("Restart")
                        
                        ComposeActionButton(icon: "text.alignleft", color: .axTextSecondary, hoverColor: .axAccentBlue) {
                            onAction("logs")
                        }
                        .help("Logs")
                        
                        ComposeActionButton(icon: "pencil", color: .axTextSecondary, hoverColor: .purple) {
                            onAction("edit")
                        }
                        .help("Edit Compose File")
                        
                        ComposeActionButton(icon: "key.fill", color: .axTextSecondary, hoverColor: .orange) {
                            onAction("env")
                        }
                        .help("Environment")
                        
                        ComposeActionButton(icon: "arrow.up.left.and.arrow.down.right", color: .axTextSecondary, hoverColor: .axAccentBlue) {
                            onAction("scale")
                        }
                        .help("Scale")
                        
                        ComposeActionButton(icon: "checkmark.shield", color: .axTextSecondary, hoverColor: .axSuccess) {
                            onAction("validate")
                        }
                        .help("Validate")
                    }
                }
            }
        }
    }
    
    private var statusColor: Color {
        if project.status.lowercased().contains("running") { return .axSuccess }
        if project.status.lowercased().contains("exited") { return .axTextMuted }
        return .axWarning
    }
}

// MARK: - Compose Action Button

private struct ComposeActionButton: View {
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
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Helper Views

struct DockerComposeLogsView: View {
    let project: DockerComposeProject
    let serverId: String
    @Binding var isPresented: Bool
    
    @State private var logs: String = ""
    @State private var isConnected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Logs: \(project.name)")
                    .font(.headline)
                Spacer()
                if isConnected {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                }
                Button("Close") { isPresented = false }
            }
            .padding()
            .background(Color.axBackground)
            
            // Logs
            ScrollView {
                Text(logs)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.black)
        }
        .frame(width: 800, height: 600)
        .onAppear {
            startLogStream()
        }
    }
    
    private func startLogStream() {
        isConnected = true
        Task {
            do {
                let output = try await DockerService.shared.composeLogs(
                    workingDir: project.workingDir,
                    serverId: serverId
                )
                await MainActor.run {
                    self.logs = output
                }
            } catch {
                await MainActor.run {
                    self.logs += "\n[Error: \(error.localizedDescription)]"
                    self.isConnected = false
                }
            }
        }
    }
}
