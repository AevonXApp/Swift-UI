//
//  TerminalSuggestionOverlay.swift
//  AevonX
//
//  Compact Warp-style suggestion panel.
//  Appears BELOW the cursor line (into empty space).
//  Falls back to above if no space below.
//

import SwiftUI

struct TerminalSuggestionOverlay: View {

    @ObservedObject var session: TerminalTabViewModel
    let onSelect: (String) -> Void

    @State private var hovered: String? = nil

    private let panelMaxH: CGFloat = 180
    private let rowPadV:   CGFloat = 6

    var body: some View {
        if !session.suggestions.isEmpty && session.isConnected {
            GeometryReader { geo in
                let rows        = max(1, session.terminalRows)
                let rowH        = geo.size.height / CGFloat(rows)
                let cursorBotY  = CGFloat(session.cursorRow + 1) * rowH + 2
                let spaceBelow  = geo.size.height - cursorBotY

                // Show below cursor if enough room, otherwise above
                let panelTop: CGFloat = spaceBelow >= panelMaxH
                    ? cursorBotY
                    : cursorBotY - panelMaxH - rowH - 4

                VStack(alignment: .leading, spacing: 0) {
                    panel
                }
                .frame(maxWidth: 480, alignment: .leading)
                .padding(.horizontal, 14)
                .offset(y: max(0, panelTop))
            }
            .allowsHitTesting(true)
        }
    }

    // MARK: - Panel

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(session.suggestions.prefix(5).enumerated()), id: \.element) { idx, suggestion in
                row(suggestion: suggestion, index: idx)
                if idx < min(session.suggestions.count, 5) - 1 {
                    Divider().background(Color.white.opacity(0.05))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.14).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.65), radius: 14, y: 4)
    }

    // MARK: - Row

    private func row(suggestion: String, index: Int) -> some View {
        Button(action: { onSelect(suggestion) }) {
            HStack(spacing: 8) {
                Image(systemName: isFromHistory(suggestion) ? "clock.arrow.2.circlepath" : "terminal")
                    .font(.system(size: 9))
                    .foregroundColor(index == 0 ? .axAccentBlue : Color.white.opacity(0.25))
                    .frame(width: 12)

                HStack(spacing: 0) {
                    let matchLen = min(session.currentInput.count, suggestion.count)
                    Text(String(suggestion.prefix(matchLen)))
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    Text(String(suggestion.dropFirst(matchLen)))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .font(.system(size: 12, design: .monospaced))

                Spacer()

                Text("↵")
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.14))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, rowPadV)
            .background(hovered == suggestion ? Color.white.opacity(0.07) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { on in hovered = on ? suggestion : nil }
    }

    private func isFromHistory(_ s: String) -> Bool {
        session.commandHistory.contains { $0.lowercased() == s.lowercased() }
    }
}
