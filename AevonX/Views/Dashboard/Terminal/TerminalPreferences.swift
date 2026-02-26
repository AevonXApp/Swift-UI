//
//  TerminalPreferences.swift
//  AevonX
//
//  Persistent terminal preferences
//  Uses @Published with UserDefaults for clean ObservableObject conformance
//

import SwiftUI
import Combine
import AevonXCore

// MARK: - Terminal Preferences

@MainActor
class TerminalPreferences: ObservableObject {
    
    static let shared = TerminalPreferences()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Appearance
    
    @Published var themeId: String {
        didSet { defaults.set(themeId, forKey: "terminal.themeId") }
    }
    
    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: "terminal.fontSize") }
    }
    
    @Published var fontName: String {
        didSet { defaults.set(fontName, forKey: "terminal.fontName") }
    }
    
    @Published var cursorStyleRaw: String {
        didSet { defaults.set(cursorStyleRaw, forKey: "terminal.cursorStyleRaw") }
    }
    
    @Published var cursorBlink: Bool {
        didSet { defaults.set(cursorBlink, forKey: "terminal.cursorBlink") }
    }
    
    @Published var backgroundOpacity: Double {
        didSet { defaults.set(backgroundOpacity, forKey: "terminal.backgroundOpacity") }
    }
    
    // MARK: - Behavior
    
    @Published var scrollbackLines: Int {
        didSet { defaults.set(scrollbackLines, forKey: "terminal.scrollbackLines") }
    }
    
    @Published var showDangerWarnings: Bool {
        didSet { defaults.set(showDangerWarnings, forKey: "terminal.showDangerWarnings") }
    }
    
    @Published var autoReconnect: Bool {
        didSet { defaults.set(autoReconnect, forKey: "terminal.autoReconnect") }
    }
    
    @Published var maxReconnectAttempts: Int {
        didSet { defaults.set(maxReconnectAttempts, forKey: "terminal.maxReconnectAttempts") }
    }
    
    @Published var showCommandTimer: Bool {
        didSet { defaults.set(showCommandTimer, forKey: "terminal.showCommandTimer") }
    }
    
    // MARK: - Init (load from UserDefaults)
    
    private init() {
        self.themeId = defaults.string(forKey: "terminal.themeId") ?? "aevonx-dark"
        self.fontSize = defaults.object(forKey: "terminal.fontSize") as? Double ?? 14
        self.fontName = defaults.string(forKey: "terminal.fontName") ?? "SFMono-Regular"
        self.cursorStyleRaw = defaults.string(forKey: "terminal.cursorStyleRaw") ?? "I-Beam"
        self.cursorBlink = defaults.object(forKey: "terminal.cursorBlink") as? Bool ?? true
        self.backgroundOpacity = defaults.object(forKey: "terminal.backgroundOpacity") as? Double ?? 1.0
        self.scrollbackLines = defaults.object(forKey: "terminal.scrollbackLines") as? Int ?? 5000
        self.showDangerWarnings = defaults.object(forKey: "terminal.showDangerWarnings") as? Bool ?? true
        self.autoReconnect = defaults.object(forKey: "terminal.autoReconnect") as? Bool ?? true
        self.maxReconnectAttempts = defaults.object(forKey: "terminal.maxReconnectAttempts") as? Int ?? 3
        self.showCommandTimer = defaults.object(forKey: "terminal.showCommandTimer") as? Bool ?? true
    }
    
    // MARK: - Computed Properties
    
    var theme: TerminalTheme {
        TerminalTheme.allThemes.first(where: { $0.id == themeId }) ?? .aevonxDark
    }
    
    var cursorStyle: TerminalCursorStyle {
        TerminalCursorStyle(rawValue: cursorStyleRaw) ?? .ibeam
    }
    
    var nsFont: NSFont {
        NSFont(name: fontName, size: CGFloat(fontSize))
            ?? .monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
    }
}
