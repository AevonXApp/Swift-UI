//
//  NodeJSModels.swift
//  AevonX
//
//  Data models and section enum for Node.js management
//

import Foundation
import SwiftUI

// MARK: - NodeJS Section

enum NodeJSSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case processes = "Processes"
    case packages = "Packages"
    case environment = "Environment"
    case versions = "Versions"
    case logs = "Logs"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .processes: return "cpu"
        case .packages: return "shippingbox.fill"
        case .environment: return "key.fill"
        case .versions: return "arrow.triangle.2.circlepath"
        case .logs: return "doc.text.fill"
        }
    }
}
