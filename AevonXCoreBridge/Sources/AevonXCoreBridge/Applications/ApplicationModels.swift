//
//  ApplicationModels.swift
//  AevonXCoreBridge
//
//  Codable models matching Go Core application management types.
//  All types mirror the Go structs in pkg/remote/applications/models.go.
//

import Foundation

// MARK: - App Info

/// Discovery metadata for an installed application.
public struct BridgeAppInfo: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let serviceType: String
    public let installed: Bool
    public let version: String?
    public let state: String
    public let pid: Int?
    public let uptime: String?
    public let icon: String
    public let accentHex: String

    private enum CodingKeys: String, CodingKey {
        case id, name
        case serviceType = "service_type"
        case installed, version, state, pid, uptime, icon
        case accentHex = "accent_hex"
    }

    /// Convenience: is the service currently running?
    public var isRunning: Bool { state == "running" }

    /// Safe icon name — falls back to "app" if the Go bridge returned an empty string.
    public var safeIcon: String { icon.isEmpty ? "app" : icon }
}

// MARK: - App Status

/// Detailed status snapshot for a single application.
public struct BridgeAppStatus: Codable, Sendable {
    public let id: String
    public let state: String
    public let version: String
    public let pid: Int
    public let uptime: String
    public let configValid: Bool
    public let configError: String?
    public let memoryUsage: String?
    public let connections: Int
    public let requestsPerSec: Double
    public let workerCount: Int

    private enum CodingKeys: String, CodingKey {
        case id, state, version, pid, uptime
        case configValid = "config_valid"
        case configError = "config_error"
        case memoryUsage = "memory_usage"
        case connections
        case requestsPerSec = "requests_per_sec"
        case workerCount = "worker_count"
    }

    public var isRunning: Bool { state == "running" }
}

// MARK: - Config

/// A configuration file on the server.
public struct BridgeAppConfig: Codable, Identifiable, Sendable {
    public let path: String
    public let name: String
    public let content: String?
    public let isMain: Bool
    public let size: Int?

    public var id: String { path }

    private enum CodingKeys: String, CodingKey {
        case path, name, content
        case isMain = "is_main"
        case size
    }
}

/// Config validation result.
public struct BridgeConfigTestResult: Codable, Sendable {
    public let valid: Bool
    public let output: String
}

// MARK: - Log Entry

/// A single parsed log line.
public struct BridgeAppLogEntry: Codable, Identifiable, Sendable {
    public let timestamp: String?
    public let level: String
    public let message: String
    public let source: String?
    public let clientIP: String?
    public let method: String?
    public let path: String?
    public let status: Int?

    public var id: String { "\(timestamp ?? "")_\(message.prefix(32))" }

    private enum CodingKeys: String, CodingKey {
        case timestamp, level, message, source
        case clientIP = "client_ip"
        case method, path, status
    }
}

// MARK: - Version

/// An installed or available version.
public struct BridgeAppVersion: Codable, Identifiable, Sendable {
    public let version: String
    public let isActive: Bool
    public let channel: String?
    public let installed: Bool

    public var id: String { version }

    private enum CodingKeys: String, CodingKey {
        case version
        case isActive = "is_active"
        case channel, installed
    }
}

// MARK: - Worker

/// A single worker/child process.
public struct BridgeWorkerInfo: Codable, Identifiable, Sendable {
    public let pid: Int
    public let cpuPercent: Double
    public let memoryMB: Double
    public let connections: Int
    public let state: String

    public var id: Int { pid }

    private enum CodingKeys: String, CodingKey {
        case pid
        case cpuPercent = "cpu_percent"
        case memoryMB = "memory_mb"
        case connections, state
    }
}

// MARK: - Module

/// A compiled-in or loaded module.
public struct BridgeModuleInfo: Codable, Identifiable, Sendable {
    public let name: String
    public let enabled: Bool

    public var id: String { name }
}

// MARK: - Full Batch Data

/// ALL section data returned from a single batched SSH call.
/// Mirrors Go's FullBatchData struct.
public struct BridgeFullBatchData: Codable, Sendable {
    public let status: BridgeAppStatus
    public let configs: [BridgeAppConfig]
    public let installedVersions: [BridgeAppVersion]
    public let availableVersions: [BridgeAppVersion]
    public let workers: [BridgeWorkerInfo]
    public let modules: [BridgeModuleInfo]

    private enum CodingKeys: String, CodingKey {
        case status, configs
        case installedVersions = "installed_versions"
        case availableVersions = "available_versions"
        case workers, modules
    }
}

// MARK: - Performance Score

/// Performance score result with per-category breakdown.
public struct BridgePerformanceScore: Codable, Sendable {
    public let total: Int
    public let categories: [BridgePerfScoreCategory]
    public let suggestions: [String]
}

/// A scored category within the performance report.
public struct BridgePerfScoreCategory: Codable, Sendable, Identifiable {
    public let name: String
    public let score: Int
    public let details: String

    public var id: String { name }
}

// MARK: - Doctor Report

/// Health check report with overall score and individual checks.
public struct BridgeDoctorReport: Codable, Sendable {
    public let score: Int
    public let checks: [BridgeDoctorCheck]
}

/// A single health check result.
public struct BridgeDoctorCheck: Codable, Sendable, Identifiable {
    public let name: String
    public let status: String
    public let message: String
    public let detail: String?

    public var id: String { name }
}

// MARK: - Config Snapshot

/// A config snapshot backup.
public struct BridgeConfigSnapshot: Codable, Sendable, Identifiable {
    public let id: String
    public let timestamp: String
    public let size: String
    public let path: String?
}

// MARK: - PHP-Specific Models

/// FPM pool with configuration and metrics.
public struct BridgePHPPool: Codable, Sendable, Identifiable {
    public let name: String
    public let enabled: Bool
    public let pm: String
    public let maxChildren: Int
    public let listen: String
    public let user: String
    public let group: String

    public var id: String { name }

    private enum CodingKeys: String, CodingKey {
        case name, enabled, pm
        case maxChildren = "max_children"
        case listen, user, group
    }
}

/// OPcache and JIT statistics.
public struct BridgeOPcacheStatus: Codable, Sendable {
    public let enabled: Bool
    public let cachedScripts: Int
    public let cachedKeys: Int
    public let maxKeys: Int
    public let hitRate: Double?
    public let hits: Int64
    public let misses: Int64
    public let jitEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case enabled
        case cachedScripts = "cached_scripts"
        case cachedKeys = "cached_keys"
        case maxKeys = "max_keys"
        case hitRate = "hit_rate"
        case hits, misses
        case jitEnabled = "jit_enabled"
    }
}

/// PHP session handler configuration and metrics.
public struct BridgePHPSessionInfo: Codable, Sendable {
    public let handler: String
    public let savePath: String?
    public let cookieHttponly: Bool
    public let cookieSecure: Bool
    public let cookieSamesite: String?
    public let useStrictMode: Bool
    public let activeCount: Int
    public let diskUsage: String?

    private enum CodingKeys: String, CodingKey {
        case handler
        case savePath = "save_path"
        case cookieHttponly = "cookie_httponly"
        case cookieSecure = "cookie_secure"
        case cookieSamesite = "cookie_samesite"
        case useStrictMode = "use_strict_mode"
        case activeCount = "active_count"
        case diskUsage = "disk_usage"
    }
}

/// Xdebug installation and configuration.
public struct BridgeXdebugInfo: Codable, Sendable {
    public let installed: Bool
    public let enabled: Bool
    public let version: String?
    public let mode: String
    public let clientHost: String?
    public let clientPort: Int
    public let idekey: String?

    private enum CodingKeys: String, CodingKey {
        case installed, enabled, version, mode
        case clientHost = "client_host"
        case clientPort = "client_port"
        case idekey
    }
}

/// Composer installation and audit data.
public struct BridgeComposerInfo: Codable, Sendable {
    public let installed: Bool
    public let version: String?
    public let globalPackages: [BridgeComposerPackage]?
    public let vulnerabilities: [BridgeComposerVulnerability]?

    private enum CodingKeys: String, CodingKey {
        case installed, version
        case globalPackages = "global_packages"
        case vulnerabilities
    }
}

/// A Composer package.
public struct BridgeComposerPackage: Codable, Sendable, Identifiable {
    public let name: String
    public let version: String

    public var id: String { name }
}

/// A known vulnerability in a Composer package.
public struct BridgeComposerVulnerability: Codable, Sendable, Identifiable {
    public let package: String
    public let version: String
    public let advisory: String
    public let severity: String

    public var id: String { "\(package)_\(advisory)" }
}

