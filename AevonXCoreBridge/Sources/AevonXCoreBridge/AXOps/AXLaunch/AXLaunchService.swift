//
//  AXLaunchService.swift
//  AevonXCoreBridge
//
//  Actor-based service managing active launches and progress polling.
//  Used by the SwiftUI ViewModel layer.
//

import Foundation

public actor AXLaunchService {
    public static let shared = AXLaunchService()
    private let bridge = AXLaunchBridge.shared

    private var pollingTimers: [String: Bool] = [:]

    private init() {}

    // MARK: - Detection

    public func detectProject(localPath: String) throws -> AXProjectInfo {
        try bridge.detectProject(localPath: localPath)
    }

    public func checkAVX(serverID: String, remotePath: String) throws -> AXAVXCheckResult {
        try bridge.checkAVX(serverID: serverID, remotePath: remotePath)
    }

    // MARK: - Lifecycle

    public func startLaunch(serverID: String, config: AXLaunchConfig) throws -> String {
        let launchID = try bridge.startLaunch(serverID: serverID, config: config)
        pollingTimers[launchID] = true
        return launchID
    }

    public func getProgress(launchID: String) -> AXLaunchProgress {
        bridge.getProgress(launchID: launchID)
    }

    public func getLogs(launchID: String, fromIndex: Int) -> AXLaunchLogsResult {
        bridge.getLogs(launchID: launchID, fromIndex: fromIndex)
    }

    public func cancel(launchID: String) {
        bridge.cancel(launchID: launchID)
        pollingTimers.removeValue(forKey: launchID)
    }

    public func getActiveLaunch(serverID: String) -> AXLaunchChannelInfo? {
        bridge.getActiveLaunch(serverID: serverID)
    }

    public func isPolling(launchID: String) -> Bool {
        pollingTimers[launchID] == true
    }

    public func stopPolling(launchID: String) {
        pollingTimers.removeValue(forKey: launchID)
    }

    // MARK: - Update

    public func computeDiff(serverID: String, localPath: String, remotePath: String) throws -> AXLaunchDiff {
        try bridge.computeDiff(serverID: serverID, localPath: localPath, remotePath: remotePath)
    }

    public func startUpdate(serverID: String, config: AXLaunchConfig) throws -> String {
        let launchID = try bridge.startUpdate(serverID: serverID, config: config)
        pollingTimers[launchID] = true
        return launchID
    }

    // MARK: - Database

    public func testDBConnection(serverID: String, config: AXDatabaseConfig) -> AXDBTestResult {
        bridge.testDBConnection(serverID: serverID, config: config)
    }

    public func listDatabases(serverID: String, engine: String) -> [String] {
        bridge.listDatabases(serverID: serverID, engine: engine)
    }

    // MARK: - History

    public func getHistory(serverID: String, remotePath: String) -> [AXLaunchHistoryEntry] {
        bridge.getHistory(serverID: serverID, remotePath: remotePath)
    }
}
