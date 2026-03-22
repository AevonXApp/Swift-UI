//
//  RedisSidebarItem.swift
//  AevonX
//
//  Sidebar navigation items for Redis detail view.
//

import SwiftUI

enum RedisSidebarCategory: String, CaseIterable, Identifiable {
    case status     = "Status"
    case management = "Management"
    case security   = "Security"
    case monitoring = "Monitoring"

    var id: String { rawValue }
}

enum RedisSidebarItem: String, CaseIterable, Identifiable {
    case overview      = "Overview"
    case doctor        = "Doctor"
    case config        = "Configuration"
    case versions      = "Versions"
    case modules       = "Modules"
    case optimization  = "Optimization"
    case snapshots     = "Snapshots"
    case databases     = "Keyspaces"
    case security      = "Security"
    case logs          = "Logs"
    case workers       = "Clients"

    var id: String { rawValue }

    var category: RedisSidebarCategory {
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
        case .databases:    return "key.fill"
        case .security:     return "lock.shield.fill"
        case .logs:         return "text.alignleft"
        case .workers:      return "person.2.fill"
        }
    }

    var color: Color {
        let redisRed = Color(red: 0.86, green: 0.23, blue: 0.23)
        switch self {
        case .overview:     return redisRed
        case .doctor:       return Color(red: 0.2, green: 0.8, blue: 0.5)
        case .config:       return .orange
        case .versions:     return .axAccentBlue
        case .modules:      return .purple
        case .optimization: return .mint
        case .snapshots:    return .indigo
        case .databases:    return redisRed
        case .security:     return .red
        case .logs:         return .teal
        case .workers:      return .cyan
        }
    }

    var description: String {
        switch self {
        case .overview:     return "Service status, memory & quick actions"
        case .doctor:       return "Health checks & performance score"
        case .config:       return "redis.conf file management"
        case .versions:     return "Installed & available Redis versions"
        case .modules:      return "Loaded Redis modules"
        case .optimization: return "Memory, persistence & eviction tuning"
        case .snapshots:    return "Configuration backup & restore"
        case .databases:    return "Keyspace stats per database"
        case .security:     return "requirepass, ACL, protected-mode"
        case .logs:         return "Server log viewer"
        case .workers:      return "Connected clients"
        }
    }

    static func categorizedItems() -> [(RedisSidebarCategory, [Self])] {
        [
            (.status,     [.overview, .doctor]),
            (.management, [.config, .versions, .modules, .optimization, .snapshots, .databases]),
            (.security,   [.security]),
            (.monitoring, [.logs, .workers]),
        ]
    }
}
