//
//  TerminalSuggestionsView.swift
//  AevonX
//
//  Command suggestions popup for the terminal
//

import SwiftUI

// MARK: - Suggestions View

struct TerminalSuggestionsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                Button(action: { onSelect(suggestion) }) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "command")
                            .foregroundColor(.axAccentBlue)
                            .font(.system(size: 11))

                        Text(suggestion)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)

                        Spacer()

                        if index == 0 {
                            Text("⇥")
                                .font(.system(size: 11))
                                .foregroundColor(.axTextTertiary)
                        }
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(Color.axSurface)

                if index < suggestions.count - 1 {
                    Divider()
                        .background(Color.axBorder)
                }
            }
        }
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        .padding(4)
    }
}
