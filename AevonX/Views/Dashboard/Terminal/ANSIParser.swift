//
//  ANSIParser.swift
//  AevonX
//
//  App-side ANSI parser — bridges Core's ANSIParserCore/ANSIColorCode to SwiftUI Colors.
//  The core parsing logic lives in AevonXCore.ANSIParserCore.
//

import Foundation
import SwiftUI
import AevonXCore

// MARK: - ANSI Styled Text (SwiftUI)

/// A styled text segment with SwiftUI colors (resolved from Core's ANSIColorCode)
struct ANSIStyledText: Equatable {
    let text: String
    let foregroundColor: Color?
    let backgroundColor: Color?
    let isBold: Bool
    let isItalic: Bool
    let isUnderline: Bool
}

// MARK: - ANSI Color (SwiftUI bridge)

/// Extension to convert Core's ANSIColorCode to SwiftUI Color
extension ANSIColorCode {
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
}

// MARK: - ANSI Parser (SwiftUI bridge)

/// App-side ANSI parser — uses Core's ANSIParserCore and converts to SwiftUI types
struct ANSIParser {
    
    /// Parse ANSI text and return SwiftUI-styled segments
    static func parse(_ text: String) -> [ANSIStyledText] {
        let coreSegments = ANSIParserCore.parse(text)
        return coreSegments.map { segment in
            ANSIStyledText(
                text: segment.text,
                foregroundColor: segment.foregroundColorCode?.swiftUIColor,
                backgroundColor: segment.backgroundColorCode?.swiftUIColor,
                isBold: segment.isBold,
                isItalic: segment.isItalic,
                isUnderline: segment.isUnderline
            )
        }
    }
    
    /// Strip all ANSI codes from text (delegates to Core)
    static func strip(_ text: String) -> String {
        ANSIParserCore.strip(text)
    }
}
