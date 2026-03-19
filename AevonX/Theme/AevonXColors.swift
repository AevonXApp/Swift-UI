//
//  AevonXColors.swift
//  AevonX
//
//  Color palette and theme constants for AevonX
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Background Colors
    public static let axBackground = Color(hex: "#121212")
    public static let axBackgroundSecondary = Color(hex: "#1A1A1A")
    public static let axBackgroundTertiary = Color(hex: "#242424")
    public static let axBackgroundElevated = Color(hex: "#2D2D2D")
    
    // Surface Colors (for cards, panels)
    public static let axSurface = Color(hex: "#1E1E1E")
    public static let axSurfaceHover = Color(hex: "#2A2A2A")
    public static let axSurfaceActive = Color(hex: "#333333")
    
    // Accent Colors - Electric Blue & Emerald Green
    public static let axPrimary = axAccentBlue
    public static let axAccentBlue = Color(hex: "#00D4FF")
    public static let axAccentBlueDimmed = Color(hex: "#00D4FF").opacity(0.6)
    public static let axAccentGreen = Color(hex: "#10B981")
    public static let axAccentGreenDimmed = Color(hex: "#10B981").opacity(0.6)
    public static let axAccentPurple = Color(hex: "#A855F7")
    
    // Status Colors
    public static let axSuccess = Color(hex: "#22C55E")
    public static let axWarning = Color(hex: "#F59E0B")
    public static let axError = Color(hex: "#EF4444")
    public static let axInfo = Color(hex: "#3B82F6")
    
    // Text Colors
    public static let axTextPrimary = Color(hex: "#FAFAFA")
    public static let axTextSecondary = Color(hex: "#A1A1AA")
    public static let axTextTertiary = Color(hex: "#71717A")
    public static let axTextMuted = Color(hex: "#52525B")
    
    // Border & Divider
    public static let axBorder = Color(hex: "#27272A")
    public static let axDivider = Color(hex: "#3F3F46")
    
    // Glassmorphism
    public static let axGlassBackground = Color(hex: "#1A1A1A").opacity(0.75)
    public static let axGlassBorder = Color.white.opacity(0.08)
    
    // Utility
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
public struct AXTypography {
    public static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    public static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
    public static let title2 = Font.system(size: 18, weight: .semibold, design: .rounded)
    public static let title3 = Font.system(size: 16, weight: .semibold, design: .rounded)
    public static let headline = Font.system(size: 14, weight: .semibold, design: .default)
    public static let body = Font.system(size: 14, weight: .regular, design: .default)
    public static let callout = Font.system(size: 13, weight: .regular, design: .default)
    public static let subheadline = Font.system(size: 12, weight: .regular, design: .default)
    public static let footnote = Font.system(size: 11, weight: .regular, design: .default)
    public static let caption = Font.system(size: 10, weight: .medium, design: .default)
    public static let caption2 = Font.system(size: 9, weight: .medium, design: .default)
    // Monospaced — for code, logs, config, terminal output
    public static let monoLg = Font.system(size: 14, weight: .regular, design: .monospaced)
    public static let monoMd = Font.system(size: 12, weight: .regular, design: .monospaced)
    public static let monoSm = Font.system(size: 11, weight: .regular, design: .monospaced)
    public static let monoXs = Font.system(size: 10, weight: .regular, design: .monospaced)
    public static let monoXxs = Font.system(size: 9, weight: .regular, design: .monospaced)
    public static let monoXxxs = Font.system(size: 8, weight: .regular, design: .monospaced)
}

// MARK: - Spacing
public struct AXSpacing {
    public static let xxxs: CGFloat = 2
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 6
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 32
    public static let xxxxl: CGFloat = 48
}

// MARK: - Corner Radius
public struct AXCornerRadius {
    public static let xs: CGFloat = 2
    public static let sm: CGFloat = 4
    public static let md: CGFloat = 8
    public static let lg: CGFloat = 12
    public static let xl: CGFloat = 16
    public static let xxl: CGFloat = 20
    public static let full: CGFloat = 9999
}
