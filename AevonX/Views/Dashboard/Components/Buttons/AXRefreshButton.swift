//
//  AXRefreshButton.swift
//  AevonX
//
//  Specialized refresh button with optional spin animation.
//  Replaces identically duplicated refresh button code in 12+ files.
//

import SwiftUI

// MARK: - AXRefreshButton

struct AXRefreshButton: View {
    var label: String = "Refresh"
    var isLoading: Bool = false
    let action: () async -> Void
    
    var body: some View {
        Button(action: { Task { await action() } }) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(
                        isLoading
                        ? Animation.linear(duration: 1).repeatForever(autoreverses: false)
                        : .default,
                        value: isLoading
                    )
                
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

// Icon-only variant
struct AXRefreshIconButton: View {
    var isLoading: Bool = false
    let action: () async -> Void
    
    var body: some View {
        Button(action: { Task { await action() } }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 14))
                .foregroundColor(.axTextSecondary)
                .rotationEffect(.degrees(isLoading ? 360 : 0))
                .animation(
                    isLoading
                    ? Animation.linear(duration: 1).repeatForever(autoreverses: false)
                    : .default,
                    value: isLoading
                )
                .frame(width: 36, height: 36)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview("AXRefreshButton") {
    HStack(spacing: AXSpacing.lg) {
        AXRefreshButton { }
        AXRefreshButton(label: "Re-scan") { }
        AXRefreshButton(isLoading: true) { }
        AXRefreshIconButton { }
        AXRefreshIconButton(isLoading: true) { }
    }
    .padding()
    .background(Color.axBackground)
}
