//
//  DatabaseType.swift
//  AevonX
//
//  Database Type extensions and UI helpers
//  Note: Core types (DatabaseType, PackageManager, ServerOSInfo) are defined in AevonXCore
//

import Foundation
import SwiftUI
import AevonXCoreBridge

// MARK: - Database Type UI Extensions

/// UI-specific extensions for the DatabaseType enum from AevonXCore
extension DatabaseType {
    
    /// Display name for the database type
    public var displayName: String {
        switch self {
        case .mysql: return "MySQL"
        case .postgresql: return "PostgreSQL"
        case .redis: return "Redis"
        case .mongodb: return "MongoDB"
        case .sqlite: return "SQLite"
        case .mariadb: return "MariaDB"
        case .cockroachdb: return "CockroachDB"
        case .cassandra: return "Cassandra"
        case .elasticsearch: return "Elasticsearch"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
    
    /// System icon name for the database type
    public var iconName: String {
        switch self {
        case .mysql, .postgresql, .mariadb, .sqlite, .cockroachdb:
            return "cylinder.split.1x2"
        case .redis:
            return "bolt.fill"
        case .mongodb:
            return "leaf.fill"
        case .cassandra:
            return "circle.hexagongrid.fill"
        case .elasticsearch:
            return "magnifyingglass"
        case .unknown:
            return "questionmark.circle"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    /// Brand color for the database type
    public var brandColor: Color {
        switch self {
        case .mysql:
            return Color(hex: "#00758F") // MySQL blue
        case .postgresql:
            return Color(hex: "#336791") // PostgreSQL blue
        case .redis:
            return Color(hex: "#DC382D") // Redis red
        case .mongodb:
            return Color(hex: "#47A248") // MongoDB green
        case .sqlite:
            return Color(hex: "#003B57") // SQLite dark blue
        case .mariadb:
            return Color(hex: "#003545") // MariaDB dark
        case .cockroachdb:
            return Color(hex: "#6933FF") // CockroachDB purple
        case .cassandra:
            return Color(hex: "#1287B1") // Cassandra blue
        case .elasticsearch:
            return Color(hex: "#FEC514") // Elasticsearch yellow
        case .unknown:
            return Color.gray
        @unknown default:
            return Color.gray
        }
    }
    
    /// Category of database (SQL, NoSQL, Cache, Search)
    public var category: DatabaseCategory {
        switch self {
        case .mysql, .postgresql, .sqlite, .mariadb, .cockroachdb:
            return .relational
        case .mongodb, .cassandra:
            return .document
        case .redis:
            return .cache
        case .elasticsearch:
            return .search
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    /// Default port for the database
    public var defaultPort: Int {
        switch self {
        case .mysql, .mariadb: return 3306
        case .postgresql, .cockroachdb: return 5432
        case .redis: return 6379
        case .mongodb: return 27017
        case .sqlite: return 0 // File-based, no port
        case .cassandra: return 9042
        case .elasticsearch: return 9200
        case .unknown: return 0
        @unknown default: return 0
        }
    }
    
    /// Whether the database requires a server installation
    public var requiresServerInstallation: Bool {
        switch self {
        case .sqlite: return false
        default: return true
        }
    }
    
    /// Whether the database supports multiple databases/schemas
    public var supportsMultipleDatabases: Bool {
        switch self {
        case .mysql, .postgresql, .mariadb, .cockroachdb, .mongodb, .redis, .sqlite:
            return true
        case .cassandra, .elasticsearch, .unknown:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Whether the database supports users and privileges
    public var supportsUserManagement: Bool {
        switch self {
        case .mysql, .postgresql, .mariadb, .cockroachdb, .mongodb, .cassandra:
            return true
        case .redis, .sqlite, .elasticsearch, .unknown:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Default service names for systemd/init.d
    public var serviceNames: [String] {
        switch self {
        case .mysql:
            return ["mysql", "mysqld", "mysql-server"]
        case .postgresql:
            return ["postgresql", "postgres", "postgresql@*"]
        case .redis:
            return ["redis", "redis-server", "redis@*"]
        case .mongodb:
            return ["mongodb", "mongod", "mongodb-server"]
        case .mariadb:
            return ["mariadb", "mariadbd", "mysql"]
        case .cockroachdb:
            return ["cockroachdb", "cockroach"]
        case .cassandra:
            return ["cassandra", "cassandra-server"]
        case .elasticsearch:
            return ["elasticsearch"]
        case .sqlite, .unknown:
            return []
        @unknown default:
            return []
        }
    }
    
    /// Binary names to check for installation
    public var binaryNames: [String] {
        switch self {
        case .mysql:
            return ["mysql", "mysqld", "mysql-server"]
        case .postgresql:
            return ["psql", "postgres", "postgresql"]
        case .redis:
            return ["redis-server", "redis-cli", "redis"]
        case .mongodb:
            return ["mongod", "mongo", "mongodb"]
        case .mariadb:
            return ["mariadb", "mariadbd", "mysql"]
        case .cockroachdb:
            return ["cockroach", "cockroachdb"]
        case .cassandra:
            return ["cassandra", "cqlsh"]
        case .elasticsearch:
            return ["elasticsearch"]
        case .sqlite:
            return ["sqlite3", "sqlite"]
        case .unknown:
            return []
        @unknown default:
            return []
        }
    }
    
    /// Default config paths — for UI display/reference only.
    /// Actual paths are resolved dynamically by Go Core's ConfigPathCmd().
    public var defaultConfigPaths: [String] {
        switch self {
        case .mysql:
            return ["/etc/mysql/my.cnf", "/etc/my.cnf", "/etc/mysql/mysql.conf.d/mysqld.cnf"]
        case .postgresql:
            return ["/etc/postgresql/*/main/postgresql.conf", "/var/lib/pgsql/data/postgresql.conf"]
        case .redis:
            return ["/etc/redis/redis.conf", "/etc/redis.conf"]
        case .mongodb:
            return ["/etc/mongod.conf", "/etc/mongodb.conf"]
        case .mariadb:
            return ["/etc/mysql/mariadb.conf.d/50-server.cnf", "/etc/my.cnf"]
        case .cockroachdb:
            return ["/etc/cockroachdb/cockroach.conf"]
        case .cassandra:
            return ["/etc/cassandra/cassandra.yaml"]
        case .elasticsearch:
            return ["/etc/elasticsearch/elasticsearch.yml"]
        case .sqlite, .unknown:
            return []
        @unknown default:
            return []
        }
    }
    
    /// Default data directories — for UI display/reference only.
    /// Actual data dirs are detected by Go Core at runtime.
    public var defaultDataDirectories: [String] {
        switch self {
        case .mysql:
            return ["/var/lib/mysql", "/var/mysql"]
        case .postgresql:
            return ["/var/lib/postgresql", "/var/lib/pgsql"]
        case .redis:
            return ["/var/lib/redis", "/var/redis"]
        case .mongodb:
            return ["/var/lib/mongodb", "/data/db"]
        case .mariadb:
            return ["/var/lib/mysql"]
        case .cockroachdb:
            return ["/var/lib/cockroachdb"]
        case .cassandra:
            return ["/var/lib/cassandra"]
        case .elasticsearch:
            return ["/var/lib/elasticsearch"]
        case .sqlite, .unknown:
            return []
        @unknown default:
            return []
        }
    }
    
    /// Command to check version
    public var versionCheckCommand: String {
        switch self {
        case .mysql:
            return "mysql --version"
        case .postgresql:
            return "psql --version"
        case .redis:
            return "redis-server --version"
        case .mongodb:
            return "mongod --version"
        case .sqlite:
            return "sqlite3 --version"
        case .mariadb:
            return "mariadb --version"
        case .cockroachdb:
            return "cockroach version"
        case .cassandra:
            return "cassandra -v"
        case .elasticsearch:
            return "elasticsearch --version"
        case .unknown:
            return "echo 'Unknown database type'"
        @unknown default:
            return "echo 'Unknown database type'"
        }
    }
    
    /// Whether the database is currently supported for AI installation
    public var isAIInstallationSupported: Bool {
        switch self {
        case .mysql, .postgresql, .redis, .mongodb, .mariadb:
            return true
        case .sqlite, .cockroachdb, .cassandra, .elasticsearch, .unknown:
            return false
        @unknown default:
            return false
        }
    }
}

// MARK: - Database Category

/// Categories of databases based on their data model
public enum DatabaseCategory: String, CaseIterable, Identifiable {
    case relational = "Relational"
    case document = "Document"
    case cache = "Cache"
    case search = "Search"
    case graph = "Graph"
    case timeSeries = "Time Series"
    case unknown = "Unknown"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .relational: return "tablecells"
        case .document: return "doc.text"
        case .cache: return "bolt.fill"
        case .search: return "magnifyingglass"
        case .graph: return "point.3.connected.trianglepath.dotted"
        case .timeSeries: return "chart.line.uptrend.xyaxis"
        case .unknown: return "questionmark"
        }
    }
}

