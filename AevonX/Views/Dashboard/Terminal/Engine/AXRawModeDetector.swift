//
//  AXRawModeDetector.swift
//  AevonX
//
//  Detects when the terminal should switch to raw mode (direct PTY passthrough).
//  Raw mode is needed for interactive commands: vim, top, password prompts, etc.
//

import Foundation

// MARK: - Raw Mode Reason

enum AXRawModeReason: Equatable {
    case alternateScreen       // vim, less, htop, etc. (\e[?1049h)
    case passwordPrompt        // sudo, ssh, etc.
    case interactiveCommand    // Known interactive commands
    case none
}

// MARK: - Raw Mode Detector

final class AXRawModeDetector {

    // MARK: - State

    private(set) var isRawMode: Bool = false
    private(set) var reason: AXRawModeReason = .none
    private var inAlternateScreen: Bool = false

    // MARK: - Known Interactive Commands

    private static let interactiveCommands: Set<String> = [
        "vim", "vi", "nvim", "nano", "emacs", "pico",
        "top", "htop", "btop", "glances", "nmon",
        "less", "more", "most",
        "ssh", "telnet", "ftp", "sftp",
        "mysql", "psql", "redis-cli", "mongo", "mongosh",
        "python", "python3", "node", "irb", "lua",
        "tmux", "screen", "byobu",
        "mc", "ranger", "nnn",
        "watch", "dialog", "whiptail",
    ]

    /// Password prompt patterns
    private static let passwordPatterns: [String] = [
        "[Pp]assword:",
        "[Pp]assword for",
        "[Pp]assphrase:",
        "\\[sudo\\]",
        "Enter passphrase",
        "Enter PIN",
        "Verification code:",
        "Enter password:",
        "Password \\(again\\):",
        "New password:",
        "Retype new password:",
    ]

    // MARK: - Detection

    /// Analyze PTY output to determine if raw mode should be active.
    /// Returns true if raw mode state changed.
    @discardableResult
    func processOutput(_ output: String) -> Bool {
        let previousState = isRawMode

        // Check for alternate screen buffer
        if output.contains("\u{1B}[?1049h") || output.contains("\u{1B}[?47h") {
            inAlternateScreen = true
            isRawMode = true
            reason = .alternateScreen
        }

        if output.contains("\u{1B}[?1049l") || output.contains("\u{1B}[?47l") {
            inAlternateScreen = false
            if reason == .alternateScreen {
                isRawMode = false
                reason = .none
            }
        }

        // Check for password prompts (only if not already in alt screen)
        if !inAlternateScreen {
            for pattern in Self.passwordPatterns {
                if output.range(of: pattern, options: .regularExpression) != nil {
                    isRawMode = true
                    reason = .passwordPrompt
                    break
                }
            }
        }

        return isRawMode != previousState
    }

    /// Check if a command is known to be interactive.
    func isInteractiveCommand(_ command: String) -> Bool {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstWord = trimmed.split(separator: " ").first.map(String.init) ?? trimmed

        // Handle commands with path prefix (e.g., /usr/bin/vim)
        let baseName = firstWord.components(separatedBy: "/").last ?? firstWord

        // Check for sudo/env prefix
        if baseName == "sudo" || baseName == "env" {
            let parts = trimmed.split(separator: " ").dropFirst()
            if let nextCmd = parts.first {
                let nextBase = String(nextCmd).components(separatedBy: "/").last ?? String(nextCmd)
                return Self.interactiveCommands.contains(nextBase)
            }
        }

        return Self.interactiveCommands.contains(baseName)
    }

    /// Force enter raw mode for a known interactive command.
    func enterRawMode(reason: AXRawModeReason) {
        isRawMode = true
        self.reason = reason
    }

    /// Exit raw mode when prompt is detected after command finishes.
    func exitRawMode() {
        guard !inAlternateScreen else { return }
        isRawMode = false
        reason = .none
    }

    /// Reset all state.
    func reset() {
        isRawMode = false
        reason = .none
        inAlternateScreen = false
    }
}
