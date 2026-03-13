//
//  AXSkeletonRow.swift
//  AevonX
//
//  Reusable skeleton placeholder row with shimmer animation.
//  Use to indicate loading state for list rows, settings rows, and table rows.
//  Standard loading pattern — see NOTE.md §15.
//

import SwiftUI

// MARK: - AXSkeletonRow

struct AXSkeletonRow: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var cornerRadius: CGFloat = AXCornerRadius.sm

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.axSurface)
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - AXSkeletonBlock
// Multi-line block placeholder (heavier sections like cards, panels)

struct AXSkeletonBlock: View {
    var lines: Int = 2
    var height: CGFloat = 14
    var spacing: CGFloat = AXSpacing.sm

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lines, id: \.self) { i in
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface)
                    .frame(maxWidth: i == lines - 1 ? .infinity : .infinity)
                    .frame(height: height)
                    .opacity(i == lines - 1 ? 0.6 : 1.0)
                    .shimmer()
            }
        }
    }
}

// MARK: - AXSkeletonSettingRow
// Mimics a settings row: label on left, value on right

struct AXSkeletonSettingRow: View {
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            AXSkeletonRow(width: 120, height: 13)
            Spacer()
            AXSkeletonRow(width: 80, height: 13)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }
}

// MARK: - Preview

#Preview("AXSkeletonRow") {
    VStack(alignment: .leading, spacing: AXSpacing.md) {
        AXSkeletonRow(width: 200, height: 12)
        AXSkeletonRow(height: 14)
        AXSkeletonBlock(lines: 3)
        AXSkeletonSettingRow()
        AXSkeletonSettingRow()
    }
    .padding(AXSpacing.xl)
    .background(Color.axBackground)
    .frame(width: 400)
}
