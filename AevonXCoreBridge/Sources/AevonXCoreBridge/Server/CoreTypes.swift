//
//  CoreTypes.swift
//  AevonXCore
//
//  Shared types used across AevonXCore modules
//

import Foundation

// ServiceStatus is already defined in Docker/DockerModels.swift

// MARK: - Adapter Error

public enum AdapterError: Error, LocalizedError {
    case serviceActionFailed(action: String, reason: String)
    case commandFailed(reason: String)
    case notInstalled
    case unsupportedOperation
    case invalidConfiguration(String?)
    case connectionFailed
    case sslOperationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .serviceActionFailed(let action, let reason):
            return "Failed to \(action) service: \(reason)"
        case .commandFailed(let reason):
            return "Command failed: \(reason)"
        case .notInstalled:
            return "Service is not installed"
        case .unsupportedOperation:
            return "This operation is not supported"
        case .invalidConfiguration(let reason):
            if let reason = reason {
                return "Invalid configuration: \(reason)"
            }
            return "Invalid configuration"
        case .connectionFailed:
            return "Failed to connect to service"
        case .sslOperationFailed(let reason):
            return "SSL operation failed: \(reason)"
        }
    }
}
