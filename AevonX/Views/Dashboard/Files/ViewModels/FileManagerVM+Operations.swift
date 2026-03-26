//
//  FileManagerVM+Operations.swift
//  AevonX
//
//  Extension: CRUD operations, clipboard, archive, symlink, chown, missing tool
//

import SwiftUI
import AevonXCoreBridge

// MARK: - File Operations (CRUD)

extension FileManagerViewModel {
    
    func createFolder(name: String) {
        let path = currentPath.hasSuffix("/") ? "\(currentPath)\(name)" : "\(currentPath)/\(name)"
        
        Task {
            do {
                try await SFTPService.shared.createDirectory(path: path, serverId: serverId)
                await loadFiles()
            } catch {
                errorMessage = "Failed to create folder: \(error.localizedDescription)"
            }
        }
    }
    
    func createFile(name: String) {
        let path = currentPath.hasSuffix("/") ? "\(currentPath)\(name)" : "\(currentPath)/\(name)"
        
        Task {
            do {
                try await SFTPService.shared.createFile(path: path, serverId: serverId)
                await loadFiles()
            } catch {
                errorMessage = "Failed to create file: \(error.localizedDescription)"
            }
        }
    }
    
    func confirmDelete(_ files: [RemoteFileItem]) {
        let hasFiles = files.contains { !$0.isDirectory }
        let hasFolders = files.contains { $0.isDirectory }
        let fileKey = hasFiles ? SettingsKey.confirmDeleteFile2 : SettingsKey.confirmDeleteFolder
        let shouldConfirm = hasFolders
            ? AppSettingsManager.shared.shouldConfirm(for: SettingsKey.confirmDeleteFolder)
            : AppSettingsManager.shared.shouldConfirm(for: fileKey)

        if shouldConfirm {
            filesToDelete = files
            showDeleteConfirmation = true
        } else {
            filesToDelete = files
            deleteConfirmed()
        }
    }
    
    func deleteConfirmed() {
        let toDelete = filesToDelete
        showDeleteConfirmation = false
        filesToDelete = []
        
        Task {
            for file in toDelete {
                do {
                    try await SFTPService.shared.deleteItem(path: file.path, serverId: serverId)
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
                try await SFTPService.shared.renameItem(from: file.path, to: newPath, serverId: serverId)
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
                try await SFTPService.shared.copyItem(from: file.path, to: newPath, serverId: serverId)
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
    
    // MARK: - Clipboard (Copy/Cut/Paste)
    
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
                        try await SFTPService.shared.renameItem(from: file.path, to: destPath, serverId: serverId)
                    } else {
                        try await SFTPService.shared.copyItem(from: file.path, to: destPath, serverId: serverId)
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
    
    // MARK: - Archive Operations
    
    func extractArchive(_ file: RemoteFileItem) {
        isExtracting = true
        Task {
            do {
                try await SFTPService.shared.extractArchive(
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
    
    func compressSelected(archiveName: String, format: ArchiveFormat) {
        let selected = files.filter { selectedFiles.contains($0.id) }
        guard !selected.isEmpty else { return }
        
        let archivePath = currentPath.hasSuffix("/")
            ? "\(currentPath)\(archiveName).\(format.fileExtension)"
            : "\(currentPath)/\(archiveName).\(format.fileExtension)"
        
        isCompressing = true
        Task {
            do {
                try await SFTPService.shared.compressFiles(
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
    
    func isArchiveFile(_ file: RemoteFileItem) -> Bool {
        SFTPService.isArchive(file.path)
    }
    
    // MARK: - Symlink
    
    func createSymlink(target: RemoteFileItem, linkName: String) {
        let linkPath = currentPath.hasSuffix("/")
            ? "\(currentPath)\(linkName)"
            : "\(currentPath)/\(linkName)"
        
        Task {
            do {
                try await SFTPService.shared.createSymlink(
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
                    let safePath = ShellSanitizer.escapePath(file.path)
                    let chownCmd = "chown -R \(ShellSanitizer.sanitizeIdentifier(owner)):\(ShellSanitizer.sanitizeIdentifier(group)) \(safePath)"
                    let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: chownCmd)
                    let _ = SSHResult.parse(json)
                } else {
                    try await SFTPService.shared.changeOwner(
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
    
    // MARK: - Missing Tool Detection
    
    func detectMissingTool(from error: String, for fileName: String) -> MissingToolInfo? {
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
        if lower.contains("command not found") || lower.contains("not found") {
            let toolName = fileName.lowercased().hasSuffix(".zip") ? "zip" : "archive-tools"
            return MissingToolInfo(toolName: toolName, packageName: toolName, description: "Required tool is not installed", icon: "exclamationmark.triangle")
        }
        return nil
    }
    
    func installMissingTool() {
        guard let tool = missingTool else { return }
        isInstallingTool = true
        
        Task {
            do {
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
                
                let installJson = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: installCmd)
                let result = SSHResult.parse(installJson)
                
                if result.isSuccess {
                    let verifyJson = await SSHBridge.shared.executeAsyncJSON(
                        serverID: serverId,
                        command: "command -v \(ShellSanitizer.sanitizeIdentifier(tool.toolName))"
                    )
                    let verify = SSHResult.parse(verifyJson)
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
}
