//
//  TerminalSwiftView.swift
//  AevonX
//
//  SwiftTerm-based terminal view.
//  Full VT100/xterm-256 emulation — vim, htop, tmux, interactive prompts all work.
//  Coordinator tracks typed input → publishes to session for suggestion overlay.
//

import SwiftUI
import AppKit
import SwiftTerm
import AevonXCoreBridge

// MARK: - SwiftTerm NSViewRepresentable

struct TerminalSwiftView: NSViewRepresentable {

    typealias NSViewType = SwiftTerm.TerminalView

    @ObservedObject var session: TerminalTabViewModel
    let font: NSFont
    let theme: TerminalTheme

    func makeCoordinator() -> Coordinator { Coordinator(session: session) }

    func makeNSView(context: Context) -> SwiftTerm.TerminalView {
        let tv = SwiftTerm.TerminalView(frame: .zero)
        tv.terminalDelegate = context.coordinator
        tv.font = font
        applyTheme(to: tv)
        context.coordinator.terminalView = tv

        session.onData = { [weak tv] data in
            let bytes = [UInt8](data)
            tv?.feed(byteArray: bytes[...])
        }

        return tv
    }

    func updateNSView(_ tv: SwiftTerm.TerminalView, context: Context) {
        tv.font = font
        applyTheme(to: tv)
    }

    // MARK: - Theme

    private func applyTheme(to tv: SwiftTerm.TerminalView) {
        tv.nativeForegroundColor = NSColor(theme.foreground)
        tv.nativeBackgroundColor = NSColor(theme.background)
        tv.installColors(build16Colors())
    }

    private func build16Colors() -> [SwiftTerm.Color] {
        [
            stColor(theme.black),          // 0
            stColor(theme.red),            // 1
            stColor(theme.green),          // 2
            stColor(theme.yellow),         // 3
            stColor(theme.blue),           // 4
            stColor(theme.magenta),        // 5
            stColor(theme.cyan),           // 6
            stColor(theme.white),          // 7
            stColor(theme.brightBlack),    // 8
            stColor(theme.brightRed),      // 9
            stColor(theme.brightGreen),    // 10
            stColor(theme.brightYellow),   // 11
            stColor(theme.brightBlue),     // 12
            stColor(theme.brightMagenta),  // 13
            stColor(theme.brightCyan),     // 14
            stColor(theme.brightWhite),    // 15
        ]
    }

    private func stColor(_ color: SwiftUI.Color) -> SwiftTerm.Color {
        let ns = NSColor(color).usingColorSpace(.deviceRGB) ?? .white
        return SwiftTerm.Color(
            red:   UInt16(ns.redComponent   * 65535),
            green: UInt16(ns.greenComponent * 65535),
            blue:  UInt16(ns.blueComponent  * 65535)
        )
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, SwiftTerm.TerminalViewDelegate {

        let session: TerminalTabViewModel
        var terminalView: SwiftTerm.TerminalView?

        // Input tracking for suggestion overlay
        private var inputBuffer = ""
        private var inEscape = false

        init(session: TerminalTabViewModel) { self.session = session }

        // User typed → raw bytes → PTY + track cursor + update suggestions
        func send(source: SwiftTerm.TerminalView, data: ArraySlice<UInt8>) {
            session.write(data: Foundation.Data(data))
            trackInput(bytes: data)
            // Read cursor position HERE (user is actively typing → cursor is at prompt)
            let row = source.terminal.getCursorLocation().y
            Task { @MainActor in self.session.cursorRow = row }
        }

        private func trackInput(bytes: ArraySlice<UInt8>) {
            for byte in bytes {
                if inEscape {
                    if byte >= 0x40 && byte <= 0x7E { inEscape = false }
                    continue
                }
                switch byte {
                case 0x1B:
                    inEscape = true
                    inputBuffer = ""
                    notify("")
                case 0x0D, 0x0A: // Enter → commit to history
                    let cmd = inputBuffer
                    inputBuffer = ""
                    notify("")
                    if !cmd.trimmingCharacters(in: .whitespaces).isEmpty {
                        Task { @MainActor in self.session.addToHistory(cmd) }
                    }
                case 0x7F: // Backspace
                    if !inputBuffer.isEmpty { inputBuffer.removeLast() }
                    notify(inputBuffer)
                case 0x03, 0x04: // Ctrl+C/D
                    inputBuffer = ""
                    notify("")
                case 0x09: // Tab — shell handles completion
                    inputBuffer = ""
                    notify("")
                default:
                    if byte >= 0x20 && byte < 0x7F {
                        inputBuffer.append(Character(UnicodeScalar(byte)))
                        notify(inputBuffer)
                    }
                }
            }
        }

        private func notify(_ value: String) {
            let v = value
            Task { @MainActor in self.session.currentInput = v }
        }

        func sizeChanged(source: SwiftTerm.TerminalView, newCols: Int, newRows: Int) {
            session.resize(cols: newCols, rows: newRows)
            Task { @MainActor in self.session.terminalRows = newRows }
        }

        func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {
            guard let dir = directory, !dir.isEmpty else { return }
            Task { @MainActor in self.session.currentDirectory = dir }
        }

        func setTerminalTitle(source: SwiftTerm.TerminalView, title: String) {
            guard !title.isEmpty else { return }
            Task { @MainActor in self.session.sessionName = title }
        }

        func scrolled(source: SwiftTerm.TerminalView, position: Double) {}

        func bell(source: SwiftTerm.TerminalView) { NSSound.beep() }

        func requestOpenLink(source: SwiftTerm.TerminalView, link: String, params: [String: String]) {
            if let url = URL(string: link) { NSWorkspace.shared.open(url) }
        }

        func clipboardCopy(source: SwiftTerm.TerminalView, content: Foundation.Data) {
            if let str = String(data: content, encoding: .utf8) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(str, forType: .string)
            }
        }

        func iTermContent(source: SwiftTerm.TerminalView, content: ArraySlice<UInt8>) {}

        func rangeChanged(source: SwiftTerm.TerminalView, startY: Int, endY: Int) {}
    }
}
