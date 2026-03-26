import Foundation

extension L10n {

    // MARK: - Files (Files.strings)
    enum Files {
        private static let table = "Files"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let goToPath = s("files.goToPath", "Go to Path")
        static let create = s("files.create", "Create")
        static let copyPath = s("files.copyPath", "Copy Path")
        static let editPermissions = s("files.editPermissions", "Edit Permissions")
        static let caseSensitive = s("files.caseSensitive", "Case Sensitive")
        static let wholeWord = s("files.wholeWord", "Whole Word")
        static let replace = s("files.replace", "Replace")
        static let replaceAll = s("files.replaceAll", "All")
        static let search = s("files.search", "Search")
        static let newFile = s("files.newFile", "New File")
        static let newFolder = s("files.newFolder", "New Folder")
        static let rename = s("files.rename", "Rename")
        static let download = s("files.download", "Download")
        static let upload = s("files.upload", "Upload")
    }
}
