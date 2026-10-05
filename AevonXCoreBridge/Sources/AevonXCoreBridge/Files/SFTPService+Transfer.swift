//
//  SFTPService+Transfer.swift
//  AevonXCoreBridge
//
//  Extension: File writing, upload, download operations with progress tracking
//

import Foundation

// MARK: - File Transfer Operations

extension SFTPService {

    // MARK: - File Writing

    /// Write content to a remote file (chunked for large content)
    public func writeFile(
        path: String,
        content: String,
        serverId: String
    ) async throws {
        let safePath = escapePath(path)
        let data = Data(content.utf8)
        let base64 = data.base64EncodedString()

        // Chunk size for command line safety (512KB base64 chunks)
        let chunkSize = 524288

        // Create escaped temp file path
        let tempPath = escapePath("\(path).axtmp")

        // Create/truncate the temp file
        let createResult = try await ssh("> \(tempPath)", serverId: serverId)
        guard createResult.isSuccess else {
            throw SFTPError.uploadFailed("Failed to create temp file: \(createResult.stderr)")
        }

        var offset = 0
        while offset < base64.count {
            let nextOffset = min(offset + chunkSize, base64.count)
            let startIdx = base64.index(base64.startIndex, offsetBy: offset)
            let endIdx = base64.index(base64.startIndex, offsetBy: nextOffset)
            let chunk = String(base64[startIdx..<endIdx])

            let writeResult = try await ssh(
                "echo -n '\(chunk)' >> \(tempPath)",
                serverId: serverId
            )

            guard writeResult.isSuccess else {
                _ = try? await ssh("rm -f \(tempPath)", serverId: serverId)
                throw SFTPError.uploadFailed("Failed to write chunk: \(writeResult.stderr)")
            }

            offset = nextOffset
        }

        // Decode temp file to final destination
        let decodeResult = try await ssh(
            "base64 -d \(tempPath) > \(safePath) && rm -f \(tempPath)",
            serverId: serverId
        )

        guard decodeResult.isSuccess else {
            _ = try? await ssh("rm -f \(tempPath)", serverId: serverId)
            throw SFTPError.uploadFailed("Failed to decode/move file: \(decodeResult.stderr)")
        }
    }

    // MARK: - File Upload (with Progress)

    /// Upload a local file to the remote server with progress tracking
    public func uploadFile(
        localURL: URL,
        remotePath: String,
        serverId: String,
        onProgress: @escaping @Sendable (Int64, Int64) -> Void
    ) async throws {
        let data = try Data(contentsOf: localURL)
        let totalBytes = Int64(data.count)
        let base64 = data.base64EncodedString()

        // Chunk size: 512KB base64 chunks
        let chunkSize = 524288

        // Create escaped temp file path
        let tempPath = escapePath("\(remotePath).axtmp")
        let safeRemotePath = escapePath(remotePath)

        // Create/truncate temp file
        _ = try await ssh("> \(tempPath)", serverId: serverId)

        var offset = 0
        while offset < base64.count {
            let nextOffset = min(offset + chunkSize, base64.count)
            let startIdx = base64.index(base64.startIndex, offsetBy: offset)
            let endIdx = base64.index(base64.startIndex, offsetBy: nextOffset)
            let chunk = String(base64[startIdx..<endIdx])

            let writeResult = try await ssh(
                "echo -n '\(chunk)' >> \(tempPath)",
                serverId: serverId
            )

            guard writeResult.isSuccess else {
                _ = try? await ssh("rm -f \(tempPath)", serverId: serverId)
                throw SFTPError.uploadFailed(writeResult.stderr)
            }

            offset = nextOffset
            let approxBytesWritten = Int64(Double(offset) / Double(base64.count) * Double(totalBytes))
            onProgress(approxBytesWritten, totalBytes)
        }

        // Decode temp to final
        let decodeResult = try await ssh(
            "base64 -d \(tempPath) > \(safeRemotePath) && rm -f \(tempPath)",
            serverId: serverId
        )

        guard decodeResult.isSuccess else {
            _ = try? await ssh("rm -f \(tempPath)", serverId: serverId)
            throw SFTPError.uploadFailed(decodeResult.stderr)
        }

        onProgress(totalBytes, totalBytes)
    }

    // MARK: - File Download

    /// Download a remote file to a local URL with progress tracking
    public func downloadFile(
        remotePath: String,
        localURL: URL,
        serverId: String,
        onProgress: @escaping @Sendable (Int64, Int64) -> Void
    ) async throws {
        let safePath = escapePath(remotePath)

        // Get file size first
        let sizeResult = try await ssh(
            "stat -c %s \(safePath) 2>/dev/null || stat -f %z \(safePath)",
            serverId: serverId
        )

        let totalBytes: Int64
        if let sizeStr = sizeResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n").last,
           let size = Int64(sizeStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
            totalBytes = size
        } else {
            totalBytes = 0
        }

        onProgress(0, totalBytes)

        // Read file as base64 in chunks to handle large files
        let chunkSize: Int64 = 786432 // 768KB raw = ~1MB base64
        var allData = Data()
        var offset: Int64 = 0

        while true {
            let readCmd = "dd if=\(safePath) bs=1 skip=\(offset) count=\(chunkSize) 2>/dev/null | base64"
            let result = try await ssh(readCmd, serverId: serverId)

            let cleanBase64 = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")

            guard !cleanBase64.isEmpty, let chunkData = Data(base64Encoded: cleanBase64) else {
                break
            }

            allData.append(chunkData)
            offset += Int64(chunkData.count)
            onProgress(offset, totalBytes)

            if chunkData.count < chunkSize {
                break // Last chunk
            }
        }

        try allData.write(to: localURL)
        onProgress(totalBytes, totalBytes)
    }

    // MARK: - Download from URL

    /// Download a file from a URL directly to the remote server
    public func downloadFromURL(url: String, destPath: String, serverId: String) async throws {
        let safePath = escapePath(destPath)
        let safeURL = "'" + url.replacingOccurrences(of: "'", with: "'\\''") + "'"

        // Try curl first, then fall back to wget
        let result = try await ssh(
            "curl -fsSL -o \(safePath) \(safeURL) 2>&1 || wget -q -O \(safePath) \(safeURL) 2>&1",
            serverId: serverId
        )

        guard result.isSuccess else {
            // Clean up partially downloaded file
            _ = try? await ssh("rm -f \(safePath)", serverId: serverId)
            throw SFTPError.downloadFailed("Failed to download from URL: \(result.stderr)")
        }
    }
}
