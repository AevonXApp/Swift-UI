//
//  SecuritySidebarItem.swift
//  AevonX
//
//  Sidebar navigation model for the Security panel.
//  Mirrors the pattern from ModernWebsitePanel (SidebarCategory + ModernSidebarItem).
//

import SwiftUI

// MARK: - Sidebar Category

enum SecuritySidebarCategory: String, CaseIterable, Identifiable {
    case overview    = "Overview"
    case firewall    = "Firewall"
    case access      = "Access Control"
    case defense     = "Defense"
    case scanning    = "Scanning"
    case monitoring  = "Monitoring"
    case ai          = "AI Assistant"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview:   return "shield.checkered"
        case .firewall:   return "flame.fill"
        case .access:     return "key.fill"
        case .defense:    return "shield.lefthalf.filled"
        case .scanning:   return "magnifyingglass.circle.fill"
        case .monitoring: return "chart.xyaxis.line"
        case .ai:         return "brain.head.profile"
        }
    }
}

// MARK: - Sidebar Item

enum SecuritySidebarItem: String, CaseIterable, Identifiable {
    // Overview
    case dashboard       = "Dashboard"

    // Firewall
    case firewallRules   = "Firewall"

    // Access Control
    case ssh             = "SSH Security"
    case users           = "Users & Permissions"

    // Defense
    case bruteForce      = "Brute Force"
    case antiIntrusion   = "Anti-Intrusion"
    case waf             = "WAF Protection"
    case geoip           = "GeoIP & Access"

    // Scanning
    case malware         = "Malware Scanner"
    case fileIntegrity   = "File Integrity"
    case hardening       = "System Hardening"

    // Monitoring
    case network         = "Network Security"
    case auditLog        = "Audit Log"
    case certificates    = "SSL/TLS Monitor"

    // AI
    case aiAssistant     = "AI Security"

    var id: String { rawValue }

    var category: SecuritySidebarCategory {
        switch self {
        case .dashboard:                                          return .overview
        case .firewallRules:                                      return .firewall
        case .ssh, .users:                                        return .access
        case .bruteForce, .antiIntrusion, .waf, .geoip:           return .defense
        case .malware, .fileIntegrity, .hardening:                return .scanning
        case .network, .auditLog, .certificates:                  return .monitoring
        case .aiAssistant:                                        return .ai
        }
    }

    var icon: String {
        switch self {
        case .dashboard:      return "gauge.with.dots.needle.67percent"
        case .firewallRules:  return "flame.fill"
        case .ssh:            return "terminal.fill"
        case .users:          return "person.2.fill"
        case .bruteForce:     return "hand.raised.fill"
        case .antiIntrusion:  return "exclamationmark.shield.fill"
        case .waf:            return "shield.lefthalf.filled"
        case .geoip:          return "globe.americas.fill"
        case .malware:        return "ant.fill"
        case .fileIntegrity:  return "doc.badge.clock.fill"
        case .hardening:      return "lock.shield.fill"
        case .network:        return "network"
        case .auditLog:       return "text.alignleft"
        case .certificates:   return "lock.fill"
        case .aiAssistant:    return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .dashboard:      return .axSuccess
        case .firewallRules:  return .orange
        case .ssh:            return .cyan
        case .users:          return .axAccentBlue
        case .bruteForce:     return .red
        case .antiIntrusion:  return .pink
        case .waf:            return .purple
        case .geoip:          return .mint
        case .malware:        return .red
        case .fileIntegrity:  return .indigo
        case .hardening:      return .yellow
        case .network:        return .teal
        case .auditLog:       return .cyan
        case .certificates:   return .orange
        case .aiAssistant:    return .purple
        }
    }

    var description: String {
        switch self {
        case .dashboard:      return "Overall security score & alerts"
        case .firewallRules:  return "Port rules, firewall toggle & traffic"
        case .ssh:            return "SSH config, keys & session monitor"
        case .users:          return "System users, sudo & permissions"
        case .bruteForce:     return "fail2ban, ban list & whitelist"
        case .antiIntrusion:  return "Jails, attack patterns & IDS"
        case .waf:            return "ModSecurity, OWASP rules & blocks"
        case .geoip:          return "Country blocking & IP reputation"
        case .malware:        return "ClamAV scan & quarantine"
        case .fileIntegrity:  return "File change & rootkit detection"
        case .hardening:      return "Kernel, network & service hardening"
        case .network:        return "Port scan, connections & DNS"
        case .auditLog:       return "Auth, sudo & service logs"
        case .certificates:   return "SSL expiry, TLS & cipher config"
        case .aiAssistant:    return "AI threat analysis & recommendations"
        }
    }

    /// Returns sidebar items organized by category
    static func categorizedItems() -> [(SecuritySidebarCategory, [Self])] {
        [
            (.overview,   [.dashboard]),
            (.firewall,   [.firewallRules]),
            (.access,     [.ssh, .users]),
            (.defense,    [.bruteForce, .antiIntrusion, .waf, .geoip]),
            (.scanning,   [.malware, .fileIntegrity, .hardening]),
            (.monitoring, [.network, .auditLog, .certificates]),
            (.ai,         [.aiAssistant]),
        ]
    }
}
