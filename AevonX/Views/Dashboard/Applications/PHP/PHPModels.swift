//
//  PHPModels.swift
//  AevonX
//
//  UI models for PHP management
//

import SwiftUI
import AevonXCore

// MARK: - PHP Section

enum PHPSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case extensions = "Extensions"
    case configuration = "Configuration"
    case disabledFunctions = "Disabled Functions"
    case fpmPools = "FPM Pools"
    case logs = "Logs"
    case versions = "Versions"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .extensions: return "puzzlepiece.extension"
        case .configuration: return "slider.horizontal.3"
        case .disabledFunctions: return "hand.raised"
        case .fpmPools: return "server.rack"
        case .logs: return "doc.text"
        case .versions: return "number"
        }
    }
}

// MARK: - PHP Config Data

struct PHPConfigData {
    var rawConfig: String = ""
    var iniPath: String = "/etc/php/php.ini"
    var logPath: String = "/var/log/php-fpm/error.log"
    var installedExtensions: [PHPExtension] = []
    var availableExtensions: [PHPExtension] = []
    var disabledFunctions: [String] = []
    var fpmPools: [PHPFPMPool] = []
    var currentVersion: String = ""
    var availableVersions: [String] = []
    var phpConfiguration: PHPConfiguration = PHPConfiguration()
}
