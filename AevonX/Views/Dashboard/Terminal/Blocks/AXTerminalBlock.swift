//
//  AXTerminalBlock.swift
//  AevonX
//
//  Core data model for block-based terminal output.
//  Each block = one command execution + its output + metadata.
//

import Foundation
import AevonXCoreBridge

// MARK: - Terminal Block

/// A discrete unit grouping a command + its output.
/// Blocks stack vertically in the terminal canvas.
struct AXTerminalBlock: Identifiable {
    let id: UUID
    let command: String
    var lines: [AXTerminalLine]
    let startTime: Date
    var endTime: Date?
    var exitCode: Int?
    var isCollapsed: Bool
    var isBookmarked: Bool
    var workingDirectory: String?

    var duration: TimeInterval? {
        guard let end = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return end.timeIntervalSince(startTime)
    }

    var isRunning: Bool { endTime == nil }
    var isSuccess: Bool { exitCode == 0 }
    var isFailed: Bool { (exitCode ?? 0) != 0 && !isRunning }

    var durationText: String {
        guard let dur = duration else { return "" }
        if dur < 1 { return String(format: "%.0fms", dur * 1000) }
        if dur < 60 { return String(format: "%.1fs", dur) }
        let mins = Int(dur) / 60
        let secs = Int(dur) % 60
        return "\(mins)m \(secs)s"
    }

    var statusIcon: String {
        if isRunning { return "arrow.trianglehead.clockwise" }
        if isSuccess { return "checkmark" }
        return "xmark"
    }

    var plainOutput: String {
        lines.map(\.rawText).joined(separator: "\n")
    }

    init(
        command: String,
        workingDirectory: String? = nil
    ) {
        self.id = UUID()
        self.command = command
        self.lines = []
        self.startTime = Date()
        self.endTime = nil
        self.exitCode = nil
        self.isCollapsed = false
        self.isBookmarked = false
        self.workingDirectory = workingDirectory
    }
}

// MARK: - Terminal Line

/// A single line of terminal output within a block.
struct AXTerminalLine: Identifiable {
    let id: UUID
    let segments: [ANSIStyledSegment]
    let rawText: String
    let lineType: LineType

    enum LineType {
        case stdout
        case stderr
        case system
    }

    init(rawOutput: String, type: LineType = .stdout) {
        self.id = UUID()
        let cleaned = Self.stripNonSGREscapes(rawOutput)
        self.rawText = ANSIParserCore.strip(cleaned)
        self.segments = ANSIParserCore.parse(cleaned)
        self.lineType = type
    }

    init(systemMessage: String, type: LineType = .system) {
        self.id = UUID()
        self.rawText = systemMessage
        self.segments = [ANSIStyledSegment(text: systemMessage)]
        self.lineType = type
    }

    /// Strip escape sequences that aren't SGR (color) codes.
    /// Keeps \e[...m for ANSI color rendering.
    private static func stripNonSGREscapes(_ text: String) -> String {
        var result = text
        let patterns = [
            "\u{1B}\\[\\?[0-9;]*[a-z]",   // DEC private modes
            "\u{1B}\\[[0-9;]*[A-LN-Z]",     // Cursor movement (not 'm')
            "\u{1B}\\][^\u{07}\u{1B}]*(?:\u{07}|\u{1B}\\\\)", // OSC sequences
        ]
        for pattern in patterns {
            result = result.replacingOccurrences(
                of: pattern, with: "", options: .regularExpression
            )
        }
        return result
    }
}

// MARK: - System Block

/// A non-command block for system messages (connection status, etc.)
struct AXSystemBlock: Identifiable {
    let id: UUID
    let lines: [AXTerminalLine]
    let timestamp: Date

    init(messages: [String]) {
        self.id = UUID()
        self.lines = messages.map { AXTerminalLine(systemMessage: $0) }
        self.timestamp = Date()
    }
}

// MARK: - Block Entry (Discriminated Union)

/// Represents any entry in the terminal scroll buffer.
enum AXBlockEntry: Identifiable {
    case command(AXTerminalBlock)
    case system(AXSystemBlock)

    var id: UUID {
        switch self {
        case .command(let block): return block.id
        case .system(let block): return block.id
        }
    }

    var isCommand: Bool {
        if case .command = self { return true }
        return false
    }

    var commandBlock: AXTerminalBlock? {
        if case .command(let block) = self { return block }
        return nil
    }
}
