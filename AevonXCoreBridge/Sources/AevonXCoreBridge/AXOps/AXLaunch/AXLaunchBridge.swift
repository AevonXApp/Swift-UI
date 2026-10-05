//
//  AXLaunchBridge.swift
//  AevonXCoreBridge
//
//  Swift bridge wrapping the AXLaunch C exports.
//  Provides async, type-safe APIs for the deployment system.
//

import Foundation
import AevonXCoreLib

public final class AXLaunchBridge: @unchecked Sendable {
    public static let shared = AXLaunchBridge()
    private init() {}

    // MARK: - Detection

    public func detectProject(localPath: String) throws -> AXProjectInfo {
        return try withCArgs { c in
            let result = AXLaunchDetectProject(c.str(localPath))
            return try parseData(result)
        }
    }

    public func checkAVX(serverID: String, remotePath: String) throws -> AXAVXCheckResult {
        return try withCArgs { c in
            let result = AXLaunchCheckAVX(c.str(serverID), c.str(remotePath))
            return try parseData(result)
        }
    }

    // MARK: - Lifecycle

    public func startLaunch(serverID: String, config: AXLaunchConfig) throws -> String {
        let configData = try JSONEncoder().encode(config)
        let configJSON = String(data: configData, encoding: .utf8) ?? "{}"
        return try withCArgs { c in
            let result = AXLaunchStart(c.str(serverID), c.str(configJSON))
            let response: AXLaunchStartResponse = try parseData(result)
            return response.launchID
        }
    }

    public func getProgress(launchID: String) -> AXLaunchProgress {
        return withCArgs { c in
            let result = AXLaunchGetProgress(c.str(launchID))
            return (try? parseData(result)) ?? .idle
        }
    }

    public func getLogs(launchID: String, fromIndex: Int) -> AXLaunchLogsResult {
        return withCArgs { c in
            let result = AXLaunchGetLogs(c.str(launchID), Int32(fromIndex))
            return (try? parseData(result)) ?? AXLaunchLogsResult(lines: [], total: 0)
        }
    }

    @discardableResult
    public func cancel(launchID: String) -> Bool {
        return withCArgs { c in
            AXLaunchCancel(c.str(launchID)) == 1
        }
    }

    public func getActiveLaunch(serverID: String) -> AXLaunchChannelInfo? {
        return withCArgs { c in
            let result = AXLaunchGetActive(c.str(serverID))
            let info: AXLaunchChannelInfo? = try? parseData(result)
            if let info, info.launchID.isEmpty { return nil }
            return info
        }
    }

    // MARK: - Update / Delta

    public func computeDiff(serverID: String, localPath: String, remotePath: String) throws -> AXLaunchDiff {
        return try withCArgs { c in
            let result = AXLaunchComputeDiff(c.str(serverID), c.str(localPath), c.str(remotePath))
            return try parseData(result)
        }
    }

    public func startUpdate(serverID: String, config: AXLaunchConfig) throws -> String {
        let configData = try JSONEncoder().encode(config)
        let configJSON = String(data: configData, encoding: .utf8) ?? "{}"
        return try withCArgs { c in
            let result = AXLaunchStartUpdate(c.str(serverID), c.str(configJSON))
            let response: AXLaunchStartResponse = try parseData(result)
            return response.launchID
        }
    }

    // MARK: - Database

    public func testDBConnection(serverID: String, config: AXDatabaseConfig) -> AXDBTestResult {
        let configJSON = (try? JSONEncoder().encode(config)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return withCArgs { c in
            let result = AXLaunchTestDBConnection(c.str(serverID), c.str(configJSON))
            return (try? parseData(result)) ?? AXDBTestResult(success: false, error: "Unknown error")
        }
    }

    public func listDatabases(serverID: String, engine: String) -> [String] {
        return withCArgs { c in
            let result = AXLaunchListDatabases(c.str(serverID), c.str(engine))
            return (try? parseData(result)) ?? []
        }
    }

    // MARK: - History

    public func getHistory(serverID: String, remotePath: String) -> [AXLaunchHistoryEntry] {
        return withCArgs { c in
            let result = AXLaunchGetHistory(c.str(serverID), c.str(remotePath))
            return (try? parseData(result)) ?? []
        }
    }

    // MARK: - Helpers

    private func parseData<T: Decodable>(_ cStr: UnsafeMutablePointer<CChar>?) throws -> T {
        guard let cStr else {
            throw AXLaunchError.nullResponse
        }
        defer { CoreFreeString(cStr) }

        let json = String(cString: cStr)
        guard let jsonData = json.data(using: .utf8) else {
            throw AXLaunchError.invalidJSON
        }

        let response = try JSONDecoder().decode(BridgeDataResponse<T>.self, from: jsonData)
        guard response.success else {
            throw AXLaunchError.bridgeError(response.error ?? "Unknown error")
        }
        guard let data = response.data else {
            throw AXLaunchError.noData
        }
        return data
    }
}

// MARK: - Response Wrapper

private struct BridgeDataResponse<T: Decodable>: Decodable {
    let success: Bool
    let error: String?
    let data: T?
    let time: Int?
}

// MARK: - Errors

public enum AXLaunchError: LocalizedError {
    case nullResponse
    case invalidJSON
    case noData
    case bridgeError(String)

    public var errorDescription: String? {
        switch self {
        case .nullResponse: return "Bridge returned null"
        case .invalidJSON: return "Invalid JSON from bridge"
        case .noData: return "No data in response"
        case .bridgeError(let msg): return msg
        }
    }
}
