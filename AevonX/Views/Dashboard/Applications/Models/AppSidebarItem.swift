//
//  AppSidebarItem.swift
//  AevonX
//
//  Sidebar navigation model for application detail views.
//  Follows the SecuritySidebarItem pattern — each app type
//  defines its own sidebar items with categorized sections.
//

import SwiftUI

// MARK: - Nginx Sidebar Category

enum NginxSidebarCategory: String, CaseIterable, Identifiable {
    case status       = "Status"
    case management   = "Management"
    case monitoring   = "Monitoring"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .status:     return "gauge.with.dots.needle.67percent"
        case .management: return "wrench.and.screwdriver"
        case .monitoring: return "chart.xyaxis.line"
        }
    }
}

// MARK: - Nginx Sidebar Item

enum NginxSidebarItem: String, CaseIterable, Identifiable {
    // Status
    case overview      = "Overview"

    // Management
    case config        = "Configuration"
    case versions      = "Versions"
    case modules       = "Modules"

    // Monitoring
    case workers       = "Workers"
    case logs          = "Logs"

    var id: String { rawValue }

    var category: NginxSidebarCategory {
        switch self {
        case .overview:                     return .status
        case .config, .versions, .modules:  return .management
        case .workers, .logs:               return .monitoring
        }
    }

    var icon: String {
        switch self {
        case .overview:  return "gauge.with.dots.needle.67percent"
        case .config:    return "doc.text.fill"
        case .versions:  return "shippingbox.fill"
        case .modules:   return "puzzlepiece.extension.fill"
        case .workers:   return "cpu.fill"
        case .logs:      return "text.alignleft"
        }
    }

    var color: Color {
        switch self {
        case .overview:  return Color(red: 0, green: 0.59, blue: 0.22)  // Nginx green
        case .config:    return .orange
        case .versions:  return .axAccentBlue
        case .modules:   return .purple
        case .workers:   return .cyan
        case .logs:      return .teal
        }
    }

    var description: String {
        switch self {
        case .overview:  return "Service health, metrics & quick actions"
        case .config:    return "Sites, main config & validation"
        case .versions:  return "Installed & available versions"
        case .modules:   return "Compiled-in modules list"
        case .workers:   return "Worker processes & connections"
        case .logs:      return "Access & error log viewer"
        }
    }

    /// Returns sidebar items organized by category.
    static func categorizedItems() -> [(NginxSidebarCategory, [Self])] {
        [
            (.status,     [.overview]),
            (.management, [.config, .versions, .modules]),
            (.monitoring, [.workers, .logs]),
        ]
    }
}
