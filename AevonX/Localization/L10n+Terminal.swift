import Foundation

extension L10n {

    // MARK: - Terminal (Terminal.strings)
    enum Terminal {
        private static let table = "Terminal"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let tabCompletion = s("terminal.tabCompletion", "Tab completion")
        static let sendInterrupt = s("terminal.sendInterrupt", "Send interrupt (Ctrl+C)")
        static let deleteSnippet = s("terminal.deleteSnippet", "Delete snippet")
        static let newTab = s("terminal.newTab", "New Tab")
        static let closeTab = s("terminal.closeTab", "Close Tab")
        static let clear = s("terminal.clear", "Clear")
        static let snippets = s("terminal.snippets", "Snippets")
        static let addSnippet = s("terminal.addSnippet", "Add Snippet")
        static let history = s("terminal.history", "History")
        static let connected = s("terminal.connected", "Connected")
        static let disconnected = s("terminal.disconnected", "Disconnected")
        static let connecting = s("terminal.connecting", "Connecting...")
        static let reconnecting = s("terminal.reconnecting", "Reconnecting...")
        static let interactiveMode = s("terminal.interactiveMode", "Interactive Mode")
        static let search = s("terminal.search", "Search")
        static let copyCommand = s("terminal.copyCommand", "Copy Command")
        static let copyOutput = s("terminal.copyOutput", "Copy Output")
        static let copyAll = s("terminal.copyAll", "Copy All")
        static let bookmark = s("terminal.bookmark", "Bookmark")
        static let collapse = s("terminal.collapse", "Collapse")
        static let expand = s("terminal.expand", "Expand")
        static let rerun = s("terminal.rerun", "Re-run Command")
        static let clearBlock = s("terminal.clearBlock", "Clear Block")
        static let settings = s("terminal.settings", "Settings")
        static let session = s("terminal.session", "Session")
        static let searchInBlock = s("terminal.searchInBlock", "Search in Block")
        static let editAndRerun = s("terminal.editAndRerun", "Edit & Re-run")
        static let noResults = s("terminal.noResults", "No results")
    }
}
