//
//  ChronoDeployRow.swift
//  AevonX
//
//  Deploy history row with status icon, project, commit, duration.
//

import SwiftUI

struct ChronoDeployRow: View {
    let deploy: ChronoDeploy

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            statusIcon
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(deploy.projectName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                    Text(deploy.commit.prefix(7))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                }
                HStack(spacing: AXSpacing.sm) {
                    Text(deploy.startedAt)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Text("·")
                        .foregroundColor(.axTextMuted)
                    Text(deploy.trigger.capitalized)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: AXSpacing.xxxs) {
                Text(deploy.status.capitalized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(statusColor)
                Text(formatDuration(deploy.durationMS))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    private var statusIcon: some View {
        Image(systemName: statusIconName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(statusColor)
            .frame(width: 28, height: 28)
            .background(statusColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
    }

    private var statusIconName: String {
        switch deploy.status {
        case "success": return "checkmark"
        case "failed": return "xmark"
        case "rolled_back": return "arrow.uturn.backward"
        case "running": return "arrow.triangle.2.circlepath"
        default: return "clock"
        }
    }

    private var statusColor: Color {
        switch deploy.status {
        case "success": return .axSuccess
        case "failed": return .axError
        case "rolled_back": return .axWarning
        case "running": return .axAccentBlue
        default: return .axTextMuted
        }
    }

    private func formatDuration(_ ms: Int) -> String {
        let s = Double(ms) / 1000
        if s >= 60 { return String(format: "%.0fm %.0fs", (s / 60).rounded(.down), s.truncatingRemainder(dividingBy: 60)) }
        return String(format: "%.1fs", s)
    }
}
