//
//  SidebarView.swift
//  AevonX
//
//  Glassmorphism sidebar with floating selection highlight
//

import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case remoteFleet = "Remote Fleet"
    case localWorkspace = "Local Workspace"
    case userProfile = "User Profile"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .remoteFleet: return "server.rack"
        case .localWorkspace: return "folder.badge.gear"
        case .userProfile: return "person.crop.circle"
        case .settings: return "gearshape.2"
        }
    }
    
    var shortcut: String {
        switch self {
        case .remoteFleet: return "⌘1"
        case .localWorkspace: return "⌘2"
        case .userProfile: return "⌘3"
        case .settings: return "⌘,"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedItem: NavigationItem
    @Binding var selectedServer: Server?
    
    var body: some View {
        VStack(spacing: 0) {
            // App Logo
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.axAccentBlue)
                    .shadow(color: .axAccentBlue.opacity(0.5), radius: 8, x: 0, y: 0)
                
                Text("AevonX")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.axBorder)
                .padding(.horizontal, AXSpacing.lg)
            
            // Navigation Items
            VStack(spacing: AXSpacing.sm) {
                ForEach(NavigationItem.allCases) { item in
                    SidebarItem(
                        item: item,
                        isSelected: selectedItem == item,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedItem = item
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.lg)
            
            Spacer()
            
            // Quick Status at Bottom
            VStack(spacing: AXSpacing.sm) {
                Divider()
                    .background(Color.axBorder)
                    .padding(.horizontal, AXSpacing.lg)
                
                HStack(spacing: AXSpacing.sm) {
                    Circle()
                        .fill(Color.axSuccess)
                        .frame(width: 6, height: 6)
                        .shadow(color: .axSuccess.opacity(0.5), radius: 3, x: 0, y: 0)
                    
                    Text("Connected")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    Spacer()
                    
                    Text("v1.0.0")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.lg)
            }
        }
        .frame(width: 240)
        .background(
            ZStack {
                Color.axBackgroundSecondary.opacity(0.9)
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        Color.axAccentBlue.opacity(0.02),
                        Color.clear,
                        Color.black.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .stroke(Color.axGlassBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}

struct SidebarItem: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .axAccentBlue : isHovered ? .axTextPrimary : .axTextSecondary)
                    .frame(width: 24)
                
                Text(item.rawValue)
                    .font(AXTypography.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .axTextPrimary : isHovered ? .axTextPrimary : .axTextSecondary)
                
                Spacer()
                
                Text(item.shortcut)
                    .font(AXTypography.caption2)
                    .foregroundColor(isSelected ? .axAccentBlue.opacity(0.7) : .axTextMuted)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.axBackgroundTertiary)
                    )
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.md)
            .background(
                // Floating highlight background
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.12) : (isHovered ? Color.axSurfaceHover.opacity(0.5) : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .stroke(isSelected ? Color.axAccentBlue.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
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

#Preview {
    SidebarView(
        selectedItem: .constant(.remoteFleet),
        selectedServer: .constant(nil)
    )
    .frame(height: 600)
    .background(Color.axBackground)
}
