//
//  ShieldBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for the Go Core Shield (anti-tamper) system.
//  Provides incident reporting, tamper status, and silent telemetry.
//

import Foundation
import AevonXCoreLib

// MARK: - Shield Models

/// Current shield health status.
public struct ShieldHealthStatus: Codable, Sendable {
    public let active: Bool
    public let tamperCount: Int32
    public let incidentCount: Int
    public let uptimeSeconds: Int64

    enum CodingKeys: String, CodingKey {
        case active
        case tamperCount = "tamper_count"
        case incidentCount = "incident_count"
        case uptimeSeconds = "uptime_seconds"
    }
}

/// A detected tampering incident from the shield.
public struct ShieldIncident: Codable, Sendable {
    public let type: String
    public let detail: String
    public let timestamp: Int64
    public let severity: Int

    enum CodingKeys: String, CodingKey {
        case type = "t"
        case detail = "d"
        case timestamp = "ts"
        case severity = "s"
    }

    /// Human-readable incident type.
    public var typeDescription: String {
        switch type {
        case "dbg": return "Debugger Detected"
        case "fri": return "Frida Detected"
        case "inj": return "Library Injection"
        case "tam": return "Tamper Detected"
        case "tmg": return "Timing Anomaly"
        case "env": return "Suspicious Environment"
        case "hpt": return "Honeypot Triggered"
        case "int": return "Binary Modified"
        default:    return "Unknown (\(type))"
        }
    }

    /// Human-readable severity.
    public var severityLabel: String {
        switch severity {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "Critical"
        default: return "Unknown"
        }
    }
}

// MARK: - Shield Bridge

/// Bridge to the Go Core Shield anti-tamper system.
/// Usage:
/// ```swift
/// let status = ShieldBridge.shared.status()
/// let incidents = ShieldBridge.shared.drainAllIncidents()
/// ```
public final class ShieldBridge: @unchecked Sendable {

    public static let shared = ShieldBridge()
    private init() {}

    // MARK: - Status

    /// Returns current shield health status.
    public func status() -> ShieldHealthStatus? {
        let cStr = ShieldStatus()
        guard let cStr = cStr else { return nil }
        defer { CoreFreeString(cStr) }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ShieldHealthStatus.self, from: data)
    }

    /// Returns total tamper events since app launch.
    public var tamperCount: Int {
        Int(ShieldTamperCount())
    }

    /// Returns number of pending (unreported) incidents.
    public var pendingIncidentCount: Int {
        Int(ShieldIncidentCount())
    }

    // MARK: - Incident Collection

    /// Retrieves and removes one pending incident.
    /// Call this periodically (e.g., piggybacked on API requests).
    public func popIncident() -> ShieldIncident? {
        let cStr = ShieldGetPendingIncident()
        guard let cStr = cStr else { return nil }
        defer { CoreFreeString(cStr) }
        let json = String(cString: cStr)
        guard !json.isEmpty, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ShieldIncident.self, from: data)
    }

    /// Drains all pending incidents as an array.
    /// Call this before sending telemetry.
    public func drainAllIncidents() -> [ShieldIncident] {
        let cStr = ShieldGetAllIncidents()
        guard let cStr = cStr else { return [] }
        defer { CoreFreeString(cStr) }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([ShieldIncident].self, from: data)) ?? []
    }

    // MARK: - Convenience

    /// Check if there are any critical incidents pending.
    public var hasCriticalIncidents: Bool {
        pendingIncidentCount > 0
    }
}
