//
//  SFTPService+Operations.swift
//  AevonXCoreBridge
//
//  Extension: CRUD, permissions, archive, symlink, search, file info
//

import Foundation

// MARK: - File CRUD Operations

extension SFTPService {

    /// Delete a file or directory
    public func deleteItem(path: String, serverId: String) async throws {
        let safePath = escapePath(path)
        let result = try await ssh("rm -rf \(safePath)", serverId: serverId)

        guard result.isSuccess else {
            if result.stderr.contains("Permission denied") {
                throw SFTPError.permissionDenied(path)
            }
            throw SFTPError.parseFailed(result.stderr)
        }
    }

    /// Rename or move a file/directory
    public func renameItem(from oldPath: String, to newPath: String, serverId: String) async throws {
        let safeOld = escapePath(oldPath)
        let safeNew = escapePath(newPath)
        let result = try await ssh("mv \(safeOld) \(safeNew)", serverId: serverId)

        guard result.isSuccess else {
            if result.stderr.contains("Permission denied") {
                throw SFTPError.permissionDenied(oldPath)
            }
            throw SFTPError.parseFailed(result.stderr)
        }
    }

    /// Create a new directory
    public func createDirectory(path: String, serverId: String) async throws {
        let safePath = escapePath(path)
        let result = try await ssh("mkdir -p \(safePath)", serverId: serverId)

        guard result.isSuccess else {
            if result.stderr.contains("Permission denied") {
                throw SFTPError.permissionDenied(path)
            }
            throw SFTPError.parseFailed(result.stderr)
        }
    }

    /// Change file/directory permissions
    public func changePermissions(path: String, mode: String, serverId: String) async throws {
        let safePath = escapePath(path)
        let safeMode = mode.replacingOccurrences(of: "'", with: "")
        let result = try await ssh("chmod \(safeMode) \(safePath)", serverId: serverId)

        guard result.isSuccess else {
            if result.stderr.contains("Permission denied") {
                throw SFTPError.permissionDenied(path)
            }
            throw SFTPError.parseFailed(result.stderr)
        }
    }

    /// Change file owner and group
    public func changeOwner(path: String, owner: String, group: String, serverId: String) async throws {
        let safePath = escapePath(path)
        let safeOwner = owner.replacingOccurrences(of: "'", with: "")
        let safeGroup = group.replacingOccurrences(of: "'", with: "")
        let result = try await ssh("chown \(safeOwner):\(safeGroup) \(safePath)", serverId: serverId)

        guard result.isSuccess else {
            throw SFTPError.permissionDenied(path)
        }
    }

    /// Copy a file or directory
    public func copyItem(from sourcePath: String, to destPath: String, serverId: String) async throws {
        let safeSrc = escapePath(sourcePath)
        let safeDest = escapePath(destPath)
        let result = try await ssh("cp -r \(safeSrc) \(safeDest)", serverId: serverId)

        guard result.isSuccess else {
            if result.stderr.contains("Permission denied") {
                throw SFTPError.permissionDenied(sourcePath)
            }
            throw SFTPError.parseFailed(result.stderr)
        }
    }

    /// Create a new empty file
    public func createFile(path: String, serverId: String) async throws {
        let safePath = escapePath(path)
        let result = try await ssh("touch \(safePath)", serverId: serverId)

        guard result.isSuccess else {
            throw SFTPError.permissionDenied(path)
        }
    }

    // MARK: - Search & Info

    /// Search for files matching a pattern
    public func searchFiles(
        query: String,
        path: String,
        serverId: String,
        maxResults: Int = 100
    ) async throws -> [RemoteFileItem] {
        let safePath = escapePath(path)
        let safeQuery = query.replacingOccurrences(of: "'", with: "'\\''")

        let command = "find \(safePath) -maxdepth 5 -iname '*\(safeQuery)*' 2>/dev/null | head -n \(maxResults)"
        let result = try await ssh(command, serverId: serverId)

        let paths = result.stdout.components(separatedBy: "\n").filter { !$0.isEmpty }

        var items: [RemoteFileItem] = []
        for filePath in paths {
            if let item = try? await getFileInfo(path: filePath, serverId: serverId) {
                items.append(item)
            }
        }

        return items
    }

    /// Get detailed file info using stat
    public func getFileInfo(path: String, serverId: String) async throws -> RemoteFileItem {
        let safePath = escapePath(path)

        let command = "LC_ALL=C stat -c '%a %s %U %G %Y %F' \(safePath) 2>/dev/null || LC_ALL=C stat -f '%Lp %z %Su %Sg %m %HT' \(safePath)"
        let result = try await ssh(command, serverId: serverId)

        guard result.isSuccess else {
            throw SFTPError.fileNotFound(path)
        }

        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = output.components(separatedBy: " ")

        guard parts.count >= 5 else {
            throw SFTPError.parseFailed("stat output: \(output)")
        }

        let numericPerms = Int(parts[0]) ?? 644
        let size = Int64(parts[1]) ?? 0
        let owner = parts[2]
        let group = parts[3]
        let epoch = TimeInterval(parts[4]) ?? 0
        let fileType = parts.count > 5 ? parts[5...].joined(separator: " ").lowercased() : ""

        let isDirectory = fileType.contains("directory")
        let isSymlink = fileType.contains("symbolic") || fileType.contains("link")
        let name = (path as NSString).lastPathComponent

        return RemoteFileItem(
            name: name,
            path: path,
            isDirectory: isDirectory,
            isSymlink: isSymlink,
            size: size,
            permissions: .fromNumeric(numericPerms, isDirectory: isDirectory, isSymlink: isSymlink),
            owner: owner,
            group: group,
            modifiedDate: Date(timeIntervalSince1970: epoch),
            isHidden: name.hasPrefix(".")
        )
    }

    // MARK: - Archive Operations

    /// Extract an archive file (auto-detects format)
    public func extractArchive(path: String, destPath: String? = nil, serverId: String) async throws {
        let safePath = escapePath(path)
        let dest = escapePath(destPath ?? (path as NSString).deletingLastPathComponent)
        let lower = path.lowercased()

        let command: String
        if lower.hasSuffix(".zip") {
            command = "unzip -o \(safePath) -d \(dest)"
        } else if lower.hasSuffix(".tar.gz") || lower.hasSuffix(".tgz") {
            command = "tar -xzf \(safePath) -C \(dest)"
        } else if lower.hasSuffix(".tar.bz2") || lower.hasSuffix(".tbz2") {
            command = "tar -xjf \(safePath) -C \(dest)"
        } else if lower.hasSuffix(".tar.xz") || lower.hasSuffix(".txz") {
            command = "tar -xJf \(safePath) -C \(dest)"
        } else if lower.hasSuffix(".tar") {
            command = "tar -xf \(safePath) -C \(dest)"
        } else if lower.hasSuffix(".rar") {
            command = "unrar x -o+ \(safePath) \(dest)"
        } else if lower.hasSuffix(".7z") {
            command = "7z x \(safePath) -o\(dest)"
        } else if lower.hasSuffix(".gz") {
            command = "gunzip -k \(safePath)"
        } else {
            throw SFTPError.invalidPath("Unsupported archive format: \(path)")
        }

        let result = try await ssh(command, serverId: serverId)

        guard result.isSuccess else {
            throw SFTPError.parseFailed("Failed to extract: \(result.stderr)")
        }
    }

    /// Compress files into an archive (uses cd to parent to avoid nested paths)
    public func compressFiles(
        paths: [String],
        archivePath: String,
        format: ArchiveFormat,
        serverId: String
    ) async throws {
        let safeArchive = escapePath(archivePath)

        let parentDir: String
        if let firstPath = paths.first {
            parentDir = (firstPath as NSString).deletingLastPathComponent
        } else {
            throw SFTPError.parseFailed("No files to compress")
        }
        let safeParent = escapePath(parentDir)
        let relNames = paths.map { escapePath(($0 as NSString).lastPathComponent) }.joined(separator: " ")

        let command: String
        switch format {
        case .zip:
            command = "cd \(safeParent) && zip -r \(safeArchive) \(relNames)"
        case .tarGz:
            command = "cd \(safeParent) && tar -czf \(safeArchive) \(relNames)"
        case .tarBz2:
            command = "cd \(safeParent) && tar -cjf \(safeArchive) \(relNames)"
        case .tarXz:
            command = "cd \(safeParent) && tar -cJf \(safeArchive) \(relNames)"
        }

        let result = try await ssh(command, serverId: serverId)

        guard result.isSuccess else {
            throw SFTPError.parseFailed("Failed to compress: \(result.stderr)")
        }
    }

    /// Check if a file path looks like an archive
    public static func isArchive(_ path: String) -> Bool {
        let lower = path.lowercased()
        return lower.hasSuffix(".zip") || lower.hasSuffix(".tar.gz") || lower.hasSuffix(".tgz")
            || lower.hasSuffix(".tar.bz2") || lower.hasSuffix(".tbz2")
            || lower.hasSuffix(".tar.xz") || lower.hasSuffix(".txz")
            || lower.hasSuffix(".tar") || lower.hasSuffix(".rar") || lower.hasSuffix(".7z")
            || lower.hasSuffix(".gz")
    }

    // MARK: - Symlink

    /// Create a symbolic link
    public func createSymlink(target: String, linkPath: String, serverId: String) async throws {
        let safeTarget = escapePath(target)
        let safeLink = escapePath(linkPath)
        let result = try await ssh("ln -sf \(safeTarget) \(safeLink)", serverId: serverId)
        guard result.isSuccess else {
            throw SFTPError.permissionDenied("Failed to create symlink: \(result.stderr)")
        }
    }
}
