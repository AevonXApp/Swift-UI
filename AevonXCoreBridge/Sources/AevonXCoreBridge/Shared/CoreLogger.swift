//
//  CoreLogger.swift
//  AevonXCoreBridge
//
//  Structured logging using Apple's os.Logger (Unified Logging).
//  Copied from AevonXCore to eliminate AevonXCore dependency.
//

import Foundation
import os.log

/// Log severity levels
public enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    /// Numeric priority for filtering
    public var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
    
    /// Map to os.log type
    public var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
    
    public func shouldLog(currentMinimum: LogLevel) -> Bool {
        return self.priority >= currentMinimum.priority
    }
}

/// Main logging service for the Core module
public final class CoreLogger {
    
    public static let shared = CoreLogger()
    
    public var isEnabled: Bool = true
    public var minimumLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }()
    
    private static let subsystem = "app.aevonx.core"
    private var loggers: [String: Logger] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    private func logger(for module: String) -> Logger {
        lock.lock()
        defer { lock.unlock() }
        if let existing = loggers[module] {
            return existing
        }
        let newLogger = Logger(subsystem: CoreLogger.subsystem, category: module)
        loggers[module] = newLogger
        return newLogger
    }
    
    /// Log a message at the specified level
    public func log(
        _ message: String,
        level: LogLevel = .info,
        module: String = "Core",
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled, level.shouldLog(currentMinimum: minimumLevel) else { return }
        
        let osLogger = logger(for: module)
        let formatted = "[\(level.rawValue)] \(message) | \(function):\(line)"
        
        switch level.osLogType {
        case .debug: osLogger.debug("\(formatted, privacy: .public)")
        case .info: osLogger.info("\(formatted, privacy: .public)")
        case .error: osLogger.error("\(formatted, privacy: .public)")
        case .fault: osLogger.fault("\(formatted, privacy: .public)")
        default: osLogger.log("\(formatted, privacy: .public)")
        }
    }
    
    /// Log a debug message
    public func debug(
        _ message: String,
        module: String = "Core",
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, module: module, function: function, line: line)
    }
    
    /// Log an info message
    public func info(
        _ message: String,
        module: String = "Core",
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, module: module, function: function, line: line)
    }
    
    /// Log a warning message
    public func warning(
        _ message: String,
        module: String = "Core",
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, module: module, function: function, line: line)
    }
    
    /// Log an error message
    public func error(
        _ message: String,
        module: String = "Core",
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, module: module, function: function, line: line)
    }
    
    /// Log a critical message
    public func critical(
        _ message: String,
        module: String = "Core",
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .critical, module: module, function: function, line: line)
    }
    
    /// Log an action
    public func action(
        _ message: String,
        module: String = "Core",
        function: String = #function,
        line: Int = #line
    ) {
        let osLogger = logger(for: module)
        osLogger.info("ACTION: \(message, privacy: .public) | \(function, privacy: .public):\(line, privacy: .public)")
    }
    
    /// Log a response
    public func response(
        _ message: String,
        module: String = "Core",
        function: String = #function,
        line: Int = #line
    ) {
        let osLogger = logger(for: module)
        osLogger.info("RESPONSE: \(message, privacy: .public) | \(function, privacy: .public):\(line, privacy: .public)")
    }
}

// MARK: - Global Convenience Functions

/// Log a debug message using the shared CoreLogger
public func dlog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let module = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    CoreLogger.shared.debug(message, module: module, function: function, line: line)
}

/// Log an info message using the shared CoreLogger
public func ilog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let module = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    CoreLogger.shared.info(message, module: module, function: function, line: line)
}

/// Log a warning message using the shared CoreLogger
public func wlog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let module = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    CoreLogger.shared.warning(message, module: module, function: function, line: line)
}

/// Log an error message using the shared CoreLogger
public func elog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let module = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    CoreLogger.shared.error(message, module: module, function: function, line: line)
}

/// Log a critical message using the shared CoreLogger
public func clog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    let module = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    CoreLogger.shared.critical(message, module: module, function: function, line: line)
}
