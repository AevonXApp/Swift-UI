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
    
    @StateObject private var viewModel: FileManagerViewModel
    
    init(serverId: String, connectionViewModel: ServerConnectionViewModel) {
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
        _viewModel = StateObject(wrappedValue: FileManagerViewModel(serverId: serverId))
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
                HStack(spacing: 0) {
                    ForEach(Array(viewModel.tabs.enumerated()), id: \.element.id) { index, tab in
                        tabItem(tab, index: index)
                    }
                }
            }
            
            Spacer()
            
            // New Tab Button
            Button(action: { viewModel.createTab() }) {
                Image(systemName: "plus")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, AXSpacing.sm)
        }
        .frame(height: 32)
        .background(Color.axBackgroundSecondary)
    }
    
    private func tabItem(_ tab: FileBrowserTabState, index: Int) -> some View {
        let isActive = index == viewModel.activeTabIndex
        
        return HStack(spacing: AXSpacing.xs) {
            Image(systemName: "folder")
                .font(.system(size: 10))
            Text(tab.title)
                .font(.system(size: 11))
                .lineLimit(1)
            
            if viewModel.tabs.count > 1 {
                Button(action: { viewModel.closeTab(at: index) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .foregroundColor(isActive ? .axTextPrimary : .axTextSecondary)
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(isActive ? Color.axBackground : Color.clear)
        .overlay(
            Rectangle()
                .fill(isActive ? Color.axAccentBlue : Color.clear)
                .frame(height: 2),
            alignment: .bottom
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
                
                Divider().frame(height: 16)
                
                toolbarButton(icon: "arrow.clockwise", action: { viewModel.refresh() })
                toolbarButton(icon: "eye\(viewModel.showHiddenFiles ? "" : ".slash")", action: { viewModel.showHiddenFiles.toggle() })
                
                Divider().frame(height: 16)
                
                toolbarButton(icon: "folder.badge.plus", action: { viewModel.showNewFolderSheet = true })
                toolbarButton(icon: "square.and.arrow.up", action: { showUploadPanel() })
                
                if !viewModel.selectedFiles.isEmpty {
                    Divider().frame(height: 16)
                    toolbarButton(icon: "trash", action: { viewModel.deleteSelected() }, tint: .axError)
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
                .font(.system(size: 12))
                .foregroundColor(disabled ? .axTextMuted.opacity(0.4) : tint)
                .frame(width: 26, height: 26)
                .background(Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
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
            headerColumn("Permissions", width: 100, alignment: .center)
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
            
            // Permissions
            Text(file.permissions.symbolic)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(permissionColor(file.permissions))
                .frame(width: 100, alignment: .center)
            
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
        .contextMenu { fileContextMenu(file) }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func fileContextMenu(_ file: RemoteFileItem) -> some View {
        if file.isDirectory {
            Button { viewModel.navigateTo(file.path) } label: {
                Label("Open", systemImage: "folder")
            }
            Button { viewModel.createTab(path: file.path) } label: {
                Label("Open in New Tab", systemImage: "plus.rectangle")
            }
        } else {
            Button { viewModel.openFileEditor(file) } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button { viewModel.downloadFile(file) } label: {
                Label("Download", systemImage: "square.and.arrow.down")
            }
        }
        
        Divider()
        
        Button { viewModel.startRename(file) } label: {
            Label("Rename", systemImage: "pencil.line")
        }
        Button { viewModel.duplicateFile(file) } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        Button { viewModel.copyPath(file) } label: {
            Label("Copy Path", systemImage: "doc.on.clipboard")
        }
        
        Divider()
        
        Button { viewModel.openPermissionsEditor(file) } label: {
            Label("Permissions (\(file.permissions.numericString))", systemImage: "lock.shield")
        }
        
        Divider()
        
        Button(role: .destructive) { viewModel.confirmDelete([file]) } label: {
            Label("Delete", systemImage: "trash")
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
