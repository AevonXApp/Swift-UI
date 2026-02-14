//
//  TerminalTab.swift
//  AevonX
//
//  Real Interactive Terminal - Like a Real Terminal Emulator
//

import SwiftUI
import AevonXCore
import AppKit

// MARK: - Terminal Tab View

struct TerminalTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var viewModel: ServerConnectionViewModel
    
    // The current active session from viewModel
    private var activeVM: TerminalViewModel? {
        guard viewModel.terminalSessions.indices.contains(viewModel.activeTerminalIndex) else {
            return nil
        }
        return viewModel.terminalSessions[viewModel.activeTerminalIndex]
    }

    init(server: Server, serverId: String, viewModel: ServerConnectionViewModel) {
        self.server = server
        self.serverId = serverId
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header / Tabs
            HStack(spacing: 0) {
                terminalTabs
                
                Spacer()
                
                terminalActions
                
                terminalHeader
                    .padding(.trailing, 12)
            }
            .frame(height: 44)
            .background(Color.axSurface.opacity(0.8))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.axBorder)
                , alignment: .bottom
            )

            // Terminal Content
            ZStack {
                if let terminalVM = activeVM {
                    RealTerminalView(viewModel: terminalVM)
                } else {
                    VStack {
                        ProgressView()
                        Text("Initializing session...")
                            .foregroundColor(.axTextMuted)
                            .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onDisappear {
            // Instant cleanup of suggestions
            activeVM?.closeSuggestions()
        }
    }

    // MARK: - Subviews

    private var terminalTabs: some View {
        HStack(spacing: 1) {
            ForEach(viewModel.terminalSessions.indices, id: \.self) { index in
                Button(action: { viewModel.activeTerminalIndex = index }) {
                    HStack(spacing: 8) {
                        Image(systemName: "terminal")
                            .font(.system(size: 11))
                        
                        Text("Session \(index + 1)")
                            .font(.system(size: 13))
                        
                        if viewModel.terminalSessions.count > 1 {
                            Button(action: { viewModel.closeTerminalSession(at: index) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8))
                            }
                            .buttonStyle(.plain)
                            .opacity(0.6)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(viewModel.activeTerminalIndex == index ? Color.axBackground : Color.clear)
                    .foregroundColor(viewModel.activeTerminalIndex == index ? .white : .axTextMuted)
                }
                .buttonStyle(.plain)
                
                Divider()
                    .frame(height: 24)
            }
            
            Button(action: { viewModel.createTerminalSession() }) {
                Image(systemName: "plus")
                    .font(.system(size: 14))
                    .padding(12)
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
    }

    private var terminalActions: some View {
        HStack(spacing: 16) {
            Button(action: { activeVM?.clear() }) {
                Label("Clear", systemImage: "trash")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(.axTextMuted)
            
            Button(action: { activeVM?.disconnect() }) {
                Label("Disconnect", systemImage: "power")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(.axError.opacity(0.8))
        }
        .padding(.trailing, 20)
    }

    // MARK: - Minimal Header

    private var terminalHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "terminal.fill")
                .foregroundColor(statusColor)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                if let vm = activeVM, vm.isConnected {
                    Text("\(vm.username)@\(vm.hostname)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            connectionStatusBadge
        }
        .padding(12)
        .background(Color(white: 0.1))
    }

    private var connectionStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        guard let vm = activeVM else { return .gray }
        switch vm.state {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private var statusText: String {
        guard let vm = activeVM else { return "Disconnected" }
        switch vm.state {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }
}

// MARK: - Real Terminal View (NSView)

struct RealTerminalView: NSViewRepresentable {
    @ObservedObject var viewModel: TerminalViewModel

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()

        // Configure text view like a real terminal
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = .white
        textView.backgroundColor = NSColor(white: 0.05, alpha: 1)
        textView.insertionPointColor = .green
        textView.drawsBackground = true
        
        // Handle layout properly
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.delegate = context.coordinator

        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.backgroundColor = NSColor(white: 0.05, alpha: 1)
        scrollView.autohidesScrollers = true

        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Build terminal text from output lines
        var fullText = ""

        // Add all output lines
        if !viewModel.lines.isEmpty {
            fullText = viewModel.lines.map { $0.content }.joined(separator: "\n")
            fullText += "\n"
        }

        // Add current prompt and input
        if viewModel.isConnected {
            fullText += viewModel.partialLine + viewModel.prompt + viewModel.inputCommand
        } else if viewModel.state == .connecting {
            // Show connecting message
            fullText += "Connecting to server...\n"
        } else if case .error(let msg) = viewModel.state {
            // Show error
            fullText += "Error: \(msg)\n"
        } else {
            // Show disconnected message
            fullText += "Terminal disconnected. Please connect from Overview tab.\n"
        }

        // Only update if text actually changed
        if textView.string != fullText {
            // Save cursor position
            let wasAtEnd = textView.selectedRange().location >= (textView.string as NSString).length - viewModel.inputCommand.count

            // Update text
            textView.string = fullText

            // Restore cursor position
            let newLength = (fullText as NSString).length
            if wasAtEnd || viewModel.inputCommand.isEmpty {
                // Put cursor at end
                textView.setSelectedRange(NSRange(location: newLength, length: 0))
            } else {
                // Keep cursor in input area
                let promptLength = (viewModel.prompt as NSString).length
                let inputStart = newLength - viewModel.inputCommand.count
                let cursorInInput = max(inputStart, min(newLength, textView.selectedRange().location))
                textView.setSelectedRange(NSRange(location: cursorInInput, length: 0))
            }

            // Scroll to show cursor
            textView.scrollRangeToVisible(textView.selectedRange())
        }

        // Update suggestions overlay
        context.coordinator.updateSuggestions(viewModel.commandSuggestions)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        @ObservedObject var viewModel: TerminalViewModel
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var suggestionsWindow: NSWindow?
        var lastPromptLength = 0

        init(viewModel: TerminalViewModel) {
            self.viewModel = viewModel
            super.init()
            
            // Connect close signal
            viewModel.onCloseSuggestions = { [weak self] in
                DispatchQueue.main.async {
                    self?.suggestionsWindow?.close()
                    self?.suggestionsWindow = nil
                }
            }
        }
        
        deinit {
            // Ensure window is closed when coordinator is destroyed
            DispatchQueue.main.async { [suggestionsWindow] in
                suggestionsWindow?.close()
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            let text = textView.string

            // Build the expected prefix (output + prompt)
            var prefix = ""
            if !viewModel.lines.isEmpty {
                prefix = viewModel.lines.map { $0.content }.joined(separator: "\n") + "\n"
            }
            prefix += viewModel.partialLine + viewModel.prompt

            let prefixLength = prefix.count

            // Extract current input after the prompt
            if text.count >= prefixLength {
                let startIndex = text.index(text.startIndex, offsetBy: prefixLength)
                let currentInput = String(text[startIndex...])

                // Update view model if input changed
                if currentInput != viewModel.inputCommand {
                    DispatchQueue.main.async {
                        self.viewModel.inputCommand = currentInput
                        self.viewModel.updateCommandSuggestions()
                    }
                }
            } else if !viewModel.inputCommand.isEmpty {
                // Text is shorter than prefix, clear input
                DispatchQueue.main.async {
                    self.viewModel.inputCommand = ""
                    self.viewModel.updateCommandSuggestions()
                }
            }
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard let replacement = replacementString else { return true }

            // Build prefix (output + prompt)
            var prefix = ""
            if !viewModel.lines.isEmpty {
                prefix = viewModel.lines.map { $0.content }.joined(separator: "\n") + "\n"
            }
            prefix += viewModel.partialLine + viewModel.prompt
            let promptLength = (prefix as NSString).length

            // Handle special control characters
            // Ctrl+C (ETX - End of Text)
            if replacement == "\u{03}" {
                viewModel.sendInterrupt()
                return false
            }

            // Ctrl+D (EOT - End of Transmission)
            if replacement == "\u{04}" {
                viewModel.sendEOF()
                return false
            }

            // Ctrl+Z (SUB - Substitute)
            if replacement == "\u{1A}" {
                viewModel.sendSuspend()
                return false
            }

            // Ctrl+L (Form Feed) - Clear screen
            if replacement == "\u{0C}" {
                viewModel.clear()
                return false
            }

            // Prevent editing before prompt
            if affectedCharRange.location < promptLength {
                // Only allow if we're at the end
                if affectedCharRange.location + affectedCharRange.length < promptLength {
                    return false
                }
            }

            // Handle Enter key
            if replacement == "\n" {
                // Send command
                Task { @MainActor in
                    viewModel.commandSuggestions = [] // Clear suggestions immediately
                    viewModel.sendCommand()
                }
                return false
            }

            return true
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.moveUp(_:)):
                // Up arrow - previous command
                viewModel.previousCommand()
                return true

            case #selector(NSResponder.moveDown(_:)):
                // Down arrow - next command
                viewModel.nextCommand()
                return true

            case #selector(NSResponder.insertTab(_:)):
                // Tab - autocomplete/accept suggestion
                if let first = viewModel.commandSuggestions.first {
                    viewModel.acceptSuggestion(first)
                } else {
                    viewModel.sendTab()
                }
                return true

            case #selector(NSResponder.cancelOperation(_:)):
                // Escape - clear suggestions
                viewModel.commandSuggestions = []
                return true

            default:
                return false
            }
        }

        // MARK: - Suggestions UI

        func updateSuggestions(_ suggestions: [String]) {
            guard let textView = textView, let window = textView.window else {
                suggestionsWindow?.close()
                suggestionsWindow = nil
                return
            }

            if suggestions.isEmpty {
                suggestionsWindow?.close()
                suggestionsWindow = nil
                return
            }

            // Show suggestions popup near cursor
            let selectedRange = textView.selectedRange()
            let cursorRect = textView.firstRect(forCharacterRange: selectedRange, actualRange: nil)
            
            // Convert rect to screen coordinates
            let screenRect = window.convertToScreen(cursorRect)

            if suggestionsWindow == nil {
                let panel = NSPanel(
                    contentRect: NSRect(x: screenRect.minX, y: screenRect.minY - 140, width: 320, height: 140),
                    styleMask: [.nonactivatingPanel, .borderless],
                    backing: .buffered,
                    defer: false
                )
                panel.isFloatingPanel = true
                panel.level = .popUpMenu // Ensure it's above everything but doesn't take focus
                panel.isOpaque = false
                panel.backgroundColor = .clear
                panel.hasShadow = true
                panel.hidesOnDeactivate = true // Close when app is not active

                suggestionsWindow = panel
            }

            // Update suggestions content
            let hostingView = NSHostingView(rootView: SuggestionsView(
                suggestions: suggestions,
                onSelect: { [weak self] suggestion in
                    self?.viewModel.acceptSuggestion(suggestion)
                }
            ))

            suggestionsWindow?.contentView = hostingView
            
            // Re-calculate size based on number of suggestions
            let height: CGFloat = CGFloat(suggestions.count * 32 + 12)
            suggestionsWindow?.setFrame(NSRect(x: screenRect.minX, y: screenRect.minY - height - 5, width: 320, height: height), display: true)
            
            // Ensure window is on front
            if suggestionsWindow?.isVisible == false {
                suggestionsWindow?.orderFront(nil)
            }
        }
    }
}

// MARK: - Suggestions View

struct SuggestionsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                Button(action: {
                    onSelect(suggestion)
                }) {
                    HStack {
                        Image(systemName: "command")
                            .foregroundColor(.green)
                            .font(.system(size: 11))

                        Text(suggestion)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white)

                        Spacer()

                        if index == 0 {
                            Text("⇥")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.15))
                }
                .buttonStyle(.plain)
                .background(Color(white: 0.1))

                if index < suggestions.count - 1 {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .background(Color(white: 0.08))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        .padding(4)
    }
}

// MARK: - Preview

#Preview {
    let testServer = Server(
        name: "Test Server",
        host: "example.com",
        port: 22,
        username: "admin",
        status: .online,
        type: .remote,
        tags: ["test"],
        lastConnected: Date(),
        os: "Ubuntu 22.04",
        location: "US-East"
    )
    let testServerId = UUID().uuidString

    return TerminalTab(
        server: testServer,
        serverId: testServerId,
        viewModel: ServerConnectionViewModel(
            server: testServer,
            serverId: testServerId
        )
    )
    .frame(width: 900, height: 600)
}
