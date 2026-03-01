//
//  AXSidebarRow.swift
//  AevonX
//
//  Unified sidebar navigation row for all sidebar panels.
//  Replaces: PremiumSidebarButton, SecuritySidebarButton,
//  ServiceSidebarNavigationRow, and Docker Tools inline button.
//

import SwiftUI

struct AXSidebarRow: View {
    let icon: String
    let title: String
    var color: Color = .axAccentBlue
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isSelected
                                ? color.opacity(0.15)
                                : color.opacity(isHovered ? 0.10 : 0.07)
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(
                            isSelected ? color : color.opacity(isHovered ? 0.85 : 0.7)
                        )
                }

                // Title
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)
                    .lineLimit(1)

                Spacer()

                // Active dot indicator
                if isSelected {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(
                        isSelected
                            ? color.opacity(0.08)
                            : (isHovered ? Color.axBackground.opacity(0.5) : Color.clear)
                    )
            )
            .overlay(
                HStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: 3)
                    }
                    Spacer()
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    VStack(spacing: 3) {
        AXSidebarRow(icon: "clock.badge.checkmark", title: "Scheduler", color: .indigo, isSelected: true, action: {})
        AXSidebarRow(icon: "key.fill", title: "Secrets", color: .yellow, isSelected: false, action: {})
        AXSidebarRow(icon: "network", title: "Traffic", color: .mint, isSelected: false, action: {})
        AXSidebarRow(icon: "flame.fill", title: "Firewall", isSelected: false, action: {})
    }
    .padding(AXSpacing.md)
    .frame(width: 240)
    .background(Color.axSurface.opacity(0.6))
}
