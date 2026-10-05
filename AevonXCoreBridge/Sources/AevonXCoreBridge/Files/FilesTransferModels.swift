//
//  FilesTransferModels.swift
//  AevonXCoreBridge
//
//  Transfer, tab, clipboard, sort, error, and archive models for file management.
//  Migrated from AevonXCore to enable Go-backed file operations.
//

import Foundation

// MARK: - File Transfer Progress

/// Tracks the progress of a file upload or download
public struct FileTransferProgress: Identifiable, Sendable {
    public let id: String
    public let fileName: String
    public let totalBytes: Int64
    public var bytesTransferred: Int64
    public var state: TransferState
    public var error: String?

    public init(
        id: String = UUID().uuidString,
        fileName: String,
        totalBytes: Int64,
        bytesTransferred: Int64 = 0,
        state: TransferState = .pending
    ) {
        self.id = id
        self.fileName = fileName
        self.totalBytes = totalBytes
        self.bytesTransferred = bytesTransferred
        self.state = state
    }

    /// Transfer completion percentage (0.0 - 1.0)
    public var percentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesTransferred) / Double(totalBytes)
    }

    /// Human-readable transferred / total
    public var progressText: String {
        let transferred = ByteCountFormatter.string(fromByteCount: bytesTransferred, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(transferred) / \(total)"
    }

    public enum TransferState: String, Sendable {
        case pending
        case transferring
        case completed
        case failed
        case cancelled
    }
}

// MARK: - File Browser Tab State

/// State for a single file browser tab (supports multi-tab navigation)
public struct FileBrowserTabState: Identifiable, Sendable {
    public let id: String
    public var title: String
    public var currentPath: String
    public var pathHistory: [String]
    public var historyIndex: Int

    public init(
        id: String = UUID().uuidString,
        title: String = "Files",
        currentPath: String = "/root",
        pathHistory: [String] = ["/root"],
        historyIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.currentPath = currentPath
        self.pathHistory = pathHistory
        self.historyIndex = historyIndex
    }

    public var canGoBack: Bool {
        historyIndex > 0
    }

    public var canGoForward: Bool {
        historyIndex < pathHistory.count - 1
    }

    public mutating func navigateTo(_ path: String) {
        if historyIndex < pathHistory.count - 1 {
            pathHistory = Array(pathHistory[0...historyIndex])
        }
        pathHistory.append(path)
        historyIndex = pathHistory.count - 1
        currentPath = path
        title = (path as NSString).lastPathComponent
        if title.isEmpty { title = "/" }
    }

    public mutating func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        currentPath = pathHistory[historyIndex]
        title = (currentPath as NSString).lastPathComponent
        if title.isEmpty { title = "/" }
    }

    public mutating func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        currentPath = pathHistory[historyIndex]
        title = (currentPath as NSString).lastPathComponent
        if title.isEmpty { title = "/" }
    }
}

// MARK: - File Clipboard

/// Clipboard state for copy/cut/paste operations
public struct FileClipboard: Sendable {
    public let files: [RemoteFileItem]
    public let isCut: Bool

    public init(files: [RemoteFileItem], isCut: Bool) {
        self.files = files
        self.isCut = isCut
    }
}

// MARK: - Sort Options

/// Sorting options for file listing
public enum FileSortOrder: String, CaseIterable, Sendable {
    case nameAscending = "Name ↑"
    case nameDescending = "Name ↓"
    case sizeAscending = "Size ↑"
    case sizeDescending = "Size ↓"
    case dateAscending = "Date ↑"
    case dateDescending = "Date ↓"
    case typeAscending = "Type ↑"

    /// Sort file items (directories first)
    public func sort(_ items: [RemoteFileItem]) -> [RemoteFileItem] {
        let dirs = items.filter { $0.isDirectory }
        let files = items.filter { !$0.isDirectory }

        let sortedDirs: [RemoteFileItem]
        let sortedFiles: [RemoteFileItem]

        switch self {
        case .nameAscending:
            sortedDirs = dirs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedFiles = files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            sortedDirs = dirs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
            sortedFiles = files.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .sizeAscending:
            sortedDirs = dirs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedFiles = files.sorted { $0.size < $1.size }
        case .sizeDescending:
            sortedDirs = dirs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedFiles = files.sorted { $0.size > $1.size }
        case .dateAscending:
            sortedDirs = dirs.sorted { $0.modifiedDate < $1.modifiedDate }
            sortedFiles = files.sorted { $0.modifiedDate < $1.modifiedDate }
        case .dateDescending:
            sortedDirs = dirs.sorted { $0.modifiedDate > $1.modifiedDate }
            sortedFiles = files.sorted { $0.modifiedDate > $1.modifiedDate }
        case .typeAscending:
            sortedDirs = dirs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedFiles = files.sorted { $0.fileExtension < $1.fileExtension }
        }

        return sortedDirs + sortedFiles
    }
}

// MARK: - Archive Format

/// Supported archive formats for compress operations
public enum ArchiveFormat: String, CaseIterable, Sendable {
    case zip = "zip"
    case tarGz = "tar.gz"
    case tarBz2 = "tar.bz2"
    case tarXz = "tar.xz"

    public var displayName: String {
        switch self {
        case .zip: return "ZIP"
        case .tarGz: return "TAR.GZ"
        case .tarBz2: return "TAR.BZ2"
        case .tarXz: return "TAR.XZ"
        }
    }

    public var fileExtension: String { rawValue }
}

// MARK: - SFTP Error

/// Errors specific to SFTP/file operations
public enum SFTPError: Error, LocalizedError, Sendable {
    case permissionDenied(String)
    case fileNotFound(String)
    case directoryNotEmpty(String)
    case diskFull
    case connectionLost
    case invalidPath(String)
    case fileTooLarge(Int64)
    case uploadFailed(String)
    case downloadFailed(String)
    case operationCancelled
    case parseFailed(String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let path): return "Permission denied: \(path)"
        case .fileNotFound(let path): return "File not found: \(path)"
        case .directoryNotEmpty(let path): return "Directory not empty: \(path)"
        case .diskFull: return "Disk is full"
        case .connectionLost: return "SSH connection lost"
        case .invalidPath(let path): return "Invalid path: \(path)"
        case .fileTooLarge(let size):
            return "File too large: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))"
        case .uploadFailed(let reason): return "Upload failed: \(reason)"
        case .downloadFailed(let reason): return "Download failed: \(reason)"
        case .operationCancelled: return "Operation cancelled"
        case .parseFailed(let detail): return "Failed to parse: \(detail)"
        }
    }
}
