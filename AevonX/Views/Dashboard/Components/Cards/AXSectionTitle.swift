//
//  AXSectionTitle.swift
//  AevonX
//
//  Simple section title with optional icon and trailing content.
//  Different from AXSectionHeader in AXDesignSystem (which has subtitle + action button).
//  Replaces SectionHeader in WebsitePanelComponents and inline section headers in 20+ files.
//

import SwiftUI

// MARK: - AXSectionTitle

struct AXSectionTitle<Trailing: View>: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color = .axAccentBlue
    var font: Font = .system(size: 18, weight: .bold)
    @ViewBuilder var trailing: () -> Trailing
    
    var body: some View {
        HStack {
            HStack(spacing: AXSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(font)
                    .foregroundColor(.axTextPrimary)
            }
            
            Spacer()
            
            trailing()
        }
    }
}

// Convenience init when no trailing content needed
extension AXSectionTitle where Trailing == EmptyView {
    init(
        title: String,
        icon: String? = nil,
        iconColor: Color = .axAccentBlue,
        font: Font = .system(size: 18, weight: .bold)
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.font = font
        self.trailing = { EmptyView() }
    }
}

// MARK: - Preview

#Preview("AXSectionTitle") {
    VStack(alignment: .leading, spacing: AXSpacing.xl) {
        AXSectionTitle(title: "System Information", icon: "server.rack")
        
        AXSectionTitle(title: "Firewall Rules", icon: "shield.fill", iconColor: .axSuccess) {
            AXBadge(text: "24 rules", color: .axAccentBlue, style: .soft)
        }
        
        AXSectionTitle(title: "Recent Activity")
    }
    .padding()
    .background(Color.axBackground)
}
