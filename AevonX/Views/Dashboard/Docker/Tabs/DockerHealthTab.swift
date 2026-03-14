
import SwiftUI
import AevonXCoreBridge

struct DockerHealthTab: View {
    let serverId: String
    
    @State private var containers: [DockerContainer] = []
    @State private var healthStatus: [String: HealthInfo] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    struct HealthInfo {
        let status: String
        let failingStreak: Int
        let lastOutput: String
        
        var statusColor: Color {
            switch status.lowercased() {
            case "healthy": return .green
            case "unhealthy": return .red
            case "starting": return .orange
            default: return .gray
            }
        }
        
        var statusIcon: String {
            switch status.lowercased() {
            case "healthy": return "checkmark.circle.fill"
            case "unhealthy": return "xmark.circle.fill"
            case "starting": return "clock.fill"
            default: return "questionmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.md) {
            // Header
            HStack {
                Text("Health Check Dashboard")
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                // Summary
                HStack(spacing: AXSpacing.md) {
                    summaryBadge("Healthy", count: healthCount("healthy"), color: .green)
                    summaryBadge("Unhealthy", count: healthCount("unhealthy"), color: .red)
                    summaryBadge("No Check", count: healthCount("none"), color: .gray)
                }
                
                AXRefreshIconButton(isLoading: isLoading) {
                    await loadData()
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.top, AXSpacing.md)
            
            if isLoading && containers.isEmpty {
                AXLoadingState(message: "Checking container health...")
            } else if containers.isEmpty {
                AXPlaceholder(
                    icon: "heart.slash",
                    title: "No containers found"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AXSpacing.sm) {
                        ForEach(containers) { container in
                            healthRow(for: container)
                        }
                    }
                    .padding(.horizontal, AXSpacing.md)
                }
            }
        }
        .task { await loadData() }
    }
    
    // MARK: - Health Row
    
    private func healthRow(for container: DockerContainer) -> some View {
        let info = healthStatus[container.id]
        let status = info?.status ?? "none"
        let color = info?.statusColor ?? .gray
        let icon = info?.statusIcon ?? "questionmark.circle.fill"
        
        return AXCard {
            HStack(spacing: AXSpacing.md) {
                // Status
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                // Container info
                VStack(alignment: .leading, spacing: 2) {
                    Text(container.names)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    Text(container.image)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextSecondary)
                }
                
                Spacer()
                
                // Health status badge
                Text(status.capitalized)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)
                
                // Failing streak
                if let info = info, info.failingStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                        Text("\(info.failingStreak) failures")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(.red)
                }
                
                // Running status
                Circle()
                    .fill(container.isRunning ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 6, height: 6)
            }
            
            // Show last check output if unhealthy
            if let info = info, !info.lastOutput.isEmpty, status == "unhealthy" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Check Output:")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.axTextMuted)
                    Text(info.lastOutput)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.red.opacity(0.8))
                        .lineLimit(3)
                }
                .padding(.top, AXSpacing.xs)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func summaryBadge(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
        }
    }
    
    private func healthCount(_ status: String) -> Int {
        healthStatus.values.filter { $0.status.lowercased() == status }.count +
        (status == "none" ? containers.count - healthStatus.count : 0)
    }
    
    // MARK: - Load Data
    
    private func loadData() async {
        isLoading = true
        do {
            containers = try await DockerService.shared.getContainers(serverId: serverId, all: true)
            
            for container in containers where container.isRunning {
                if let info = try? await DockerService.shared.fetchContainerHealth(id: container.id, serverId: serverId) {
                    await MainActor.run {
                        healthStatus[container.id] = HealthInfo(
                            status: info.status,
                            failingStreak: info.failingStreak,
                            lastOutput: info.lastOutput
                        )
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
