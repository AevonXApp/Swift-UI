//
//  AXSkeletonCard.swift
//  AevonX
//
//  Skeleton placeholder for app cards shown during data loading.
//  Standard loading pattern for the Applications section and any card grid.
//  See NOTE.md §15 for skeleton loading conventions.
//

import SwiftUI

// MARK: - AXSkeletonAppCard
// Mimics the compact horizontal app card during loading

struct AXSkeletonAppCard: View {
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Icon circle
            Circle()
                .fill(Color.axSurface)
                .frame(width: 36, height: 36)
                .shimmer()

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                // App name
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface)
                    .frame(width: 90, height: 12)
                    .shimmer()
                // Version / type
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface)
                    .frame(width: 55, height: 10)
                    .shimmer()
            }

            Spacer()

            // Status badge
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.axSurface)
                .frame(width: 64, height: 22)
                .shimmer()
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface.opacity(0.4))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - AXSkeletonStatCard
// Mimics AXStatCard during loading

struct AXSkeletonStatCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            // Icon
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.axSurface)
                .frame(width: 20, height: 20)
                .shimmer()

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                // Value
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface)
                    .frame(width: 60, height: 22)
                    .shimmer()
                // Label
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface)
                    .frame(width: 80, height: 10)
                    .shimmer()
            }
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - AXSkeletonSectionContent
// Full section loading skeleton — mimics a typical section with stat cards + rows

struct AXSkeletonSectionContent: View {
    var statCards: Int = 4
    var rows: Int = 3

    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Stat cards row
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: statCards),
                spacing: AXSpacing.md
            ) {
                ForEach(0..<statCards, id: \.self) { _ in
                    AXSkeletonStatCard()
                }
            }

            // Content rows
            VStack(spacing: AXSpacing.xs) {
                ForEach(0..<rows, id: \.self) { _ in
                    AXSkeletonSettingRow()
                        .background(Color.axSurface.opacity(0.3))
                        .cornerRadius(AXCornerRadius.sm)
                }
            }

            Spacer()
        }
        .padding(AXSpacing.xl)
        .background(Color.axBackground)
    }
}

// MARK: - Preview

#Preview("AXSkeletonCard") {
    VStack(spacing: AXSpacing.lg) {
        Group {
            AXSkeletonAppCard()
            AXSkeletonAppCard()
            AXSkeletonAppCard()
        }

        HStack {
            AXSkeletonStatCard()
            AXSkeletonStatCard()
            AXSkeletonStatCard()
        }
    }
    .padding(AXSpacing.xl)
    .background(Color.axBackground)
    .frame(width: 500)
}
