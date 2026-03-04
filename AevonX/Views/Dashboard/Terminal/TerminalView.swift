//
//  TerminalView.swift
//  AevonX
//
//  Pure SwiftUI terminal view — same pattern as DockerTerminalView
//  ScrollView (read-only output) + TextField (input)
//

import SwiftUI
import AevonXCore

// MARK: - Terminal View

struct TerminalView: View {
    @ObservedObject var viewModel: TerminalViewModel
    @ObservedObject var preferences: TerminalPreferences
    @FocusState var isInputFocused: Bool

    var body: some View {
        let theme = preferences.theme

        VStack(spacing: 0) {
            // MARK: - Output Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.lines) { line in
                            Text(line.content)
                                .font(.system(size: CGFloat(preferences.fontSize), design: .monospaced))
                                .foregroundColor(colorForLineType(line.type, theme: theme))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 0.5)
                                .id(line.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(theme.background)
                .onChange(of: viewModel.lines.count) { _, _ in
                    if let lastId = viewModel.lines.last?.id {
                        withAnimation(.none) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            // MARK: - Input Bar
            if viewModel.isConnected {
                inputBar(theme: theme)
            } else if viewModel.state == .connecting || viewModel.state == .reconnecting(attempt: 0) {
                statusBar(text: "Connecting...", color: theme.yellow, background: theme.background)
            }
        }
        .background(theme.background)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
    }

    // MARK: - Input Bar

    private func inputBar(theme: TerminalTheme) -> some View {
        VStack(spacing: 0) {
            // Suggestions popup (above input)
            if !viewModel.commandSuggestions.isEmpty {
                suggestionsOverlay(theme: theme)
            }

            HStack(spacing: 10) {
                // Prompt indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.axSuccess : Color.axError)
                        .frame(width: 6, height: 6)
                    
                    Text(viewModel.prompt)
                        .font(.system(size: CGFloat(preferences.fontSize), weight: .semibold, design: .monospaced))
                        .foregroundColor(theme.green)
                        .lineLimit(1)
                }

                // Command input
                TextField("Type a command...", text: $viewModel.inputCommand)
                    .font(.system(size: CGFloat(preferences.fontSize), design: .monospaced))
                    .foregroundColor(theme.foreground)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isInputFocused)
                    .onSubmit {
                        viewModel.sendCommand()
                    }
                    .onChange(of: viewModel.inputCommand) { _, _ in
                        Task { @MainActor in
                            viewModel.updateSuggestions()
                        }
                    }
                    .onKeyPress(.upArrow) {
                        viewModel.previousCommand()
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        viewModel.nextCommand()
                        return .handled
                    }
                    .onKeyPress(.tab) {
                        if let first = viewModel.commandSuggestions.first {
                            viewModel.acceptSuggestion(first)
                        } else {
                            viewModel.sendTab()
                        }
                        return .handled
                    }
                    .onKeyPress(.escape) {
                        viewModel.commandSuggestions = []
                        return .handled
                    }
                    .disabled(!viewModel.isConnected)

                // Action buttons
                HStack(spacing: 6) {
                    // Tab completion
                    Button(action: { viewModel.sendTab() }) {
                        Text("Tab")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(theme.foreground.opacity(0.5))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Tab completion")
                    
                    // Ctrl+C
                    Button(action: { viewModel.sendInterrupt() }) {
                        Text("⌃C")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.red.opacity(0.8))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(theme.red.opacity(0.08))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(theme.red.opacity(0.15), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Send interrupt (Ctrl+C)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color.black.opacity(0.3)
                    .background(.ultraThinMaterial)
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.axBorder.opacity(0.1), Color.axBorder.opacity(0.4), Color.axBorder.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ),
                alignment: .top
            )
        }
    }

    // MARK: - Suggestions

    private func suggestionsOverlay(theme: TerminalTheme) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.commandSuggestions, id: \.self) { suggestion in
                Button(action: {
                    viewModel.acceptSuggestion(suggestion)
                    isInputFocused = true
                }) {
                    Text(suggestion)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(theme.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.clear)
                .contentShape(Rectangle())

                if suggestion != viewModel.commandSuggestions.last {
                    Divider().background(Color.axBorder.opacity(0.2))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.axSurface)
                .shadow(color: .black.opacity(0.3), radius: 8, y: -4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.axBorder, lineWidth: 0.5)
        )
        .padding(.horizontal, 12)
    }

    // MARK: - Status Bar

    private func statusBar(text: String, color: Color, background: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ProgressView()
                .scaleEffect(0.6)
                .tint(color)
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
    }

    // MARK: - Helpers

    private func colorForLineType(_ type: SSHTerminalLine.LineType, theme: TerminalTheme) -> Color {
        switch type {
        case .output: return theme.foreground
        case .system: return theme.cyan
        case .error:  return theme.red
        case .input:  return theme.green
        }
    }
}
