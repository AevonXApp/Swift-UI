//
//  LiteSpeedSnapshotsSection.swift
//  AevonX
//
//  Config snapshots — create, restore, diff for LiteSpeed.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedSnapshotsSection: View {
    let serverId: String

    @State private var snapshots: [BridgeConfigSnapshot] = []
    @State private var isLoading = false
    @State private var isCreating = false
    @State private var diffText: String?
    @State private var diffSnapshotID: String?

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack {
                    AXSectionTitle(title: "Config Snapshots (\(snapshots.count))", icon: "clock.arrow.2.circlepath")
                    Spacer()
                    Button {
                        Task { await createSnapshot() }
                    } label: {
                        HStack(spacing: 4) {
                            if isCreating {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "plus.circle.fill").font(AXTypography.footnote)
                            }
                            Text("Create Snapshot")
                                .font(AXTypography.footnote).fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.md).padding(.vertical, 5)
                        .background(lsGreen)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isCreating)

                    AXRefreshButton(isLoading: isLoading) { await loadSnapshots() }
                }

                if isLoading && snapshots.isEmpty {
                    VStack { Spacer(); ProgressView("Loading snapshots..."); Spacer() }
                        .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xl)
                } else if snapshots.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Spacer()
                        Image(systemName: "clock.arrow.2.circlepath").font(AXTypography.largeTitle).foregroundColor(.axTextMuted.opacity(0.3))
                        Text("No snapshots yet").font(AXTypography.callout).foregroundColor(.axTextMuted)
                        Text("Create a snapshot to backup your current config").font(AXTypography.footnote).foregroundColor(.axTextMuted)
                        Spacer()
                    }.frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xl)
                } else {
                    ForEach(snapshots, id: \.id) { snap in
                        VStack(spacing: 0) {
                            HStack(spacing: AXSpacing.md) {
                                Image(systemName: "doc.badge.clock")
                                    .font(AXTypography.body)
                                    .foregroundColor(.indigo)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snap.id)
                                        .font(AXTypography.monoMd).fontWeight(.semibold)
                                        .foregroundColor(.axTextPrimary)
                                    HStack(spacing: AXSpacing.sm) {
                                        if !snap.timestamp.isEmpty {
                                            Text(snap.timestamp)
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextMuted)
                                        }
                                        if !snap.size.isEmpty {
                                            Text(snap.size)
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextMuted)
                                        }
                                    }
                                }

                                Spacer()

                                Button {
                                    Task { await diffSnapshot(snap.id) }
                                } label: {
                                    Text("Diff")
                                        .font(AXTypography.caption).fontWeight(.semibold)
                                        .foregroundColor(.axAccentBlue)
                                        .padding(.horizontal, AXSpacing.sm).padding(.vertical, 3)
                                        .background(Color.axAccentBlue.opacity(0.08))
                                        .cornerRadius(AXCornerRadius.sm)
                                }.buttonStyle(PlainButtonStyle())

                                Button {
                                    Task { await restoreSnapshot(snap.id) }
                                } label: {
                                    Text("Restore")
                                        .font(AXTypography.caption).fontWeight(.semibold)
                                        .foregroundColor(lsGreen)
                                        .padding(.horizontal, AXSpacing.sm).padding(.vertical, 3)
                                        .background(lsGreen.opacity(0.08))
                                        .cornerRadius(AXCornerRadius.sm)
                                }.buttonStyle(PlainButtonStyle())

                                Button {
                                    Task { await deleteSnapshot(snap.id) }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axError)
                                        .padding(4)
                                        .background(Color.axError.opacity(0.08))
                                        .cornerRadius(AXCornerRadius.sm)
                                }.buttonStyle(PlainButtonStyle())
                            }
                            .padding(AXSpacing.md)

                            // Diff viewer
                            if diffSnapshotID == snap.id, let diff = diffText {
                                Divider().background(Color.axBorder.opacity(0.2))
                                ScrollView(.horizontal) {
                                    Text(diff)
                                        .font(AXTypography.monoSm)
                                        .foregroundColor(.axTextPrimary)
                                        .textSelection(.enabled)
                                        .padding(AXSpacing.md)
                                }
                                .frame(maxHeight: 300)
                                .background(Color.axBackground)
                            }
                        }
                        .background(Color.axSurface.opacity(0.3))
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.1), lineWidth: 1))
                    }
                }

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadSnapshots() }
    }

    private func loadSnapshots() async {
        isLoading = true
        let json = await bridge.listSnapshots(serverID: serverId, appID: "litespeed")
        if let data = json.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeDataResponse<[BridgeConfigSnapshot]>.self, from: data),
           resp.success {
            snapshots = resp.data ?? []
        }
        isLoading = false
    }

    private func createSnapshot() async {
        isCreating = true
        let json = await bridge.createSnapshot(serverID: serverId, appID: "litespeed")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Snapshot created")
            await loadSnapshots()
        } else {
            toast.showError("Failed to create snapshot")
        }
        isCreating = false
    }

    private func restoreSnapshot(_ id: String) async {
        let json = await bridge.restoreSnapshot(serverID: serverId, appID: "litespeed", id: id)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Snapshot restored")
        } else {
            toast.showError("Failed to restore snapshot")
        }
    }

    private func deleteSnapshot(_ id: String) async {
        let json = await bridge.deleteSnapshot(serverID: serverId, appID: "litespeed", id: id)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Snapshot deleted")
            await loadSnapshots()
        } else {
            toast.showError("Failed to delete snapshot")
        }
    }

    private func diffSnapshot(_ id: String) async {
        if diffSnapshotID == id {
            diffSnapshotID = nil
            diffText = nil
            return
        }
        let json = await bridge.diffSnapshot(serverID: serverId, appID: "litespeed", id: id)
        if let data = json.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeDataResponse<String>.self, from: data),
           resp.success {
            diffText = resp.data ?? "No differences"
            diffSnapshotID = id
        }
    }
}
