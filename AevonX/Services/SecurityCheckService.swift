//
//  SecurityCheckService.swift
//  AevonX
//
//  Runtime security monitoring service
//  Performs periodic integrity checks, jailbreak detection, and anti-debug monitoring
//  Automatically terminates connections on security violations
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - Security Check Result

/// Result of a comprehensive security check
public struct SecurityCheckResult {
    public let isSecure: Bool
    public let integrityPassed: Bool
    public let jailbreakLevel: JailbreakLevel
    public let debuggerDetected: Bool
    public let violations: [SecurityViolation]
    public let timestamp: Date
    
    public init(
        isSecure: Bool,
        integrityPassed: Bool,
        jailbreakLevel: JailbreakLevel,
        debuggerDetected: Bool,
        violations: [SecurityViolation],
        timestamp: Date = Date()
    ) {
        self.isSecure = isSecure
        self.integrityPassed = integrityPassed
        self.jailbreakLevel = jailbreakLevel
        self.debuggerDetected = debuggerDetected
        self.violations = violations
        self.timestamp = timestamp
    }
}

extension SecurityCheckResult: Sendable {}

// MARK: - Security Violation

/// Represents a security violation detected during checks
public struct SecurityViolation: Identifiable {
    public let id = UUID()
    public let type: ViolationType
    public let severity: ViolationSeverity
    public let description: String
    public let timestamp: Date
    
    public init(
        type: ViolationType,
        severity: ViolationSeverity,
        description: String,
        timestamp: Date = Date()
    ) {
        self.type = type
        self.severity = severity
        self.description = description
        self.timestamp = timestamp
    }
}

/// Types of security violations
public enum ViolationType: String {
    case integrityFailure = "integrity_failure"
    case jailbreakDetected = "jailbreak_detected"
    case debuggerDetected = "debugger_detected"
    case codeTampering = "code_tampering"
    case runtimeManipulation = "runtime_manipulation"
    case certificatePinningFailure = "certificate_pinning_failure"
}

/// Severity levels for security violations
public enum ViolationSeverity: Int {
    case warning = 1      // Logged but operation continues
    case critical = 2     // Connections terminated, user notified
    case fatal = 3        // App should exit
}

// MARK: - Jailbreak Level

/// Jailbreak detection levels
public enum JailbreakLevel: Int, CaseIterable {
    case clean = 0        // No jailbreak indicators detected
    case suspicious = 1   // Some suspicious indicators present
    case jailbroken = 2   // Jailbreak confirmed
    
    public var description: String {
        switch self {
        case .clean:
            return "Device appears clean"
        case .suspicious:
            return "Suspicious indicators detected"
        case .jailbroken:
            return "Jailbreak detected"
        }
    }
}

// MARK: - Anti-Debug Result

/// Result of anti-debug check
public struct AntiDebugResult: Sendable {
    public let debuggerDetected: Bool
    public let debuggerType: DebuggerType?

    public nonisolated init(debuggerDetected: Bool, debuggerType: DebuggerType? = nil) {
        self.debuggerDetected = debuggerDetected
        self.debuggerType = debuggerType
    }
}

/// Types of debuggers that may be detected
public enum DebuggerType: String {
    case lldb = "LLDB"
    case gdb = "GDB"
    case xcode = "Xcode"
    case other = "Other"
}

// MARK: - Integrity Check Result

/// Result of integrity check
public struct IntegrityCheckResult: Sendable {
    public let isValid: Bool
    public let checksFailed: [IntegrityFailure]

    public nonisolated init(isValid: Bool, checksFailed: [IntegrityFailure] = []) {
        self.isValid = isValid
        self.checksFailed = checksFailed
    }
}

/// Integrity check failure details
public struct IntegrityFailure {
    public let type: IntegrityCheckType
    public let reason: String
    public let severity: ViolationSeverity
    
    public init(type: IntegrityCheckType, reason: String, severity: ViolationSeverity) {
        self.type = type
        self.reason = reason
        self.severity = severity
    }
}

extension IntegrityFailure: Sendable {}

/// Types of integrity checks
public enum IntegrityCheckType: String {
    case codeSignature = "code_signature"
    case binaryIntegrity = "binary_integrity"
    case runtimeIntegrity = "runtime_integrity"
}

// MARK: - Mock Services for Security Checks

/// Mock integrity checker for security monitoring
public actor IntegrityChecker {
    public static let shared = IntegrityChecker()
    
    public func verifyIntegrity() async throws -> IntegrityCheckResult {
        // In a real implementation, this would verify code signing and binary integrity
        // For now, return valid result
        return IntegrityCheckResult(isValid: true, checksFailed: [])
    }
}

/// Mock jailbreak detector for security monitoring
public actor JailbreakDetector {
    public static let shared = JailbreakDetector()
    
    public struct JailbreakDetectionResult {
        public let level: JailbreakLevel
        public let detectedIndicators: [JailbreakIndicator]
    }
    
    public struct JailbreakIndicator {
        public let description: String
    }
    
    public func detectJailbreak() async -> JailbreakDetectionResult {
        // In a real implementation, this would check for jailbreak indicators
        // For now, return clean result
        return JailbreakDetectionResult(level: .clean, detectedIndicators: [])
    }
}

/// Mock anti-debug service for security monitoring
public actor AntiDebug {
    public static let shared = AntiDebug()
    
    public func checkDebugger() async -> AntiDebugResult {
        // In a real implementation, this would check for debuggers
        // For now, return no debugger detected
        return AntiDebugResult(debuggerDetected: false, debuggerType: nil)
    }
}

// MARK: - Connection State

/// Connection states for server connections
public enum ConnectionState: String {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case error = "error"
}

/// Mock connection pool manager for terminating connections on security violations
public actor ConnectionPoolManager {
    public static let shared = ConnectionPoolManager()
    
    private var connections: [String: ConnectionState] = [:]
    
    public func activeConnections() async -> [String] {
        return connections.filter { $0.value == .connected }.map { $0.key }
    }
    
    public func updateState(serverId: String, to state: ConnectionState) async {
        connections[serverId] = state
    }
}

// MARK: - Security Configuration

/// Security check configuration
public struct SecurityConfiguration {
    public static let integrityCheckInterval: TimeInterval = 300.0  // 5 minutes
    public static let jailbreakCheckInterval: TimeInterval = 60.0   // 1 minute
    public static let antiDebugCheckInterval: TimeInterval = 30.0   // 30 seconds
    public static let enableIntegrityChecking: Bool = true
    public static let enableJailbreakDetection: Bool = true
    public static let enableAntiDebug: Bool = true
}

// MARK: - Security Check Service

/// Runtime security monitoring service
///
/// This service provides continuous security monitoring:
/// - Periodic integrity checks (code signing, binary integrity)
/// - Jailbreak detection monitoring
/// - Anti-debug monitoring
/// - Automatic connection termination on security violations
///
/// The service runs checks at configured intervals and takes action
/// based on the severity of any detected violations.
@MainActor
public class SecurityCheckService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the current security state is secure
    @Published public private(set) var isSecure: Bool = true
    
    /// Current jailbreak detection level
    @Published public private(set) var jailbreakLevel: JailbreakLevel = .clean
    
    /// Whether a debugger is currently detected
    @Published public private(set) var debuggerDetected: Bool = false
    
    /// List of active security violations
    @Published public private(set) var activeViolations: [SecurityViolation] = []
    
    /// Last security check result
    @Published public private(set) var lastCheckResult: SecurityCheckResult?
    
    /// Whether security monitoring is currently active
    @Published public private(set) var isMonitoring: Bool = false
    
    // MARK: - Private Properties
    
    /// Shared singleton instance
    public static let shared = SecurityCheckService()
    
    /// Integrity checker from Core
    private let integrityChecker = IntegrityChecker.shared
    
    /// Jailbreak detector from Core
    private let jailbreakDetector = JailbreakDetector.shared
    
    /// Anti-debug from Core
    private let antiDebug = AntiDebug.shared
    
    /// Connection pool manager for terminating connections
    private let connectionPool = ConnectionPoolManager.shared
    
    /// Logger
    private let logger = CoreLogger.shared
    
    /// Check intervals loaded from Core's InternalConfiguration
    private let integrityCheckInterval: TimeInterval = SecurityConfiguration.integrityCheckInterval
    private let jailbreakCheckInterval: TimeInterval = SecurityConfiguration.jailbreakCheckInterval
    private let antiDebugCheckInterval: TimeInterval = SecurityConfiguration.antiDebugCheckInterval
    
    /// Tasks for periodic checks
    private var integrityCheckTask: Task<Void, Never>?
    private var jailbreakCheckTask: Task<Void, Never>?
    private var antiDebugCheckTask: Task<Void, Never>?
    private var masterMonitoringTask: Task<Void, Never>?
    
    /// Callback for security violations
    private var violationHandler: ((SecurityViolation) -> Void)?
    
    /// Whether to automatically terminate connections on violations
    private var autoTerminateConnections: Bool = true
    
    // MARK: - Initialization
    
    private init() {}
    
    // Deinit cannot capture MainActor-isolated self in Swift 6
    // Cleanup should be manual or rely on Task cancellation
    deinit {
        // Tasks are automatically cancelled when the instance is deallocated
        // if they were stored in .task() modifiers, but here they are properties.
        // However, we cannot safely access them here without isolation issues.
        // Given this is a singleton, deinit is unlikely to be called.
    }
    
    // MARK: - Public Methods
    
    /// Configures the security check service
    /// - Parameters:
    ///   - autoTerminate: Whether to auto-terminate connections on violations
    ///   - violationHandler: Callback when violations are detected
    public func configure(
        autoTerminateConnections: Bool = true,
        onViolation: ((SecurityViolation) -> Void)? = nil
    ) {
        self.autoTerminateConnections = autoTerminateConnections
        self.violationHandler = onViolation
    }
    
    /// Starts continuous security monitoring
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        logger.info("Starting security monitoring", module: "SecurityCheck")
        
        // Perform initial check
        Task {
            await performFullSecurityCheck()
        }
        
        // Start periodic checks
        startIntegrityChecks()
        startJailbreakChecks()
        startAntiDebugChecks()
    }
    
    /// Stops all security monitoring
    public func stopMonitoring() {
        isMonitoring = false
        
        integrityCheckTask?.cancel()
        jailbreakCheckTask?.cancel()
        antiDebugCheckTask?.cancel()
        masterMonitoringTask?.cancel()
        
        integrityCheckTask = nil
        jailbreakCheckTask = nil
        antiDebugCheckTask = nil
        masterMonitoringTask = nil
        
        logger.info("Security monitoring stopped", module: "SecurityCheck")
    }
    
    /// Performs a comprehensive security check immediately
    /// - Returns: The result of the security check
    public func performFullSecurityCheck() async -> SecurityCheckResult {
        var violations: [SecurityViolation] = []
        
        // 1. Integrity Check
        let integrityResult = await performIntegrityCheck()
        if !integrityResult.passed {
            violations.append(contentsOf: integrityResult.violations)
        }
        
        // 2. Jailbreak Check
        let jailbreakResult = await performJailbreakCheck()
        if jailbreakResult.level != JailbreakLevel.clean {
            violations.append(contentsOf: jailbreakResult.violations)
        }
        
        // 3. Anti-Debug Check
        let antiDebugResult = await performAntiDebugCheck()
        if antiDebugResult.debuggerDetected {
            violations.append(contentsOf: antiDebugResult.violations)
        }
        
        // Determine overall security state
        let isSecure = violations.allSatisfy { $0.severity != .fatal }
        let hasCriticalViolations = violations.contains { $0.severity == .critical }
        
        let result = SecurityCheckResult(
            isSecure: isSecure,
            integrityPassed: integrityResult.passed,
            jailbreakLevel: jailbreakResult.level,
            debuggerDetected: antiDebugResult.debuggerDetected,
            violations: violations
        )
        
        // Update published state
        await MainActor.run {
            self.lastCheckResult = result
            self.isSecure = isSecure
            self.jailbreakLevel = jailbreakResult.level
            self.debuggerDetected = antiDebugResult.debuggerDetected
            self.activeViolations = violations
        }
        
        // Handle violations
        for violation in violations {
            await handleViolation(violation)
        }
        
        // Auto-terminate connections if critical violations detected
        if hasCriticalViolations && autoTerminateConnections {
            await terminateAllConnections(reason: "Critical security violation detected")
        }
        
        return result
    }
    
    /// Clears all active violations (use with caution)
    public func clearViolations() {
        activeViolations.removeAll()
        isSecure = true
        logger.warning("Security violations cleared by user", module: "SecurityCheck")
    }
    
    /// Returns a human-readable security status
    public func securityStatusDescription() -> String {
        if isSecure && activeViolations.isEmpty {
            return "Security check passed"
        }
        
        if !isSecure {
            return "Security violations detected - connections disabled"
        }
        
        if !activeViolations.isEmpty {
            let warningCount = activeViolations.filter { $0.severity == .warning }.count
            return "\(warningCount) security warning(s) active"
        }
        
        return "Unknown security state"
    }
    
    // MARK: - Private Methods
    
    /// Performs integrity check
    private func performIntegrityCheck() async -> (passed: Bool, violations: [SecurityViolation]) {
        var violations: [SecurityViolation] = []
        
        // Skip if integrity checking is disabled in Core configuration
        guard SecurityConfiguration.enableIntegrityChecking else {
            return (true, [])
        }
        
        do {
            let result = try await integrityChecker.verifyIntegrity()
            
            if !result.isValid {
                for failure in result.checksFailed {
                    let severity: ViolationSeverity = failure.severity == .critical ? .critical : .warning
                    violations.append(SecurityViolation(
                        type: .integrityFailure,
                        severity: severity,
                        description: "Integrity check failed: \(failure.type.rawValue) - \(failure.reason)"
                    ))
                }
            }
            
            return (result.isValid, violations)
        } catch {
            violations.append(SecurityViolation(
                type: .integrityFailure,
                severity: .warning,
                description: "Integrity check error: \(error.localizedDescription)"
            ))
            return (false, violations)
        }
    }
    
    /// Performs jailbreak check
    private func performJailbreakCheck() async -> (level: JailbreakLevel, violations: [SecurityViolation]) {
        var violations: [SecurityViolation] = []
        
        // Skip if jailbreak detection is disabled in Core configuration
        guard SecurityConfiguration.enableJailbreakDetection else {
            return (JailbreakLevel.clean, [])
        }
        
        let result = await jailbreakDetector.detectJailbreak()
        
        switch result.level {
        case JailbreakLevel.clean:
            break // No violations
            
        case JailbreakLevel.suspicious:
            violations.append(SecurityViolation(
                type: .jailbreakDetected,
                severity: .warning,
                description: "Suspicious indicators detected: \(result.detectedIndicators.map { $0.description }.joined(separator: ", "))"
            ))
            
        case JailbreakLevel.jailbroken:
            violations.append(SecurityViolation(
                type: .jailbreakDetected,
                severity: .critical,
                description: "Jailbreak detected - SSH connections disabled"
            ))
        }
        
        return (result.level, violations)
    }
    
    /// Performs anti-debug check
    private func performAntiDebugCheck() async -> (debuggerDetected: Bool, violations: [SecurityViolation]) {
        var violations: [SecurityViolation] = []
        
        // Skip if anti-debug is disabled in Core configuration
        guard SecurityConfiguration.enableAntiDebug else {
            return (false, [])
        }
        
        let result = await antiDebug.checkDebugger()
        
        if result.debuggerDetected {
            let debuggerType = result.debuggerType?.rawValue ?? "Unknown"
            violations.append(SecurityViolation(
                type: .debuggerDetected,
                severity: .critical,
                description: "Debugger detected: \(debuggerType)"
            ))
        }
        
        return (result.debuggerDetected, violations)
    }
    
    /// Handles a security violation
    private func handleViolation(_ violation: SecurityViolation) async {
        logger.error("Security violation: \(violation.type.rawValue) - \(violation.description)", module: "SecurityCheck")
        
        // Call violation handler
        await MainActor.run {
            violationHandler?(violation)
        }
        
        // Take action based on severity
        switch violation.severity {
        case .warning:
            // Just log - operation continues
            break
            
        case .critical:
            // Terminate connections
            if autoTerminateConnections {
                await terminateAllConnections(reason: violation.description)
            }
            
        case .fatal:
            // Terminate connections and notify app
            if autoTerminateConnections {
                await terminateAllConnections(reason: violation.description)
            }
            // App should handle fatal violations by exiting or locking
            logger.error("FATAL security violation detected", module: "SecurityCheck")
        }
    }
    
    /// Terminates all active SSH connections
    private func terminateAllConnections(reason: String) async {
        logger.error("Terminating all connections due to: \(reason)", module: "SecurityCheck")
        
        // Get all active connections and disconnect them
        let activeConnections = await connectionPool.activeConnections()
        for serverId in activeConnections {
            await connectionPool.updateState(serverId: serverId, to: ConnectionState.disconnected)
            logger.info("Connection terminated for server: \(serverId)", module: "SecurityCheck")
        }
        
        await MainActor.run {
            // Post notification for UI to respond
            NotificationCenter.default.post(
                name: .securityViolationConnectionsTerminated,
                object: nil,
                userInfo: ["reason": reason]
            )
        }
    }
    
    // MARK: - Periodic Check Starters
    
    private func startIntegrityChecks() {
        integrityCheckTask?.cancel()
        integrityCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                let result = await self.performIntegrityCheck()
                if !result.passed {
                    for violation in result.violations {
                        await self.handleViolation(violation)
                    }
                }
                
                try? await Task.sleep(nanoseconds: UInt64(self.integrityCheckInterval * 1_000_000_000))
            }
        }
    }
    
    private func startJailbreakChecks() {
        jailbreakCheckTask?.cancel()
        jailbreakCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                let result = await self.performJailbreakCheck()
                if result.level != JailbreakLevel.clean {
                    for violation in result.violations {
                        await self.handleViolation(violation)
                    }
                }
                
                // Update published state
                await MainActor.run {
                    self.jailbreakLevel = result.level
                }
                
                try? await Task.sleep(nanoseconds: UInt64(self.jailbreakCheckInterval * 1_000_000_000))
            }
        }
    }
    
    private func startAntiDebugChecks() {
        antiDebugCheckTask?.cancel()
        antiDebugCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                let result = await self.performAntiDebugCheck()
                if result.debuggerDetected {
                    for violation in result.violations {
                        await self.handleViolation(violation)
                    }
                }
                
                // Update published state
                await MainActor.run {
                    self.debuggerDetected = result.debuggerDetected
                }
                
                try? await Task.sleep(nanoseconds: UInt64(self.antiDebugCheckInterval * 1_000_000_000))
            }
        }
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    /// Posted when connections are terminated due to security violations
    static let securityViolationConnectionsTerminated = Notification.Name("securityViolationConnectionsTerminated")
}
