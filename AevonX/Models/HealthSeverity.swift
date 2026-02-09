//
//  HealthSeverity.swift
//  AevonX
//
//  Shared health monitoring severity enum
//

import Foundation

/// Priority level for health issues and notifications
public enum HealthSeverity: String, Codable, CaseIterable, Hashable {
    case critical = "Critical"
    case warning = "Warning"
    case info = "Info"

    public var priority: Int {
        switch self {
        case .critical: return 3
        case .warning: return 2
        case .info: return 1
        }
    }
}
