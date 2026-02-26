//
//  HookComponentStyles.swift
//  AevonX
//
//  Shared design tokens for hook components — v1.0
//  Defines consistent styling for headers, cells, badges, and cards.
//

import SwiftUI

// MARK: - Hook Component Styles (v1.0)

public enum HookComponentStyles {

    // MARK: - Typography

    public struct ColumnHeader: ViewModifier {
        let isActive: Bool

        public func body(content: Content) -> some View {
            content
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isActive ? .axAccentBlue : .axTextSecondary)
                .tracking(0.5)
                .textCase(.uppercase)
        }
    }

    public struct CellText: ViewModifier {
        let type: CellType

        public func body(content: Content) -> some View {
            content
                .font(type.font)
                .foregroundColor(type.color)
                .lineLimit(1)
        }
    }

    // MARK: - Cell Types

    public enum CellType {
        case text, number, ip, datetime, code, badge

        var font: Font {
            switch self {
            case .text:     return .system(size: 12)
            case .number:   return .system(size: 12, weight: .medium, design: .monospaced)
            case .ip:       return .system(size: 11, weight: .medium, design: .monospaced)
            case .datetime: return .system(size: 11, design: .monospaced)
            case .code:     return .system(size: 11, design: .monospaced)
            case .badge:    return .system(size: 10, weight: .semibold)
            }
        }

        var color: Color {
            switch self {
            case .text:     return .axTextPrimary
            case .number:   return .axTextPrimary
            case .ip:       return .axAccentBlue
            case .datetime: return .axTextSecondary
            case .code:     return .axTextSecondary
            case .badge:    return .white
            }
        }
    }

    // MARK: - Badge Styles

    public enum BadgeStyle {
        case critical, warning, info, success, neutral

        var backgroundColor: Color {
            switch self {
            case .critical: return .axError
            case .warning:  return .axWarning
            case .info:     return .axAccentBlue
            case .success:  return .axSuccess
            case .neutral:  return Color.axTextMuted.opacity(0.3)
            }
        }

        var textColor: Color {
            switch self {
            case .neutral:  return .axTextSecondary
            default:        return .white
            }
        }
    }

    // MARK: - Severity Mapping

    public static func badgeStyle(for value: String) -> BadgeStyle {
        let lower = value.lowercased()
        if lower.contains("critical") || lower.contains("error") || lower.contains("block") {
            return .critical
        }
        if lower.contains("warn") || lower.contains("high") || lower.contains("emergency") {
            return .warning
        }
        if lower.contains("info") || lower.contains("medium") {
            return .info
        }
        if lower.contains("success") || lower.contains("active") || lower.contains("allow") {
            return .success
        }
        return .neutral
    }

    // MARK: - Card Elevation

    public struct CardElevation: ViewModifier {
        let level: Int

        public func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(Color.axSurface)
                        .shadow(color: Color.black.opacity(Double(level) * 0.02), radius: CGFloat(level * 3), y: CGFloat(level))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(Color.axBorder.opacity(0.4), lineWidth: 1)
                )
        }
    }
}

// MARK: - View Extensions

extension View {
    func hookColumnHeader(active: Bool = false) -> some View {
        modifier(HookComponentStyles.ColumnHeader(isActive: active))
    }

    func hookCellStyle(_ type: HookComponentStyles.CellType = .text) -> some View {
        modifier(HookComponentStyles.CellText(type: type))
    }

    func hookCardElevation(_ level: Int = 1) -> some View {
        modifier(HookComponentStyles.CardElevation(level: level))
    }
}

// Backward compatibility
public typealias PluginComponentStyles = HookComponentStyles
