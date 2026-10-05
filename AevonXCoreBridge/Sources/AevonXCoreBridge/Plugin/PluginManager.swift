//
//  PluginManager.swift
//  AevonXCoreBridge
//
//  Bridge adapter wrapping Go Core PluginManager CGo exports.
//  Provides the same API as AevonXCore.PluginManager.shared
//

import Foundation
import AevonXCoreLib

// MARK: - Dev Build Step

public struct DevBuildStep: Identifiable, Sendable {
    public let id: UUID
    public let index: Int
    public let label: String
    public var status: StepStatus
    public var detail: String?
    public var duration: TimeInterval?
    
    public init(index: Int, label: String, status: StepStatus = .pending, detail: String? = nil) {
        self.id = UUID()
        self.index = index
        self.label = label
        self.status = status
        self.detail = detail
    }
    
    public enum StepStatus: String, Sendable {
        case pending, running, success, failed, skipped
        public var icon: String {
            switch self {
            case .pending:  return "circle"
            case .running:  return "arrow.trianglehead.2.clockwise"
            case .success:  return "checkmark.circle.fill"
            case .failed:   return "xmark.circle.fill"
            case .skipped:  return "minus.circle"
            }
        }
    }
}

// MARK: - Manifest Validation

public struct ManifestValidationResult: Sendable {
    public let isValid: Bool
    public let pluginName: String?
    public let version: String?
    public let warnings: [String]
    public let errors: [String]
    
    public static func valid(name: String, version: String?, warnings: [String] = []) -> ManifestValidationResult {
        ManifestValidationResult(isValid: true, pluginName: name, version: version, warnings: warnings, errors: [])
    }
    public static func invalid(errors: [String]) -> ManifestValidationResult {
        ManifestValidationResult(isValid: false, pluginName: nil, version: nil, warnings: [], errors: errors)
    }
}

// MARK: - AXSecurity Status

public struct AxSecurityStatusResult: Codable, Sendable {
    public let installed: Bool
    public let running: Bool
    public var processName: String?
    public var lastHeartbeat: Int64?
    public var needsUpdate: Bool?
    public var heartbeatStale: Bool?

    public init(installed: Bool, running: Bool) {
        self.installed = installed
        self.running = running
    }

    enum CodingKeys: String, CodingKey {
        case installed, running
        case processName = "process_name"
        case lastHeartbeat = "last_heartbeat"
        case needsUpdate = "needs_update"
        case heartbeatStale = "heartbeat_stale"
    }
}

/// Server readiness for plugin installation.
public enum ServerReadiness: Sendable {
    case ready
    case needsDeployment
    case needsUpdate
    case heartbeatStale
    case agentDown
    case unknown

    public init(from status: AxSecurityStatusResult) {
        if !status.installed {
            self = .needsDeployment
        } else if !status.running {
            self = .agentDown
        } else if status.needsUpdate == true {
            self = .needsUpdate
        } else if status.heartbeatStale == true {
            self = .heartbeatStale
        } else {
            self = .ready
        }
    }
}

// MARK: - Plugin Health & Update

public struct PluginHealth: Sendable {
    public enum Status: String, Sendable { case healthy, unhealthy, notInstalled = "not_installed" }
    public let slug: String
    public let status: Status
    public let message: String
    public var serviceActive: Bool = false
    public var healthOutput: String = ""
}

public struct PluginUpdateInfo: Codable, Sendable {
    public let pluginSlug: String
    public let pluginName: String
    public let installedVersion: String
    public let latestVersion: String
    public let changelog: String?
    public var updateAvailable: Bool { true }

    enum CodingKeys: String, CodingKey {
        case pluginSlug = "plugin_slug"
        case pluginName = "plugin_name"
        case installedVersion = "installed_version"
        case latestVersion = "latest_version"
        case changelog
    }
}

// MARK: - Plugin Security Status (batch status from backend)

public enum PluginSecurityStatus: String, Codable, Sendable {
    case active
    case notInstalled = "not_installed"
    case expired
    case suspended
    case tamperDetected = "tamper_detected"
    case heartbeatStale = "heartbeat_stale"
    case updateAvailable = "update_available"
    case agentDown = "agent_down"
    case unknown
}

public struct PluginStatusInfo: Codable, Sendable {
    public let status: PluginSecurityStatus
    public var reason: String?
    public var lastHeartbeat: Int64?
    public var tamperCount: Int?
    public var installedVersion: String?
    public var latestVersion: String?
    public var expiredAt: Int64?

    enum CodingKeys: String, CodingKey {
        case status, reason
        case lastHeartbeat = "last_heartbeat"
        case tamperCount = "tamper_count"
        case installedVersion = "installed_version"
        case latestVersion = "latest_version"
        case expiredAt = "expired_at"
    }
}

// MARK: - Plugin Manager Error

public enum PluginManagerError: Error, LocalizedError {
    case extractionFailed(detail: String)
    case setupScriptNotFound
    case setupFailed(detail: String)
    case configNotFound(pluginSlug: String)
    case invalidSlug(_ slug: String)
    case incompatibleVersion(pluginVersion: String, requiredMin: String)
    case healthCheckFailed(slug: String, detail: String)
    case binaryNotFound(pluginSlug: String)
    case sshFailed(operation: String, detail: String)
    
    public var errorDescription: String? {
        switch self {
        case .extractionFailed(let d): return "Failed to extract plugin: \(d)"
        case .setupScriptNotFound: return "setup.sh not found in plugin package"
        case .setupFailed(let d): return "Plugin setup failed: \(d)"
        case .configNotFound(let s): return "Config not found for '\(s)'"
        case .invalidSlug(let s): return "Invalid slug: '\(s)'"
        case .incompatibleVersion(let pv, let rv): return "Version \(pv) requires Core \(rv)+"
        case .healthCheckFailed(let s, let d): return "Health check failed for '\(s)': \(d)"
        case .binaryNotFound(let s): return "Binary not found: \(s)"
        case .sshFailed(let op, let d): return "\(op) failed: \(d)"
        }
    }
}

// MARK: - Plugin Manager

/// Bridge adapter for Go Core PluginManager.
/// Matches AevonXCore.PluginManager API signatures.
public actor PluginManager {
    
    public static let shared = PluginManager()
    public static let coreVersion = "1.0.0"
    
    private init() {}
    
    // MARK: - List Installed Slugs
    
    public func listInstalledPluginSlugs(on serverId: String) async throws -> [String] {
        let json = await callGo { serverId.withMutableCString { PluginListInstalled($0) } }
        return parseArray(json)
    }
    
    // MARK: - List Installed Sources
    
    public func listInstalledSources(on serverId: String) async throws -> [String: InstallSource] {
        let json = await callGo { serverId.withMutableCString { PluginListSources($0) } }
        guard let data = extractData(json),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        var result: [String: InstallSource] = [:]
        for (k, v) in dict {
            result[k] = InstallSource(rawValue: v) ?? .unknown
        }
        return result
    }
    
    // MARK: - Read Remote Config
    
    public func readRemoteConfig(pluginSlug: String, on serverId: String) async throws -> PluginConfig {
        let json = await callGo { serverId.withMutableCString { s in pluginSlug.withMutableCString { p in PluginReadConfig(s, p) } } }
        guard let data = extractData(json) else {
            throw PluginManagerError.configNotFound(pluginSlug: pluginSlug)
        }
        return try JSONDecoder().decode(PluginConfig.self, from: data)
    }
    
    // MARK: - Write Remote Config
    
    public func writeRemoteConfig(pluginSlug: String, config: PluginConfig, on serverId: String) async throws {
        let configData = try JSONEncoder().encode(config)
        let configJSON = String(data: configData, encoding: .utf8) ?? "{}"
        let json = await callGo { serverId.withMutableCString { s in pluginSlug.withMutableCString { p in configJSON.withMutableCString { c in PluginWriteConfig(s, p, c) } } } }
        guard isSuccess(json) else {
            throw PluginManagerError.sshFailed(operation: "writeConfig", detail: extractError(json))
        }
    }
    
    // MARK: - Read Raw Config

    /// Reads the raw config.avx content as a string (for text editor).
    public func readRemoteRawConfig(pluginSlug: String, on serverId: String) async throws -> String {
        let json = await callGo { serverId.withMutableCString { s in pluginSlug.withMutableCString { p in PluginReadRawConfig(s, p) } } }
        guard let data = extractData(json) else {
            throw PluginManagerError.configNotFound(pluginSlug: pluginSlug)
        }
        // The response is a JSON string wrapper, decode to get the raw content
        return (try? JSONDecoder().decode(String.self, from: data)) ?? String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Write Raw Config

    /// Writes raw JSON content to the plugin config file via SSH binary pipe.
    public func writeRemoteRawConfig(pluginSlug: String, rawJSON: String, on serverId: String) async throws {
        let json = await callGo { serverId.withMutableCString { s in pluginSlug.withMutableCString { p in rawJSON.withMutableCString { r in PluginWriteRawConfig(s, p, r) } } } }
        guard isSuccess(json) else {
            throw PluginManagerError.sshFailed(operation: "writeRawConfig", detail: extractError(json))
        }
    }

    // MARK: - Execute Plugin Action

    /// Executes a plugin action command on the server and returns the output.
    public func executeAction(pluginSlug: String, command: String, on serverId: String) async throws -> String {
        let json = await callGo { serverId.withMutableCString { s in pluginSlug.withMutableCString { p in command.withMutableCString { c in PluginExecuteAction(s, p, c) } } } }
        guard let data = extractData(json) else {
            throw PluginManagerError.sshFailed(operation: "executeAction", detail: extractError(json))
        }
        return (try? JSONDecoder().decode(String.self, from: data)) ?? String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Get Config Value

    /// Extracts a single field value from a plugin's config by key.
    public func getConfigValue(pluginSlug: String, key: String, on serverId: String) async throws -> String {
        let json = await callGo { serverId.withMutableCString { s in pluginSlug.withMutableCString { p in key.withMutableCString { k in PluginGetConfigValue(s, p, k) } } } }
        guard let data = extractData(json) else {
            throw PluginManagerError.sshFailed(operation: "getConfigValue", detail: extractError(json))
        }
        return (try? JSONDecoder().decode(String.self, from: data)) ?? String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Install Plugin

    /// Whether the current build is a local dev environment.
    /// Uses compile-time `#if DEBUG` — cannot be tampered with at runtime.
    public static var isDevBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - Secure Plugin Install (SSH Binary Pipe)

    /// Unified secure install: download ZIP → extract correct arch binary + supporting files
    /// → upload directly to server via SSH binary pipe (AES-256/ChaCha20 encrypted channel) → install.
    ///
    /// All logic is inside the Go core (garble obfuscated). No Python, no intermediary,
    /// no base64 overhead. The SSH2 channel provides transport encryption.
    public func installSecure(
        plugin: Plugin,
        version: PluginVersion?,
        downloadURL: String,
        serverId: String,
        serverIP: String,
        baseURL: String,
        token: String,
        licenseToken: String? = nil,
        tokenSignature: String? = nil,
        nonce: String? = nil,
        onProgress: @escaping @Sendable (String, Double) -> Void
    ) async throws {
        let log = CoreLogger.shared
        let slug = plugin.slug
        let start = CFAbsoluteTimeGetCurrent()

        // SECURITY: No legacy flow. license_token IS the proof of authorization.
        // No token = no install. Patching the app to skip Fortress = useless.
        // The token is cryptographically signed (HMAC-SHA256) and encrypted (AES-256-GCM).
        // Without a valid token, SecureDownloadController returns 403. Period.
        guard let lt = licenseToken, !lt.isEmpty,
              let sig = tokenSignature, !sig.isEmpty,
              let n = nonce, !n.isEmpty else {
            log.error("[SecureInstall] No license token — cannot install", module: "PluginMgr")
            throw PluginManagerError.setupFailed(detail: "License verification required")
        }

        try await installSecureBlindRelay(
            slug: slug, serverId: serverId, baseURL: baseURL, token: token,
            licenseToken: lt, tokenSignature: sig, nonce: n,
            onProgress: onProgress
        )
        let totalDuration = CFAbsoluteTimeGetCurrent() - start
        log.info("[SecureInstall] COMPLETE in \(String(format: "%.1f", totalDuration))s", module: "PluginMgr")
    }

    /// Blind relay install: encrypted binary goes Mac → Server without Mac ever seeing plaintext.
    /// The Mac is just a relay — it passes opaque encrypted blobs via SSH.
    ///
    /// Split into 3 phases with real progress:
    ///   Phase 1 (0.00-0.10): Collect server fingerprint
    ///   Phase 2 (0.10-0.50): Request + wait for async build (polls every 30s)
    ///   Phase 3 (0.50-0.95): Download + deploy to server
    private func installSecureBlindRelay(
        slug: String, serverId: String, baseURL: String, token: String,
        licenseToken: String, tokenSignature: String, nonce: String,
        onProgress: @escaping @Sendable (String, Double) -> Void
    ) async throws {
        let log = CoreLogger.shared
        let start = CFAbsoluteTimeGetCurrent()
        let progressID = UUID().uuidString

        log.info("[SecureInstall] Starting...", module: "PluginMgr")

        // ── Phase 1: Collect server fingerprint ──
        onProgress("Collecting server fingerprint...", 0.05)
        log.info("[SecureInstall] Phase 1: Fingerprint", module: "PluginMgr")
        let fpJSON = await callGo { serverId.withMutableCString { ProtectionCollectFingerprint($0) } }

        guard isSuccess(fpJSON) else {
            let err = extractError(fpJSON)
            log.error("[SecureInstall] Fingerprint failed", module: "PluginMgr")
            throw PluginManagerError.setupFailed(detail: "Failed to collect server fingerprint: \(err)")
        }
        onProgress("Server fingerprint collected", 0.10)

        // ── Phase 2: Request async build + poll until ready ──
        onProgress("Requesting build...", 0.12)
        log.info("[SecureInstall] Phase 2: Async build", module: "PluginMgr")

        let buildJSON = await callGoWithProgress(
            progressID: progressID,
            phaseRange: 0.10...0.50,
            onProgress: onProgress
        ) {
            serverId.withMutableCString { sv in slug.withMutableCString { sl in baseURL.withMutableCString { bu in token.withMutableCString { tk in
            licenseToken.withMutableCString { lt in tokenSignature.withMutableCString { ts in fpJSON.withMutableCString { fp in progressID.withMutableCString { pid in
                PrepareBuildAsync(sv, sl, bu, tk, lt, ts, fp, pid)
            } } } } } } } }
        }

        guard isSuccess(buildJSON) else {
            let err = extractError(buildJSON)
            log.error("[SecureInstall] Build preparation failed", module: "PluginMgr")
            throw PluginManagerError.setupFailed(detail: "Build preparation failed: \(err)")
        }
        onProgress("Build ready", 0.50)
        log.info("[SecureInstall] Phase 2 done — build ready", module: "PluginMgr")

        // ── Phase 3: Download + deploy via secure channel ──
        onProgress("Downloading and deploying...", 0.55)
        log.info("[SecureInstall] Phase 3: Install", module: "PluginMgr")

        let resultJSON = await callGoWithProgress(
            progressID: progressID,
            phaseRange: 0.50...0.95,
            onProgress: onProgress
        ) {
            serverId.withMutableCString { sv in slug.withMutableCString { sl in baseURL.withMutableCString { bu in token.withMutableCString { tk in
            licenseToken.withMutableCString { lt in tokenSignature.withMutableCString { ts in nonce.withMutableCString { nc in fpJSON.withMutableCString { fp in progressID.withMutableCString { pid in
                SecureInstallPlugin(sv, sl, bu, tk, lt, ts, nc, fp, pid)
            } } } } } } } } }
        }

        guard isSuccess(resultJSON) else {
            let err = extractError(resultJSON)
            log.error("[SecureInstall] Install failed", module: "PluginMgr")
            throw PluginManagerError.setupFailed(detail: err)
        }

        onProgress("Plugin installed securely", 0.95)
        let totalDuration = CFAbsoluteTimeGetCurrent() - start
        log.info("[SecureInstall] Complete in \(String(format: "%.1f", totalDuration))s", module: "PluginMgr")
    }

    // MARK: - Staging Directory

    /// Unzip marketplace ZIP → select correct arch binary + supporting files → staging directory.
    /// The staging dir is uploaded directly to the server via SSH binary pipe by Go core.
    /// Returns URL of the staging directory (caller is responsible for cleanup).
    private func prepareStagingDirectory(zipURL: URL, slug: String, arch: String) throws -> URL {
        let fm = FileManager.default
        let extractDir = fm.temporaryDirectory.appendingPathComponent("aevonx-extract-\(UUID().uuidString)")
        let stageDir   = fm.temporaryDirectory.appendingPathComponent("aevonx-stage-\(UUID().uuidString)")
        try fm.createDirectory(at: extractDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: stageDir,   withIntermediateDirectories: true)

        // Unzip marketplace ZIP
        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments = ["-o", zipURL.path, "-d", extractDir.path]
        unzip.standardOutput = FileHandle.nullDevice
        unzip.standardError  = FileHandle.nullDevice
        try unzip.run()
        unzip.waitUntilExit()
        guard unzip.terminationStatus == 0 else {
            try? fm.removeItem(at: extractDir)
            throw PluginManagerError.extractionFailed(detail: "unzip exited \(unzip.terminationStatus)")
        }

        // Find correct arch binary
        let binaryName   = "\(slug)-linux-\(arch)"
        let fallbackName = slug
        var binaryURL: URL?

        if let enumerator = fm.enumerator(at: extractDir, includingPropertiesForKeys: nil) {
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.lastPathComponent == binaryName { binaryURL = fileURL; break }
            }
        }
        // Fallback 1: exact slug name (no arch suffix)
        if binaryURL == nil {
            if let enumerator = fm.enumerator(at: extractDir, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if fileURL.lastPathComponent == fallbackName {
                        var isDir: ObjCBool = false
                        if fm.fileExists(atPath: fileURL.path, isDirectory: &isDir), !isDir.boolValue {
                            binaryURL = fileURL; break
                        }
                    }
                }
            }
        }
        // Fallback 2: any file ending with -linux-{arch} (handles slug != binary name)
        if binaryURL == nil {
            let archSuffix = "-linux-\(arch)"
            if let enumerator = fm.enumerator(at: extractDir, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if fileURL.lastPathComponent.hasSuffix(archSuffix) {
                        binaryURL = fileURL; break
                    }
                }
            }
        }
        guard let binary = binaryURL else {
            try? fm.removeItem(at: extractDir)
            throw PluginManagerError.binaryNotFound(pluginSlug: slug)
        }

        // Copy correct binary + all supporting files, skip other-arch binaries
        let sourceDir = binary.deletingLastPathComponent()
        let skipNames: Set<String> = Set([
            "\(slug)-linux-amd64", "\(slug)-linux-arm64",
            "\(slug)-linux-x86_64", "\(slug)-linux-aarch64"
        ].filter { $0 != binaryName })

        if let items = try? fm.contentsOfDirectory(at: sourceDir, includingPropertiesForKeys: nil) {
            for item in items {
                let name = item.lastPathComponent
                if name.hasPrefix(".") || name.hasPrefix("__MACOSX") || name.hasPrefix("._") { continue }
                if skipNames.contains(name) { continue }
                try? fm.copyItem(at: item, to: stageDir.appendingPathComponent(name))
            }
        }

        try? fm.removeItem(at: extractDir)
        return stageDir
    }
    
    // MARK: - Uninstall Plugin
    
    public func uninstallPlugin(plugin: Plugin, on serverId: String) async throws {
        let log = CoreLogger.shared
        log.info("[PluginMgr] ▶ Uninstalling \(plugin.slug) from server \(serverId)...", module: "PluginMgr")
        let start = CFAbsoluteTimeGetCurrent()

        let json = await callGo { serverId.withMutableCString { s in plugin.slug.withMutableCString { p in PluginUninstall(s, p) } } }
        let duration = CFAbsoluteTimeGetCurrent() - start

        guard isSuccess(json) else {
            let err = extractError(json)
            log.error("[PluginMgr] ✖ Uninstall FAILED after \(String(format: "%.1f", duration))s: \(err)", module: "PluginMgr")
            throw PluginManagerError.sshFailed(operation: "uninstall", detail: err)
        }
        log.info("[PluginMgr] ✓ Uninstalled \(plugin.slug) in \(String(format: "%.1f", duration))s", module: "PluginMgr")
    }
    
    // MARK: - Install Dev Build
    
    @discardableResult
    public func installDevBuild(
        zipURL: URL,
        on serverId: String,
        onStep: @escaping @Sendable (DevBuildStep) -> Void = { _ in }
    ) async throws -> String {
        // Step 1: Detect slug from ZIP filename
        var step = DevBuildStep(index: 1, label: "Detecting plugin slug", status: .running)
        onStep(step)
        
        let zipName = zipURL.deletingPathExtension().lastPathComponent.lowercased()
        let cleaned = zipName.replacingOccurrences(
            of: #"-v?\d+\.\d+\.\d+(-[a-z0-9]+)*$"#,
            with: "",
            options: .regularExpression
        )
        let slug = cleaned.isEmpty ? zipName : cleaned
        step.status = .success
        step.detail = slug
        onStep(step)
        
        // Step 2: Upload
        step = DevBuildStep(index: 2, label: "Uploading to server", status: .running)
        onStep(step)
        
        let archJSON = await callGo { serverId.withMutableCString { ProtectionDetectArchitecture($0) } }
        let arch = extractStringData(archJSON) ?? "amd64"
        let stagingURL = try prepareStagingDirectory(zipURL: zipURL, slug: slug, arch: arch)
        try? FileManager.default.removeItem(at: zipURL)
        step.status = .success
        onStep(step)

        // Step 3: Upload + Install via Go Core (SSH binary pipe)
        step = DevBuildStep(index: 3, label: "Installing plugin", status: .running)
        onStep(step)

        let json = await callGo { serverId.withMutableCString { s in slug.withMutableCString { sl in stagingURL.path.withMutableCString { p in PluginInstallFromLocal(s, sl, p) } } } }
        try? FileManager.default.removeItem(at: stagingURL)
        guard isSuccess(json) else {
            step.status = .failed
            step.detail = extractError(json)
            onStep(step)
            throw PluginManagerError.setupFailed(detail: extractError(json))
        }
        step.status = .success
        step.detail = "Completed"
        onStep(step)
        
        // Step 4: Done
        step = DevBuildStep(index: 4, label: "Installation complete", status: .success)
        step.detail = "\(slug) is ready"
        onStep(step)
        
        return slug
    }
    
    // MARK: - Install Protected Plugin (DRM Pipeline)

    /// Installs a plugin through the full protection pipeline:
    // MARK: - License Verification

    /// Verifies that a plugin has a valid license for a given server.
    /// Returns the verification result as a dictionary.
    public func verifyLicense(slug: String, on serverId: String) async -> LicenseVerificationResult {
        let log = CoreLogger.shared
        let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
        let token = await AuthService.shared.getToken() ?? ""

        log.info("[LicenseVerify] ▶ Starting license verification: slug=\(slug), server=\(serverId)", module: "PluginMgr")
        let start = CFAbsoluteTimeGetCurrent()

        let json = await APIBridge.shared.verifyPluginLicenseAsync(
            baseURL: baseURL, token: token, pluginSlug: slug, serverID: serverId
        )

        let duration = CFAbsoluteTimeGetCurrent() - start
        log.info("[LicenseVerify] Go Core returned in \(String(format: "%.2f", duration))s", module: "PluginMgr")

        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              obj["success"] as? Bool == true,
              let inner = obj["data"] as? [String: Any] else {
            let errMsg = (try? JSONSerialization.jsonObject(with: json.data(using: .utf8) ?? Data()) as? [String: Any])?["error"] as? String ?? "parse_failed"
            log.error("[LicenseVerify] ✖ FAILED for \(slug): \(errMsg) (raw length: \(json.count))", module: "PluginMgr")
            return LicenseVerificationResult(valid: false, pricingType: "unknown", reason: "verification_failed")
        }

        let result = LicenseVerificationResult(
            valid: inner["valid"] as? Bool ?? false,
            pricingType: inner["pricing_type"] as? String ?? "unknown",
            reason: inner["reason"] as? String,
            expiresAt: inner["expires_at"] as? String,
            verificationToken: inner["verification_token"] as? String,
            ttl: inner["ttl"] as? Int,
            licenseToken: inner["license_token"] as? String,
            tokenSignature: inner["token_signature"] as? String,
            nonce: inner["nonce"] as? String
        )

        if result.isAuthorized {
            log.info("[LicenseVerify] Authorized", module: "PluginMgr")
        } else {
            log.warning("[LicenseVerify] Denied", module: "PluginMgr")
        }

        return result
    }

    // MARK: - Parse Config
    
    public func parseConfig(_ content: String) -> PluginConfig {
        guard let data = content.data(using: .utf8),
              let config = try? JSONDecoder().decode(PluginConfig.self, from: data) else {
            return PluginConfig()
        }
        return config
    }
    
    public func generateConfig(from config: PluginConfig) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(config),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }
    
    // MARK: - AXSecurity Agent Management

    /// Check if axsecurity agent is deployed and running on a server.
    public func checkAxSecurityStatus(
        serverID: String, baseURL: String, token: String
    ) async -> AxSecurityStatusResult {
        let json = await callGo {
            serverID.withMutableCString { s in baseURL.withMutableCString { b in token.withMutableCString { t in CheckAxSecurityStatus(s, b, t) } } }
        }
        guard let data = extractData(json),
              let result = try? JSONDecoder().decode(AxSecurityStatusResult.self, from: data)
        else {
            return AxSecurityStatusResult(installed: false, running: false)
        }
        return result
    }

    /// Deploy axsecurity agent to a server for the first time.
    public func deployAxSecurity(
        serverID: String, baseURL: String, token: String, fingerprint: String,
        onProgress: @escaping @Sendable (String, Double) -> Void
    ) async throws {
        let progressID = UUID().uuidString
        onProgress("Building security agent...", 0.05)

        let json = await callGoWithProgress(
            progressID: progressID,
            phaseRange: 0.0...1.0,
            onProgress: onProgress
        ) {
            serverID.withMutableCString { s in baseURL.withMutableCString { b in token.withMutableCString { t in fingerprint.withMutableCString { f in progressID.withMutableCString { pid in
                DeployAxSecurity(s, b, t, f, pid)
            } } } } }
        }
        guard isSuccess(json) else {
            throw PluginManagerError.setupFailed(detail: extractError(json))
        }
        onProgress("Agent deployed successfully", 1.0)
    }

    // MARK: - Fingerprint Collection

    /// Collect server fingerprint JSON for axsecurity deployment.
    public func collectServerFingerprint(serverID: String) async -> String {
        await callGo { serverID.withMutableCString { ProtectionCollectFingerprint($0) } }
    }

    // MARK: - Architecture Detection

    /// Detect server architecture via SSH (returns "amd64" or "arm64").
    public func detectServerArchitecture(serverID: String) async -> String {
        let json = await callGo { serverID.withMutableCString { ProtectionDetectArchitecture($0) } }
        // Response is {"success":true,"data":{"architecture":"amd64"}}
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              obj["success"] as? Bool == true,
              let dataObj = obj["data"] as? [String: Any],
              let arch = dataObj["architecture"] as? String else {
            return "amd64"
        }
        return arch
    }

    // MARK: - Helpers

    private func extractStringData(_ json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              obj["success"] as? Bool == true,
              let val = obj["data"] as? String else { return nil }
        return val
    }

    // MARK: - Check For Updates

    /// Checks for available updates for all installed plugins on a server.
    /// Returns array of available updates with version info and changelog.
    public func checkForUpdates(on serverId: String) async throws -> [PluginUpdateInfo] {
        let log = CoreLogger.shared
        log.info("[PluginMgr] Checking for plugin updates on server \(serverId)...", module: "PluginMgr")

        // 1. Get installed plugins and their versions
        let versionsJSON = await callGo { serverId.withMutableCString { PluginGetInstalledVersions($0) } }
        guard let versionsData = extractData(versionsJSON),
              let versions = try? JSONSerialization.jsonObject(with: versionsData) as? [String: String],
              !versions.isEmpty else {
            log.info("[PluginMgr] No installed plugins found or failed to read versions", module: "PluginMgr")
            return []
        }

        // 2. Build request payload
        var installed: [[String: String]] = []
        for (slug, version) in versions {
            installed.append(["slug": slug, "installed_version": version])
        }
        guard let installedData = try? JSONSerialization.data(withJSONObject: installed),
              let installedJSON = String(data: installedData, encoding: .utf8) else {
            return []
        }

        // 3. Call backend via Go bridge
        let baseURL = ConfigurationManager.shared.currentConfiguration.fullBaseURL
        let token = await AuthService.shared.getToken() ?? ""

        let resultJSON = await callGo {
            baseURL.withMutableCString { b in token.withMutableCString { t in installedJSON.withMutableCString { j in PluginCheckForUpdates(b, t, j) } } }
        }

        guard let data = extractData(resultJSON),
              let updates = try? JSONDecoder().decode([PluginUpdateInfo].self, from: data) else {
            let err = extractError(resultJSON)
            log.error("[PluginMgr] Check updates failed: \(err)", module: "PluginMgr")
            throw PluginManagerError.sshFailed(operation: "checkUpdates", detail: err)
        }

        log.info("[PluginMgr] Found \(updates.count) update(s) available", module: "PluginMgr")
        return updates
    }

    /// Updates a plugin on the server (preserves config, uninstalls old, installs new).
    public func updatePlugin(
        slug: String,
        downloadURL: String,
        on serverId: String,
        onProgress: @escaping @Sendable (String, Double) -> Void
    ) async throws {
        let log = CoreLogger.shared
        let start = CFAbsoluteTimeGetCurrent()
        log.info("[PluginMgr] ▶ Updating \(slug) on server \(serverId)...", module: "PluginMgr")

        onProgress("Backing up configuration...", 0.10)

        let json = await callGo {
            serverId.withMutableCString { s in slug.withMutableCString { sl in downloadURL.withMutableCString { d in PluginUpdate(s, sl, d) } } }
        }

        let duration = CFAbsoluteTimeGetCurrent() - start

        guard isSuccess(json) else {
            let err = extractError(json)
            log.error("[PluginMgr] ✖ Update FAILED after \(String(format: "%.1f", duration))s: \(err)", module: "PluginMgr")
            throw PluginManagerError.setupFailed(detail: err)
        }

        onProgress("Update complete", 1.0)
        log.info("[PluginMgr] ✓ Updated \(slug) in \(String(format: "%.1f", duration))s", module: "PluginMgr")
    }

    // MARK: - Batch Plugin Status

    public func getPluginStatuses(
        serverID: String, slugs: [String], baseURL: String, token: String
    ) async -> [String: PluginStatusInfo] {
        guard !slugs.isEmpty else { return [:] }

        guard let slugsData = try? JSONEncoder().encode(slugs),
              let slugsJSON = String(data: slugsData, encoding: .utf8) else { return [:] }

        let json = await callGo {
            serverID.withMutableCString { s in slugsJSON.withMutableCString { sl in baseURL.withMutableCString { b in token.withMutableCString { t in GetPluginStatuses(s, sl, b, t) } } } }
        }

        guard let data = extractData(json),
              let wrapper = try? JSONDecoder().decode([String: [String: PluginStatusInfo]].self, from: data),
              let statuses = wrapper["statuses"] else {
            return [:]
        }
        return statuses
    }

    private func callGo(_ work: @escaping @Sendable () -> UnsafeMutablePointer<CChar>?) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = work()
                defer { if let r = result { CoreFreeString(r) } }
                let json = result.map { String(cString: $0) } ?? ""
                continuation.resume(returning: json)
            }
        }
    }

    // MARK: - Progress File Polling

    /// Progress data written by Go to /tmp/.ax-progress-{id}.json
    private struct GoProgress: Codable {
        let phase: String
        let progress: Double
        let status: String
        let bytesTotal: Int64
        let bytesDone: Int64
        let updatedAt: Int64

        enum CodingKeys: String, CodingKey {
            case phase, progress, status
            case bytesTotal = "bytes_total"
            case bytesDone = "bytes_done"
            case updatedAt = "updated_at"
        }
    }

    /// Run a Go call while polling a progress file on a timer.
    /// Maps Go's 0.0-1.0 progress to the given phaseRange for the caller's overall pipeline.
    private func callGoWithProgress(
        progressID: String,
        phaseRange: ClosedRange<Double>,
        onProgress: @escaping @Sendable (String, Double) -> Void,
        work: @escaping @Sendable () -> UnsafeMutablePointer<CChar>?
    ) async -> String {
        let progressPath = "/tmp/.ax-progress-\(progressID).json"
        let rangeSpan = phaseRange.upperBound - phaseRange.lowerBound

        // Start timer on main thread to poll progress file
        let timerSource = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timerSource.schedule(deadline: .now() + 0.5, repeating: 0.5)
        timerSource.setEventHandler { [weak self] in
            guard self != nil else { return }
            guard let data = FileManager.default.contents(atPath: progressPath),
                  let gp = try? JSONDecoder().decode(GoProgress.self, from: data) else { return }

            let mapped = phaseRange.lowerBound + gp.progress * rangeSpan

            if gp.bytesTotal > 0 && gp.bytesDone > 0 {
                let mbDone = Double(gp.bytesDone) / 1_048_576.0
                let mbTotal = Double(gp.bytesTotal) / 1_048_576.0
                let status = String(format: "%@ %.1f / %.1f MB", gp.status, mbDone, mbTotal)
                onProgress(status, min(mapped, phaseRange.upperBound))
            } else {
                onProgress(gp.status, min(mapped, phaseRange.upperBound))
            }
        }
        timerSource.resume()

        let result = await callGo(work)

        timerSource.cancel()
        return result
    }
    
    private func isSuccess(_ json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return obj["success"] as? Bool ?? false
    }
    
    private func extractError(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return "Unknown" }
        return obj["error"] as? String ?? "Unknown error"
    }
    
    private func extractData(_ json: String) -> Data? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = obj["data"],
              !(inner is NSNull) else { return nil }
        // JSONSerialization.data(withJSONObject:) throws NSException (NOT a Swift
        // error, so try? doesn't catch it) for non-container top-level types.
        // Handle primitives manually to avoid the NSException path entirely.
        if let s = inner as? String {
            // Encode as JSON string literal using JSONEncoder (always safe)
            return try? JSONEncoder().encode(s)
        }
        if let n = inner as? NSNumber {
            // Check for Bool first (NSNumber bridges Bool)
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
                return (n.boolValue ? "true" : "false").data(using: .utf8)
            }
            return "\(n)".data(using: .utf8)
        }
        // Containers (array/dictionary) — safe to serialize
        guard JSONSerialization.isValidJSONObject(inner) else { return nil }
        return try? JSONSerialization.data(withJSONObject: inner)
    }
    
    private func parseArray(_ json: String) -> [String] {
        guard let data = extractData(json),
              let arr = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return arr
    }
    
}

