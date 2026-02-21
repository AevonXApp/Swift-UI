//
//  FileManagerViewModel.swift
//  AevonX
//
//  ViewModel for SSH File Manager
//  Connects the UI to AevonXCore's SFTPFileManager
//

import SwiftUI
import Combine
import AevonXCore

// MARK: - File Manager ViewModel

@MainActor
final class FileManagerViewModel: ObservableObject {
    
    // MARK: - Properties
    
    let serverId: String
    
    // Tab Management
    @Published var tabs: [FileBrowserTabState] = [FileBrowserTabState()]
    @Published var activeTabIndex: Int = 0
    
    // File Listing
    @Published var files: [RemoteFileItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Selection
    @Published var selectedFiles: Set<String> = []
    @Published var lastSelectedFile: RemoteFileItem?
    
    // Search
    @Published var searchText = ""
    @Published var searchResults: [RemoteFileItem] = []
    @Published var isSearching = false
    
    // Sorting
    @Published var sortOrder: FileSortOrder = .nameAscending
    @Published var showHiddenFiles = true
    
    // Editor
    @Published var isEditorOpen = false
    @Published var editorFile: RemoteFileItem?
    @Published var editorContent = ""
    @Published var editorOriginalContent = ""
    @Published var isSavingFile = false
    @Published var isLoadingFile = false
    
    // Permissions Editor
    @Published var isPermissionsEditorOpen = false
    @Published var permissionsFile: RemoteFileItem?
    @Published var editingPermissions: FilePermissions?
    @Published var isSavingPermissions = false
    
    // Transfers
    @Published var activeTransfers: [FileTransferProgress] = []
    @Published var showUploadSheet = false
    @Published var showNewFolderSheet = false
    @Published var showNewFileSheet = false
    @Published var showDownloadURLSheet = false
    @Published var isDownloadingFromURL = false
    
    // Clipboard for Copy/Cut/Paste
    @Published var clipboard: FileClipboard?
    
    // Compress
    @Published var showCompressSheet = false
    @Published var isCompressing = false
    @Published var isExtracting = false
    
    // Symlink
    @Published var showSymlinkSheet = false
    @Published var symlinkSourceFile: RemoteFileItem?
    
    // Change Owner
    @Published var showChangeOwnerSheet = false
    @Published var changeOwnerFile: RemoteFileItem?
    
    // Go To Path
    @Published var showGoToPath = false
    @Published var goToPathText = ""
    
    // Rename
    @Published var isRenaming = false
    @Published var renamingFile: RemoteFileItem?
    @Published var renameText = ""
    
    // Delete Confirmation
    @Published var showDeleteConfirmation = false
    @Published var filesToDelete: [RemoteFileItem] = []
    
    // Quick Access
    @Published var quickAccessPaths: [(icon: String, title: String, path: String)] = []
    
    // Disk Usage
    @Published var diskUsage: String = ""
    
    // Search debounce
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var activeTab: FileBrowserTabState {
        guard tabs.indices.contains(activeTabIndex) else {
            return FileBrowserTabState()
        }
        return tabs[activeTabIndex]
    }
    
    var currentPath: String {
        activeTab.currentPath
    }
    
    /// Path components for breadcrumb navigation
    var pathComponents: [(name: String, path: String)] {
        let path = currentPath
        var components: [(name: String, path: String)] = []
        var current = ""
        
        for part in path.split(separator: "/") {
            current += "/\(part)"
            components.append((name: String(part), path: current))
        }
        
        if components.isEmpty {
            components.append(("/", "/"))
        }
        
        return components
    }
    
    var canGoBack: Bool { activeTab.canGoBack }
    var canGoForward: Bool { activeTab.canGoForward }
    
    var isEditorDirty: Bool {
        editorContent != editorOriginalContent
    }
    
    /// Filtered and sorted file list
    var displayFiles: [RemoteFileItem] {
        var result = files
        
        if !showHiddenFiles {
            result = result.filter { !$0.isHidden }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return sortOrder.sort(result)
    }
    
    // MARK: - Session Persistence Keys
    
    private var sessionKey: String { "fm_session_\(serverId)" }
    
    // MARK: - Initialization
    
    init(serverId: String) {
        self.serverId = serverId
        restoreSession()
    }
    
    // MARK: - Session Persistence
    
    /// Save current tabs + settings to UserDefaults
    private func saveSession() {
        let tabData = tabs.map { ["id": $0.id, "title": $0.title, "path": $0.currentPath] }
        let session: [String: Any] = [
            "tabs": tabData,
            "activeTabIndex": activeTabIndex,
            "showHidden": showHiddenFiles,
            "sortOrder": sortOrder.rawValue
        ]
        UserDefaults.standard.set(session, forKey: sessionKey)
    }
    
    /// Restore tabs + settings from UserDefaults
    private func restoreSession() {
        guard let session = UserDefaults.standard.dictionary(forKey: sessionKey) else { return }
        
        if let tabData = session["tabs"] as? [[String: String]], !tabData.isEmpty {
            var restoredTabs: [FileBrowserTabState] = []
            for data in tabData {
                let path = data["path"] ?? "/root"
                let title = data["title"] ?? (path as NSString).lastPathComponent
                restoredTabs.append(FileBrowserTabState(
                    title: title,
                    currentPath: path,
                    pathHistory: [path]
                ))
            }
            tabs = restoredTabs
        }
        
        if let idx = session["activeTabIndex"] as? Int, tabs.indices.contains(idx) {
            activeTabIndex = idx
        }
        
        if let hidden = session["showHidden"] as? Bool {
            showHiddenFiles = hidden
        }
        
        if let sortRaw = session["sortOrder"] as? String,
           let sort = FileSortOrder(rawValue: sortRaw) {
            sortOrder = sort
        }
    }
    
    // MARK: - Tab Management
    
    func createTab(path: String = "/root") {
        let tab = FileBrowserTabState(
            title: (path as NSString).lastPathComponent,
            currentPath: path,
            pathHistory: [path]
        )
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
        Task { await loadFiles() }
        saveSession()
    }
    
    func closeTab(at index: Int) {
        guard tabs.count > 1, tabs.indices.contains(index) else { return }
        tabs.remove(at: index)
        if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        }
        Task { await loadFiles() }
        saveSession()
    }
    
    func switchToTab(_ index: Int) {
        guard tabs.indices.contains(index) else { return }
        activeTabIndex = index
        Task { await loadFiles() }
        saveSession()
    }
    
    // MARK: - Navigation
    
    func navigateTo(_ path: String) {
        guard tabs.indices.contains(activeTabIndex) else { return }
        tabs[activeTabIndex].navigateTo(path)
        selectedFiles.removeAll()
        lastSelectedFile = nil
        Task { await loadFiles() }
        saveSession()
    }
    
    func goBack() {
        guard tabs.indices.contains(activeTabIndex) else { return }
        tabs[activeTabIndex].goBack()
        selectedFiles.removeAll()
        Task { await loadFiles() }
        saveSession()
    }
    
    func goForward() {
        guard tabs.indices.contains(activeTabIndex) else { return }
        tabs[activeTabIndex].goForward()
        selectedFiles.removeAll()
        Task { await loadFiles() }
        saveSession()
    }
    
    func goToParent() {
        let parent = (currentPath as NSString).deletingLastPathComponent
        navigateTo(parent.isEmpty ? "/" : parent)
    }
    
    func navigateToQuickAccess(_ path: String) {
        navigateTo(path)
    }
    
    // MARK: - File Loading
    
    func loadFiles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            files = try await SFTPFileManager.shared.listDirectory(
                path: currentPath,
                serverId: serverId,
                showHidden: showHiddenFiles
            )
        } catch {
            errorMessage = error.localizedDescription
            files = []
        }
        
        isLoading = false
    }
    
    func refresh() {
        Task { await loadFiles() }
    }
    
    // MARK: - Initial Load
    
    private var hasLoadedOnce = false
    
    func initialLoad() async {
        // Load quick access paths
        quickAccessPaths = await SFTPFileManager.shared.getQuickAccessPaths(serverId: serverId)
        
        // Only set home directory on first load — don't override user's current path
        if !hasLoadedOnce {
            hasLoadedOnce = true
            
            if let homePath = quickAccessPaths.first(where: { $0.title == "Home" }) {
                if tabs.indices.contains(activeTabIndex) {
                    tabs[activeTabIndex] = FileBrowserTabState(
                        id: tabs[activeTabIndex].id,
                        title: "Home",
                        currentPath: homePath.path,
                        pathHistory: [homePath.path]
                    )
                }
            }
        }
        
        // Load files for current path
        await loadFiles()
        
        // Load disk usage in background
        Task {
            if let usage = try? await SFTPFileManager.shared.getDiskUsage(path: currentPath, serverId: serverId) {
                diskUsage = usage
            }
        }
    }
    
    // MARK: - File Selection
    
    func selectFile(_ file: RemoteFileItem) {
        lastSelectedFile = file
        if selectedFiles.contains(file.id) {
            selectedFiles.remove(file.id)
        } else {
            selectedFiles.insert(file.id)
        }
    }
    
    func selectSingleFile(_ file: RemoteFileItem) {
        selectedFiles = [file.id]
        lastSelectedFile = file
    }
    
    func clearSelection() {
        selectedFiles.removeAll()
        lastSelectedFile = nil
    }
    
    func handleFileDoubleTap(_ file: RemoteFileItem) {
        if file.isDirectory {
            navigateTo(file.path)
        } else {
            openFileEditor(file)
        }
    }
    
    // MARK: - File Editor
    
    func openFileEditor(_ file: RemoteFileItem) {
        editorFile = file
        isLoadingFile = true
        isEditorOpen = true
        
        Task {
            do {
                let content = try await SFTPFileManager.shared.readFile(
                    path: file.path,
                    serverId: serverId
                )
                editorContent = content
                editorOriginalContent = content
            } catch {
                errorMessage = "Failed to open file: \(error.localizedDescription)"
                isEditorOpen = false
            }
            isLoadingFile = false
        }
    }
    
    func saveFile() {
        guard let file = editorFile else { return }
        isSavingFile = true
        
        Task {
            do {
                try await SFTPFileManager.shared.writeFile(
                    path: file.path,
                    content: editorContent,
                    serverId: serverId
                )
                editorOriginalContent = editorContent
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
            isSavingFile = false
        }
    }
    
    func closeEditor() {
        isEditorOpen = false
        editorFile = nil
        editorContent = ""
        editorOriginalContent = ""
    }
    
    // MARK: - Permissions Editor
    
    func openPermissionsEditor(_ file: RemoteFileItem) {
        permissionsFile = file
        editingPermissions = file.permissions
        isPermissionsEditorOpen = true
    }
    
    func savePermissions() {
        guard let file = permissionsFile, let perms = editingPermissions else { return }
        isSavingPermissions = true
        
        Task {
            do {
                try await SFTPFileManager.shared.changePermissions(
                    path: file.path,
                    mode: perms.numericString,
                    serverId: serverId
                )
                isPermissionsEditorOpen = false
                await loadFiles()
            } catch {
                errorMessage = "Failed to change permissions: \(error.localizedDescription)"
            }
            isSavingPermissions = false
        }
    }
    
    // MARK: - File Operations
    
    func createFolder(name: String) {
        let path = currentPath.hasSuffix("/") ? "\(currentPath)\(name)" : "\(currentPath)/\(name)"
        
        Task {
            do {
                try await SFTPFileManager.shared.createDirectory(path: path, serverId: serverId)
                await loadFiles()
            } catch {
                errorMessage = "Failed to create folder: \(error.localizedDescription)"
            }
        }
    }
    
    func confirmDelete(_ files: [RemoteFileItem]) {
        filesToDelete = files
        showDeleteConfirmation = true
    }
    
    func deleteConfirmed() {
        let toDelete = filesToDelete
        showDeleteConfirmation = false
        filesToDelete = []
        
        Task {
            for file in toDelete {
                do {
                    try await SFTPFileManager.shared.deleteItem(path: file.path, serverId: serverId)
                } catch {
                    errorMessage = "Failed to delete \(file.name): \(error.localizedDescription)"
                }
            }
            selectedFiles.removeAll()
            await loadFiles()
        }
    }
    
    func deleteSelected() {
        let selected = files.filter { selectedFiles.contains($0.id) }
        guard !selected.isEmpty else { return }
        confirmDelete(selected)
    }
    
    func startRename(_ file: RemoteFileItem) {
        renamingFile = file
        renameText = file.name
        isRenaming = true
    }
    
    func confirmRename() {
        guard let file = renamingFile, !renameText.isEmpty, renameText != file.name else {
            isRenaming = false
            return
        }
        
        let parentPath = (file.path as NSString).deletingLastPathComponent
        let newPath = (parentPath as NSString).appendingPathComponent(renameText)
        
        isRenaming = false
        
        Task {
            do {
                try await SFTPFileManager.shared.renameItem(from: file.path, to: newPath, serverId: serverId)
                await loadFiles()
            } catch {
                errorMessage = "Failed to rename: \(error.localizedDescription)"
            }
        }
    }
    
    func duplicateFile(_ file: RemoteFileItem) {
        let ext = (file.name as NSString).pathExtension
        let baseName = (file.name as NSString).deletingPathExtension
        let newName = ext.isEmpty ? "\(baseName) (copy)" : "\(baseName) (copy).\(ext)"
        let parentPath = (file.path as NSString).deletingLastPathComponent
        let newPath = (parentPath as NSString).appendingPathComponent(newName)
        
        Task {
            do {
                try await SFTPFileManager.shared.copyItem(from: file.path, to: newPath, serverId: serverId)
                await loadFiles()
            } catch {
                errorMessage = "Failed to duplicate: \(error.localizedDescription)"
            }
        }
    }
    
    func copyPath(_ file: RemoteFileItem) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(file.path, forType: .string)
        #endif
    }
    
    // MARK: - Create File
    
    func createFile(name: String) {
        let path = currentPath.hasSuffix("/") ? "\(currentPath)\(name)" : "\(currentPath)/\(name)"
        
        Task {
            do {
                try await SFTPFileManager.shared.createFile(path: path, serverId: serverId)
                await loadFiles()
            } catch {
                errorMessage = "Failed to create file: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Select All / Deselect
    
    func selectAll() {
        selectedFiles = Set(displayFiles.map { $0.id })
        lastSelectedFile = displayFiles.last
    }
    
    func deselectAll() {
        selectedFiles.removeAll()
        lastSelectedFile = nil
    }
    
    // MARK: - Copy / Cut / Paste
    
    func copyFiles() {
        let selected = files.filter { selectedFiles.contains($0.id) }
        guard !selected.isEmpty else { return }
        clipboard = FileClipboard(files: selected, isCut: false)
    }
    
    func cutFiles() {
        let selected = files.filter { selectedFiles.contains($0.id) }
        guard !selected.isEmpty else { return }
        clipboard = FileClipboard(files: selected, isCut: true)
    }
    
    func pasteFiles() {
        guard let clipboard = clipboard else { return }
        let destDir = currentPath
        
        Task {
            for file in clipboard.files {
                let destName = file.name
                let destPath = destDir.hasSuffix("/") ? "\(destDir)\(destName)" : "\(destDir)/\(destName)"
                
                do {
                    if clipboard.isCut {
                        try await SFTPFileManager.shared.renameItem(from: file.path, to: destPath, serverId: serverId)
                    } else {
                        try await SFTPFileManager.shared.copyItem(from: file.path, to: destPath, serverId: serverId)
                    }
                } catch {
                    errorMessage = "Failed to paste \(file.name): \(error.localizedDescription)"
                }
            }
            
            if clipboard.isCut {
                self.clipboard = nil
            }
            
            selectedFiles.removeAll()
            await loadFiles()
        }
    }
    
    var hasClipboard: Bool {
        clipboard != nil && !(clipboard?.files.isEmpty ?? true)
    }
    
    // MARK: - Download from URL
    
    func downloadFromURL(urlString: String, fileName: String? = nil) {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        let name = fileName?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? fileName!
            : url.lastPathComponent.isEmpty ? "downloaded_file" : url.lastPathComponent
        
        let destPath = currentPath.hasSuffix("/") ? "\(currentPath)\(name)" : "\(currentPath)/\(name)"
        
        isDownloadingFromURL = true
        
        Task {
            do {
                try await SFTPFileManager.shared.downloadFromURL(
                    url: urlString,
                    destPath: destPath,
                    serverId: serverId
                )
                await loadFiles()
            } catch {
                errorMessage = "Failed to download: \(error.localizedDescription)"
            }
            isDownloadingFromURL = false
            showDownloadURLSheet = false
        }
    }
    // MARK: - Archive Operations
    
    /// Extract an archive file in-place
    func extractArchive(_ file: RemoteFileItem) {
        isExtracting = true
        Task {
            do {
                try await SFTPFileManager.shared.extractArchive(
                    path: file.path,
                    serverId: serverId
                )
                await loadFiles()
            } catch {
                let msg = error.localizedDescription
                if let tool = detectMissingTool(from: msg, for: file.name) {
                    missingTool = tool
                    showMissingToolBanner = true
                } else {
                    errorMessage = "Extract failed: \(msg)"
                }
            }
            isExtracting = false
        }
    }
    
    /// Compress selected files into an archive
    func compressSelected(archiveName: String, format: SFTPFileManager.ArchiveFormat) {
        let selected = files.filter { selectedFiles.contains($0.id) }
        guard !selected.isEmpty else { return }
        
        let archivePath = currentPath.hasSuffix("/")
            ? "\(currentPath)\(archiveName).\(format.fileExtension)"
            : "\(currentPath)/\(archiveName).\(format.fileExtension)"
        
        isCompressing = true
        Task {
            do {
                try await SFTPFileManager.shared.compressFiles(
                    paths: selected.map { $0.path },
                    archivePath: archivePath,
                    format: format,
                    serverId: serverId
                )
                selectedFiles.removeAll()
                await loadFiles()
            } catch {
                let msg = error.localizedDescription
                if let tool = detectMissingTool(from: msg, for: format.rawValue) {
                    missingTool = tool
                    showMissingToolBanner = true
                } else {
                    errorMessage = "Compress failed: \(msg)"
                }
            }
            isCompressing = false
            showCompressSheet = false
        }
    }
    
    /// Check if a file is an archive
    func isArchiveFile(_ file: RemoteFileItem) -> Bool {
        SFTPFileManager.isArchive(file.path)
    }
    
    // MARK: - Missing Tool Detection
    
    /// Info about a missing tool needed for an operation
    struct MissingToolInfo {
        let toolName: String
        let packageName: String
        let description: String
        let icon: String
    }
    
    @Published var showMissingToolBanner = false
    @Published var missingTool: MissingToolInfo?
    @Published var isInstallingTool = false
    
    /// Detect which tool is missing from an error message
    private func detectMissingTool(from error: String, for fileName: String) -> MissingToolInfo? {
        let lower = error.lowercased()
        if lower.contains("zip: command not found") || lower.contains("zip: not found") {
            return MissingToolInfo(toolName: "zip", packageName: "zip", description: "Required to create ZIP archives", icon: "archivebox")
        }
        if lower.contains("unzip: command not found") || lower.contains("unzip: not found") {
            return MissingToolInfo(toolName: "unzip", packageName: "unzip", description: "Required to extract ZIP archives", icon: "archivebox")
        }
        if lower.contains("unrar: command not found") || lower.contains("unrar: not found") {
            return MissingToolInfo(toolName: "unrar", packageName: "unrar", description: "Required to extract RAR archives", icon: "archivebox")
        }
        if lower.contains("7z: command not found") || lower.contains("7z: not found") {
            return MissingToolInfo(toolName: "7z", packageName: "p7zip-full", description: "Required to extract 7-Zip archives", icon: "archivebox")
        }
        if lower.contains("tar: command not found") || lower.contains("tar: not found") {
            return MissingToolInfo(toolName: "tar", packageName: "tar", description: "Required for TAR archives", icon: "archivebox")
        }
        // Generic "command not found"
        if lower.contains("command not found") || lower.contains("not found") {
            let toolName = fileName.lowercased().hasSuffix(".zip") ? "zip" : "archive-tools"
            return MissingToolInfo(toolName: toolName, packageName: toolName, description: "Required tool is not installed", icon: "exclamationmark.triangle")
        }
        return nil
    }
    
    /// Install a missing tool on the server
    func installMissingTool() {
        guard let tool = missingTool else { return }
        isInstallingTool = true
        
        Task {
            do {
                // Detect package manager and install
                let installCmd = """
                if command -v apt-get >/dev/null 2>&1; then
                    apt-get update -qq && apt-get install -y -qq \(ShellSanitizer.sanitizeIdentifier(tool.packageName))
                elif command -v yum >/dev/null 2>&1; then
                    yum install -y -q \(ShellSanitizer.sanitizeIdentifier(tool.packageName))
                elif command -v dnf >/dev/null 2>&1; then
                    dnf install -y -q \(ShellSanitizer.sanitizeIdentifier(tool.packageName))
                elif command -v apk >/dev/null 2>&1; then
                    apk add --quiet \(ShellSanitizer.sanitizeIdentifier(tool.packageName))
                else
                    echo "NO_PKG_MANAGER" && exit 1
                fi
                """
                
                let result = try await SSHService.shared.execute(installCmd, serverId: serverId)
                
                if result.isSuccess {
                    // Verify installation
                    let verify = try await SSHService.shared.execute(
                        "command -v \(ShellSanitizer.sanitizeIdentifier(tool.toolName))",
                        serverId: serverId
                    )
                    if verify.isSuccess {
                        showMissingToolBanner = false
                        missingTool = nil
                    } else {
                        errorMessage = "Installation completed but \(tool.toolName) still not found"
                    }
                } else {
                    errorMessage = "Failed to install \(tool.toolName): \(result.stderr)"
                }
            } catch {
                errorMessage = "Install failed: \(error.localizedDescription)"
            }
            isInstallingTool = false
        }
    }
    
    // MARK: - Symlink
    
    func createSymlink(target: RemoteFileItem, linkName: String) {
        let linkPath = currentPath.hasSuffix("/")
            ? "\(currentPath)\(linkName)"
            : "\(currentPath)/\(linkName)"
        
        Task {
            do {
                try await SFTPFileManager.shared.createSymlink(
                    target: target.path,
                    linkPath: linkPath,
                    serverId: serverId
                )
                await loadFiles()
            } catch {
                errorMessage = "Symlink failed: \(error.localizedDescription)"
            }
            showSymlinkSheet = false
        }
    }
    
    // MARK: - Change Owner
    
    func changeOwner(file: RemoteFileItem, owner: String, group: String, recursive: Bool) {
        Task {
            do {
                if recursive {
                    // Use SSH directly for recursive chown
                    let safePath = ShellSanitizer.escapePath(file.path)
                    _ = try await SSHService.shared.execute(
                        "chown -R \(ShellSanitizer.sanitizeIdentifier(owner)):\(ShellSanitizer.sanitizeIdentifier(group)) \(safePath)",
                        serverId: serverId
                    )
                } else {
                    try await SFTPFileManager.shared.changeOwner(
                        path: file.path,
                        owner: owner,
                        group: group,
                        serverId: serverId
                    )
                }
                await loadFiles()
            } catch {
                errorMessage = "chown failed: \(error.localizedDescription)"
            }
            showChangeOwnerSheet = false
        }
    }
    
    // MARK: - Go To Path
    
    func goToPath(_ path: String) {
        let trimmed = path.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let normalized = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        showGoToPath = false
        navigateTo(normalized)
    }
    
    // MARK: - File Upload
    
    func uploadFiles(urls: [URL]) {
        for url in urls {
            let fileName = url.lastPathComponent
            let remotePath = currentPath.hasSuffix("/") ? "\(currentPath)\(fileName)" : "\(currentPath)/\(fileName)"
            
            let fileSize: Int64
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                fileSize = size
            } else {
                fileSize = 0
            }
            
            let transfer = FileTransferProgress(
                fileName: fileName,
                totalBytes: fileSize,
                state: .pending
            )
            
            let transferId = transfer.id
            activeTransfers.append(transfer)
            
            Task {
                do {
                    updateTransferState(id: transferId, state: .transferring)
                    
                    try await SFTPFileManager.shared.uploadFile(
                        localURL: url,
                        remotePath: remotePath,
                        serverId: serverId,
                        onProgress: { transferred, total in
                            Task { @MainActor [weak self] in
                                self?.updateTransferProgress(id: transferId, bytesTransferred: transferred)
                            }
                        }
                    )
                    
                    updateTransferState(id: transferId, state: .completed)
                    await loadFiles()
                    
                    // Auto-remove completed transfers after 3 seconds
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    removeTransfer(id: transferId)
                } catch {
                    updateTransferState(id: transferId, state: .failed, error: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - File Download
    
    func downloadFile(_ file: RemoteFileItem) {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.name
        panel.canCreateDirectories = true
        
        panel.begin { [weak self] response in
            guard response == .OK, let localURL = panel.url, let self = self else { return }
            
            let transfer = FileTransferProgress(
                fileName: file.name,
                totalBytes: file.size,
                state: .pending
            )
            
            let transferId = transfer.id
            
            Task { @MainActor in
                self.activeTransfers.append(transfer)
                self.updateTransferState(id: transferId, state: .transferring)
                
                do {
                    try await SFTPFileManager.shared.downloadFile(
                        remotePath: file.path,
                        localURL: localURL,
                        serverId: self.serverId,
                        onProgress: { transferred, total in
                            Task { @MainActor [weak self] in
                                self?.updateTransferProgress(id: transferId, bytesTransferred: transferred)
                            }
                        }
                    )
                    
                    self.updateTransferState(id: transferId, state: .completed)
                    
                    // Auto-remove after 3 seconds
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    self.removeTransfer(id: transferId)
                } catch {
                    self.updateTransferState(id: transferId, state: .failed, error: error.localizedDescription)
                }
            }
        }
        #endif
    }
    
    // MARK: - Search
    
    func performSearch(_ query: String) {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        searchTask = Task {
            // Debounce: 300ms
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            isSearching = true
            
            do {
                searchResults = try await SFTPFileManager.shared.searchFiles(
                    query: query,
                    path: currentPath,
                    serverId: serverId
                )
            } catch {
                searchResults = []
            }
            
            isSearching = false
        }
    }
    
    // MARK: - Transfer Helpers
    
    private func updateTransferProgress(id: String, bytesTransferred: Int64) {
        if let index = activeTransfers.firstIndex(where: { $0.id == id }) {
            activeTransfers[index].bytesTransferred = bytesTransferred
        }
    }
    
    private func updateTransferState(id: String, state: FileTransferProgress.TransferState, error: String? = nil) {
        if let index = activeTransfers.firstIndex(where: { $0.id == id }) {
            activeTransfers[index].state = state
            activeTransfers[index].error = error
        }
    }
    
    private func removeTransfer(id: String) {
        activeTransfers.removeAll { $0.id == id }
    }
    
    func cancelTransfer(_ transfer: FileTransferProgress) {
        updateTransferState(id: transfer.id, state: .cancelled)
        // Note: actual cancellation would require task tracking
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.removeTransfer(id: transfer.id)
        }
    }
}
