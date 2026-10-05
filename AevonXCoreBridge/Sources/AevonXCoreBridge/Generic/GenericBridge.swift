//
//  GenericBridge.swift
//  AevonXCoreBridge
//
//  Unified bridge to Go Core via the CoreDispatch entry point.
//  Replaces 20+ individual *Bridge.swift files with a single
//  call-by-name interface. All functions use JSON for arguments
//  and return JSON responses.
//
//  Usage:
//    // Simple call (no args)
//    let result = await GenericBridge.call("docker.startCmd")
//
//    // Call with arguments
//    let result = await GenericBridge.call("app.getStatus", [
//        "server_id": serverID,
//        "app_id": appID
//    ])
//
//    // Extract command string (for command-generator functions)
//    let cmd = GenericBridge.command(from: result)
//

import Foundation
import AevonXCoreLib

public final class GenericBridge: @unchecked Sendable {

    public static let shared = GenericBridge()
    private let queue = DispatchQueue(label: "app.aevonx.bridge.generic", qos: .userInitiated, attributes: .concurrent)
    private init() {}

    // MARK: - Primary API

    /// Calls a Go Core function by name with optional arguments.
    /// Returns the raw JSON response string.
    public func call(_ function: String, _ args: [String: Any] = [:]) async -> String {
        let argsJSON = Self.encodeArgs(args)
        return await run { withCArgs { c in CoreDispatch(c.str(function), c.str(argsJSON)) } }
    }

    /// Calls a Go Core function synchronously (for non-SSH, fast operations).
    /// Use this for config, models, and local data that doesn't need async.
    public func callSync(_ function: String, _ args: [String: Any] = [:]) -> String {
        let argsJSON = Self.encodeArgs(args)
        return withCArgs { c in
            let cStr = CoreDispatch(c.str(function), c.str(argsJSON))
            guard let cStr = cStr else { return "" }
            defer { CoreFreeString(cStr) }
            return String(cString: cStr)
        }
    }

    // MARK: - Convenience Extractors

    /// Extracts the "command" field from a response (for command-generator functions).
    /// Most Docker, DB, and Websites functions return {"success":true,"data":{"command":"..."}}
    public static func command(from jsonResponse: String) -> String {
        guard let data = jsonResponse.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = obj["data"] as? [String: Any],
              let cmd = inner["command"] as? String else { return "" }
        return cmd
    }

    /// Extracts the full "data" field as a JSON string.
    public static func dataJSON(from jsonResponse: String) -> String {
        guard let data = jsonResponse.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = obj["data"] else { return "{}" }
        guard let innerData = try? JSONSerialization.data(withJSONObject: inner),
              let str = String(data: innerData, encoding: .utf8) else { return "{}" }
        return str
    }

    /// Checks if the response indicates success.
    public static func isSuccess(_ jsonResponse: String) -> Bool {
        guard let data = jsonResponse.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = obj["success"] as? Bool else { return false }
        return success
    }

    /// Extracts the error message from a failed response.
    public static func error(from jsonResponse: String) -> String? {
        guard let data = jsonResponse.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let err = obj["error"] as? String else { return nil }
        return err
    }

    /// Decodes the "data" field into a Decodable type.
    public static func decode<T: Decodable>(_ type: T.Type, from jsonResponse: String) -> T? {
        guard let data = jsonResponse.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inner = obj["data"],
              let innerData = try? JSONSerialization.data(withJSONObject: inner) else { return nil }
        return try? JSONDecoder().decode(T.self, from: innerData)
    }

    // MARK: - List Available Functions (Debug)

    /// Returns all registered function names from Go Core.
    public func listFunctions() async -> [String] {
        let result = await call("__list_functions__")
        guard let data = result.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let arr = obj["data"] as? [String] else { return [] }
        return arr
    }

    // MARK: - Async Dispatch (Non-Blocking SSH)

    /// Calls a Go Core function via the async poll pattern.
    /// Unlike `call()`, this does NOT hold a GCD thread while Go executes.
    /// Use this for SSH-dependent operations (stats, app data, etc.).
    public func callAsync(_ function: String, _ args: [String: Any] = [:], pollInterval: TimeInterval = 0.05) async -> String {
        let argsJSON = Self.encodeArgs(args)
        let requestID = withCArgs { c in AsyncCoreDispatch(c.str(function), c.str(argsJSON)) }

        // Poll until result is ready
        while true {
            let ready = AsyncIsReady(UInt64(requestID))
            if ready == 1 {
                // Result is ready — consume it
                guard let cStr = AsyncPoll(UInt64(requestID)) else { return "" }
                defer { CoreFreeString(cStr) }
                return String(cString: cStr)
            } else if ready == -1 {
                return "" // Unknown request
            }
            // Not ready — yield and try again
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
    }

    /// Cancels a pending async request.
    public func cancelAsync(_ requestID: UInt64) {
        AsyncCancel(UInt64(requestID))
    }

    // MARK: - Internal

    private func run(_ block: @escaping @Sendable () -> UnsafeMutablePointer<CChar>?) async -> String {
        await withCheckedContinuation { continuation in
            queue.async {
                let cStr = block()
                let result: String
                if let cStr = cStr {
                    result = String(cString: cStr)
                    CoreFreeString(cStr)
                } else {
                    result = ""
                }
                continuation.resume(returning: result)
            }
        }
    }

    private static func encodeArgs(_ args: [String: Any]) -> String {
        if args.isEmpty { return "{}" }
        guard let data = try? JSONSerialization.data(withJSONObject: args),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}
