//
//  WebsiteStatCard.swift
//  AevonX
//
//  Reusable statistics card component for website metrics
//

import SwiftUI

// MARK: - Website Stat Card

struct WebsiteStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.4), radius: 4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)

                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(isHovered ? color.opacity(0.5) : Color.axBorder, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }
}
