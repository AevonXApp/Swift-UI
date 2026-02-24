
import SwiftUI
import AevonXCore

struct DockerContainerStats: View {
    let container: DockerContainer
    let serverId: String
    
    @State private var stats: ContainerStats?
    @State private var cpuHistory: [Double] = []
    @State private var isLoading = true
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(spacing: AXSpacing.sm) {
            if isLoading && stats == nil {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(height: 60)
            } else if let stats = stats {
                HStack(spacing: AXSpacing.lg) {
                    // CPU
                    statBox(
                        icon: "cpu.fill",
                        label: "CPU",
                        value: String(format: "%.1f%%", stats.cpuPercent),
                        color: cpuColor(stats.cpuPercent),
                        sparkline: cpuHistory
                    )
                    
                    // Memory
                    statBox(
                        icon: "memorychip",
                        label: "Memory",
                        value: stats.memLimitMB > 0
                            ? String(format: "%.0fMB / %.0fMB", stats.memUsageMB, stats.memLimitMB)
                            : String(format: "%.0fMB", stats.memUsageMB),
                        color: memColor(stats.memPercent),
                        progress: stats.memPercent / 100
                    )
                    
                    // Network
                    statBox(
                        icon: "network",
                        label: "Net I/O",
                        value: String(format: "↓%.1fMB ↑%.1fMB", stats.netInputMB, stats.netOutputMB),
                        color: .axAccentBlue
                    )
                    
                    // PIDs
                    statBox(
                        icon: "list.number",
                        label: "PIDs",
                        value: "\(stats.pids)",
                        color: .purple
                    )
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.sm)
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }
    
    private func statBox(icon: String, label: String, value: String, color: Color, sparkline: [Double]? = nil, progress: Double? = nil) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.axTextMuted)
            }
            
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
            
            if let sparkline = sparkline, sparkline.count > 1 {
                miniSparkline(data: sparkline, color: color)
                    .frame(height: 16)
            }
            
            if let progress = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.axBorder)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                        Rectangle()
                            .fill(color)
                            .frame(width: geo.size.width * min(progress, 1.0), height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func miniSparkline(data: [Double], color: Color) -> some View {
        GeometryReader { geo in
            let maxVal = max(data.max() ?? 1, 1)
            Path { path in
                for (i, val) in data.enumerated() {
                    let x = CGFloat(i) / CGFloat(max(data.count - 1, 1)) * geo.size.width
                    let y = geo.size.height - (CGFloat(val / maxVal) * geo.size.height)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(color, lineWidth: 1.5)
        }
    }
    
    private func cpuColor(_ percent: Double) -> Color {
        if percent > 80 { return .red }
        if percent > 50 { return .orange }
        return .axSuccess
    }
    
    private func memColor(_ percent: Double) -> Color {
        if percent > 80 { return .red }
        if percent > 60 { return .orange }
        return .axAccentBlue
    }
    
    private func startPolling() {
        fetchStats()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            fetchStats()
        }
    }
    
    private func stopPolling() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func fetchStats() {
        Task {
            do {
                let newStats = try await DockerManager.shared.getContainerStats(id: container.id, serverId: serverId)
                await MainActor.run {
                    stats = newStats
                    cpuHistory.append(newStats.cpuPercent)
                    if cpuHistory.count > 20 { cpuHistory.removeFirst() }
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}
