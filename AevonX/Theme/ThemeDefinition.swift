//
//  ThemeDefinition.swift
//  AevonX
//
//  Theme model and 6 built-in theme definitions
//

import SwiftUI

// MARK: - Theme Category

enum ThemeCategory: String, Codable {
    case builtin
    case custom
}

// MARK: - Theme Definition

struct AXTheme: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let category: ThemeCategory
    let isLight: Bool

    // Background palette
    let background: String
    let backgroundSecondary: String
    let backgroundTertiary: String
    let backgroundElevated: String

    // Surface palette
    let surface: String
    let surfaceHover: String
    let surfaceActive: String

    // Accent colors
    let accentPrimary: String
    let accentSecondary: String
    let accentPurple: String

    // Status colors
    let success: String
    let warning: String
    let error: String
    let info: String

    // Text colors
    let textPrimary: String
    let textSecondary: String
    let textTertiary: String
    let textMuted: String

    // Border & glass
    let border: String
    let divider: String
    let glassBackground: String
    let glassBorderOpacity: Double
}

// MARK: - Built-in Themes

extension AXTheme {
    /// Midnight (Current Default) - Dark, high contrast, cyber aesthetic
    static let midnight = AXTheme(
        id: "midnight",
        name: "Midnight",
        category: .builtin,
        isLight: false,
        background: "#121212",
        backgroundSecondary: "#1A1A1A",
        backgroundTertiary: "#242424",
        backgroundElevated: "#2D2D2D",
        surface: "#1E1E1E",
        surfaceHover: "#2A2A2A",
        surfaceActive: "#333333",
        accentPrimary: "#00D4FF",
        accentSecondary: "#10B981",
        accentPurple: "#A855F7",
        success: "#22C55E",
        warning: "#F59E0B",
        error: "#EF4444",
        info: "#3B82F6",
        textPrimary: "#FAFAFA",
        textSecondary: "#A1A1AA",
        textTertiary: "#71717A",
        textMuted: "#52525B",
        border: "#27272A",
        divider: "#3F3F46",
        glassBackground: "#1A1A1A",
        glassBorderOpacity: 0.08
    )

    /// Ocean Deep - Dark, deep navy blue, ocean-inspired
    static let ocean = AXTheme(
        id: "ocean",
        name: "Ocean Deep",
        category: .builtin,
        isLight: false,
        background: "#0A1628",
        backgroundSecondary: "#0E1D33",
        backgroundTertiary: "#142640",
        backgroundElevated: "#1A304D",
        surface: "#112240",
        surfaceHover: "#1A3358",
        surfaceActive: "#234470",
        accentPrimary: "#64FFDA",
        accentSecondary: "#82B1FF",
        accentPurple: "#C792EA",
        success: "#22C55E",
        warning: "#FFCB6B",
        error: "#FF5370",
        info: "#82AAFF",
        textPrimary: "#CCD6F6",
        textSecondary: "#8892B0",
        textTertiary: "#5C6B8A",
        textMuted: "#3D4F6F",
        border: "#1E3A5F",
        divider: "#2A4A72",
        glassBackground: "#0E1D33",
        glassBorderOpacity: 0.1
    )

    /// Forest - Dark, natural green tones
    static let forest = AXTheme(
        id: "forest",
        name: "Forest",
        category: .builtin,
        isLight: false,
        background: "#1A1F16",
        backgroundSecondary: "#202618",
        backgroundTertiary: "#282F20",
        backgroundElevated: "#313A28",
        surface: "#252B20",
        surfaceHover: "#313A28",
        surfaceActive: "#3D4830",
        accentPrimary: "#4ADE80",
        accentSecondary: "#FCD34D",
        accentPurple: "#C084FC",
        success: "#4ADE80",
        warning: "#FCD34D",
        error: "#F87171",
        info: "#60A5FA",
        textPrimary: "#E8F0E0",
        textSecondary: "#A0B090",
        textTertiary: "#6D7D60",
        textMuted: "#4A5740",
        border: "#2E3825",
        divider: "#3D4830",
        glassBackground: "#202618",
        glassBorderOpacity: 0.08
    )

    /// Crimson - Dark, warm red tones
    static let crimson = AXTheme(
        id: "crimson",
        name: "Crimson",
        category: .builtin,
        isLight: false,
        background: "#1A1014",
        backgroundSecondary: "#22141A",
        backgroundTertiary: "#2C1C22",
        backgroundElevated: "#36242C",
        surface: "#251820",
        surfaceHover: "#36242C",
        surfaceActive: "#473038",
        accentPrimary: "#F43F5E",
        accentSecondary: "#FB923C",
        accentPurple: "#E879F9",
        success: "#4ADE80",
        warning: "#FBBF24",
        error: "#F43F5E",
        info: "#60A5FA",
        textPrimary: "#FDE8EC",
        textSecondary: "#B08090",
        textTertiary: "#7D5060",
        textMuted: "#5A3848",
        border: "#3A2028",
        divider: "#4A2C36",
        glassBackground: "#22141A",
        glassBorderOpacity: 0.08
    )

    /// Arctic Light - Clean, bright light theme
    static let arcticLight = AXTheme(
        id: "arctic_light",
        name: "Arctic Light",
        category: .builtin,
        isLight: true,
        background: "#F8FAFC",
        backgroundSecondary: "#F1F5F9",
        backgroundTertiary: "#E2E8F0",
        backgroundElevated: "#FFFFFF",
        surface: "#FFFFFF",
        surfaceHover: "#F1F5F9",
        surfaceActive: "#E2E8F0",
        accentPrimary: "#0EA5E9",
        accentSecondary: "#10B981",
        accentPurple: "#8B5CF6",
        success: "#16A34A",
        warning: "#D97706",
        error: "#DC2626",
        info: "#2563EB",
        textPrimary: "#0F172A",
        textSecondary: "#475569",
        textTertiary: "#94A3B8",
        textMuted: "#CBD5E1",
        border: "#E2E8F0",
        divider: "#CBD5E1",
        glassBackground: "#FFFFFF",
        glassBorderOpacity: 0.12
    )

    /// Warm Light - Warm paper-like tones
    static let warmLight = AXTheme(
        id: "warm_light",
        name: "Warm Light",
        category: .builtin,
        isLight: true,
        background: "#FFFBEB",
        backgroundSecondary: "#FEF3C7",
        backgroundTertiary: "#FDE68A",
        backgroundElevated: "#FFFFFF",
        surface: "#FFFFFF",
        surfaceHover: "#FEF3C7",
        surfaceActive: "#FDE68A",
        accentPrimary: "#D97706",
        accentSecondary: "#059669",
        accentPurple: "#7C3AED",
        success: "#16A34A",
        warning: "#D97706",
        error: "#DC2626",
        info: "#2563EB",
        textPrimary: "#1C1917",
        textSecondary: "#57534E",
        textTertiary: "#A8A29E",
        textMuted: "#D6D3D1",
        border: "#E7E5E4",
        divider: "#D6D3D1",
        glassBackground: "#FFFFFF",
        glassBorderOpacity: 0.15
    )

    /// All built-in themes
    static let allBuiltIn: [AXTheme] = [
        .midnight, .ocean, .forest, .crimson, .arcticLight, .warmLight
    ]

    /// Find theme by ID
    static func theme(withId id: String) -> AXTheme {
        allBuiltIn.first { $0.id == id } ?? .midnight
    }
}
