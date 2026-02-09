//
//  DatabaseInfo.swift
//  AevonX
//
//  Comprehensive database information model
//  Represents a database instance with full metadata and status
//

import Foundation
import AevonXCore

// MARK: - Database Info

/// Represents a complete database instance with all metadata
public struct DatabaseInfo: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var type: DatabaseType
    public var version: String?
    public var status: DatabaseStatus
    public var size: Double // Size in MB
    public var tables: Int
    public var connections: Int
    public var maxConnections: Int?
    
    // Connection details
    public var host: String
    public var port: Int
    public var socket: String?
    
    // Performance metrics
    public var uptime: TimeInterval?
    public var queriesPerSecond: Double?
    public var slowQueries: Int?
    public var cacheHitRatio: Double?
    
    // Timestamps
    public var createdAt: Date?
    public var lastBackupAt: Date?
    public var lastCheckedAt: Date?
    
    // Additional metadata
    public var characterSet: String?
    public var collation: String?
    public var engine: String?
    public var dataDirectory: String?
    
    // Health indicators
    public var isReachable: Bool
    public var healthIssues: [DatabaseHealthIssue]
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: DatabaseType,
        version: String? = nil,
        status: DatabaseStatus = .unknown,
        size: Double = 0,
        tables: Int = 0,
        connections: Int = 0,
        maxConnections: Int? = nil,
        host: String = "localhost",
        port: Int? = nil,
        socket: String? = nil,
        uptime: TimeInterval? = nil,
        queriesPerSecond: Double? = nil,
        slowQueries: Int? = nil,
        cacheHitRatio: Double? = nil,
        createdAt: Date? = nil,
        lastBackupAt: Date? = nil,
        lastCheckedAt: Date? = nil,
        characterSet: String? = nil,
        collation: String? = nil,
        engine: String? = nil,
        dataDirectory: String? = nil,
        isReachable: Bool = false,
        healthIssues: [DatabaseHealthIssue] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.version = version
        self.status = status
        self.size = size
        self.tables = tables
        self.connections = connections
        self.maxConnections = maxConnections
        self.host = host
        self.port = port ?? type.defaultPort
        self.socket = socket
        self.uptime = uptime
        self.queriesPerSecond = queriesPerSecond
        self.slowQueries = slowQueries
        self.cacheHitRatio = cacheHitRatio
        self.createdAt = createdAt
        self.lastBackupAt = lastBackupAt
        self.lastCheckedAt = lastCheckedAt
        self.characterSet = characterSet
        self.collation = collation
        self.engine = engine
        self.dataDirectory = dataDirectory
        self.isReachable = isReachable
        self.healthIssues = healthIssues
    }
    
    /// Formatted size string
    public var formattedSize: String {
        if size >= 1024 * 1024 {
            return String(format: "%.2f TB", size / (1024 * 1024))
        } else if size >= 1024 {
            return String(format: "%.2f GB", size / 1024)
        } else {
            return String(format: "%.0f MB", size)
        }
    }
    
    /// Formatted uptime string
    public var formattedUptime: String {
        guard let uptime = uptime else { return "Unknown" }
        
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Connection string representation
    public var connectionString: String {
        if let socket = socket, !socket.isEmpty {
            return "socket:\(socket)"
        }
        return "\(host):\(port)"
    }
    
    /// Whether the database is in a healthy state
    public var isHealthy: Bool {
        status == .online && isReachable && healthIssues.isEmpty
    }
    
    /// Overall health score (0-100)
    public var healthScore: Int {
        var score = 100
        
        if status != .online { score -= 30 }
        if !isReachable { score -= 40 }
        score -= healthIssues.count * 10
        
        return max(0, score)
    }
}

// MARK: - Database Status

public enum DatabaseStatus: String, Codable, CaseIterable {
    case online = "online"
    case offline = "offline"
    case starting = "starting"
    case stopping = "stopping"
    case error = "error"
    case maintenance = "maintenance"
    case unknown = "unknown"
    case notInstalled = "not_installed"
    
    public var isActive: Bool {
        self == .online
    }
}

// MARK: - Database Health Issue

public struct DatabaseHealthIssue: Identifiable, Codable, Hashable {
    public let id: UUID
    public var severity: HealthSeverity
    public var title: String
    public var description: String
    public var recommendation: String?
    public var detectedAt: Date
    
    public init(
        id: UUID = UUID(),
        severity: HealthSeverity,
        title: String,
        description: String,
        recommendation: String? = nil,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.description = description
        self.recommendation = recommendation
        self.detectedAt = detectedAt
    }
}



// MARK: - Database User Info

/// Represents a database user with privileges
public struct DatabaseUserInfo: Identifiable, Codable, Hashable {
    public let id: UUID
    public var username: String
    public var host: String
    public var privileges: [DatabasePrivilege]
    public var maxConnections: Int?
    public var sslRequired: Bool
    public var passwordExpiry: Date?
    public var lastActive: Date?
    public var isLocked: Bool
    
    public init(
        id: UUID = UUID(),
        username: String,
        host: String = "%",
        privileges: [DatabasePrivilege] = [],
        maxConnections: Int? = nil,
        sslRequired: Bool = false,
        passwordExpiry: Date? = nil,
        lastActive: Date? = nil,
        isLocked: Bool = false
    ) {
        self.id = id
        self.username = username
        self.host = host
        self.privileges = privileges
        self.maxConnections = maxConnections
        self.sslRequired = sslRequired
        self.passwordExpiry = passwordExpiry
        self.lastActive = lastActive
        self.isLocked = isLocked
    }
}

// MARK: - Database Privilege

public struct DatabasePrivilege: Identifiable, Codable, Hashable {
    public let id: UUID
    public var database: String
    public var table: String
    public var permission: String
    public var grantOption: Bool
    
    public init(
        id: UUID = UUID(),
        database: String,
        table: String = "*",
        permission: String,
        grantOption: Bool = false
    ) {
        self.id = id
        self.database = database
        self.table = table
        self.permission = permission
        self.grantOption = grantOption
    }
}

// MARK: - Database Connection Config

/// Configuration for connecting to a database
public struct DatabaseConnectionConfig: Codable {
    public var host: String
    public var port: Int
    public var username: String
    public var password: String?
    public var database: String?
    public var sslMode: SSLMode
    public var sslCertificate: String?
    public var sslKey: String?
    public var sslCA: String?
    public var connectionTimeout: Int
    public var queryTimeout: Int
    
    public init(
        host: String = "localhost",
        port: Int = 3306,
        username: String = "root",
        password: String? = nil,
        database: String? = nil,
        sslMode: SSLMode = .prefer,
        sslCertificate: String? = nil,
        sslKey: String? = nil,
        sslCA: String? = nil,
        connectionTimeout: Int = 30,
        queryTimeout: Int = 300
    ) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.database = database
        self.sslMode = sslMode
        self.sslCertificate = sslCertificate
        self.sslKey = sslKey
        self.sslCA = sslCA
        self.connectionTimeout = connectionTimeout
        self.queryTimeout = queryTimeout
    }
}

public enum SSLMode: String, Codable, CaseIterable {
    case disable = "disable"
    case allow = "allow"
    case prefer = "prefer"
    case require = "require"
    case verifyCA = "verify-ca"
    case verifyFull = "verify-full"
}

// MARK: - Database Installation State

/// Represents the installation state of a database on a server
public struct DatabaseInstallationState: Identifiable, Codable {
    public let id: UUID
    public var type: DatabaseType
    public var isInstalled: Bool
    public var installedVersion: String?
    public var installPath: String?
    public var serviceStatus: ServiceStatus
    public var isRunning: Bool
    public var lastCheckedAt: Date
    public var availableVersions: [DatabaseVersion]
    public var recommendedVersion: DatabaseVersion?
    
    public init(
        id: UUID = UUID(),
        type: DatabaseType,
        isInstalled: Bool = false,
        installedVersion: String? = nil,
        installPath: String? = nil,
        serviceStatus: ServiceStatus = .unknown,
        isRunning: Bool = false,
        lastCheckedAt: Date = Date(),
        availableVersions: [DatabaseVersion] = [],
        recommendedVersion: DatabaseVersion? = nil
    ) {
        self.id = id
        self.type = type
        self.isInstalled = isInstalled
        self.installedVersion = installedVersion
        self.installPath = installPath
        self.serviceStatus = serviceStatus
        self.isRunning = isRunning
        self.lastCheckedAt = lastCheckedAt
        self.availableVersions = availableVersions
        self.recommendedVersion = recommendedVersion
    }
}

public enum ServiceStatus: String, Codable {
    case active = "active"
    case inactive = "inactive"
    case failed = "failed"
    case unknown = "unknown"
    case notInstalled = "not_installed"
}

// MARK: - Database Version (UI Layer)

/// Represents an available database version for installation (UI Layer)
/// Note: AevonXCore has a different DatabaseVersion type for Core layer
public struct DatabaseVersion: Identifiable, Codable, Hashable {
    public let id: UUID
    public var version: String
    public var releaseDate: Date?
    public var isLTS: Bool
    public var isStable: Bool
    public var isRecommended: Bool
    public var changelog: String?
    public var downloadSize: Int64?
    public var installCommand: String?
    public var requirements: [String]
    
    public init(
        id: UUID = UUID(),
        version: String,
        releaseDate: Date? = nil,
        isLTS: Bool = false,
        isStable: Bool = true,
        isRecommended: Bool = false,
        changelog: String? = nil,
        downloadSize: Int64? = nil,
        installCommand: String? = nil,
        requirements: [String] = []
    ) {
        self.id = id
        self.version = version
        self.releaseDate = releaseDate
        self.isLTS = isLTS
        self.isStable = isStable
        self.isRecommended = isRecommended
        self.changelog = changelog
        self.downloadSize = downloadSize
        self.installCommand = installCommand
        self.requirements = requirements
    }
}