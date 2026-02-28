//
//  AXActionButton.swift
//  AevonX
//
//  Universal action button with 5 styles and 3 sizes.
//  Used across the entire dashboard for all interactive actions.
//

import SwiftUI

// MARK: - Button Style

enum AXButtonStyle: Equatable {
    case primary
    case destructive
    case success
    case warning
    case ghost
    
    var foregroundColor: Color {
        switch self {
        case .primary: return .white
        case .destructive: return .white
        case .success: return .white
        case .warning: return .white
        case .ghost: return .axTextSecondary
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .axAccentBlue
        case .destructive: return .axError.opacity(0.85)
        case .success: return .axSuccess
        case .warning: return .axWarning
        case .ghost: return .clear
        }
    }
    
    var hasBorder: Bool {
        self == .ghost
    }
    
    var borderColor: Color {
        switch self {
        case .ghost: return .axBorder
        default: return .clear
        }
    }
}

// MARK: - Button Size

enum AXButtonSize {
    case small
    case regular
    case large
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 11
        case .regular: return 12
        case .large: return 13
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 10
        case .regular: return 11
        case .large: return 12
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return AXSpacing.sm
        case .regular: return AXSpacing.md
        case .large: return AXSpacing.lg
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return AXSpacing.xxxs
        case .regular: return AXSpacing.xs
        case .large: return AXSpacing.sm
        }
    }
}

// MARK: - AXActionButton

struct AXActionButton: View {
    let label: String
    var icon: String? = nil
    var style: AXButtonStyle = .primary
    var size: AXButtonSize = .regular
    var isLoading: Bool = false
    var fullWidth: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xxs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: size.iconSize, height: size.iconSize)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize))
                }
                
                Text(label)
                    .font(.system(size: size.fontSize, weight: .medium))
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(isHovered ? style.backgroundColor.opacity(0.9) : style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(style.borderColor, lineWidth: style.hasBorder ? 1 : 0)
                    )
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview("AXActionButton") {
    VStack(spacing: AXSpacing.lg) {
        HStack(spacing: AXSpacing.md) {
            AXActionButton(label: "Install", icon: "arrow.down.circle", style: .primary) {}
            AXActionButton(label: "Unban", icon: "lock.open.fill", style: .destructive) {}
            AXActionButton(label: "Enable", icon: "play.circle", style: .success) {}
        }
        HStack(spacing: AXSpacing.md) {
            AXActionButton(label: "Warning", icon: "exclamationmark.triangle", style: .warning) {}
            AXActionButton(label: "Refresh", icon: "arrow.clockwise", style: .ghost) {}
            AXActionButton(label: "Loading…", style: .primary, isLoading: true) {}
        }
        HStack(spacing: AXSpacing.md) {
            AXActionButton(label: "Small", icon: "xmark", style: .destructive, size: .small) {}
            AXActionButton(label: "Regular", icon: "checkmark", style: .success, size: .regular) {}
            AXActionButton(label: "Large", icon: "plus", style: .primary, size: .large) {}
        }
    }
    .padding()
    .background(Color.axBackground)
}
