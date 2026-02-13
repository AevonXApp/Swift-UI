//
//  DatabaseSection.swift
//  AevonX
//
//  Unified section enum for all database engine detail views
//  Used by MySQL, PostgreSQL, Redis, MongoDB, MariaDB, etc.
//

import Foundation

/// Unified section enum for database engine management
/// Follows the same pattern as PHPSection and NginxSection
public enum DatabaseSection: String, SidebarSection, CaseIterable {
    case overview = "Overview"
    case configuration = "Configuration"
    case logs = "Logs"
    case versions = "Versions"
    case optimization = "Optimization"
    case access = "Access & Users"

    public var id: String { rawValue }

    public var displayName: String { rawValue }

    public var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .configuration: return "slider.horizontal.3"
        case .logs: return "doc.text"
        case .versions: return "number"
        case .optimization: return "chart.line.uptrend.xyaxis"
        case .access: return "person.2"
        }
    }
}

/// Database-specific configuration data holder
public struct DatabaseConfigData {
    public var rawConfig: String = ""
    public var configPath: String = ""
    public var logPath: String = ""
    public var dataPath: String = ""
    public var currentVersion: String = ""
    public var availableVersions: [String] = []
    public var isOptimized: Bool = false

    public init(
        rawConfig: String = "",
        configPath: String = "",
        logPath: String = "",
        dataPath: String = "",
        currentVersion: String = "",
        availableVersions: [String] = [],
        isOptimized: Bool = false
    ) {
        self.rawConfig = rawConfig
        self.configPath = configPath
        self.logPath = logPath
        self.dataPath = dataPath
        self.currentVersion = currentVersion
        self.availableVersions = availableVersions
        self.isOptimized = isOptimized
    }
}
