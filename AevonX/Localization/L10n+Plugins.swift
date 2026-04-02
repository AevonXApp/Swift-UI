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
        static let community = s("plugin.community", "Community")
        static let search = s("plugin.search", "Search plugins...")
        static let loading = s("plugin.loading", "Loading marketplace...")
        static let noPlugins = s("plugin.noPlugins", "No plugins found")
        static let noInstalled = s("plugin.noInstalled", "No plugins installed")
        static let browseHint = s("plugin.browseHint", "Browse the marketplace to find powerful extensions.")
        static let adjustFilters = s("plugin.adjustFilters", "Try adjusting your search or filters.")
        static let buy = s("plugin.buy", "Purchase")
        static let proOnly = s("plugin.proOnly", "Pro Only")
        static let all = s("plugin.all", "All")
        static let reinstall = s("plugin.reinstall", "Reinstall")
        static let downloads = s("plugin.downloads", "Downloads")
        static let rating = s("plugin.rating", "Rating")
        static let support = s("plugin.support", "Support")
        static let repository = s("plugin.repository", "Repository")

        // MARK: - Detail
        enum Detail {
            private static let table = "Plugins"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let about = s("plugin.detail.about", "About")
            static let versions = s("plugin.detail.versions", "Versions")
            static let whatsNew = s("plugin.detail.whatsNew", "What's New")
            static let developer = s("plugin.detail.developer", "Developer")
            static let latest = s("plugin.detail.latest", "Latest")
            static let current = s("plugin.detail.current", "Installed")
            static let noChangelog = s("plugin.detail.noChangelog", "No changelog available")
            static let noDescription = s("plugin.detail.noDescription", "No description available")
            static let noVersions = s("plugin.detail.noVersions", "No versions available")
            static let showAllVersions = s("plugin.detail.showAllVersions", "Show All Versions")
            static let olderVersion = s("plugin.detail.olderVersion", "Older Version")
            static let servers = s("plugin.detail.servers", "Servers")
            static let category = s("plugin.detail.category", "Category")
            static let verifiedDeveloper = s("plugin.detail.verifiedDeveloper", "Verified")
            static let newPlugin = s("plugin.detail.newPlugin", "New")
        }

        // MARK: - Update
        enum Update {
            private static let table = "Plugins"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let available = s("plugin.update.available", "Update Available")
            static let updateAll = s("plugin.update.updateAll", "Update All")
            static let update = s("plugin.update.update", "Update")
            static let checkingUpdates = s("plugin.update.checking", "Checking for updates...")
            static let noUpdates = s("plugin.update.noUpdates", "All plugins are up to date")
            static let verifyingLicense = s("plugin.update.verifyingLicense", "Verifying license...")
            static let downloading = s("plugin.update.downloading", "Downloading update...")
            static let installing = s("plugin.update.installing", "Installing update...")
            static let finalizing = s("plugin.update.finalizing", "Finalizing...")
            static let complete = s("plugin.update.complete", "Update complete")
            static let failed = s("plugin.update.failed", "Update failed")
            static let licenseFailed = s("plugin.update.licenseFailed", "License verification failed")
            static let downloadFailed = s("plugin.update.downloadFailed", "Failed to prepare download. Please try again.")
            static let genericError = s("plugin.update.genericError", "Update failed. Please try again later.")

            static func newVersion(_ version: String) -> String {
                "v\(version) available"
            }

            static func successToast(_ name: String) -> String {
                "\(name) updated successfully"
            }
        }
    }
}
