//
//  FilesTab.swift
//  AevonX
//
//  SFTP File Explorer with upload/download/edit capabilities
//

import SwiftUI
import UniformTypeIdentifiers

struct FileItem: Identifiable {
    let id = UUID()
    var name: String
    var isDirectory: Bool
    var size: Int64?
    var modifiedDate: Date
    var permissions: String
    var children: [FileItem]?
    var isExpanded: Bool = false
}

struct FilesTab: View {
    @State private var currentPath = "/var/www"
    @State private var searchText = ""
    @State private var selectedFile: FileItem?
    @State private var showUploadSheet = false
    @State private var showNewFolderSheet = false
    @State private var showFileEditor = false
    @State private var editingFile: FileItem?
    
    @State private var files: [FileItem] = [
        FileItem(
            name: "html",
            isDirectory: true,
            size: nil,
            modifiedDate: Date().addingTimeInterval(-86400),
            permissions: "drwxr-xr-x",
            children: [
                FileItem(name: "index.html", isDirectory: false, size: 3456, modifiedDate: Date().addingTimeInterval(-3600), permissions: "-rw-r--r--", children: nil),
                FileItem(name: "about.html", isDirectory: false, size: 2345, modifiedDate: Date().addingTimeInterval(-7200), permissions: "-rw-r--r--", children: nil),
                FileItem(name: "css", isDirectory: true, size: nil, modifiedDate: Date().addingTimeInterval(-86400), permissions: "drwxr-xr-x", children: [
                    FileItem(name: "main.css", isDirectory: false, size: 5678, modifiedDate: Date().addingTimeInterval(-3600), permissions: "-rw-r--r--", children: nil),
                    FileItem(name: "responsive.css", isDirectory: false, size: 3456, modifiedDate: Date().addingTimeInterval(-7200), permissions: "-rw-r--r--", children: nil)
                ]),
                FileItem(name: "js", isDirectory: true, size: nil, modifiedDate: Date().addingTimeInterval(-86400), permissions: "drwxr-xr-x", children: [
                    FileItem(name: "app.js", isDirectory: false, size: 12345, modifiedDate: Date().addingTimeInterval(-1800), permissions: "-rw-r--r--", children: nil),
                    FileItem(name: "utils.js", isDirectory: false, size: 4567, modifiedDate: Date().addingTimeInterval(-3600), permissions: "-rw-r--r--", children: nil)
                ])
            ]
        ),
        FileItem(name: "logs", isDirectory: true, size: nil, modifiedDate: Date().addingTimeInterval(-172800), permissions: "drwxr-xr-x", children: [
            FileItem(name: "access.log", isDirectory: false, size: 2345678, modifiedDate: Date().addingTimeInterval(-300), permissions: "-rw-r--r--", children: nil),
            FileItem(name: "error.log", isDirectory: false, size: 123456, modifiedDate: Date().addingTimeInterval(-600), permissions: "-rw-r--r--", children: nil),
            FileItem(name: "nginx.log", isDirectory: false, size: 567890, modifiedDate: Date().addingTimeInterval(-900), permissions: "-rw-r--r--", children: nil)
        ]),
        FileItem(name: "config", isDirectory: true, size: nil, modifiedDate: Date().addingTimeInterval(-259200), permissions: "drwxr-xr-x", children: [
            FileItem(name: "nginx.conf", isDirectory: false, size: 3456, modifiedDate: Date().addingTimeInterval(-86400), permissions: "-rw-r--r--", children: nil),
            FileItem(name: "php.ini", isDirectory: false, size: 12345, modifiedDate: Date().addingTimeInterval(-172800), permissions: "-rw-r--r--", children: nil)
        ]),
        FileItem(name: "README.md", isDirectory: false, size: 2345, modifiedDate: Date().addingTimeInterval(-432000), permissions: "-rw-r--r--", children: nil),
        FileItem(name: ".env", isDirectory: false, size: 567, modifiedDate: Date().addingTimeInterval(-604800), permissions: "-rw-r--r--", children: nil),
        FileItem(name: "deploy.sh", isDirectory: false, size: 1234, modifiedDate: Date().addingTimeInterval(-21600), permissions: "-rwxr-xr-x", children: nil)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar - Quick Access
            FileSidebar()
                .frame(width: 200)
            
            Divider()
                .background(Color.axBorder)
            
            // Main File Browser
            VStack(spacing: 0) {
                // Toolbar
                FileToolbar(
                    currentPath: $currentPath,
                    searchText: $searchText,
                    showUploadSheet: $showUploadSheet,
                    showNewFolderSheet: $showNewFolderSheet
                )
                
                Divider()
                    .background(Color.axBorder)
                
                // File List Header
                FileListHeader()
                
                Divider()
                    .background(Color.axBorder)
                
                // File List
                List {
                    ForEach(files) { file in
                        FileRow(
                            file: file,
                            level: 0,
                            selectedFile: $selectedFile,
                            onEdit: { file in
                                editingFile = file
                                showFileEditor = true
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.axBackground)
                .scrollContentBackground(.hidden)
                
                // Status Bar
                FileStatusBar(selectedFile: selectedFile, itemCount: files.count)
            }
            .background(Color.axBackground)
        }
        .background(Color.axBackground)
        .sheet(isPresented: $showUploadSheet) {
            UploadFileView()
        }
        .sheet(isPresented: $showNewFolderSheet) {
            NewFolderView()
        }
        .sheet(isPresented: $showFileEditor) {
            if let file = editingFile {
                FileEditorView(file: file)
            }
        }
    }
}

// MARK: - File Sidebar
struct FileSidebar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FAVORITES")
                .font(AXTypography.caption2)
                .fontWeight(.bold)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.top, AXSpacing.lg)
                .padding(.bottom, AXSpacing.sm)
            
            VStack(spacing: AXSpacing.xxs) {
                FileSidebarItem(icon: "house", title: "Home")
                FileSidebarItem(icon: "desktopcomputer", title: "Root")
                FileSidebarItem(icon: "globe", title: "Web Root")
                FileSidebarItem(icon: "doc.text", title: "Logs")
                FileSidebarItem(icon: "gearshape", title: "Config")
            }
            
            Text("QUICK ACCESS")
                .font(AXTypography.caption2)
                .fontWeight(.bold)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.top, AXSpacing.xl)
                .padding(.bottom, AXSpacing.sm)
            
            VStack(spacing: AXSpacing.xxs) {
                FileSidebarItem(icon: "clock", title: "Recent")
                FileSidebarItem(icon: "star", title: "Starred")
            }
            
            Spacer()
        }
        .background(Color.axBackgroundSecondary)
    }
}

struct FileSidebarItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                
                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - File Toolbar
struct FileToolbar: View {
    @Binding var currentPath: String
    @Binding var searchText: String
    @Binding var showUploadSheet: Bool
    @Binding var showNewFolderSheet: Bool
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Navigation
            HStack(spacing: AXSpacing.xs) {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(true)
            }
            
            // Path Bar
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "folder")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
                
                Text(currentPath)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            
            Spacer()
            
            // Search
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
                
                TextField("Search files...", text: $searchText)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 150)
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .cornerRadius(AXCornerRadius.sm)
            
            // Actions
            HStack(spacing: AXSpacing.xs) {
                Button(action: { showUploadSheet = true }) {
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 14))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 32, height: 32)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Upload File")
                
                Button(action: { showNewFolderSheet = true }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14))
                        .foregroundColor(.axAccentGreen)
                        .frame(width: 32, height: 32)
                        .background(Color.axAccentGreen.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .help("New Folder")
                
                Button(action: {}) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Download")
                
                Divider()
                    .frame(height: 20)
                    .background(Color.axBorder)
                
                Button(action: {}) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axBackground)
    }
}

// MARK: - File List Header
struct FileListHeader: View {
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Text("Name")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 300, alignment: .leading)
            
            Text("Size")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 80, alignment: .trailing)
            
            Text("Permissions")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 90, alignment: .center)
            
            Text("Modified")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text("Actions")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextMuted)
                .frame(width: 100, alignment: .center)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackgroundTertiary)
    }
}

// MARK: - File Row
struct FileRow: View {
    @State var file: FileItem
    let level: Int
    @Binding var selectedFile: FileItem?
    var onEdit: (FileItem) -> Void
    
    var isSelected: Bool {
        selectedFile?.id == file.id
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                selectedFile = file
                if file.isDirectory {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        file.isExpanded.toggle()
                    }
                }
            }) {
                HStack(spacing: AXSpacing.md) {
                    // Indentation + Expand Icon
                    HStack(spacing: AXSpacing.xs) {
                        ForEach(0..<level, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 16)
                        }
                        
                        if file.isDirectory {
                            Image(systemName: file.isExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.axTextMuted)
                                .frame(width: 16)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 16)
                        }
                        
                        // File Icon
                        Image(systemName: fileIcon)
                            .font(.system(size: 16))
                            .foregroundColor(fileColor)
                        
                        // Name
                        Text(file.name)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                    }
                    .frame(width: 300, alignment: .leading)
                    
                    // Size
                    Text(fileSize)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .frame(width: 80, alignment: .trailing)
                    
                    // Permissions
                    Text(file.permissions)
                        .font(AXTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(permissionColor)
                        .frame(width: 90, alignment: .center)
                        .monospaced()
                    
                    // Modified Date
                    Text(formatDate(file.modifiedDate))
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .frame(width: 120, alignment: .leading)
                    
                    Spacer()
                    
                    // Actions
                    HStack(spacing: AXSpacing.sm) {
                        if !file.isDirectory {
                            Button(action: { onEdit(file) }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                    .foregroundColor(.axAccentBlue)
                                    .frame(width: 26, height: 26)
                                    .background(Color.axAccentBlue.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Edit")
                            
                            Button(action: {}) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextSecondary)
                                    .frame(width: 26, height: 26)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Download")
                        }
                        
                        Menu {
                            if file.isDirectory {
                                Button("Open") {}
                                Button("Upload Here") {}
                            } else {
                                Button("Edit") { onEdit(file) }
                                Button("Download") {}
                                Button("Duplicate") {}
                            }
                            Button("Rename") {}
                            Button("Copy Path") {}
                            Divider()
                            Button("Permissions") {}
                            Divider()
                            Button("Delete", role: .destructive) {}
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextSecondary)
                                .frame(width: 26, height: 26)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                    .frame(width: 100, alignment: .center)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Children
            if file.isDirectory && file.isExpanded, let children = file.children {
                ForEach(children) { child in
                    FileRow(file: child, level: level + 1, selectedFile: $selectedFile, onEdit: onEdit)
                }
            }
        }
    }
    
    private var fileIcon: String {
        if file.isDirectory {
            return "folder.fill"
        }
        let ext = (file.name as NSString).pathExtension.lowercased()
        switch ext {
        case "html", "htm": return "doc.text.magnifyingglass"
        case "css": return "paintbrush"
        case "js", "ts": return "doc.plaintext"
        case "json": return "doc.text"
        case "md": return "doc.text"
        case "sh", "bash": return "terminal"
        case "log": return "doc.text.below.ecg"
        case "conf", "ini", "env": return "gearshape"
        case "php": return "p.circle"
        case "py": return "p.circle.fill"
        case "go": return "g.circle"
        default: return "doc"
        }
    }
    
    private var fileColor: Color {
        if file.isDirectory {
            return .axAccentBlue
        }
        let ext = (file.name as NSString).pathExtension.lowercased()
        switch ext {
        case "html", "htm": return .axError
        case "css": return .axInfo
        case "js", "ts": return .axWarning
        case "sh", "bash": return .axSuccess
        case "conf", "ini", "env": return .axTextSecondary
        default: return .axTextTertiary
        }
    }
    
    private var fileSize: String {
        guard let size = file.size else { return "--" }
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024)
        } else {
            return String(format: "%.1f MB", Double(size) / (1024 * 1024))
        }
    }
    
    private var permissionColor: Color {
        if file.permissions.hasPrefix("d") {
            return .axAccentBlue
        } else if file.permissions.hasPrefix("-") && file.permissions.contains("x") {
            return .axSuccess
        } else {
            return .axTextTertiary
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - File Status Bar
struct FileStatusBar: View {
    let selectedFile: FileItem?
    let itemCount: Int
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            if let file = selectedFile {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: file.isDirectory ? "folder" : "doc")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextMuted)
                    
                    Text(file.name)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    if let size = file.size {
                        Text("•")
                            .foregroundColor(.axTextMuted)
                        
                        Text(formatSize(size))
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                }
                
                Spacer()
                
                Text(file.permissions)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                    .monospaced()
            } else {
                Text("\(itemCount) items")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                Spacer()
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackgroundTertiary)
    }
    
    private func formatSize(_ size: Int64) -> String {
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024)
        } else {
            return String(format: "%.1f MB", Double(size) / (1024 * 1024))
        }
    }
}

// MARK: - Upload File View
struct UploadFileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFiles: [String] = []
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            HStack {
                Text("Upload Files")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .background(Color.axBorder)
            
            // Drop Zone
            VStack(spacing: AXSpacing.lg) {
                Image(systemName: "arrow.up.doc")
                    .font(.system(size: 48))
                    .foregroundColor(.axAccentBlue)
                
                Text("Drag & Drop Files Here")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                
                Text("or")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                
                Button(action: {}) {
                    Text("Browse Files")
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.axSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .stroke(Color.axAccentBlue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
            .cornerRadius(AXCornerRadius.lg)
            
            HStack(spacing: AXSpacing.md) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { dismiss() }) {
                    Text("Upload")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 500, height: 450)
        .background(Color.axBackground)
    }
}

// MARK: - New Folder View
struct NewFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var folderName = ""
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            HStack {
                Text("New Folder")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .background(Color.axBorder)
            
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Folder Name")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                TextField("new-folder", text: $folderName)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
                    .padding(AXSpacing.md)
                    .background(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .cornerRadius(AXCornerRadius.md)
            }
            
            Spacer()
            
            HStack(spacing: AXSpacing.md) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { dismiss() }) {
                    Text("Create")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentGreen)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 350, height: 250)
        .background(Color.axBackground)
    }
}

// MARK: - File Editor View
struct FileEditorView: View {
    let file: FileItem
    @Environment(\.dismiss) private var dismiss
    @State private var content = "// Sample file content\nfunction hello() {\n  console.log('Hello, AevonX!');\n}\n"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text("Editing: \(file.name)")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    Text("\(formatSize(file.size ?? 0)) • \(file.permissions)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                
                Spacer()
                
                HStack(spacing: AXSpacing.sm) {
                    Button(action: {}) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Download")
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axBackgroundSecondary)
            
            Divider()
                .background(Color.axBorder)
            
            // Editor
            TextEditor(text: $content)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .background(Color.axBackground)
                .scrollContentBackground(.hidden)
            
            Divider()
                .background(Color.axBorder)
            
            // Footer
            HStack {
                Text("UTF-8")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                
                Spacer()
                
                HStack(spacing: AXSpacing.md) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { dismiss() }) {
                        Text("Save Changes")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axBackgroundSecondary)
        }
        .frame(width: 700, height: 500)
        .background(Color.axBackground)
    }
    
    private func formatSize(_ size: Int64) -> String {
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024)
        } else {
            return String(format: "%.1f MB", Double(size) / (1024 * 1024))
        }
    }
}

#Preview {
    FilesTab()
        .frame(height: 600)
        .background(Color.axBackground)
}
