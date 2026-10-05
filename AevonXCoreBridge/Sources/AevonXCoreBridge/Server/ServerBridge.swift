//
//  ServerBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core server detection and strategies.
//

import Foundation
import AevonXCoreLib

// MARK: - Server Profile

/// Detected server profile from Go Core.
public struct BridgeServerProfile: Codable, Sendable {
    public let distro: String
    public let distroName: String
    public let version: String
    public let arch: String?
    public let kernel: String?
    public let hostname: String?
    public let initSystem: String
    public let packageManager: String
    public let hasDocker: Bool
    public let hasNginx: Bool
    public let hasApache: Bool
    public let hasPHP: Bool
    public let hasMySQL: Bool
    public let hasPostgres: Bool
    public let hasRedis: Bool
    public let hasMongoDB: Bool
    public let hasNode: Bool
    public let hasPython: Bool
    public let hasGit: Bool

    private enum CodingKeys: String, CodingKey {
        case distro, version, arch, kernel, hostname
        case distroName = "distro_name"
        case initSystem = "init_system"
        case packageManager = "package_manager"
        case hasDocker = "has_docker"
        case hasNginx = "has_nginx"
        case hasApache = "has_apache"
        case hasPHP = "has_php"
        case hasMySQL = "has_mysql"
        case hasPostgres = "has_postgres"
        case hasRedis = "has_redis"
        case hasMongoDB = "has_mongodb"
        case hasNode = "has_node"
        case hasPython = "has_python"
        case hasGit = "has_git"
    }
}

// MARK: - Server Bridge

/// Bridge to Go Core server detection and strategy operations.
public final class ServerBridge: @unchecked Sendable {

    /// Shared instance.
    public static let shared = ServerBridge()
    private init() {}

    /// Detects server profile from SSH probe outputs.
    public func detectProfile(osRelease: String, initProbe: String, softwareProbe: String) -> BridgeServerProfile? {
        let result = withCArgs { c in ServerDetectProfile(c.str(osRelease), c.str(initProbe), c.str(softwareProbe)) }
        defer { CoreFreeString(result) }

        guard let cStr = result else { return nil }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let response = try? JSONDecoder().decode(BridgeResponse.self, from: data),
              response.success,
              let responseData = response.data else {
            return nil
        }
        return try? JSONDecoder().decode(BridgeServerProfile.self, from: responseData)
    }

    /// Returns the shell command for a package operation.
    public func packageCommand(manager: String, operation: String, package: String = "") -> String? {
        let result = withCArgs { c in ServerGetPackageCommand(c.str(manager), c.str(operation), c.str(`package`)) }
        defer { CoreFreeString(result) }
        return extractField(result, field: "command")
    }

    /// Returns the shell command for a service operation.
    public func serviceCommand(initSystem: String, operation: String, service: String) -> String? {
        let result = withCArgs { c in ServerGetServiceCommand(c.str(initSystem), c.str(operation), c.str(service)) }
        defer { CoreFreeString(result) }
        return extractField(result, field: "command")
    }

    private func extractField(_ cStr: UnsafeMutablePointer<CChar>?, field: String) -> String? {
        guard let cStr = cStr else { return nil }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let response = try? JSONDecoder().decode(BridgeResponse.self, from: data),
              response.success,
              let responseData = response.data,
              let dict = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let value = dict[field] as? String else {
            return nil
        }
        return value
    }
}
