//
//  FileContextMenu.swift
//  AevonX
//
//  Custom context menu view with hover effects
//  Displayed on right-click of a file row
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Custom Context Menu

struct CustomContextMenuView: View {
    let file: RemoteFileItem
    @ObservedObject var viewModel: FileManagerViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            // Header — file name with icon
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(file.isDirectory ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Image(systemName: file.iconName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(file.isDirectory ? .blue : .axTextSecondary)
                }
                Text(file.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            menuDivider
            
            // Open / Edit section
            if file.isDirectory {
                menuItem("Open", icon: "folder.fill", color: .blue) {
                    viewModel.navigateTo(file.path)
                }
                menuItem("Open in New Tab", icon: "rectangle.stack.fill.badge.plus", color: .blue) {
                    viewModel.createTab(path: file.path)
                }
                menuItem("Open Terminal Here", icon: "terminal.fill", color: .green) {
                    TerminalLaunchHelper.openTerminal(at: file.path, serverId: viewModel.serverId)
                }
            } else {
                menuItem(L10n.Button.edit, icon: "pencil.circle.fill", color: .blue) {
                    viewModel.openFileEditor(file)
                }
                menuItem(L10n.Files.download, icon: "arrow.down.circle.fill", color: .cyan) {
                    viewModel.downloadFile(file)
                }
            }
            
            // Extract
            if !file.isDirectory && viewModel.isArchiveFile(file) {
                menuDivider
                menuItem("Extract Here", icon: "archivebox.circle.fill", color: .purple) {
                    viewModel.extractArchive(file)
                }
            }
            
            menuDivider
            
            // Clipboard
            menuItem(L10n.Button.copy, icon: "doc.on.doc.fill", color: .blue) {
                viewModel.selectSingleFile(file)
                viewModel.copyFiles()
            }
            menuItem("Cut", icon: "scissors.circle.fill", color: .orange) {
                viewModel.selectSingleFile(file)
                viewModel.cutFiles()
            }
            if viewModel.hasClipboard {
                menuItem("Paste", icon: "doc.on.clipboard.fill", color: .green) {
                    viewModel.pasteFiles()
                }
            }
            
            menuDivider
            
            // File ops
            menuItem(L10n.Files.rename, icon: "character.cursor.ibeam", color: .yellow) {
                viewModel.startRename(file)
            }
            menuItem("Duplicate", icon: "plus.square.on.square.fill", color: .yellow) {
                viewModel.duplicateFile(file)
            }
            menuItem("Create Symlink", icon: "link.circle.fill", color: .mint) {
                viewModel.symlinkSourceFile = file
                viewModel.showSymlinkSheet = true
            }
            menuItem(L10n.Files.copyPath, icon: "text.badge.checkmark", color: .gray) {
                viewModel.copyPath(file)
            }
            
            menuDivider
            
            // Permissions
            menuItem("Change Owner", icon: "person.2.circle.fill", color: .indigo) {
                viewModel.changeOwnerFile = file
                viewModel.showChangeOwnerSheet = true
            }
            menuItem("Permissions (\(file.permissions.numericString))", icon: "lock.shield.fill", color: .indigo) {
                viewModel.openPermissionsEditor(file)
            }
            
            menuDivider
            
            // Info & Favorites
            menuItem("File Info", icon: "info.circle.fill", color: .cyan) {
                viewModel.showFileInfo(file)
            }
            menuItem(
                viewModel.isPathFavorite(file.path) ? "Remove Favorite" : "Add to Favorites",
                icon: viewModel.isPathFavorite(file.path) ? "star.slash.fill" : "star.fill",
                color: .yellow
            ) {
                viewModel.toggleFavorite(path: file.path)
            }
            if file.isDirectory {
                menuItem("Search Contents", icon: "doc.text.magnifyingglass", color: .teal) {
                    viewModel.navigateTo(file.path)
                    viewModel.showContentSearch = true
                }
            }
            
            menuDivider
            
            // Delete
            menuItem(L10n.Button.delete, icon: "trash.fill", color: .red, isDestructive: true) {
                viewModel.confirmDelete([file])
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.14))
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func menuItem(_ title: String, icon: String, color: Color, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            onDismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                action()
            }
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 24, height: 24)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isDestructive ? .red : .white.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(ContextMenuItemStyle())
    }
    
    private var menuDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
    }
}

// MARK: - Context Menu Item Hover Style

struct ContextMenuItemStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
                    .padding(.horizontal, 4)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
