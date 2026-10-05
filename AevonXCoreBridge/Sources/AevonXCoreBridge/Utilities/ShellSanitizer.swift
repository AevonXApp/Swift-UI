//
//  ShellSanitizer.swift
//  AevonXCoreBridge
//
//  Centralized shell sanitization utility.
//  Prevents command injection in all SSH operations.
//

import Foundation

// MARK: - Shell Sanitizer

/// Provides secure string escaping for shell command construction.
///
/// **Security**: All adapters and SSH operations MUST use these methods
/// instead of raw string interpolation when constructing shell commands.
public enum ShellSanitizer {

    // MARK: - Path & Argument Escaping

    /// Safely quotes a string for use as a shell argument.
    public static func quote(_ argument: String) -> String {
        let escaped = argument.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    /// Safely escapes a file path for shell use.
    public static func escapePath(_ path: String) -> String {
        return quote(path)
    }

    /// Escapes a string for use inside double quotes.
    public static func escapeForDoubleQuotes(_ argument: String) -> String {
        return argument
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "!", with: "\\!")
    }

    // MARK: - Identifier Sanitization

    /// Sanitizes an identifier to contain only safe characters.
    public static func sanitizeIdentifier(_ identifier: String) -> String {
        return String(identifier.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) ||
            scalar == "-" || scalar == "_" || scalar == "."
        })
    }

    /// Sanitizes a service name for systemctl/service commands.
    public static func sanitizeServiceName(_ name: String) -> String {
        return String(name.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) ||
            scalar == "-" || scalar == "_" || scalar == "@" || scalar == "."
        })
    }

    // MARK: - Validation

    /// Validates that a string looks like a safe file path.
    public static func isValidPath(_ path: String) -> Bool {
        let dangerousChars: Set<Character> = [";", "&", "|", "`", "$", "(", ")", "{", "}", "<", ">", "\n", "\r"]
        return path.allSatisfy { !dangerousChars.contains($0) }
    }

    /// Validates that a string is a safe identifier.
    public static func isValidIdentifier(_ identifier: String) -> Bool {
        let pattern = "^[a-zA-Z0-9._-]+$"
        return identifier.range(of: pattern, options: .regularExpression) != nil
    }
}
