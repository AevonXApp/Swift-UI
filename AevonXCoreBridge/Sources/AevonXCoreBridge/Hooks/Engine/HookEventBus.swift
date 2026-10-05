//
//  HookEventBus.swift
//  AevonXCoreBridge
//
//  Inter-hook communication and lifecycle event system.
//  Hooks can subscribe to events from other hooks and the app.
//

import Foundation
import Combine

// MARK: - Hook Event

public struct HookEvent: Identifiable {
    public let id = UUID()
    public let source: String
    public let name: String
    public let payload: [String: Any]
    public let timestamp: Date = Date()
}

// MARK: - Hook Event Bus

@MainActor
public final class HookEventBus: ObservableObject {
    public static let shared = HookEventBus()

    private let eventSubject = PassthroughSubject<HookEvent, Never>()

    public var events: AnyPublisher<HookEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private var listeners: [String: [(namespace: String, handler: (HookEvent) -> Void)]] = [:]

    private init() {}

    // MARK: - Emit

    public func emit(source: String, name: String, payload: [String: Any] = [:]) {
        let event = HookEvent(source: source, name: name, payload: payload)

        eventSubject.send(event)

        if let handlers = listeners[name] {
            for listener in handlers {
                listener.handler(event)
            }
        }

        if let wildcardHandlers = listeners["*"] {
            for listener in wildcardHandlers {
                listener.handler(event)
            }
        }
    }

    // MARK: - Subscribe

    public func on(_ eventName: String, namespace: String, handler: @escaping (HookEvent) -> Void) {
        if listeners[eventName] == nil {
            listeners[eventName] = []
        }
        listeners[eventName]?.append((namespace: namespace, handler: handler))
    }

    public func removeListeners(for namespace: String) {
        for key in listeners.keys {
            listeners[key]?.removeAll { $0.namespace == namespace }
        }
    }

    // MARK: - Built-in Events

    public enum StandardEvent: String {
        case pluginInstalled    = "plugin_installed"
        case pluginUninstalled  = "plugin_uninstalled"
        case scanCompleted      = "scan_completed"
        case dataRefreshed      = "data_refreshed"
        case settingsChanged    = "settings_changed"
        case serverConnected    = "server_connected"
        case serverDisconnected = "server_disconnected"
    }

    public func emit(source: String, event: StandardEvent, payload: [String: Any] = [:]) {
        emit(source: source, name: event.rawValue, payload: payload)
    }
}

// Backward compatibility
public typealias PluginEventBus = HookEventBus
public typealias PluginEvent = HookEvent
