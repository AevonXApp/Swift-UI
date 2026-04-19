//
//  AXTerminalViewModel.swift
//  AevonX
//
//  Main terminal state machine — block-based, OSC 133-aware,
//  with raw mode detection and smart completions.
//
//  Full rewrite of the original TerminalViewModel.
//  Keeps the same PTY bridge infrastructure (PTYBridge, SSHBridge).
//

import Foundation
import Combine
import SwiftUI
import AevonXCoreBridge

// MARK: - Terminal Session

struct AXTerminalSession: Identifiable, Equatable {
    let id: String
    var name: String
    var hasUnreadOutput: Bool
    var isConnected: Bool
    let createdAt: Date

    init(name: String = L10n.Terminal.session) {
        self.id = UUID().uuidString
        self.name = name
        self.hasUnreadOutput = false
        self.isConnected = false
        self.createdAt = Date()
    }
}

// MARK: - View Model

@MainActor
final class AXTerminalViewModel: ObservableObject {

    // MARK: - Blocks

    @Published var blocks: [AXBlockEntry] = []
    @Published private(set) var currentBlock: AXTerminalBlock?

    // MARK: - Input

    @Published var inputText: String = ""
    @Published private(set) var isRawMode: Bool = false
    @Published private(set) var rawModeReason: AXRawModeReason = .none

    // MARK: - Completions

    @Published var completions: [AXCompletion] = []
    @Published var autosuggestion: String?
    @Published var selectedCompletionIndex: Int = 0
    @Published var showCompletionPopup: Bool = false

    // MARK: - Session

    @Published var connectionState: TerminalConnectionState = .disconnected
    @Published var currentDirectory: String = "~"
    @Published var session: AXTerminalSession

    // MARK: - Search

    @Published var isSearchVisible: Bool = false
    @Published var searchQuery: String = ""
    @Published var searchResults: [AXSearchResult] = []
    @Published var currentSearchIndex: Int = 0

    // MARK: - Danger

    @Published var dangerWarning: DangerousCommandDetector.Analysis?
    @Published var pendingDangerCommand: String?

    // MARK: - Unified Terminal Callbacks
    // These are set by AXUnifiedTerminalView to receive output without blocks.

    /// Called with every chunk of attributed PTY output (lines + system messages).
    var onOutput: ((NSAttributedString) -> Void)?

    /// Called after the prompt text has been emitted — signals input is ready.
    var onPromptReady: (() -> Void)?

    /// Called when the terminal buffer should be cleared (user typed "clear", etc.).
    var onClear: (() -> Void)?

    // MARK: - Private

    let serverId: String
    let preferences = TerminalPreferences.shared

    private let ptySessionID: String
    private var readTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var completionTask: Task<Void, Never>?

    private let blockDetector = AXBlockDetector()
    private let rawModeDetector = AXRawModeDetector()
    private let completionEngine = AXCompletionEngine()
    private let searchEngine = AXTerminalSearch()

    private var commandHistory: [CommandHistoryEntry] = []
    private var historyIndex: Int = -1
    private var savedCurrentInput: String = ""
    private var outputBuffer: String = ""
    private var shellIntegrationInjected: Bool = false
    private var detectedShell: String?

    private var reconnectAttempt: Int = 0
    private var lastServerName: String?
    private var lastServerHost: String?

    var isConnected: Bool { connectionState == .connected }

    // MARK: - Init

    init(serverId: String, sessionName: String? = nil) {
        self.serverId = serverId
        self.ptySessionID = "pty-\(UUID().uuidString.prefix(8))"
        self.session = AXTerminalSession(name: sessionName ?? L10n.Terminal.session)
    }

    deinit {
        readTask?.cancel()
        reconnectTask?.cancel()
        completionTask?.cancel()
    }

    // MARK: - Connection

    func connect(serverName: String, serverHost: String) async {
        lastServerName = serverName
        lastServerHost = serverHost
        reconnectAttempt = 0
        connectionState = .connecting

        addSystemBlock([
            "\u{2501}".repeated(40),
            "AevonX Interactive Terminal",
            "\u{2501}".repeated(40),
            "\(L10n.Terminal.connecting) \(serverName) (\(serverHost))...",
        ])

        let connected = SSHBridge.shared.isConnected(serverID: serverId)
        guard connected else {
            connectionState = .error("SSH \(L10n.Terminal.disconnected)")
            addSystemBlock(["SSH \(L10n.Terminal.disconnected)"])
            session.isConnected = false
            return
        }

        let resultJSON = PTYBridge.shared.startSession(
            serverID: serverId,
            sessionID: ptySessionID,
            rows: 24,
            cols: 80
        )

        guard let data = resultJSON.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true else {
            connectionState = .error("PTY session failed")
            addSystemBlock(["PTY session failed"])
            session.isConnected = false
            if preferences.autoReconnect { attemptReconnect() }
            return
        }

        startReadLoop()

        connectionState = .connected
        session.isConnected = true

        // Register completion specs
        registerCompletionSpecs(ToolSpecsRegistry.allSpecs)

        // Detect shell type and inject integration
        injectShellIntegration()
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        readTask?.cancel()
        readTask = nil
        completionTask?.cancel()

        let _ = PTYBridge.shared.closeSession(sessionID: ptySessionID)

        connectionState = .disconnected
        session.isConnected = false
        rawModeDetector.reset()
        isRawMode = false
        rawModeReason = .none

        addSystemBlock([
            "\u{2501}".repeated(40),
            L10n.Terminal.disconnected,
            "\u{2501}".repeated(40),
        ])
    }

    private func attemptReconnect() {
        guard reconnectAttempt < preferences.maxReconnectAttempts,
              let name = lastServerName, let host = lastServerHost else { return }
        reconnectAttempt += 1
        connectionState = .reconnecting(attempt: reconnectAttempt)

        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.reconnectAttempt ?? 1) * 2_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.connect(serverName: name, serverHost: host)
        }
    }

    // MARK: - Shell Integration

    /// Track whether we're in the setup phase (suppress output)
    private var isInSetupPhase: Bool = false

    private func injectShellIntegration() {
        isInSetupPhase = true

        // Detect shell silently — space prefix avoids bash history, redirect stderr
        let detectCmd = " echo \"AX_SHELL:$SHELL\" 2>/dev/null\n"
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: detectCmd)

        Task {
            try? await Task.sleep(nanoseconds: 800_000_000) // 800ms
            guard !shellIntegrationInjected else { return }
            injectIntegration(shell: "bash")
        }
    }

    private func injectIntegration(shell: String) {
        guard !shellIntegrationInjected else { return }
        shellIntegrationInjected = true
        detectedShell = shell

        let script = AXBlockDetector.integrationScript(for: shell)
        // Wrap in subshell to suppress all output; space prefix avoids history
        let escaped = script
            .replacingOccurrences(of: "'", with: "'\\''")
            .replacingOccurrences(of: "\n", with: "; ")
        let cmd = " eval '\(escaped)' 2>/dev/null\n"
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: cmd)

        // End setup phase after integration is injected + prompt settles
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            self.isInSetupPhase = false
            // Nudge the shell to emit a fresh prompt
            let _ = PTYBridge.shared.writeString(sessionID: self.ptySessionID, text: "\n")
        }
    }

    // MARK: - PTY Output Reading

    private func startReadLoop() {
        readTask?.cancel()
        readTask = Task { [weak self] in
            var idleCount: UInt64 = 0
            while !Task.isCancelled {
                guard let self = self, self.isConnected else { break }

                if let data = PTYBridge.shared.read(sessionID: self.ptySessionID, maxBytes: 8192),
                   let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    idleCount = 0
                    await MainActor.run {
                        self.handleOutput(output)
                    }
                } else {
                    // Adaptive backoff: 10ms → 20ms → 50ms (idle cap)
                    idleCount += 1
                    let delay: UInt64 = min(50_000_000, 10_000_000 * min(idleCount, 5))
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
    }

    // MARK: - Output Processing

    private func handleOutput(_ output: String) {
        // Check for shell detection response
        if !shellIntegrationInjected {
            if let shell = AXBlockDetector.parseShellType(from: output) {
                injectIntegration(shell: shell)
            }
        }

        // During setup phase, only process shell detection — don't show output
        if isInSetupPhase {
            // Still process raw mode detection (for alternate screen)
            let _ = rawModeDetector.processOutput(output)
            return
        }

        // Raw mode detection
        let rawChanged = rawModeDetector.processOutput(output)
        if rawChanged {
            isRawMode = rawModeDetector.isRawMode
            rawModeReason = rawModeDetector.reason
        }

        // In raw mode, append raw output to current block
        if isRawMode {
            handleRawOutput(output)
            return
        }

        // Block detection via OSC 133
        let (cleaned, events) = blockDetector.processOutput(output)

        for event in events {
            switch event {
            case .promptStart:
                finalizeCurrentBlock(exitCode: nil)
            case .commandStart:
                // Block already started when we sent the command
                break
            case .outputStart:
                break
            case .commandFinished(let exitCode):
                finalizeCurrentBlock(exitCode: exitCode)
            case .promptDetected:
                // Heuristic fallback — if we have a running block, finalize it
                if currentBlock != nil && currentBlock!.isRunning {
                    finalizeCurrentBlock(exitCode: 0)
                }
            case .outputLine:
                break
            }
        }

        // Process cleaned output into lines
        processOutputLines(cleaned)

        // CWD tracking
        updateCWDFromOutput(cleaned)

        // Signal prompt-ready to unified view after output has been emitted
        let hasPrompt = events.contains { event in
            if case .commandStart = event { return true }
            if case .promptDetected = event { return true }
            return false
        }
        if hasPrompt { onPromptReady?() }

        session.hasUnreadOutput = true
    }

    private func handleRawOutput(_ output: String) {
        if var block = currentBlock {
            let lines = output.components(separatedBy: "\n")
            for line in lines where !line.isEmpty {
                block.lines.append(AXTerminalLine(rawOutput: line))
            }
            currentBlock = block
            updateCurrentBlockInEntries()
        }

        // Emit raw output to unified view (PTY handles cursor positioning)
        let attributed = ANSITerminalRenderer.render(
            output, theme: preferences.theme, font: preferences.nsFont
        )
        onOutput?(attributed)
    }

    private func processOutputLines(_ text: String) {
        guard !text.isEmpty else { return }

        outputBuffer += text

        var lines = outputBuffer.components(separatedBy: "\n")

        if lines.count > 1 {
            outputBuffer = lines.removeLast()

            for line in lines {
                appendLineToCurrentBlock(line)
            }
        }

        // Flush buffer on prompt detection
        let stripped = ANSIParserCore.strip(outputBuffer).trimmingCharacters(in: .whitespaces)
        if stripped.hasSuffix("$") || stripped.hasSuffix("#") || stripped.hasSuffix("❯") || stripped.hasSuffix(">") || stripped.hasSuffix("%") {
            if !outputBuffer.isEmpty {
                appendLineToCurrentBlock(outputBuffer)
                outputBuffer = ""
            }
        }
    }

    private func appendLineToCurrentBlock(_ text: String) {
        // Handle \r for progress bars — overwrite the last line if \r present
        let parts = text.components(separatedBy: "\r")
        let finalText = parts.last ?? text

        guard var block = currentBlock else {
            // No active block — this is pre-command output (e.g., MOTD)
            if !finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let entry = AXSystemBlock(messages: [finalText])
                blocks.append(.system(entry))
            }
            // Emit to unified view regardless of block state
            let attributed = ANSITerminalRenderer.render(
                finalText + "\n", theme: preferences.theme, font: preferences.nsFont
            )
            onOutput?(attributed)
            return
        }

        block.lines.append(AXTerminalLine(rawOutput: finalText))
        currentBlock = block
        updateCurrentBlockInEntries()

        // Emit to unified view
        let attributed = ANSITerminalRenderer.render(
            finalText + "\n", theme: preferences.theme, font: preferences.nsFont
        )
        onOutput?(attributed)
    }

    private func updateCurrentBlockInEntries() {
        guard let block = currentBlock else { return }
        if let lastIdx = blocks.indices.last, case .command = blocks[lastIdx] {
            blocks[lastIdx] = .command(block)
        }
    }

    // MARK: - Block Management

    private func startNewBlock(command: String) {
        let block = AXTerminalBlock(command: command, workingDirectory: currentDirectory)
        currentBlock = block
        blocks.append(.command(block))
        trimBlocks()
    }

    private func finalizeCurrentBlock(exitCode: Int?) {
        guard var block = currentBlock else { return }
        block.endTime = Date()
        if let code = exitCode {
            block.exitCode = code
        }
        currentBlock = nil

        // Update in blocks array
        if let lastIdx = blocks.indices.last, case .command = blocks[lastIdx] {
            blocks[lastIdx] = .command(block)
        }
    }

    private func addSystemBlock(_ messages: [String]) {
        let entry = AXSystemBlock(messages: messages)
        blocks.append(.system(entry))

        // Emit to unified view
        let font = preferences.nsFont
        let theme = preferences.theme
        let result = NSMutableAttributedString()
        for msg in messages {
            result.append(ANSITerminalRenderer.renderSystem(msg + "\n", theme: theme, font: font))
        }
        onOutput?(result)
    }

    private func trimBlocks() {
        let maxBlocks = 500
        if blocks.count > maxBlocks {
            blocks.removeFirst(blocks.count - maxBlocks)
        }
    }

    // MARK: - Command Execution

    func sendCommand() {
        let command = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        dismissCompletions()

        guard !command.isEmpty else {
            // Just press Enter on empty — send newline to PTY
            let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "\n")
            return
        }

        // Local clear
        if command == "clear" || command == "cls" {
            blocks.removeAll()
            currentBlock = nil
            outputBuffer = ""
            onClear?()
            let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "clear\n")
            return
        }

        // Dangerous command detection
        if preferences.showDangerWarnings {
            let analysis = DangerousCommandDetector.analyze(command)
            if analysis.level >= .dangerous {
                dangerWarning = analysis
                pendingDangerCommand = command
                return
            }
        }

        executeCommand(command)
    }

    func confirmDangerousCommand() {
        guard let command = pendingDangerCommand else { return }
        dangerWarning = nil
        pendingDangerCommand = nil
        executeCommand(command)
    }

    func cancelDangerousCommand() {
        dangerWarning = nil
        pendingDangerCommand = nil
    }

    private func executeCommand(_ command: String) {
        addToHistory(command)
        blockDetector.setPendingCommand(command)

        // Start a new block
        startNewBlock(command: command)

        // Check if interactive
        if rawModeDetector.isInteractiveCommand(command) {
            rawModeDetector.enterRawMode(reason: .interactiveCommand)
            isRawMode = true
            rawModeReason = .interactiveCommand
        }

        // Send to PTY
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: command + "\n")
    }

    // MARK: - Raw Mode Input

    func sendRawKeystroke(_ text: String) {
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: text)
    }

    func sendInterrupt() {
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "\u{03}")
        // Exit raw mode on Ctrl+C
        if isRawMode && rawModeReason != .alternateScreen {
            rawModeDetector.exitRawMode()
            isRawMode = false
            rawModeReason = .none
        }
    }

    func sendEOF() {
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "\u{04}")
    }

    func sendTab() {
        if isRawMode {
            let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "\t")
        } else {
            // In editor mode, trigger completions
            if showCompletionPopup && !completions.isEmpty {
                acceptCompletion()
            } else {
                updateCompletions()
                showCompletionPopup = true
            }
        }
    }

    // MARK: - History Navigation

    func previousCommand() {
        guard !commandHistory.isEmpty else { return }
        if historyIndex == -1 {
            savedCurrentInput = inputText
            historyIndex = commandHistory.count - 1
        } else if historyIndex > 0 {
            historyIndex -= 1
        }
        if historyIndex >= 0 && historyIndex < commandHistory.count {
            inputText = commandHistory[historyIndex].command
        }
    }

    func nextCommand() {
        guard historyIndex != -1 else { return }
        historyIndex += 1
        if historyIndex >= commandHistory.count {
            historyIndex = -1
            inputText = savedCurrentInput
        } else {
            inputText = commandHistory[historyIndex].command
        }
    }

    private func addToHistory(_ command: String) {
        guard !command.isEmpty else { return }
        // Deduplicate
        if let lastIdx = commandHistory.lastIndex(where: { $0.command == command }) {
            commandHistory[lastIdx].executionCount += 1
        } else {
            commandHistory.append(CommandHistoryEntry(command: command))
        }
        if commandHistory.count > 1000 {
            commandHistory.removeFirst(commandHistory.count - 1000)
        }
        historyIndex = -1
        savedCurrentInput = ""

        Task {
            await completionEngine.updateHistory(commandHistory)
        }
    }

    // MARK: - Completions

    func updateCompletions() {
        completionTask?.cancel()

        let input = inputText
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else {
            dismissCompletions()
            return
        }

        completionTask = Task {
            let context = CompletionContext(input: input, cwd: currentDirectory)
            let results = await completionEngine.complete(context: context)
            let suggestion = await completionEngine.autosuggestion(for: input)

            guard !Task.isCancelled else { return }

            self.completions = results
            self.autosuggestion = suggestion
            self.selectedCompletionIndex = 0
            self.showCompletionPopup = !results.isEmpty
        }
    }

    func acceptCompletion() {
        guard selectedCompletionIndex < completions.count else { return }
        let completion = completions[selectedCompletionIndex]

        // Replace current word with completion
        let parts = inputText.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        if parts.count > 1 {
            var newParts = Array(parts.dropLast())
            newParts.append(completion.text)
            inputText = newParts.joined(separator: " ")
        } else {
            inputText = completion.text
        }

        // Add trailing space for commands/subcommands
        if completion.kind == .command || completion.kind == .subcommand {
            inputText += " "
        }

        dismissCompletions()
    }

    func acceptAutosuggestion() {
        guard let suggestion = autosuggestion else { return }
        inputText += suggestion
        autosuggestion = nil
    }

    func acceptAutosuggestionWord() {
        guard let suggestion = autosuggestion, !suggestion.isEmpty else { return }
        // Accept one word
        let firstSpace = suggestion.firstIndex(of: " ") ?? suggestion.endIndex
        let word = String(suggestion[suggestion.startIndex..<firstSpace])
        inputText += word
        let remaining = String(suggestion[firstSpace...]).trimmingCharacters(in: .init(charactersIn: " "))
        autosuggestion = remaining.isEmpty ? nil : " " + remaining
    }

    func dismissCompletions() {
        completions = []
        autosuggestion = nil
        showCompletionPopup = false
        selectedCompletionIndex = 0
    }

    func selectNextCompletion() {
        guard !completions.isEmpty else { return }
        selectedCompletionIndex = (selectedCompletionIndex + 1) % completions.count
    }

    func selectPreviousCompletion() {
        guard !completions.isEmpty else { return }
        selectedCompletionIndex = (selectedCompletionIndex - 1 + completions.count) % completions.count
    }

    // MARK: - Block Actions

    func toggleBookmark(blockID: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == blockID }),
              case .command(var block) = blocks[idx] else { return }
        block.isBookmarked.toggle()
        blocks[idx] = .command(block)
    }

    func toggleCollapse(blockID: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == blockID }),
              case .command(var block) = blocks[idx] else { return }
        block.isCollapsed.toggle()
        blocks[idx] = .command(block)
    }

    func rerunCommand(blockID: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == blockID }),
              case .command(let block) = blocks[idx] else { return }
        inputText = block.command
        sendCommand()
    }

    func editAndRerun(blockID: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == blockID }),
              case .command(let block) = blocks[idx] else { return }
        inputText = block.command
    }

    func removeBlock(blockID: UUID) {
        blocks.removeAll { $0.id == blockID }
    }

    func copyCommand(blockID: UUID) -> String? {
        blocks.first(where: { $0.id == blockID })?.commandBlock?.command
    }

    func copyOutput(blockID: UUID) -> String? {
        blocks.first(where: { $0.id == blockID })?.commandBlock?.plainOutput
    }

    // MARK: - Terminal Control

    func clear() {
        blocks.removeAll()
        currentBlock = nil
        outputBuffer = ""
        onClear?()
    }

    func clearAllBlocks() {
        blocks.removeAll()
        currentBlock = nil
        outputBuffer = ""
        onClear?()
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "clear\n")
    }

    func resize(width: Int, height: Int) {
        let _ = PTYBridge.shared.resize(sessionID: ptySessionID, rows: height, cols: width)
    }

    // MARK: - Search

    func toggleSearch() {
        isSearchVisible.toggle()
        if !isSearchVisible {
            searchQuery = ""
            searchResults = []
            currentSearchIndex = 0
        }
    }

    func performSearch() {
        searchResults = searchEngine.search(query: searchQuery, in: blocks)
        currentSearchIndex = searchResults.isEmpty ? 0 : searchResults.count - 1
    }

    func nextSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
    }

    func previousSearchResult() {
        guard !searchResults.isEmpty else { return }
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
    }

    // MARK: - Snippets

    func insertSnippet(_ snippet: CommandSnippet) {
        inputText = snippet.command
    }

    // MARK: - CWD Tracking

    private func updateCWDFromOutput(_ output: String) {
        let stripped = ANSIParserCore.strip(output)
        // Try to extract CWD from prompt patterns like "user@host:/path/to/dir$"
        let patterns = [
            "(?:.*?):(.+?)[$#%>]\\s*$",
            "(?:.*?)\\s(.+?)[$#%>]\\s*$",
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: stripped, range: NSRange(stripped.startIndex..., in: stripped)),
               let range = Range(match.range(at: 1), in: stripped) {
                let path = String(stripped[range]).trimmingCharacters(in: .whitespaces)
                if path.hasPrefix("/") || path.hasPrefix("~") {
                    currentDirectory = path
                    break
                }
            }
        }
    }

    // MARK: - Spec Registration

    func registerCompletionSpecs(_ specs: [ToolSpec]) {
        Task {
            await completionEngine.registerSpecs(specs)
        }
    }
}

// MARK: - String Repeat Helper

private extension String {
    func repeated(_ count: Int) -> String {
        String(repeating: self, count: count)
    }
}
