//
//  FilesView.swift
//  AevonX
//
//  Main hub for the file manager module
//  Orchestrates all sub-components: TabBar, Toolbar, Sidebar, FileList, Editor
//  Follows the Security module pattern (thin hub → focused components)
//

import SwiftUI
import AevonXCoreBridge
import UniformTypeIdentifiers

// MARK: - Files View (Main Hub)

struct FilesView: View {
    let serverId: String
    let connectionViewModel: ServerConnectionViewModel
    
    @ObservedObject private var viewModel: FileManagerViewModel
    
    // Custom context menu state
    @State private var showCustomMenu = false
    @State private var customMenuFile: RemoteFileItem?
    @State private var customMenuPosition: CGPoint = .zero
    
    init(serverId: String, connectionViewModel: ServerConnectionViewModel) {
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
        self.viewModel = connectionViewModel.fileManagerViewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            FileTabBar(viewModel: viewModel)
            
            Divider().background(Color.axBorder)
            
            // Toolbar
            if !viewModel.isEditorOpen {
                FileToolbar(viewModel: viewModel)
                Divider().background(Color.axBorder)
                
                // Missing tool banner
                if viewModel.showMissingToolBanner, let tool = viewModel.missingTool {
                    MissingToolBanner(tool: tool, viewModel: viewModel)
                }
            }
            
            // Main Content — switch between file browser and editor
            if viewModel.isEditorOpen {
                editorView
            } else {
                browserView
            }
            
            // Transfer Progress Bar
            if !viewModel.activeTransfers.isEmpty {
                Divider().background(Color.axBorder)
                FileTransferPanel(viewModel: viewModel)
            }
        }
        .background(Color.axBackground)
        .overlay { contextMenuOverlay }
        .onAppear { Task { await viewModel.initialLoad() } }
        .sheet(isPresented: $viewModel.isPermissionsEditorOpen) {
            FilePermissionsEditorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showNewFolderSheet) {
            NewFolderSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showNewFileSheet) {
            NewFileSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showDownloadURLSheet) {
            DownloadFromURLSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showCompressSheet) {
            CompressSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showSymlinkSheet) {
            SymlinkSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showChangeOwnerSheet) {
            ChangeOwnerSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showFileInfoSheet) {
            if let file = viewModel.fileInfoFile {
                FileInfoSheet(file: file, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showContentSearch) {
            FileContentSearchSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showBatchPermissions) {
            BatchPermissionsSheet(viewModel: viewModel)
        }
        .alert("Delete", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { viewModel.deleteConfirmed() }
        } message: {
            let dangerLevel = viewModel.filesToDelete.reduce(DangerousPathGuard.DangerLevel.safe) { highest, file in
                let level = DangerousPathGuard.isDangerousToDelete(file.path)
                return level.isDangerous ? level : highest
            }
            if dangerLevel.isDangerous {
                Text("\(dangerLevel.message)\n\nDelete \(viewModel.filesToDelete.count) item(s)? This cannot be undone.")
            } else {
                Text("Delete \(viewModel.filesToDelete.count) item(s)? This cannot be undone.")
            }
        }
        .alert("Go to Path", isPresented: $viewModel.showGoToPath) {
            TextField("/var/www", text: $viewModel.goToPathText)
            Button("Cancel", role: .cancel) {}
            Button("Go") { viewModel.goToPath(viewModel.goToPathText) }
        }
        .onChange(of: viewModel.searchText) { _, newValue in
            viewModel.performSearch(newValue)
        }
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers, viewModel: viewModel)
            return true
        }
    }
    
    // MARK: - Browser View
    
    private var browserView: some View {
        HStack(spacing: 0) {
            // Sidebar
            FileSidebar(viewModel: viewModel)
                .frame(width: 190)
            
            Divider().background(Color.axBorder)
            
            // File List
            VStack(spacing: 0) {
                FileListHeader()
                Divider().background(Color.axBorder.opacity(0.5))
                FileListContent(viewModel: viewModel) { file, position in
                    customMenuFile = file
                    customMenuPosition = position
                    showCustomMenu = true
                }
                FileStatusBar(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Editor View
    
    private var editorView: some View {
        VStack(spacing: 0) {
            FileInlineEditorHeader(viewModel: viewModel)
            Divider().background(Color.axBorder)
            
            // Find & Replace bar
            if viewModel.showFindReplace {
                FindReplaceBar(viewModel: viewModel)
            }
            
            // CRITICAL: frame + clipped prevent NSScrollView from expanding beyond parent
            ZStack {
                if viewModel.isLoadingFile {
                    VStack(spacing: AXSpacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                        Text("Loading file...")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#121212").opacity(0.9))
                } else {
                    CodeEditorView(
                        text: $viewModel.editorContent,
                        language: viewModel.editorFile?.language ?? .plainText,
                        isReadOnly: false
                    )
                    // KEY FIX: .id forces SwiftUI to destroy + recreate the
                    // NSViewRepresentable for each new file. makeNSView is then
                    // called with a properly-sized frame, so text is never
                    // laid out in a zero-width container.
                    .id(viewModel.editorFile?.path ?? "")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }
    
    // MARK: - Context Menu Overlay
    
    @ViewBuilder
    private var contextMenuOverlay: some View {
        if showCustomMenu, let file = customMenuFile {
            GeometryReader { geo in
                let menuW: CGFloat = 230
                let menuH: CGFloat = 440
                let x = min(customMenuPosition.x, geo.size.width - menuW - 10)
                let y = min(customMenuPosition.y, geo.size.height - menuH - 10)
                
                ZStack(alignment: .topLeading) {
                    Color.black.opacity(0.01)
                        .onTapGesture { showCustomMenu = false }
                    
                    CustomContextMenuView(file: file, viewModel: viewModel) {
                        showCustomMenu = false
                    }
                    .frame(width: menuW)
                    .offset(x: x, y: y)
                }
            }
            .transition(.opacity)
            .animation(.easeOut(duration: 0.12), value: showCustomMenu)
        }
    }
}
