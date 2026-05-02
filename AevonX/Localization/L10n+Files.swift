import Foundation

extension L10n {

    // MARK: - Files (Files.strings)
    enum Files {
        private static let table = "Files"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let goToPath = s("files.goToPath", "Go to Path")
        static let copyPath = s("files.copyPath", "Copy Path")
        static let editPermissions = s("files.editPermissions", "Edit Permissions")
        static let caseSensitive = s("files.caseSensitive", "Case Sensitive")
        static let wholeWord = s("files.wholeWord", "Whole Word")
        static let replace = s("files.replace", "Replace")
        static let replaceAll = s("files.replaceAll", "All")
        static let newFile = s("files.newFile", "New File")
        static let newFolder = s("files.newFolder", "New Folder")
        static let rename = s("files.rename", "Rename")
        static let download = s("files.download", "Download")
        static let files = s("files.files", "Files")
        static let discard = s("files.discard", "Discard")
        static let upgradeToUnlockGit = s("files.upgradeToUnlockGit", "Upgrade to unlock Git")
        static let installing = s("files.installing", "Installing...")
        static let quickAccess = s("files.quickAccess", "QUICK ACCESS")
        static let sortBy = s("files.sortBy", "SORT BY")
        static let batchPermissions = s("files.batchPermissions", "Batch Permissions")
        static let permissions = s("files.permissions", "Permissions:")
        static let applyRecursivelyToDirectories = s("files.applyRecursivelyToDirectories", "Apply recursively to directories")
        static let changeOwner = s("files.changeOwner", "Change Owner")
        static let owner = s("files.owner", "Owner")
        static let group = s("files.group", "Group")
        static let custom = s("files.custom", "Custom")
        static let compressFiles = s("files.compressFiles", "Compress Files")
        static let archiveName = s("files.archiveName", "Archive Name")
        static let format = s("files.format", "Format")
        static let compress = s("files.compress", "Compress")
        static let downloadFromUrl = s("files.downloadFromUrl", "Download from URL")
        static let fileNameOptional = s("files.fileNameOptional", "File Name (optional)")
        static let searchInFileContents = s("files.searchInFileContents", "Search in File Contents")
        static let numeric = s("files.numeric", "Numeric")
        static let accessLevel = s("files.accessLevel", "Access Level")
        static let quickPresets = s("files.quickPresets", "Quick Presets")
        static let fileName = s("files.fileName", "File Name")
        static let folderName = s("files.folderName", "Folder Name")
        static let createSymlink = s("files.createSymlink", "Create Symlink")
        static let linkName = s("files.linkName", "Link Name")
    }
}
