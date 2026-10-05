//
//  HookSettingsStore.swift
//  AevonXCoreBridge
//
//  Persistent key-value settings storage per hook namespace.
//  Settings are stored in UserDefaults under a hook-specific prefix.
//

import Foundation
import Combine

// MARK: - Hook Settings Store

@MainActor
public final class HookSettingsStore: ObservableObject {
    public static let shared = HookSettingsStore()

    private let defaults = UserDefaults.standard
    private let prefix = "app.aevonx.plugin.settings."

    @Published public var lastUpdated: Date = Date()

    private init() {}

    // MARK: - Read

    public func getString(_ key: String, namespace: String) -> String? {
        defaults.string(forKey: fullKey(key, namespace: namespace))
    }

    public func getBool(_ key: String, namespace: String) -> Bool {
        defaults.bool(forKey: fullKey(key, namespace: namespace))
    }

    public func getInt(_ key: String, namespace: String) -> Int {
        defaults.integer(forKey: fullKey(key, namespace: namespace))
    }

    public func getDouble(_ key: String, namespace: String) -> Double {
        defaults.double(forKey: fullKey(key, namespace: namespace))
    }

    public func getData(_ key: String, namespace: String) -> Data? {
        defaults.data(forKey: fullKey(key, namespace: namespace))
    }

    public func getJSON(_ key: String, namespace: String) -> [String: Any]? {
        guard let data = getData(key, namespace: namespace),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    public func getAll(namespace: String) -> [String: Any] {
        let nsPrefix = fullKey("", namespace: namespace)
        var result: [String: Any] = [:]
        for (key, value) in defaults.dictionaryRepresentation() {
            if key.hasPrefix(nsPrefix) {
                let shortKey = String(key.dropFirst(nsPrefix.count))
                result[shortKey] = value
            }
        }
        return result
    }

    // MARK: - Write

    public func set(_ value: Any?, forKey key: String, namespace: String) {
        defaults.set(value, forKey: fullKey(key, namespace: namespace))
        lastUpdated = Date()

        HookEventBus.shared.emit(
            source: namespace,
            event: .settingsChanged,
            payload: ["key": key, "namespace": namespace]
        )
    }

    public func setJSON(_ dict: [String: Any], forKey key: String, namespace: String) {
        if let data = try? JSONSerialization.data(withJSONObject: dict) {
            defaults.set(data, forKey: fullKey(key, namespace: namespace))
            lastUpdated = Date()
        }
    }

    // MARK: - Delete

    public func remove(_ key: String, namespace: String) {
        defaults.removeObject(forKey: fullKey(key, namespace: namespace))
        lastUpdated = Date()
    }

    public func removeAll(namespace: String) {
        let nsPrefix = fullKey("", namespace: namespace)
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix(nsPrefix) {
                defaults.removeObject(forKey: key)
            }
        }
        lastUpdated = Date()
    }

    // MARK: - Private

    private func fullKey(_ key: String, namespace: String) -> String {
        "\(prefix)\(namespace).\(key)"
    }
}

// Backward compatibility
public typealias PluginSettingsStore = HookSettingsStore
