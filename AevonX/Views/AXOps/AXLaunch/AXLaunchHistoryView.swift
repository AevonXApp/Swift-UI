//
//  AXLaunchHistoryView.swift
//  AevonX
//
//  Deploy history list for a server/project.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchHistoryView: View {
    let serverID: String
    let remotePath: String
    @State private var entries: [AXLaunchHistoryEntry] = []
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text(L10n.AXLaunch.historyTitle)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.axTextPrimary)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if entries.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .padding(AXSpacing.lg)
        .task { await loadHistory() }
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 28))
                .foregroundColor(.axTextMuted)
            Text(L10n.AXLaunch.historyNoHistory)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxl)
    }

    private var historyList: some View {
        VStack(spacing: AXSpacing.xs) {
            ForEach(entries) { entry in
                AXLaunchHistoryRow(entry: entry)
            }
        }
    }

    private func loadHistory() async {
        entries = await AXLaunchService.shared.getHistory(serverID: serverID, remotePath: remotePath)
        isLoading = false
    }
}

// MARK: - History Row

struct AXLaunchHistoryRow: View {
    let entry: AXLaunchHistoryEntry

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: entry.type == "update" ? "arrow.triangle.2.circlepath" : "paperplane.fill")
                .font(.system(size: 12))
                .foregroundColor(statusColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(entry.type.capitalized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                    statusBadge
                }
                Text(entry.at)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            if let files = entry.files {
                Text("\(files) files")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Text(formatDuration(entry.durationS))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextMuted)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    private var statusColor: Color {
        switch entry.status {
        case "completed": return .axSuccess
        case "failed": return .axError
        case "cancelled": return .axWarning
        default: return .axTextMuted
        }
    }

    private var statusBadge: some View {
        Text(entry.status)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(statusColor)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(statusColor.opacity(0.15))
            .cornerRadius(AXCornerRadius.sm)
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m \(seconds % 60)s"
    }
}
