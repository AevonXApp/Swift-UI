//
//  StaticData.swift
//  AevonXCoreBridge
//
//  Static data that never changes at runtime.
//  Moved from Go → CGo → JSON → Swift to compile-time constants.
//  Eliminates serialization overhead for fixed catalogs.
//

import Foundation

// MARK: - Database Types

/// All supported database engine types.
/// Mirrors: core-go/pkg/models/types/database.go
public enum AXDatabaseType: String, CaseIterable, Sendable {
    case mysql         = "MySQL"
    case postgresql    = "PostgreSQL"
    case redis         = "Redis"
    case mongodb       = "MongoDB"
    case sqlite        = "SQLite"
    case mariadb       = "MariaDB"
    case cockroachdb   = "CockroachDB"
    case cassandra     = "Cassandra"
    case elasticsearch = "Elasticsearch"

    /// Lowercase key for API communication.
    public var apiKey: String {
        switch self {
        case .mysql:         return "mysql"
        case .postgresql:    return "postgresql"
        case .redis:         return "redis"
        case .mongodb:       return "mongodb"
        case .sqlite:        return "sqlite"
        case .mariadb:       return "mariadb"
        case .cockroachdb:   return "cockroachdb"
        case .cassandra:     return "cassandra"
        case .elasticsearch: return "elasticsearch"
        }
    }

    /// Human-readable display name.
    public var displayName: String { rawValue }
}

// MARK: - Server Icons

/// SF Symbol icon options for server display.
/// Mirrors: core-go/pkg/models/types/icons.go
public enum AXServerIcon: String, CaseIterable, Sendable {
    case serverRack = "server.rack"
    case desktop    = "desktopcomputer"
    case laptop     = "laptopcomputer"
    case cloud      = "cloud"
    case globe      = "globe"
    case database   = "cylinder.split.1x2"
    case box        = "shippingbox.fill"
    case cpu        = "cpu"
    case terminal   = "terminal"
    case gear       = "gearshape.fill"
    case shield     = "shield.fill"
    case building   = "building.2.fill"
    case house      = "house.fill"
    case network    = "network"
    case wifi       = "wifi"

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .serverRack: return "Server Rack"
        case .desktop:    return "Desktop"
        case .laptop:     return "Laptop"
        case .cloud:      return "Cloud"
        case .globe:      return "Globe"
        case .database:   return "Database"
        case .box:        return "Box"
        case .cpu:        return "CPU"
        case .terminal:   return "Terminal"
        case .gear:       return "Gear"
        case .shield:     return "Shield"
        case .building:   return "Building"
        case .house:      return "House"
        case .network:    return "Network"
        case .wifi:       return "WiFi"
        }
    }
}

// MARK: - Server Colors

/// Color options for server display (hex values).
/// Mirrors: core-go/pkg/models/types/icons.go
public enum AXServerColor: String, CaseIterable, Sendable {
    case blue   = "#007AFF"
    case green  = "#34C759"
    case orange = "#FF9500"
    case purple = "#AF52DE"
    case red    = "#FF3B30"
    case teal   = "#5AC8FA"
    case yellow = "#FFCC00"
    case pink   = "#FF2D55"
    case indigo = "#5856D6"
    case cyan   = "#00C7BE"

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .blue:   return "Blue"
        case .green:  return "Green"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .red:    return "Red"
        case .teal:   return "Teal"
        case .yellow: return "Yellow"
        case .pink:   return "Pink"
        case .indigo: return "Indigo"
        case .cyan:   return "Cyan"
        }
    }
}
