//
//  AsyncBridge.swift
//  AevonXCoreBridge
//
//  Non-blocking async bridge that avoids tying up GCD threads during SSH wait.
//
//  Instead of blocking a DispatchQueue thread for the entire SSH round-trip,
//  this bridge starts the operation in Go (which uses its own goroutine pool)
//  and polls for completion using Swift structured concurrency (Task.sleep).
//
//  Usage:
//    let result = try await AsyncBridge.shared.getFullData(serverID: id, appID: "nginx")
//    // result is a JSON string, ready for decoding
//

import Foundation
import AevonXCoreLib

/// Non-blocking async bridge to Go Core.
/// Operations return immediately with a request ID, then poll for completion
/// without holding a GCD thread.
public final class AsyncBridge: @unchecked Sendable {

    public static let shared = AsyncBridge()
    private init() {}

    /// Poll interval in nanoseconds (5ms — balances latency vs CPU)
    private let pollIntervalNs: UInt64 = 5_000_000

    // MARK: - Application Data

    /// Fetches ALL section data for an application without blocking a GCD thread.
    public func getFullData(serverID: String, appID: String) async throws -> String {
        let requestID = withCArgs { c in AsyncAppGetFullData(c.str(serverID), c.str(appID)) }
        return try await pollForResult(requestID: requestID)
    }

    /// Discovers all installed applications without blocking a GCD thread.
    public func discoverApps(serverID: String) async throws -> String {
        let requestID = withCArgs { c in AsyncAppDiscoverApps(c.str(serverID)) }
        return try await pollForResult(requestID: requestID)
    }

    /// Gets status for a specific application without blocking a GCD thread.
    public func getStatus(serverID: String, appID: String) async throws -> String {
        let requestID = withCArgs { c in AsyncAppGetStatus(c.str(serverID), c.str(appID)) }
        return try await pollForResult(requestID: requestID)
    }

    /// Executes an SSH command without blocking a GCD thread.
    public func sshExecute(serverID: String, command: String) async throws -> String {
        let requestID = withCArgs { c in AsyncSSHExecute(c.str(serverID), c.str(command)) }
        return try await pollForResult(requestID: requestID)
    }

    // MARK: - Cancel

    /// Cancels a pending async request.
    public func cancel(requestID: UInt64) {
        AsyncCancel(CUnsignedLongLong(requestID))
    }

    // MARK: - Internal

    /// Polls for an async result using cooperative Task.sleep.
    /// Supports Task cancellation — will clean up the Go-side request on cancel.
    private func pollForResult(requestID: CUnsignedLongLong) async throws -> String {
        while true {
            // Check for Swift Task cancellation
            try Task.checkCancellation()

            let result = AsyncPoll(requestID)
            if let result = result {
                let str = String(cString: result)
                CoreFreeString(result)
                return str
            }

            // Cooperative sleep — doesn't block any thread
            try await Task.sleep(nanoseconds: pollIntervalNs)
        }
    }
}
