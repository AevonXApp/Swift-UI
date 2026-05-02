
import SwiftUI
import AevonXCoreBridge

struct DockerContainerInspector: View {
    let container: DockerContainer
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var inspection: ContainerInspection?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab: InspectorTab = .environment
    @State private var showRawJSON = false
    
    enum InspectorTab: String, CaseIterable {
        case environment = "Environment"
        case mounts = "Mounts"
        case network = "Network"
        case labels = "Labels"
        case processes = "Processes"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(container.isRunning ? Color.axSuccess : Color.axTextMuted)
                            .frame(width: 8, height: 8)
                        Text(container.names)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                    Text("\(container.image) • \(container.shortId)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .monospaced()
                }
                Spacer()
                
                Button(action: { showRawJSON.toggle() }) {
                    Image(systemName: showRawJSON ? "list.bullet" : "curlybraces")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                        .padding(6)
                        .background(Color.axSurface)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help(showRawJSON ? "Show Details" : "Show Raw JSON")
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            if isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                    Text(L10n.Docker.inspectingContainer)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.axError)
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if showRawJSON {
                rawJSONView
            } else {
                // Tab bar
                HStack(spacing: 0) {
                    ForEach(InspectorTab.allCases, id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: selectedTab == tab ? .bold : .regular))
                                .foregroundColor(selectedTab == tab ? .axAccentBlue : .axTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedTab == tab ? Color.axAccentBlue.opacity(0.1) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axSurface.opacity(0.5))
                
                // Tab content
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        switch selectedTab {
                        case .environment: envView
                        case .mounts: mountsView
                        case .network: networkView
                        case .labels: labelsView
                        case .processes: processesView
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            }
        }
        .frame(width: 700, height: 550)
        .background(Color.axBackground)
        .task { await loadInspection() }
    }
    
    // MARK: - Tab Views
    
    private var envView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            sectionTitle("Environment Variables", count: inspection?.envVars.count ?? 0)
            
            if let envVars = inspection?.envVars, !envVars.isEmpty {
                ForEach(envVars, id: \.self) { env in
                    let parts = env.split(separator: "=", maxSplits: 1)
                    HStack(spacing: 0) {
                        Text(String(parts.first ?? ""))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.axAccentBlue)
                            .frame(minWidth: 150, alignment: .leading)
                        
                        Text("=")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextMuted)
                            .padding(.horizontal, 4)
                        
                        Text(String(parts.count > 1 ? parts[1] : ""))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, AXSpacing.sm)
                    .background(Color.axSurface.opacity(0.5))
                    .cornerRadius(4)
                }
            } else {
                emptyState("No environment variables")
            }
        }
    }
    
    private var mountsView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            sectionTitle("Volume Mounts", count: inspection?.mounts.count ?? 0)
            
            if let mounts = inspection?.mounts, !mounts.isEmpty {
                ForEach(mounts.indices, id: \.self) { i in
                    let mount = mounts[i]
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(mount.type, systemImage: mount.type == "bind" ? "folder.fill" : "cylinder.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.axAccentBlue)
                            
                            if !mount.mode.isEmpty {
                                Text(mount.mode)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.axTextMuted)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.axSurface)
                                    .cornerRadius(3)
                            }
                        }
                        
                        HStack(spacing: 6) {
                            Text(mount.source)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axTextSecondary)
                                .lineLimit(1)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                                .foregroundColor(.axTextMuted)
                            
                            Text(mount.destination)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .lineLimit(1)
                        }
                    }
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface.opacity(0.5))
                    .cornerRadius(AXCornerRadius.sm)
                }
            } else {
                emptyState("No volumes mounted")
            }
        }
    }
    
    private var networkView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            sectionTitle("Network Settings", count: inspection?.networkSettings.count ?? 0)
            
            if let nets = inspection?.networkSettings, !nets.isEmpty {
                ForEach(nets.indices, id: \.self) { i in
                    let net = nets[i]
                    VStack(alignment: .leading, spacing: 6) {
                        Text(net.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.axTextPrimary)
                        
                        HStack(spacing: AXSpacing.lg) {
                            infoField("IP", net.ipAddress)
                            infoField("Gateway", net.gateway)
                            infoField("MAC", net.macAddress)
                        }
                    }
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface.opacity(0.5))
                    .cornerRadius(AXCornerRadius.sm)
                }
            } else {
                emptyState("No network info")
            }
            
            if let restart = inspection?.restartPolicy, !restart.isEmpty {
                Divider().padding(.vertical, AXSpacing.xs)
                infoField("Restart Policy", restart)
            }
        }
    }
    
    private var labelsView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            sectionTitle("Labels", count: inspection?.labels.count ?? 0)
            
            if let labels = inspection?.labels, !labels.isEmpty {
                ForEach(Array(labels.keys.sorted()), id: \.self) { key in
                    HStack(spacing: 0) {
                        Text(key)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.purple)
                            .lineLimit(1)
                        
                        Text(" = ")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextMuted)
                        
                        Text(labels[key] ?? "")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, AXSpacing.sm)
                    .background(Color.axSurface.opacity(0.5))
                    .cornerRadius(4)
                }
            } else {
                emptyState("No labels")
            }
        }
    }
    
    private var processesView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            sectionTitle("Running Processes", count: inspection?.processes.count ?? 0)
            
            if let procs = inspection?.processes, !procs.isEmpty {
                // Header
                HStack {
                    Text("PID").frame(width: 60, alignment: .leading)
                    Text(L10n.Docker.user).frame(width: 80, alignment: .leading)
                    Text(L10n.Docker.command)
                    Spacer()
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.axTextSecondary)
                .padding(.horizontal, AXSpacing.sm)
                
                ForEach(procs.indices, id: \.self) { i in
                    HStack {
                        Text(procs[i].pid).frame(width: 60, alignment: .leading)
                        Text(procs[i].user).frame(width: 80, alignment: .leading)
                        Text(procs[i].command)
                        Spacer()
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .padding(.vertical, 3)
                    .padding(.horizontal, AXSpacing.sm)
                    .background(i % 2 == 0 ? Color.axSurface.opacity(0.3) : Color.clear)
                    .cornerRadius(4)
                }
            } else {
                emptyState("Container is not running")
            }
        }
    }
    
    private var rawJSONView: some View {
        ScrollView {
            Text(inspection?.rawJSON ?? "No data")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AXSpacing.md)
        }
        .background(Color.black.opacity(0.05))
    }
    
    // MARK: - Helpers
    
    private func sectionTitle(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.axTextPrimary)
            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
        }
    }
    
    private func infoField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.axTextMuted)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextPrimary)
        }
    }
    
    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(AXTypography.caption)
            .foregroundColor(.axTextMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.xl)
    }
    
    // MARK: - Load
    
    private func loadInspection() async {
        isLoading = true
        do {
            inspection = try await DockerService.shared.inspectContainer(id: container.id, serverId: serverId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
