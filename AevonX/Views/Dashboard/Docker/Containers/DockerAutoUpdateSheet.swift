
import SwiftUI
import AevonXCoreBridge

struct DockerAutoUpdateSheet: View {
    let container: DockerContainer
    let serverId: String
    var onComplete: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var updateStatus: ImageUpdateStatus?
    @State private var isChecking = true
    @State private var isUpdating = false
    @State private var createSnapshot = true
    @State private var progressMessage = ""
    @State private var progressValue: Double = 0
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    // Watchtower
    @State private var watchtowerRunning = false
    @State private var watchtowerSchedule = "0 0 4 * * *"
    @State private var watchtowerNotifyOnly = false
    @State private var isDeployingWatchtower = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Docker.autoUpdate)
                        .font(AXTypography.title2)
                        .foregroundColor(.axTextPrimary)
                    Text(container.names)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
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
                    // Update Check
                    AXCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Update Status", systemImage: "arrow.triangle.2.circlepath")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            if isChecking {
                                HStack {
                                    ProgressView().scaleEffect(0.7)
                                    Text("Checking for updates...")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                }
                            } else if let status = updateStatus {
                                HStack(spacing: AXSpacing.md) {
                                    Image(systemName: status.isOutdated ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(status.isOutdated ? .axWarning : .axSuccess)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(status.isOutdated ? "Update Available" : "Up to Date")
                                            .font(AXTypography.body)
                                            .foregroundColor(.axTextPrimary)
                                            .fontWeight(.medium)
                                        Text("Image: \(status.imageName)")
                                            .font(AXTypography.caption)
                                            .foregroundColor(.axTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if status.isOutdated {
                                        Button {
                                            updateNow()
                                        } label: {
                                            if isUpdating {
                                                ProgressView().scaleEffect(0.6)
                                            } else {
                                                Label("Update", systemImage: "arrow.down.circle")
                                                    .font(AXTypography.caption)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.axWarning)
                                        .foregroundColor(.white)
                                        .cornerRadius(AXCornerRadius.sm)
                                        .disabled(isUpdating)
                                    }
                                }
                                
                                Toggle("Create rollback snapshot before update", isOn: $createSnapshot)
                                    .font(AXTypography.caption)
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                            } else {
                                Text("Could not determine update status")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                            }
                        }
                    }
                    
                    // Progress
                    if isUpdating {
                        VStack(spacing: AXSpacing.sm) {
                            ProgressView(value: progressValue)
                                .progressViewStyle(.linear)
                            Text(progressMessage)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                        .padding()
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    
                    // Messages
                    if let error = errorMessage {
                        Text(error)
                            .font(AXTypography.caption)
                            .foregroundColor(.axError)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axError.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    
                    if let success = successMessage {
                        Text(success)
                            .font(AXTypography.caption)
                            .foregroundColor(.axSuccess)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axSuccess.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    
                    // Watchtower Section
                    AXCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Watchtower (Auto-Update Agent)", systemImage: "clock.arrow.2.circlepath")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Circle()
                                    .fill(watchtowerRunning ? Color.axSuccess : Color.axTextMuted)
                                    .frame(width: 8, height: 8)
                                Text(watchtowerRunning ? L10n.Status.running : "Not Running")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(watchtowerRunning ? .axSuccess : .axTextMuted)
                            }
                            
                            Text("Watchtower monitors your containers and automatically updates them when new images are available.")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                            
                            Toggle("Notify only (don't auto-update)", isOn: $watchtowerNotifyOnly)
                                .font(AXTypography.caption)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            
                            HStack {
                                if watchtowerRunning {
                                    Button {
                                        removeWatchtower()
                                    } label: {
                                        Label(L10n.Button.remove, systemImage: "trash")
                                            .font(AXTypography.caption)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.axError.opacity(0.15))
                                    .foregroundColor(.axError)
                                    .cornerRadius(AXCornerRadius.sm)
                                } else {
                                    Button {
                                        deployWatchtower()
                                    } label: {
                                        if isDeployingWatchtower {
                                            ProgressView().scaleEffect(0.6)
                                        } else {
                                            Label("Deploy Watchtower", systemImage: "play.fill")
                                                .font(AXTypography.caption)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.axAccentBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .disabled(isDeployingWatchtower)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 550, minHeight: 450)
        .background(Color.axBackground)
        .onAppear { checkUpdate(); checkWatchtower() }
    }
    
    private func checkUpdate() {
        Task {
            do {
                let statuses = try await DockerService.shared.checkAllImageUpdates(serverId: serverId)
                let match = statuses.first { $0.containerIds.contains(container.id) }
                await MainActor.run {
                    updateStatus = match
                    isChecking = false
                }
            } catch {
                await MainActor.run {
                    isChecking = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func updateNow() {
        isUpdating = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await DockerService.shared.updateContainerImage(
                    containerId: container.id,
                    serverId: serverId,
                    createSnapshot: createSnapshot,
                    progress: { msg, pct in
                        Task { @MainActor in
                            progressMessage = msg
                            progressValue = pct
                        }
                    }
                )
                await MainActor.run {
                    isUpdating = false
                    successMessage = "Container updated successfully ✅"
                    onComplete?()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func checkWatchtower() {
        Task {
            let running = try? await DockerService.shared.isWatchtowerRunning(serverId: serverId)
            await MainActor.run { watchtowerRunning = running ?? false }
        }
    }
    
    private func deployWatchtower() {
        isDeployingWatchtower = true
        Task {
            do {
                try await DockerService.shared.deployWatchtower(
                    notifyOnly: watchtowerNotifyOnly,
                    serverId: serverId
                )
                await MainActor.run {
                    watchtowerRunning = true
                    isDeployingWatchtower = false
                }
            } catch {
                await MainActor.run {
                    isDeployingWatchtower = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func removeWatchtower() {
        Task {
            try? await DockerService.shared.removeWatchtower(serverId: serverId)
            await MainActor.run { watchtowerRunning = false }
        }
    }
}
