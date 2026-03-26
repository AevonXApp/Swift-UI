//
//  ThemeEngine.swift
//  AevonX
//
//  Theme switching, loading, and persistence engine
//

import SwiftUI
import Combine

@MainActor
class ThemeEngine: ObservableObject {
    static let shared = ThemeEngine()

    @Published private(set) var currentTheme: AXTheme = .midnight

    private init() {
        let themeId = UserDefaults.standard.string(forKey: SettingsKey.theme) ?? "midnight"
        currentTheme = AXTheme.theme(withId: themeId)
    }

    // MARK: - Theme Switching

    func setTheme(_ theme: AXTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.id, forKey: SettingsKey.theme)
    }

    func setTheme(id: String) {
        setTheme(AXTheme.theme(withId: id))
    }

    // MARK: - Color Scheme

    var colorScheme: ColorScheme? {
        if currentTheme.id == "auto" { return nil }
        return currentTheme.isLight ? .light : .dark
    }

    // MARK: - Resolved Colors

    var background: Color { Color(hex: currentTheme.background) }
    var backgroundSecondary: Color { Color(hex: currentTheme.backgroundSecondary) }
    var backgroundTertiary: Color { Color(hex: currentTheme.backgroundTertiary) }
    var backgroundElevated: Color { Color(hex: currentTheme.backgroundElevated) }

    var surface: Color { Color(hex: currentTheme.surface) }
    var surfaceHover: Color { Color(hex: currentTheme.surfaceHover) }
    var surfaceActive: Color { Color(hex: currentTheme.surfaceActive) }

    var accentPrimary: Color { Color(hex: currentTheme.accentPrimary) }
    var accentSecondary: Color { Color(hex: currentTheme.accentSecondary) }
    var accentPurple: Color { Color(hex: currentTheme.accentPurple) }

    var success: Color { Color(hex: currentTheme.success) }
    var warning: Color { Color(hex: currentTheme.warning) }
    var error: Color { Color(hex: currentTheme.error) }
    var info: Color { Color(hex: currentTheme.info) }

    var textPrimary: Color { Color(hex: currentTheme.textPrimary) }
    var textSecondary: Color { Color(hex: currentTheme.textSecondary) }
    var textTertiary: Color { Color(hex: currentTheme.textTertiary) }
    var textMuted: Color { Color(hex: currentTheme.textMuted) }

    var border: Color { Color(hex: currentTheme.border) }
    var divider: Color { Color(hex: currentTheme.divider) }
    var glassBackground: Color { Color(hex: currentTheme.glassBackground).opacity(0.75) }
    var glassBorder: Color { Color.white.opacity(currentTheme.glassBorderOpacity) }
}
