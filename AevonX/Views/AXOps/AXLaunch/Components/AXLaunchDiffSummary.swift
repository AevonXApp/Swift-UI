//
//  AXLaunchDiffSummary.swift
//  AevonX
//
//  Shows diff summary (modified / added / deleted / transfer size).
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchDiffSummary: View {
    let diff: AXLaunchDiff

    var body: some View {
        VStack(spacing: AXSpacing.sm) {
            diffRow(icon: "pencil", label: L10n.AXLaunch.Diff.modified, count: diff.changed, color: .axWarning)
            diffRow(icon: "plus", label: L10n.AXLaunch.Diff.added, count: diff.added, color: .axSuccess)
            diffRow(icon: "minus", label: L10n.AXLaunch.Diff.deleted, count: diff.deleted, color: .axError)

            Divider().background(Color.axBorder)

            HStack {
                Text(L10n.AXLaunch.Diff.transferSize)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                Spacer()
                Text(diff.transferSize)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
            }

            if diff.hasNewMigrations {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.axWarning)
                        .font(.system(size: 12))
                    Text(L10n.AXLaunch.Diff.newMigrations)
                        .font(AXTypography.caption)
                        .foregroundColor(.axWarning)
                    Spacer()
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private func diffRow(icon: String, label: String, count: Int, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
                .frame(width: 16)
            Text(label)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
            Spacer()
            Text(L10n.AXLaunch.diffFiles(count))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.axTextPrimary)
        }
    }
}
