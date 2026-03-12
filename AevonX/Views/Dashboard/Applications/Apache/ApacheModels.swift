//
//  ApacheModels.swift
//  AevonX
//
//  Data models and section enum for Apache management
//

import Foundation
import AevonXCoreBridge

// MARK: - Apache Config Data (UI container — was in AevonXCore)

struct ApacheConfigData {
    var rawConfig: String = ""
    var configPath: String = ""
    var documentRoot: String = ""
    var modules: [ApacheModule] = []
    var virtualHosts: [ApacheVHost] = []
    var version: String? = nil
}

// MARK: - Apache Section

enum ApacheSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case modules = "Modules"
    case configuration = "Configuration"
    case virtualHosts = "Virtual Hosts"
    case logs = "Logs"
    case versions = "Versions"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .modules: return "square.stack.3d.up.fill"
        case .configuration: return "gearshape.fill"
        case .virtualHosts: return "network"
        case .logs: return "doc.text.fill"
        case .versions: return "arrow.triangle.2.circlepath"
        }
    }
}
