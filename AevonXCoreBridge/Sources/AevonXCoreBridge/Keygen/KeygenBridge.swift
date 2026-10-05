//
//  KeygenBridge.swift
//  AevonXCoreBridge
//
//  Thin Swift wrapper around Go bridge/exports_keygen.go.
//
//  All cryptographic generation, command-string assembly and parsing
//  happens in Go. This file's job is exclusively:
//   1. Forward calls into Go via CGo
//   2. Decode the JSON response into Codable models
//
//  No SSH commands or shell strings are constructed in Swift.
//

import Foundation
import AevonXCoreLib

// MARK: - KeygenBridge

/// Bridge for SSH key generation, public-key injection command builders,
/// and SSH port detection.
public final class KeygenBridge: @unchecked Sendable {

    public static let shared = KeygenBridge()
    private init() {}

    // MARK: - Local Generation

    /// Generates a new SSH key pair locally on this device.
    ///
    /// The generated `privateKey` should be persisted via
    /// `KeygenKeyStorage.shared.save(...)` and then dropped from memory.
    public func generate(
        type: KeygenType,
        comment: String,
        passphrase: String
    ) async throws -> KeygenKeyPair {
        try await runOffMain { [self] in
            let response = withCArgs { c in
                KeygenGenerateLocal(
                    c.str(type.rawValue),
                    c.str(comment),
                    c.str(passphrase)
                )
            }
            return try self.decode(response, as: KeygenKeyPair.self)
        }
    }

    // MARK: - Inject / Verify / Remove (command builders)

    /// Returns the shell command that appends `publicKey` to authorized_keys
    /// idempotently. Execute it via `SSHBridge.shared.executeAsync(...)`.
    public func injectPublicKeyCmd(home: String, publicKey: String) -> String {
        commandString { c in
            KeygenInjectPublicKeyCmd(c.str(home), c.str(publicKey))
        }
    }

    /// Returns the shell command that prints `VERIFY_OK` if the key is
    /// currently present in authorized_keys, else `VERIFY_MISSING`.
    public func verifyKeyInjectedCmd(home: String, publicKey: String) -> String {
        commandString { c in
            KeygenVerifyKeyInjectedCmd(c.str(home), c.str(publicKey))
        }
    }

    /// Returns the shell command that removes every authorized_keys entry
    /// matching the given SHA256 fingerprint (server-side `ssh-keygen -lf`
    /// match — comments cannot fool it).
    public func removeKeyByFingerprintCmd(home: String, fingerprint: String) -> String {
        commandString { c in
            KeygenRemoveKeyByFingerprintCmd(c.str(home), c.str(fingerprint))
        }
    }

    // MARK: - Multi-Key Listing

    /// Returns the shell command that emits every `~/.ssh/*.pub` file plus
    /// the contents of `authorized_keys`, with section delimiters that
    /// `parseAllKeys(output:)` understands.
    public func listAllKeysCmd(home: String) -> String {
        commandString { c in
            KeygenListAllKeysCmd(c.str(home))
        }
    }

    /// Parses the output of `listAllKeysCmd` into structured entries.
    /// Always returns a non-nil array (empty on parse failure).
    public func parseAllKeys(output: String) -> [KeygenAuthorizedKey] {
        guard let ptr = withCArgs({ c in KeygenParseAllKeys(c.str(output)) }) else {
            return []
        }
        defer { CoreFreeString(ptr) }

        struct Wrapper: Codable { let keys: [KeygenAuthorizedKey] }
        do {
            let wrapped = try Self.decodeData(ptr, as: Wrapper.self)
            return wrapped.keys
        } catch {
            return []
        }
    }

    // MARK: - SSH Port Detection

    /// Returns the shell command that runs the three-probe SSH-port detection.
    /// Pass an empty string for `configPath` to default to `/etc/ssh/sshd_config`.
    public func sshPortDetectCmd(configPath: String) -> String {
        commandString { c in
            KeygenSSHPortDetectCmd(c.str(configPath))
        }
    }

    /// Parses the detection output and returns the chosen port + the probe
    /// that supplied it. Falls back to port=22 if no probe answered.
    public func parseSSHPort(output: String) -> KeygenPortDetection {
        guard let ptr = withCArgs({ c in KeygenSSHPortParse(c.str(output)) }) else {
            return KeygenPortDetection(port: 22, method: .fallback, raw: "")
        }
        defer { CoreFreeString(ptr) }
        do {
            return try Self.decodeData(ptr, as: KeygenPortDetection.self)
        } catch {
            return KeygenPortDetection(port: 22, method: .fallback, raw: "")
        }
    }

    // MARK: - Fingerprint Helper

    /// Computes the SHA256 fingerprint of a single OpenSSH-format public
    /// key line. Returns an empty string when the line cannot be parsed.
    public func fingerprint(forPublicKeyLine line: String) -> String {
        guard let ptr = withCArgs({ c in KeygenFingerprint(c.str(line)) }) else { return "" }
        defer { CoreFreeString(ptr) }
        struct Wrapper: Codable { let fingerprint: String }
        return (try? Self.decodeData(ptr, as: Wrapper.self).fingerprint) ?? ""
    }

    // MARK: - One-shot Test Execute

    /// Connects to an UNREGISTERED server with the supplied credentials,
    /// runs a single command, and disconnects. Used during the Add-Server
    /// wizard to inject the freshly-generated public key before the server
    /// is persisted (and therefore before any CAT exists).
    ///
    /// Returns the parsed `SSHCommandResult` (stdout/stderr/exitCode).
    public func testExecute(
        host: String,
        port: Int,
        username: String,
        password: String,
        privateKey: String,
        passphrase: String,
        command: String
    ) async throws -> SSHCommandResult {
        try await runOffMain { [self] in
            let response = withCArgs { c in
                KeygenTestExecute(
                    c.str(host),
                    Int32(port),
                    c.str(username),
                    c.str(password),
                    c.str(privateKey),
                    c.str(passphrase),
                    c.str(command)
                )
            }
            return try self.decode(response, as: SSHCommandResult.self)
        }
    }

    // MARK: - Internals

    private func commandString(_ call: (CArgs) -> UnsafeMutablePointer<CChar>?) -> String {
        guard let ptr = withCArgs(call) else { return "" }
        defer { CoreFreeString(ptr) }
        struct Wrapper: Codable { let command: String }
        return (try? Self.decodeData(ptr, as: Wrapper.self).command) ?? ""
    }

    private func decode<T: Decodable>(
        _ ptr: UnsafeMutablePointer<CChar>?,
        as type: T.Type
    ) throws -> T {
        guard let ptr else { throw CoreBridgeError.nullResponse }
        defer { CoreFreeString(ptr) }
        return try Self.decodeData(ptr, as: type)
    }

    /// Shared JSON decoder that pulls the `data` field out of the bridge
    /// envelope and decodes it as `T`.
    private static func decodeData<T: Decodable>(
        _ ptr: UnsafeMutablePointer<CChar>?,
        as type: T.Type
    ) throws -> T {
        guard let ptr else { throw CoreBridgeError.nullResponse }
        let json = String(cString: ptr)
        guard let data = json.data(using: .utf8) else {
            throw CoreBridgeError.invalidJSON
        }
        let response = try JSONDecoder().decode(BridgeResponse.self, from: data)
        guard response.success, let payload = response.data else {
            throw CoreBridgeError.executionFailed(response.error ?? "Unknown keygen error")
        }
        return try JSONDecoder().decode(T.self, from: payload)
    }

    /// Runs a synchronous CGo call off the MainActor / off the calling actor.
    /// Generation can take >1s for RSA-4096 — we must not block CGo's
    /// pinned OS thread on the main run loop.
    private func runOffMain<T: Sendable>(_ work: @Sendable @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try work()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
