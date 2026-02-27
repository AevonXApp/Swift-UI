//
//  TerminalViewModel.swift
//  AevonX
//
//  Interactive SSH Terminal ViewModel
//  Uses same pattern as DockerTerminalViewModel — lines array + inputCommand
//

import Foundation
import AevonXCore
import Combine

// MARK: - Terminal Line

struct SSHTerminalLine: Identifiable {
    let id = UUID()
    let content: String
    let type: LineType
    let timestamp: Date

    enum LineType {
        case output, system, error, input
    }

    init(content: String, type: LineType = .output) {
        self.content = content
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
    @Published var currentPath: String = "~"
    @Published var username: String = "user"
    @Published var hostname: String = "server"
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
    private let terminalService = TerminalService.shared
    private var interactiveSession: SSHInteractiveSession?
    let preferences = TerminalPreferences.shared

    private var commandHistory: [String] = []
    private var historyIndex: Int = -1
    private var savedCurrentInput: String = ""
    private var reconnectAttempt: Int = 0
    private var reconnectTask: Task<Void, Never>?
    private var lastServer: Server?
    private var outputBuffer: String = ""

    // MARK: - Computed Properties

    var prompt: String { "\(username)@\(hostname):\(currentPath) $ " }
    var maxLines: Int { preferences.scrollbackLines }

    // MARK: - Init

    init(serverId: String, sessionName: String? = nil) {
        self.serverId = serverId
        self.sessionInfo = TerminalSessionInfo(name: sessionName ?? "Session")
    }

    // MARK: - Connection

    func connect(server: Server) async {
        lastServer = server
        reconnectAttempt = 0
        state = .connecting

        addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", type: .system)
        addLine("🚀 AevonX Interactive Terminal", type: .system)
        addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", type: .system)
        addLine("Connecting to \(server.name) (\(server.host))...", type: .system)

        let connected = await terminalService.isSSHConnected(serverId: serverId)

        guard connected else {
            state = .error("Not connected to SSH")
            addLine("", type: .error)
            addLine("❌ ERROR: Not connected to SSH server", type: .error)
            addLine("📌 Please connect from the Overview tab first", type: .error)
            isConnected = false
            return
        }

        do {
            username = await terminalService.fetchUsername(serverId: serverId)
            hostname = await terminalService.fetchHostname(serverId: serverId)

            addLine("Starting interactive shell session...", type: .system)

            interactiveSession = try await terminalService.startInteractiveSession(
                serverId: serverId,
                onOutput: { [weak self] output in
                    Task { @MainActor [weak self] in
                        self?.handleOutput(output)
                    }
                }
            )

            state = .connected
            isConnected = true
            sessionInfo.isConnected = true

            addLine("", type: .system)
            addLine("✅ Connected successfully!", type: .system)
            addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", type: .system)

        } catch {
            state = .error(error.localizedDescription)
            isConnected = false
            sessionInfo.isConnected = false
            addLine("", type: .error)
            addLine("❌ Connection failed: \(error.localizedDescription)", type: .error)

            if preferences.autoReconnect { attemptReconnect() }
        }
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil

        Task {
            try? await interactiveSession?.close()
            interactiveSession = nil
            isConnected = false
            sessionInfo.isConnected = false
            state = .disconnected
            addLine("", type: .system)
            addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", type: .system)
            addLine("🔌 Disconnected from server", type: .system)
            addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", type: .system)
        }
    }

    private func attemptReconnect() {
        guard reconnectAttempt < preferences.maxReconnectAttempts, let server = lastServer else { return }
        reconnectAttempt += 1
        state = .reconnecting(attempt: reconnectAttempt)
        addLine("🔄 Reconnecting... (attempt \(reconnectAttempt)/\(preferences.maxReconnectAttempts))", type: .system)

        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(reconnectAttempt) * 2_000_000_000)
            guard !Task.isCancelled else { return }
            await connect(server: server)
        }
    }

    // MARK: - Command Execution

    func sendCommand() {
        let command = inputCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        inputCommand = ""

        guard !command.isEmpty else {
            // Send empty newline
            if let session = interactiveSession {
                Task { try? await session.write("\n") }
            }
            return
        }

        // Local commands
        if command == "clear" || command == "cls" {
            lines.removeAll()
            return
        }

        // Dangerous command detection
        if preferences.showDangerWarnings {
            let analysis = DangerousCommandDetector.analyze(command)
            if analysis.level >= .dangerous {
                dangerWarning = analysis
                inputCommand = command // Put it back so user can see it
                return
            }
        }

        addToHistory(command)
        if preferences.showCommandTimer { commandStartTime = Date() }

        // Invalidate directory cache if cd command
        if command.hasPrefix("cd ") || command == "cd" {
            invalidateDirectoryCache()
        }

        // Send to shell
        guard let session = interactiveSession else { return }
        Task {
            try? await session.write(command + "\n")
        }
    }

    func confirmDangerousCommand() {
        guard dangerWarning != nil else { return }
        let command = inputCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        dangerWarning = nil
        inputCommand = ""
        addToHistory(command)
        if preferences.showCommandTimer { commandStartTime = Date() }

        guard let session = interactiveSession else { return }
        Task { try? await session.write(command + "\n") }
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
        guard let session = interactiveSession else { return }
        Task { try? await session.write("\u{03}") }
    }

    func sendEOF() {
        guard let session = interactiveSession else { return }
        Task { try? await session.write("\u{04}") }
    }

    func sendTab() {
        guard let session = interactiveSession else { return }
        Task { try? await session.write("\t") }
    }

    // MARK: - Terminal Control

    func clear() {
        lines.removeAll()
        outputBuffer = ""
    }

    func resize(width: Int, height: Int) {
        guard let session = interactiveSession else { return }
        Task { try? await session.resize(width: width, height: height) }
    }

    // MARK: - Search

    func toggleSearch() {
        isSearchVisible.toggle()
        if !isSearchVisible { searchQuery = ""; searchResultCount = 0; currentSearchIndex = 0 }
    }

    // MARK: - Private: Output Handling

    private func handleOutput(_ output: String) {
        // Clean ANSI codes
        let cleaned = ANSIParserCore.strip(output)
            .replacingOccurrences(of: "\r", with: "")

        guard !cleaned.isEmpty else { return }

        // Buffer partial lines
        outputBuffer += cleaned

        // Split into complete lines
        var outputLines = outputBuffer.components(separatedBy: "\n")

        if outputLines.count > 1 {
            // Keep the last (potentially incomplete) line in buffer
            outputBuffer = outputLines.removeLast()

            // Add complete lines
            for line in outputLines {
                addLine(line)
            }
        }

        // If buffer ends with prompt pattern, flush it as a line
        let trimmedBuffer = outputBuffer.trimmingCharacters(in: .whitespaces)
        if trimmedBuffer.hasSuffix("$") || trimmedBuffer.hasSuffix("#") || trimmedBuffer.hasSuffix("❯") || trimmedBuffer.hasSuffix(">") {
            if !outputBuffer.isEmpty {
                addLine(outputBuffer)
                outputBuffer = ""
            }
        }

        sessionInfo.hasUnreadOutput = true

        // Command timer
        if let startTime = commandStartTime {
            if trimmedBuffer.hasSuffix("$") || trimmedBuffer.hasSuffix("#") {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > 2.0 {
                    addLine("⏱ Command completed in \(String(format: "%.1f", elapsed))s", type: .system)
                }
                commandStartTime = nil
            }
        }
    }

    private func addLine(_ content: String, type: SSHTerminalLine.LineType = .output) {
        lines.append(SSHTerminalLine(content: content, type: type))
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
    }

    // MARK: - Smart Suggestions

    private var suggestionsTask: Task<Void, Never>?
    private var cachedDirContents: [String: (entries: [String], timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 10 // Cache for 10 seconds

    func updateSuggestions() {
        let input = inputCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { commandSuggestions = []; return }

        // Cancel previous async fetch
        suggestionsTask?.cancel()

        // Determine if we need live SSH suggestions
        let parts = input.split(separator: " ", maxSplits: 1).map(String.init)
        let baseCmd = parts.first?.lowercased() ?? ""
        let argument = parts.count > 1 ? parts[1] : ""

        let needsPathSuggestions = ["cd", "ls", "cat", "less", "more", "head", "tail",
                                     "vim", "vi", "nano", "cp", "mv", "rm", "chmod",
                                     "chown", "stat", "file", "source", "bash", "sh"].contains(baseCmd)
        let needsDirOnly = ["cd"].contains(baseCmd)

        if needsPathSuggestions && parts.count >= 1 {
            // Async: fetch real paths from server
            suggestionsTask = Task { [weak self] in
                guard let self = self else { return }

                // Show static suggestions immediately while fetching
                let quick = self.getQuickSuggestions(input: input, baseCmd: baseCmd)
                if !quick.isEmpty {
                    self.commandSuggestions = quick
                }

                // Determine which directory to list
                let dirToList: String
                let partialName: String

                if argument.isEmpty {
                    dirToList = "."
                    partialName = ""
                } else if argument.hasSuffix("/") {
                    dirToList = argument
                    partialName = ""
                } else {
                    // e.g. "cd /var/ww" → list "/var/" and filter "ww"
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

                // Check cache
                let entries: [String]
                if let cached = self.cachedDirContents[dirToList],
                   Date().timeIntervalSince(cached.timestamp) < self.cacheTTL {
                    entries = cached.entries
                } else {
                    // Fetch from server
                    let fetched = await self.terminalService.fetchDirectoryContents(
                        path: dirToList, serverId: self.serverId
                    )
                    guard !Task.isCancelled else { return }
                    self.cachedDirContents[dirToList] = (entries: fetched, timestamp: Date())
                    entries = fetched
                }

                guard !Task.isCancelled else { return }

                // Filter entries
                let filtered = entries.filter { entry in
                    if needsDirOnly && !entry.hasSuffix("/") { return false }
                    if partialName.isEmpty { return true }
                    let name = entry.replacingOccurrences(of: "/", with: "")
                                    .replacingOccurrences(of: "*", with: "")
                                    .replacingOccurrences(of: "@", with: "")
                    return name.lowercased().hasPrefix(partialName.lowercased())
                }

                // Build full suggestion strings
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

                // Add history matches
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
            // Synchronous: static + history suggestions
            var suggestions: [String] = []

            let staticSuggestions = terminalService.getStaticSuggestions(for: input)
            suggestions.append(contentsOf: staticSuggestions)

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

    /// Quick suggestions shown instantly while SSH fetch is in progress
    private func getQuickSuggestions(input: String, baseCmd: String) -> [String] {
        let inputLower = input.lowercased()

        // History-based
        var quick = commandHistory.filter {
            $0.lowercased().starts(with: inputLower)
        }.suffix(3).map { $0 }

        // Common shortcuts for the base command
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

    /// Invalidate cache when directory changes (cd command)
    func invalidateDirectoryCache() {
        cachedDirContents.removeAll()
    }
}
