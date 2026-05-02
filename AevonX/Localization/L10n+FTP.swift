import Foundation

extension L10n {

    // MARK: - FTP (FTP.strings)
    enum FTP {
        private static let table = "FTP"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let addUser = s("ftp.addUser", "Add User")
        static let editUser = s("ftp.editUser", "Edit User")
        static let username = s("ftp.username", "Username")
        static let password = s("ftp.password", "Password")
        static let status = s("ftp.status", "Status")
        static let disabled = s("ftp.disabled", "Disabled")
        static let noUsers = s("ftp.noUsers", "No FTP Users")
        static let ftpManager = s("ftp.ftpManager", "FTP Manager")
        static let settings = s("ftp.settings", "Settings")
        static let addFtp = s("ftp.addFtp", "Add FTP")
        static let ftpAddress = s("ftp.ftpAddress", "FTP address:")
        static let pureftpd = s("ftp.pureftpd", "PureFTPd")
        static let user = s("ftp.user", "User")
        static let quota = s("ftp.quota", "Quota")
        static let actions = s("ftp.actions", "Actions")
        static let type = s("ftp.type", "Type")
        static let timestamp = s("ftp.timestamp", "Timestamp")
        static let message = s("ftp.message", "Message")
        static let pureftpdNotInstalled = s("ftp.pureftpdNotInstalled", "PureFTPd Not Installed")
        static let configureFtpAccessCredentialsAndPermissions = s("ftp.configureFtpAccessCredentialsAndPermissions", "Configure FTP access credentials and permissions")
        static let useTheGenerateButtonForASecureRandomPassword = s("ftp.useTheGenerateButtonForASecureRandomPassword", "Use the generate button for a secure random password")
        static let browse = s("ftp.browse", "Browse")
        static let quick = s("ftp.quick", "Quick:")
        static let emptyDirectory = s("ftp.emptyDirectory", "Empty directory")
        static let ftpSettings = s("ftp.ftpSettings", "FTP Settings")
        static let changeTheFtpListeningPortDefault = s("ftp.changeTheFtpListeningPortDefault", "Change the FTP listening port. Default: 21")
        static let changePort = s("ftp.changePort", "Change Port")
    }
}
