//
//  AXTerminalSearch.swift
//  AevonX
//
//  Full-text search across terminal blocks with highlighting.
//

import Foundation

// MARK: - Search Result

struct AXSearchResult: Identifiable {
    let id: UUID
    let blockID: UUID
    let lineIndex: Int
    let range: Range<String.Index>
    let matchText: String

    init(blockID: UUID, lineIndex: Int, range: Range<String.Index>, matchText: String) {
        self.id = UUID()
        self.blockID = blockID
        self.lineIndex = lineIndex
        self.range = range
        self.matchText = matchText
    }
}

// MARK: - Terminal Search

final class AXTerminalSearch {

    /// Search across all blocks for a query string.
    func search(
        query: String,
        in blocks: [AXBlockEntry],
        caseSensitive: Bool = false
    ) -> [AXSearchResult] {
        guard !query.isEmpty else { return [] }

        var results: [AXSearchResult] = []
        let options: String.CompareOptions = caseSensitive ? [] : .caseInsensitive

        for entry in blocks {
            guard case .command(let block) = entry else { continue }

            // Search in command text
            if let range = block.command.range(of: query, options: options) {
                results.append(AXSearchResult(
                    blockID: block.id,
                    lineIndex: -1,
                    range: range,
                    matchText: String(block.command[range])
                ))
            }

            // Search in output lines
            for (lineIdx, line) in block.lines.enumerated() {
                var searchStart = line.rawText.startIndex
                while searchStart < line.rawText.endIndex {
                    let searchRange = searchStart..<line.rawText.endIndex
                    if let range = line.rawText.range(of: query, options: options, range: searchRange) {
                        results.append(AXSearchResult(
                            blockID: block.id,
                            lineIndex: lineIdx,
                            range: range,
                            matchText: String(line.rawText[range])
                        ))
                        searchStart = range.upperBound
                    } else {
                        break
                    }
                }
            }
        }

        return results
    }
}
