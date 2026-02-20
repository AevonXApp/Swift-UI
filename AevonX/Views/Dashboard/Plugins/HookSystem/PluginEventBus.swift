//
//  PluginEventBus.swift
//  AevonX
//
//  Inter-plugin communication and lifecycle event system.
//  Plugins can subscribe to events from other plugins and the app.
//  Events flow through a central bus to maintain decoupling.
//

import SwiftUI
import Combine

// MARK: - Plugin Event

public struct PluginEvent: Identifiable {
    public let id = UUID()
    public let source: String          // namespace of the emitting plugin
    public let name: String            // event name (e.g. "scan_completed")
    public let payload: [String: Any]  // event data
    public let timestamp: Date = Date()
}

// MARK: - Plugin Event Bus

@MainActor
public final class PluginEventBus: ObservableObject {
    public static let shared = PluginEventBus()

    /// Combine subject carrying events
    private let eventSubject = PassthroughSubject<PluginEvent, Never>()

    /// Public publisher for subscribers
    public var events: AnyPublisher<PluginEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    /// Registered listeners: [eventName: [(namespace, handler)]]
    private var listeners: [String: [(namespace: String, handler: (PluginEvent) -> Void)]] = [:]

    private init() {}

    // MARK: - Emit

    /// Emit an event from a plugin
    public func emit(source: String, name: String, payload: [String: Any] = [:]) {
        let event = PluginEvent(source: source, name: name, payload: payload)

        // Notify Combine subscribers
        eventSubject.send(event)

        // Notify registered closure listeners
        if let handlers = listeners[name] {
            for listener in handlers {
                listener.handler(event)
            }
        }

        // Also fire wildcard listeners ("*")
        if let wildcardHandlers = listeners["*"] {
            for listener in wildcardHandlers {
                listener.handler(event)
            }
        }
    }

    // MARK: - Subscribe

    /// Register a closure listener for a specific event name
    public func on(_ eventName: String, namespace: String, handler: @escaping (PluginEvent) -> Void) {
        if listeners[eventName] == nil {
            listeners[eventName] = []
        }
        listeners[eventName]?.append((namespace: namespace, handler: handler))
    }

    /// Remove all listeners for a specific namespace
    public func removeListeners(for namespace: String) {
        for key in listeners.keys {
            listeners[key]?.removeAll { $0.namespace == namespace }
        }
    }

    // MARK: - Built-in Events

    /// Standard event names
    public enum StandardEvent: String {
        case pluginInstalled  = "plugin_installed"
        case pluginUninstalled = "plugin_uninstalled"
        case scanCompleted    = "scan_completed"
        case dataRefreshed    = "data_refreshed"
        case settingsChanged  = "settings_changed"
        case serverConnected  = "server_connected"
        case serverDisconnected = "server_disconnected"
    }

    /// Convenience: emit a standard event
    public func emit(source: String, event: StandardEvent, payload: [String: Any] = [:]) {
        emit(source: source, name: event.rawValue, payload: payload)
    }
}
