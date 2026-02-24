
import SwiftUI
import AevonXCore

struct DockerResourceLimitsEditor: View {
    let container: DockerContainer
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var memoryMB: String = "512"
    @State private var cpus: String = "1.0"
    @State private var memorySwapMB: String = ""
    @State private var cpuShares: String = ""
    @State private var isApplying = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .foregroundColor(.orange)
                    Text("Resource Limits")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
                Text(container.names)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.axSurface)
                    .cornerRadius(4)
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Label("Memory Limit (MB)", systemImage: "memorychip")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                        TextField("512", text: $memoryMB)
                            .textFieldStyle(AXTextFieldStyle())
                        Text("0 = unlimited. Docker default is no limit.")
                            .font(.system(size: 9)).foregroundColor(.axTextMuted)
                    }
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Label("CPU Limit (cores)", systemImage: "cpu")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                        TextField("1.0", text: $cpus)
                            .textFieldStyle(AXTextFieldStyle())
                        Text("1.5 = 1.5 CPU cores. 0 = unlimited.")
                            .font(.system(size: 9)).foregroundColor(.axTextMuted)
                    }
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Label("Memory + Swap (MB)", systemImage: "arrow.triangle.swap")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                        TextField("Optional", text: $memorySwapMB)
                            .textFieldStyle(AXTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Label("CPU Shares (relative weight)", systemImage: "dial.low")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                        TextField("1024 (default)", text: $cpuShares)
                            .textFieldStyle(AXTextFieldStyle())
                    }
                    
                    if let error = errorMessage {
                        HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                            .font(.system(size: 11)).foregroundColor(.axError)
                            .padding(AXSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axError.opacity(0.08)).cornerRadius(6)
                    }
                    if let success = successMessage {
                        HStack(spacing: 6) { Image(systemName: "checkmark.circle.fill"); Text(success) }
                            .font(.system(size: 11)).foregroundColor(.axSuccess)
                            .padding(AXSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axSuccess.opacity(0.08)).cornerRadius(6)
                    }
                }
                .padding(AXSpacing.lg)
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button(action: applyLimits) {
                    HStack(spacing: 4) {
                        if isApplying { ProgressView().controlSize(.small) }
                        Text(isApplying ? "Applying..." : "Apply Limits")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(isApplying)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 450, height: 480)
        .background(Color.axBackground)
        .task { await loadCurrentLimits() }
    }
    
    private func loadCurrentLimits() async {
        do {
            let limits = try await DockerManager.shared.getContainerLimits(id: container.id, serverId: serverId)
            await MainActor.run {
                if limits.memoryMB > 0 { memoryMB = "\(limits.memoryMB)" }
                if limits.cpus > 0 { cpus = String(format: "%.1f", limits.cpus) }
                if limits.memorySwapMB > 0 { memorySwapMB = "\(limits.memorySwapMB)" }
                if limits.cpuShares > 0 { cpuShares = "\(limits.cpuShares)" }
            }
        } catch {}
    }
    
    private func applyLimits() {
        isApplying = true; errorMessage = nil; successMessage = nil
        Task {
            do {
                var flags: [String] = []
                if let mem = Int(memoryMB), mem > 0 { flags.append("--memory \(mem)m") }
                if let cpu = Double(cpus), cpu > 0 { flags.append("--cpus \(cpu)") }
                if let swap = Int(memorySwapMB), swap != 0 { flags.append("--memory-swap \(swap)m") }
                if let shares = Int(cpuShares), shares > 0 { flags.append("--cpu-shares \(shares)") }
                
                guard !flags.isEmpty else {
                    await MainActor.run { errorMessage = "No limits to apply"; isApplying = false }
                    return
                }
                
                try await DockerManager.shared.updateContainerLimits(
                    id: container.id, flags: flags, serverId: serverId
                )
                await MainActor.run { successMessage = "Resource limits updated"; isApplying = false }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isApplying = false }
            }
        }
    }
}
