import Foundation

extension L10n {

    // MARK: - Fleet (Fleet.strings)
    enum Fleet {
        private static let table = "Fleet"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let title = s("fleet.title", "Remote Fleet")
        static let loading = s("fleet.loading", "Loading servers...")
        static let noServers = s("fleet.noServers", "No Servers Yet")
        static let addFirstServer = s("fleet.addFirstServer", "Add your first server to get started")
        static let addServer = s("fleet.addServer", "Add Server")
        static let noResults = s("fleet.noResults", "No Servers Found")
        static let adjustFilters = s("fleet.adjustFilters", "Try adjusting your filters or search criteria")
        static let clearSearch = s("fleet.clearSearch", "Clear Search")
        static let clearFilter = s("fleet.clearFilter", "Clear Filter")
        static let searchPlaceholder = s("fleet.searchPlaceholder", "Search by name, host, or tags...")
        static let editServer = s("fleet.editServer", "Edit Server")
        static let duplicate = s("fleet.duplicate", "Duplicate")
        static let deleteServer = s("fleet.deleteServer", "Delete Server")
        static let copyIP = s("fleet.copyIP", "Copy IP Address")
        static let serverIdentity = s("fleet.serverIdentity", "Server Identity")
        static let connectionDetails = s("fleet.connectionDetails", "Connection Details")
        static let authentication = s("fleet.authentication", "Authentication")
        static let serverNameHelp = s("fleet.serverNameHelp", "Server name is not encrypted and visible in the server list.")
        static let tagsHelp = s("fleet.tagsHelp", "Add tags like 'production', 'staging' to organize servers.")
        static let tagsPlaceholder = s("fleet.tagsPlaceholder", "production, staging, web, database")
        static let currentPasswordKept = s("fleet.currentPasswordKept", "• current password kept")
        static let currentKeyKept = s("fleet.currentKeyKept", "• current key kept")
        static let statusOnline = s("fleet.statusOnline", "Online")
        static let statusOffline = s("fleet.statusOffline", "Offline")
        static let freeLimit = s("fleet.freeLimit", "Free Limit")
        static let upgradeToConnect = s("fleet.upgradeToConnect", "Upgrade to Connect")
        static let pro = s("fleet.pro", "PRO")

        static func online(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) Online"
            return String(localized: "fleet.online", defaultValue: dv, table: table)
        }

        static func offline(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) Offline"
            return String(localized: "fleet.offline", defaultValue: dv, table: table)
        }

        static func noFilterResults(_ filter: String) -> String {
            let dv: String.LocalizationValue = "No \(filter) servers match your criteria"
            return String(localized: "fleet.noFilterResults", defaultValue: dv, table: table)
        }

        static func noSearchResults(_ query: String) -> String {
            let dv: String.LocalizationValue = "No servers match '\(query)'"
            return String(localized: "fleet.noSearchResults", defaultValue: dv, table: table)
        }

        static func filterCount(_ filtered: Int, _ total: Int) -> String {
            let dv: String.LocalizationValue = "\(filtered) of \(total)"
            return String(localized: "fleet.filterCount", defaultValue: dv, table: table)
        }

        static func moreTagsCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "+\(count)"
            return String(localized: "fleet.moreTags", defaultValue: dv, table: table)
        }
    }
}
