//
//  AXPlaceholder.swift
//  AevonX
//
//  Dashboard empty / not-installed / no-results placeholder.
//  Different from the AXEmptyState in AXDesignSystem.swift (which has gradient icon + description).
//  This is a simpler, more compact placeholder for inside table cards and section content.
//

import SwiftUI

// MARK: - Placeholder Action

struct AXPlaceholderAction {
    let label: String
    var icon: String? = nil
    var style: AXButtonStyle = .primary
    var isLoading: Bool = false
    let handler: () async -> Void
}

// MARK: - AXPlaceholder

struct AXPlaceholder: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color = .axTextMuted
    var iconSize: CGFloat = 36
    var action: AXPlaceholderAction? = nil
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(iconColor)
            
            VStack(spacing: AXSpacing.sm) {
                Text(title)
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }
            }
            
            if let action = action {
                AXActionButton(
                    label: action.label,
                    icon: action.icon,
                    style: action.style,
                    isLoading: action.isLoading
                ) {
                    Task { await action.handler() }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxl)
    }
}

// MARK: - Preview

#Preview("AXPlaceholder") {
    VStack(spacing: AXSpacing.xl) {
        AXCard {
            AXPlaceholder(
                icon: "checkmark.shield.fill",
                title: "No suspicious files found",
                iconColor: .axSuccess
            )
        }
        
        AXCard {
            AXPlaceholder(
                icon: "exclamationmark.shield",
                title: "fail2ban is not installed",
                subtitle: "Install to enable brute force protection",
                iconColor: .axWarning,
                action: AXPlaceholderAction(
                    label: "Install",
                    icon: "arrow.down.circle",
                    style: .primary
                ) { }
            )
        }
        
        AXCard {
            AXPlaceholder(
                icon: "magnifyingglass",
                title: "No results match filter",
                subtitle: "Try a different search term",
                iconColor: .axTextMuted
            )
        }
    }
    .padding()
    .background(Color.axBackground)
    .frame(width: 600)
}
