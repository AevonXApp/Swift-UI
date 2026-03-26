//
//  ChronoSnapshotsView.swift
//  AevonX
//
//  Snapshot management — list, restore, delete snapshots across projects.
//

import SwiftUI

struct ChronoSnapshotsView: View {
    @ObservedObject var viewModel: ChronoViewModel
    let projectId: String

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            header
            snapshotsList
        }
        .task { await viewModel.loadSnapshots(projectId: projectId) }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "camera.fill")
                .font(.system(size: 14))
                .foregroundColor(.axAccentPurple)
            Text(L10n.Chrono.Snapshots.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)
            Spacer()
            Text(L10n.Chrono.deploysCount(viewModel.snapshots.count))
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
    }

    // MARK: - List

    @ViewBuilder
    private var snapshotsList: some View {
        if viewModel.snapshots.isEmpty {
            emptyState
        } else {
            VStack(spacing: AXSpacing.sm) {
                ForEach(viewModel.snapshots) { snap in
                    snapshotCard(snap)
                }
            }
        }
    }

    private func snapshotCard(_ snap: ChronoSnapshot) -> some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                typeIcon(snap.type)

                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    HStack(spacing: AXSpacing.sm) {
                        Text(String(snap.commitHash.prefix(8)))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                        typeBadge(snap.type)
                    }
                    HStack(spacing: AXSpacing.md) {
                        Text(snap.createdAt)
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                        Text(viewModel.formatBytes(snap.sizeBytes))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextSecondary)
                        Text("\(snap.fileCount) files")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                }

                Spacer()

                HStack(spacing: AXSpacing.sm) {
                    Button {
                        Task { await viewModel.restoreSnapshot(projectId: projectId, snapshotId: snap.id) }
                    } label: {
                        HStack(spacing: AXSpacing.xxxs) {
                            Image(systemName: "arrow.uturn.backward")
                            Text(L10n.Chrono.Snapshots.restore)
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axWarning)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xxs)
                        .background(Color.axWarning.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await viewModel.deleteSnapshot(id: snap.id, projectId: projectId) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.axError.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AXSpacing.md)
        }
    }

    // MARK: - Helpers

    private func typeIcon(_ type: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(typeColor(type).opacity(0.12))
                .frame(width: 32, height: 32)
            Image(systemName: typeIconName(type))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(typeColor(type))
        }
    }

    private func typeBadge(_ type: String) -> some View {
        Text(type.capitalized)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(typeColor(type))
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(typeColor(type).opacity(0.1))
            .clipShape(Capsule())
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "auto": return .axAccentBlue
        case "manual": return .axAccentPurple
        case "rollback": return .axWarning
        default: return .axTextMuted
        }
    }

    private func typeIconName(_ type: String) -> String {
        switch type {
        case "auto": return "camera.fill"
        case "manual": return "hand.tap"
        case "rollback": return "arrow.uturn.backward"
        default: return "camera"
        }
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "camera")
                .font(.system(size: 28))
                .foregroundColor(.axTextMuted)
            Text(L10n.Chrono.Snapshots.empty)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }
}
