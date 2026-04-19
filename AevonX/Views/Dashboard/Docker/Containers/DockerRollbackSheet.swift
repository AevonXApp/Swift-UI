
import SwiftUI
import AevonXCoreBridge

struct DockerRollbackSheet: View {
    let container: DockerContainer
    let serverId: String
    var onComplete: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var snapshots: [RollbackSnapshot] = []
    @State private var isLoading = true
    @State private var isCreatingSnapshot = false
    @State private var isRollingBack = false
    @State private var progressMessage = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Divider()
            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    createSnapshotCard
                    progressRow
                    messagesRow
                    snapshotsList
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color.axBackground)
        .onAppear { loadSnapshots() }
    }

    // MARK: - Header

    @ViewBuilder private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Docker.rollback).font(AXTypography.title2).foregroundColor(.axTextPrimary)
                Text(container.names).font(AXTypography.caption).foregroundColor(.axTextSecondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.axSurface)
    }

    // MARK: - Sections

    @ViewBuilder private var createSnapshotCard: some View {
        AXCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Snapshot").font(AXTypography.headline).foregroundColor(.axTextPrimary)
                    Text("Save current state before making changes").font(AXTypography.caption).foregroundColor(.axTextSecondary)
                }
                Spacer()
                Button { createSnapshot() } label: {
                    if isCreatingSnapshot { ProgressView().scaleEffect(0.7) }
                    else { Label("Snapshot", systemImage: "camera.fill").font(AXTypography.caption).fontWeight(.semibold) }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.axAccentBlue).foregroundColor(.white)
                .cornerRadius(AXCornerRadius.sm).disabled(isCreatingSnapshot)
            }
        }
    }

    @ViewBuilder private var progressRow: some View {
        if !progressMessage.isEmpty {
            HStack {
                ProgressView().scaleEffect(0.7)
                Text(progressMessage).font(AXTypography.caption).foregroundColor(.axTextSecondary)
            }
            .padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.axAccentBlue.opacity(0.1)).cornerRadius(AXCornerRadius.sm)
        }
    }

    @ViewBuilder private var messagesRow: some View {
        if let error = errorMessage {
            Text(error).font(AXTypography.caption).foregroundColor(.axError)
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axError.opacity(0.1)).cornerRadius(AXCornerRadius.sm)
        }
        if let success = successMessage {
            Text(success).font(AXTypography.caption).foregroundColor(.axSuccess)
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axSuccess.opacity(0.1)).cornerRadius(AXCornerRadius.sm)
        }
    }

    @ViewBuilder private var snapshotsList: some View {
        if isLoading {
            ProgressView("Loading snapshots...").padding()
        } else if snapshots.isEmpty {
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: "camera.metering.none").font(.system(size: 32)).foregroundColor(.axTextMuted)
                Text("No snapshots yet").font(AXTypography.body).foregroundColor(.axTextSecondary)
                Text("Create a snapshot to enable rollback").font(AXTypography.caption).foregroundColor(.axTextMuted)
            }
            .padding(.vertical, 20)
        } else {
            VStack(spacing: AXSpacing.sm) {
                Text("Available Snapshots").font(AXTypography.headline).foregroundColor(.axTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(snapshots) { snapshot in
                    AXCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(snapshot.snapshotTag).font(AXTypography.body).foregroundColor(.axTextPrimary).lineLimit(1)
                                Text(snapshot.createdAt).font(AXTypography.caption).foregroundColor(.axTextMuted)
                            }
                            Spacer()
                            Button { rollbackToSnapshot(snapshot) } label: {
                                Label(L10n.Docker.rollback, systemImage: "arrow.uturn.backward").font(AXTypography.caption).fontWeight(.semibold)
                            }
                            .buttonStyle(.plain).padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.axWarning).foregroundColor(.white).cornerRadius(AXCornerRadius.sm).disabled(isRollingBack)
                            Button { deleteSnapshot(snapshot) } label: {
                                Image(systemName: "trash").font(.system(size: 12)).foregroundColor(.axError)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private func loadSnapshots() {
        isLoading = true
        Task {
            do {
                let all = try await DockerService.shared.listRollbackSnapshots(serverId: serverId)
                let containerSnapshots = all.filter {
                    $0.containerName.lowercased() == container.names.lowercased().replacingOccurrences(of: "/", with: "")
                }
                await MainActor.run {
                    snapshots = containerSnapshots
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func createSnapshot() {
        isCreatingSnapshot = true
        errorMessage = nil
        successMessage = nil
        progressMessage = "Creating snapshot..."
        
        Task {
            do {
                let snapshot = try await DockerService.shared.createRollbackSnapshot(
                    containerId: container.id,
                    containerName: container.names,
                    serverId: serverId
                )
                await MainActor.run {
                    snapshots.insert(snapshot, at: 0)
                    isCreatingSnapshot = false
                    progressMessage = ""
                    successMessage = "Snapshot created successfully ✅"
                }
            } catch {
                await MainActor.run {
                    isCreatingSnapshot = false
                    progressMessage = ""
                    errorMessage = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func rollbackToSnapshot(_ snapshot: RollbackSnapshot) {
        isRollingBack = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await DockerService.shared.rollbackContainer(
                    containerId: container.id,
                    containerName: container.names,
                    snapshot: snapshot,
                    serverId: serverId,
                    progress: { msg in
                        Task { @MainActor in progressMessage = msg }
                    }
                )
                await MainActor.run {
                    isRollingBack = false
                    progressMessage = ""
                    successMessage = "Rollback completed ✅"
                    onComplete?()
                }
            } catch {
                await MainActor.run {
                    isRollingBack = false
                    progressMessage = ""
                    errorMessage = "Rollback failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteSnapshot(_ snapshot: RollbackSnapshot) {
        Task {
            do {
                try await DockerService.shared.deleteRollbackSnapshot(snapshotTag: snapshot.snapshotTag, serverId: serverId)
                await MainActor.run {
                    snapshots.removeAll { $0.id == snapshot.id }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
