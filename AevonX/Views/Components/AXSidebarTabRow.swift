//
//  AXSidebarTabRow.swift
//  AevonX
//
//  Shared sidebar navigation row — used in Profile, Settings, and any inner sidebar.
//  Matches the main SidebarView's SidebarNavItem style for visual consistency.
//

import SwiftUI

struct AXSidebarTabRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Icon in container
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.axAccentBlue.opacity(0.15) : (isHovered ? Color.axSurface : .clear))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .axAccentBlue : (isHovered ? .axTextPrimary : .axTextSecondary))
                }
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .axTextPrimary : (isHovered ? .axTextPrimary : .axTextSecondary))
                
                Spacer()
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.08) : (isHovered ? Color.axSurfaceHover.opacity(0.3) : .clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(isSelected ? Color.axAccentBlue.opacity(0.25) : .clear, lineWidth: 1)
                    )
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.axAccentBlue)
                        .frame(width: 3, height: 18)
                        .shadow(color: .axAccentBlue.opacity(0.5), radius: 4)
                        .offset(x: -2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
