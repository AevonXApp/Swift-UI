//
//  FileInfoSheet.swift
//  AevonX
//
//  Detailed file information sheet showing metadata
//  Size, path, permissions, owner, dates, type detection
//

import SwiftUI
import AevonXCoreBridge

// MARK: - File Info Sheet

struct FileInfoSheet: View {
    let file: RemoteFileItem
    @ObservedObject var viewModel: FileManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: file.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(file.isDirectory ? .axAccentBlue : fileColor(for: file))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(AXTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(file.isDirectory ? "Directory" : file.language.displayName)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.axBackgroundSecondary)
            
            Divider().background(Color.axBorder)
            
            // Info Grid
            ScrollView {
                VStack(spacing: 0) {
                    infoRow("Full Path", file.path, icon: "folder", mono: true)
                    infoRow("Size", file.formattedSize, icon: "internaldrive")
                    infoRow("Permissions", file.permissions.numericString, icon: "lock")
                    infoRow("Owner", "\(file.owner):\(file.group)", icon: "person")
                    infoRow("Modified", formatFileDate(file.modifiedDate), icon: "calendar")
                    
                    if file.isSymlink, let target = file.symlinkTarget {
                        infoRow("Symlink Target", target, icon: "arrow.turn.right.down", mono: true)
                    }
                    
                    if file.isDirectory {
                        infoRow("Type", "Directory", icon: "folder.fill")
                    } else {
                        let ext = (file.name as NSString).pathExtension
                        if !ext.isEmpty {
                            infoRow("Extension", ".\(ext)", icon: "doc")
                        }
                        infoRow("Language", file.language.displayName, icon: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    // MIME type guess
                    if !file.isDirectory {
                        infoRow("MIME Type", guessMIME(for: file), icon: "doc.text")
                    }
                }
            }
            
            Divider().background(Color.axBorder)
            
            // Actions
            HStack(spacing: AXSpacing.md) {
                Button(L10n.Files.copyPath) {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(file.path, forType: .string)
                    #endif
                    dismiss()
                }
                .buttonStyle(AXSecondaryButtonStyle())
                
                Button(L10n.Files.editPermissions) {
                    dismiss()
                    viewModel.openPermissionsEditor(file)
                }
                .buttonStyle(AXSecondaryButtonStyle())
                
                Spacer()
                
                Button(L10n.Button.close) { dismiss() }
                    .buttonStyle(AXPrimaryButtonStyle())
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .background(Color.axBackground)
    }
    
    // MARK: - Info Row
    
    private func infoRow(_ label: String, _ value: String, icon: String, mono: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(.axAccentBlue)
                    .frame(width: 16)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 110, alignment: .leading)
                
                Text(value)
                    .font(.system(size: 12, design: mono ? .monospaced : .default))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(2)
                    .textSelection(.enabled)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider().background(Color.axBorder.opacity(0.3))
        }
    }
    
    // MARK: - MIME Type Guess
    
    private func guessMIME(for file: RemoteFileItem) -> String {
        let ext = (file.name as NSString).pathExtension.lowercased()
        switch ext {
        case "html", "htm": return "text/html"
        case "css": return "text/css"
        case "js", "mjs": return "application/javascript"
        case "json": return "application/json"
        case "xml": return "application/xml"
        case "php": return "application/x-php"
        case "py": return "text/x-python"
        case "rb": return "text/x-ruby"
        case "swift": return "text/x-swift"
        case "go": return "text/x-go"
        case "rs": return "text/x-rust"
        case "java": return "text/x-java"
        case "sh", "bash": return "application/x-shellscript"
        case "sql": return "application/sql"
        case "yaml", "yml": return "application/x-yaml"
        case "md": return "text/markdown"
        case "txt", "log": return "text/plain"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "pdf": return "application/pdf"
        case "zip": return "application/zip"
        case "gz", "tgz": return "application/gzip"
        case "tar": return "application/x-tar"
        case "mp4": return "video/mp4"
        case "mp3": return "audio/mpeg"
        default: return "application/octet-stream"
        }
    }
}
