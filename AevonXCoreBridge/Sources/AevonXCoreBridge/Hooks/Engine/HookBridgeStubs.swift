//
//  HookBridgeStubs.swift
//  AevonXCoreBridge
//
//  Stubs for types referenced by Hook engine files.
//

import Foundation
import CommonCrypto

// MARK: - PluginManifestStore Stub

public final class PluginManifestStore: @unchecked Sendable {
    public static let shared = PluginManifestStore()
    private init() {}

    public struct HookNamespace: Sendable {
        public let slug: String
        public let manifests: [PluginManifest]
    }

    public struct PluginManifest: Sendable {
        public let slug: String
        public let permissions: PluginPermissions
        public let installPath: String
        public let argStyle: String?
        public let commandsPath: String?
        public let binary: String?
        /// When non-nil and non-empty, only actions present in this list are
        /// allowed. When nil/empty, the plugin is fully trusted (developer
        /// mode, useful for unsigned plugins under active iteration).
        public let allowedActions: [String]?

        public init(slug: String, permissions: PluginPermissions = PluginPermissions(), installPath: String = "", argStyle: String? = "flag", commandsPath: String? = nil, binary: String? = nil, allowedActions: [String]? = nil) {
            self.slug = slug
            self.permissions = permissions
            self.installPath = installPath
            self.argStyle = argStyle
            self.commandsPath = commandsPath
            self.binary = binary
            self.allowedActions = allowedActions
        }
    }

    public struct PluginPermissions: Sendable {
        public let allowedPaths: [String]
        public let allowedCommands: [String]

        public init(allowedPaths: [String] = ["/var/www"], allowedCommands: [String] = []) {
            self.allowedPaths = allowedPaths
            self.allowedCommands = allowedCommands
        }
    }

    private var manifests: [String: PluginManifest] = [:]
    private var namespaces: [String: String] = [:]  // namespace → slug
    /// Stores SHA-256 hash of each manifest's raw JSON data on first registration.
    /// Used to detect on-disk tampering between reloads.
    private var manifestHashes: [String: String] = [:]

    public func manifest(for pluginSlug: String) -> PluginManifest? {
        return manifests[pluginSlug]
    }

    public func register(_ manifest: PluginManifest) {
        manifests[manifest.slug] = manifest
        namespaces[manifest.slug] = manifest.slug
    }

    /// Register a manifest with integrity tracking.
    /// On first call for a slug, stores the content hash.
    /// On subsequent calls, warns if the manifest content has changed.
    public func register(_ manifest: PluginManifest, rawData: Data) {
        let hash = sha256(rawData)
        if let previousHash = manifestHashes[manifest.slug], previousHash != hash {
            CoreLogger.shared.warning(
                "SECURITY: Manifest for '\(manifest.slug)' has changed since last load (hash mismatch). Possible tampering.",
                module: "PluginManifestStore"
            )
        }
        manifestHashes[manifest.slug] = hash
        manifests[manifest.slug] = manifest
        namespaces[manifest.slug] = manifest.slug
    }

    public func allManifestSlugs() -> [String] {
        return Array(manifests.keys)
    }

    public func namespaceForSlug(_ slug: String) -> String? {
        return namespaces[slug]
    }

    public func allNamespaces() -> [String] {
        let ns = Array(namespaces.keys)
        return ns.isEmpty ? Array(manifests.keys) : ns
    }

    public func clearAll() {
        manifests.removeAll()
        namespaces.removeAll()
        // Note: manifestHashes intentionally NOT cleared — persists across reloads
        // so we can detect changes between load cycles.
    }

    private func sha256(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ServerPathResolver Stub

public final class ServerPathResolver: @unchecked Sendable {
    public static let shared = ServerPathResolver()
    private init() {}
    
    public func webRoot(serverId: String) async throws -> String {
        return "/var/www"
    }
    
    public func nginxLogDir(serverId: String) async throws -> String {
        return "/var/log/nginx"
    }
    
    public func logDir(serverId: String) async throws -> String {
        return "/var/log"
    }
}
