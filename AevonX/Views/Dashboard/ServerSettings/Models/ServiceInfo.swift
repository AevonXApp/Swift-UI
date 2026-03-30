//
//  ServiceInfo.swift
//  AevonX
//
//  Data model for systemd/SysV/OpenRC service entries.
//

import SwiftUI

struct ServiceInfo: Identifiable {
    let id: String
    let name: String
    let activeState: ServiceActiveState
    let subState: String
    let enabledState: ServiceEnabledState
    var category: ServiceCategory

    init(name: String, activeState: ServiceActiveState, subState: String, enabledState: ServiceEnabledState) {
        self.id = name
        self.name = name.replacingOccurrences(of: ".service", with: "")
        self.activeState = activeState
        self.subState = subState
        self.enabledState = enabledState
        self.category = ServiceCategory.categorize(name)
    }
}

// MARK: - Active State

enum ServiceActiveState: String {
    case active, inactive, failed, activating, deactivating

    var color: Color {
        switch self {
        case .active: return .axSuccess
        case .inactive: return .axTextMuted
        case .failed: return .axError
        case .activating, .deactivating: return .axWarning
        }
    }

    var icon: String {
        switch self {
        case .active: return "circle.fill"
        case .inactive: return "circle"
        case .failed: return "exclamationmark.circle.fill"
        case .activating, .deactivating: return "arrow.clockwise.circle"
        }
    }
}

// MARK: - Enabled State

enum ServiceEnabledState: String {
    case enabled, disabled, `static`, masked, unknown

    var color: Color {
        switch self {
        case .enabled: return .axSuccess
        case .disabled: return .axTextMuted
        case .static: return .axAccentBlue
        case .masked: return .axError
        case .unknown: return .axTextTertiary
        }
    }

    var label: String { rawValue.capitalized }
}

// MARK: - Category

enum ServiceCategory: String, CaseIterable {
    case failed = "Failed"
    case web = "Web"
    case database = "Database"
    case mail = "Mail"
    case security = "Security"
    case monitoring = "Monitoring"
    case system = "System"

    var icon: String {
        switch self {
        case .failed: return "exclamationmark.triangle.fill"
        case .web: return "globe"
        case .database: return "cylinder.split.1x2"
        case .mail: return "envelope.fill"
        case .security: return "lock.shield.fill"
        case .monitoring: return "chart.bar.fill"
        case .system: return "gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .failed: return .axError
        case .web: return .axAccentBlue
        case .database: return .axAccentPurple
        case .mail: return .orange
        case .security: return .axSuccess
        case .monitoring: return .axWarning
        case .system: return .axTextSecondary
        }
    }

    static func categorize(_ name: String) -> ServiceCategory {
        let n = name.lowercased()
        let webKeys = ["nginx", "apache", "apache2", "httpd", "caddy", "litespeed",
                       "php-fpm", "php7", "php8", "php5", "gunicorn", "uwsgi",
                       "tomcat", "node", "pm2"]
        let dbKeys = ["mysql", "mariadb", "postgresql", "postgres", "redis",
                      "mongodb", "mongod", "memcached", "elasticsearch",
                      "influxdb", "clickhouse"]
        let mailKeys = ["postfix", "dovecot", "sendmail", "exim", "opendkim",
                        "spamassassin", "amavis"]
        let secKeys = ["sshd", "ssh", "fail2ban", "ufw", "iptables", "firewalld",
                       "apparmor", "crowdsec", "ossec"]
        let monKeys = ["prometheus", "grafana", "telegraf", "collectd", "zabbix",
                       "nagios", "netdata", "node_exporter"]

        if webKeys.contains(where: { n.contains($0) }) { return .web }
        if dbKeys.contains(where: { n.contains($0) }) { return .database }
        if mailKeys.contains(where: { n.contains($0) }) { return .mail }
        if secKeys.contains(where: { n.contains($0) }) { return .security }
        if monKeys.contains(where: { n.contains($0) }) { return .monitoring }
        return .system
    }
}

// MARK: - Filter

enum ServiceFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case inactive = "Inactive"
    case failed = "Failed"
    case enabled = "Enabled"
    case disabled = "Disabled"
}
