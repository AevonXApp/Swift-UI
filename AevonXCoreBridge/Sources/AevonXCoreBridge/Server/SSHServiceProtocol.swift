//
//  SSHServiceProtocol.swift
//  AevonXCoreBridge
//
//  Protocol extraction for SSHService enabling dependency injection and testability.
//  All adapters and managers should depend on this protocol, not the concrete SSHService.
//

import Foundation

// MARK: - SSH Service Protocol

/// Protocol defining the SSH execution capabilities required by adapters and managers.
///
/// **Architecture**: This protocol enables:
/// - Dependency injection (pass mock for testing)
/// - Decoupling adapters from the concrete SSHService singleton
/// - Future support for alternative SSH implementations
///
/// All remote adapters and managers MUST depend on this protocol,
/// never on `SSHService` directly.
public protocol SSHServiceProtocol: Sendable {
    
    /// Execute a command on a remote server.
    /// - Parameters:
    ///   - command: The shell command to execute
    ///   - serverId: The target server identifier
    /// - Returns: The command result containing stdout, stderr, and exit code
    func execute(_ command: String, serverId: String) async throws -> SSHCommandResult
    
    /// Upload a local file to a remote server.
    /// - Parameters:
    ///   - localURL: Local file URL to upload
    ///   - remotePath: Destination path on the remote server
    ///   - serverId: The target server identifier
    func upload(localURL: URL, remotePath: String, serverId: String) async throws
    
    /// Stream-upload a local file via a single SSH channel (fast binary transfer).
    /// Falls back to the legacy chunked base64 upload on failure.
    func streamUpload(localURL: URL, remotePath: String, serverId: String) async throws
    
    /// Check if currently connected to a server.
    /// - Parameter serverId: The server identifier
    /// - Returns: True if an active SSH session exists for this server
    func isConnected(serverId: String) async -> Bool
}

// NOTE: SSHBridge conformance to SSHServiceProtocol is provided
// by the app layer in SSHBridge+SSHServiceProtocol.swift

// MARK: - SSH Command Helpers

/// Common SSH command patterns used across adapters.
///
/// These helpers use `ShellSanitizer` for safe command construction
/// and reduce boilerplate in adapter implementations.
public extension SSHServiceProtocol {
    
    /// Execute a command and return trimmed stdout.
    /// - Parameters:
    ///   - command: The shell command
    ///   - serverId: The server identifier
    /// - Returns: Trimmed stdout output
    func executeAndTrim(_ command: String, serverId: String) async throws -> String {
        let result = try await execute(command, serverId: serverId)
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Execute a command and check if it succeeds (exit code 0).
    /// - Parameters:
    ///   - command: The shell command
    ///   - serverId: The server identifier
    /// - Returns: True if exit code is 0
    func executeSucceeds(_ command: String, serverId: String) async throws -> Bool {
        let result = try await execute(command, serverId: serverId)
        return result.isSuccess
    }
    
    /// Check if a binary exists on the remote server.
    /// - Parameters:
    ///   - binary: Binary name or path
    ///   - serverId: The server identifier
    /// - Returns: True if the binary is found
    func binaryExists(_ binary: String, serverId: String) async throws -> Bool {
        let safeBinary = ShellSanitizer.sanitizeIdentifier(binary)
        let result = try await execute("command -v \(safeBinary) >/dev/null 2>&1 && echo 'found' || echo 'notfound'", serverId: serverId)
        return result.stdout.contains("found")
    }
    
    /// Check if a file or directory exists on the remote server.
    /// - Parameters:
    ///   - path: The path to check
    ///   - serverId: The server identifier
    /// - Returns: True if the path exists
    func pathExists(_ path: String, serverId: String) async throws -> Bool {
        let safePath = ShellSanitizer.escapePath(path)
        let result = try await execute("test -e \(safePath) && echo 'exists' || echo 'missing'", serverId: serverId)
        return result.stdout.contains("exists")
    }
}
