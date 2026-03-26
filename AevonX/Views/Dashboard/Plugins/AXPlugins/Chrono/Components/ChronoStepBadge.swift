//
//  ChronoStepBadge.swift
//  AevonX
//
//  Pipeline step status badge for deploy detail view.
//

import SwiftUI

struct ChronoStepBadge: View {
    let step: ChronoDeployStep
    let formatDuration: (Int) -> String

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            statusIcon
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(step.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.axTextPrimary)
                if let msg = step.message {
                    Text(msg)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(formatDuration(step.durationMS))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextSecondary)
        }
        .padding(.vertical, AXSpacing.xs)
    }

    private var statusIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(iconColor)
            .frame(width: 22, height: 22)
            .background(iconColor.opacity(0.12))
            .clipShape(Circle())
    }

    private var iconName: String {
        switch step.status {
        case "success": return "checkmark"
        case "failed": return "xmark"
        case "running": return "arrow.triangle.2.circlepath"
        case "skipped": return "forward"
        default: return "circle"
        }
    }

    private var iconColor: Color {
        switch step.status {
        case "success": return .axSuccess
        case "failed": return .axError
        case "running": return .axAccentBlue
        case "skipped": return .axTextMuted
        default: return .axTextMuted
        }
    }
}
