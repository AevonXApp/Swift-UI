import Foundation

extension L10n {

    // MARK: - Plugin (Plugins.strings)
    enum Plugin {
        private static let table = "Plugins"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let official = s("plugin.official", "Official AevonX Plugin")
        static let docs = s("plugin.docs", "Docs")
        static let github = s("plugin.github", "GitHub")
        static let discord = s("plugin.discord", "Discord")
        static let editRawFile = s("plugin.editRawFile", "Edit Raw File")
        static let marketplace = s("plugin.marketplace", "Marketplace")
        static let installed = s("plugin.installed", "Installed")
        static let install = s("plugin.install", "Install")
        static let uninstall = s("plugin.uninstall", "Uninstall")
        static let configure = s("plugin.configure", "Configure")
        static let version = s("plugin.version", "Version")
    }
}
