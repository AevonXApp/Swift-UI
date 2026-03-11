//
//  DatabaseLogService.swift
//  AevonX
//
//  Bridge-backed service for database log operations.
//

import Foundation
import AevonXCoreBridge

/// Service for retrieving database error and slow query logs.
public actor DatabaseLogService {

    public static let shared = DatabaseLogService()
    private let bridge = DatabasesBridge.shared
    private let ssh = SSHBridge.shared

    private init() {}

    public func getErrorLog(type: DatabaseType, serverId: String, lines: Int = 100) async throws -> String {
        let cmd = bridge.errorLogCmd(engine: type.rawValue, lines: lines)
        return await ssh.executeAsync(serverID: serverId, command: cmd)
    }

    public func getSlowQueryLog(type: DatabaseType, serverId: String, lines: Int = 100) async throws -> String {
        let cmd = bridge.slowQueryLogCmd(engine: type.rawValue, lines: lines)
        return await ssh.executeAsync(serverID: serverId, command: cmd)
    }

    /// Return LogContent for error log (used by ViewModels)
    public func readErrorLog(type: DatabaseType, lines: Int = 100, offset: Int = 0, serverId: String) async throws -> LogContent {
        let raw = try await getErrorLog(type: type, serverId: serverId, lines: lines)
        return LogContent(content: raw, lineCount: raw.components(separatedBy: .newlines).count)
    }

    /// Return LogContent for slow query log (used by ViewModels)
    public func readSlowQueryLog(type: DatabaseType, lines: Int = 100, offset: Int = 0, serverId: String) async throws -> LogContent {
        let raw = try await getSlowQueryLog(type: type, serverId: serverId, lines: lines)
        return LogContent(content: raw, lineCount: raw.components(separatedBy: .newlines).count)
    }
}
