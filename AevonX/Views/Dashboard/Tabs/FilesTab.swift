//
//  FilesTab.swift
//  AevonX
//
//  SSH-powered file browser with real-time file management
//  Multi-tab navigation, breadcrumbs, drag-drop upload, context menus
//

import SwiftUI
import AevonXCore
import UniformTypeIdentifiers

// MARK: - Files Tab View

struct FilesTab: View {
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
            fileTabBar
            
            Divider().background(Color.axBorder)
            
            // Toolbar
            if !viewModel.isEditorOpen {
                fileToolbar
                Divider().background(Color.axBorder)
                
                // Missing Tool Banner
                if viewModel.showMissingToolBanner, let tool = viewModel.missingTool {
                    missingToolBanner(tool)
                }
            }
            
            // Main Content - switch between file browser and editor
            if viewModel.isEditorOpen {
                // Inline File Editor
                inlineEditorHeader
                Divider().background(Color.axBorder)
                
                ZStack {
                    Color(nsColor: AtomOneDark.background)
                    
                    if viewModel.isLoadingFile {
                        VStack(spacing: AXSpacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                            Text("Loading file...")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    } else {
                        SimpleCodeEditor(
                            text: $viewModel.editorContent,
                            language: viewModel.editorFile?.language ?? .plainText
                        )
                    }
                }
            } else {
                HStack(spacing: 0) {
                    // Sidebar
                    fileSidebar
                        .frame(width: 190)
                    
                    Divider().background(Color.axBorder)
                    
                    // File List Area
                    VStack(spacing: 0) {
                        fileListHeader
                        Divider().background(Color.axBorder)
                        fileListContent
                        Divider().background(Color.axBorder)
                        fileStatusBar
                    }
                }
            }
            
            // Transfer Progress Bar
            if !viewModel.activeTransfers.isEmpty {
                Divider().background(Color.axBorder)
                transferProgressBar
            }
        }
        .background(Color.axBackground)
        .overlay {
            // Custom context menu overlay
            if showCustomMenu, let file = customMenuFile {
                GeometryReader { geo in
                    let menuW: CGFloat = 230
                    let menuH: CGFloat = file.isDirectory ? 480 : (viewModel.isArchiveFile(file) ? 530 : 480)
                    let x = min(max(customMenuPosition.x, 0), geo.size.width - menuW)
                    let y = min(max(customMenuPosition.y, 0), geo.size.height - menuH)
                    
                    ZStack(alignment: .topLeading) {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                            .onTapGesture { withAnimation(.easeOut(duration: 0.12)) { showCustomMenu = false } }
                        
                        CustomContextMenuView(
                            file: file,
                            viewModel: viewModel,
                            onDismiss: { withAnimation(.easeOut(duration: 0.12)) { showCustomMenu = false } }
                        )
                        .frame(width: menuW)
                        .offset(x: x, y: y)
                    }
                }
                .transition(.opacity)
                .animation(.easeOut(duration: 0.12), value: showCustomMenu)
            }
        }
        .onAppear { Task { await viewModel.initialLoad() } }
        .sheet(isPresented: $viewModel.isPermissionsEditorOpen) {
            FilePermissionsEditorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showNewFolderSheet) {
            newFolderSheet
        }
        .alert("Delete Items", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { viewModel.deleteConfirmed() }
        } message: {
            Text("Are you sure you want to delete \(viewModel.filesToDelete.count) item(s)? This cannot be undone.")
        }
        .alert("Rename", isPresented: $viewModel.isRenaming) {
            TextField("Name", text: $viewModel.renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") { viewModel.confirmRename() }
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
        .alert("Go to Path", isPresented: $viewModel.showGoToPath) {
            TextField("/var/www", text: $viewModel.goToPathText)
            Button("Cancel", role: .cancel) {}
            Button("Go") { viewModel.goToPath(viewModel.goToPathText) }
        } message: {
            Text("Enter the full path to navigate to")
        }
        .onChange(of: viewModel.searchText) { _, newValue in
            viewModel.performSearch(newValue)
        }
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers)
            return true
        }
    }
    
    // MARK: - Tab Bar
    
    private var fileTabBar: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(viewModel.tabs.enumerated()), id: \.element.id) { index, tab in
                        tabItem(tab, index: index)
                    }
                }
                .padding(.horizontal, 6)
            }
            
            Spacer()
            
            // New Tab Button — prominent green circle
            Button(action: { viewModel.createTab() }) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 10)
            .help("New Tab")
        }
        .frame(height: 36)
        .background(Color.axBackgroundSecondary)
    }
    
    private func tabItem(_ tab: FileBrowserTabState, index: Int) -> some View {
        let isActive = index == viewModel.activeTabIndex
        
        return HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .font(.system(size: 11))
                .foregroundColor(isActive ? .blue : .axTextMuted)
            
            Text(tab.title)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .lineLimit(1)
            
            if viewModel.tabs.count > 1 {
                Button(action: { viewModel.closeTab(at: index) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .foregroundColor(isActive ? .white : .axTextSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.axAccentBlue.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.axAccentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { viewModel.switchToTab(index) }
    }
    
    // MARK: - Toolbar
    
    private var fileToolbar: some View {
        HStack(spacing: AXSpacing.md) {
            // Navigation buttons
            HStack(spacing: AXSpacing.xs) {
                toolbarButton(icon: "chevron.left", action: { viewModel.goBack() }, disabled: !viewModel.canGoBack)
                toolbarButton(icon: "chevron.right", action: { viewModel.goForward() }, disabled: !viewModel.canGoForward)
                toolbarButton(icon: "chevron.up", action: { viewModel.goToParent() })
            }
            
            // Breadcrumb
            breadcrumbBar
            
            Spacer()
            
            // Actions
            HStack(spacing: AXSpacing.xs) {
                // Search
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
                
                Divider().frame(height: 20)
                
                toolbarButton(icon: "arrow.clockwise", action: { viewModel.refresh() }, tint: .axAccentBlue)
                toolbarButton(icon: "eye\(viewModel.showHiddenFiles ? "" : ".slash")", action: { viewModel.showHiddenFiles.toggle() }, tint: viewModel.showHiddenFiles ? .axAccentBlue : .axTextMuted)
                
                Divider().frame(height: 20)
                
                toolbarButton(icon: "doc.badge.plus", action: { viewModel.showNewFileSheet = true }, tint: .green)
                toolbarButton(icon: "folder.badge.plus", action: { viewModel.showNewFolderSheet = true }, tint: .green)
                toolbarButton(icon: "square.and.arrow.up", action: { showUploadPanel() }, tint: .cyan)
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
    
    // MARK: - Missing Tool Banner
    
    private func missingToolBanner(_ tool: FileManagerViewModel.MissingToolInfo) -> some View {
        HStack(spacing: AXSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AXSpacing.xs) {
                    Text("\(tool.toolName)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("not installed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
                Text(tool.description)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextSecondary)
            }
            
            Spacer()
            
            // Install button
            Button(action: { viewModel.installMissingTool() }) {
                HStack(spacing: 4) {
                    if viewModel.isInstallingTool {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
                        Text("Installing...")
                            .font(.system(size: 11, weight: .semibold))
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                        Text("Install")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isInstallingTool)
            
            // Dismiss
            Button(action: {
                viewModel.showMissingToolBanner = false
                viewModel.missingTool = nil
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.axTextMuted)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, AXSpacing.sm)
        .padding(.top, AXSpacing.xs)
    }
    
    // MARK: - Breadcrumb
    
    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Root
                Button(action: { viewModel.navigateTo("/") }) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
                
                ForEach(Array(viewModel.pathComponents.enumerated()), id: \.offset) { index, component in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.axTextMuted)
                    
                    Button(action: { viewModel.navigateTo(component.path) }) {
                        Text(component.name)
                            .font(.system(size: 12, weight: index == viewModel.pathComponents.count - 1 ? .semibold : .regular))
                            .foregroundColor(index == viewModel.pathComponents.count - 1 ? .axTextPrimary : .axTextSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Sidebar
    
    private var fileSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("QUICK ACCESS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.md)
                .padding(.top, AXSpacing.md)
                .padding(.bottom, AXSpacing.sm)
            
            ForEach(viewModel.quickAccessPaths, id: \.path) { item in
                sidebarItem(icon: item.icon, title: item.title, path: item.path)
            }
            
            if !viewModel.quickAccessPaths.isEmpty {
                Divider()
                    .background(Color.axBorder)
                    .padding(.vertical, AXSpacing.sm)
            }
            
            // Sort options
            Text("SORT BY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.md)
                .padding(.bottom, AXSpacing.xs)
            
            Picker("Sort", selection: $viewModel.sortOrder) {
                ForEach(FileSortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .font(.system(size: 11))
            .padding(.horizontal, AXSpacing.sm)
            
            Spacer()
            
            // Disk usage
            if !viewModel.diskUsage.isEmpty {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Text("Used: \(viewModel.diskUsage)")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextTertiary)
                }
                .padding(AXSpacing.md)
            }
        }
        .background(Color.axSurface.opacity(0.4))
    }
    
    private func sidebarItem(icon: String, title: String, path: String) -> some View {
        let isActive = viewModel.currentPath == path
        
        return Button(action: { viewModel.navigateToQuickAccess(path) }) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? .axAccentBlue : .axTextMuted)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? .axTextPrimary : .axTextSecondary)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(isActive ? Color.axAccentBlue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - File List Header
    
    private var fileListHeader: some View {
        HStack(spacing: 0) {
            headerColumn("Name", width: nil, alignment: .leading)
            headerColumn("Size", width: 80, alignment: .trailing)
            headerColumn("Mode", width: 50, alignment: .center)
            headerColumn("Owner", width: 70, alignment: .center)
            headerColumn("Modified", width: 130, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axBackgroundSecondary)
    }
    
    private func headerColumn(_ title: String, width: CGFloat?, alignment: Alignment) -> some View {
        Group {
            if let w = width {
                Text(title)
                    .frame(width: w, alignment: alignment)
            } else {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(.axTextMuted)
    }
    
    // MARK: - File List Content
    
    private var fileListContent: some View {
        Group {
            if viewModel.isLoading && viewModel.files.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                    Text("Loading files...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.files.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28))
                        .foregroundColor(.axWarning)
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") { viewModel.refresh() }
                        .buttonStyle(AXSecondaryButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.displayFiles.isEmpty {
                AXEmptyState(
                    icon: "folder",
                    title: "Empty Directory",
                    description: "This directory has no files.",
                    actionLabel: "New File",
                    action: { viewModel.showNewFolderSheet = true }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.displayFiles) { file in
                            fileRow(file)
                            Divider().background(Color.axBorder.opacity(0.3))
                        }
                    }
                }
            }
        }
        .background(Color.axBackground)
    }
    
    // MARK: - File Row
    
    private func fileRow(_ file: RemoteFileItem) -> some View {
        let isSelected = viewModel.selectedFiles.contains(file.id)
        
        return HStack(spacing: 0) {
            // Selection checkbox
            Button(action: {
                if isSelected {
                    viewModel.selectedFiles.remove(file.id)
                } else {
                    viewModel.selectedFiles.insert(file.id)
                    viewModel.lastSelectedFile = file
                }
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted.opacity(0.4))
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 24)
            .padding(.trailing, 4)
            
            // Name column
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: file.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(file.isDirectory ? .axAccentBlue : fileColor(for: file))
                    .frame(width: 18)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(file.name)
                        .font(.system(size: 12, weight: file.isDirectory ? .medium : .regular))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    
                    if file.isSymlink, let target = file.symlinkTarget {
                        Text("→ \(target)")
                            .font(.system(size: 9))
                            .foregroundColor(.axTextTertiary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            
            // Size
            Text(file.formattedSize)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .frame(width: 80, alignment: .trailing)
            
            // Permissions — numeric
            Text(file.permissions.numericString)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(permissionColor(file.permissions))
                .frame(width: 50, alignment: .center)
            
            // Owner
            Text(file.owner)
                .font(.system(size: 11))
                .foregroundColor(.axTextSecondary)
                .frame(width: 70, alignment: .center)
                .lineLimit(1)
            
            // Modified date
            Text(formatDate(file.modifiedDate))
                .font(.system(size: 11))
                .foregroundColor(.axTextTertiary)
                .frame(width: 130, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(isSelected ? Color.axAccentBlue.opacity(0.12) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.selectSingleFile(file) }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { viewModel.handleFileDoubleTap(file) }
        )
        .overlay(
            RightClickHandler { position in
                customMenuFile = file
                customMenuPosition = position
                withAnimation(.easeOut(duration: 0.12)) {
                    showCustomMenu = true
                }
            }
        )
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func fileContextMenu(_ file: RemoteFileItem) -> some View {
        // Open / Edit section
        if file.isDirectory {
            Button { viewModel.navigateTo(file.path) } label: {
                Label("Open", systemImage: "folder.fill")
            }
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.blue)
            
            Button { viewModel.createTab(path: file.path) } label: {
                Label("Open in New Tab", systemImage: "plus.rectangle.fill.on.rectangle.fill")
            }
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.blue)
        } else {
            Button { viewModel.openFileEditor(file) } label: {
                Label("Edit", systemImage: "pencil.circle.fill")
            }
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.blue)
            
            Button { viewModel.downloadFile(file) } label: {
                Label("Download", systemImage: "arrow.down.circle.fill")
            }
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.cyan)
        }
        
        Divider()
        
        // Archive section
        if !file.isDirectory && viewModel.isArchiveFile(file) {
            Button {
                viewModel.extractArchive(file)
            } label: {
                Label("Extract Here", systemImage: "archivebox.circle.fill")
            }
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.purple)
            
            Divider()
        }
        
        // Clipboard section
        Button { 
            viewModel.selectSingleFile(file)
            viewModel.copyFiles()
        } label: {
            Label("Copy", systemImage: "doc.on.doc.fill")
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.blue)
        
        Button {
            viewModel.selectSingleFile(file)
            viewModel.cutFiles()
        } label: {
            Label("Cut", systemImage: "scissors.circle.fill")
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.orange)
        
        if viewModel.hasClipboard {
            Button { viewModel.pasteFiles() } label: {
                Label("Paste", systemImage: "doc.on.clipboard.fill")
            }
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.green)
        }
        
        Divider()
        
        // File operations section
        Button { viewModel.startRename(file) } label: {
            Label("Rename", systemImage: "character.cursor.ibeam")
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.yellow)
        
        Button { viewModel.duplicateFile(file) } label: {
            Label("Duplicate", systemImage: "plus.square.on.square.fill")
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.yellow)
        
        Button {
            viewModel.symlinkSourceFile = file
            viewModel.showSymlinkSheet = true
        } label: {
            Label("Create Symlink", systemImage: "link.circle.fill")
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.mint)
        
        Button { viewModel.copyPath(file) } label: {
            Label("Copy Path", systemImage: "text.badge.checkmark")
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.gray)
        
        Divider()
        
        // Permissions section
        Button {
            viewModel.changeOwnerFile = file
            viewModel.showChangeOwnerSheet = true
        } label: {
            Label("Change Owner", systemImage: "person.2.circle.fill")
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.indigo)
        
        Button { viewModel.openPermissionsEditor(file) } label: {
            Label("Permissions (\(file.permissions.numericString))", systemImage: "lock.shield.fill")
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.indigo)
        
        Divider()
        
        // Delete section
        Button(role: .destructive) { viewModel.confirmDelete([file]) } label: {
            Label("Delete", systemImage: "trash.fill")
        }
    }
    
    // MARK: - Status Bar
    
    private var fileStatusBar: some View {
        HStack(spacing: AXSpacing.md) {
            // Item count
            Text("\(viewModel.displayFiles.count) items")
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
            
            if !viewModel.selectedFiles.isEmpty {
                Text("• \(viewModel.selectedFiles.count) selected")
                    .font(.system(size: 10))
                    .foregroundColor(.axAccentBlue)
            }
            
            Spacer()
            
            // Error message
            if let error = viewModel.errorMessage {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 9))
                    Text(error)
                        .font(.system(size: 10))
                        .lineLimit(1)
                }
                .foregroundColor(.axWarning)
            }
            
            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .axAccentBlue))
                    .scaleEffect(0.5)
            }
            
            // Current path
            Text(viewModel.currentPath)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, 4)
        .background(Color.axBackgroundSecondary)
    }
    
    // MARK: - Transfer Progress
    
    private var transferProgressBar: some View {
        VStack(spacing: AXSpacing.xs) {
            ForEach(viewModel.activeTransfers) { transfer in
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: transfer.state == .completed ? "checkmark.circle.fill" :
                            transfer.state == .failed ? "xmark.circle.fill" : "arrow.up.circle")
                        .font(.system(size: 12))
                        .foregroundColor(transfer.state == .completed ? .axSuccess :
                                            transfer.state == .failed ? .axError : .axAccentBlue)
                    
                    Text(transfer.fileName)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    
                    if transfer.state == .transferring {
                        ProgressView(value: transfer.percentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: .axAccentBlue))
                            .frame(width: 100)
                    }
                    
                    Text(transfer.progressText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextTertiary)
                    
                    Spacer()
                    
                    if transfer.state == .transferring {
                        Button(action: { viewModel.cancelTransfer(transfer) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9))
                                .foregroundColor(.axTextMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axBackgroundSecondary)
    }
    
    // MARK: - Inline Editor Header
    
    private var inlineEditorHeader: some View {
        HStack(spacing: AXSpacing.md) {
            // Back to files
            Button(action: { viewModel.closeEditor() }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                    Text("Files")
                        .font(.system(size: 12))
                }
                .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().frame(height: 16)
            
            // File icon + name
            if let file = viewModel.editorFile {
                Image(systemName: file.iconName)
                    .font(.system(size: 13))
                    .foregroundColor(fileColor(for: file))
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: AXSpacing.xs) {
                    Text(viewModel.editorFile?.name ?? "Untitled")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    
                    if viewModel.isEditorDirty {
                        Circle()
                            .fill(Color.axWarning)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Text(viewModel.editorFile?.path ?? "")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Language badge
            if let file = viewModel.editorFile {
                Text(file.language.displayName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
            }
            
            // Discard
            Button(action: { viewModel.editorContent = viewModel.editorOriginalContent }) {
                Text("Discard")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 3)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.isEditorDirty)
            .opacity(viewModel.isEditorDirty ? 1 : 0.4)
            
            // Save
            Button(action: { viewModel.saveFile() }) {
                HStack(spacing: AXSpacing.xxs) {
                    if viewModel.isSavingFile {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.5)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 10))
                    }
                    Text("Save")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, 3)
                .background(viewModel.isEditorDirty ? Color.axAccentBlue : Color.axAccentBlue.opacity(0.4))
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.isEditorDirty || viewModel.isSavingFile)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackgroundSecondary)
    }
    
    // MARK: - New Folder Sheet
    
    private var newFolderSheet: some View {
        NewFolderSheetView(viewModel: viewModel)
    }
    
    // MARK: - Helpers
    
    private func fileColor(for file: RemoteFileItem) -> Color {
        switch file.fileExtension {
        case "html", "htm": return .orange
        case "css", "scss": return .blue
        case "js", "ts", "jsx", "tsx": return .yellow
        case "json": return .green
        case "php": return .purple
        case "py": return .cyan
        case "sh", "bash": return .mint
        case "conf", "env", "ini", "md", "yml", "yaml": return .gray
        case "log": return .secondary
        case "png", "jpg", "gif", "svg": return .pink
        case "zip", "tar", "gz": return .brown
        case "key", "pem", "crt", "avx": return .red
        default: return .axTextSecondary
        }
    }
    
    private func permissionColor(_ perms: FilePermissions) -> Color {
        if perms.ownerWrite && perms.othersWrite { return .axWarning }
        if perms.ownerExecute { return .axAccentGreen }
        return .axTextSecondary
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func showUploadPanel() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.begin { response in
            if response == .OK {
                viewModel.uploadFiles(urls: panel.urls)
            }
        }
        #endif
    }
    
    private func handleFileDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in
                    viewModel.uploadFiles(urls: [url])
                }
            }
        }
    }
}

// MARK: - New Folder Sheet View

struct NewFolderSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var folderName = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Text("New Folder")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Folder Name")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                TextField("folder-name", text: $folderName)
                    .textFieldStyle(AXTextFieldStyle())
                    .onSubmit {
                        createIfValid()
                    }
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showNewFolderSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                Button("Create") { createIfValid() }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(folderName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 340)
        .background(Color.axBackground)
    }
    
    private func createIfValid() {
        let name = folderName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.createFolder(name: name)
        viewModel.showNewFolderSheet = false
    }
}

// MARK: - New File Sheet View

struct NewFileSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var fileName = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Text("New File")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("File Name")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                TextField("filename.txt", text: $fileName)
                    .textFieldStyle(AXTextFieldStyle())
                    .onSubmit {
                        createIfValid()
                    }
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showNewFileSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                Button("Create") { createIfValid() }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(fileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 340)
        .background(Color.axBackground)
    }
    
    private func createIfValid() {
        let name = fileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.createFile(name: name)
        viewModel.showNewFileSheet = false
    }
}

// MARK: - Download from URL Sheet View

struct DownloadFromURLSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var urlString = ""
    @State private var fileName = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(.axAccentBlue)
                Text("Download from URL")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("URL")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    TextField("https://example.com/file.tar.gz", text: $urlString)
                        .textFieldStyle(AXTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("File Name (optional)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    TextField("Leave empty to auto-detect", text: $fileName)
                        .textFieldStyle(AXTextFieldStyle())
                }
                
                Text("Destination: \(viewModel.currentPath)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showDownloadURLSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                
                Button(action: {
                    viewModel.downloadFromURL(
                        urlString: urlString,
                        fileName: fileName.isEmpty ? nil : fileName
                    )
                }) {
                    HStack(spacing: AXSpacing.xxs) {
                        if viewModel.isDownloadingFromURL {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.5)
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 12))
                        }
                        Text("Download")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(urlString.isEmpty ? Color.axAccentBlue.opacity(0.4) : Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isDownloadingFromURL)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 420)
        .background(Color.axBackground)
    }
}

// MARK: - Compress Sheet View

struct CompressSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var archiveName = ""
    @State private var selectedFormat: SFTPFileManager.ArchiveFormat = .zip
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "archivebox")
                    .font(.system(size: 18))
                    .foregroundColor(.axAccentBlue)
                Text("Compress Files")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }
            
            Text("\(viewModel.selectedFiles.count) item(s) selected")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Archive Name")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    TextField("archive", text: $archiveName)
                        .textFieldStyle(AXTextFieldStyle())
                        .onSubmit { compressIfValid() }
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Format")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    Picker("", selection: $selectedFormat) {
                        ForEach(SFTPFileManager.ArchiveFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Text("Output: \(archiveName.isEmpty ? "archive" : archiveName).\(selectedFormat.fileExtension)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showCompressSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                
                Button(action: { compressIfValid() }) {
                    HStack(spacing: AXSpacing.xxs) {
                        if viewModel.isCompressing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.5)
                        }
                        Text("Compress")
                    }
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(archiveName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isCompressing)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 380)
        .background(Color.axBackground)
    }
    
    private func compressIfValid() {
        let name = archiveName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.compressSelected(archiveName: name, format: selectedFormat)
    }
}

// MARK: - Symlink Sheet View

struct SymlinkSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var linkName = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "link")
                    .font(.system(size: 18))
                    .foregroundColor(.axAccentBlue)
                Text("Create Symlink")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }
            
            if let source = viewModel.symlinkSourceFile {
                Text("Target: \(source.path)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(2)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Link Name")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                TextField("link_name", text: $linkName)
                    .textFieldStyle(AXTextFieldStyle())
                    .onSubmit { createIfValid() }
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showSymlinkSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                Button("Create") { createIfValid() }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(linkName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 380)
        .background(Color.axBackground)
    }
    
    private func createIfValid() {
        guard let source = viewModel.symlinkSourceFile else { return }
        let name = linkName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.createSymlink(target: source, linkName: name)
    }
}

// MARK: - Change Owner Sheet View

struct ChangeOwnerSheetView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var owner = "root"
    @State private var group = "root"
    @State private var recursive = false
    @State private var customOwner = false
    @State private var customGroup = false
    
    private let commonOwners = ["root", "www-data", "nginx", "nobody", "ubuntu", "deploy"]
    private let commonGroups = ["root", "www-data", "nginx", "nogroup", "adm", "users"]
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "person.2")
                    .font(.system(size: 18))
                    .foregroundColor(.axAccentBlue)
                Text("Change Owner")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }
            
            if let file = viewModel.changeOwnerFile {
                Text(file.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(2)
                
                Text("Current: \(file.owner):\(file.group)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                // Owner
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Owner")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    ownerChipRow(options: commonOwners, selected: $owner, isCustom: $customOwner)
                    
                    if customOwner {
                        TextField("custom user", text: $owner)
                            .textFieldStyle(AXTextFieldStyle())
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                
                // Group
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Group")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    ownerChipRow(options: commonGroups, selected: $group, isCustom: $customGroup)
                    
                    if customGroup {
                        TextField("custom group", text: $group)
                            .textFieldStyle(AXTextFieldStyle())
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                
                Toggle("Apply recursively", isOn: $recursive)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            
            // Preview
            Text("chown \(recursive ? "-R " : "")\(owner):\(group)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xxs)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") { viewModel.showChangeOwnerSheet = false }
                    .buttonStyle(AXSecondaryButtonStyle())
                Button("Apply") {
                    guard let file = viewModel.changeOwnerFile else { return }
                    viewModel.changeOwner(file: file, owner: owner, group: group, recursive: recursive)
                }
                .buttonStyle(AXPrimaryButtonStyle())
                .disabled(owner.isEmpty || group.isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 420)
        .background(Color.axBackground)
        .onAppear {
            if let file = viewModel.changeOwnerFile {
                owner = file.owner
                group = file.group
                customOwner = !commonOwners.contains(file.owner)
                customGroup = !commonGroups.contains(file.group)
            }
        }
    }
    
    private func ownerChipRow(options: [String], selected: Binding<String>, isCustom: Binding<Bool>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selected.wrappedValue = option
                        isCustom.wrappedValue = false
                    } label: {
                        Text(option)
                            .font(.system(size: 10, weight: selected.wrappedValue == option && !isCustom.wrappedValue ? .bold : .regular, design: .monospaced))
                            .foregroundColor(selected.wrappedValue == option && !isCustom.wrappedValue ? .white : .axTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                selected.wrappedValue == option && !isCustom.wrappedValue
                                    ? Color.axAccentBlue
                                    : Color.axBackgroundSecondary
                            )
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Custom option
                Button {
                    isCustom.wrappedValue = true
                    selected.wrappedValue = ""
                } label: {
                    Text("Custom")
                        .font(.system(size: 10, weight: isCustom.wrappedValue ? .bold : .regular))
                        .foregroundColor(isCustom.wrappedValue ? .white : .axTextTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isCustom.wrappedValue ? Color.axAccentBlue : Color.axBackgroundSecondary)
                        .cornerRadius(AXCornerRadius.sm)
                }
            .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Right Click Handler (macOS)

struct RightClickHandler: NSViewRepresentable {
    let action: (CGPoint) -> Void
    
    func makeNSView(context: Context) -> RightClickNSView {
        let view = RightClickNSView()
        view.onRightClick = action
        return view
    }
    
    func updateNSView(_ nsView: RightClickNSView, context: Context) {
        nsView.onRightClick = action
    }
    
    class RightClickNSView: NSView {
        var onRightClick: ((CGPoint) -> Void)?
        
        override func rightMouseDown(with event: NSEvent) {
            // Convert to window coordinates then to SwiftUI coordinate space
            guard let window = self.window else { return }
            let windowPoint = event.locationInWindow
            // Convert from bottom-left origin to top-left origin
            let flipped = CGPoint(
                x: windowPoint.x,
                y: window.contentView!.frame.height - windowPoint.y
            )
            onRightClick?(flipped)
        }
    }
}

// MARK: - Custom Context Menu View

struct CustomContextMenuView: View {
    let file: RemoteFileItem
    @ObservedObject var viewModel: FileManagerViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            // Header — file name with gradient
            HStack(spacing: 8) {
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
            } else {
                menuItem("Edit", icon: "pencil.circle.fill", color: .blue) {
                    viewModel.openFileEditor(file)
                }
                menuItem("Download", icon: "arrow.down.circle.fill", color: .cyan) {
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
            menuItem("Copy", icon: "doc.on.doc.fill", color: .blue) {
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
            menuItem("Rename", icon: "character.cursor.ibeam", color: .yellow) {
                viewModel.startRename(file)
            }
            menuItem("Duplicate", icon: "plus.square.on.square.fill", color: .yellow) {
                viewModel.duplicateFile(file)
            }
            menuItem("Create Symlink", icon: "link.circle.fill", color: .mint) {
                viewModel.symlinkSourceFile = file
                viewModel.showSymlinkSheet = true
            }
            menuItem("Copy Path", icon: "text.badge.checkmark", color: .gray) {
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
            
            // Delete
            menuItem("Delete", icon: "trash.fill", color: .red, isDestructive: true) {
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
