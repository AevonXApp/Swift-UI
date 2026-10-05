//
//  SFTPService.swift
//  AevonXCoreBridge
//
//  SSH-based remote file manager — listing, reading, writing, disk usage, quick access.
//  Replaces AevonXCore's SFTPFileManager using Go-backed SSHBridge.
//
//  Extensions:
//    - SFTPService+Operations.swift  (CRUD, chmod, chown, symlink, archive, search)
//    - SFTPService+Transfer.swift    (upload, download, downloadFromURL)
//

import Foundation

// MARK: - SFTP Service

/// Remote file management service using Go-backed SSH
public actor SFTPService {

    // MARK: - Singleton

    public static let shared = SFTPService()

    private init() {}

    // MARK: - Directory Listing

    /// List files and directories at the given path
    public func listDirectory(
        path: String,
        serverId: String,
        showHidden: Bool = true
    ) async throws -> [RemoteFileItem] {
        let safePath = escapePath(path)

        // Use ls -la with full-iso time format for precise timestamps
        let flags = showHidden ? "-la" : "-l"
        let command = "LC_ALL=C ls \(flags) --full-time \(safePath) 2>/dev/null || LC_ALL=C ls \(flags) \(safePath)"

        let result = try await ssh(command, serverId: serverId)

        guard result.isSuccess else {
            if result.stderr.contains("Permission denied") {
                throw SFTPError.permissionDenied(path)
            }
            if result.stderr.contains("No such file or directory") {
                throw SFTPError.fileNotFound(path)
            }
            throw SFTPError.parseFailed(result.stderr)
        }

        return parseDirectoryListing(result.stdout, basePath: path)
    }

    // MARK: - File Reading

    /// Read a file's content as a string
    public func readFile(
        path: String,
        serverId: String,
        maxSize: Int64 = 10_485_760
    ) async throws -> String {
        let safePath = escapePath(path)

        // Check file size first
        let sizeResult = try await ssh(
            "stat -c %s \(safePath) 2>/dev/null || stat -f %z \(safePath)",
            serverId: serverId
        )

        if let sizeStr = sizeResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n").last,
           let size = Int64(sizeStr.trimmingCharacters(in: .whitespacesAndNewlines)),
           size > maxSize {
            throw SFTPError.fileTooLarge(size)
        }

        // Read via base64 to safely handle binary-ish content
        let readResult = try await ssh("base64 \(safePath)", serverId: serverId)

        guard readResult.isSuccess else {
            if readResult.stderr.contains("Permission denied") {
                throw SFTPError.permissionDenied(path)
            }
            if readResult.stderr.contains("No such file") {
                throw SFTPError.fileNotFound(path)
            }
            throw SFTPError.parseFailed(readResult.stderr)
        }

        let cleanBase64 = readResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")

        guard let data = Data(base64Encoded: cleanBase64),
              let content = String(data: data, encoding: .utf8) else {
            throw SFTPError.parseFailed("Failed to decode file content")
        }

        return content
    }

    // MARK: - Get Disk Usage

    /// Get disk usage for a path
    public func getDiskUsage(path: String, serverId: String) async throws -> String {
        let safePath = escapePath(path)
        let result = try await ssh("du -sh \(safePath) 2>/dev/null | cut -f1", serverId: serverId)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Quick Access Paths

    /// Get common server paths for quick navigation
    public func getQuickAccessPaths(serverId: String) async -> [(icon: String, title: String, path: String)] {
        var paths: [(icon: String, title: String, path: String)] = [
            ("house", "Home", "/root"),
            ("desktopcomputer", "Root", "/"),
            ("globe", "Web Root", "/var/www"),
            ("doc.text.below.ecg", "Logs", "/var/log"),
            ("gearshape", "Config", "/etc"),
            ("externaldrive", "Tmp", "/tmp"),
        ]

        // Try to detect actual home directory
        if let result = try? await ssh("echo $HOME", serverId: serverId) {
            let home = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if !home.isEmpty {
                paths[0] = ("house", "Home", home)
            }
        }

        // Try to detect web root
        if let result = try? await ssh(
            "test -d /var/www/html && echo /var/www/html || echo /var/www", serverId: serverId
        ) {
            let webRoot = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if !webRoot.isEmpty {
                paths[2] = ("globe", "Web Root", webRoot)
            }
        }

        return paths
    }

    // MARK: - SSH Execution Helper

    /// Execute a command via Go SSH bridge and return parsed result
    func ssh(_ command: String, serverId: String) async throws -> SSHResult {
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: command)
        return SSHResult.parse(json)
    }

    // MARK: - Parsing Helpers

    /// Parse `ls -la` output into RemoteFileItem array
    func parseDirectoryListing(_ output: String, basePath: String) -> [RemoteFileItem] {
        let lines = output.components(separatedBy: "\n")
        var items: [RemoteFileItem] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("total "),
                  !trimmed.hasSuffix(" ."),
                  !trimmed.hasSuffix(" ..") else {
                continue
            }

            if let item = parseLsLine(trimmed, basePath: basePath) {
                items.append(item)
            }
        }

        return items
    }

    /// Parse a single `ls -la` line
    private func parseLsLine(_ line: String, basePath: String) -> RemoteFileItem? {
        let components = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)

        guard components.count >= 9 else { return nil }

        let permStr = components[0]
        guard permStr.count >= 10 else { return nil }

        let permissions = FilePermissions.fromSymbolic(permStr)
        let isDirectory = permStr.hasPrefix("d")
        let isSymlink = permStr.hasPrefix("l")
        let owner = components[2]
        let group = components[3]
        let size = Int64(components[4]) ?? 0

        // Parse date
        var nameStartIndex = 8
        var modifiedDate = Date()

        if components.count >= 9, components[5].contains("-"), components[5].count == 10 {
            let dateStr = "\(components[5]) \(components[6])"
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")

            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"
            if let date = formatter.date(from: dateStr) {
                modifiedDate = date
            } else {
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let shortDateStr = String(dateStr.prefix(19))
                if let date = formatter.date(from: shortDateStr) {
                    modifiedDate = date
                }
            }

            if components.count > 8, components[7].hasPrefix("+") || components[7].hasPrefix("-") {
                nameStartIndex = 8
            } else {
                nameStartIndex = 7
            }
        } else {
            nameStartIndex = 8
        }

        guard components.count > nameStartIndex else { return nil }
        var name = components[nameStartIndex...].joined(separator: " ")

        // Handle symlinks
        var symlinkTarget: String? = nil
        if isSymlink, let arrowRange = name.range(of: " -> ") {
            symlinkTarget = String(name[arrowRange.upperBound...])
            name = String(name[..<arrowRange.lowerBound])
        }

        guard name != "." && name != ".." else { return nil }

        let normalizedBase = basePath.hasSuffix("/") ? String(basePath.dropLast()) : basePath
        let fullPath = "\(normalizedBase)/\(name)"

        return RemoteFileItem(
            name: name,
            path: fullPath,
            isDirectory: isDirectory,
            isSymlink: isSymlink,
            symlinkTarget: symlinkTarget,
            size: size,
            permissions: permissions,
            owner: owner,
            group: group,
            modifiedDate: modifiedDate,
            isHidden: name.hasPrefix(".")
        )
    }

    /// Safely escape a path for shell commands
    func escapePath(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
