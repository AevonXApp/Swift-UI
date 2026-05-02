
import SwiftUI
import AevonXCoreBridge

struct DockerSystemPrune: View {
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: AppSettingsManager
    
    @State private var pruneAll = false
    @State private var pruneVolumes = false
    @State private var isPruning = false
    @State private var output: String = ""
    @State private var spaceReclaimed: String?
    @State private var errorMessage: String?
    @State private var showConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.axError)
                    Text(L10n.Docker.systemPrune)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
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
                    // Warning
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.axWarning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.Docker.thisWillRemoveUnusedDockerResources)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.axTextPrimary)
                            Text(L10n.Docker.stoppedContainersDanglingImagesUnusedNetworksAndBuildCacheWillBeRemoved)
                                .font(.system(size: 10))
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axWarning.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                    
                    // Options
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Toggle(isOn: $pruneAll) {
                            VStack(alignment: .leading) {
                                Text(L10n.Docker.removeAllUnusedImages)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.axTextPrimary)
                                Text(L10n.Docker.notJustDanglingImagesAddsAllFlag)
                                    .font(.system(size: 10))
                                    .foregroundColor(.axTextMuted)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Toggle(isOn: $pruneVolumes) {
                            VStack(alignment: .leading) {
                                Text(L10n.Docker.alsoPruneVolumes)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.axTextPrimary)
                                Text("⚠️ This will delete ALL unused volume data permanently!")
                                    .font(.system(size: 10))
                                    .foregroundColor(.axError)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                    
                    // Output
                    if !output.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.Docker.output)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.axTextMuted)
                            ScrollView {
                                Text(output)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(AXSpacing.sm)
                            .frame(maxHeight: 150)
                            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                            .cornerRadius(6)
                        }
                    }
                    
                    if let space = spaceReclaimed {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.axSuccess)
                            Text("Space reclaimed: \(space)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.axSuccess)
                        }
                        .padding(AXSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.axSuccess.opacity(0.08))
                        .cornerRadius(6)
                    }
                    
                    if let error = errorMessage {
                        HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                            .font(.system(size: 11)).foregroundColor(.axError)
                            .padding(AXSpacing.sm).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.axError.opacity(0.08)).cornerRadius(6)
                    }
                }
                .padding(AXSpacing.lg)
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button(action: {
                    if settings.shouldConfirm(for: SettingsKey.confirmDockerPrune) {
                        showConfirm = true
                    } else {
                        executePrune()
                    }
                }) {
                    HStack(spacing: 4) {
                        if isPruning { ProgressView().controlSize(.small) }
                        Image(systemName: "trash.fill").font(.system(size: 10))
                        Text(isPruning ? "Pruning..." : "Prune Now")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isPruning ? Color.gray : Color.axError)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(isPruning)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 500, height: 480)
        .background(Color.axBackground)
        .overlay {
            if showConfirm {
                AXDeleteConfirmation(
                    title: "Confirm System Prune",
                    itemName: "Docker Resources",
                    icon: "trash.circle.fill",
                    warning: "This will permanently remove unused Docker resources. This action cannot be undone.",
                    confirmLabel: "Prune",
                    onConfirm: {
                        showConfirm = false
                        executePrune()
                    },
                    onCancel: { showConfirm = false }
                )
            }
        }
    }
    
    private func executePrune() {
        isPruning = true; errorMessage = nil; spaceReclaimed = nil; output = ""
        Task {
            do {
                let result = try await DockerService.shared.systemPrune(all: pruneAll, volumes: pruneVolumes, serverId: serverId)
                
                await MainActor.run {
                    output = result
                    if let range = result.range(of: "Total reclaimed space:") {
                        spaceReclaimed = String(result[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        spaceReclaimed = "Completed"
                    }
                    isPruning = false
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription; isPruning = false }
            }
        }
    }
}
