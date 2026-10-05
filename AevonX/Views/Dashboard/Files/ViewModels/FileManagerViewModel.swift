//
//  FileManagerViewModel.swift
//  AevonX
//
//  ViewModel for SSH File Manager — Properties & Computed Properties
//  All methods are in extension files under Files/ViewModels/:
//    - FileManagerVM+Navigation.swift  (tabs, nav, session, selection, load)
//    - FileManagerVM+Editor.swift      (open/save/close, permissions)
//    - FileManagerVM+Operations.swift  (CRUD, clipboard, archive, symlink, chown)
//    - FileManagerVM+Transfer.swift    (upload, download, search, progress)
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - File Manager ViewModel

@MainActor
final class FileManagerViewModel: ObservableObject {
    
    // MARK: - Properties
    
    let serverId: String
    
    // Tab Management
    @Published var tabs: [FileBrowserTabState] = [FileBrowserTabState()]
    @Published var activeTabIndex: Int = 0
    
    // File Listing
    @Published var files: [RemoteFileItem] = [] {
        didSet { filesVersion &+= 1 }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Selection
    @Published var selectedFiles: Set<String> = []
    @Published var lastSelectedFile: RemoteFileItem?
    
    // Search
    @Published var searchText = ""
    @Published var searchResults: [RemoteFileItem] = []
    @Published var isSearching = false
    var searchTask: Task<Void, Never>?
    
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
    
    // File Info
    @Published var showFileInfoSheet = false
    @Published var fileInfoFile: RemoteFileItem?
    
    // Content Search
    @Published var showContentSearch = false
    
    // Batch Permissions
    @Published var showBatchPermissions = false
    
    // Find & Replace
    @Published var showFindReplace = false
    
    // Favorites
    @Published var favorites: [FavoritePath] = []
    
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
    
    // Missing Tool
    @Published var showMissingToolBanner = false
    @Published var missingTool: MissingToolInfo?
    @Published var isInstallingTool = false

    // Git Integration
    @Published var isGitRepo = false
    @Published var gitInfo = GitRepoInfo()
    @Published var gitFileChanges: [GitFileChange] = []
    @Published var gitBranches: [GitBranch] = []
    @Published var gitCommits: [GitCommit] = []
    @Published var gitStashes: [GitStashEntry] = []
    @Published var gitTags: [GitTag] = []
    @Published var gitRemotes: [GitRemote] = []
    @Published var gitOperationRunning = false
    @Published var gitOperationMessage: String?
    @Published var showGitCommitSheet = false
    @Published var showGitBranchPopover = false
    @Published var showGitLogSheet = false
    @Published var showGitStashSheet = false
    @Published var showGitTagsSheet = false
    @Published var showGitRemotesSheet = false
    @Published var showGitDangerConfirm = false
    @Published var gitDangerAction: GitDangerAction?
    @Published var gitCommitMessage = ""
    @Published var gitNewBranchName = ""
    @Published var gitStashMessage = ""
    @Published var gitNewRemoteName = ""
    @Published var gitNewRemoteURL = ""

    enum GitDangerAction {
        case resetHard, discardAll, disconnect
    }

    // Internal State
    var hasLoadedOnce = false
    
    // Task tracking for real cancellation
    var transferTasks: [String: Task<Void, Never>] = [:]
    
    // MARK: - Missing Tool Info
    
    struct MissingToolInfo {
        let toolName: String
        let packageName: String
        let description: String
        let icon: String
    }
    
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
    
    /// Bumped whenever `files` changes; part of the `displayFiles` cache key.
    private var filesVersion = 0
    private var displayFilesCache: (key: DisplayFilesKey, files: [RemoteFileItem])?

    private struct DisplayFilesKey: Equatable {
        let filesVersion: Int
        let showHidden: Bool
        let search: String
        let sort: FileSortOrder
    }

    /// Filtered and sorted file list.
    ///
    /// Memoized: it is read several times per render (list, toolbar, status
    /// bar), and re-sorting a large directory on every read made each click
    /// or selection change slow. Recomputed only when its inputs change.
    var displayFiles: [RemoteFileItem] {
        let key = DisplayFilesKey(filesVersion: filesVersion, showHidden: showHiddenFiles, search: searchText, sort: sortOrder)
        if let cache = displayFilesCache, cache.key == key {
            return cache.files
        }

        var result = files
        
        if !showHiddenFiles {
            result = result.filter { !$0.isHidden }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        let sorted = sortOrder.sort(result)
        displayFilesCache = (key, sorted)
        return sorted
    }
    
    // MARK: - Initialization
    
    init(serverId: String) {
        self.serverId = serverId
        // Sync with app settings
        let appSettings = AppSettingsManager.shared
        self.showHiddenFiles = appSettings.showHiddenFiles
        self.sortOrder = Self.mapSortOrder(appSettings.fileSortOrder)
        restoreSession()
    }

    /// Maps settings string ("name", "date", "size", "type") to FileSortOrder
    private static func mapSortOrder(_ value: String) -> FileSortOrder {
        switch value {
        case "date": return .dateDescending
        case "size": return .sizeDescending
        case "type": return .typeAscending
        default: return .nameAscending
        }
    }
}
