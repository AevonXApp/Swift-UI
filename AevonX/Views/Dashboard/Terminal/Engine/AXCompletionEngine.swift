//
//  AXCompletionEngine.swift
//  AevonX
//
//  3-tier completion engine:
//    Tier 1: Static tool specs (instant, ~50ms)
//    Tier 2: Dynamic server fetch (cached, ~200ms)
//    Tier 3: History + frecency (background)
//

import Foundation
import AevonXCoreBridge

// MARK: - Completion Item

struct AXCompletion: Identifiable, Hashable {
    let id: UUID
    let text: String
    let displayText: String
    let description: String?
    let icon: String?
    let kind: CompletionKind
    let score: Double

    init(
        text: String,
        displayText: String? = nil,
        description: String? = nil,
        icon: String? = nil,
        kind: CompletionKind = .command,
        score: Double = 0
    ) {
        self.id = UUID()
        self.text = text
        self.displayText = displayText ?? text
        self.description = description
        self.icon = icon
        self.kind = kind
        self.score = score
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AXCompletion, rhs: AXCompletion) -> Bool {
        lhs.id == rhs.id
    }
}

enum CompletionKind: Equatable {
    case command
    case subcommand
    case flag
    case path
    case gitBranch
    case dockerContainer
    case history
    case snippet
    case variable
    case service
}

// MARK: - Completion Context

struct CompletionContext {
    let cwd: String
    let fullInput: String
    let cursorPosition: Int
    let commandPrefix: String
    let currentWord: String
    let wordIndex: Int
    let isFlag: Bool

    init(input: String, cwd: String) {
        self.cwd = cwd
        self.fullInput = input
        self.cursorPosition = input.count

        let parts = input.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        self.commandPrefix = parts.first ?? ""
        self.currentWord = parts.last ?? ""
        self.wordIndex = max(0, parts.count - 1)
        self.isFlag = (parts.last ?? "").hasPrefix("-")
    }
}

// MARK: - Tool Spec

struct ToolSpec {
    let command: String
    let description: String?
    let subcommands: [SubcommandSpec]
    let globalFlags: [FlagSpec]
}

struct SubcommandSpec {
    let name: String
    let description: String
    let flags: [FlagSpec]
}

struct FlagSpec {
    let long: String
    let short: String?
    let description: String
    let takesValue: Bool
    let values: [String]?

    init(
        long: String,
        short: String? = nil,
        description: String = "",
        takesValue: Bool = false,
        values: [String]? = nil
    ) {
        self.long = long
        self.short = short
        self.description = description
        self.takesValue = takesValue
        self.values = values
    }
}

// MARK: - Completion Engine

actor AXCompletionEngine {

    // MARK: - State

    private var toolSpecs: [String: ToolSpec] = [:]
    private var shellHistory: [CommandHistoryEntry] = []
    private var directoryCache: [String: (entries: [String], timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 5

    // MARK: - Registration

    func registerSpec(_ spec: ToolSpec) {
        toolSpecs[spec.command] = spec
    }

    func registerSpecs(_ specs: [ToolSpec]) {
        for spec in specs {
            toolSpecs[spec.command] = spec
        }
    }

    func updateHistory(_ entries: [CommandHistoryEntry]) {
        shellHistory = entries
    }

    func addHistoryEntry(_ entry: CommandHistoryEntry) {
        shellHistory.append(entry)
        if shellHistory.count > 1000 {
            shellHistory.removeFirst(shellHistory.count - 1000)
        }
    }

    // MARK: - Completion

    func complete(context: CompletionContext) -> [AXCompletion] {
        var results: [AXCompletion] = []

        // Tier 1: Static tool specs
        results.append(contentsOf: completeFromSpecs(context: context))

        // Tier 3: History
        results.append(contentsOf: completeFromHistory(context: context))

        // Sort by score (descending), deduplicate
        var seen = Set<String>()
        return results
            .sorted { $0.score > $1.score }
            .filter { seen.insert($0.text).inserted }
            .prefix(12)
            .map { $0 }
    }

    /// Ghost text autosuggestion from history.
    func autosuggestion(for input: String) -> String? {
        guard !input.isEmpty else { return nil }
        let inputLower = input.lowercased()

        // Find best history match
        var bestMatch: (command: String, score: Double)?
        let now = Date()

        for entry in shellHistory.reversed() {
            let cmdLower = entry.command.lowercased()
            guard cmdLower.hasPrefix(inputLower), cmdLower != inputLower else { continue }

            // Frecency score
            let age = now.timeIntervalSince(entry.timestamp)
            let recencyBonus: Double
            if age < 3600 { recencyBonus = 20 }        // last hour
            else if age < 86400 { recencyBonus = 10 }   // last day
            else { recencyBonus = 0 }

            let freqBonus = Double(min(entry.executionCount, 10)) * 2
            let score = recencyBonus + freqBonus

            if bestMatch == nil || score > bestMatch!.score {
                bestMatch = (entry.command, score)
            }
        }

        guard let match = bestMatch else { return nil }
        // Return only the suffix (the part user hasn't typed yet)
        return String(match.command.dropFirst(input.count))
    }

    // MARK: - Tier 1: Static Specs

    private func completeFromSpecs(context: CompletionContext) -> [AXCompletion] {
        let command = context.commandPrefix.lowercased()

        // If user is typing the first word, match against all known commands
        if context.wordIndex == 0 {
            return toolSpecs.keys
                .filter { $0.lowercased().hasPrefix(context.currentWord.lowercased()) }
                .map { cmd in
                    let spec = toolSpecs[cmd]
                    return AXCompletion(
                        text: cmd,
                        description: spec?.description,
                        icon: "terminal",
                        kind: .command,
                        score: fuzzyScore(candidate: cmd, query: context.currentWord) + 50
                    )
                }
        }

        // Look up spec for the base command
        guard let spec = toolSpecs[command] else { return [] }

        // If typing a flag
        if context.isFlag {
            return completeFlagsFromSpec(spec, context: context)
        }

        // Complete subcommands
        return spec.subcommands
            .filter { subCmd in
                context.currentWord.isEmpty ||
                subCmd.name.lowercased().hasPrefix(context.currentWord.lowercased()) ||
                fuzzyMatch(candidate: subCmd.name, query: context.currentWord)
            }
            .map { subCmd in
                AXCompletion(
                    text: subCmd.name,
                    description: subCmd.description,
                    icon: "chevron.right",
                    kind: .subcommand,
                    score: fuzzyScore(candidate: subCmd.name, query: context.currentWord) + 40
                )
            }
    }

    private func completeFlagsFromSpec(
        _ spec: ToolSpec,
        context: CompletionContext
    ) -> [AXCompletion] {
        // Find which subcommand we're in (if any)
        let parts = context.fullInput.split(separator: " ").map(String.init)
        var flags = spec.globalFlags

        if parts.count >= 2 {
            let subCmdName = parts[1].lowercased()
            if let subCmd = spec.subcommands.first(where: { $0.name.lowercased() == subCmdName }) {
                flags = subCmd.flags + spec.globalFlags
            }
        }

        let query = context.currentWord
        return flags
            .filter { flag in
                query.isEmpty ||
                flag.long.hasPrefix(query) ||
                (flag.short != nil && flag.short!.hasPrefix(query))
            }
            .map { flag in
                let display = flag.short != nil ? "\(flag.long), \(flag.short!)" : flag.long
                return AXCompletion(
                    text: flag.long,
                    displayText: display,
                    description: flag.description,
                    icon: "minus",
                    kind: .flag,
                    score: fuzzyScore(candidate: flag.long, query: query) + 30
                )
            }
    }

    // MARK: - Tier 3: History

    private func completeFromHistory(context: CompletionContext) -> [AXCompletion] {
        let input = context.fullInput.lowercased()
        guard !input.isEmpty else { return [] }

        let now = Date()
        return shellHistory
            .filter { $0.command.lowercased().hasPrefix(input) && $0.command.lowercased() != input }
            .suffix(5)
            .map { entry in
                let age = now.timeIntervalSince(entry.timestamp)
                let recencyBonus: Double = age < 3600 ? 15 : (age < 86400 ? 8 : 0)
                let freqBonus = Double(min(entry.executionCount, 5)) * 2
                return AXCompletion(
                    text: entry.command,
                    description: L10n.Terminal.history,
                    icon: "clock",
                    kind: .history,
                    score: recencyBonus + freqBonus + 10
                )
            }
    }

    // MARK: - Fuzzy Matching

    private func fuzzyMatch(candidate: String, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        var queryIndex = query.lowercased().startIndex
        let candidateLower = candidate.lowercased()

        for char in candidateLower {
            if char == query.lowercased()[queryIndex] {
                queryIndex = query.lowercased().index(after: queryIndex)
                if queryIndex == query.lowercased().endIndex { return true }
            }
        }
        return false
    }

    private func fuzzyScore(candidate: String, query: String) -> Double {
        guard !query.isEmpty else { return 0 }
        let candidateLower = candidate.lowercased()
        let queryLower = query.lowercased()

        // Exact prefix
        if candidateLower.hasPrefix(queryLower) { return 100 }

        // Substring
        if candidateLower.contains(queryLower) { return 50 }

        // Fuzzy character match
        var score: Double = 0
        var queryIdx = queryLower.startIndex
        var lastMatchPos = -1

        for (pos, char) in candidateLower.enumerated() {
            guard queryIdx < queryLower.endIndex else { break }
            if char == queryLower[queryIdx] {
                score += 10
                // Bonus for consecutive matches
                if lastMatchPos == pos - 1 { score += 5 }
                // Penalty for gaps
                if lastMatchPos >= 0 { score -= Double(pos - lastMatchPos - 1) * 2 }
                lastMatchPos = pos
                queryIdx = queryLower.index(after: queryIdx)
            }
        }

        // Penalty if not all query chars matched
        if queryIdx < queryLower.endIndex { score -= 20 }

        return max(0, score)
    }

    // MARK: - Dynamic Completions (Tier 2)

    func updateDirectoryCache(path: String, entries: [String]) {
        directoryCache[path] = (entries: entries, timestamp: Date())
    }

    func getCachedDirectory(path: String) -> [String]? {
        guard let cached = directoryCache[path],
              Date().timeIntervalSince(cached.timestamp) < cacheTTL else {
            return nil
        }
        return cached.entries
    }

    func invalidateDirectoryCache() {
        directoryCache.removeAll()
    }
}
