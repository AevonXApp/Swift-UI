//
//  DatabaseLinkInfo.swift
//  AevonX
//
//  Models for linking databases to websites
//

import Foundation
import SwiftUI

// MARK: - Database Link

struct DatabaseLink: Identifiable, Hashable {
    let id = UUID()
    var databaseName: String
    var databaseType: DatabaseType
    var username: String
    var host: String = "localhost"
    var port: Int

    enum DatabaseType: String, CaseIterable, Identifiable {
        case mysql = "MySQL"
        case postgresql = "PostgreSQL"
        case mariadb = "MariaDB"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .mysql, .mariadb: return "cylinder.fill"
            case .postgresql: return "elephant.fill"
            }
        }

        var defaultPort: Int {
            switch self {
            case .mysql, .mariadb: return 3306
            case .postgresql: return 5432
            }
        }

        var color: Color {
            switch self {
            case .mysql: return .orange
            case .postgresql: return .blue
            case .mariadb: return .cyan
            }
        }
    }
}

// MARK: - Connection String Format

enum ConnectionStringFormat: String, CaseIterable, Identifiable {
    case laravel = "Laravel (.env)"
    case wordpress = "WordPress (wp-config.php)"
    case nodejs = "Node.js (DATABASE_URL)"
    case django = "Django (settings.py)"
    case raw = "Raw DSN"

    var id: String { rawValue }

    func generate(link: DatabaseLink, password: String = "YOUR_PASSWORD") -> String {
        switch self {
        case .laravel:
            return """
            DB_CONNECTION=\(link.databaseType == .postgresql ? "pgsql" : "mysql")
            DB_HOST=\(link.host)
            DB_PORT=\(link.port)
            DB_DATABASE=\(link.databaseName)
            DB_USERNAME=\(link.username)
            DB_PASSWORD=\(password)
            """
        case .wordpress:
            return """
            define('DB_NAME', '\(link.databaseName)');
            define('DB_USER', '\(link.username)');
            define('DB_PASSWORD', '\(password)');
            define('DB_HOST', '\(link.host)');
            """
        case .nodejs:
            let scheme = link.databaseType == .postgresql ? "postgresql" : "mysql"
            return "\(scheme)://\(link.username):\(password)@\(link.host):\(link.port)/\(link.databaseName)"
        case .django:
            let engine = link.databaseType == .postgresql ? "django.db.backends.postgresql" : "django.db.backends.mysql"
            return """
            DATABASES = {
                'default': {
                    'ENGINE': '\(engine)',
                    'NAME': '\(link.databaseName)',
                    'USER': '\(link.username)',
                    'PASSWORD': '\(password)',
                    'HOST': '\(link.host)',
                    'PORT': '\(link.port)',
                }
            }
            """
        case .raw:
            let scheme = link.databaseType == .postgresql ? "postgresql" : "mysql"
            return "\(scheme)://\(link.username):\(password)@\(link.host):\(link.port)/\(link.databaseName)"
        }
    }
}

// MARK: - Database Stats

struct DatabaseStats: Identifiable {
    let id = UUID()
    let databaseName: String
    var sizeBytes: Int64
    var tableCount: Int

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }
}
