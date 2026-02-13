//
//  ServiceSectionProtocol.swift
//  AevonX
//
//  Protocol and helpers for standardizing service sections across all engines
//

import Foundation

/// Protocol that all service section enums must conform to
/// This ensures consistency across PHP, Nginx, MySQL, PostgreSQL, etc.
public protocol ServiceSection: RawRepresentable, CaseIterable, Identifiable where RawValue == String {
    /// Display name for the section
    var displayName: String { get }

    /// SF Symbol icon name for the section
    var icon: String { get }
}

/// Default implementation for ServiceSection
public extension ServiceSection {
    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - Common Section Types

/// Common sections that most services share
public enum CommonServiceSection: String, ServiceSection, CaseIterable {
    case overview = "Overview"
    case configuration = "Configuration"
    case logs = "Logs"
    case versions = "Versions"

    public var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .configuration: return "slider.horizontal.3"
        case .logs: return "doc.text"
        case .versions: return "number"
        }
    }
}

// MARK: - Section Extensions

/// Make PHPSection conform to ServiceSection
extension PHPSection: ServiceSection {
    public var displayName: String { rawValue }
}

/// Make NginxSection conform to ServiceSection
extension NginxSection: ServiceSection {
    public var displayName: String { rawValue }
}

// MARK: - Helper for Section Icons

/// Standard icon mapping for common section types
public struct ServiceSectionIcons {
    public static func icon(for sectionName: String) -> String {
        switch sectionName.lowercased() {
        case "overview": return "info.circle"
        case "configuration": return "slider.horizontal.3"
        case "logs": return "doc.text"
        case "versions": return "number"
        case "extensions": return "puzzlepiece.extension"
        case "security": return "shield"
        case "ports": return "network"
        case "optimization": return "chart.line.uptrend.xyaxis"
        case "access", "users": return "person.2"
        case "pools": return "server.rack"
        default: return "doc"
        }
    }
}
