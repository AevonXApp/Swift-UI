//
//  FileManagerVM+Navigation.swift
//  AevonX
//
//  Extension: Tab management, navigation, session persistence, initial load
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Navigation & Tab Management

extension FileManagerViewModel {
    
    // MARK: - Session Persistence
    
    var sessionKey: String { "fm_session_\(serverId)" }
    
    /// Save current tabs + settings to UserDefaults
    func saveSession() {
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
    func restoreSession() {
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
            files = try await SFTPService.shared.listDirectory(
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
    
    func initialLoad() async {
        // Load quick access paths
        quickAccessPaths = await SFTPService.shared.getQuickAccessPaths(serverId: serverId)
        
        // Load favorites
        favorites = FavoritesManager.shared.getFavorites(serverId: serverId)
        
        // Only set home directory on first load
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
            if let usage = try? await SFTPService.shared.getDiskUsage(path: currentPath, serverId: serverId) {
                diskUsage = usage
            }
        }
    }
    
    // MARK: - Favorites
    
    func toggleFavorite(path: String) {
        FavoritesManager.shared.toggleFavorite(path: path, serverId: serverId)
        favorites = FavoritesManager.shared.getFavorites(serverId: serverId)
    }
    
    func isPathFavorite(_ path: String) -> Bool {
        FavoritesManager.shared.isFavorite(path: path, serverId: serverId)
    }
    
    // MARK: - File Info
    
    func showFileInfo(_ file: RemoteFileItem) {
        fileInfoFile = file
        showFileInfoSheet = true
    }
    
    // MARK: - Selection
    
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
    
    func selectAll() {
        selectedFiles = Set(displayFiles.map { $0.id })
        lastSelectedFile = displayFiles.last
    }
    
    func deselectAll() {
        selectedFiles.removeAll()
        lastSelectedFile = nil
    }
    
    // MARK: - Go To Path
    
    func goToPath(_ path: String) {
        let trimmed = path.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let normalized = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        showGoToPath = false
        navigateTo(normalized)
    }
}
