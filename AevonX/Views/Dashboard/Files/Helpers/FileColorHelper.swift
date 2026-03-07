//
//  FileColorHelper.swift
//  AevonX
//
//  Color mapping helpers for file types and permissions
//

import SwiftUI
import AevonXCore

// MARK: - File Color Helpers

/// Color for file icon based on file extension
func fileColor(for file: RemoteFileItem) -> Color {
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

/// Color for permission display based on security level
func permissionColor(_ perms: FilePermissions) -> Color {
    if perms.ownerWrite && perms.othersWrite { return .axWarning }
    if perms.ownerExecute { return .axAccentGreen }
    return .axTextSecondary
}
