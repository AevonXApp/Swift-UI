//
//  HookRegistry.swift
//  AevonX
//
//  Central registry for all active plugin registrations.
//  Plugins register here after being loaded by PluginLoader.
//

import Foundation
import Combine
import AevonXCore

@MainActor
final class HookRegistry: ObservableObject {

    static let shared = HookRegistry()

    /// All registered plugins, keyed by hook point
    @Published private(set) var registrations: [HookPoint: [HookPluginDefinition]] = [:]

    private init() {}

    // MARK: - Registration

    func register(_ plugin: HookPluginDefinition) {
        var list = registrations[plugin.hook] ?? []
        // Avoid duplicates (by id)
        if !list.contains(where: { $0.id == plugin.id }) {
            list.append(plugin)
            registrations[plugin.hook] = list
        }
    }

    func unregister(pluginId: String) {
        for hook in HookPoint.allCases {
            registrations[hook]?.removeAll { $0.id == pluginId }
        }
    }

    /// Remove all registrations (called before reload)
    func clearAll() {
        registrations = [:]
    }

    // MARK: - Queries

    /// All plugins registered at a given hook point
    func plugins(for hook: HookPoint) -> [HookPluginDefinition] {
        registrations[hook] ?? []
    }

    /// All plugins from a specific namespace
    func plugins(inNamespace namespace: String) -> [HookPluginDefinition] {
        HookPoint.allCases.flatMap { registrations[$0] ?? [] }
            .filter { $0.namespace == namespace }
    }

    /// Total count across all hooks
    var totalCount: Int {
        registrations.values.reduce(0) { $0 + $1.count }
    }

    /// Whether any plugins are registered at a hook
    func hasPlugins(for hook: HookPoint) -> Bool {
        !(registrations[hook]?.isEmpty ?? true)
    }
}
