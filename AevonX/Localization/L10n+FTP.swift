import Foundation

extension L10n {

    // MARK: - FTP (FTP.strings)
    enum FTP {
        private static let table = "FTP"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let title = s("ftp.title", "FTP Users")
        static let addUser = s("ftp.addUser", "Add User")
        static let editUser = s("ftp.editUser", "Edit User")
        static let deleteUser = s("ftp.deleteUser", "Delete User")
        static let homeDirectory = s("ftp.homeDirectory", "Home Directory")
        static let username = s("ftp.username", "Username")
        static let password = s("ftp.password", "Password")
        static let status = s("ftp.status", "Status")
        static let enabled = s("ftp.enabled", "Enabled")
        static let disabled = s("ftp.disabled", "Disabled")
        static let noUsers = s("ftp.noUsers", "No FTP Users")
        static let addFirstUser = s("ftp.addFirstUser", "Add your first FTP user to get started")
    }
}
