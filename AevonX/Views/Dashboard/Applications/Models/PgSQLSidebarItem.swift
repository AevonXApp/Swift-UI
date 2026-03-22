//
//  PgSQLSidebarItem.swift
//  AevonX
//
//  Sidebar navigation items for PostgreSQL detail view.
//

import SwiftUI

enum PgSQLSidebarCategory: String, CaseIterable, Identifiable {
    case status     = "Status"
    case management = "Management"
    case security   = "Security"
    case monitoring = "Monitoring"

    var id: String { rawValue }
}

enum PgSQLSidebarItem: String, CaseIterable, Identifiable {
    // Status
    case overview      = "Overview"
    case doctor        = "Doctor"

    // Management
    case config        = "Configuration"
    case versions      = "Versions"
    case modules       = "Extensions"
    case optimization  = "Optimization"
    case snapshots     = "Snapshots"
    case databases     = "Databases"

    // Security
    case security      = "Security"

    // Monitoring
    case logs          = "Logs"
    case workers       = "Connections"

    var id: String { rawValue }

    var category: PgSQLSidebarCategory {
        switch self {
        case .overview, .doctor:                         return .status
        case .config, .versions, .modules, .optimization,
             .snapshots, .databases:                     return .management
        case .security:                                   return .security
        case .logs, .workers:                            return .monitoring
        }
    }

    var icon: String {
        switch self {
        case .overview:     return "gauge.with.dots.needle.33percent"
        case .doctor:       return "stethoscope"
        case .config:       return "doc.text.fill"
        case .versions:     return "shippingbox.fill"
        case .modules:      return "puzzlepiece.extension.fill"
        case .optimization: return "slider.horizontal.3"
        case .snapshots:    return "clock.arrow.circlepath"
        case .databases:    return "cylinder.fill"
        case .security:     return "lock.shield.fill"
        case .logs:         return "text.alignleft"
        case .workers:      return "point.3.connected.trianglepath.dotted"
        }
    }

    var color: Color {
        let pgsqlBlue = Color(red: 0.2, green: 0.4, blue: 0.57)
        switch self {
        case .overview:     return pgsqlBlue
        case .doctor:       return Color(red: 0.2, green: 0.8, blue: 0.5)
        case .config:       return .orange
        case .versions:     return .axAccentBlue
        case .modules:      return .purple
        case .optimization: return .mint
        case .snapshots:    return .indigo
        case .databases:    return pgsqlBlue
        case .security:     return .red
        case .logs:         return .teal
        case .workers:      return .cyan
        }
    }

    var description: String {
        switch self {
        case .overview:     return "Service status, connections & quick actions"
        case .doctor:       return "Health checks & performance score"
        case .config:       return "postgresql.conf & pg_hba.conf files"
        case .versions:     return "Installed & available PostgreSQL versions"
        case .modules:      return "PostgreSQL extensions & contrib modules"
        case .optimization: return "Memory, connections & WAL tuning"
        case .snapshots:    return "Configuration backup & restore"
        case .databases:    return "Database sizes & management"
        case .security:     return "SSL, pg_hba.conf & authentication"
        case .logs:         return "Error & general log viewer"
        case .workers:      return "Active connections & backends"
        }
    }

    static func categorizedItems() -> [(PgSQLSidebarCategory, [Self])] {
        [
            (.status,     [.overview, .doctor]),
            (.management, [.config, .versions, .modules, .optimization, .snapshots, .databases]),
            (.security,   [.security]),
            (.monitoring, [.logs, .workers]),
        ]
    }
}
