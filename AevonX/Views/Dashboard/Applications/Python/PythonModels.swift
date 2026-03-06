//
//  PythonModels.swift
//  AevonX
//
//  Data models and section enum for Python management
//

import Foundation
import SwiftUI

// MARK: - Python Section

enum PythonSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case virtualenvs = "Virtual Envs"
    case packages = "Packages"
    case processes = "Processes"
    case configuration = "Configuration"
    case versions = "Versions"
    case logs = "Logs"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .virtualenvs: return "folder.fill.badge.gearshape"
        case .packages: return "shippingbox.fill"
        case .processes: return "cpu"
        case .configuration: return "gearshape.fill"
        case .versions: return "arrow.triangle.2.circlepath"
        case .logs: return "doc.text.fill"
        }
    }
}
