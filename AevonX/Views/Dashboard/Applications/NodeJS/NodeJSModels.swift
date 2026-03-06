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
    case deployment = "Deployment"
    case frameworks = "Frameworks"
    case packages = "Packages"
    case npm = "NPM"
    case environment = "Environment"
    case reverseProxy = "Reverse Proxy"
    case versions = "Versions"
    case security = "Security"
    case logs = "Logs"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .processes: return "cpu"
        case .deployment: return "arrow.triangle.branch"
        case .frameworks: return "square.stack.3d.up.fill"
        case .packages: return "shippingbox.fill"
        case .npm: return "terminal.fill"
        case .environment: return "key.fill"
        case .reverseProxy: return "network"
        case .versions: return "arrow.triangle.2.circlepath"
        case .security: return "shield.checkered"
        case .logs: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
