//
//  SSHResult.swift
//  AevonXCoreBridge
//
//  Shared SSH command result type used by all bridge services.
//  Parses Go Core's JSON SSH response into a typed Swift struct.
//

import Foundation

// MARK: - SSH Result

/// Parsed SSH command result from Go Core JSON response
public struct SSHResult: Sendable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int
    public let success: Bool

    /// Alias for backwards compatibility
    public var isSuccess: Bool { success }

    public init(stdout: String, stderr: String, exitCode: Int, success: Bool) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
        self.success = success
    }

    /// Parse Go Core's JSON SSH response
    public static func parse(_ json: String) -> SSHResult {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = obj["success"] as? Bool else {
            return SSHResult(stdout: json, stderr: "", exitCode: -1, success: false)
        }

        if let inner = obj["data"] as? [String: Any] {
            return SSHResult(
                stdout: (inner["stdout"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                stderr: inner["stderr"] as? String ?? "",
                exitCode: inner["exit_code"] as? Int ?? 0,
                success: success && (inner["exit_code"] as? Int ?? 0) == 0
            )
        }
        if let error = obj["error"] as? String {
            return SSHResult(stdout: "", stderr: error, exitCode: -1, success: false)
        }
        return SSHResult(stdout: json, stderr: "", exitCode: -1, success: false)
    }
}
