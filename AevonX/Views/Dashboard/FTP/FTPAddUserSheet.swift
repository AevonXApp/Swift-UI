//
//  FTPAddUserSheet.swift
//  AevonX
//
//  Sheet to add or edit an FTP user — with directory browser
//

import SwiftUI
import AevonXCoreBridge

struct FTPAddUserSheet: View {
    @ObservedObject var vm: FTPViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var documentRoot = "/www/wwwroot"
    @State private var quota = ""
    @State private var note = ""
    @State private var isSaving = false
    @State private var showPasswordCopied = false
    
    // Directory browser
    @State private var showDirBrowser = false
    @State private var currentBrowsePath = "/"
    @State private var directories: [String] = []
    @State private var isLoadingDirs = false
    
    private var isEditing: Bool { vm.editingUser != nil }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEditing ? "Edit FTP User" : "Add FTP User")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("Configure FTP access credentials and permissions")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextTertiary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            
            Divider().background(Color.axBorder)
            
            // Form
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    // Username
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        formLabel("Username")
                        TextField("FTP username", text: $username)
                            .font(.system(size: 13))
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(AXSpacing.sm)
                            .background(Color.axBackgroundTertiary)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            .cornerRadius(AXCornerRadius.sm)
                            .disabled(isEditing)
                            .opacity(isEditing ? 0.6 : 1)
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        formLabel("Password")
                        HStack(spacing: AXSpacing.sm) {
                            TextField("Password", text: $password)
                                .font(.system(size: 13, design: .monospaced))
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(AXSpacing.sm)
                                .background(Color.axBackgroundTertiary)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                                .cornerRadius(AXCornerRadius.sm)
                            
                            Button(action: { password = vm.generatePassword() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.axAccentBlue)
                                    .frame(width: 32, height: 32)
                                    .background(Color.axAccentBlue.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1))
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Generate Password")
                            
                            Button(action: {
                                #if os(macOS)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(password, forType: .string)
                                #endif
                                showPasswordCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showPasswordCopied = false }
                            }) {
                                Image(systemName: showPasswordCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(showPasswordCopied ? .axSuccess : .axTextSecondary)
                                    .frame(width: 32, height: 32)
                                    .background((showPasswordCopied ? Color.axSuccess : Color.axTextSecondary).opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke((showPasswordCopied ? Color.axSuccess : Color.axBorder).opacity(0.3), lineWidth: 1))
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Copy Password")
                        }
                        
                        // Password strength hint
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 10))
                            Text("Use the generate button for a secure random password")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.axTextTertiary)
                    }
                    
                    // Document Root
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        formLabel("Document Root")
                        
                        if showDirBrowser {
                            // Directory browser
                            VStack(spacing: 0) {
                                // Breadcrumb path bar
                                HStack(spacing: AXSpacing.xs) {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.axAccentBlue)
                                    Text(currentBrowsePath)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    if isLoadingDirs {
                                        ProgressView().scaleEffect(0.5)
                                    }
                                    
                                    // Go up
                                    if currentBrowsePath != "/" {
                                        Button(action: {
                                            let parent = (currentBrowsePath as NSString).deletingLastPathComponent
                                            currentBrowsePath = parent.isEmpty ? "/" : parent
                                            Task { await browseDirs() }
                                        }) {
                                            HStack(spacing: 2) {
                                                Image(systemName: "arrow.up").font(.system(size: 9, weight: .bold))
                                                Text("Up").font(.system(size: 10, weight: .medium))
                                            }
                                            .foregroundColor(.axAccentBlue)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.axAccentBlue.opacity(0.08))
                                            .cornerRadius(4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, 6)
                                .background(Color.axBackgroundTertiary)
                                
                                Divider().background(Color.axBorder)
                                
                                // Directory list
                                ScrollView {
                                    VStack(spacing: 0) {
                                        if directories.isEmpty && !isLoadingDirs {
                                            Text("Empty directory")
                                                .font(.system(size: 11))
                                                .foregroundColor(.axTextTertiary)
                                                .padding(AXSpacing.lg)
                                        } else {
                                            ForEach(directories, id: \.self) { dir in
                                                Button(action: {
                                                    let newPath = currentBrowsePath == "/"
                                                        ? "/\(dir)"
                                                        : "\(currentBrowsePath)/\(dir)"
                                                    currentBrowsePath = newPath
                                                    Task { await browseDirs() }
                                                }) {
                                                    HStack(spacing: AXSpacing.sm) {
                                                        Image(systemName: "folder")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(.axAccentBlue)
                                                        Text(dir)
                                                            .font(.system(size: 12))
                                                            .foregroundColor(.axTextPrimary)
                                                        Spacer()
                                                        Image(systemName: "chevron.right")
                                                            .font(.system(size: 9))
                                                            .foregroundColor(.axTextMuted)
                                                    }
                                                    .padding(.horizontal, AXSpacing.sm)
                                                    .padding(.vertical, 6)
                                                    .background(Color.clear)
                                                    .contentShape(Rectangle())
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                
                                                if dir != directories.last {
                                                    Divider().background(Color.axBorder.opacity(0.5))
                                                        .padding(.leading, 32)
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(height: 140)
                                
                                Divider().background(Color.axBorder)
                                
                                // Select / Cancel
                                HStack {
                                    Button(action: { showDirBrowser = false }) {
                                        Text("Cancel")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.axTextSecondary)
                                            .padding(.horizontal, AXSpacing.md)
                                            .padding(.vertical, 5)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Spacer()
                                    
                                    Text(currentBrowsePath)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.axTextTertiary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        documentRoot = currentBrowsePath
                                        showDirBrowser = false
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                                            Text("Select").font(.system(size: 11, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, AXSpacing.md)
                                        .padding(.vertical, 5)
                                        .background(Color.axAccentBlue)
                                        .cornerRadius(AXCornerRadius.sm)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, 6)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.sm)
                        } else {
                            HStack(spacing: AXSpacing.sm) {
                                TextField("/path/to/directory", text: $documentRoot)
                                    .font(.system(size: 13, design: .monospaced))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(AXSpacing.sm)
                                    .background(Color.axBackgroundTertiary)
                                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                                    .cornerRadius(AXCornerRadius.sm)
                                
                                Button(action: {
                                    showDirBrowser = true
                                    currentBrowsePath = documentRoot.isEmpty ? "/" : documentRoot
                                    Task { await browseDirs() }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "folder.badge.questionmark")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Browse")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(.axAccentBlue)
                                    .padding(.horizontal, AXSpacing.md)
                                    .padding(.vertical, 8)
                                    .background(Color.axAccentBlue.opacity(0.1))
                                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1))
                                    .cornerRadius(AXCornerRadius.sm)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help("Browse Server Directories")
                            }
                        }
                        
                        // Common paths
                        if !showDirBrowser {
                            HStack(spacing: AXSpacing.sm) {
                                Text("Quick:")
                                    .font(.system(size: 10))
                                    .foregroundColor(.axTextTertiary)
                                ForEach(["/www/wwwroot", "/home", "/var/www"], id: \.self) { path in
                                    Button(action: { documentRoot = path }) {
                                        Text(path)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(documentRoot == path ? .axAccentBlue : .axTextTertiary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(documentRoot == path ? Color.axAccentBlue.opacity(0.08) : Color.axBackgroundTertiary)
                                            .cornerRadius(3)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    // Quota + Note side by side
                    HStack(spacing: AXSpacing.lg) {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            formLabel("Quota")
                            HStack(spacing: 0) {
                                TextField("0 = Unlimited", text: $quota)
                                    .font(.system(size: 13))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(AXSpacing.sm)
                                
                                Text("MB")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.axTextTertiary)
                                    .padding(.trailing, AXSpacing.sm)
                            }
                            .background(Color.axBackgroundTertiary)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            .cornerRadius(AXCornerRadius.sm)
                        }
                        
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            formLabel("Note")
                            TextField("Optional note", text: $note)
                                .font(.system(size: 13))
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(AXSpacing.sm)
                                .background(Color.axBackgroundTertiary)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                }
                .padding(AXSpacing.xl)
            }
            
            Divider().background(Color.axBorder)
            
            // Footer
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.sm)
                
                Spacer()
                
                Button(action: save) {
                    HStack(spacing: AXSpacing.xs) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                        }
                        Text(isEditing ? "Save Changes" : "Create User")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(username.isEmpty || password.isEmpty || isSaving)
                .opacity(username.isEmpty || password.isEmpty ? 0.5 : 1)
            }
            .padding(AXSpacing.xl)
        }
        .frame(width: 600, height: showDirBrowser ? 640 : 520)
        .background(Color.axBackground)
        .animation(.spring(response: 0.3), value: showDirBrowser)
        .onAppear {
            if let editing = vm.editingUser {
                username = editing.username
                password = editing.password
                documentRoot = editing.documentRoot
                quota = editing.quota > 0 ? "\(editing.quota)" : ""
                note = editing.note
            } else {
                password = vm.generatePassword()
            }
        }
    }
    
    private func save() {
        isSaving = true
        var user = FTPUser(
            username: username,
            password: password,
            documentRoot: documentRoot,
            quota: Int(quota) ?? 0,
            note: note
        )
        if let editing = vm.editingUser {
            user.id = editing.id
        }
        Task {
            if isEditing {
                await vm.changePassword(username: user.username, newPassword: user.password)
            } else {
                await vm.addUser(user)
            }
            isSaving = false
            dismiss()
        }
    }
    
    private func browseDirs() async {
        isLoadingDirs = true
        defer { isLoadingDirs = false }
        let json = await SSHBridge.shared.executeAsyncJSON(
            serverID: vm.serverId,
            command: FilesBridge.shared.browseSubdirsCmd(path: currentBrowsePath)
        )
        let result = SSHResult.parse(json)
        let paths = result.stdout.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .compactMap { path -> String? in
                let name = (path as NSString).lastPathComponent
                return name.isEmpty ? nil : name
            }
        directories = paths
    }
    
    private func formLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.axTextSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
