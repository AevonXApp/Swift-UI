//
//  AevonXColors.swift
//  AevonX
//
//  Color palette and theme constants for AevonX
//

import SwiftUI

// MARK: - Color Palette (Dynamic - reads from ThemeEngine)
extension Color {
    // Background Colors
    public static var axBackground: Color { ThemeEngine.shared.background }
    public static var axBackgroundSecondary: Color { ThemeEngine.shared.backgroundSecondary }
    public static var axBackgroundTertiary: Color { ThemeEngine.shared.backgroundTertiary }
    public static var axBackgroundElevated: Color { ThemeEngine.shared.backgroundElevated }

    // Surface Colors (for cards, panels)
    public static var axSurface: Color { ThemeEngine.shared.surface }
    public static var axSurfaceHover: Color { ThemeEngine.shared.surfaceHover }
    public static var axSurfaceActive: Color { ThemeEngine.shared.surfaceActive }

    // Accent Colors
    public static var axPrimary: Color { axAccentBlue }
    public static var axAccentBlue: Color { ThemeEngine.shared.accentPrimary }
    public static var axAccentBlueDimmed: Color { ThemeEngine.shared.accentPrimary.opacity(0.6) }
    public static var axAccentGreen: Color { ThemeEngine.shared.accentSecondary }
    public static var axAccentGreenDimmed: Color { ThemeEngine.shared.accentSecondary.opacity(0.6) }
    public static var axAccentPurple: Color { ThemeEngine.shared.accentPurple }

    // Status Colors
    public static var axSuccess: Color { ThemeEngine.shared.success }
    public static var axWarning: Color { ThemeEngine.shared.warning }
    public static var axError: Color { ThemeEngine.shared.error }
    public static var axInfo: Color { ThemeEngine.shared.info }

    // Text Colors
    public static var axTextPrimary: Color { ThemeEngine.shared.textPrimary }
    public static var axTextSecondary: Color { ThemeEngine.shared.textSecondary }
    public static var axTextTertiary: Color { ThemeEngine.shared.textTertiary }
    public static var axTextMuted: Color { ThemeEngine.shared.textMuted }

    // Border & Divider
    public static var axBorder: Color { ThemeEngine.shared.border }
    public static var axDivider: Color { ThemeEngine.shared.divider }

    // Glassmorphism
    public static var axGlassBackground: Color { ThemeEngine.shared.glassBackground }
    public static var axGlassBorder: Color { ThemeEngine.shared.glassBorder }
    
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
