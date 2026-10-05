//
//  SSHBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core SSH operations.
//  Covers: types, classifier, output parsing, systemctl commands, model decode.
//

import Foundation
import AevonXCoreLib

public final class SSHBridge: @unchecked Sendable {

    public static let shared = SSHBridge()
    private init() {}

    // MARK: - Types & Config

    public func getConnectionStages() -> String {
        extract(SSHGetConnectionStages())
    }

    public func getSupportedKeyFormats() -> String {
        extract(SSHGetSupportedKeyFormats())
    }

    public func getReconnectionConfig() -> String {
        extract(SSHGetReconnectionConfig())
    }

    // MARK: - Classifier

    public func isBenignCommand(_ command: String) -> String {
        withCArgs { c in extract(SSHIsBenignCommand(c.str(command))) }
    }

    public func isRetryableError(_ errMsg: String) -> String {
        withCArgs { c in extract(SSHIsRetryableError(c.str(errMsg))) }
    }

    public func isConnectionError(_ errMsg: String) -> String {
        withCArgs { c in extract(SSHIsConnectionError(c.str(errMsg))) }
    }

    public func isNoisyCommand(_ command: String) -> String {
        withCArgs { c in extract(SSHIsNoisyCommand(c.str(command))) }
    }

    public func shouldAutoHealApt(command: String, stderr: String, exitCode: Int32) -> String {
        withCArgs { c in extract(SSHShouldAutoHealApt(c.str(command), c.str(stderr), exitCode)) }
    }

    public func getAptRepairCommand() -> String {
        extract(SSHGetAptRepairCommand())
    }

    // MARK: - Output Parsing

    public func parseLines(stdout: String) -> String {
        withCArgs { c in extract(SSHParseLines(c.str(stdout))) }
    }

    public func parseTableRows(stdout: String) -> String {
        withCArgs { c in extract(SSHParseTableRows(c.str(stdout))) }
    }

    public func parsePipeSeparated(stdout: String) -> String {
        withCArgs { c in extract(SSHParsePipeSeparated(c.str(stdout))) }
    }

    public func firstLine(stdout: String) -> String {
        withCArgs { c in extract(SSHFirstLine(c.str(stdout))) }
    }

    // MARK: - Systemctl Commands

    public func cmdSystemctl(action: String, service: String) -> String {
        withCArgs { c in extract(SSHCmdSystemctl(c.str(action), c.str(service))) }
    }

    public func cmdBinaryExists(binary: String) -> String {
        withCArgs { c in extract(SSHCmdBinaryExists(c.str(binary))) }
    }

    public func cmdPathExists(path: String) -> String {
        withCArgs { c in extract(SSHCmdPathExists(c.str(path))) }
    }

    // MARK: - Model Decode

    public func decodeCommandResult(json: String) -> String {
        withCArgs { c in extract(SSHDecodeCommandResult(c.str(json))) }
    }

    public func decodeTestResult(json: String) -> String {
        withCArgs { c in extract(SSHDecodeTestResult(c.str(json))) }
    }

    public func decodeConnectionMetadata(json: String) -> String {
        withCArgs { c in extract(SSHDecodeConnectionMetadata(c.str(json))) }
    }

    // MARK: - Helpers

    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        return String(cString: cStr)
    }

    // MARK: - Runtime Configuration

    /// Push network settings to the Go SSH client.
    /// Call whenever the user changes network/proxy/SSH settings.
    public func applySettings(
        connectionTimeout: Int,
        keepAliveInterval: Int,
        maxRetries: Int,
        sshCompression: Bool,
        strictHostKeyChecking: Bool,
        useProxy: Bool,
        proxyHost: String,
        proxyPort: Int,
        proxyType: String,
        autoDisconnectIdle: Bool,
        idleTimeout: Int
    ) {
        let config: [String: Any] = [
            "connectionTimeout": connectionTimeout,
            "keepAliveInterval": keepAliveInterval,
            "maxRetries": maxRetries,
            "sshCompression": sshCompression,
            "strictHostKeyChecking": strictHostKeyChecking,
            "useProxy": useProxy,
            "proxyHost": proxyHost,
            "proxyPort": proxyPort,
            "proxyType": proxyType,
            "autoDisconnectIdle": autoDisconnectIdle,
            "idleTimeout": idleTimeout,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: config),
              let json = String(data: data, encoding: .utf8) else { return }

        withCArgs { c in
            SSHSetConfig(c.str(json))
        }
    }

    // MARK: - SSH Connection Operations (Async)
    // These wrap the CGo exports from exports.go: SSHConnect, SSHExecute, etc.
    // All run on background threads to avoid blocking the @MainActor UI.

    /// Run a synchronous CGo call on a background thread.
    private func background(_ work: @escaping @Sendable () -> String) async -> String {
        await Task.detached(priority: .userInitiated) { work() }.value
    }

    /// Test SSH connectivity WITHOUT CAT validation.
    /// Used by "Add Server" wizard — server isn't registered yet, so no CAT exists.
    /// The Go Core connects, verifies auth, and immediately disconnects.
    /// Returns JSON: `{"success":true,"data":{"connected":true,"fingerprint":"..."}}`
    public func testConnectAsync(
        host: String,
        port: Int32,
        username: String,
        password: String,
        privateKey: String = "",
        passphrase: String = ""
    ) async -> String {
        await background { [self] in
            withCArgs { c in
                extract(SSHTestConnect(
                    c.str(host),
                    port,
                    c.str(username),
                    c.str(password),
                    c.str(privateKey),
                    c.str(passphrase)
                ))
            }
        }
    }

    /// Connect to a remote server via Go SSH client.
    /// REQUIRES a valid CAT token from the backend — Go Core validates before connecting.
    /// Returns JSON: `{"success":true,"data":{"server_id":"...","connected":true}}`
    public func connectAsync(
        serverID: String,
        host: String,
        port: Int32,
        username: String,
        password: String,
        privateKey: String = "",
        passphrase: String = "",
        catToken: String,
        deviceFingerprint: String
    ) async -> String {
        await background { [self] in
            withCArgs { c in
                extract(SSHConnect(
                    c.str(serverID),
                    c.str(host),
                    port,
                    c.str(username),
                    c.str(password),
                    c.str(privateKey),
                    c.str(passphrase),
                    c.str(catToken),
                    c.str(deviceFingerprint)
                ))
            }
        }
    }

    /// Execute a command on a connected server.
    /// Returns just the stdout string extracted from Go Core's JSON response.
    /// If JSON parsing fails, returns the raw response string as fallback.
    public func executeAsync(serverID: String, command: String) async -> String {
        let raw = await background { [self] in
            withCArgs { c in extract(SSHExecute(c.str(serverID), c.str(command))) }
        }
        return extractStdout(from: raw)
    }

    /// Execute a command and return the FULL JSON response from Go Core.
    /// Use this when you need access to stderr, exit_code, or the raw JSON structure.
    /// Returns: `{"success":true,"data":{"stdout":"...","stderr":"...","exit_code":0}}`
    public func executeAsyncJSON(serverID: String, command: String) async -> String {
        await background { [self] in
            withCArgs { c in extract(SSHExecute(c.str(serverID), c.str(command))) }
        }
    }

    /// Execute synchronously. Returns just stdout.
    public func execute(serverID: String, command: String) -> String {
        let raw = withCArgs { c in extract(SSHExecute(c.str(serverID), c.str(command))) }
        return extractStdout(from: raw)
    }

    /// Extract stdout from Go Core's JSON SSH response.
    /// Input:  `{"success":true,"data":{"stdout":"hello\n","stderr":"","exit_code":0}}`
    /// Output: `"hello\n"`
    private func extractStdout(from json: String) -> String {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = obj["data"] as? [String: Any],
              let stdout = inner["stdout"] as? String else {
            // Fallback: return raw string (might already be plain text)
            return json
        }
        return stdout
    }

    /// Get the host/IP for a connected server.
    public func getHost(serverID: String) -> String {
        let c = strdup(serverID)
        defer { free(c) }
        let cStr = SSHGetHost(c)
        guard let cStr = cStr else { return "" }
        defer { free(cStr) }
        return String(cString: cStr)
    }

    /// Disconnect from a server.
    public func disconnect(serverID: String) {
        let c = strdup(serverID)
        defer { free(c) }
        SSHDisconnect(c)
    }

    /// Check if a server is connected.
    public func isConnected(serverID: String) -> Bool {
        let c = strdup(serverID)
        defer { free(c) }
        return SSHIsConnected(c) == 1
    }

    /// Get all active session info.
    public func activeSessions() -> String {
        extract(SSHActiveSessions())
    }

    // MARK: - Batch Execution

    /// Execute multiple commands in a single SSH session.
    /// Input: array of (label, command) tuples.
    /// Returns: dictionary of label → stdout string.
    public func batchExecuteAsync(serverID: String, commands: [(label: String, command: String)]) async -> [String: String] {
        let jsonArray = commands.map { ["label": $0.label, "command": $0.command] }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            return [:]
        }

        let raw = await background { [self] in
            withCArgs { c in extract(SSHBatchExecute(c.str(serverID), c.str(jsonStr))) }
        }

        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              obj["success"] as? Bool == true,
              let results = obj["data"] as? [String: String] else {
            return [:]
        }
        return results
    }

    // MARK: - Host Key TOFU

    /// Pre-load a known host key fingerprint (from Keychain) before connecting.
    /// Prevents TOFU prompt for servers already verified.
    public func trustHostKey(hostPort: String, fingerprint: String) {
        withCArgs { c in
            SSHHostKeyTrust(c.str(hostPort), c.str(fingerprint))
        }
    }

    /// Remove a stored host key fingerprint (for re-trusting after key rotation).
    public func removeHostKey(hostPort: String) {
        withCArgs { c in
            SSHHostKeyRemove(c.str(hostPort))
        }
    }

    /// Get all stored host key fingerprints.
    public func allHostKeys() -> [String: String] {
        let json = extract(SSHHostKeyGetAll())
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              resp["success"] as? Bool == true,
              let keys = resp["data"] as? [String: String] else {
            return [:]
        }
        return keys
    }
}

// MARK: - SSHServiceProtocol Conformance

extension SSHBridge: SSHServiceProtocol {

    /// Execute a command and return a typed `SSHCommandResult`.
    public func execute(_ command: String, serverId: String) async throws -> SSHCommandResult {
        let json = await executeAsyncJSON(serverID: serverId, command: command)

        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              obj["success"] as? Bool == true,
              let cmdData = obj["data"] as? [String: Any] else {
            var errorMsg = "Go SSH command failed"
            if let data = json.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = obj["error"] as? String {
                errorMsg = err
            }
            throw SSHServiceError.commandFailed(errorMsg)
        }

        return SSHCommandResult(
            stdout: cmdData["stdout"] as? String ?? "",
            stderr: cmdData["stderr"] as? String ?? "",
            exitCode: cmdData["exit_code"] as? Int ?? -1
        )
    }

    /// Upload a local file to a remote server via SSH base64 chunked transfer.
    public func upload(localURL: URL, remotePath: String, serverId: String) async throws {
        let dir = (remotePath as NSString).deletingLastPathComponent
        _ = try await execute("mkdir -p '\(dir)'", serverId: serverId)

        let fileData = try Data(contentsOf: localURL)
        let chunkSize = 64 * 1024 // 64KB — smaller to avoid stressing SSH
        let totalChunks = (fileData.count + chunkSize - 1) / chunkSize

        for i in 0..<totalChunks {
            let start = i * chunkSize
            let end = min(start + chunkSize, fileData.count)
            let chunk = fileData[start..<end]
            let b64 = chunk.base64EncodedString()
            let op = i == 0 ? ">" : ">>"
            _ = try await execute("echo '\(b64)' | base64 -d \(op) '\(remotePath)'", serverId: serverId)
        }
    }

    /// Stream-upload (currently uses the same base64 chunked approach).
    public func streamUpload(localURL: URL, remotePath: String, serverId: String) async throws {
        try await upload(localURL: localURL, remotePath: remotePath, serverId: serverId)
    }

    /// Check if connected to the given server.
    public func isConnected(serverId: String) async -> Bool {
        isConnected(serverID: serverId)
    }
}

