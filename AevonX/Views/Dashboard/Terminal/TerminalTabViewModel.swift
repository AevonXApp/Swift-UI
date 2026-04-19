//
//  TerminalTabViewModel.swift
//  AevonX
//
//  PTY session manager for SwiftTerm integration.
//  Reads raw bytes from PTY → feeds to SwiftTerm via onData callback.
//  Tracks typed input for suggestions (history + common commands).
//

import Foundation
import Combine
import SwiftUI
import AevonXCoreBridge

@MainActor
final class TerminalTabViewModel: ObservableObject, Identifiable {

    let id = UUID()

    // MARK: - Published

    @Published var connectionState: TerminalConnectionState = .disconnected
    @Published var currentDirectory: String = "~"
    @Published var sessionName: String = "Session"
    @Published var hasUnread: Bool = false
    @Published var currentInput: String = ""
    @Published var cursorRow: Int = 0
    @Published var terminalRows: Int = 24

    var isConnected: Bool { connectionState == .connected }

    // MARK: - Suggestions

    private(set) var commandHistory: [String] = []

    private static let commonCommands: [String] = [
        "ls", "ls -la", "ls -lh", "ls -lah",
        "cd ..", "cd ~", "cd /", "pwd",
        "cat", "grep", "find", "tail -f", "tail -n 100",
        "top", "htop", "ps aux", "ps aux | grep",
        "df -h", "du -sh *", "free -h",
        "mkdir", "rm -rf", "mv", "cp -r", "chmod +x", "chown -R",
        "sudo", "sudo su", "sudo -i",
        "apt update", "apt upgrade", "apt install",
        "systemctl status", "systemctl restart", "systemctl stop", "systemctl start", "systemctl enable",
        "journalctl -f", "journalctl -u",
        "nginx -t", "service nginx reload", "service nginx restart",
        "docker ps", "docker ps -a", "docker images", "docker logs -f",
        "docker-compose up -d", "docker-compose down", "docker exec -it",
        "git status", "git pull", "git log --oneline", "git diff", "git add .", "git commit -m",
        "php artisan", "php artisan migrate", "php artisan cache:clear",
        "composer install", "composer update",
        "npm install", "npm run build", "npm run dev",
        "pip install", "python3",
        "curl", "wget", "ping", "nslookup", "dig", "netstat -tlnp",
        "crontab -l", "crontab -e", "history",
    ]

    var suggestions: [String] {
        guard currentInput.count >= 2 else { return [] }
        let prefix = currentInput.lowercased()
        var seen = Set<String>()
        var results: [String] = []
        for cmd in commandHistory.reversed() {
            if cmd.lowercased().hasPrefix(prefix) && seen.insert(cmd.lowercased()).inserted {
                results.append(cmd)
                if results.count >= 6 { return results }
            }
        }
        for cmd in Self.commonCommands {
            if cmd.lowercased().hasPrefix(prefix) && seen.insert(cmd.lowercased()).inserted {
                results.append(cmd)
                if results.count >= 6 { return results }
            }
        }
        return results
    }

    func addToHistory(_ cmd: String) {
        let trimmed = cmd.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if commandHistory.last != trimmed { commandHistory.append(trimmed) }
        if commandHistory.count > 500 { commandHistory.removeFirst() }
    }

    // MARK: - Callbacks

    var onData: ((Data) -> Void)?

    // MARK: - Internal

    let serverId: String
    let ptyID: String
    private var readTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var lastServerName: String?
    private var lastServerHost: String?
    private var reconnectAttempt: Int = 0

    let prefs = TerminalPreferences.shared

    // MARK: - Init

    init(serverId: String, name: String = "Session") {
        self.serverId = serverId
        self.ptyID = "pty-\(UUID().uuidString.prefix(8))"
        self.sessionName = name
    }

    deinit {
        readTask?.cancel()
        reconnectTask?.cancel()
    }

    // MARK: - Connection

    func connect(serverName: String, serverHost: String) async {
        lastServerName = serverName
        lastServerHost = serverHost
        reconnectAttempt = 0
        connectionState = .connecting

        guard SSHBridge.shared.isConnected(serverID: serverId) else {
            connectionState = .error("SSH not connected")
            let msg = "\r\n\u{1B}[31mERROR: SSH not connected. Connect from Overview first.\u{1B}[0m\r\n"
            onData?(Data(msg.utf8))
            return
        }

        let result = PTYBridge.shared.startSession(
            serverID: serverId,
            sessionID: ptyID,
            rows: 24,
            cols: 220
        )

        guard let d = result.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              json["success"] as? Bool == true else {
            connectionState = .error("PTY failed")
            let msg = "\r\n\u{1B}[31mERROR: Could not start PTY session.\u{1B}[0m\r\n"
            onData?(Data(msg.utf8))
            if prefs.autoReconnect { scheduleReconnect() }
            return
        }

        connectionState = .connected
        startReadLoop()
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        readTask?.cancel()
        readTask = nil
        let _ = PTYBridge.shared.closeSession(sessionID: ptyID)
        connectionState = .disconnected
        let msg = "\r\n\u{1B}[90mDisconnected.\u{1B}[0m\r\n"
        onData?(Data(msg.utf8))
    }

    private func scheduleReconnect() {
        guard reconnectAttempt < prefs.maxReconnectAttempts,
              let name = lastServerName, let host = lastServerHost else { return }
        reconnectAttempt += 1
        connectionState = .reconnecting(attempt: reconnectAttempt)
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.reconnectAttempt ?? 1) * 2_000_000_000)
            guard !Task.isCancelled, let self else { return }
            await self.connect(serverName: name, serverHost: host)
        }
    }

    // MARK: - PTY Read Loop (adaptive backoff)

    private func startReadLoop() {
        readTask?.cancel()
        readTask = Task { [weak self] in
            var idleCount: UInt64 = 0
            while !Task.isCancelled {
                guard let self, self.isConnected else { break }
                if let data = PTYBridge.shared.read(sessionID: self.ptyID, maxBytes: 65536),
                   !data.isEmpty {
                    idleCount = 0
                    await MainActor.run {
                        self.onData?(data)
                        self.hasUnread = true
                    }
                } else {
                    // Adaptive backoff: 5ms → 10ms → 20ms → 50ms (idle cap)
                    idleCount += 1
                    let delay: UInt64 = min(50_000_000, 5_000_000 * min(idleCount, 10))
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
    }

    // MARK: - Write

    func write(data: Data) {
        let _ = PTYBridge.shared.write(sessionID: ptyID, data: data)
    }

    func write(text: String) {
        let _ = PTYBridge.shared.writeString(sessionID: ptyID, text: text)
    }

    func clear() { write(text: "clear\n") }

    func resize(cols: Int, rows: Int) {
        guard isConnected else { return }
        let _ = PTYBridge.shared.resize(sessionID: ptyID, rows: rows, cols: cols)
    }

    // MARK: - Path Breadcrumb

    var pathSegments: [(label: String, path: String)] {
        guard currentDirectory != "~" else { return [(label: "~", path: "~")] }
        let parts = currentDirectory.components(separatedBy: "/").filter { !$0.isEmpty }
        var segments: [(label: String, path: String)] = []
        var cumPath = ""
        for part in parts {
            cumPath += "/\(part)"
            segments.append((label: part, path: cumPath))
        }
        return segments.isEmpty ? [(label: "~", path: "~")] : segments
    }
}
