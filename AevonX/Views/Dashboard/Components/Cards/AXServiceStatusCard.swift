//
//  AXServiceStatusCard.swift
//  AevonX
//
//  Service-level header card with icon, title, subtitle,
//  active/inactive status badge, and customizable trailing content.
//  Replaces headerCard patterns in BruteForce, SSH, AntiIntrusion, AI Security.
//

import SwiftUI

// MARK: - AXServiceStatusCard

struct AXServiceStatusCard<Trailing: View>: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var isActive: Bool = true
    var activeLabel: String = "Active"
    var inactiveLabel: String = "Inactive"
    var iconColor: Color = .axAccentBlue
    @ViewBuilder var trailing: () -> Trailing
    
    var body: some View {
        AXCard {
            HStack {
                // Leading: icon + title + subtitle
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isActive ? iconColor : .axTextMuted)
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                        Text(title)
                            .font(AXTypography.title3)
                            .foregroundColor(.axTextPrimary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                        }
                    }
                    
                    // Status badge
                    HStack(spacing: AXSpacing.xxs) {
                        Circle()
                            .fill(isActive ? Color.axSuccess : Color.axError)
                            .frame(width: 7, height: 7)
                        Text(isActive ? activeLabel : inactiveLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isActive ? .axSuccess : .axError)
                    }
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(
                        Capsule()
                            .fill(isActive ? Color.axSuccess.opacity(0.1) : Color.axError.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(isActive ? Color.axSuccess.opacity(0.2) : Color.axError.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                // Trailing content (stats, buttons, etc.)
                trailing()
            }
        }
    }
}

// Convenience init when no trailing content needed
extension AXServiceStatusCard where Trailing == EmptyView {
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isActive: Bool = true,
        activeLabel: String = "Active",
        inactiveLabel: String = "Inactive",
        iconColor: Color = .axAccentBlue
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isActive = isActive
        self.activeLabel = activeLabel
        self.inactiveLabel = inactiveLabel
        self.iconColor = iconColor
        self.trailing = { EmptyView() }
    }
}

// MARK: - Preview

#Preview("AXServiceStatusCard") {
    VStack(spacing: AXSpacing.lg) {
        AXServiceStatusCard(
            icon: "hand.raised.fill",
            title: "Brute Force Protection",
            subtitle: "fail2ban active jail",
            isActive: true
        ) {
            HStack(spacing: AXSpacing.xl) {
                VStack(spacing: AXSpacing.xxxs) {
                    Text("24").font(.system(size: 16, weight: .bold)).foregroundColor(.axError)
                    Text(L10n.Label.banned).font(.system(size: 10)).foregroundColor(.axTextMuted)
                }
                VStack(spacing: AXSpacing.xxxs) {
                    Text("3").font(.system(size: 16, weight: .bold)).foregroundColor(.axSuccess)
                    Text(L10n.Label.whitelisted).font(.system(size: 10)).foregroundColor(.axTextMuted)
                }
            }
        }
        
        AXServiceStatusCard(
            icon: "terminal.fill",
            title: "SSH Service",
            subtitle: "Port 22",
            isActive: true,
            iconColor: .axAccentBlue
        )
    }
    .padding()
    .background(Color.axBackground)
}
