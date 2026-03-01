
import SwiftUI
import AevonXCore

// MARK: - Docker Tools Tab

struct DockerToolsTab: View {
    let serverId: String
    
    @State private var selectedTool: ToolSection = .scheduler
    
    enum ToolSection: String, CaseIterable, Identifiable {
        case scheduler = "Scheduler"
        case secrets = "Secrets"
        case traffic = "Traffic"
        case dependencies = "Dependencies"
        case runToCompose = "Run→Compose"
        case envTemplates = "Env Templates"
        case profiles = "Profiles"
        case autoUpdate = "Auto-Update"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .scheduler: return "clock.badge.checkmark"
            case .secrets: return "key.fill"
            case .traffic: return "network"
            case .dependencies: return "point.3.connected.trianglepath.dotted"
            case .runToCompose: return "arrow.right.arrow.left"
            case .envTemplates: return "list.bullet.rectangle"
            case .profiles: return "square.and.arrow.up.on.square"
            case .autoUpdate: return "arrow.triangle.2.circlepath"
            }
        }
        
        var color: Color {
            switch self {
            case .scheduler: return .indigo
            case .secrets: return .yellow
            case .traffic: return .mint
            case .dependencies: return .pink
            case .runToCompose: return .orange
            case .envTemplates: return .cyan
            case .profiles: return .axAccentBlue
            case .autoUpdate: return .axSuccess
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            toolsSidebar
            
            Divider().background(Color.axBorder)
            
            // Content
            ScrollView {
                toolContent
                    .padding(AXSpacing.lg)
            }
        }
    }
    
    // MARK: - Sidebar
    
    private var toolsSidebar: some View {
        AXSidebarContainer(
            width: 200,
            header: {
                HStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.axAccentBlue)
                    Text("TOOLS")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.axTextMuted)
                        .tracking(1.5)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)
            },
            items: {
                ForEach(ToolSection.allCases) { tool in
                    AXSidebarRow(
                        icon: tool.icon,
                        title: tool.rawValue,
                        color: tool.color,
                        isSelected: selectedTool == tool,
                        action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedTool = tool
                            }
                        }
                    )
                }
            },
            footer: {
                Rectangle()
                    .fill(Color.axBorder.opacity(0.25))
                    .frame(height: 1)
                    .padding(.horizontal, 10)
                Text("Docker Tools v1.0")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.axTextMuted.opacity(0.5))
                    .padding(.vertical, 10)
            }
        )
    }
    
    // MARK: - Content Router
    
    @ViewBuilder
    private var toolContent: some View {
        switch selectedTool {
        case .scheduler:
            DockerSchedulerInline(serverId: serverId)
        case .secrets:
            DockerSecretsInline(serverId: serverId)
        case .traffic:
            DockerTrafficInline(serverId: serverId)
        case .dependencies:
            DockerDependenciesInline(serverId: serverId)
        case .runToCompose:
            DockerRunToComposeInline(serverId: serverId)
        case .envTemplates:
            DockerEnvTemplatesInline(serverId: serverId)
        case .profiles:
            DockerProfilesInline(serverId: serverId)
        case .autoUpdate:
            DockerAutoUpdateInline(serverId: serverId)
        }
    }
}

// MARK: - Scheduler Inline

private struct DockerSchedulerInline: View {
    let serverId: String
    @State private var jobs: [DockerManager.ScheduledAction] = []
    @State private var isLoading = true
    @State private var showAddForm = false
    @State private var selectedContainer = ""
    @State private var selectedAction = "restart"
    @State private var selectedSchedule = "0 3 * * *"
    @State private var containers: [DockerContainer] = []
    @State private var isAdding = false
    @State private var errorMessage: String?
    
    let cronPresets = [
        ("Every hour", "0 * * * *"),
        ("Every 6 hours", "0 */6 * * *"),
        ("Daily 3 AM", "0 3 * * *"),
        ("Weekly Sunday", "0 3 * * 0"),
    ]
    let actions = ["restart", "stop", "start"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Container Scheduler")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Schedule automatic container actions using cron")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Button { showAddForm.toggle() } label: {
                    Label("New Schedule", systemImage: "plus")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.indigo)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            
            if showAddForm {
                addForm
            }
            
            if isLoading {
                ProgressView("Loading schedules...").padding(20)
            } else if jobs.isEmpty {
                emptyView("No scheduled jobs", "Create your first scheduled container action above")
            } else {
                ForEach(Array(jobs.enumerated()), id: \.offset) { _, job in
                    jobRow(job)
                }
            }
            
            if let error = errorMessage {
                Text(error).font(.system(size: 11)).foregroundColor(.axError)
            }
        }
        .onAppear { load() }
    }
    
    private var addForm: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.md) {
                Picker("Container", selection: $selectedContainer) {
                    Text("Select...").tag("")
                    ForEach(containers, id: \.id) { c in
                        Text(c.names).tag(c.names)
                    }
                }
                .frame(width: 200)
                
                Picker("Action", selection: $selectedAction) {
                    Text("Restart").tag("restart")
                    Text("Stop").tag("stop")
                    Text("Start").tag("start")
                }
                .frame(width: 120)
            }
            
            HStack(spacing: 6) {
                Text("Cron:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                TextField("cron expression", text: $selectedSchedule)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .font(.system(size: 12, design: .monospaced))
                
                ForEach(cronPresets, id: \.1) { label, cron in
                    Button(label) { selectedSchedule = cron }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(selectedSchedule == cron ? .indigo : .axTextMuted)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(selectedSchedule == cron ? Color.indigo.opacity(0.1) : Color.axSurface)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Button("Add") { addSchedule() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(selectedContainer.isEmpty ? Color.axTextMuted : Color.indigo)
                    .cornerRadius(6)
                    .disabled(selectedContainer.isEmpty || isAdding)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }
    
    private func jobRow(_ job: DockerManager.ScheduledAction) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))
                .foregroundColor(.indigo)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(job.containerName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text("\(job.action) · \(job.schedule)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
            }
            
            Spacer()
            
            Button {
                deleteJob(job)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.axError)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private func load() {
        Task {
            containers = (try? await DockerManager.shared.getContainers(serverId: serverId, all: false)) ?? []
            jobs = (try? await DockerManager.shared.listScheduledActions(serverId: serverId)) ?? []
            await MainActor.run { isLoading = false }
        }
    }
    
    private func addSchedule() {
        isAdding = true
        Task {
            do {
                try await DockerManager.shared.scheduleContainerAction(
                    containerName: selectedContainer,
                    action: selectedAction,
                    schedule: selectedSchedule,
                    serverId: serverId
                )
                await MainActor.run { isAdding = false; showAddForm = false; load() }
            } catch {
                await MainActor.run { isAdding = false; errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func deleteJob(_ job: DockerManager.ScheduledAction) {
        Task {
            try? await DockerManager.shared.removeScheduledAction(containerName: job.containerName, action: job.action, serverId: serverId)
            await MainActor.run { load() }
        }
    }
}

// MARK: - Secrets Inline

private struct DockerSecretsInline: View {
    let serverId: String
    @State private var secrets: [DockerManager.DockerSecret] = []
    @State private var isLoading = true
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newValue = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Docker Secrets")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Manage sensitive data for containers (requires Swarm mode)")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Button { showAdd.toggle() } label: {
                    Label("New Secret", systemImage: "plus")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.yellow.opacity(0.8))
                .foregroundColor(.black)
                .cornerRadius(6)
            }
            
            if showAdd {
                HStack(spacing: AXSpacing.sm) {
                    TextField("Secret name", text: $newName)
                        .textFieldStyle(.roundedBorder).frame(width: 200)
                    SecureField("Secret value", text: $newValue)
                        .textFieldStyle(.roundedBorder).frame(width: 200)
                    Button("Create") { createSecret() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Color.yellow.opacity(0.8))
                        .cornerRadius(6)
                        .disabled(newName.isEmpty || newValue.isEmpty)
                }
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
            }
            
            if isLoading {
                ProgressView("Loading secrets...").padding(20)
            } else if secrets.isEmpty {
                emptyView("No secrets found", "Secrets require Docker Swarm mode to be initialized")
            } else {
                ForEach(secrets) { secret in
                    HStack {
                        Image(systemName: "key.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        Text(secret.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axTextPrimary)
                        Spacer()
                        Text(secret.createdAt)
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Button {
                            Task { try? await DockerManager.shared.deleteSecret(name: secret.name, serverId: serverId); load() }
                        } label: {
                            Image(systemName: "trash").font(.system(size: 11)).foregroundColor(.axError)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                }
            }
            
            if let error = errorMessage {
                Text(error).font(.system(size: 11)).foregroundColor(.axError)
            }
        }
        .onAppear { load() }
    }
    
    private func load() {
        Task {
            secrets = (try? await DockerManager.shared.listSecrets(serverId: serverId)) ?? []
            await MainActor.run { isLoading = false }
        }
    }
    
    private func createSecret() {
        Task {
            do {
                try await DockerManager.shared.createSecret(name: newName, value: newValue, serverId: serverId)
                await MainActor.run { newName = ""; newValue = ""; showAdd = false; load() }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
}

// MARK: - Traffic Inline

private struct DockerTrafficInline: View {
    let serverId: String
    @State private var stats: [DockerManager.ContainerNetworkStats] = []
    @State private var isLoading = true
    
    private var maxBytes: Int64 { max(stats.map { $0.rxBytes + $0.txBytes }.max() ?? 1, 1) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network Traffic")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Real-time network I/O per container")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Button { load() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }
            
            if isLoading {
                ProgressView("Loading traffic...").padding(20)
            } else if stats.isEmpty {
                emptyView("No traffic data", "Start some containers to see network statistics")
            } else {
                // Table
                VStack(spacing: 0) {
                    HStack {
                        Text("Container").frame(width: 150, alignment: .leading)
                        Text("Received").frame(width: 100, alignment: .trailing)
                        Text("Sent").frame(width: 100, alignment: .trailing)
                        Text("").frame(minWidth: 200)
                        Spacer()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)
                    
                    Divider()
                    
                    ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                        HStack {
                            Text(stat.containerName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.axTextPrimary)
                                .lineLimit(1)
                                .frame(width: 150, alignment: .leading)
                            
                            Text(formatBytes(stat.rxBytes))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axSuccess)
                                .frame(width: 100, alignment: .trailing)
                            
                            Text(formatBytes(stat.txBytes))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axAccentBlue)
                                .frame(width: 100, alignment: .trailing)
                            
                            // Bar
                            GeometryReader { geo in
                                HStack(spacing: 1) {
                                    Rectangle()
                                        .fill(Color.axSuccess.opacity(0.6))
                                        .frame(width: geo.size.width * CGFloat(stat.rxBytes) / CGFloat(maxBytes))
                                    Rectangle()
                                        .fill(Color.axAccentBlue.opacity(0.6))
                                        .frame(width: geo.size.width * CGFloat(stat.txBytes) / CGFloat(maxBytes))
                                }
                                .frame(height: 8)
                                .cornerRadius(4)
                                .frame(maxHeight: .infinity, alignment: .center)
                            }
                            .frame(minWidth: 200, minHeight: 20)
                            
                            Spacer()
                        }
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(index % 2 == 0 ? Color.axBackground : Color.axSurface.opacity(0.3))
                    }
                }
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.3)))
            }
        }
        .onAppear { load() }
    }
    
    private func load() {
        isLoading = true
        Task {
            stats = (try? await DockerManager.shared.getNetworkTrafficStats(serverId: serverId)) ?? []
            await MainActor.run { isLoading = false }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .binary)
    }
}

// MARK: - Dependencies Inline

private struct DockerDependenciesInline: View {
    let serverId: String
    @State private var deps: [DockerManager.ContainerDependency] = []
    @State private var isLoading = true
    
    private var containerNames: [String] {
        var names = Set<String>()
        deps.forEach { names.insert($0.sourceContainer); names.insert($0.targetContainer) }
        return names.sorted()
    }
    
    private let nodeColors: [Color] = [.axAccentBlue, .axSuccess, .purple, .orange, .cyan, .pink, .mint, .indigo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Container Dependencies")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Shared networks and volumes between containers")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Button { load() } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 11)).foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }
            
            if isLoading {
                ProgressView("Detecting dependencies...").padding(20)
            } else if deps.isEmpty {
                emptyView("No dependencies", "Containers sharing networks or volumes will appear here")
            } else {
                // Nodes
                let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(containerNames.enumerated()), id: \.offset) { idx, name in
                        HStack(spacing: 6) {
                            Circle().fill(nodeColors[idx % nodeColors.count]).frame(width: 8, height: 8)
                            Text(name).font(.system(size: 11, weight: .medium)).foregroundColor(.axTextPrimary).lineLimit(1)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(nodeColors[idx % nodeColors.count].opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Connections
                ForEach(Array(deps.enumerated()), id: \.offset) { _, dep in
                    HStack(spacing: AXSpacing.sm) {
                        Text(dep.sourceContainer).font(.system(size: 11, weight: .medium)).foregroundColor(.axTextPrimary)
                        Image(systemName: "arrow.left.and.right").font(.system(size: 10)).foregroundColor(.axTextMuted)
                        Text(dep.dependencyType).font(.system(size: 10)).foregroundColor(.axAccentBlue)
                        Image(systemName: "arrow.left.and.right").font(.system(size: 10)).foregroundColor(.axTextMuted)
                        Text(dep.targetContainer).font(.system(size: 11, weight: .medium)).foregroundColor(.axTextPrimary)
                        Spacer()
                    }
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(6)
                }
            }
        }
        .onAppear { load() }
    }
    
    private func load() {
        isLoading = true
        Task {
            deps = (try? await DockerManager.shared.detectContainerDependencies(serverId: serverId)) ?? []
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Run→Compose Inline

private struct DockerRunToComposeInline: View {
    let serverId: String
    @State private var runCommand = ""
    @State private var composeOutput = ""
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Run → Compose Converter")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Text("Convert a docker run command to docker-compose.yml")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)
            }
            
            TextEditor(text: $runCommand)
                .font(.system(size: 12, design: .monospaced))
                .frame(minHeight: 70)
                .padding(8)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder))
            
            HStack {
                Button {
                    composeOutput = DockerManager.shared.convertRunToCompose(runCommand: runCommand)
                } label: {
                    Label("Convert", systemImage: "arrow.right.arrow.left")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(runCommand.isEmpty ? Color.axSurface : Color.orange)
                .foregroundColor(runCommand.isEmpty ? .axTextMuted : .white)
                .cornerRadius(6)
                .disabled(runCommand.isEmpty)
                
                Spacer()
            }
            
            if !composeOutput.isEmpty {
                HStack {
                    Text("docker-compose.yml").font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(composeOutput, forType: .string)
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
                    } label: {
                        Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isCopied ? .axSuccess : .axTextSecondary)
                }
                
                Text(composeOutput)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(AXCornerRadius.sm)
            }
        }
    }
}

// MARK: - Env Templates Inline

private struct DockerEnvTemplatesInline: View {
    let serverId: String
    @State private var templates: [DockerManager.EnvTemplate] = []
    @State private var isLoading = true
    @State private var showAdd = false
    @State private var tName = ""
    @State private var tDesc = ""
    @State private var tVars = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Environment Templates")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Save and reuse environment variable sets")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Button { showAdd.toggle() } label: {
                    Label("New", systemImage: "plus")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.cyan)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            
            if showAdd {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: AXSpacing.sm) {
                        TextField("Template name", text: $tName).textFieldStyle(.roundedBorder).frame(width: 200)
                        TextField("Description", text: $tDesc).textFieldStyle(.roundedBorder)
                    }
                    Text("Variables (KEY=VALUE, one per line)").font(.system(size: 10)).foregroundColor(.axTextMuted)
                    TextEditor(text: $tVars).font(.system(size: 11, design: .monospaced)).frame(height: 80)
                        .padding(6).background(Color.axSurface).cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.axBorder))
                    HStack {
                        Spacer()
                        Button("Save") { saveTemplate() }
                            .buttonStyle(.plain).font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 5)
                            .background(tName.isEmpty ? Color.axTextMuted : Color.cyan).cornerRadius(6)
                            .disabled(tName.isEmpty)
                    }
                }
                .padding(AXSpacing.md).background(Color.axSurface).cornerRadius(AXCornerRadius.md)
            }
            
            if isLoading {
                ProgressView("Loading...").padding(20)
            } else if templates.isEmpty {
                emptyView("No templates", "Save env var sets for quick reuse across containers")
            } else {
                ForEach(templates) { t in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(t.name).font(.system(size: 12, weight: .semibold)).foregroundColor(.axTextPrimary)
                            Text(t.description).font(.system(size: 11)).foregroundColor(.axTextSecondary)
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(t.variables.joined(separator: "\n"), forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc").font(.system(size: 10)).foregroundColor(.axAccentBlue)
                            }.buttonStyle(.plain)
                            Button {
                                Task { try? await DockerManager.shared.deleteEnvTemplate(id: t.id, serverId: serverId); load() }
                            } label: {
                                Image(systemName: "trash").font(.system(size: 10)).foregroundColor(.axError)
                            }.buttonStyle(.plain)
                        }
                        HStack(spacing: 4) {
                            ForEach(t.variables.prefix(3), id: \.self) { v in
                                Text(v).font(.system(size: 9, design: .monospaced)).foregroundColor(.axTextMuted)
                                    .padding(.horizontal, 6).padding(.vertical, 2).background(Color.axSurface).cornerRadius(4)
                            }
                            if t.variables.count > 3 {
                                Text("+\(t.variables.count - 3)").font(.system(size: 9)).foregroundColor(.axTextMuted)
                            }
                        }
                    }
                    .padding(AXSpacing.md).background(Color.axSurface).cornerRadius(AXCornerRadius.sm)
                }
            }
            if let error = errorMessage { Text(error).font(.system(size: 11)).foregroundColor(.axError) }
        }
        .onAppear { load() }
    }
    
    private func load() {
        Task {
            templates = (try? await DockerManager.shared.listEnvTemplates(serverId: serverId)) ?? []
            await MainActor.run { isLoading = false }
        }
    }
    
    private func saveTemplate() {
        let vars = tVars.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        Task {
            do {
                try await DockerManager.shared.saveEnvTemplate(DockerManager.EnvTemplate(name: tName, description: tDesc, variables: vars), serverId: serverId)
                await MainActor.run { tName = ""; tDesc = ""; tVars = ""; showAdd = false; load() }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
}

// MARK: - Profiles Inline

private struct DockerProfilesInline: View {
    let serverId: String
    @State private var exportedJSON = ""
    @State private var importJSON = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var isCopied = false
    @State private var progressMsg = ""
    @State private var progressVal: Double = 0
    @State private var successMsg: String?
    @State private var errorMsg: String?
    @State private var mode: Mode = .export
    
    enum Mode: String, CaseIterable { case export = "Export"; case `import` = "Import" }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Export / Import")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Export all container configs as JSON or import to recreate")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            
            if mode == .export {
                Button {
                    exportProfile()
                } label: {
                    Label(isExporting ? "Exporting..." : "Export Profile", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Color.axAccentBlue)
                .foregroundColor(.white)
                .cornerRadius(6)
                .disabled(isExporting)
                
                if !exportedJSON.isEmpty {
                    HStack {
                        Text("Exported JSON").font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(exportedJSON, forType: .string)
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
                        } label: {
                            Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(isCopied ? .axSuccess : .axTextSecondary)
                    }
                    ScrollView {
                        Text(exportedJSON)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(8).frame(maxHeight: 200)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(AXCornerRadius.sm)
                }
            } else {
                TextEditor(text: $importJSON)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(minHeight: 120)
                    .padding(6).background(Color.axSurface).cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.axBorder))
                
                if isImporting {
                    VStack(spacing: 4) {
                        ProgressView(value: progressVal).progressViewStyle(.linear)
                        Text(progressMsg).font(.system(size: 10)).foregroundColor(.axTextSecondary)
                    }
                }
                
                Button { importProfile() } label: {
                    Label(isImporting ? "Importing..." : "Import Profile", systemImage: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(importJSON.isEmpty ? Color.axSurface : Color.axWarning)
                .foregroundColor(importJSON.isEmpty ? .axTextMuted : .white)
                .cornerRadius(6)
                .disabled(importJSON.isEmpty || isImporting)
            }
            
            if let s = successMsg { Text(s).font(.system(size: 11)).foregroundColor(.axSuccess) }
            if let e = errorMsg { Text(e).font(.system(size: 11)).foregroundColor(.axError) }
        }
    }
    
    private func exportProfile() {
        isExporting = true; errorMsg = nil
        Task {
            do {
                let json = try await DockerManager.shared.exportContainerProfile(serverId: serverId)
                await MainActor.run { exportedJSON = json; isExporting = false }
            } catch {
                await MainActor.run { isExporting = false; errorMsg = error.localizedDescription }
            }
        }
    }
    
    private func importProfile() {
        isImporting = true; errorMsg = nil; successMsg = nil
        Task {
            do {
                try await DockerManager.shared.importContainerProfile(json: importJSON, serverId: serverId) { msg, pct in
                    Task { @MainActor in progressMsg = msg; progressVal = pct }
                }
                await MainActor.run { isImporting = false; successMsg = "Profile imported ✅" }
            } catch {
                await MainActor.run { isImporting = false; errorMsg = error.localizedDescription }
            }
        }
    }
}

// MARK: - Auto Update Inline

private struct DockerAutoUpdateInline: View {
    let serverId: String
    @State private var updates: [DockerManager.ImageUpdateStatus] = []
    @State private var isChecking = false
    @State private var updatingId: String?
    @State private var watchtowerRunning = false
    @State private var isCheckingWT = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-Update Manager")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Check and apply container image updates")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Button {
                    checkUpdates()
                } label: {
                    HStack(spacing: 6) {
                        if isChecking { ProgressView().scaleEffect(0.5) }
                        else { Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 11)) }
                        Text(isChecking ? "Checking..." : "Check Updates")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.axSuccess)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.axSuccess.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(isChecking)
            }
            
            // Watchtower
            HStack {
                Image(systemName: "eye.fill")
                    .font(.system(size: 12))
                    .foregroundColor(watchtowerRunning ? .axSuccess : .axTextMuted)
                Text("Watchtower: ")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextPrimary)
                Text(watchtowerRunning ? "Running" : "Not Running")
                    .font(.system(size: 12))
                    .foregroundColor(watchtowerRunning ? .axSuccess : .axTextMuted)
                Spacer()
                Button {
                    toggleWatchtower()
                } label: {
                    Text(watchtowerRunning ? "Stop" : "Deploy")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(watchtowerRunning ? .axError : .axSuccess)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background((watchtowerRunning ? Color.axError : Color.axSuccess).opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            
            if updates.isEmpty && !isChecking {
                emptyView("No updates checked", "Click \"Check Updates\" to scan all images")
            } else {
                ForEach(Array(updates.enumerated()), id: \.offset) { _, info in
                    HStack {
                        Circle()
                            .fill(info.isOutdated ? Color.axWarning : Color.axSuccess)
                            .frame(width: 8, height: 8)
                        Text(info.containerNames.first ?? info.imageName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axTextPrimary)
                        Text(info.imageName)
                            .font(.system(size: 11)).foregroundColor(.axTextSecondary)
                        Spacer()
                        if info.isOutdated {
                            if updatingId == info.imageName {
                                ProgressView().scaleEffect(0.5)
                            } else {
                                Button("Update") {
                                    updateContainer(info)
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.axSuccess)
                                .cornerRadius(6)
                            }
                        } else {
                            Text("Up to date")
                                .font(.system(size: 10))
                                .foregroundColor(.axSuccess)
                        }
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                }
            }
            
            if let error = errorMessage { Text(error).font(.system(size: 11)).foregroundColor(.axError) }
        }
        .onAppear { checkWatchtower() }
    }
    
    private func checkUpdates() {
        isChecking = true
        Task {
            do {
                let u = try await DockerManager.shared.checkAllImageUpdates(serverId: serverId)
                await MainActor.run { updates = u; isChecking = false }
            } catch {
                await MainActor.run { isChecking = false; errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func updateContainer(_ info: DockerManager.ImageUpdateStatus) {
        updatingId = info.imageName
        Task {
            do {
                let containerId = info.containerIds.first ?? info.imageName
                try await DockerManager.shared.updateContainerImage(containerId: containerId, serverId: serverId, createSnapshot: true) { _, _ in }
                await MainActor.run { updatingId = nil; checkUpdates() }
            } catch {
                await MainActor.run { updatingId = nil; errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func checkWatchtower() {
        Task {
            watchtowerRunning = (try? await DockerManager.shared.isWatchtowerRunning(serverId: serverId)) ?? false
        }
    }
    
    private func toggleWatchtower() {
        Task {
            do {
                if watchtowerRunning {
                    try await DockerManager.shared.removeWatchtower(serverId: serverId)
                } else {
                    try await DockerManager.shared.deployWatchtower(serverId: serverId)
                }
                await MainActor.run { watchtowerRunning.toggle() }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
}

// MARK: - Empty View Helper

private func emptyView(_ title: String, _ subtitle: String) -> some View {
    VStack(spacing: AXSpacing.sm) {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.axTextSecondary)
        Text(subtitle)
            .font(.system(size: 12))
            .foregroundColor(.axTextMuted)
    }
    .frame(maxWidth: .infinity)
    .padding(30)
}
