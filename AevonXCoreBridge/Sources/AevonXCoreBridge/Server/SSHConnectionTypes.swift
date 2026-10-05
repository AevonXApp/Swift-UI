//
//  SSHConnectionTypes.swift
//  AevonXCoreBridge
//
//  SSH connection types for UI integration
//  These types are used by the UI layer to track connection progress
//

import Foundation

// MARK: - Connection Stage

/// Stages of the SSH connection process
public enum ConnectionStage: String, CaseIterable, Sendable {
    case requestingCAT = "Requesting Authorization"
    case decryptingCAT = "Decrypting Authorization"
    case validatingCAT = "Validating Authorization"
    case authenticating = "Authenticating"
    case decrypting = "Decrypting Credentials"
    case verifyingHostKey = "Verifying Host Key"
    case establishingSSH = "Establishing SSH Connection"
    case testing = "Testing Connection"
    case complete = "Complete"
    case failed = "Failed"
}

// MARK: - Connection Test Result

/// Result of a connection test operation
public struct ConnectionTestResult: Sendable {
    /// Whether the connection test was successful
    public let success: Bool
    
    /// Human-readable message about the result
    public let message: String
    
    /// The stage at which the test completed or failed
    public let stage: ConnectionStage
    
    /// Optional latency measurement in milliseconds
    public let latencyMs: Double?
    
    /// Optional server version string
    public let serverVersion: String?
    
    public init(
        success: Bool,
        message: String,
        stage: ConnectionStage,
        latencyMs: Double? = nil,
        serverVersion: String? = nil
    ) {
        self.success = success
        self.message = message
        self.stage = stage
        self.latencyMs = latencyMs
        self.serverVersion = serverVersion
    }
}

// MARK: - SSH Connection Error

/// Errors that can occur during SSH connection
public enum SSHConnectionError: Error, LocalizedError, Sendable {
    case connectionFailed(String)
    case authenticationFailed(String)
    case timeout
    case invalidCredentials
    case hostKeyVerificationFailed
    case channelCreationFailed
    case commandExecutionFailed(String)
    case notConnected
    case alreadyConnected
    case decryptionFailed(String)
    case catValidationFailed
    case networkUnreachable
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .timeout:
            return "Connection timed out"
        case .invalidCredentials:
            return "Invalid credentials"
        case .hostKeyVerificationFailed:
            return "Host key verification failed"
        case .channelCreationFailed:
            return "Failed to create SSH channel"
        case .commandExecutionFailed(let reason):
            return "Command execution failed: \(reason)"
        case .notConnected:
            return "Not connected to server"
        case .alreadyConnected:
            return "Already connected to server"
        case .decryptionFailed(let reason):
            return "Decryption failed: \(reason)"
        case .catValidationFailed:
            return "CAT validation failed"
        case .networkUnreachable:
            return "Network is unreachable"
        }
    }
}


// MARK: - SSH Service Error

public enum SSHServiceError: Error, LocalizedError {
    case notConnected
    case alreadyConnected
    case connectionFailed(String)
    case authenticationFailed(String)
    case commandFailed(String)
    case timeout
    case invalidCredentials
    case channelCreationFailed
    
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to SSH server"
        case .alreadyConnected:
            return "Already connected to SSH server"
        case .connectionFailed(let msg):
            return "Connection failed: \(msg)"
        case .authenticationFailed(let msg):
            return "Authentication failed: \(msg)"
        case .commandFailed(let msg):
            return "Command failed: \(msg)"
        case .timeout:
            return "Connection timed out"
        case .invalidCredentials:
            return "Invalid credentials"
        case .channelCreationFailed:
            return "Channel creation failed"
        }
    }
}
