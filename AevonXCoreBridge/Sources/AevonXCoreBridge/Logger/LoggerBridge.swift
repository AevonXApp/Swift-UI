//
//  LoggerBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core logging controls.
//

import Foundation
import AevonXCoreLib

// MARK: - Log Level

/// Log severity levels matching Go Core.
public enum BridgeLogLevel: Int32, Sendable {
    case debug    = -4
    case info     = 0
    case warning  = 4
    case error    = 8
    case critical = 12
}

// MARK: - Logger Bridge

/// Bridge to Go Core logging system.
/// Allows SwiftUI to control log level and send logs through Go Core.
public final class LoggerBridge: @unchecked Sendable {

    /// Shared instance.
    public static let shared = LoggerBridge()
    private init() {}

    /// Sets the minimum log level at runtime.
    public func setLevel(_ level: BridgeLogLevel) {
        LogSetLevel(level.rawValue)
    }

    /// Returns the current minimum log level.
    public func getLevel() -> BridgeLogLevel {
        let raw = LogGetLevel()
        return BridgeLogLevel(rawValue: raw) ?? .info
    }

    /// Logs a debug message.
    public func debug(_ message: String, module: String = "SwiftUI") {
        withCArgs { c in LogDebug(c.str(message), c.str(module)) }
    }

    /// Logs an informational message.
    public func info(_ message: String, module: String = "SwiftUI") {
        withCArgs { c in LogInfo(c.str(message), c.str(module)) }
    }

    /// Logs a warning message.
    public func warn(_ message: String, module: String = "SwiftUI") {
        withCArgs { c in LogWarn(c.str(message), c.str(module)) }
    }

    /// Logs an error message.
    public func error(_ message: String, module: String = "SwiftUI") {
        withCArgs { c in LogError(c.str(message), c.str(module)) }
    }
}
