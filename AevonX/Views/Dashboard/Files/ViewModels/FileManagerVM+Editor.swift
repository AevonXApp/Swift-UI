//
//  FileManagerVM+Editor.swift
//  AevonX
//
//  Extension: File editor — open, save, close
//  Permissions editor — open, save
//

import SwiftUI
import AevonXCoreBridge

// MARK: - File Editor

extension FileManagerViewModel {

    /// Open a file in the inline editor.
    /// Reads content first, then shows the editor — no flash/empty screen.
    func openFileEditor(_ file: RemoteFileItem) {
        // Reset previous state
        editorFile = nil
        editorContent = ""
        editorOriginalContent = ""
        isEditorOpen = false
        isLoadingFile = true

        Task {
            do {
                let content = try await SFTPService.shared.readFile(
                    path: file.path,
                    serverId: serverId
                )
                // Content is ready — now reveal the editor.
                // SwiftUI will create a fresh CodeEditorView (via .id(file.path))
                // with correct frame geometry and text set in makeNSView.
                editorFile = file
                editorContent = content
                editorOriginalContent = content
                isEditorOpen = true
            } catch {
                errorMessage = "Failed to open \(file.name): \(error.localizedDescription)"
            }
            isLoadingFile = false
        }
    }

    /// Save current editor content back to the remote server.
    func saveFile() {
        guard let file = editorFile else { return }
        isSavingFile = true

        Task {
            do {
                try await SFTPService.shared.writeFile(
                    path: file.path,
                    content: editorContent,
                    serverId: serverId
                )
                editorOriginalContent = editorContent
            } catch {
                errorMessage = "Failed to save \(file.name): \(error.localizedDescription)"
            }
            isSavingFile = false
        }
    }

    /// Close the editor and clear all editor state.
    func closeEditor() {
        isEditorOpen = false
        editorFile = nil
        editorContent = ""
        editorOriginalContent = ""
        showFindReplace = false
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
                try await SFTPService.shared.changePermissions(
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
}
