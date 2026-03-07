//
//  FileKeyboardShortcuts.swift
//  AevonX
//
//  Keyboard shortcuts for the file manager
//  ⌘C=Copy, ⌘X=Cut, ⌘V=Paste, ⌘A=SelectAll, ⌘⌫=Delete
//  ⌘N=NewFile, ⌘⇧N=NewFolder, ⌘G=GoToPath, ⌘R=Refresh
//  ⌘F=Search, ⌘S=Save (in editor), ⌘W=CloseEditor
//

import SwiftUI
import AevonXCore

// MARK: - Keyboard Shortcuts Modifier

struct FileKeyboardShortcuts: ViewModifier {
    @ObservedObject var viewModel: FileManagerViewModel
    
    func body(content: Content) -> some View {
        content
            // Copy
            .keyboardShortcut("c", modifiers: [.command]) {
                viewModel.copyFiles()
            }
            // Cut
            .keyboardShortcut("x", modifiers: [.command]) {
                viewModel.cutFiles()
            }
            // Paste
            .keyboardShortcut("v", modifiers: [.command]) {
                viewModel.pasteFiles()
            }
            // Select All
            .keyboardShortcut("a", modifiers: [.command]) {
                viewModel.selectAll()
            }
            // Delete
            .keyboardShortcut(.delete, modifiers: [.command]) {
                viewModel.deleteSelected()
            }
            // New File
            .keyboardShortcut("n", modifiers: [.command]) {
                viewModel.showNewFileSheet = true
            }
            // New Folder
            .keyboardShortcut("n", modifiers: [.command, .shift]) {
                viewModel.showNewFolderSheet = true
            }
            // Go To Path
            .keyboardShortcut("g", modifiers: [.command]) {
                viewModel.showGoToPath = true
            }
            // Refresh
            .keyboardShortcut("r", modifiers: [.command]) {
                viewModel.refresh()
            }
            // Save (editor)
            .keyboardShortcut("s", modifiers: [.command]) {
                if viewModel.isEditorOpen && viewModel.isEditorDirty {
                    viewModel.saveFile()
                }
            }
            // Close editor
            .keyboardShortcut("w", modifiers: [.command]) {
                if viewModel.isEditorOpen {
                    viewModel.closeEditor()
                }
            }
    }
}

// MARK: - Convenience extension for .keyboardShortcut with action

extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        self.background(
            Button("") { action() }
                .keyboardShortcut(key, modifiers: modifiers)
                .frame(width: 0, height: 0)
                .opacity(0)
        )
    }
}
