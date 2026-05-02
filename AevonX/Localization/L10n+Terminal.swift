import Foundation

extension L10n {

    // MARK: - Terminal (Terminal.strings)
    enum Terminal {
        private static let table = "Terminal"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let deleteSnippet = s("terminal.deleteSnippet", "Delete snippet")
        static let snippets = s("terminal.snippets", "Snippets")
        static let addSnippet = s("terminal.addSnippet", "Add Snippet")
        static let history = s("terminal.history", "History")
        static let connected = s("terminal.connected", "Connected")
        static let disconnected = s("terminal.disconnected", "Disconnected")
        static let connecting = s("terminal.connecting", "Connecting...")
        static let reconnecting = s("terminal.reconnecting", "Reconnecting...")
        static let copyCommand = s("terminal.copyCommand", "Copy Command")
        static let copyOutput = s("terminal.copyOutput", "Copy Output")
        static let copyAll = s("terminal.copyAll", "Copy All")
        static let bookmark = s("terminal.bookmark", "Bookmark")
        static let collapse = s("terminal.collapse", "Collapse")
        static let rerun = s("terminal.rerun", "Re-run Command")
        static let clearBlock = s("terminal.clearBlock", "Clear Block")
        static let session = s("terminal.session", "Session")
        static let searchInBlock = s("terminal.searchInBlock", "Search in Block")
        static let editAndRerun = s("terminal.editAndRerun", "Edit & Re-run")
        static let terminalSettings = s("terminal.terminalSettings", "Terminal Settings")
        static let fontFamily = s("terminal.fontFamily", "Font Family")
        static let fontSize = s("terminal.fontSize", "Font Size")
        static let style = s("terminal.style", "Style")
        static let cursorBlink = s("terminal.cursorBlink", "Cursor Blink")
        static let scrollbackLines = s("terminal.scrollbackLines", "Scrollback Lines")
        static let dangerousCommandWarnings = s("terminal.dangerousCommandWarnings", "Dangerous Command Warnings")
        static let autoReconnect = s("terminal.autoReconnect", "Auto Reconnect")
        static let commandTimer = s("terminal.commandTimer", "Command Timer")
        static let noSnippetsFound = s("terminal.noSnippetsFound", "No snippets found")
        static let tryADifferentSearchOrAddANewSnippet = s("terminal.tryADifferentSearchOrAddANewSnippet", "Try a different search or add a new snippet")
        static let custom = s("terminal.custom", "Custom")
        static let newCustomSnippet = s("terminal.newCustomSnippet", "New Custom Snippet")
        static let loadingDirectories = s("terminal.loadingDirectories", "Loading directories...")
        static let noSubdirectories = s("terminal.noSubdirectories", "No subdirectories")
        static let terminal = s("terminal.terminal", "Terminal")
        static let disconnect = s("terminal.disconnect", "Disconnect")
    }
}
