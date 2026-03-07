//
//  CodeEditorTheme.swift
//  AevonX
//
//  Editor color theme — matches the app's #121212 dark theme.
//  Colors are absolute sRGB values (appearance-independent).
//

import AppKit

// MARK: - Editor Theme (app-matched)

/// Shared editor colors used by FileCodeEditorView and LineNumberRulerView.
/// Values use absolute sRGB to avoid NSColor semantic-color resolution issues
/// when NSViewRepresentable is embedded inside a SwiftUI view hierarchy.
struct EditorTheme {
    // Backgrounds
    static let background  = NSColor(srgbRed: 0.071, green: 0.071, blue: 0.071, alpha: 1)   // #121212
    static let gutter      = NSColor(srgbRed: 0.102, green: 0.102, blue: 0.102, alpha: 1)   // #1A1A1A
    static let gutterLine  = NSColor(srgbRed: 0.153, green: 0.153, blue: 0.153, alpha: 1)   // #272727

    // Cursor & selection
    static let selection   = NSColor(srgbRed: 0.000, green: 0.831, blue: 1.000, alpha: 0.18)
    static let cursor      = NSColor(srgbRed: 0.000, green: 0.831, blue: 1.000, alpha: 1)   // #00D4FF

    // Text
    static let foreground  = NSColor(srgbRed: 0.980, green: 0.980, blue: 0.980, alpha: 1)   // #FAFAFA
    static let lineNumbers = NSColor(srgbRed: 0.388, green: 0.388, blue: 0.404, alpha: 1)   // #636366

    // Syntax
    static let keyword     = NSColor(srgbRed: 0.749, green: 0.549, blue: 0.843, alpha: 1)
    static let string      = NSColor(srgbRed: 0.596, green: 0.769, blue: 0.459, alpha: 1)
    static let number      = NSColor(srgbRed: 0.906, green: 0.776, blue: 0.447, alpha: 1)
    static let typeIdent   = NSColor(srgbRed: 0.000, green: 0.831, blue: 1.000, alpha: 1)
    static let variable    = NSColor(srgbRed: 0.878, green: 0.443, blue: 0.455, alpha: 1)
    static let property    = NSColor(srgbRed: 0.337, green: 0.757, blue: 0.722, alpha: 1)
    static let comment     = NSColor(srgbRed: 0.388, green: 0.388, blue: 0.404, alpha: 1)
}
