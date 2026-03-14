//
//  FileToolbar.swift
//  AevonX
//
//  Main toolbar with navigation buttons, search, and action buttons
//

import SwiftUI
import AevonXCoreBridge

// MARK: - File Toolbar

struct FileToolbar: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Navigation buttons
            HStack(spacing: AXSpacing.xs) {
                toolbarButton(icon: "chevron.left", action: { viewModel.goBack() }, disabled: !viewModel.canGoBack)
                toolbarButton(icon: "chevron.right", action: { viewModel.goForward() }, disabled: !viewModel.canGoForward)
                toolbarButton(icon: "chevron.up", action: { viewModel.goToParent() })
            }
            
            // Breadcrumb
            FileBreadcrumb(viewModel: viewModel)
            
            Spacer()
            
            // Actions
            HStack(spacing: AXSpacing.xs) {
                // Search
                searchField
                
                Divider().frame(height: 20)
                
                toolbarButton(icon: "arrow.clockwise", action: { viewModel.refresh() }, tint: .axAccentBlue)
                toolbarButton(icon: "eye\(viewModel.showHiddenFiles ? "" : ".slash")", action: { viewModel.showHiddenFiles.toggle() }, tint: viewModel.showHiddenFiles ? .axAccentBlue : .axTextMuted)
                
                Divider().frame(height: 20)
                
                toolbarButton(icon: "doc.badge.plus", action: { viewModel.showNewFileSheet = true }, tint: .green)
                toolbarButton(icon: "folder.badge.plus", action: { viewModel.showNewFolderSheet = true }, tint: .green)
                toolbarButton(icon: "square.and.arrow.up", action: { showUploadPanel(viewModel: viewModel) }, tint: .cyan)
                toolbarButton(icon: "link.badge.plus", action: { viewModel.showDownloadURLSheet = true }, tint: .cyan)
                
                Divider().frame(height: 20)
                
                // Select All / Deselect
                if viewModel.selectedFiles.count == viewModel.displayFiles.count && !viewModel.displayFiles.isEmpty {
                    toolbarButton(icon: "xmark.circle.fill", action: { viewModel.deselectAll() }, tint: .orange)
                } else {
                    toolbarButton(icon: "checkmark.circle", action: { viewModel.selectAll() }, tint: .orange)
                }
                
                // Paste button (only shown when clipboard has content)
                if viewModel.hasClipboard {
                    toolbarButton(icon: "doc.on.clipboard.fill", action: { viewModel.pasteFiles() }, tint: .green)
                }
                
                if !viewModel.selectedFiles.isEmpty {
                    Divider().frame(height: 20)
                    toolbarButton(icon: "doc.on.doc", action: { viewModel.copyFiles() }, tint: .axAccentBlue)
                    toolbarButton(icon: "scissors", action: { viewModel.cutFiles() }, tint: .orange)
                    toolbarButton(icon: "archivebox.fill", action: { viewModel.showCompressSheet = true }, tint: .purple)
                    toolbarButton(icon: "trash.fill", action: { viewModel.deleteSelected() }, tint: .red)
                }
                
                Divider().frame(height: 20)
                toolbarButton(icon: "arrow.right.doc.on.clipboard", action: { viewModel.showGoToPath = true }, tint: .teal)
                
                // Progress indicator
                if viewModel.isExtracting || viewModel.isCompressing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                        .scaleEffect(0.7)
                }
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackgroundSecondary)
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(.axTextMuted)
            TextField("Search files...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 12))
                .frame(width: 140)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, 4)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.sm)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
    }
    
    // MARK: - Toolbar Button
    
    private func toolbarButton(icon: String, action: @escaping () -> Void, disabled: Bool = false, tint: Color = .axTextSecondary) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(disabled ? .axTextMuted.opacity(0.3) : tint)
                .frame(width: 30, height: 30)
                .background(Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
        .help(icon.replacingOccurrences(of: ".", with: " "))
    }
}
