
import SwiftUI
import AevonXCoreBridge

struct DockerRestartPolicyEditor: View {
    let container: DockerContainer
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPolicy: String = "no"
    @State private var selectedPolicy: String = "no"
    @State private var maxRetries: String = "5"
    @State private var isApplying = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    let policies = [
        ("no", "No", "Do not restart the container automatically"),
        ("always", "Always", "Always restart, even if stopped manually"),
        ("unless-stopped", "Unless Stopped", "Restart unless explicitly stopped"),
        ("on-failure", "On Failure", "Restart only on non-zero exit code"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(.orange)
                    Text(L10n.Docker.restartPolicy)
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
                    // Current policy
                    HStack(spacing: 6) {
                        Text(L10n.Docker.current)
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                        Text(currentPolicy)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    // Policy options
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(policies, id: \.0) { id, name, desc in
                            Button(action: { selectedPolicy = id }) {
                                HStack(spacing: AXSpacing.sm) {
                                    Image(systemName: selectedPolicy == id ? "circle.inset.filled" : "circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(selectedPolicy == id ? .axAccentBlue : .axTextMuted)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.axTextPrimary)
                                        Text(desc)
                                            .font(.system(size: 10))
                                            .foregroundColor(.axTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(id)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.axTextMuted)
                                }
                                .padding(AXSpacing.sm)
                                .background(selectedPolicy == id ? Color.axAccentBlue.opacity(0.05) : Color.axSurface.opacity(0.3))
                                .cornerRadius(AXCornerRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .stroke(selectedPolicy == id ? Color.axAccentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Max retries for on-failure
                    if selectedPolicy == "on-failure" {
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text(L10n.Docker.maxRetries)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextSecondary)
                            TextField("5", text: $maxRetries)
                                .textFieldStyle(AXTextFieldStyle())
                                .frame(width: 100)
                            Text(L10n.Docker.numberOfTimesToRetryBeforeGivingUpUnlimited)
                                .font(.system(size: 9))
                                .foregroundColor(.axTextMuted)
                        }
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
                Button(action: applyPolicy) {
                    HStack(spacing: 4) {
                        if isApplying { ProgressView().controlSize(.small) }
                        Text(isApplying ? "Applying..." : "Apply Policy")
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
        .task { await loadCurrentPolicy() }
    }
    
    private func loadCurrentPolicy() async {
        do {
            let info = try await DockerService.shared.getRestartPolicy(id: container.id, serverId: serverId)
            await MainActor.run {
                currentPolicy = info.name
                selectedPolicy = info.name
                maxRetries = "\(info.maxRetries)"
            }
        } catch {}
    }
    
    private func applyPolicy() {
        isApplying = true; errorMessage = nil; successMessage = nil
        Task {
            do {
                var policy = selectedPolicy
                if selectedPolicy == "on-failure", let retries = Int(maxRetries), retries > 0 {
                    policy = "on-failure:\(retries)"
                }
                
                try await DockerService.shared.updateRestartPolicy(id: container.id, policy: policy, serverId: serverId)
                await MainActor.run {
                    currentPolicy = selectedPolicy
                    successMessage = "Restart policy updated to '\(selectedPolicy)'"
                    isApplying = false
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isApplying = false }
            }
        }
    }
}
