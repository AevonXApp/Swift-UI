
import SwiftUI
import AevonXCoreBridge

struct DockerNetworkTrafficView: View {
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var stats: [ContainerNetworkStats] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var totalRx: Int64 { stats.reduce(0) { $0 + $1.rxBytes } }
    var totalTx: Int64 { stats.reduce(0) { $0 + $1.txBytes } }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Network Traffic", systemImage: "network")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                
                Button { loadStats() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
                
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)
            
            Divider()
            
            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    // Total summary
                    if !stats.isEmpty {
                        HStack(spacing: AXSpacing.md) {
                            trafficCard("Total Received", value: AXFormatter.formatBytes(totalRx), icon: "arrow.down.circle.fill", color: .axAccentBlue)
                            trafficCard("Total Sent", value: AXFormatter.formatBytes(totalTx), icon: "arrow.up.circle.fill", color: .axSuccess)
                            trafficCard("Containers", value: "\(stats.count)", icon: "shippingbox.fill", color: .purple)
                        }
                    }
                    
                    if isLoading {
                        ProgressView("Loading traffic data...").padding(30)
                    } else if stats.isEmpty {
                        VStack(spacing: AXSpacing.sm) {
                            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                                .font(.system(size: 32))
                                .foregroundColor(.axTextMuted)
                            Text(L10n.Docker.noNetworkData)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                        }
                        .padding(30)
                    } else {
                        // Per-container traffic
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text(L10n.Docker.perContainer)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            ForEach(stats) { stat in
                                AXCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(stat.containerName)
                                                .font(AXTypography.body)
                                                .foregroundColor(.axTextPrimary)
                                                .fontWeight(.medium)
                                            
                                            // Traffic bar
                                            let maxBytes = max(stats.map { $0.rxBytes + $0.txBytes }.max() ?? 1, 1)
                                            let pct = Double(stat.rxBytes + stat.txBytes) / Double(maxBytes)
                                            
                                            GeometryReader { geo in
                                                HStack(spacing: 0) {
                                                    let rxPct = stat.txBytes + stat.rxBytes > 0 ? Double(stat.rxBytes) / Double(stat.rxBytes + stat.txBytes) : 0.5
                                                    Rectangle()
                                                        .fill(Color.axAccentBlue)
                                                        .frame(width: geo.size.width * pct * rxPct)
                                                    Rectangle()
                                                        .fill(Color.axSuccess)
                                                        .frame(width: geo.size.width * pct * (1 - rxPct))
                                                }
                                                .cornerRadius(3)
                                            }
                                            .frame(height: 6)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.down")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.axAccentBlue)
                                                Text(stat.rxFormatted)
                                                    .font(AXTypography.caption)
                                                    .foregroundColor(.axTextSecondary)
                                                    .monospaced()
                                            }
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.up")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.axSuccess)
                                                Text(stat.txFormatted)
                                                    .font(AXTypography.caption)
                                                    .foregroundColor(.axTextSecondary)
                                                    .monospaced()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error).font(AXTypography.caption).foregroundColor(.axError)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 550, minHeight: 400)
        .background(Color.axBackground)
        .onAppear { loadStats() }
    }
    
    @ViewBuilder
    private func trafficCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        AXCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(value)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text(title)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
    
    
    private func loadStats() {
        isLoading = true
        Task {
            do {
                let s = try await DockerService.shared.getNetworkTrafficStats(serverId: serverId)
                await MainActor.run { stats = s; isLoading = false }
            } catch {
                await MainActor.run { isLoading = false; errorMessage = error.localizedDescription }
            }
        }
    }
}
