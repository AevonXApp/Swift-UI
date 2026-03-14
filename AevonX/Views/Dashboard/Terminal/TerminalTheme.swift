//
//  TerminalTheme.swift
//  AevonX
//
//  Terminal color themes with full ANSI color mapping
//  Uses ANSIColorCode from AevonXCore for color mapping
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Terminal Theme

/// A complete terminal color theme (app-side, uses SwiftUI Color)
struct TerminalTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let background: Color
    let foreground: Color
    let cursor: Color
    let selection: Color
    let selectionText: Color
    
    // ANSI Standard 16 Colors
    let black: Color
    let red: Color
    let green: Color
    let yellow: Color
    let blue: Color
    let magenta: Color
    let cyan: Color
    let white: Color
    let brightBlack: Color
    let brightRed: Color
    let brightGreen: Color
    let brightYellow: Color
    let brightBlue: Color
    let brightMagenta: Color
    let brightCyan: Color
    let brightWhite: Color
    
    /// Map Core ANSI color code to theme color
    func colorForANSI(_ ansiColor: ANSIColorCode) -> Color {
        switch ansiColor {
        case .black: return black
        case .red: return red
        case .green: return green
        case .yellow: return yellow
        case .blue: return blue
        case .magenta: return magenta
        case .cyan: return cyan
        case .white: return white
        case .brightBlack: return brightBlack
        case .brightRed: return brightRed
        case .brightGreen: return brightGreen
        case .brightYellow: return brightYellow
        case .brightBlue: return brightBlue
        case .brightMagenta: return brightMagenta
        case .brightCyan: return brightCyan
        case .brightWhite: return brightWhite
        case .custom(let r, let g, let b):
            return Color(red: Double(r) / 255.0, green: Double(g) / 255.0, blue: Double(b) / 255.0)
        }
    }
}

// MARK: - Built-in Themes

extension TerminalTheme {
    
    static let allThemes: [TerminalTheme] = [
        .aevonxDark, .dracula, .monokai, .solarizedDark, .nord, .oneDark
    ]
    
    /// Default AevonX theme — matches the app's design system
    static let aevonxDark = TerminalTheme(
        id: "aevonx-dark", name: "AevonX Dark",
        background: Color(hex: "#121212"), foreground: Color(hex: "#FAFAFA"),
        cursor: Color(hex: "#00D4FF"),
        selection: Color(hex: "#00D4FF").opacity(0.25), selectionText: Color(hex: "#FAFAFA"),
        black: Color(hex: "#1E1E1E"), red: Color(hex: "#EF4444"),
        green: Color(hex: "#22C55E"), yellow: Color(hex: "#F59E0B"),
        blue: Color(hex: "#00D4FF"), magenta: Color(hex: "#A855F7"),
        cyan: Color(hex: "#06B6D4"), white: Color(hex: "#A1A1AA"),
        brightBlack: Color(hex: "#52525B"), brightRed: Color(hex: "#F87171"),
        brightGreen: Color(hex: "#4ADE80"), brightYellow: Color(hex: "#FBBF24"),
        brightBlue: Color(hex: "#38BDF8"), brightMagenta: Color(hex: "#C084FC"),
        brightCyan: Color(hex: "#22D3EE"), brightWhite: Color(hex: "#FAFAFA")
    )
    
    static let dracula = TerminalTheme(
        id: "dracula", name: "Dracula",
        background: Color(hex: "#282A36"), foreground: Color(hex: "#F8F8F2"),
        cursor: Color(hex: "#F8F8F2"),
        selection: Color(hex: "#44475A"), selectionText: Color(hex: "#F8F8F2"),
        black: Color(hex: "#21222C"), red: Color(hex: "#FF5555"),
        green: Color(hex: "#50FA7B"), yellow: Color(hex: "#F1FA8C"),
        blue: Color(hex: "#BD93F9"), magenta: Color(hex: "#FF79C6"),
        cyan: Color(hex: "#8BE9FD"), white: Color(hex: "#F8F8F2"),
        brightBlack: Color(hex: "#6272A4"), brightRed: Color(hex: "#FF6E6E"),
        brightGreen: Color(hex: "#69FF94"), brightYellow: Color(hex: "#FFFFA5"),
        brightBlue: Color(hex: "#D6ACFF"), brightMagenta: Color(hex: "#FF92DF"),
        brightCyan: Color(hex: "#A4FFFF"), brightWhite: Color(hex: "#FFFFFF")
    )
    
    static let monokai = TerminalTheme(
        id: "monokai", name: "Monokai",
        background: Color(hex: "#272822"), foreground: Color(hex: "#F8F8F2"),
        cursor: Color(hex: "#F8F8F0"),
        selection: Color(hex: "#49483E"), selectionText: Color(hex: "#F8F8F2"),
        black: Color(hex: "#272822"), red: Color(hex: "#F92672"),
        green: Color(hex: "#A6E22E"), yellow: Color(hex: "#F4BF75"),
        blue: Color(hex: "#66D9EF"), magenta: Color(hex: "#AE81FF"),
        cyan: Color(hex: "#A1EFE4"), white: Color(hex: "#F8F8F2"),
        brightBlack: Color(hex: "#75715E"), brightRed: Color(hex: "#F92672"),
        brightGreen: Color(hex: "#A6E22E"), brightYellow: Color(hex: "#F4BF75"),
        brightBlue: Color(hex: "#66D9EF"), brightMagenta: Color(hex: "#AE81FF"),
        brightCyan: Color(hex: "#A1EFE4"), brightWhite: Color(hex: "#F9F8F5")
    )
    
    static let solarizedDark = TerminalTheme(
        id: "solarized-dark", name: "Solarized Dark",
        background: Color(hex: "#002B36"), foreground: Color(hex: "#839496"),
        cursor: Color(hex: "#93A1A1"),
        selection: Color(hex: "#073642"), selectionText: Color(hex: "#93A1A1"),
        black: Color(hex: "#073642"), red: Color(hex: "#DC322F"),
        green: Color(hex: "#859900"), yellow: Color(hex: "#B58900"),
        blue: Color(hex: "#268BD2"), magenta: Color(hex: "#D33682"),
        cyan: Color(hex: "#2AA198"), white: Color(hex: "#EEE8D5"),
        brightBlack: Color(hex: "#002B36"), brightRed: Color(hex: "#CB4B16"),
        brightGreen: Color(hex: "#586E75"), brightYellow: Color(hex: "#657B83"),
        brightBlue: Color(hex: "#839496"), brightMagenta: Color(hex: "#6C71C4"),
        brightCyan: Color(hex: "#93A1A1"), brightWhite: Color(hex: "#FDF6E3")
    )
    
    static let nord = TerminalTheme(
        id: "nord", name: "Nord",
        background: Color(hex: "#2E3440"), foreground: Color(hex: "#D8DEE9"),
        cursor: Color(hex: "#D8DEE9"),
        selection: Color(hex: "#434C5E"), selectionText: Color(hex: "#D8DEE9"),
        black: Color(hex: "#3B4252"), red: Color(hex: "#BF616A"),
        green: Color(hex: "#A3BE8C"), yellow: Color(hex: "#EBCB8B"),
        blue: Color(hex: "#81A1C1"), magenta: Color(hex: "#B48EAD"),
        cyan: Color(hex: "#88C0D0"), white: Color(hex: "#E5E9F0"),
        brightBlack: Color(hex: "#4C566A"), brightRed: Color(hex: "#BF616A"),
        brightGreen: Color(hex: "#A3BE8C"), brightYellow: Color(hex: "#EBCB8B"),
        brightBlue: Color(hex: "#81A1C1"), brightMagenta: Color(hex: "#B48EAD"),
        brightCyan: Color(hex: "#8FBCBB"), brightWhite: Color(hex: "#ECEFF4")
    )
    
    static let oneDark = TerminalTheme(
        id: "one-dark", name: "One Dark",
        background: Color(hex: "#282C34"), foreground: Color(hex: "#ABB2BF"),
        cursor: Color(hex: "#528BFF"),
        selection: Color(hex: "#3E4451"), selectionText: Color(hex: "#ABB2BF"),
        black: Color(hex: "#282C34"), red: Color(hex: "#E06C75"),
        green: Color(hex: "#98C379"), yellow: Color(hex: "#E5C07B"),
        blue: Color(hex: "#61AFEF"), magenta: Color(hex: "#C678DD"),
        cyan: Color(hex: "#56B6C2"), white: Color(hex: "#ABB2BF"),
        brightBlack: Color(hex: "#545862"), brightRed: Color(hex: "#E06C75"),
        brightGreen: Color(hex: "#98C379"), brightYellow: Color(hex: "#E5C07B"),
        brightBlue: Color(hex: "#61AFEF"), brightMagenta: Color(hex: "#C678DD"),
        brightCyan: Color(hex: "#56B6C2"), brightWhite: Color(hex: "#C8CCD4")
    )
}
