//
//  SecuritySidebarButton.swift
//  AevonX
//
//  Sidebar button for Security panel.
//  Mirrors PremiumSidebarButton from WebsitePanelComponents.
//

import SwiftUI

// MARK: - Security Sidebar Button

struct SecuritySidebarButton: View {
    let item: SecuritySidebarItem
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(isSelected ? Color.axAccentBlue.opacity(0.15) : Color.axBackground.opacity(isHovered ? 0.5 : 0))
                        .frame(width: 32, height: 32)

                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                }

                // Title
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)

                Spacer()

                // Selection Indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.axAccentBlue)
                        .frame(width: 3, height: 16)
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.05) : (isHovered ? Color.axBackground.opacity(0.5) : Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
