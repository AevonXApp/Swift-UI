//
//  TerminalBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core Terminal operations.
//  Covers: models, snippets, danger detection, ANSI parsing, suggestions, commands.
//

import Foundation
import AevonXCoreLib

public final class TerminalBridge: @unchecked Sendable {

    public static let shared = TerminalBridge()
    private init() {}

    // MARK: - Data

    public func getCursorStyles() -> String {
        extract(TerminalGetCursorStyles())
    }

    public func getFontFamilies() -> String {
        extract(TerminalGetFontFamilies())
    }

    public func getSnippets() -> String {
        extract(TerminalGetSnippets())
    }

    // MARK: - Command Danger Analysis

    public func analyzeCommand(_ command: String) -> String {
        withCArgs { c in extract(TerminalAnalyzeCommand(c.str(command))) }
    }

    // MARK: - Suggestions

    public func getSuggestions(input: String) -> String {
        withCArgs { c in extract(TerminalGetSuggestions(c.str(input))) }
    }

    // MARK: - ANSI

    public func parseANSI(text: String) -> String {
        withCArgs { c in extract(TerminalParseANSI(c.str(text))) }
    }

    public func stripANSI(text: String) -> String {
        withCArgs { c in extract(TerminalStripANSI(c.str(text))) }
    }

    // MARK: - SSH Commands

    public func getCommands() -> String {
        extract(TerminalGetCommands())
    }

    public func cmdListDir(path: String) -> String {
        withCArgs { c in extract(TerminalCmdListDir(c.str(path))) }
    }

    public func parseDirectoryListing(output: String) -> String {
        withCArgs { c in extract(TerminalParseDirectoryListing(c.str(output))) }
    }

    // MARK: - Model Decode

    public func decodeSessionInfo(json: String) -> String {
        withCArgs { c in extract(TerminalDecodeSessionInfo(c.str(json))) }
    }

    public func decodeHistory(json: String) -> String {
        withCArgs { c in extract(TerminalDecodeHistory(c.str(json))) }
    }

    // MARK: - Helpers

    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        return String(cString: cStr)
    }
}
