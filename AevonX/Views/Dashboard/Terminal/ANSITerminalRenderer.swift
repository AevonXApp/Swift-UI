//
//  ANSITerminalRenderer.swift
//  AevonX
//
//  Renders ANSI-escaped terminal output into NSAttributedString.
//  Used by AXTerminalViewModel to produce attributed text for display.
//

import AppKit
import SwiftUI
import AevonXCoreBridge

struct ANSITerminalRenderer {

    // MARK: - Render ANSI output

    static func render(_ text: String, theme: TerminalTheme, font: NSFont) -> NSAttributedString {
        let segments = ANSIParserCore.parse(text)
        let result = NSMutableAttributedString()

        for segment in segments {
            var attrs: [NSAttributedString.Key: Any] = [
                .font: segment.isBold
                    ? NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                    : font,
                .foregroundColor: segment.foregroundColorCode.map { resolveColor($0, theme: theme) }
                    ?? NSColor(theme.foreground)
            ]
            if let bg = segment.backgroundColorCode {
                attrs[.backgroundColor] = resolveColor(bg, theme: theme)
            }
            result.append(NSAttributedString(string: segment.text, attributes: attrs))
        }

        if result.length == 0 {
            result.append(NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: NSColor(theme.foreground)
            ]))
        }

        return result
    }

    // MARK: - Render system message

    static func renderSystem(_ text: String, theme: TerminalTheme, font: NSFont) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: NSColor(theme.foreground).withAlphaComponent(0.5)
        ])
    }

    // MARK: - Color resolver

    private static func resolveColor(_ code: ANSIColorCode, theme: TerminalTheme) -> NSColor {
        switch code {
        case .black:         return NSColor(theme.black)
        case .red:           return NSColor(theme.red)
        case .green:         return NSColor(theme.green)
        case .yellow:        return NSColor(theme.yellow)
        case .blue:          return NSColor(theme.blue)
        case .magenta:       return NSColor(theme.magenta)
        case .cyan:          return NSColor(theme.cyan)
        case .white:         return NSColor(theme.white)
        case .brightBlack:   return NSColor(theme.brightBlack)
        case .brightRed:     return NSColor(theme.brightRed)
        case .brightGreen:   return NSColor(theme.brightGreen)
        case .brightYellow:  return NSColor(theme.brightYellow)
        case .brightBlue:    return NSColor(theme.brightBlue)
        case .brightMagenta: return NSColor(theme.brightMagenta)
        case .brightCyan:    return NSColor(theme.brightCyan)
        case .brightWhite:   return NSColor(theme.brightWhite)
        case .custom(let r, let g, let b):
            return NSColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
        @unknown default:    return NSColor(theme.foreground)
        }
    }
}
