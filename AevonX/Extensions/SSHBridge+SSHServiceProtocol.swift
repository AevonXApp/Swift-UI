//
//  SSHBridge+SSHServiceProtocol.swift
//  AevonX
//
//  Makes SSHBridge conform to AevonXCore.SSHServiceProtocol
//  so CapabilityDetector, strategies, and HookLoader can use Go SSH.
//
//  This extension lives in the APP target (not AevonXCoreBridge)
//  to avoid circular dependency between AevonXCore and AevonXCoreBridge.
//

import Foundation
import AevonXCoreBridge
import AevonXCore

extension SSHBridge: @retroactive AevonXCore.SSHServiceProtocol {

    /// Execute a command via Go SSH, returning AevonXCore.SSHCommandResult.
    public func execute(_ command: String, serverId: String) async throws -> AevonXCore.SSHCommandResult {
        let json = await executeAsyncJSON(serverID: serverId, command: command)

        guard let data = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              result["success"] as? Bool == true,
              let cmdData = result["data"] as? [String: Any] else {
            var errorMsg = "Go SSH command failed"
            if let data = json.data(using: .utf8),
               let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = result["error"] as? String {
                errorMsg = err
            }
            throw AevonXCore.SSHServiceError.commandFailed(errorMsg)
        }

        return AevonXCore.SSHCommandResult(
            stdout: cmdData["stdout"] as? String ?? "",
            stderr: cmdData["stderr"] as? String ?? "",
            exitCode: Int32(cmdData["exit_code"] as? Int ?? -1)
        )
    }

    /// Upload via base64 through Go SSH.
    public func upload(localURL: URL, remotePath: String, serverId: String) async throws {
        let fileData = try Data(contentsOf: localURL)
        let base64 = fileData.base64EncodedString()
        let _ = try await execute("echo '\(base64)' | base64 -d > \(remotePath)", serverId: serverId)
    }

    /// Stream upload — delegates to upload.
    public func streamUpload(localURL: URL, remotePath: String, serverId: String) async throws {
        try await upload(localURL: localURL, remotePath: remotePath, serverId: serverId)
    }

    /// Check connection via Go SSH.
    public func isConnected(serverId: String) async -> Bool {
        isConnected(serverID: serverId)
    }
}
