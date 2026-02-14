//
//  ANSIParser.swift
//  AevonX
//
//  ANSI Escape Code Parser for Terminal
//  Handles colors, text formatting, and control sequences
//

import Foundation
import SwiftUI

// MARK: - ANSI Text Style

/// Represents a styled segment of terminal text
struct ANSIStyledText {
    let text: String
    let foregroundColor: Color?
    let backgroundColor: Color?
    let isBold: Bool
    let isItalic: Bool
    let isUnderline: Bool
}

// MARK: - ANSI Color

/// ANSI color codes (standard 16 colors)
enum ANSIColor {
    case black
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan
    case white
    case brightBlack
    case brightRed
    case brightGreen
    case brightYellow
    case brightBlue
    case brightMagenta
    case brightCyan
    case brightWhite
    case custom(r: Int, g: Int, b: Int)

    var swiftUIColor: Color {
        switch self {
        case .black:        return Color(red: 0.0, green: 0.0, blue: 0.0)
        case .red:          return Color(red: 0.8, green: 0.0, blue: 0.0)
        case .green:        return Color(red: 0.0, green: 0.8, blue: 0.0)
        case .yellow:       return Color(red: 0.8, green: 0.8, blue: 0.0)
        case .blue:         return Color(red: 0.0, green: 0.0, blue: 0.8)
        case .magenta:      return Color(red: 0.8, green: 0.0, blue: 0.8)
        case .cyan:         return Color(red: 0.0, green: 0.8, blue: 0.8)
        case .white:        return Color(red: 0.8, green: 0.8, blue: 0.8)
        case .brightBlack:  return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .brightRed:    return Color(red: 1.0, green: 0.0, blue: 0.0)
        case .brightGreen:  return Color(red: 0.0, green: 1.0, blue: 0.0)
        case .brightYellow: return Color(red: 1.0, green: 1.0, blue: 0.0)
        case .brightBlue:   return Color(red: 0.3, green: 0.3, blue: 1.0)
        case .brightMagenta:return Color(red: 1.0, green: 0.0, blue: 1.0)
        case .brightCyan:   return Color(red: 0.0, green: 1.0, blue: 1.0)
        case .brightWhite:  return Color(red: 1.0, green: 1.0, blue: 1.0)
        case .custom(let r, let g, let b):
            return Color(red: Double(r) / 255.0, green: Double(g) / 255.0, blue: Double(b) / 255.0)
        }
    }

    /// Parse ANSI color code
    static func from(code: Int) -> ANSIColor? {
        switch code {
        case 30, 40: return .black
        case 31, 41: return .red
        case 32, 42: return .green
        case 33, 43: return .yellow
        case 34, 44: return .blue
        case 35, 45: return .magenta
        case 36, 46: return .cyan
        case 37, 47: return .white
        case 90, 100: return .brightBlack
        case 91, 101: return .brightRed
        case 92, 102: return .brightGreen
        case 93, 103: return .brightYellow
        case 94, 104: return .brightBlue
        case 95, 105: return .brightMagenta
        case 96, 106: return .brightCyan
        case 97, 107: return .brightWhite
        default: return nil
        }
    }
}

// MARK: - ANSI Parser

/// Parser for ANSI escape sequences
struct ANSIParser {

    /// Parse ANSI text and return styled segments
    /// - Parameter text: Text with ANSI codes
    /// - Returns: Array of styled text segments
    static func parse(_ text: String) -> [ANSIStyledText] {
        var result: [ANSIStyledText] = []
        var currentText = ""
        var foregroundColor: ANSIColor?
        var backgroundColor: ANSIColor?
        var isBold = false
        var isItalic = false
        var isUnderline = false

        let pattern = "\u{1B}\\[([0-9;]*)m"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        var lastIndex = text.startIndex
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))

        for match in matches {
            // Text before the escape sequence
            let beforeRange = lastIndex..<text.index(text.startIndex, offsetBy: match.range.location)
            let beforeText = String(text[beforeRange])

            if !beforeText.isEmpty {
                currentText += beforeText
            }

            // Parse the escape sequence
            if let codesRange = Range(match.range(at: 1), in: text) {
                let codesString = String(text[codesRange])
                let codes = codesString.split(separator: ";").compactMap { Int($0) }

                // If we have accumulated text, add it to result before applying new style
                if !currentText.isEmpty {
                    result.append(ANSIStyledText(
                        text: currentText,
                        foregroundColor: foregroundColor?.swiftUIColor,
                        backgroundColor: backgroundColor?.swiftUIColor,
                        isBold: isBold,
                        isItalic: isItalic,
                        isUnderline: isUnderline
                    ))
                    currentText = ""
                }

                // Apply style codes
                for code in codes {
                    switch code {
                    case 0: // Reset all
                        foregroundColor = nil
                        backgroundColor = nil
                        isBold = false
                        isItalic = false
                        isUnderline = false
                    case 1: // Bold
                        isBold = true
                    case 3: // Italic
                        isItalic = true
                    case 4: // Underline
                        isUnderline = true
                    case 22: // Normal intensity
                        isBold = false
                    case 23: // Not italic
                        isItalic = false
                    case 24: // Not underlined
                        isUnderline = false
                    case 30...37, 90...97: // Foreground colors
                        foregroundColor = ANSIColor.from(code: code)
                    case 40...47, 100...107: // Background colors
                        backgroundColor = ANSIColor.from(code: code)
                    default:
                        break
                    }
                }
            }

            lastIndex = text.index(text.startIndex, offsetBy: match.range.location + match.range.length)
        }

        // Add remaining text
        let remainingText = String(text[lastIndex...])
        if !remainingText.isEmpty {
            currentText += remainingText
        }

        if !currentText.isEmpty {
            result.append(ANSIStyledText(
                text: currentText,
                foregroundColor: foregroundColor?.swiftUIColor,
                backgroundColor: backgroundColor?.swiftUIColor,
                isBold: isBold,
                isItalic: isItalic,
                isUnderline: isUnderline
            ))
        }

        // If no ANSI codes found, return plain text
        if result.isEmpty && !text.isEmpty {
            result.append(ANSIStyledText(
                text: text,
                foregroundColor: nil,
                backgroundColor: nil,
                isBold: false,
                isItalic: false,
                isUnderline: false
            ))
        }

        return result
    }

    /// Strip all ANSI codes from text
    /// - Parameter text: Text with ANSI codes
    /// - Returns: Plain text without ANSI codes
    static func strip(_ text: String) -> String {
        var cleaned = text

        // Remove all ANSI escape sequences
        let patterns = [
            "\u{1B}\\[[0-9;]*m",           // Color and style codes
            "\u{1B}\\[[0-9;]*[A-Za-z]",    // Cursor movement and other commands
            "\u{1B}\\[\\?[0-9]*[a-z]",     // Mode changes
            "\u{1B}\\][0-9];[^\u{07}]*\u{07}", // OSC sequences
            "\u{1B}\\]0;[^\u{07}]*\u{07}", // Window title
            "\r",                           // Carriage return
        ]

        for pattern in patterns {
            cleaned = cleaned.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }

        return cleaned
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Apply ANSI text style
    func ansiStyle(_ style: ANSIStyledText) -> some View {
        self
            .foregroundColor(style.foregroundColor ?? .white)
            .background(style.backgroundColor ?? .clear)
            .fontWeight(style.isBold ? .bold : .regular)
            .italic(style.isItalic)
            .underline(style.isUnderline)
    }
}
