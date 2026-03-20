//
//  LiteSpeedSidebarItem.swift
//  AevonX
//
//  LiteSpeed-specific sidebar items for the detail view.
//

import SwiftUI

enum LiteSpeedSidebarCategory: String, CaseIterable, Identifiable {
    case status       = "Status"
    case management   = "Management"
    case security     = "Security"
    case monitoring   = "Monitoring"

    var id: String { rawValue }
}

enum LiteSpeedSidebarItem: String, CaseIterable, Identifiable {
    // Status
    case overview      = "Overview"
    case doctor        = "Doctor"

    // Management
    case config        = "Configuration"
    case versions      = "Versions"
    case modules       = "Modules"
    case optimization  = "Optimization"
    case sites         = "Sites"
    case snapshots     = "Snapshots"

    // Security
    case security      = "Security"

    // Monitoring
    case workers       = "Workers"
    case logs          = "Logs"

    var id: String { rawValue }

    var category: LiteSpeedSidebarCategory {
        switch self {
        case .overview, .doctor:                         return .status
        case .config, .versions, .modules, .optimization,
             .sites, .snapshots:                         return .management
        case .security:                                  return .security
        case .workers, .logs:                            return .monitoring
        }
    }

    var icon: String {
        switch self {
        case .overview:     return "gauge.with.dots.needle.67percent"
        case .doctor:       return "stethoscope"
        case .config:       return "doc.text.fill"
        case .versions:     return "shippingbox.fill"
        case .modules:      return "puzzlepiece.extension.fill"
        case .optimization: return "slider.horizontal.3"
        case .sites:        return "globe"
        case .snapshots:    return "clock.arrow.2.circlepath"
        case .security:     return "shield.lefthalf.filled"
        case .workers:      return "cpu.fill"
        case .logs:         return "text.alignleft"
        }
    }

    var color: Color {
        let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34) // #2E8B57
        switch self {
        case .overview:     return lsGreen
        case .doctor:       return Color(red: 0.2, green: 0.8, blue: 0.5)
        case .config:       return .orange
        case .versions:     return .axAccentBlue
        case .modules:      return .purple
        case .optimization: return .mint
        case .sites:        return .cyan
        case .snapshots:    return .indigo
        case .security:     return .red
        case .workers:      return .teal
        case .logs:         return .teal
        }
    }

    var description: String {
        switch self {
        case .overview:     return "Service health, metrics & quick actions"
        case .doctor:       return "12-point health check & score"
        case .config:       return "VirtualHost configs & validation"
        case .versions:     return "Installed & available versions"
        case .modules:      return "Loaded LiteSpeed modules"
        case .optimization: return "Connection, cache & timeout tuning"
        case .sites:        return "Enable/disable virtual hosts"
        case .snapshots:    return "Config backups & diff viewer"
        case .security:     return "Headers, SSL, rate limiting"
        case .workers:      return "Worker processes & resource usage"
        case .logs:         return "Access & error log viewer"
        }
    }

    static func categorizedItems() -> [(LiteSpeedSidebarCategory, [Self])] {
        [
            (.status,     [.overview, .doctor]),
            (.management, [.config, .versions, .modules, .optimization, .sites, .snapshots]),
            (.security,   [.security]),
            (.monitoring, [.workers, .logs]),
        ]
    }
}
