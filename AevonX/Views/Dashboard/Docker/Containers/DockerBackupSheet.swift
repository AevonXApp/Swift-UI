
import SwiftUI
import AevonXCoreBridge

struct DockerBackupSheet: View {
    let container: DockerContainer
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var isBackingUp = false
    @State private var backupResult: ContainerBackup?
    @State private var existingBackups: [BackupEntry] = []
    @State private var isLoadingBackups = true
    @State private var progressMessage = ""
    @State private var progressValue: Double = 0
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Docker.backupRestore)
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
                    // Backup Now
                    AXCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.Docker.fullBackup)
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                Text(L10n.Docker.savesImageVolumesAndConfiguration)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextSecondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                startBackup()
                            } label: {
                                if isBackingUp {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Label("Backup Now", systemImage: "externaldrive.badge.plus")
                                        .font(AXTypography.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.axAccentBlue)
                            .foregroundColor(.white)
                            .cornerRadius(AXCornerRadius.sm)
                            .disabled(isBackingUp)
                        }
                    }
                    
                    // Progress
                    if isBackingUp {
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
                    
                    // Backup Result
                    if let result = backupResult {
                        AXCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Backup Complete ✅", systemImage: "checkmark.circle.fill")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axSuccess)
                                
                                HStack {
                                    statBadge("Image", value: result.imageSaved ? "✅" : "❌")
                                    statBadge("Config", value: result.configSaved ? "✅" : "❌")
                                    statBadge("Volumes", value: "\(result.volumesSaved)")
                                    statBadge("Size", value: result.totalSizeMB)
                                }
                                
                                Text("Path: \(result.backupPath)")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axTextMuted)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(AXTypography.caption)
                            .foregroundColor(.axError)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axError.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    
                    // Existing Backups
                    if isLoadingBackups {
                        ProgressView("Loading backups...")
                    } else if !existingBackups.isEmpty {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text(L10n.Docker.existingBackups)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            ForEach(existingBackups) { backup in
                                AXCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(backup.name)
                                                .font(AXTypography.body)
                                                .foregroundColor(.axTextPrimary)
                                            
                                            HStack(spacing: AXSpacing.sm) {
                                                if backup.hasImage {
                                                    Label("Image", systemImage: "photo")
                                                        .font(AXTypography.caption2)
                                                        .foregroundColor(.axSuccess)
                                                }
                                                if backup.hasConfig {
                                                    Label("Config", systemImage: "gearshape")
                                                        .font(AXTypography.caption2)
                                                        .foregroundColor(.axAccentBlue)
                                                }
                                                if backup.volumeCount > 0 {
                                                    Label("\(backup.volumeCount) vol", systemImage: "cylinder")
                                                        .font(AXTypography.caption2)
                                                        .foregroundColor(.purple)
                                                }
                                                Text(backup.size)
                                                    .font(AXTypography.caption2)
                                                    .foregroundColor(.axTextMuted)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            deleteBackup(backup)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 12))
                                                .foregroundColor(.axError)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color.axBackground)
        .onAppear { loadBackups() }
    }
    
    @ViewBuilder
    private func statBadge(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AXTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private func startBackup() {
        isBackingUp = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await DockerService.shared.backupContainer(
                    containerId: container.id,
                    serverId: serverId,
                    progress: { msg, pct in
                        Task { @MainActor in
                            progressMessage = msg
                            progressValue = pct
                        }
                    }
                )
                await MainActor.run {
                    backupResult = result
                    isBackingUp = false
                    loadBackups()
                }
            } catch {
                await MainActor.run {
                    isBackingUp = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadBackups() {
        isLoadingBackups = true
        Task {
            do {
                let backups = try await DockerService.shared.listBackups(serverId: serverId)
                await MainActor.run {
                    existingBackups = backups
                    isLoadingBackups = false
                }
            } catch {
                await MainActor.run {
                    isLoadingBackups = false
                }
            }
        }
    }
    
    private func deleteBackup(_ backup: BackupEntry) {
        Task {
            try? await DockerService.shared.deleteBackup(backupPath: backup.path, serverId: serverId)
            await MainActor.run {
                existingBackups.removeAll { $0.id == backup.id }
            }
        }
    }
}
