//
//  HooksBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core Hook/Plugin model operations.
//  Provides JSON decode/encode validation through Go's strong typing.
//

import Foundation
import AevonXCoreLib

public final class HooksBridge: @unchecked Sendable {

    public static let shared = HooksBridge()
    private init() {}

    /// Decode and validate a single plugin definition JSON.
    /// Returns normalised JSON or empty string on failure.
    public func decodePluginDefinition(json: String) -> String {
        withCArgs { c in extractRaw(HookDecodePluginDefinition(c.str(json))) }
    }

    /// Decode and validate a namespace manifest JSON.
    public func decodeManifest(json: String) -> String {
        withCArgs { c in extractRaw(HookDecodeManifest(c.str(json))) }
    }

    /// Decode and validate a batch array of plugin definitions.
    public func decodePluginBatch(json: String) -> String {
        withCArgs { c in extractRaw(HookDecodePluginBatch(c.str(json))) }
    }

    // MARK: - Helpers

    private func extractRaw(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = resp["success"] as? Bool, success,
              let value = resp["data"] as? String else { return "" }
        return value
    }
}
