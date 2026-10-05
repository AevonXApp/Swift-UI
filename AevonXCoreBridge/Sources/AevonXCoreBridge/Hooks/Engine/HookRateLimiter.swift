//
//  HookRateLimiter.swift
//  AevonXCoreBridge
//
//  Prevents SSH flooding by capping the number of plugin command calls
//  per namespace within a rolling 60-second window.
//

import Foundation

// MARK: - Rate Limiter

actor HookRateLimiter {

    static let shared = HookRateLimiter()

    private struct Window {
        var count: Int
        var windowStart: Date
    }

    private var windows: [String: Window] = [:]
    private var globalWindow: Window?

    /// Maximum plugin command calls allowed per namespace per minute.
    private let maxCallsPerMinute = 60

    /// Maximum total plugin command calls across ALL namespaces per minute.
    /// Prevents bypassing per-namespace limits via many namespaces.
    private let maxGlobalCallsPerMinute = 200

    private init() {}

    /// Checks whether the namespace is within its rate limit and records the call.
    /// Throws `HookRateLimitError.tooManyRequests` if the limit is exceeded.
    func checkAndRecord(namespace: String) throws {
        let now = Date()

        // Global rate limit — cap total SSH calls from all plugins combined
        var global = globalWindow ?? Window(count: 0, windowStart: now)
        if now.timeIntervalSince(global.windowStart) >= 60 {
            global = Window(count: 0, windowStart: now)
        }
        guard global.count < maxGlobalCallsPerMinute else {
            CoreLogger.shared.warning(
                "SECURITY: Global plugin rate limit exceeded (\(maxGlobalCallsPerMinute)/min)",
                module: "HookRateLimiter"
            )
            throw HookRateLimitError.tooManyRequests(namespace: "global", limit: maxGlobalCallsPerMinute)
        }

        // Per-namespace rate limit
        var window = windows[namespace] ?? Window(count: 0, windowStart: now)
        if now.timeIntervalSince(window.windowStart) >= 60 {
            window = Window(count: 0, windowStart: now)
        }
        guard window.count < maxCallsPerMinute else {
            throw HookRateLimitError.tooManyRequests(namespace: namespace, limit: maxCallsPerMinute)
        }

        window.count += 1
        windows[namespace] = window
        global.count += 1
        globalWindow = global
    }

    /// Resets the rate limit window for a specific namespace (e.g. after uninstall).
    func reset(namespace: String) {
        windows.removeValue(forKey: namespace)
    }

    /// Resets all windows (called on plugin reload).
    func resetAll() {
        windows.removeAll()
        globalWindow = nil
    }
}

// MARK: - Error

enum HookRateLimitError: LocalizedError {
    case tooManyRequests(namespace: String, limit: Int)

    var errorDescription: String? {
        switch self {
        case .tooManyRequests(let ns, let limit):
            return "Rate limit exceeded for '\(ns)': maximum \(limit) calls/minute"
        }
    }
}
