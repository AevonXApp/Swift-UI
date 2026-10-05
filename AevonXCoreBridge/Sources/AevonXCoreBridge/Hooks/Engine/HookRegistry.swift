//
//  HookRegistry.swift
//  AevonXCoreBridge
//
//  Central registry for all active hook registrations.
//  Hooks register here after being loaded by HookLoader.
//

import Foundation
import Combine

@MainActor
public final class HookRegistry: ObservableObject {

    public static let shared = HookRegistry()

    /// All registered plugins, keyed by hook point
    @Published public private(set) var registrations: [HookPoint: [HookPluginDefinition]] = [:]

    /// Namespace manifests (binary path + allowed_actions)
    public private(set) var manifests: [String: HookNamespaceManifest] = [:]

    private init() {}

    // MARK: - Registration

    public func register(_ plugin: HookPluginDefinition) {
        guard let hook = plugin.hook else { return }
        var list = registrations[hook] ?? []
        // Avoid duplicates (by id)
        if !list.contains(where: { $0.id == plugin.id }) {
            list.append(plugin)
            registrations[hook] = list
        }
    }

    /// Store a namespace manifest for dynamic command resolution
    public func registerManifest(_ manifest: HookNamespaceManifest, namespace: String) {
        manifests[namespace] = manifest
    }

    public func unregister(pluginId: String) {
        for hook in HookPoint.allCases {
            registrations[hook]?.removeAll { $0.id == pluginId }
        }
    }

    /// Remove all registrations (called before reload)
    public func clearAll() {
        registrations = [:]
        manifests = [:]
    }

    // MARK: - Queries

    /// All plugins registered at a given hook point
    public func plugins(for hook: HookPoint) -> [HookPluginDefinition] {
        registrations[hook] ?? []
    }

    /// All plugins from a specific namespace
    public func plugins(inNamespace namespace: String) -> [HookPluginDefinition] {
        HookPoint.allCases.flatMap { registrations[$0] ?? [] }
            .filter { $0.namespace == namespace }
    }

    /// Look up the manifest for a namespace (used by HookCommandDispatcher)
    public func manifest(for namespace: String) -> HookNamespaceManifest? {
        manifests[namespace]
    }

    /// Total count across all hooks
    public var totalCount: Int {
        registrations.values.reduce(0) { $0 + $1.count }
    }

    /// All registered plugins across all hook points
    public func allPlugins() -> [HookPluginDefinition] {
        HookPoint.allCases.flatMap { registrations[$0] ?? [] }
    }

    /// Whether any plugins are registered at a hook
    public func hasPlugins(for hook: HookPoint) -> Bool {
        !(registrations[hook]?.isEmpty ?? true)
    }
}
