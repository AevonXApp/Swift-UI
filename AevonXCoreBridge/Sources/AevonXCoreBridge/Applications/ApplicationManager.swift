//
//  ApplicationManager.swift
//  AevonXCoreBridge
//
//  Minimal bridge adapter for ApplicationManager — provides only the
//  methods used by AXLogsViewModel (readLogs + blockIP).
//  The full ApplicationManager adapter chain lives in AevonXCore.
//

import Foundation

// MARK: - Application Type

public enum ApplicationType: String, Codable, CaseIterable, Sendable {
    case nginx = "Nginx"
    case apache = "Apache"
    case phpFpm = "PHP-FPM"
    case mysql = "MySQL"
    case postgresql = "PostgreSQL"
    case redis = "Redis"
    case docker = "Docker"
    case supervisor = "Supervisor"
    case elasticsearch = "Elasticsearch"
    case mongodb = "MongoDB"
    case nodejs = "Node.js"
    case python = "Python"
    case rabbitmq = "RabbitMQ"
    case memcached = "Memcached"
    case mariadb = "MariaDB"
    case sqlite = "SQLite"
    case cockroachdb = "CockroachDB"
    case cassandra = "Cassandra"
    case unknown = "Unknown"

    public var displayName: String { rawValue }

    /// The systemd service name for this application
    public var serviceName: String {
        switch self {
        case .nginx: return "nginx"
        case .apache: return "apache2"
        case .phpFpm: return "php-fpm"
        case .mysql: return "mysql"
        case .postgresql: return "postgresql"
        case .redis: return "redis-server"
        case .docker: return "docker"
        case .supervisor: return "supervisor"
        case .elasticsearch: return "elasticsearch"
        case .mongodb: return "mongod"
        case .nodejs: return "node"
        case .python: return "python3"
        case .rabbitmq: return "rabbitmq-server"
        case .memcached: return "memcached"
        case .mariadb: return "mariadb"
        case .sqlite: return "sqlite3"
        case .cockroachdb: return "cockroach"
        case .cassandra: return "cassandra"
        case .unknown: return "unknown"
        }
    }
}

// MARK: - Application Manager Error

public enum ApplicationManagerError: Error, LocalizedError {
    case featureNotSupported(ApplicationType, String)
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .featureNotSupported(let type, let feature):
            return "\(type.displayName) does not support \(feature)"
        case .commandFailed(let msg):
            return "Command failed: \(msg)"
        }
    }
}

// MARK: - Application Manager

/// Minimal bridge adapter providing readLogs and blockIP via SSH.
public actor ApplicationManager {

    public static let shared = ApplicationManager()
    private init() {}

    /// Read application logs via SSH
    public func readLogs(type: ApplicationType, lines: Int = 100, serverId: String) async throws -> String {
        let logPath: String
        switch type {
        case .nginx:
            logPath = "/var/log/nginx/error.log"
        case .apache:
            logPath = "/var/log/apache2/error.log"
        case .phpFpm:
            logPath = "/var/log/php*-fpm.log"
        case .mysql:
            logPath = "/var/log/mysql/error.log"
        case .postgresql:
            logPath = "/var/log/postgresql/postgresql-*-main.log"
        case .redis:
            logPath = "/var/log/redis/redis-server.log"
        case .docker:
            logPath = "/var/log/docker.log"
        case .mongodb:
            logPath = "/var/log/mongodb/mongod.log"
        default:
            logPath = "/var/log/syslog"
        }

        let result = try await SSHBridge.shared.execute(
            "sudo tail -n \(lines) \(logPath) 2>/dev/null || echo 'No logs found'",
            serverId: serverId
        )
        return result.stdout
    }

    /// Block an IP address via iptables
    public func blockIP(_ ip: String, reason: String? = nil, duration: String? = nil, type: ApplicationType, serverId: String) async throws {
        let sanitizedIP = ip.replacingOccurrences(of: "'", with: "")
        let result = try await SSHBridge.shared.execute(
            "sudo iptables -I INPUT -s '\(sanitizedIP)' -j DROP 2>&1 && echo 'OK'",
            serverId: serverId
        )
        if !result.stdout.contains("OK") {
            throw ApplicationManagerError.commandFailed("Failed to block IP: \(result.stderr)")
        }
    }
}
