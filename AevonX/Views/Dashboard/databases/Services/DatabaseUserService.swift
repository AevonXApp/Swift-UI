//
//  DatabaseUserService.swift
//  AevonX
//
//  Bridge-backed service for database user management.
//

import Foundation
import AevonXCoreBridge

/// Service for managing database users and privileges.
public actor DatabaseUserService {

    public static let shared = DatabaseUserService()
    private let bridge = DatabasesBridge.shared
    private let ssh = SSHBridge.shared

    private init() {}

    public func listUsers(type: DatabaseType, serverId: String) async throws -> [BridgeDatabaseUser] {
        let cmd = bridge.listUsersCmd(engine: type.rawValue)
        let output = await ssh.executeAsync(serverID: serverId, command: cmd)
        return parseUsers(output)
    }

    public func createUser(username: String, password: String, host: String = "%", type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.createUserCmd(engine: type.rawValue, username: username, password: password, host: host)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") && !result.lowercased().contains("already exists") {
            throw DatabaseServiceError.operationFailed("Create user failed: \(result)")
        }
    }

    public func dropUser(username: String, host: String = "%", type: DatabaseType, serverId: String) async throws {
        let cmd = bridge.dropUserCmd(engine: type.rawValue, username: username, host: host)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Drop user failed: \(result)")
        }
    }

    public func grantPrivileges(username: String, host: String, database: String, privileges: [String] = [], type: DatabaseType, serverId: String) async throws {
        let privsStr = privileges.joined(separator: ",")
        let cmd = bridge.grantPrivilegesCmd(engine: type.rawValue, username: username, host: host, database: database, privileges: privsStr)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Grant privileges failed: \(result)")
        }
    }

    public func revokePrivileges(username: String, host: String, database: String, privileges: [String] = [], type: DatabaseType, serverId: String) async throws {
        let privsStr = privileges.joined(separator: ",")
        let cmd = bridge.revokePrivilegesCmd(engine: type.rawValue, username: username, host: host, database: database, privileges: privsStr)
        let result = await ssh.executeAsync(serverID: serverId, command: cmd)
        if result.lowercased().contains("error") {
            throw DatabaseServiceError.operationFailed("Revoke privileges failed: \(result)")
        }
    }

    private func parseUsers(_ output: String) -> [BridgeDatabaseUser] {
        let lines = output.components(separatedBy: .newlines)
        var users: [BridgeDatabaseUser] = []
        for line in lines {
            let parts = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 1 && !parts[0].isEmpty {
                users.append(BridgeDatabaseUser(
                    username: parts[0],
                    host: parts.count > 1 ? parts[1] : "%"
                ))
            }
        }
        return users
    }
}
