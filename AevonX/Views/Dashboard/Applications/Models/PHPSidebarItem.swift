//
//  PHPSidebarItem.swift
//  AevonX
//
//  PHP-FPM specific sidebar items.
//

import SwiftUI

enum PHPSidebarCategory: String, CaseIterable, Identifiable {
    case status       = "Status"
    case management   = "Management"
    case fpm          = "FPM"
    case performance  = "Performance"
    case security     = "Security"
    case monitoring   = "Monitoring"
    case tools        = "Tools"

    var id: String { rawValue }
}

enum PHPSidebarItem: String, CaseIterable, Identifiable {
    // Status
    case overview       = "Overview"
    case performance    = "Performance Score"

    // Management
    case config         = "Configuration"
    case versions       = "Versions"
    case extensions     = "Extensions"
    case optimization   = "Optimization"
    case snapshots      = "Snapshots"

    // FPM
    case pools          = "FPM Pools"
    case workers        = "Workers"

    // Performance
    case opcache        = "OPcache"

    // Security
    case security       = "Security"

    // Monitoring
    case logs           = "Logs"
    case doctor         = "Doctor"
    case sessions       = "Sessions"

    // Tools
    case xdebug         = "Xdebug"
    case composer       = "Composer"

    var id: String { rawValue }

    var category: PHPSidebarCategory {
        switch self {
        case .overview, .performance:                   return .status
        case .config, .versions, .extensions,
             .optimization, .snapshots:                 return .management
        case .pools, .workers:                          return .fpm
        case .opcache:                                  return .performance
        case .security:                                 return .security
        case .logs, .doctor, .sessions:                 return .monitoring
        case .xdebug, .composer:                        return .tools
        }
    }

    var icon: String {
        switch self {
        case .overview:     return "gauge.with.dots.needle.67percent"
        case .performance:  return "chart.bar.xaxis"
        case .config:       return "doc.text.fill"
        case .versions:     return "shippingbox.fill"
        case .extensions:   return "puzzlepiece.extension.fill"
        case .optimization: return "slider.horizontal.3"
        case .snapshots:    return "clock.arrow.2.circlepath"
        case .pools:        return "square.stack.3d.up.fill"
        case .workers:      return "cpu.fill"
        case .opcache:      return "memorychip"
        case .security:     return "shield.lefthalf.filled"
        case .logs:         return "text.alignleft"
        case .doctor:       return "stethoscope"
        case .sessions:     return "person.2.fill"
        case .xdebug:       return "ant.fill"
        case .composer:     return "shippingbox.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .overview:     return Color(red: 0.47, green: 0.48, blue: 0.71) // PHP purple
        case .performance:  return Color(red: 0.4, green: 0.7, blue: 0.3)
        case .config:       return .orange
        case .versions:     return .axAccentBlue
        case .extensions:   return .purple
        case .optimization: return .mint
        case .snapshots:    return .indigo
        case .pools:        return .cyan
        case .workers:      return .teal
        case .opcache:      return Color(red: 0.3, green: 0.8, blue: 0.6)
        case .security:     return .red
        case .logs:         return .teal
        case .doctor:       return Color(red: 0.2, green: 0.8, blue: 0.5)
        case .sessions:     return .pink
        case .xdebug:       return Color(red: 0.9, green: 0.5, blue: 0.1)
        case .composer:     return Color(red: 0.6, green: 0.4, blue: 0.2)
        }
    }

    var description: String {
        switch self {
        case .overview:     return "Service health, metrics & quick actions"
        case .performance:  return "PHP configuration score (0–100)"
        case .config:       return "php.ini, php-fpm.conf & pool configs"
        case .versions:     return "Installed & available PHP versions"
        case .extensions:   return "PHP modules & Zend extensions"
        case .optimization: return "Memory, execution & upload limits"
        case .snapshots:    return "Config backups & diff viewer"
        case .pools:        return "FPM pool management & tuning"
        case .workers:      return "FPM worker processes"
        case .opcache:      return "OPcache & JIT statistics"
        case .security:     return "Hardening, disable_functions, open_basedir"
        case .logs:         return "FPM error & slow log viewer"
        case .doctor:       return "12-point PHP health check"
        case .sessions:     return "Session handler & cleanup"
        case .xdebug:       return "Debug profiler toggle & config"
        case .composer:     return "Dependency audit & security scan"
        }
    }

    static func categorizedItems() -> [(PHPSidebarCategory, [Self])] {
        [
            (.status,      [.overview, .performance]),
            (.management,  [.config, .versions, .extensions, .optimization, .snapshots]),
            (.fpm,         [.pools, .workers]),
            (.performance, [.opcache]),
            (.security,    [.security]),
            (.monitoring,  [.logs, .doctor, .sessions]),
            (.tools,       [.xdebug, .composer]),
        ]
    }
}
