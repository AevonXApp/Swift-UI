//
//  MySQLSnapshotsSection.swift
//  AevonX
//
//  Config snapshots — create, restore, diff, delete mysql.conf backups.
//

import SwiftUI
import AevonXCoreBridge

struct MySQLSnapshotsSection: View {
    let serverId: String

    @State private var snapshots: [[String: String]] = []
    @State private var isLoading = true
    @State private var isCreating = false
    @State private var diffText = ""
    @State private var showingDiff = false
    @State private var diffTitle = ""

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Apps.configSnapshots)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text(L10n.Apps.automaticBackupsOfMysqlConfBeforeEachChange)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
                Button {
                    Task { await createSnapshot() }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if isCreating {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(L10n.Apps.createSnapshot)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, 7)
                    .background(Color.indigo)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isCreating)
            }
            .padding(AXSpacing.xl)

            Divider()

            if isLoading {
                // Skeleton loading
                VStack(spacing: 1) {
                    ForEach(0..<5, id: \.self) { _ in
                        AXSkeletonRow()
                            .padding(.horizontal, AXSpacing.xl)
                            .padding(.vertical, 6)
                    }
                }
                .padding(.top, AXSpacing.lg)
                Spacer()
            } else if snapshots.isEmpty {
                Spacer()
                VStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.1))
                            .frame(width: 60, height: 60)
                        Image(systemName: "clock.arrow.2.circlepath")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.indigo)
                    }
                    Text(L10n.Apps.noSnapshotsYet)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    Text(L10n.Apps.createASnapshotToSaveTheCurrentMysqlConfState)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await createSnapshot() }
                    } label: {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "plus.circle.fill")
                            Text(L10n.Apps.createFirstSnapshot)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, 8)
                        .background(Color.indigo)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, AXSpacing.xs)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(snapshots.indices, id: \.self) { i in
                            snapshotRow(snapshots[i])
                        }
                    }
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
                    .padding(AXSpacing.xl)
                }
            }
        }
        .sheet(isPresented: $showingDiff) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(diffTitle)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Button(L10n.Button.close) { showingDiff = false }
                        .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.axAccentBlue)
                }
                .padding()
                Divider()
                ScrollView {
                    Text(diffText.isEmpty ? "No differences" : diffText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(width: 600, height: 500)
            .background(Color.axBackground)
        }
        .task { await loadSnapshots() }
    }

    private func snapshotRow(_ snap: [String: String]) -> some View {
        let id = snap["id"] ?? ""
        let timestamp = snap["timestamp"] ?? ""
        return HStack(spacing: AXSpacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.indigo)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text("mysql.conf.\(id)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                Text(timestamp)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            // Diff
            Button {
                Task { await showDiff(id: id, ts: timestamp) }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 11))
                    .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Compare with current")

            // Restore
            Button {
                Task { await restore(id: id) }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Restore this snapshot")

            // Delete
            Button {
                Task { await deleteSnapshot(id: id) }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Delete snapshot")
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, 10)
        .background(Color.axSurface)
    }

    private func loadSnapshots() async {
        isLoading = true
        let json = await bridge.listSnapshots(serverID: serverId, appID: "mysql")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = resp["data"] as? [[String: Any]] {
            snapshots = list.map { s in
                ["id": s["id"] as? String ?? "",
                 "timestamp": s["timestamp"] as? String ?? "",
                 "path": s["path"] as? String ?? ""]
            }
        }
        isLoading = false
    }

    private func createSnapshot() async {
        isCreating = true
        let json = await bridge.createSnapshot(serverID: serverId, appID: "mysql")
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

    private func restore(id: String) async {
        let json = await bridge.restoreSnapshot(serverID: serverId, appID: "mysql", id: id)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Snapshot restored — mysql.conf updated")
        } else {
            toast.showError("Restore failed")
        }
    }

    private func deleteSnapshot(id: String) async {
        let json = await bridge.deleteSnapshot(serverID: serverId, appID: "mysql", id: id)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Snapshot deleted")
            await loadSnapshots()
        } else {
            toast.showError("Delete failed")
        }
    }

    private func showDiff(id: String, ts: String) async {
        let json = await bridge.diffSnapshot(serverID: serverId, appID: "mysql", id: id)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let d = (resp["data"] as? [String: Any])?["diff"] as? String {
            diffText = d
            diffTitle = "Diff: \(ts) vs current"
            showingDiff = true
        }
    }
}
