//
//  Models.swift
//  AevonXCoreBridge
//
//  Codable models matching Go bridge JSON responses.
//

import Foundation

// MARK: - Bridge Response

/// Generic response from the Go Core bridge.
public struct BridgeResponse: Codable {
    /// Whether the operation succeeded.
    public let success: Bool

    /// Error message if the operation failed.
    public let error: String?

    /// Raw data payload (JSON encoded).
    public let data: Data?

    /// Unix timestamp of the response.
    public let time: Int?

    private enum CodingKeys: String, CodingKey {
        case success, error, data, time
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        time = try container.decodeIfPresent(Int.self, forKey: .time)

        // The "data" field can be any JSON value — capture it as raw Data
        if container.contains(.data) {
            let rawValue = try container.decode(BridgeAnyCodable.self, forKey: .data)
            data = try JSONEncoder().encode(rawValue)
        } else {
            data = nil
        }
    }
}

// MARK: - SSH Models

/// Result of an SSH command execution.
public struct SSHCommandResult: Codable, Sendable {
    /// Standard output from the command.
    public let stdout: String

    /// Standard error output from the command.
    public let stderr: String

    /// Command exit code (0 = success).
    public let exitCode: Int

    /// Returns true if the command exited with code 0.
    public var isSuccess: Bool { exitCode == 0 }

    public init(stdout: String, stderr: String, exitCode: Int) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }

    private enum CodingKeys: String, CodingKey {
        case stdout, stderr
        case exitCode = "exit_code"
    }
}

/// Information about an active SSH session.
public struct SSHSessionInfo: Codable, Sendable {
    public let serverID: String
    public let host: String
    public let port: Int
    public let state: String
    public let connectedAt: Int?

    private enum CodingKeys: String, CodingKey {
        case serverID = "server_id"
        case host, port, state
        case connectedAt = "connected_at"
    }
}

// MARK: - Errors

/// Errors that can occur in the CoreBridge layer.
public enum CoreBridgeError: Error, LocalizedError {
    case notInitialized
    case nullResponse
    case invalidJSON
    case executionFailed(String)
    case connectionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Go Core has not been initialized. Call CoreBridge.shared.initialize() first."
        case .nullResponse:
            return "Received null response from Go Core."
        case .invalidJSON:
            return "Failed to parse JSON response from Go Core."
        case .executionFailed(let msg):
            return "Command execution failed: \(msg)"
        case .connectionFailed(let msg):
            return "SSH connection failed: \(msg)"
        }
    }
}

// MARK: - BridgeAnyCodable Helper

/// A type-erased Codable value for handling dynamic JSON.
/// Named BridgeAnyCodable to avoid collision with AevonXCore.AnyCodable.
struct BridgeAnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([BridgeAnyCodable].self) {
            value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: BridgeAnyCodable].self) {
            value = dictVal.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [Any]:
            try container.encode(arrayVal.map { BridgeAnyCodable($0) })
        case let dictVal as [String: Any]:
            try container.encode(dictVal.mapValues { BridgeAnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
