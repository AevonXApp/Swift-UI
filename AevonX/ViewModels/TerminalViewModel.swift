//
//  TerminalViewModel.swift
//  AevonX
//
//  Interactive SSH Terminal ViewModel
//  Full-featured terminal emulator with PTY support
//

import Foundation
import AevonXCore
import Combine

// MARK: - Terminal Line Model

/// Represents a single line in the terminal output.
/// Uses auto-incrementing Int ID instead of UUID for performance (P2-2).
struct SSHTerminalLine: Identifiable, Equatable {
    static var nextId: Int = 0
    let id: Int
    let content: String
    let timestamp: Date

    init(content: String) {
        Self.nextId += 1
        self.id = Self.nextId
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Terminal State

/// Current state of the terminal session
enum TerminalState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

// MARK: - Terminal View Model

@MainActor
class TerminalViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All terminal output lines
    @Published var lines: [SSHTerminalLine] = []

    /// Current input command being typed
    @Published var inputCommand: String = ""

    /// Current terminal state
    @Published var state: TerminalState = .disconnected

    /// Whether terminal is connected and ready
    @Published var isConnected: Bool = false

    /// Current working directory
    @Published var currentPath: String = "~"

    /// Username on the server
    @Published var username: String = "user"

    /// Hostname of the server
    @Published var hostname: String = "server"

    /// Error message if any
    @Published var errorMessage: String?

    /// AI command suggestions based on current input
    @Published var commandSuggestions: [String] = []

    /// Partial output line from server (not yet ended with \n)
    @Published var partialLine: String = ""

    /// Contents of the current working directory for suggestions
    @Published var currentDirectoryContents: [String] = []

    /// Signal to close suggestions window immediately
    var onCloseSuggestions: (() -> Void)?

    // MARK: - Private Properties

    private let serverId: String
    private let sshService = SSHService.shared
    private var interactiveSession: SSHInteractiveSession?
    private var buffer: String = ""

    /// Command history for up/down arrow navigation
    private var commandHistory: [String] = []
    private var historyIndex: Int = -1

    /// Maximum command history size
    private let maxHistorySize = 100
    
    /// Maximum terminal lines to prevent unbounded memory growth (P2-1)
    private let maxLines = 5000
    
    /// Cached system info to avoid redundant SSH calls (P2-3)
    private var cachedUsername: String?
    private var cachedHostname: String?
    
    /// Debounce task for path-based SSH suggestions (P2-4)
    private var suggestionDebounceTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Terminal prompt (e.g. "user@server:~/path $")
    var prompt: String {
        "\(username)@\(hostname):\(currentPath) $ "
    }

    // MARK: - Initialization

    init(serverId: String) {
        self.serverId = serverId
    }

    // MARK: - Connection Management

    /// Connect to the server and start interactive terminal session
    /// - Parameter server: Server to connect to
    func connect(server: Server) async {
        state = .connecting
        addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLine("🚀 AevonX Interactive Terminal")
        addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLine("")
        addLine("Connecting to \(server.name) (\(server.host))...")

        // Check if SSH connection is established
        let connected = await sshService.isConnected(serverId: serverId)

        guard connected else {
            state = .error("Not connected to SSH")
            addLine("")
            addLine("❌ ERROR: Not connected to SSH server")
            addLine("📌 Please connect from the Overview tab first")
            addLine("")
            isConnected = false
            return
        }

        do {
            // Get initial system info
            await fetchSystemInfo()

            // Start interactive shell session
            addLine("Starting interactive shell session...")

            interactiveSession = try await sshService.startInteractive(
                command: "/bin/bash -l || /bin/sh -l || sh",  // Login shell with fallback
                serverId: serverId,
                terminalType: "xterm-256color",
                width: 120,
                height: 40,
                onOutput: { [weak self] output in
                    Task { @MainActor [weak self] in
                        self?.handleOutput(output)
                    }
                }
            )

            state = .connected
            isConnected = true

            // Initial UI refresh
            await refreshContext()

            addLine("")
            addLine("✅ Connected successfully!")
            addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            addLine("")

        } catch {
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            isConnected = false

            addLine("")
            addLine("❌ Connection failed: \(error.localizedDescription)")
            addLine("")
        }
    }

    /// Disconnect from the terminal session
    func disconnect() {
        Task {
            try? await interactiveSession?.close()
            interactiveSession = nil
            isConnected = false
            state = .disconnected

            addLine("")
            addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            addLine("🔌 Disconnected from server")
            addLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
    }

    /// Clear all terminal output

    // MARK: - Command Execution

    /// Send command to the interactive terminal
    func sendCommand() {
        guard !inputCommand.isEmpty, let session = interactiveSession else { return }

        let command = inputCommand.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle local commands
        if handleLocalCommand(command) {
            inputCommand = ""
            return
        }

        // Add to history
        addToHistory(command)

        // Send command to server
        let commandWithNewline = command + "\n"
        inputCommand = ""

        Task {
            do {
                try await session.write(commandWithNewline)
                
                // Refresh context after a command (with delay to let command finish)
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                await refreshContext()
            } catch {
                addLine("❌ Error sending command: \(error.localizedDescription)")
            }
        }
    }

    /// Navigate to previous command in history
    func previousCommand() {
        guard !commandHistory.isEmpty else { return }

        if historyIndex == -1 {
            historyIndex = commandHistory.count - 1
        } else if historyIndex > 0 {
            historyIndex -= 1
        }

        if historyIndex >= 0 && historyIndex < commandHistory.count {
            inputCommand = commandHistory[historyIndex]
        }
    }

    /// Navigate to next command in history
    func nextCommand() {
        guard historyIndex != -1 else { return }

        historyIndex += 1

        if historyIndex >= commandHistory.count {
            historyIndex = -1
            inputCommand = ""
        } else {
            inputCommand = commandHistory[historyIndex]
        }
    }

    /// Add command to history
    private func addToHistory(_ command: String) {
        // Don't add empty or duplicate consecutive commands
        guard !command.isEmpty else { return }
        if let last = commandHistory.last, last == command {
            return
        }

        commandHistory.append(command)

        // Trim history if too long
        if commandHistory.count > maxHistorySize {
            commandHistory.removeFirst(commandHistory.count - maxHistorySize)
        }

        // Reset history index
        historyIndex = -1
    }

    /// Send raw input to terminal (for special keys, etc.)
    /// - Parameter input: Input string to send
    func sendInput(_ input: String) {
        guard let session = interactiveSession else { return }

        Task {
            do {
                try await session.write(input)
            } catch {
                addLine("❌ Error sending input: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Terminal Control

    /// Clear the terminal screen
    func clear() {
        lines.removeAll()
        partialLine = ""
        addLine("")
    }

    /// Resize terminal
    /// - Parameters:
    ///   - width: New width in characters
    ///   - height: New height in rows
    func resize(width: Int, height: Int) {
        guard let session = interactiveSession else { return }

        Task {
            do {
                try await session.resize(width: width, height: height)
            } catch {
                print("Failed to resize terminal: \(error)")
            }
        }
    }

    // MARK: - Private Methods

    /// Fetch initial system information (username, hostname, path)
    /// Caches username/hostname to avoid redundant SSH calls (P2-3)
    private func fetchSystemInfo() async {
        // Get username (cache on first call)
        if cachedUsername == nil {
            if let result = try? await sshService.execute("whoami", serverId: serverId) {
                cachedUsername = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        username = cachedUsername ?? "user"

        // Get hostname (cache on first call)
        if cachedHostname == nil {
            if let result = try? await sshService.execute("hostname", serverId: serverId) {
                cachedHostname = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        hostname = cachedHostname ?? "server"

        // Get current path (always refresh — it changes with cd)
        let previousPath = currentPath
        if let result = try? await sshService.execute("pwd", serverId: serverId) {
            currentPath = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Only fetch directory contents if path changed (P3-2)
        if currentPath != previousPath {
            await fetchDirectoryContents()
        }
    }

    /// Refresh context after a command — only refreshes pwd (P2-3)
    private func refreshContext() async {
        let previousPath = currentPath
        if let result = try? await sshService.execute("pwd", serverId: serverId) {
            currentPath = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if currentPath != previousPath {
            await fetchDirectoryContents()
        }
    }

    /// Fetch files and folders in a specific directory for suggestions.
    /// Uses ShellSanitizer for path safety (P4-1).
    private func fetchDirectoryContents(path: String? = nil) async {
        let fetchPath = path ?? "."
        let safePath = ShellSanitizer.escapePath(fetchPath)
        guard let result = try? await sshService.execute("ls -F1a \(safePath)", serverId: serverId) else { return }
        
        let rawItems = result.stdout.components(separatedBy: "\n")
        let contents = rawItems
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "./" && $0 != "../" }
        
        if path == nil || path == "." {
            currentDirectoryContents = contents
        }
    }

    /// Handle output from the interactive session
    /// - Parameter output: Raw output from SSH
    private func handleOutput(_ output: String) {
        // Add to buffer
        buffer += output

        // Process lines in the buffer
        var lines = buffer.components(separatedBy: "\n")
        
        // If there's at least one newline, we process all complete lines
        if lines.count > 1 {
            // Keep the last part in the buffer (might be incomplete)
            buffer = lines.removeLast()
            
            // Add all complete lines to the display
            for line in lines {
                processLine(line)
            }
        }
        
        // Update partial line for real-time display of incomplete lines (like prompts)
        partialLine = cleanANSI(buffer)
    }

    /// Process and clean a single line of output
    /// - Parameter line: Raw line from terminal
    private func processLine(_ line: String) {
        // Clean ANSI escape codes (basic cleaning)
        let cleaned = cleanANSI(line)

        // Skip empty lines in some cases
        if cleaned.isEmpty && lines.last?.content.isEmpty == true {
            return
        }

        addLine(cleaned)
    }

    /// Clean ANSI escape codes from text
    /// - Parameter text: Text with ANSI codes
    /// - Returns: Cleaned text
    private func cleanANSI(_ text: String) -> String {
        return ANSIParser.strip(text)
    }

    /// Handle local commands that don't need to be sent to server
    /// - Parameter command: Command to check
    /// - Returns: True if command was handled locally
    private func handleLocalCommand(_ command: String) -> Bool {
        switch command {
        case "clear", "cls":
            clear()
            return true

        case "exit", "logout", "quit":
            disconnect()
            return true

        default:
            return false
        }
    }

    /// Add a line to the terminal output.
    /// Caps at `maxLines` to prevent unbounded memory growth (P2-1).
    private func addLine(_ content: String) {
        lines.append(SSHTerminalLine(content: content))
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
    }

    // MARK: - AI Command Suggestions

    /// Update command suggestions based on current input
    func updateCommandSuggestions() {
        let input = inputCommand.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !input.isEmpty else {
            commandSuggestions = []
            return
        }

        // 1. Split input to get the last "word" for path completion
        let components = input.components(separatedBy: " ")
        guard let lastWord = components.last else {
            commandSuggestions = []
            return
        }
        
        let inputLower = input.lowercased()
        var suggestions: [String] = []

        // 2. Local-aware completions (files/folders in current dir)
        // If the input starts with cd, we should filter currentDirectoryContents to show ONLY directories
        let isCD = inputLower.hasPrefix("cd")
        
        // If the last word looks like a path (contains /)
        if lastWord.contains("/") {
            let pathPart: String
            let searchPart: String
            
            if lastWord.hasSuffix("/") {
                pathPart = lastWord
                searchPart = ""
            } else {
                let parts = lastWord.components(separatedBy: "/")
                pathPart = parts.dropLast().joined(separator: "/") + "/"
                searchPart = parts.last ?? ""
            }
            
            // Debounce path-based SSH suggestions to 300ms (P2-4)
            suggestionDebounceTask?.cancel()
            suggestionDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                
                // Sanitize path before sending to SSH (P4-1)
                let safePath = ShellSanitizer.escapePath(pathPart)
                guard let result = try? await sshService.execute("ls -F1a \(safePath)", serverId: serverId) else { return }
                let items = result.stdout.components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty && $0 != "./" && $0 != "../" }
                
                guard !Task.isCancelled else { return }
                let filtered = items.filter { item in
                    let matches = item.lowercased().starts(with: searchPart.lowercased())
                    if isCD {
                        return matches && (item.hasSuffix("/") || !item.contains("."))
                    }
                    return matches
                }
                let base = components.dropLast().joined(separator: " ")
                let prefix = base.isEmpty ? "" : base + " "
                
                let newSuggestions = filtered.map { prefix + pathPart + $0 }
                if !newSuggestions.isEmpty {
                    self.commandSuggestions = Array(newSuggestions.prefix(5))
                }
            }
        }
        
        if components.count > 1 || input.contains("./") || input.contains("../") {
            // Filter directory contents
            let filteredContents = currentDirectoryContents.filter { item in
                let matches = item.lowercased().starts(with: lastWord.lowercased())
                if isCD {
                    // For CD, only show items that look like directories (ends with /)
                    return matches && item.hasSuffix("/")
                }
                return matches
            }
            
            // Reconstruct the full command suggestion
            let base = components.dropLast().joined(separator: " ")
            let prefix = base.isEmpty ? "" : base + " "
            
            suggestions = filteredContents.map { prefix + $0 }
        }

        // 3. Smart hardcoded fallback if no local files match or for top-level commands
        if suggestions.count < 3 {
            var staticSuggestions: [String] = []
            
            // File operations
            if inputLower.hasPrefix("ls") {
                staticSuggestions = ["ls -la", "ls -lh", "ls -lt", "ls -R"]
            } else if isCD {
                // Better static defaults for cd if nothing matches
                staticSuggestions = ["cd ..", "cd ~", "cd -"]
                
                // Add common web paths if we are in a web-related server
                if inputLower == "cd" || inputLower == "cd " {
                   staticSuggestions.append(contentsOf: ["cd /var/www", "cd /etc/nginx"])
                }
            } else if inputLower.hasPrefix("cat") {
                staticSuggestions = ["cat -n", "cat file.txt"]
            } else if inputLower.hasPrefix("mkdir") {
                staticSuggestions = ["mkdir -p"]
            } else if inputLower.hasPrefix("rm") {
                staticSuggestions = ["rm -rf", "rm -i"]
            }
            // System monitoring
            else if inputLower.hasPrefix("top") {
                staticSuggestions = ["top", "htop"]
            } else if inputLower.hasPrefix("ps") {
                staticSuggestions = ["ps aux", "ps -ef"]
            } else if inputLower.hasPrefix("df") {
                staticSuggestions = ["df -h"]
            } else if inputLower.hasPrefix("du") {
                staticSuggestions = ["du -sh *", "du -h --max-depth=1"]
            }
            // Network
            else if inputLower.hasPrefix("ping") {
                staticSuggestions = ["ping -c 4"]
            } else if inputLower.hasPrefix("curl") {
                staticSuggestions = ["curl -I", "curl -L"]
            } else if inputLower.hasPrefix("docker") {
                staticSuggestions = ["docker ps", "docker images", "docker logs", "docker compose up -d"]
            } else if inputLower.hasPrefix("git") {
                staticSuggestions = ["git status", "git pull", "git push", "git log --oneline"]
            } else if inputLower.hasPrefix("systemctl") {
                staticSuggestions = ["systemctl status", "systemctl restart", "systemctl stop"]
            }
            
            // Filter static suggestions that match current input
            let matchingStatic = staticSuggestions.filter { $0.lowercased().starts(with: inputLower) }
            suggestions.append(contentsOf: matchingStatic)
        }

        // 4. Add from history
        let historySuggestions = commandHistory
            .filter { $0.lowercased().starts(with: inputLower) }
            .suffix(3)

        for hist in historySuggestions {
            if !suggestions.contains(where: { $0.lowercased() == hist.lowercased() }) {
                suggestions.append(hist)
            }
        }

        // Limit to top 5 and ensure unique
        var finalSuggestions: [String] = []
        for s in suggestions {
            if !finalSuggestions.contains(s) {
                finalSuggestions.append(s)
            }
        }
        
        commandSuggestions = Array(finalSuggestions.prefix(5))
    }

    /// Accept a suggestion
    func acceptSuggestion(_ suggestion: String) {
        inputCommand = suggestion
        commandSuggestions = []
    }

    /// Explicitly close suggestions
    func closeSuggestions() {
        commandSuggestions = []
        onCloseSuggestions?()
    }
}

// MARK: - Special Keys Support

extension TerminalViewModel {

    /// Send Ctrl+C (interrupt signal)
    func sendInterrupt() {
        sendInput("\u{03}")  // ETX (End of Text) - Ctrl+C
    }

    /// Send Ctrl+D (EOF)
    func sendEOF() {
        sendInput("\u{04}")  // EOT (End of Transmission) - Ctrl+D
    }

    /// Send Ctrl+Z (suspend)
    func sendSuspend() {
        sendInput("\u{1A}")  // SUB (Substitute) - Ctrl+Z
    }

    /// Send Tab (autocomplete)
    func sendTab() {
        sendInput("\t")
    }
}
