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
    }
    
    var body: some View {
        Group {
            switch (layout, style) {
            case (.vertical, .card):
                verticalCard
            case (.horizontal, .card):
                horizontalCard
            case (.vertical, .pill), (.horizontal, .pill):
                pillView
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
