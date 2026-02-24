
import SwiftUI
import AevonXCore

struct DockerOverviewTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    
    @State private var dockerInfo: DockerInfo?
    @State private var serviceStatus: AevonXCore.ServiceStatus = .unknown
    @State private var cpuUsage: Double = 0
    @State private var memoryUsage: Double = 0
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var recentEvents: [(time: String, type: String, action: String, actor: String)] = []
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Service Status Card
            AXCard {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Docker Engine")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            
                            Text(statusText)
                                .font(AXTypography.subheadline)
                                .foregroundColor(statusColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: AXSpacing.sm) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button(action: refreshData) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                    .foregroundColor(.axTextSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help("Refresh")
                            
                            Button(action: { toggleService() }) {
                                Image(systemName: serviceStatus == .active ? "stop.fill" : "play.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(serviceStatus == .active ? .axError : .axSuccess)
                                    .frame(width: 32, height: 32)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(serviceStatus == .active ? "Stop Service" : "Start Service")
                        }
                    }
                }
            }
            
            if let error = errorMessage {
                AXCard {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.axError)
                        Text(error)
                            .foregroundColor(.axError)
                        Spacer()
                        Button(action: { errorMessage = nil }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
            }
            
            // Statistics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AXSpacing.md) {
                
                StatCard(
                    title: "Containers",
                    value: "\(dockerInfo?.containers ?? 0)",
                    subtitle: "\(dockerInfo?.containersRunning ?? 0) Running",
                    icon: "shippingbox.fill",
                    color: .axAccentBlue
                )
                
                StatCard(
                    title: "Images",
                    value: "\(dockerInfo?.images ?? 0)",
                    subtitle: "Available Locally",
                    icon: "photo.stack.fill",
                    color: .purple
                )
                
                StatCard(
                    title: "CPU Usage",
                    value: String(format: "%.1f%%", cpuUsage),
                    subtitle: "Docker Daemon",
                    icon: "cpu",
                    color: .orange
                )
                
                StatCard(
                    title: "Memory",
                    value: String(format: "%.1f MB", memoryUsage),
                    subtitle: "Docker Daemon",
                    icon: "memorychip",
                    color: .green
                )
            }
            
            // System Info
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("System Information")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    Divider()
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                        DockerInfoRow(label: "Docker Version", value: dockerInfo?.serverVersion ?? "Unknown")
                        DockerInfoRow(label: "API Version", value: "1.41+") 
                        DockerInfoRow(label: "OS Type", value: dockerInfo?.osType ?? "Unknown")
                        DockerInfoRow(label: "Architecture", value: dockerInfo?.architecture ?? "Unknown")
                        DockerInfoRow(label: "Kernel Version", value: dockerInfo?.kernelVersion ?? "Unknown")
                        DockerInfoRow(label: "Root Dir", value: dockerInfo?.dockerRootDir ?? "Unknown")
                    }
                }
            }
            
            // Recent Activity
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))
                        Text("Recent Activity")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Spacer()
                        Text("\(recentEvents.count) events")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                    
                    Divider()
                    
                    if recentEvents.isEmpty {
                        HStack {
                            Spacer()
                            Text("No recent events")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .padding(.vertical, AXSpacing.md)
                            Spacer()
                        }
                    } else {
                        ForEach(recentEvents.indices, id: \.self) { i in
                            let event = recentEvents[i]
                            HStack(spacing: AXSpacing.sm) {
                                Text(event.type)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(eventColor(event.type))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(eventColor(event.type).opacity(0.1))
                                    .cornerRadius(4)
                                    .frame(width: 75)
                                
                                Text(event.action)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(actionColor(event.action))
                                    .frame(width: 70, alignment: .leading)
                                
                                Text(event.actor)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.axTextSecondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(event.time)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.axTextMuted)
                            }
                            .padding(.vertical, 2)
                            
                            if i < recentEvents.count - 1 {
                                Divider().opacity(0.3)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            refreshData()
        }
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch serviceStatus {
        case .active: return .axSuccess
        case .inactive: return .axTextMuted
        case .failed: return .axError
        default: return .axWarning
        }
    }
    
    private var statusText: String {
        switch serviceStatus {
        case .active: return "Running"
        case .inactive: return "Stopped"
        case .failed: return "Failed"
        default: return "Unknown"
        }
    }
    
    private func eventColor(_ type: String) -> Color {
        switch type {
        case "container": return .axAccentBlue
        case "image": return .purple
        case "volume": return .orange
        case "network": return .green
        default: return .axTextPrimary
        }
    }
    
    private func actionColor(_ action: String) -> Color {
        switch action {
        case "start", "create": return .green
        case "stop", "kill", "die": return .red
        case "restart": return .orange
        case "pull", "push": return .axAccentBlue
        default: return .axTextSecondary
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
            
        Task {
            do {
                serviceStatus = try await DockerManager.shared.getServiceStatus(serverId: serverId)
                
                if serviceStatus == .active {
                    // Sequential but fault-tolerant — each call independent
                    dockerInfo = try? await DockerManager.shared.getDockerInfo(serverId: serverId)
                    cpuUsage = (try? await DockerManager.shared.getCPUUsage(serverId: serverId)) ?? 0
                    memoryUsage = (try? await DockerManager.shared.getMemoryUsage(serverId: serverId)) ?? 0
                    
                    // Fetch recent events (single call, no polling)
                    let since = Int(Date().timeIntervalSince1970) - 300
                    let until = Int(Date().timeIntervalSince1970)
                    let events = (try? await DockerManager.shared.getRecentEvents(since: since, until: until, serverId: serverId)) ?? []
                    recentEvents = events.prefix(10).map { e in
                        (time: String(e.timestamp.suffix(8)), type: e.type, action: e.action, actor: e.actor)
                    }
                }
            } catch {
                errorMessage = "Failed to fetch Docker data: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    private func toggleService() {
        isLoading = true
        Task {
            do {
                if serviceStatus == .active {
                    try await DockerManager.shared.stopService(serverId: serverId)
                } else {
                    try await DockerManager.shared.startService(serverId: serverId)
                }
                // Wait a bit then refresh
                try await Task.sleep(nanoseconds: 2_000_000_000)
                refreshData()
            } catch {
                errorMessage = "Failed to toggle service: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - Subviews

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 20))
                    Spacer()
                }
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                Text(subtitle)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
        }
    }
}

    private struct DockerInfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                Spacer()
                Text(value)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
                    .monospaced()
            }
        }
    }
