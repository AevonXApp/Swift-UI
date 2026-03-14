//
//  TerminalViewModel.swift
//  AevonX
//
//  Interactive SSH Terminal ViewModel — PTY-backed real terminal.
//  Uses Go SSH PTY sessions for persistent shell with colors, vim, htop, etc.
//

import Foundation
import AevonXCoreBridge
import Combine

// MARK: - Terminal Line

struct SSHTerminalLine: Identifiable {
    let id = UUID()
    let content: String
    let segments: [ANSIStyledSegment]
    let type: LineType
    let timestamp: Date

    enum LineType {
        case output, system, error, input
    }

    /// Create a line from raw output (may contain ANSI codes)
    init(content: String, type: LineType = .output) {
        // Strip non-SGR escape sequences (cursor, bracketed paste, OSC, etc.)
        // but KEEP SGR color sequences (\e[...m) for rendering
        let cleaned = Self.stripNonColorEscapes(content)
        self.content = ANSIParserCore.strip(cleaned)
        self.segments = type == .output ? ANSIParserCore.parse(cleaned) : [ANSIStyledSegment(text: cleaned)]
        self.type = type
        self.timestamp = Date()
    }

    /// Strip escape sequences that aren't SGR (color) codes
    private static func stripNonColorEscapes(_ text: String) -> String {
        var result = text
        let nonSGRPatterns = [
            "\u{1B}\\[\\?[0-9;]*[a-z]",   // DEC private modes: [?2004h, [?2004l, etc.
            "\u{1B}\\[[0-9;]*[A-LN-Z]",     // Cursor movement, erase, etc. (NOT 'm')
            "\u{1B}\\][^\u{07}]*\u{07}",     // OSC (Operating System Command)
            "\u{1B}\\]0;[^\u{07}]*\u{07}",   // Window title
        ]
        for pattern in nonSGRPatterns {
            result = result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        return result
    }

    /// Create a system/error line (no ANSI parsing needed)
    init(system content: String, type: LineType) {
        self.content = content
        self.segments = [ANSIStyledSegment(text: content)]
        self.type = type
        self.timestamp = Date()
    }
}

// MARK: - Terminal View Model

@MainActor
class TerminalViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var lines: [SSHTerminalLine] = []
    @Published var inputCommand: String = ""
    @Published var state: TerminalConnectionState = .disconnected
    @Published var isConnected: Bool = false
    @Published var commandSuggestions: [String] = []
    @Published var sessionInfo: TerminalSessionInfo
    @Published var isSearchVisible: Bool = false
    @Published var searchQuery: String = ""
    @Published var searchResultCount: Int = 0
    @Published var currentSearchIndex: Int = 0
    @Published var dangerWarning: DangerousCommandDetector.Analysis?
    @Published var commandStartTime: Date?

    // MARK: - Private Properties

    let serverId: String
    let preferences = TerminalPreferences.shared

    /// Unique PTY session ID for this terminal tab
    private let ptySessionID: String

    /// Background task that polls PTY output
    private var readTask: Task<Void, Never>?

    private var commandHistory: [String] = []
    private var historyIndex: Int = -1
    private var savedCurrentInput: String = ""
    private var reconnectAttempt: Int = 0
    private var reconnectTask: Task<Void, Never>?
    private var lastServerName: String?
    private var lastServerHost: String?
    private var outputBuffer: String = ""

    // MARK: - Computed Properties

    var maxLines: Int { preferences.scrollbackLines }

    // MARK: - Init

    init(serverId: String, sessionName: String? = nil) {
        self.serverId = serverId
        self.ptySessionID = "pty-\(UUID().uuidString.prefix(8))"
        self.sessionInfo = TerminalSessionInfo(name: sessionName ?? "Session")
    }

    deinit {
        readTask?.cancel()
    }

    // MARK: - Connection

    func connect(serverName: String, serverHost: String) async {
        lastServerName = serverName
        lastServerHost = serverHost
        reconnectAttempt = 0
        state = .connecting

        addSystemLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addSystemLine("🚀 AevonX Interactive Terminal")
        addSystemLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addSystemLine("Connecting to \(serverName) (\(serverHost))...")

        let connected = SSHBridge.shared.isConnected(serverID: serverId)

        guard connected else {
            state = .error("Not connected to SSH")
            addLine(system: "", type: .error)
            addLine(system: "❌ ERROR: Not connected to SSH server", type: .error)
            addLine(system: "📌 Please connect from the Overview tab first", type: .error)
            isConnected = false
            return
        }

        // Start PTY session via Go bridge
        let resultJSON = PTYBridge.shared.startSession(
            serverID: serverId,
            sessionID: ptySessionID,
            rows: 24,
            cols: 80
        )

        // Check result
        guard let data = resultJSON.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true else {
            state = .error("Failed to start PTY session")
            addLine(system: "❌ Failed to start interactive session", type: .error)
            isConnected = false

            if preferences.autoReconnect { attemptReconnect() }
            return
        }

        // Start output polling
        startReadLoop()

        state = .connected
        isConnected = true
        sessionInfo.isConnected = true

        addSystemLine("✅ Connected — interactive shell ready")
        addSystemLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        readTask?.cancel()
        readTask = nil

        // Close PTY session
        let _ = PTYBridge.shared.closeSession(sessionID: ptySessionID)

        isConnected = false
        sessionInfo.isConnected = false
        state = .disconnected

        addSystemLine("")
        addSystemLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addSystemLine("🔌 Disconnected from server")
        addSystemLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    private func attemptReconnect() {
        guard reconnectAttempt < preferences.maxReconnectAttempts,
              let name = lastServerName, let host = lastServerHost else { return }
        reconnectAttempt += 1
        state = .reconnecting(attempt: reconnectAttempt)
        addSystemLine("🔄 Reconnecting... (attempt \(reconnectAttempt)/\(preferences.maxReconnectAttempts))")

        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(reconnectAttempt) * 2_000_000_000)
            guard !Task.isCancelled else { return }
            await connect(serverName: name, serverHost: host)
        }
    }

    // MARK: - PTY Output Reading

    private func startReadLoop() {
        readTask?.cancel()
        readTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, self.isConnected else { break }

                // Read from PTY — this may block briefly in Go if no data
                if let data = PTYBridge.shared.read(sessionID: self.ptySessionID, maxBytes: 8192),
                   let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    await MainActor.run {
                        self.handleOutput(output)
                    }
                } else {
                    // No data — small sleep to avoid spinning
                    try? await Task.sleep(nanoseconds: 30_000_000) // 30ms
                }
            }
        }
    }

    // MARK: - Command Execution

    func sendCommand() {
        let command = inputCommand
        inputCommand = ""

        // Local commands
        if command.trimmingCharacters(in: .whitespacesAndNewlines) == "clear" ||
           command.trimmingCharacters(in: .whitespacesAndNewlines) == "cls" {
            lines.removeAll()
            outputBuffer = ""
            // Send clear to the real terminal too
            let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "clear\n")
            return
        }

        // Dangerous command detection
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && preferences.showDangerWarnings {
            let analysis = DangerousCommandDetector.analyze(trimmed)
            if analysis.level >= .dangerous {
                dangerWarning = analysis
                inputCommand = command
                return
            }
        }

        if !trimmed.isEmpty {
            addToHistory(trimmed)
            if preferences.showCommandTimer { commandStartTime = Date() }
        }

        // Write to PTY — the shell will echo it and show output
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: command + "\n")
    }

    func confirmDangerousCommand() {
        guard dangerWarning != nil else { return }
        let command = inputCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        dangerWarning = nil
        inputCommand = ""
        addToHistory(command)
        if preferences.showCommandTimer { commandStartTime = Date() }

        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: command + "\n")
    }

    func cancelDangerousCommand() {
        dangerWarning = nil
        inputCommand = ""
    }

    // MARK: - History Navigation

    func previousCommand() {
        guard !commandHistory.isEmpty else { return }
        if historyIndex == -1 {
            savedCurrentInput = inputCommand
            historyIndex = commandHistory.count - 1
        } else if historyIndex > 0 {
            historyIndex -= 1
        }
        if historyIndex >= 0 && historyIndex < commandHistory.count {
            inputCommand = commandHistory[historyIndex]
        }
    }

    func nextCommand() {
        guard historyIndex != -1 else { return }
        historyIndex += 1
        if historyIndex >= commandHistory.count {
            historyIndex = -1
            inputCommand = savedCurrentInput
        } else {
            inputCommand = commandHistory[historyIndex]
        }
    }

    private func addToHistory(_ command: String) {
        guard !command.isEmpty else { return }
        if commandHistory.last == command { return }
        commandHistory.append(command)
        if commandHistory.count > 500 { commandHistory.removeFirst(commandHistory.count - 500) }
        historyIndex = -1
        savedCurrentInput = ""
    }

    // MARK: - Input Helpers

    func insertSnippet(_ snippet: CommandSnippet) {
        inputCommand = snippet.command
    }

    func sendInterrupt() {
        // Real Ctrl+C via PTY
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "\u{03}")
    }

    func sendEOF() {
        // Real Ctrl+D via PTY
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "\u{04}")
    }

    func sendTab() {
        // Real Tab via PTY — server-side completion!
        let _ = PTYBridge.shared.writeString(sessionID: ptySessionID, text: "\t")
    }

    // MARK: - Terminal Control

    func clear() {
        lines.removeAll()
        outputBuffer = ""
    }

    func resize(width: Int, height: Int) {
        let _ = PTYBridge.shared.resize(sessionID: ptySessionID, rows: height, cols: width)
    }

    // MARK: - Search

    func toggleSearch() {
        isSearchVisible.toggle()
        if !isSearchVisible { searchQuery = ""; searchResultCount = 0; currentSearchIndex = 0 }
    }

    // MARK: - Private: Output Handling

    private func handleOutput(_ output: String) {
        // Clean \r (carriage return) but KEEP ANSI codes for color rendering
        let cleaned = output.replacingOccurrences(of: "\r", with: "")

        guard !cleaned.isEmpty else { return }

        // Buffer partial lines
        outputBuffer += cleaned

        // Split into complete lines
        var outputLines = outputBuffer.components(separatedBy: "\n")

        if outputLines.count > 1 {
            // Keep the last (potentially incomplete) line in buffer
            outputBuffer = outputLines.removeLast()

            // Add complete lines — with ANSI color parsing
            for line in outputLines {
                addLine(raw: line)
            }
        }

        // If buffer ends with prompt pattern, flush it
        let stripped = ANSIParserCore.strip(outputBuffer).trimmingCharacters(in: .whitespaces)
        if stripped.hasSuffix("$") || stripped.hasSuffix("#") || stripped.hasSuffix("❯") || stripped.hasSuffix(">") {
            if !outputBuffer.isEmpty {
                addLine(raw: outputBuffer)
                outputBuffer = ""
            }
        }

        sessionInfo.hasUnreadOutput = true

        // Command timer
        if let startTime = commandStartTime {
            if stripped.hasSuffix("$") || stripped.hasSuffix("#") {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > 2.0 {
                    addLine(system: "⏱ Command completed in \(String(format: "%.1f", elapsed))s", type: .system)
                }
                commandStartTime = nil
            }
        }
    }

    /// Add a line with ANSI color parsing (for real terminal output)
    private func addLine(raw content: String) {
        lines.append(SSHTerminalLine(content: content, type: .output))
        trimLines()
    }

    /// Add a system/error line (no ANSI parsing)
    private func addLine(system content: String, type: SSHTerminalLine.LineType) {
        lines.append(SSHTerminalLine(system: content, type: type))
        trimLines()
    }

    /// Convenience for system lines
    private func addSystemLine(_ content: String) {
        addLine(system: content, type: .system)
    }

    private func trimLines() {
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
    }

    // MARK: - Smart Suggestions

    private var suggestionsTask: Task<Void, Never>?
    private var cachedDirContents: [String: (entries: [String], timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 10

    func updateSuggestions() {
        let input = inputCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { commandSuggestions = []; return }

        suggestionsTask?.cancel()

        let parts = input.split(separator: " ", maxSplits: 1).map(String.init)
        let baseCmd = parts.first?.lowercased() ?? ""
        let argument = parts.count > 1 ? parts[1] : ""

        let needsPathSuggestions = ["cd", "ls", "cat", "less", "more", "head", "tail",
                                     "vim", "vi", "nano", "cp", "mv", "rm", "chmod",
                                     "chown", "stat", "file", "source", "bash", "sh"].contains(baseCmd)
        let needsDirOnly = ["cd"].contains(baseCmd)

        if needsPathSuggestions && parts.count >= 1 {
            suggestionsTask = Task { [weak self] in
                guard let self = self else { return }

                let quick = self.getQuickSuggestions(input: input, baseCmd: baseCmd)
                if !quick.isEmpty {
                    self.commandSuggestions = quick
                }

                let dirToList: String
                let partialName: String

                if argument.isEmpty {
                    dirToList = "."
                    partialName = ""
                } else if argument.hasSuffix("/") {
                    dirToList = argument
                    partialName = ""
                } else {
                    let lastSlash = argument.lastIndex(of: "/")
                    if let idx = lastSlash {
                        dirToList = String(argument[...idx])
                        partialName = String(argument[argument.index(after: idx)...])
                    } else {
                        dirToList = "."
                        partialName = argument
                    }
                }

                guard !Task.isCancelled else { return }

                let entries: [String]
                if let cached = self.cachedDirContents[dirToList],
                   Date().timeIntervalSince(cached.timestamp) < self.cacheTTL {
                    entries = cached.entries
                } else {
                    let safePath = dirToList.replacingOccurrences(of: "'", with: "'\\''")
                    let output = await SSHBridge.shared.executeAsync(
                        serverID: self.serverId,
                        command: "ls -F1a '\(safePath)' 2>/dev/null"
                    )
                    guard !Task.isCancelled else { return }
                    let fetched = output.components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty && $0 != "." && $0 != ".." }
                    self.cachedDirContents[dirToList] = (entries: fetched, timestamp: Date())
                    entries = fetched
                }

                guard !Task.isCancelled else { return }

                let filtered = entries.filter { entry in
                    if needsDirOnly && !entry.hasSuffix("/") { return false }
                    if partialName.isEmpty { return true }
                    let name = entry.replacingOccurrences(of: "/", with: "")
                                    .replacingOccurrences(of: "*", with: "")
                                    .replacingOccurrences(of: "@", with: "")
                    return name.lowercased().hasPrefix(partialName.lowercased())
                }

                let prefix: String
                if dirToList == "." {
                    prefix = baseCmd + " "
                } else {
                    prefix = baseCmd + " " + dirToList
                }

                var suggestions = filtered.prefix(8).map { entry -> String in
                    let cleanEntry = entry.replacingOccurrences(of: "*", with: "")
                                         .replacingOccurrences(of: "@", with: "")
                    return prefix + cleanEntry
                }

                let inputLower = input.lowercased()
                let histMatches = self.commandHistory.filter {
                    $0.lowercased().starts(with: inputLower)
                }.suffix(2)
                for hist in histMatches {
                    if !suggestions.contains(where: { $0.lowercased() == hist.lowercased() }) {
                        suggestions.append(hist)
                    }
                }

                guard !Task.isCancelled else { return }
                self.commandSuggestions = Array(suggestions.prefix(8))
            }
        } else {
            var suggestions: [String] = []

            let suggestionsJSON = TerminalBridge.shared.getSuggestions(input: input)
            if let data = suggestionsJSON.data(using: .utf8),
               let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               response["success"] as? Bool == true,
               let suggestionsData = response["data"] as? [String] {
                suggestions.append(contentsOf: suggestionsData)
            }

            let inputLower = input.lowercased()
            let historySuggestions = commandHistory.filter {
                $0.lowercased().starts(with: inputLower)
            }.suffix(3)
            for hist in historySuggestions {
                if !suggestions.contains(where: { $0.lowercased() == hist.lowercased() }) {
                    suggestions.append(hist)
                }
            }

            commandSuggestions = Array(suggestions.prefix(8))
        }
    }

    private func getQuickSuggestions(input: String, baseCmd: String) -> [String] {
        let inputLower = input.lowercased()

        var quick = commandHistory.filter {
            $0.lowercased().starts(with: inputLower)
        }.suffix(3).map { $0 }

        switch baseCmd {
        case "cd":
            let cdQuick = ["cd ..", "cd ~", "cd -", "cd /"]
                .filter { $0.starts(with: input) }
            quick.insert(contentsOf: cdQuick, at: 0)
        case "ls":
            let lsQuick = ["ls -la", "ls -lh", "ls -lt"]
                .filter { $0.starts(with: input) }
            quick.insert(contentsOf: lsQuick, at: 0)
        default:
            break
        }

        return Array(quick.prefix(3))
    }

    func acceptSuggestion(_ suggestion: String) {
        inputCommand = suggestion
        commandSuggestions = []
    }

    func invalidateDirectoryCache() {
        cachedDirContents.removeAll()
    }
}
