//
//  AXStatCard.swift
//  AevonX
//
//  Generic metric card — displays icon + value + label with accent border.
//  Three layout variants: vertical, horizontal, pill.
//  Replaces duplicate statCard() in 9+ dashboard files.
//

import SwiftUI

// MARK: - AXStatCard

struct AXStatCard: View {
    let icon: String
    let label: String
    let value: String
    var subtitle: String? = nil
    var color: Color = .axAccentBlue
    var layout: Layout = .vertical
    var style: Style = .card
    
    enum Layout {
        case vertical    // icon top → value → label
        case horizontal  // icon left → value + label right
    }
    
    enum Style {
        case card  // full card with background + border
        case pill  // compact inline pill
        case glass // glassmorphism with hover glow
    }
    
    @State private var isHovered = false
    
    var body: some View {
        Group {
            switch (layout, style) {
            case (.vertical, .card):
                verticalCard
            case (.horizontal, .card):
                horizontalCard
            case (.vertical, .pill), (.horizontal, .pill):
                pillView
            case (.vertical, .glass):
                verticalGlass
            case (.horizontal, .glass):
                horizontalGlass
            }
        }
    }
    
    // MARK: - Vertical Card
    
    private var verticalCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
            }
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Horizontal Card
    
    private var horizontalCard: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Pill
    
    private var pillView: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.axTextMuted)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Vertical Glass
    
    private var verticalGlass: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            glassIcon
            
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(GlassBackground(color: color, isHovered: isHovered))
        .onHover { isHovered = $0 }
    }
    
    // MARK: - Horizontal Glass
    
    private var horizontalGlass: some View {
        HStack(spacing: AXSpacing.md) {
            glassIcon
            
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .modifier(GlassBackground(color: color, isHovered: isHovered))
        .onHover { isHovered = $0 }
    }
    
    // MARK: - Shared Glass Sub-views
    
    private var glassIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.25), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
            
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// MARK: - Glass Background Modifier

private struct GlassBackground: ViewModifier {
    let color: Color
    let isHovered: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(Color.axGlassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: isHovered
                                ? [color.opacity(0.4), color.opacity(0.2)]
                                : [Color.axGlassBorder, Color.axBorder],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: isHovered ? color.opacity(0.1) : .clear, radius: 8, y: 4)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)
    }
}

// MARK: - Preview

#Preview("AXStatCard") {
    HStack(spacing: AXSpacing.lg) {
        AXStatCard(icon: "antenna.radiowaves.left.and.right", label: "Open Ports", value: "24", color: .axAccentBlue)
        AXStatCard(icon: "xmark.circle", label: "Banned IPs", value: "4", color: .axError)
        AXStatCard(icon: "lock.shield.fill", label: "TLS Version", value: "1.3", color: .axAccentBlue, layout: .horizontal)
    }
    .padding()
    .background(Color.axBackground)
}
