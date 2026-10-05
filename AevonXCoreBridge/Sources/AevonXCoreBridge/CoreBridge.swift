//
//  CoreBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper around the Go Core C exports.
//  Provides async, type-safe Swift APIs over the C bridge.
//

import Foundation
import AevonXCoreLib

/// Main bridge to the Go Core engine.
/// Provides Swift-friendly async APIs that delegate to C functions.
public final class CoreBridge: @unchecked Sendable {

    // MARK: - Singleton

    /// Shared instance of the CoreBridge.
    public static let shared = CoreBridge()

    /// Whether the core has been initialized.
    private var isInitialized = false

    private init() {}

    // MARK: - Lifecycle

    /// Initializes the Go Core engine. Must be called once at app launch.
    public func initialize() {
        guard !isInitialized else { return }
        CoreInit()
        isInitialized = true
    }

    /// Returns the Go Core version string.
    public func version() -> String {
        let cStr = CoreVersion()
        defer { CoreFreeString(cStr) }
        return String(cString: cStr!)
    }

    /// Shuts down the Go Core engine. Call on app termination.
    public func shutdown() {
        CoreShutdown()
        isInitialized = false
    }

    // MARK: - Error Reporter

    /// Updates the silent error reporter's auth context.
    /// Call after login to enable authenticated error reporting,
    /// and on logout to clear the context.
    public func setReporterContext(baseURL: String, token: String, deviceID: String) {
        baseURL.withCString { cBase in
            token.withCString { cToken in
                deviceID.withCString { cDevice in
                    CoreSetReporterContext(
                        UnsafeMutablePointer(mutating: cBase),
                        UnsafeMutablePointer(mutating: cToken),
                        UnsafeMutablePointer(mutating: cDevice)
                    )
                }
            }
        }
    }

    // MARK: - SSH

    /// Connects to a remote server via SSH.
    /// - Parameters:
    ///   - serverID: Unique server identifier
    ///   - host: Server hostname or IP
    ///   - port: SSH port (default 22)
    ///   - username: SSH username
    ///   - password: SSH password (optional if using key)
    ///   - privateKey: PEM-encoded private key (optional)
    /// - Returns: Connection result
    public func sshConnect(
        serverID: String,
        host: String,
        port: Int32 = 22,
        username: String,
        password: String = "",
        privateKey: String = "",
        passphrase: String = "",
        catToken: String = "",
        deviceFingerprint: String = ""
    ) async throws -> BridgeResponse {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = withCArgs { c in
                    SSHConnect(
                        c.str(serverID),
                        c.str(host),
                        port,
                        c.str(username),
                        c.str(password),
                        c.str(privateKey),
                        c.str(passphrase),
                        c.str(catToken),
                        c.str(deviceFingerprint)
                    )
                }
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseResponse(result)
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Executes a command on a connected server.
    /// - Parameters:
    ///   - command: The command to execute
    ///   - serverID: The server to execute on
    /// - Returns: Command result with stdout, stderr, and exit code
    public func sshExecute(
        _ command: String,
        serverID: String
    ) async throws -> SSHCommandResult {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = withCArgs { c in
                    SSHExecute(
                        c.str(serverID),
                        c.str(command)
                    )
                }
                defer { CoreFreeString(result) }

                do {
                    let response = try self.parseResponse(result)
                    guard response.success,
                          let data = response.data else {
                        throw CoreBridgeError.executionFailed(
                            response.error ?? "Unknown error"
                        )
                    }

                    let cmdResult = try JSONDecoder().decode(
                        SSHCommandResult.self,
                        from: data
                    )
                    continuation.resume(returning: cmdResult)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Disconnects from a server.
    /// - Parameter serverID: The server to disconnect from
    public func sshDisconnect(serverID: String) {
        withCArgs { c in SSHDisconnect(c.str(serverID)) }
    }

    /// Checks if a server has an active SSH connection.
    /// - Parameter serverID: The server to check
    /// - Returns: true if connected
    public func sshIsConnected(serverID: String) -> Bool {
        return withCArgs { c in SSHIsConnected(c.str(serverID)) == 1 }
    }

    // MARK: - Feature Permits (Ed25519)

    /// Verifies an Ed25519-signed feature permit from the backend.
    /// Uses the same public key as CAT verification (embedded in Go Core).
    /// - Parameters:
    ///   - permitB64: Base64url-encoded permit JSON
    ///   - signatureB64: Base64url-encoded Ed25519 signature
    ///   - deviceID: SHA-256 hash of device's IOPlatformUUID
    /// - Returns: JSON result string from Go Core
    public func verifyFeaturePermit(permitB64: String, signatureB64: String, deviceID: String) -> String {
        return withCArgs { c in
            let result = APIVerifyFeaturePermit(c.str(permitB64), c.str(signatureB64), c.str(deviceID))
            defer { CoreFreeString(result) }
            return String(cString: result!)
        }
    }

    private func parseResponse(_ cStr: UnsafeMutablePointer<CChar>?) throws -> BridgeResponse {
        guard let cStr = cStr else {
            throw CoreBridgeError.nullResponse
        }

        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8) else {
            throw CoreBridgeError.invalidJSON
        }

        return try JSONDecoder().decode(BridgeResponse.self, from: data)
    }
}
