//
//  AppSidebarItem.swift
//  AevonX
//

import SwiftUI

enum NginxSidebarCategory: String, CaseIterable, Identifiable {
    case status       = "Status"
    case management   = "Management"
    case security     = "Security"
    case analytics    = "Analytics"
    case advanced     = "Advanced"
    case monitoring   = "Monitoring"

    var id: String { rawValue }
}

enum NginxSidebarItem: String, CaseIterable, Identifiable {
    // Status
    case overview      = "Overview"
    case performance   = "Performance Score"

    // Management
    case config        = "Configuration"
    case versions      = "Versions"
    case modules       = "Modules"
    case optimization  = "Optimization"
    case sites         = "Sites"
    case snapshots     = "Snapshots"

    // Security
    case security      = "Security"
    case ssl           = "SSL / TLS"

    // Analytics
    case analytics     = "Log Analytics"

    // Advanced
    case cache         = "Cache"
    case benchmark     = "Benchmark"
    case proxy         = "Reverse Proxy"

    // Monitoring
    case workers       = "Workers"
    case logs          = "Logs"
    case doctor        = "Doctor"

    var id: String { rawValue }

    var category: NginxSidebarCategory {
        switch self {
        case .overview, .performance:                         return .status
        case .config, .versions, .modules, .optimization,
             .sites, .snapshots:                             return .management
        case .security, .ssl:                                 return .security
        case .analytics:                                      return .analytics
        case .cache, .benchmark, .proxy:                      return .advanced
        case .workers, .logs, .doctor:                        return .monitoring
        }
    }

    var icon: String {
        switch self {
        case .overview:     return "gauge.with.dots.needle.67percent"
        case .performance:  return "chart.bar.xaxis"
        case .config:       return "doc.text.fill"
        case .versions:     return "shippingbox.fill"
        case .modules:      return "puzzlepiece.extension.fill"
        case .optimization: return "slider.horizontal.3"
        case .sites:        return "globe"
        case .snapshots:    return "clock.arrow.2.circlepath"
        case .security:     return "shield.lefthalf.filled"
        case .ssl:          return "lock.shield.fill"
        case .analytics:    return "chart.xyaxis.line"
        case .cache:        return "memorychip"
        case .benchmark:    return "gauge.with.dots.needle.100percent"
        case .proxy:        return "arrow.triangle.branch"
        case .workers:      return "cpu.fill"
        case .logs:         return "text.alignleft"
        case .doctor:       return "stethoscope"
        }
    }

    var color: Color {
        switch self {
        case .overview:     return Color(red: 0, green: 0.59, blue: 0.22)
        case .performance:  return Color(red: 0.4, green: 0.7, blue: 0.3)
        case .config:       return .orange
        case .versions:     return .axAccentBlue
        case .modules:      return .purple
        case .optimization: return .mint
        case .sites:        return .cyan
        case .snapshots:    return .indigo
        case .security:     return .red
        case .ssl:          return .green
        case .analytics:    return .teal
        case .cache:        return Color(red: 0.3, green: 0.8, blue: 0.6)
        case .benchmark:    return .yellow
        case .proxy:        return Color(red: 0.9, green: 0.5, blue: 0.1)
        case .workers:      return .cyan
        case .logs:         return .teal
        case .doctor:       return Color(red: 0.2, green: 0.8, blue: 0.5)
        }
    }

    var description: String {
        switch self {
        case .overview:     return "Service health, metrics & quick actions"
        case .performance:  return "Lighthouse-style config score (0–100)"
        case .config:       return "Sites, main config & validation"
        case .versions:     return "Installed & available versions"
        case .modules:      return "Compiled-in modules list"
        case .optimization: return "Performance tuning & directives"
        case .sites:        return "Enable/disable server blocks"
        case .snapshots:    return "Config backups & diff viewer"
        case .security:     return "Headers, rate limiting"
        case .ssl:          return "SSL certificates & HTTPS"
        case .analytics:    return "Top IPs, URLs, status codes"
        case .cache:        return "FastCGI/proxy cache & purge"
        case .benchmark:    return "Built-in performance tester"
        case .proxy:        return "Upstream groups & load balancing"
        case .workers:      return "Worker processes & connections"
        case .logs:         return "Access & error log viewer"
        case .doctor:       return "12-point health check"
        }
    }

    static func categorizedItems() -> [(NginxSidebarCategory, [Self])] {
        [
            (.status,     [.overview, .performance]),
            (.management, [.config, .versions, .modules, .optimization, .sites, .snapshots]),
            (.security,   [.security, .ssl]),
            (.analytics,  [.analytics]),
            (.advanced,   [.cache, .benchmark, .proxy]),
            (.monitoring, [.workers, .logs, .doctor]),
        ]
    }
}
