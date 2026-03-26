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
    }
}
