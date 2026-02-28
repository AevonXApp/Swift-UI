//
//  AXBadge.swift
//  AevonX
//
//  Compact text badge/pill with multiple styles.
//  Different from AXStatusBadge (which is a dot indicator).
//  Replaces inline badge patterns in CertificatesSection, BruteForceSubTab,
//  SSHSubTab, and other sections.
//

import SwiftUI

// MARK: - AXBadge

struct AXBadge: View {
    let text: String
    var color: Color = .axAccentBlue
    var style: Style = .filled
    
    enum Style: Equatable {
        case filled   // colored background, white text
        case soft     // light background, colored text
        case outline  // border only, colored text
        case capsule  // pill-shaped filled
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: badgeFontSize, weight: .bold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(background)
    }
    
    // MARK: - Computed
    
    private var badgeFontSize: CGFloat {
        switch style {
        case .capsule: return 11
        default: return 10
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .capsule: return AXSpacing.sm
        default: return AXSpacing.xs
        }
    }
    
    private var verticalPadding: CGFloat {
        switch style {
        case .capsule: return AXSpacing.xxxs
        default: return 2
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .filled, .capsule: return .white
        case .soft, .outline: return color
        }
    }
    
    @ViewBuilder
    private var background: some View {
        switch style {
        case .filled:
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(color)
        case .soft:
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(color.opacity(0.1))
        case .outline:
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        case .capsule:
            Capsule()
                .fill(color)
        }
    }
}

// MARK: - Preview

#Preview("AXBadge") {
    VStack(spacing: AXSpacing.lg) {
        HStack(spacing: AXSpacing.md) {
            AXBadge(text: "Active", color: .axSuccess, style: .filled)
            AXBadge(text: "Inactive", color: .axError, style: .filled)
            AXBadge(text: "Warning", color: .axWarning, style: .filled)
        }
        HStack(spacing: AXSpacing.md) {
            AXBadge(text: "Valid", color: .axSuccess, style: .soft)
            AXBadge(text: "Expired", color: .axError, style: .soft)
            AXBadge(text: "30d left", color: .axWarning, style: .soft)
        }
        HStack(spacing: AXSpacing.md) {
            AXBadge(text: "Critical", color: .axError, style: .outline)
            AXBadge(text: "High", color: .axWarning, style: .outline)
            AXBadge(text: "Low", color: .axSuccess, style: .outline)
        }
        HStack(spacing: AXSpacing.md) {
            AXBadge(text: "4 banned", color: .axError, style: .capsule)
            AXBadge(text: "12 active", color: .axSuccess, style: .capsule)
        }
    }
    .padding()
    .background(Color.axBackground)
}
