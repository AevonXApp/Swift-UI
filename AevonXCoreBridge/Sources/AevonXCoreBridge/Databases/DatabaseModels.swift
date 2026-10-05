//
//  DatabaseModels.swift
//  AevonXCoreBridge
//
//  Core database models for the Bridge layer.
//  These replace the types previously defined in AevonXCore.
//

import Foundation

// MARK: - Database Type

/// Represents all supported database engines.
/// Raw values match Go Core engine type constants.
public enum DatabaseType: String, CaseIterable, Identifiable, Codable, Sendable {
    case mysql = "MySQL"
    case postgresql = "PostgreSQL"
    case redis = "Redis"
    case mongodb = "MongoDB"
    case sqlite = "SQLite"
    case mariadb = "MariaDB"
    case cockroachdb = "CockroachDB"
    case cassandra = "Cassandra"
    case elasticsearch = "Elasticsearch"
    case unknown = "Unknown"

    public var id: String { rawValue }

    public var displayName: String { rawValue }

    /// Go Core engine type key (lowercase)
    public var engineKey: String { rawValue.lowercased() }

    /// Icon name for SF Symbols
    public var iconName: String {
        switch self {
        case .mysql: return "cylinder.split.1x2"
        case .postgresql: return "cylinder"
        case .redis: return "memorychip"
        case .mongodb: return "leaf"
        case .sqlite: return "doc"
        case .mariadb: return "cylinder.split.1x2"
        case .cockroachdb: return "network"
        case .cassandra: return "square.grid.3x3"
        case .elasticsearch: return "magnifyingglass"
        case .unknown: return "questionmark.circle"
        }
    }

    /// Whether this is a relational (SQL) database
    public var isRelational: Bool {
        switch self {
        case .mysql, .postgresql, .mariadb, .cockroachdb, .sqlite:
            return true
        default:
            return false
        }
    }

    /// Whether this database supports traditional user management
    public var supportsUsers: Bool {
        switch self {
        case .sqlite:
            return false
        default:
            return true
        }
    }

    /// Whether this database supports table/schema management
    public var supportsTables: Bool {
        switch self {
        case .redis:
            return false
        default:
            return true
        }
    }

    /// Whether this database is a server (vs file-based)
    public var isServerBased: Bool {
        switch self {
        case .sqlite:
            return false
        default:
            return true
        }
    }

    /// Brand color hex string for each database engine
    public var brandColorHex: String {
        switch self {
        case .mysql: return "#00758F"
        case .postgresql: return "#336791"
        case .redis: return "#DC382D"
        case .mongodb: return "#47A248"
        case .sqlite: return "#003B57"
        case .mariadb: return "#003545"
        case .cockroachdb: return "#6933FF"
        case .cassandra: return "#1287B1"
        case .elasticsearch: return "#FEC514"
        case .unknown: return "#888888"
        }
    }
}

// MARK: - Database Status

public enum BridgeDatabaseStatus: String, Codable, Sendable {
    case online = "Online"
    case offline = "Offline"
    case error = "Error"
    case unknown = "Unknown"

    public var color: String {
        switch self {
        case .online: return "green"
        case .offline: return "gray"
        case .error: return "red"
        case .unknown: return "orange"
        }
    }
}

// MARK: - Service Status

public enum BridgeServiceStatus: String, Codable, Sendable {
    case active = "active"
    case inactive = "inactive"
    case failed = "failed"
    case unknown = "unknown"
}

// MARK: - Installation State

public struct BridgeInstallationState: Codable, Sendable {
    public var isInstalled: Bool
    public var version: String
    public var installPath: String
    public var installedVersion: String { version }

    public init(isInstalled: Bool = false, version: String = "", installPath: String = "") {
        self.isInstalled = isInstalled
        self.version = version
        self.installPath = installPath
    }

    /// Synthesized service status based on installation state
    public var serviceStatus: BridgeServiceStatus {
        isInstalled ? .active : .inactive
    }
}

// MARK: - Database Instance Info

public struct BridgeDatabaseInfo: Identifiable, Codable, Sendable {
    public var id: String { name }
    public var name: String
    public var characterSet: String
    public var collation: String
    public var size: Int64
    public var tableCount: Int

    public init(name: String = "", characterSet: String = "", collation: String = "", size: Int64 = 0, tableCount: Int = 0) {
        self.name = name
        self.characterSet = characterSet
        self.collation = collation
        self.size = size
        self.tableCount = tableCount
    }
}

// MARK: - Database User Info

public struct BridgeDatabaseUser: Identifiable, Codable, Sendable {
    public var id: String { "\(username)@\(host)" }
    public var username: String
    public var host: String
    public var privileges: [String]
    public var isLocked: Bool
    public var sslRequired: Bool

    public init(username: String = "", host: String = "%", privileges: [String] = [], isLocked: Bool = false, sslRequired: Bool = false) {
        self.username = username
        self.host = host
        self.privileges = privileges
        self.isLocked = isLocked
        self.sslRequired = sslRequired
    }
}

// MARK: - Table Info

public struct BridgeTableInfo: Identifiable, Codable, Sendable {
    public var id: String { name }
    public var name: String
    public var engine: String
    public var rowCount: Int64
    public var dataSize: Int64
    public var indexSize: Int64
    public var collation: String

    public init(name: String = "", engine: String = "", rowCount: Int64 = 0, dataSize: Int64 = 0, indexSize: Int64 = 0, collation: String = "") {
        self.name = name
        self.engine = engine
        self.rowCount = rowCount
        self.dataSize = dataSize
        self.indexSize = indexSize
        self.collation = collation
    }
}

// MARK: - Column Info

public struct BridgeColumnInfo: Identifiable, Codable, Sendable {
    public var id: String { name }
    public var name: String
    public var type: String
    public var isNullable: Bool
    public var defaultValue: String
    public var isPrimaryKey: Bool
    public var isAutoIncrement: Bool
    public var extra: String

    public init(name: String = "", type: String = "", isNullable: Bool = true, defaultValue: String = "", isPrimaryKey: Bool = false, isAutoIncrement: Bool = false, extra: String = "") {
        self.name = name
        self.type = type
        self.isNullable = isNullable
        self.defaultValue = defaultValue
        self.isPrimaryKey = isPrimaryKey
        self.isAutoIncrement = isAutoIncrement
        self.extra = extra
    }
}

// MARK: - Column Definition (for CREATE TABLE)

public struct BridgeColumnDefinition: Codable, Sendable {
    public var name: String
    public var type: String
    public var length: String?
    public var isNullable: Bool
    public var defaultValue: String
    public var isPrimaryKey: Bool
    public var isAutoIncrement: Bool
    public var isUnique: Bool

    public init(name: String = "", type: String = "VARCHAR", length: String? = "255", isNullable: Bool = true, defaultValue: String = "", isPrimaryKey: Bool = false, isAutoIncrement: Bool = false, isUnique: Bool = false) {
        self.name = name
        self.type = type
        self.length = length
        self.isNullable = isNullable
        self.defaultValue = defaultValue
        self.isPrimaryKey = isPrimaryKey
        self.isAutoIncrement = isAutoIncrement
        self.isUnique = isUnique
    }

    enum CodingKeys: String, CodingKey {
        case name, type, length
        case isNullable = "is_nullable"
        case defaultValue = "default_value"
        case isPrimaryKey = "is_primary_key"
        case isAutoIncrement = "is_auto_increment"
        case isUnique = "is_unique"
    }

    /// Encodes an array of column definitions to JSON for sending to Go Core.
    public static func encodeColumns(_ columns: [BridgeColumnDefinition]) -> String {
        guard let data = try? JSONEncoder().encode(columns),
              let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }
}

// MARK: - Backup Info

public struct BridgeBackupInfo: Identifiable, Codable, Sendable {
    public var id: String { path }
    public var path: String
    public var size: String
    public var date: Date?

    public init(path: String = "", size: String = "", date: Date? = nil) {
        self.path = path
        self.size = size
        self.date = date
    }
}

// MARK: - Query Result

public struct BridgeQueryResult: Codable, Sendable {
    public var columns: [String]
    public var rows: [[String]]
    public var affectedRows: Int64
    public var isSelect: Bool
    public var error: String?

    public var executionTime: Double

    public init(columns: [String] = [], rows: [[String]] = [], affectedRows: Int64 = 0, isSelect: Bool = false, error: String? = nil, executionTime: Double = 0) {
        self.columns = columns
        self.rows = rows
        self.affectedRows = affectedRows
        self.isSelect = isSelect
        self.error = error
        self.executionTime = executionTime
    }
}

// MARK: - Database Metrics

public struct BridgeDatabaseMetrics: Codable, Sendable {
    public var uptime: TimeInterval
    public var connections: Int
    public var maxConnections: Int
    public var queries: Int64
    public var slowQueries: Int64
    public var bufferPoolUsage: Double

    public init(uptime: TimeInterval = 0, connections: Int = 0, maxConnections: Int = 0, queries: Int64 = 0, slowQueries: Int64 = 0, bufferPoolUsage: Double = 0) {
        self.uptime = uptime
        self.connections = connections
        self.maxConnections = maxConnections
        self.queries = queries
        self.slowQueries = slowQueries
        self.bufferPoolUsage = bufferPoolUsage
    }
}

// MARK: - Database Configuration

public struct BridgeDatabaseConfiguration: Codable, Sendable {
    public var configPath: String
    public var content: String

    public init(configPath: String = "", content: String = "") {
        self.configPath = configPath
        self.content = content
    }
}

// MARK: - Table Structure

public struct TableStructure: Sendable {
    public var columns: [BridgeColumnInfo]
    public var primaryKey: [String]
    public var engine: String
    public var collation: String
    public var rowCount: Int64

    public init(columns: [BridgeColumnInfo] = [], primaryKey: [String] = [], engine: String = "", collation: String = "", rowCount: Int64 = 0) {
        self.columns = columns
        self.primaryKey = primaryKey
        self.engine = engine
        self.collation = collation
        self.rowCount = rowCount
    }
}

// MARK: - Table Index

public struct TableIndex: Identifiable, Sendable {
    public var id: String { name }
    public var name: String
    public var columns: [String]
    public var isUnique: Bool
    public var type: String

    public init(name: String = "", columns: [String] = [], isUnique: Bool = false, type: String = "BTREE") {
        self.name = name
        self.columns = columns
        self.isUnique = isUnique
        self.type = type
    }
}

// MARK: - Database Metrics (Legacy Name)

public struct DatabaseMetrics: Codable, Sendable {
    public var uptime: TimeInterval
    public var connections: Int
    public var maxConnections: Int
    public var queries: Int64
    public var slowQueries: Int64
    public var cacheHitRatio: Double
    public var bufferPoolUsage: Double
    public var memoryUsage: Double

    public init(uptime: TimeInterval = 0, connections: Int = 0, maxConnections: Int = 0, queries: Int64 = 0, slowQueries: Int64 = 0, cacheHitRatio: Double = 0, bufferPoolUsage: Double = 0, memoryUsage: Double = 0) {
        self.uptime = uptime
        self.connections = connections
        self.maxConnections = maxConnections
        self.queries = queries
        self.slowQueries = slowQueries
        self.cacheHitRatio = cacheHitRatio
        self.bufferPoolUsage = bufferPoolUsage
        self.memoryUsage = memoryUsage
    }
}

// MARK: - Performance Statistics

public struct PerformanceStatistics: Codable, Sendable {
    public var queriesPerSecond: Double
    public var avgQueryTime: Double
    public var maxQueryTime: Double
    public var activeConnections: Int
    public var threadsCached: Int
    public var threadsRunning: Int
    public var tableOpenCacheHits: Int64
    public var tableOpenCacheMisses: Int64
    public var totalQueries: Int64
    public var indexUsage: Double

    public init(queriesPerSecond: Double = 0, avgQueryTime: Double = 0, maxQueryTime: Double = 0, activeConnections: Int = 0, threadsCached: Int = 0, threadsRunning: Int = 0, tableOpenCacheHits: Int64 = 0, tableOpenCacheMisses: Int64 = 0, totalQueries: Int64 = 0, indexUsage: Double = 0) {
        self.queriesPerSecond = queriesPerSecond
        self.avgQueryTime = avgQueryTime
        self.maxQueryTime = maxQueryTime
        self.activeConnections = activeConnections
        self.threadsCached = threadsCached
        self.threadsRunning = threadsRunning
        self.tableOpenCacheHits = tableOpenCacheHits
        self.tableOpenCacheMisses = tableOpenCacheMisses
        self.totalQueries = totalQueries
        self.indexUsage = indexUsage
    }
}

// MARK: - Backward-Compatible Typealiases
// These map old AevonXCore type names to new Bridge types so UI code compiles.

public typealias TableInfo = BridgeTableInfo
public typealias ColumnInfo = BridgeColumnInfo
public typealias QueryResult = BridgeQueryResult
public typealias BackupInfo = BridgeBackupInfo
public typealias CoreDatabaseUserInfo = BridgeDatabaseUser
public typealias CreateTableColumnDefinition = BridgeColumnDefinition

// MARK: - Log Content

public struct LogContent: Sendable {
    public var content: String
    public var path: String
    public var lineCount: Int

    public init(content: String = "", path: String = "", lineCount: Int = 0) {
        self.content = content
        self.path = path
        self.lineCount = lineCount
    }

    /// Lines computed from content for UI display
    public var lines: [String] {
        content.isEmpty ? [] : content.components(separatedBy: .newlines)
    }
}

// MARK: - Database Configuration (Legacy)

public struct DatabaseConfiguration: Sendable {
    public var configPath: String
    public var content: String
    public var lastModified: Date?
    public var engineType: DatabaseType
    public var settings: [String: String]
    public var rawContent: String

    public init(configPath: String = "", content: String = "", lastModified: Date? = nil) {
        self.configPath = configPath
        self.content = content
        self.lastModified = lastModified
        self.engineType = .unknown
        self.settings = [:]
        self.rawContent = content
    }

    public init(engineType: DatabaseType, settings: [String: String] = [:], rawContent: String = "") {
        self.engineType = engineType
        self.settings = settings
        self.rawContent = rawContent
        self.configPath = ""
        self.content = rawContent
        self.lastModified = nil
    }
}

// MARK: - Database Version

public struct DatabaseVersion: Identifiable, Sendable {
    public var id: String { version }
    public var version: String
    public var isInstalled: Bool
    public var isDefault: Bool
    public var releaseDate: Date?
    public var isLTS: Bool
    public var isStable: Bool
    public var isRecommended: Bool
    public var changelog: String
    public var downloadSize: String
    public var requirements: String

    public init(version: String = "", isInstalled: Bool = false, isDefault: Bool = false, releaseDate: Date? = nil, isLTS: Bool = false, isStable: Bool = true, isRecommended: Bool = false, changelog: String = "", downloadSize: String = "", requirements: String = "") {
        self.version = version
        self.isInstalled = isInstalled
        self.isDefault = isDefault
        self.releaseDate = releaseDate
        self.isLTS = isLTS
        self.isStable = isStable
        self.isRecommended = isRecommended
        self.changelog = changelog
        self.downloadSize = downloadSize
        self.requirements = requirements
    }
}

