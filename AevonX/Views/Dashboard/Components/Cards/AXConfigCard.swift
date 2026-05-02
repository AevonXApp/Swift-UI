//
//  AXConfigCard.swift
//  AevonX
//
//  Configuration section card with icon, title, description, and ViewBuilder content.
//  Replaces ConfigCard in WebsitePanelComponents and inline config patterns
//  in 10+ website/application configuration sections.
//

import SwiftUI

// MARK: - AXConfigCard

struct AXConfigCard<Content: View>: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color = .axAccentBlue
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Header
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(title)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }
            
            Divider().background(Color.axBorder.opacity(0.5))
            
            // Content
            content()
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("AXConfigCard") {
    VStack(spacing: AXSpacing.lg) {
        AXConfigCard(
            icon: "gearshape.fill",
            title: "PHP Configuration",
            subtitle: "Adjust memory limits, upload sizes, and timeouts"
        ) {
            VStack(spacing: AXSpacing.md) {
                AXInfoRow(label: "Memory Limit", value: "256M", valueColor: .axAccentBlue)
                AXInfoRow(label: "Upload Size", value: "64M", valueColor: .axAccentBlue)
                AXInfoRow(label: "Max Execution", value: "30s", valueColor: .axWarning)
            }
        }
        
        AXConfigCard(
            icon: "lock.shield.fill",
            title: "Security Headers",
            iconColor: .axSuccess
        ) {
            Text(L10n.Label.configureSecurityHeaders)
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
        }
    }
    .padding()
    .background(Color.axBackground)
    .frame(width: 500)
}
