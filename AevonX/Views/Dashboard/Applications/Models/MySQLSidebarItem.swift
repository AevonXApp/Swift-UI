//
//  MySQLSidebarItem.swift
//  AevonX
//
//  Sidebar navigation items for MySQL detail view.
//

import SwiftUI

enum MySQLSidebarCategory: String, CaseIterable, Identifiable {
    case status     = "Status"
    case management = "Management"
    case security   = "Security"
    case monitoring = "Monitoring"

    var id: String { rawValue }
}

enum MySQLSidebarItem: String, CaseIterable, Identifiable {
    // Status
    case overview      = "Overview"
    case doctor        = "Doctor"

    // Management
    case config        = "Configuration"
    case versions      = "Versions"
    case modules       = "Engines & Plugins"
    case optimization  = "Optimization"
    case snapshots     = "Snapshots"
    case databases     = "Databases"

    // Security
    case security      = "Security"

    // Monitoring
    case logs          = "Logs"
    case workers       = "Threads"

    var id: String { rawValue }

    var category: MySQLSidebarCategory {
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
        case .workers:      return "cpu.fill"
        }
    }

    var color: Color {
        let mysqlBlue = Color(red: 0.27, green: 0.47, blue: 0.63)
        switch self {
        case .overview:     return mysqlBlue
        case .doctor:       return Color(red: 0.2, green: 0.8, blue: 0.5)
        case .config:       return .orange
        case .versions:     return .axAccentBlue
        case .modules:      return .purple
        case .optimization: return .mint
        case .snapshots:    return .indigo
        case .databases:    return mysqlBlue
        case .security:     return .red
        case .logs:         return .teal
        case .workers:      return .cyan
        }
    }

    var description: String {
        switch self {
        case .overview:     return "Service status, connections & quick actions"
        case .doctor:       return "Health checks & performance score"
        case .config:       return "my.cnf configuration files"
        case .versions:     return "Installed & available MySQL versions"
        case .modules:      return "Storage engines & server plugins"
        case .optimization: return "InnoDB, connections & cache tuning"
        case .snapshots:    return "Configuration backup & restore"
        case .databases:    return "Database sizes & management"
        case .security:     return "Users, SSL & authentication"
        case .logs:         return "Error, slow query & general logs"
        case .workers:      return "Thread & connection list"
        }
    }

    static func categorizedItems() -> [(MySQLSidebarCategory, [Self])] {
        [
            (.status,     [.overview, .doctor]),
            (.management, [.config, .versions, .modules, .optimization, .snapshots, .databases]),
            (.security,   [.security]),
            (.monitoring, [.logs, .workers]),
        ]
    }
}
