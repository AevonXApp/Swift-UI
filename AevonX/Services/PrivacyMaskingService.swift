//
//  PrivacyMaskingService.swift
//  AevonX
//
//  Privacy masking functions for IP addresses, usernames, hostnames
//

import Foundation

struct PrivacyMask {
    /// Masks an IP address: 192.168.0.1 -> 192.***.***.1
    static func ip(_ ip: String) -> String {
        // IPv6
        if ip.contains(":") {
            let parts = ip.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count > 2, let first = parts.first, let last = parts.last else { return ip }
            var masked = [String(first)]
            for i in 1..<(parts.count - 1) {
                masked.append(parts[i].isEmpty ? "" : "***")
            }
            masked.append(String(last))
            return masked.joined(separator: ":")
        }

        // IPv4
        let octets = ip.split(separator: ".")
        guard octets.count == 4 else { return ip }
        return "\(octets[0]).***.***.\(octets[3])"
    }

    /// Masks a username: root -> r**t, admin -> a***n
    static func username(_ username: String) -> String {
        guard username.count > 2, let first = username.first, let last = username.last else {
            return String(repeating: "*", count: username.count)
        }
        let middle = String(repeating: "*", count: username.count - 2)
        return "\(first)\(middle)\(last)"
    }

    /// Masks a hostname: myserver.example.com -> m*******.e******.com
    static func hostname(_ hostname: String) -> String {
        let parts = hostname.split(separator: ".")
        guard parts.count >= 2 else {
            return maskWord(String(hostname))
        }
        var masked: [String] = []
        for (index, part) in parts.enumerated() {
            if index == parts.count - 1 {
                // Keep TLD
                masked.append(String(part))
            } else {
                masked.append(maskWord(String(part)))
            }
        }
        return masked.joined(separator: ".")
    }

    /// Masks a port number: 22 -> **
    static func port(_ port: Int) -> String {
        return String(repeating: "*", count: String(port).count)
    }

    /// Masks a database name: production_db -> p***********b
    static func databaseName(_ name: String) -> String {
        return username(name) // Same pattern as username masking
    }

    // MARK: - Private

    private static func maskWord(_ word: String) -> String {
        guard word.count > 1, let first = word.first else { return "*" }
        let rest = String(repeating: "*", count: word.count - 1)
        return "\(first)\(rest)"
    }
}
