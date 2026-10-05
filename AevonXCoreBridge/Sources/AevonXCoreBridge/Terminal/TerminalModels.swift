//
//  TerminalModels.swift
//  AevonXCoreBridge
//
//  UI-facing models for Terminal — pure logic types that don't
//  depend on NIO-SSH or interactive sessions.
//

import Foundation

// MARK: - SSH Interactive Session Protocol

/// Protocol for interactive PTY sessions.
/// The implementation lives in AevonXCore (NIO-SSH), but the type is
/// defined here so downstream code doesn't need to import AevonXCore.
public protocol SSHInteractiveSession: Sendable {
    func write(_ data: String) async throws
    func resize(width: Int, height: Int) async throws
    func close() async throws
}

// MARK: - Terminal Connection State

/// Current state of the terminal connection.
public enum TerminalConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    case reconnecting(attempt: Int)
}

// MARK: - Terminal Session Info

/// Metadata for a terminal session (tab).
public struct TerminalSessionInfo: Identifiable, Equatable {
    public let id: String
    public var name: String
    public var hasUnreadOutput: Bool
    public var isConnected: Bool
    public let createdAt: Date

    public init(name: String = "Session") {
        self.id = UUID().uuidString
        self.name = name
        self.hasUnreadOutput = false
        self.isConnected = false
        self.createdAt = Date()
    }
}

// MARK: - Cursor Style

/// Terminal cursor appearance.
public enum TerminalCursorStyle: String, CaseIterable, Identifiable, Sendable {
    case ibeam = "I-Beam"
    case block = "Block"
    case underline = "Underline"

    public var id: String { rawValue }
}

// MARK: - Terminal Font

/// Available monospaced fonts for the terminal.
public enum TerminalFontFamily: String, CaseIterable, Identifiable, Sendable {
    case sfMono = "SF Mono"
    case menlo = "Menlo"
    case monaco = "Monaco"
    case courierNew = "Courier New"

    public var id: String { rawValue }

    public var fontName: String {
        switch self {
        case .sfMono: return "SFMono-Regular"
        case .menlo: return "Menlo"
        case .monaco: return "Monaco"
        case .courierNew: return "Courier New"
        }
    }
}

// MARK: - Command History Entry

/// A command from history with metadata.
public struct CommandHistoryEntry: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public let command: String
    public let timestamp: Date
    public var executionCount: Int

    public init(command: String) {
        self.id = UUID().uuidString
        self.command = command
        self.timestamp = Date()
        self.executionCount = 1
    }
}

// MARK: - Command Snippet

/// A saved command snippet for quick access.
public struct CommandSnippet: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public var name: String
    public var command: String
    public var category: String
    public var icon: String

    public init(
        name: String, command: String,
        category: String = "General", icon: String = "terminal"
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.command = command
        self.category = category
        self.icon = icon
    }

    /// Built-in snippet templates.
    public static let builtInSnippets: [CommandSnippet] = [
        // System
        CommandSnippet(name: "System Info", command: "uname -a", category: "System", icon: "cpu"),
        CommandSnippet(name: "Disk Usage", command: "df -h", category: "System", icon: "internaldrive"),
        CommandSnippet(name: "Memory Usage", command: "free -h", category: "System", icon: "memorychip"),
        CommandSnippet(name: "Top Processes", command: "ps aux --sort=-%cpu | head -20", category: "System", icon: "chart.bar"),
        CommandSnippet(name: "Uptime", command: "uptime", category: "System", icon: "clock"),
        // Nginx
        CommandSnippet(name: "Nginx Status", command: "systemctl status nginx", category: "Nginx", icon: "server.rack"),
        CommandSnippet(name: "Nginx Reload", command: "systemctl reload nginx", category: "Nginx", icon: "arrow.clockwise"),
        CommandSnippet(name: "Nginx Test Config", command: "nginx -t", category: "Nginx", icon: "checkmark.shield"),
        CommandSnippet(name: "Nginx Error Log", command: "tail -50 /var/log/nginx/error.log", category: "Nginx", icon: "doc.text"),
        // Docker
        CommandSnippet(name: "Docker Containers", command: "docker ps -a", category: "Docker", icon: "shippingbox"),
        CommandSnippet(name: "Docker Images", command: "docker images", category: "Docker", icon: "photo.stack"),
        CommandSnippet(name: "Docker Logs", command: "docker logs --tail 100 -f", category: "Docker", icon: "scroll"),
        // Git
        CommandSnippet(name: "Git Status", command: "git status", category: "Git", icon: "arrow.triangle.branch"),
        CommandSnippet(name: "Git Pull", command: "git pull origin main", category: "Git", icon: "arrow.down.circle"),
        CommandSnippet(name: "Git Log", command: "git log --oneline -20", category: "Git", icon: "list.bullet"),
        // Network
        CommandSnippet(name: "Open Ports", command: "ss -tlnp", category: "Network", icon: "network"),
        CommandSnippet(name: "Active Connections", command: "ss -s", category: "Network", icon: "link"),
        CommandSnippet(name: "DNS Lookup", command: "dig +short", category: "Network", icon: "globe"),
    ]
}

// MARK: - Dangerous Command Detection

/// Detects potentially dangerous commands before execution.
public struct DangerousCommandDetector: Sendable {

    /// Danger level for a command.
    public enum DangerLevel: Comparable, Sendable {
        case safe
        case caution
        case dangerous
        case critical
    }

    /// Result of command analysis.
    public struct Analysis: Sendable {
        public let level: DangerLevel
        public let reason: String
        public let suggestion: String?
    }

    // MARK: - Detection Patterns

    private static let criticalPatterns: [(pattern: String, reason: String, suggestion: String?)] = [
        ("rm\\s+-rf\\s+/\\s*$", "Deletes entire root filesystem", "Use a specific path instead of /"),
        ("rm\\s+-rf\\s+/\\*", "Deletes all files in root", "Specify exact files to delete"),
        ("mkfs", "Formats a filesystem — all data will be lost", "Double-check the target device"),
        ("dd\\s+if=.*of=/dev/[sh]d", "Writes directly to disk — destroys data", "Verify the target device"),
        ("> /dev/sd", "Overwrites disk device directly", nil),
        ("chmod\\s+-R\\s+777\\s+/", "Sets world-writable permissions on root", "Use specific permissions (644/755)"),
        (":(){ :|:& };:", "Fork bomb — will crash the system", nil),
    ]

    private static let dangerousPatterns: [(pattern: String, reason: String, suggestion: String?)] = [
        ("rm\\s+-rf", "Recursively deletes files without confirmation", "Consider using rm -ri for interactive mode"),
        ("chmod\\s+777", "Sets world-writable permissions", "Use 644 for files, 755 for directories"),
        ("chown\\s+-R\\s+.*\\s+/", "Changes ownership recursively from root", "Specify exact directory"),
        ("kill\\s+-9", "Force kills a process without cleanup", "Try kill (SIGTERM) first"),
        ("shutdown", "Will shut down the server", nil),
        ("reboot", "Will reboot the server", nil),
        ("init\\s+0", "Halts the system", nil),
        ("wget.*\\|\\s*sh", "Downloads and executes remote script", "Download first, review, then execute"),
        ("curl.*\\|\\s*sh", "Downloads and executes remote script", "Download first, review, then execute"),
        ("curl.*\\|\\s*bash", "Downloads and executes remote script", "Download first, review, then execute"),
    ]

    private static let cautionPatterns: [(pattern: String, reason: String, suggestion: String?)] = [
        ("rm\\s+", "Deletes files", nil),
        ("mv\\s+/", "Moves files from root directory", nil),
        ("truncate", "Truncates file to zero length", nil),
        ("iptables\\s+-F", "Flushes all firewall rules", "Save current rules first with iptables-save"),
        ("systemctl\\s+stop", "Stops a system service", nil),
        ("systemctl\\s+disable", "Disables a system service", nil),
        ("apt\\s+remove", "Removes a package", nil),
        ("yum\\s+remove", "Removes a package", nil),
        ("drop\\s+database", "Drops a database", "Ensure you have a backup"),
        ("drop\\s+table", "Drops a database table", "Ensure you have a backup"),
    ]

    /// Analyze a command for potential dangers.
    public static func analyze(_ command: String) -> Analysis {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        for pattern in criticalPatterns {
            if trimmed.range(of: pattern.pattern, options: .regularExpression) != nil {
                return Analysis(level: .critical, reason: pattern.reason, suggestion: pattern.suggestion)
            }
        }
        for pattern in dangerousPatterns {
            if trimmed.range(of: pattern.pattern, options: .regularExpression) != nil {
                return Analysis(level: .dangerous, reason: pattern.reason, suggestion: pattern.suggestion)
            }
        }
        for pattern in cautionPatterns {
            if trimmed.range(of: pattern.pattern, options: .regularExpression) != nil {
                return Analysis(level: .caution, reason: pattern.reason, suggestion: pattern.suggestion)
            }
        }
        return Analysis(level: .safe, reason: "", suggestion: nil)
    }
}

// MARK: - ANSI Color Code

/// ANSI color codes (standard 16 colors + custom RGB).
public enum ANSIColorCode: Equatable, Sendable {
    case black, red, green, yellow, blue, magenta, cyan, white
    case brightBlack, brightRed, brightGreen, brightYellow
    case brightBlue, brightMagenta, brightCyan, brightWhite
    case custom(r: Int, g: Int, b: Int)

    /// Parse ANSI color code integer (standard 16-color SGR codes).
    public static func from(code: Int) -> ANSIColorCode? {
        switch code {
        case 30, 40: return .black
        case 31, 41: return .red
        case 32, 42: return .green
        case 33, 43: return .yellow
        case 34, 44: return .blue
        case 35, 45: return .magenta
        case 36, 46: return .cyan
        case 37, 47: return .white
        case 90, 100: return .brightBlack
        case 91, 101: return .brightRed
        case 92, 102: return .brightGreen
        case 93, 103: return .brightYellow
        case 94, 104: return .brightBlue
        case 95, 105: return .brightMagenta
        case 96, 106: return .brightCyan
        case 97, 107: return .brightWhite
        default: return nil
        }
    }

    /// Convert 256-color palette index to ANSIColorCode.
    /// Indices 0-7 → standard, 8-15 → bright, 16-231 → 6x6x6 cube, 232-255 → grayscale.
    public static func from256(index: Int) -> ANSIColorCode? {
        switch index {
        case 0: return .black
        case 1: return .red
        case 2: return .green
        case 3: return .yellow
        case 4: return .blue
        case 5: return .magenta
        case 6: return .cyan
        case 7: return .white
        case 8: return .brightBlack
        case 9: return .brightRed
        case 10: return .brightGreen
        case 11: return .brightYellow
        case 12: return .brightBlue
        case 13: return .brightMagenta
        case 14: return .brightCyan
        case 15: return .brightWhite
        case 16...231:
            // 6x6x6 color cube
            let adjusted = index - 16
            let r = adjusted / 36
            let g = (adjusted % 36) / 6
            let b = adjusted % 6
            let rVal = r == 0 ? 0 : 55 + r * 40
            let gVal = g == 0 ? 0 : 55 + g * 40
            let bVal = b == 0 ? 0 : 55 + b * 40
            return .custom(r: rVal, g: gVal, b: bVal)
        case 232...255:
            // Grayscale ramp (232=dark, 255=light)
            let gray = 8 + (index - 232) * 10
            return .custom(r: gray, g: gray, b: gray)
        default:
            return nil
        }
    }
}

// MARK: - ANSI Styled Segment

/// Represents a styled segment of terminal text.
public struct ANSIStyledSegment: Sendable {
    public let text: String
    public let foregroundColorCode: ANSIColorCode?
    public let backgroundColorCode: ANSIColorCode?
    public let isBold: Bool
    public let isItalic: Bool
    public let isUnderline: Bool

    public init(
        text: String, foregroundColor: ANSIColorCode? = nil,
        backgroundColor: ANSIColorCode? = nil,
        isBold: Bool = false, isItalic: Bool = false, isUnderline: Bool = false
    ) {
        self.text = text
        self.foregroundColorCode = foregroundColor
        self.backgroundColorCode = backgroundColor
        self.isBold = isBold
        self.isItalic = isItalic
        self.isUnderline = isUnderline
    }
}

// MARK: - ANSI Parser Core

/// Parser for ANSI escape sequences — pure Foundation, no UI imports.
public struct ANSIParserCore {

    /// Parse ANSI text and return styled segments.
    /// Supports standard 16-color, 256-color (`\e[38;5;Nm`), and true color (`\e[38;2;R;G;Bm`).
    /// Handles `\r` (carriage return) by replacing the current line content up to that point.
    public static func parse(_ text: String) -> [ANSIStyledSegment] {
        // Pre-process: handle \r (carriage return) per line
        let processed = handleCarriageReturns(text)

        var result: [ANSIStyledSegment] = []
        var currentText = ""
        var fgColor: ANSIColorCode?
        var bgColor: ANSIColorCode?
        var isBold = false
        var isItalic = false
        var isUnderline = false

        let pattern = "\u{1B}\\[([0-9;]*)m"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        var lastIndex = processed.startIndex
        let matches = regex.matches(
            in: processed, options: [],
            range: NSRange(processed.startIndex..., in: processed)
        )

        for match in matches {
            let beforeRange = lastIndex..<processed.index(
                processed.startIndex, offsetBy: match.range.location
            )
            let beforeText = String(processed[beforeRange])

            if !beforeText.isEmpty {
                currentText += beforeText
            }

            if let codesRange = Range(match.range(at: 1), in: processed) {
                let codes = String(processed[codesRange])
                    .split(separator: ";").compactMap { Int($0) }

                if !currentText.isEmpty {
                    result.append(ANSIStyledSegment(
                        text: currentText,
                        foregroundColor: fgColor, backgroundColor: bgColor,
                        isBold: isBold, isItalic: isItalic, isUnderline: isUnderline
                    ))
                    currentText = ""
                }

                // Parse codes with extended color support
                var i = 0
                while i < codes.count {
                    let code = codes[i]
                    switch code {
                    case 0:
                        fgColor = nil; bgColor = nil
                        isBold = false; isItalic = false; isUnderline = false
                    case 1: isBold = true
                    case 3: isItalic = true
                    case 4: isUnderline = true
                    case 22: isBold = false
                    case 23: isItalic = false
                    case 24: isUnderline = false
                    case 30...37, 90...97:
                        fgColor = ANSIColorCode.from(code: code)
                    case 40...47, 100...107:
                        bgColor = ANSIColorCode.from(code: code)
                    case 38:
                        // Extended foreground: 38;5;N (256) or 38;2;R;G;B (true color)
                        if i + 1 < codes.count && codes[i + 1] == 5 && i + 2 < codes.count {
                            fgColor = ANSIColorCode.from256(index: codes[i + 2])
                            i += 2
                        } else if i + 1 < codes.count && codes[i + 1] == 2 && i + 4 < codes.count {
                            fgColor = .custom(r: codes[i + 2], g: codes[i + 3], b: codes[i + 4])
                            i += 4
                        }
                    case 48:
                        // Extended background: 48;5;N (256) or 48;2;R;G;B (true color)
                        if i + 1 < codes.count && codes[i + 1] == 5 && i + 2 < codes.count {
                            bgColor = ANSIColorCode.from256(index: codes[i + 2])
                            i += 2
                        } else if i + 1 < codes.count && codes[i + 1] == 2 && i + 4 < codes.count {
                            bgColor = .custom(r: codes[i + 2], g: codes[i + 3], b: codes[i + 4])
                            i += 4
                        }
                    case 39: fgColor = nil // default foreground
                    case 49: bgColor = nil // default background
                    default: break
                    }
                    i += 1
                }
            }

            lastIndex = processed.index(
                processed.startIndex,
                offsetBy: match.range.location + match.range.length
            )
        }

        let remaining = String(processed[lastIndex...])
        if !remaining.isEmpty { currentText += remaining }

        if !currentText.isEmpty {
            result.append(ANSIStyledSegment(
                text: currentText,
                foregroundColor: fgColor, backgroundColor: bgColor,
                isBold: isBold, isItalic: isItalic, isUnderline: isUnderline
            ))
        }

        if result.isEmpty && !text.isEmpty {
            result.append(ANSIStyledSegment(text: text))
        }

        return result
    }

    /// Handle `\r` (carriage return without newline) — used by progress bars and spinners.
    /// When `\r` appears mid-line, the text after it overwrites from the beginning of the line.
    private static func handleCarriageReturns(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        for i in lines.indices {
            let line = lines[i]
            guard line.contains("\r") else { continue }

            let parts = line.components(separatedBy: "\r")
            // Each \r resets to column 0; last part overwrites from the start
            var buffer = Array(repeating: Character(" "), count: 0)
            for part in parts {
                let chars = Array(part)
                // Extend buffer if needed
                while buffer.count < chars.count {
                    buffer.append(" ")
                }
                // Overwrite from position 0
                for (j, ch) in chars.enumerated() {
                    buffer[j] = ch
                }
            }
            lines[i] = String(buffer)
        }
        return lines.joined(separator: "\n")
    }

    /// Strip all ANSI codes from text.
    public static func strip(_ text: String) -> String {
        var cleaned = text
        let patterns = [
            "\u{1B}\\[[0-9;]*m",
            "\u{1B}\\[[0-9;]*[A-Za-z]",
            "\u{1B}\\[\\?[0-9]*[a-z]",
            "\u{1B}\\][0-9];[^\u{07}]*\u{07}",
            "\u{1B}\\]0;[^\u{07}]*\u{07}",
            "\r",
        ]
        for pattern in patterns {
            cleaned = cleaned.replacingOccurrences(
                of: pattern, with: "", options: .regularExpression
            )
        }
        return cleaned
    }
}
