//
//  AXLogTableRow.swift
//  AevonX
//
//  Single row in a parsed/structured log table.
//  Used by AXAdvancedLogsView.
//

import SwiftUI

// MARK: - AX Log Tab Button

struct AXLogTabButton: View {
    let tab: AXLogTab
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))

                Text(tab.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? .white : tab.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? tab.color : tab.color.opacity(0.15))
                        .cornerRadius(10)
                }
            }
            .foregroundColor(isSelected ? tab.color : .axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(isSelected ? tab.color.opacity(0.1) : (isHovered ? Color.axBackground.opacity(0.5) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(isSelected ? tab.color.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - AX Log Table Row

struct AXLogTableRow: View {
    let log: AXLogEntryDisplay
    let isEven: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Time
                Text(log.timeFormatted)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .frame(width: 140, alignment: .leading)

                if log.type == .access {
                    // IP Address
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                            .font(.system(size: 9))
                            .foregroundColor(.axAccentBlue)
                        Text(log.ip ?? "N/A")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                    }
                    .frame(width: 130, alignment: .leading)

                    // Method
                    Text(log.method ?? "")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(methodColor(log.method))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(methodColor(log.method).opacity(0.1))
                        .cornerRadius(4)
                        .frame(width: 70, alignment: .leading)

                    // Status Code
                    Text(log.statusCode != nil ? "\(log.statusCode!)" : "")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor(log.statusCode))
                        .cornerRadius(6)
                        .frame(width: 80, alignment: .leading)
                } else {
                    // Error Level
                    HStack(spacing: 4) {
                        Image(systemName: log.levelIcon)
                            .font(.system(size: 10))
                        Text(log.level?.uppercased() ?? "")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(log.levelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(log.levelColor.opacity(0.1))
                    .cornerRadius(6)
                    .frame(width: 80, alignment: .leading)
                }

                // URL or Message
                Text(log.urlOrMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(1)
                    .frame(minWidth: 200, alignment: .leading)

                Spacer()

                // Expand Icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextTertiary)
                    .opacity(isHovered ? 1 : 0)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(isHovered ? Color.axAccentBlue.opacity(0.05) : (isEven ? Color.axBackground : Color.axSurface.opacity(0.3)))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovered = hovering }
    }

    private func methodColor(_ method: String?) -> Color {
        guard let method = method else { return .axTextMuted }
        switch method {
        case "GET": return .axAccentBlue
        case "POST": return .axSuccess
        case "PUT": return .axWarning
        case "DELETE": return .axError
        default: return .axTextSecondary
        }
    }

    private func statusColor(_ code: Int?) -> Color {
        guard let code = code else { return .axTextMuted }
        switch code {
        case 200..<300: return .axSuccess
        case 300..<400: return .axAccentBlue
        case 400..<500: return .axWarning
        case 500..<600: return .axError
        default: return .axTextMuted
        }
    }
}
