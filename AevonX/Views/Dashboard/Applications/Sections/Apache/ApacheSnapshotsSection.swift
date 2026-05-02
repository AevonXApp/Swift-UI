//
//  ApacheSnapshotsSection.swift
//  AevonX
//
//  Apache config snapshot manager — create, restore, delete, diff.
//

import SwiftUI
import AevonXCoreBridge

struct ApacheSnapshotsSection: View {
    let serverId: String

    @State private var snapshots: [SnapshotItem] = []
    @State private var isLoading = true
    @State private var isCreating = false
    @State private var actionInProgress: String?

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let apacheRed = Color(red: 0.82, green: 0.13, blue: 0.16)

    struct SnapshotItem: Identifiable {
        let id: String
        let path: String
        let timestamp: String
        let size: String
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                AXSectionTitle(title: "Config Snapshots", icon: "clock.arrow.circlepath")
                Spacer()
                Button { Task { await createSnapshot() } } label: {
                    HStack(spacing: 4) {
                        if isCreating { ProgressView().scaleEffect(0.6) }
                        else { Image(systemName: "plus.circle.fill").font(.system(size: 12)) }
                        Text(L10n.Apps.createSnapshot).font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 5)
                    .background(apacheRed).cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle()).disabled(isCreating)
            }
            .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            Divider().background(Color.axBorder.opacity(0.3))

            if isLoading {
                Spacer(); ProgressView("Loading snapshots..."); Spacer()
            } else if snapshots.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 28)).foregroundColor(.axTextMuted)
                    Text(L10n.Apps.noSnapshotsYet).font(AXTypography.caption).foregroundColor(.axTextMuted)
                    Text(L10n.Apps.createASnapshotToBackupYourConfigBeforeChanges)
                        .font(.system(size: 11)).foregroundColor(.axTextMuted).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(snapshots) { snap in snapshotRow(snap) }
                    }.padding(AXSpacing.lg)
                }
            }
        }
        .task { await loadSnapshots() }
    }

    private func snapshotRow(_ snap: SnapshotItem) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "clock.fill").font(.system(size: 14)).foregroundColor(apacheRed)

            VStack(alignment: .leading, spacing: 2) {
                Text(snap.id).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    Text(snap.timestamp).font(.system(size: 10)).foregroundColor(.axTextMuted)
                    Text(snap.size).font(.system(size: 10)).foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            HStack(spacing: AXSpacing.sm) {
                actionButton("Restore", icon: "arrow.uturn.backward", color: .axAccentBlue) {
                    Task { await restoreSnapshot(snap.id) }
                }
                actionButton(L10n.Button.delete, icon: "trash", color: .axError) {
                    Task { await deleteSnapshot(snap.id) }
                }
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.15), lineWidth: 1))
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 9))
                Text(title).font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(color).padding(.horizontal, 6).padding(.vertical, 3)
            .background(color.opacity(0.08)).cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func loadSnapshots() async {
        isLoading = true
        let json = await bridge.listSnapshots(serverID: serverId, appID: "apache")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let raw = resp["data"] as? [[String: Any]] {
            snapshots = raw.map { s in
                SnapshotItem(id: s["id"] as? String ?? "", path: s["path"] as? String ?? "",
                             timestamp: s["timestamp"] as? String ?? "", size: s["size"] as? String ?? "")
            }
        }
        isLoading = false
    }

    private func createSnapshot() async {
        isCreating = true
        let json = await bridge.createSnapshot(serverID: serverId, appID: "apache")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true { toast.showSuccess("Snapshot created") }
        else { toast.showError("Failed to create snapshot") }
        isCreating = false
        await loadSnapshots()
    }

    private func restoreSnapshot(_ id: String) async {
        actionInProgress = id
        let json = await bridge.restoreSnapshot(serverID: serverId, appID: "apache", id: id)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true { toast.showSuccess("Snapshot restored") }
        else { toast.showError("Failed to restore snapshot") }
        actionInProgress = nil
    }

    private func deleteSnapshot(_ id: String) async {
        actionInProgress = id
        let json = await bridge.deleteSnapshot(serverID: serverId, appID: "apache", id: id)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true { toast.showSuccess("Snapshot deleted") }
        else { toast.showError("Failed to delete snapshot") }
        actionInProgress = nil
        await loadSnapshots()
    }
}
