//
//  AXBlockDetector.swift
//  AevonX
//
//  Detects block boundaries in PTY output using OSC 133 shell integration
//  sequences and heuristic prompt detection as fallback.
//
//  OSC 133 protocol (same as iTerm2 / VS Code terminal):
//    \e]133;A\e\\ = Prompt start
//    \e]133;B\e\\ = Command start (user pressed Enter)
//    \e]133;C\e\\ = Command output start
//    \e]133;D;{exitcode}\e\\ = Command finished
//

import Foundation
import AevonXCoreBridge

// MARK: - Block Detector Events

enum AXBlockEvent {
    case promptStart
    case commandStart(command: String)
    case outputStart
    case commandFinished(exitCode: Int)
    case promptDetected(prompt: String)
    case outputLine(text: String)
}

// MARK: - Block Detector

final class AXBlockDetector {

    // MARK: - Shell Integration Script

    /// Bash shell integration — inject after session starts.
    /// Sets up OSC 133 markers around prompt/command/output boundaries.
    static let bashIntegrationScript: String = """
    __ax_preexec() { printf '\\e]133;C\\e\\\\'; }
    __ax_prompt_command() {
        local ec=$?
        printf '\\e]133;D;%d\\e\\\\' "$ec"
        printf '\\e]133;A\\e\\\\'
    }
    if [[ ! "$PROMPT_COMMAND" == *"__ax_prompt_command"* ]]; then
        PROMPT_COMMAND="__ax_prompt_command${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    fi
    trap '__ax_preexec' DEBUG
    PS1="\\[\\e]133;B\\e\\\\\\]$PS1"
    """

    /// Zsh shell integration
    static let zshIntegrationScript: String = """
    __ax_precmd() {
        local ec=$?
        printf '\\e]133;D;%d\\e\\\\' "$ec"
        printf '\\e]133;A\\e\\\\'
    }
    __ax_preexec() { printf '\\e]133;C\\e\\\\'; }
    [[ -z "${precmd_functions[(r)__ax_precmd]}" ]] && precmd_functions+=(__ax_precmd)
    [[ -z "${preexec_functions[(r)__ax_preexec]}" ]] && preexec_functions+=(__ax_preexec)
    PROMPT="%{$(printf '\\e]133;B\\e\\\\')%}$PROMPT"
    """

    // MARK: - State

    private var oscEnabled: Bool = false
    private var pendingCommand: String = ""
    private var heuristicPromptPatterns: [String] = ["$ ", "# ", "% ", "❯ ", "> "]
    private var lastPrompt: String = ""

    // MARK: - OSC 133 Parsing

    /// Process raw PTY output and emit block events.
    /// Returns cleaned output (all non-SGR escape sequences stripped) and events detected.
    func processOutput(_ raw: String) -> (cleaned: String, events: [AXBlockEvent]) {
        var events: [AXBlockEvent] = []
        var cleaned = raw

        // 1. Extract OSC 133 events BEFORE stripping
        let oscPattern = "\u{1B}\\]133;([A-D])(?:;([^\u{07}\u{1B}]*))?(?:\u{07}|\u{1B}\\\\)"

        if let regex = try? NSRegularExpression(pattern: oscPattern) {
            let nsRange = NSRange(cleaned.startIndex..., in: cleaned)
            let matches = regex.matches(in: cleaned, range: nsRange)

            if !matches.isEmpty { oscEnabled = true }

            for match in matches.reversed() {
                if let typeRange = Range(match.range(at: 1), in: cleaned) {
                    let type = String(cleaned[typeRange])
                    let param: String?
                    if match.range(at: 2).location != NSNotFound,
                       let pRange = Range(match.range(at: 2), in: cleaned) {
                        param = String(cleaned[pRange])
                    } else {
                        param = nil
                    }

                    switch type {
                    case "A": events.append(.promptStart)
                    case "B": events.append(.commandStart(command: pendingCommand))
                    case "C": events.append(.outputStart)
                    case "D":
                        let exitCode = param.flatMap(Int.init) ?? 0
                        events.append(.commandFinished(exitCode: exitCode))
                    default: break
                    }
                }

                if let fullRange = Range(match.range, in: cleaned) {
                    cleaned.removeSubrange(fullRange)
                }
            }

            events.reverse()
        }

        // 2. Strip ALL non-SGR escape sequences from output
        cleaned = Self.stripNonSGRSequences(cleaned)

        // 3. If OSC not available, use heuristic prompt detection
        if !oscEnabled {
            events.append(contentsOf: detectPromptsHeuristically(in: cleaned))
        }

        return (cleaned, events)
    }

    // MARK: - Escape Sequence Stripping

    /// Strip CSI sequences (cursor, mode, erase), OSC sequences (title, etc.),
    /// and other non-SGR escapes. Preserves SGR color/style sequences (\e[...m)
    /// for the ANSI parser to handle.
    private static func stripNonSGRSequences(_ text: String) -> String {
        var result = text

        // Patterns to strip (order matters — most specific first)
        let patterns: [(String, String)] = [
            // OSC sequences: \e]...BEL or \e]...\e\\  (title, hyperlinks, etc.)
            ("\u{1B}\\][^\u{07}\u{1B}]*(?:\u{07}|\u{1B}\\\\)", ""),
            // DEC private mode: \e[?...h, \e[?...l (bracketed paste, alt screen, etc.)
            ("\u{1B}\\[\\?[0-9;]*[hl]", ""),
            // CSI cursor/erase: \e[...A-Z (except m which is SGR)
            ("\u{1B}\\[[0-9;]*[A-LN-Z]", ""),
            // CSI lowercase (except m): \e[...a-l, n-z
            ("\u{1B}\\[[0-9;]*[a-ln-z]", ""),
            // \e( and \e) — character set selection
            ("\u{1B}[()].", ""),
            // \e= and \e> — keypad mode
            ("\u{1B}[=>]", ""),
            // Standalone \r not followed by \n (progress bar overwrites)
            // Don't strip \r\n — those are normal line endings
            ("\r(?!\n)", ""),
        ]

        for (pattern, replacement) in patterns {
            result = result.replacingOccurrences(
                of: pattern, with: replacement, options: .regularExpression
            )
        }

        return result
    }

    /// Set the pending command text (captured from input editor before sending).
    func setPendingCommand(_ command: String) {
        pendingCommand = command
    }

    // MARK: - Heuristic Prompt Detection (Fallback)

    private func detectPromptsHeuristically(in text: String) -> [AXBlockEvent] {
        var events: [AXBlockEvent] = []
        let stripped = ANSIParserCore.strip(text).trimmingCharacters(in: .whitespaces)

        for pattern in heuristicPromptPatterns {
            if stripped.hasSuffix(pattern.trimmingCharacters(in: .whitespaces)) {
                events.append(.promptDetected(prompt: stripped))
                break
            }
        }

        return events
    }

    /// Update prompt patterns based on detected prompt format.
    func addPromptPattern(_ pattern: String) {
        if !heuristicPromptPatterns.contains(pattern) {
            heuristicPromptPatterns.append(pattern)
        }
    }

    // MARK: - Shell Detection

    /// Returns the appropriate integration script based on shell type.
    static func integrationScript(for shell: String) -> String {
        let shellName = shell.components(separatedBy: "/").last ?? shell
        switch shellName {
        case "zsh":
            return zshIntegrationScript
        case "bash":
            return bashIntegrationScript
        default:
            // Fallback to bash-style
            return bashIntegrationScript
        }
    }

    /// Command to detect the current shell.
    static let shellDetectionCommand = "echo \"AX_SHELL:$SHELL\""

    /// Parse shell detection response.
    static func parseShellType(from output: String) -> String? {
        guard let range = output.range(of: "AX_SHELL:") else { return nil }
        let shell = output[range.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return shell.isEmpty ? nil : shell
    }

    // MARK: - State Queries

    var isOSCEnabled: Bool { oscEnabled }
}
