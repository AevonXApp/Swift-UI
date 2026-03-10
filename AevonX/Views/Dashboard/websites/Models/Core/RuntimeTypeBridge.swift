//
//  RuntimeTypeBridge.swift
//  AevonX
//
//  Local definitions for types previously imported from AevonXCore.
//  These are used in Websites UI Runtime components.
//

import Foundation

// MARK: - Core Runtime Type (was AevonXCore.CoreRuntimeType)

public enum CoreRuntimeType: String, Codable, Sendable {
    case php = "PHP"
    case nodejs = "Node.js"
    case python = "Python"
    case ruby = "Ruby"
    case `static` = "Static"
    case docker = "Docker"
}

// MARK: - Environment Variable (was AevonXCore.EnvironmentVariable)

public struct EnvironmentVariable: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var key: String
    public var value: String
    public var isSecret: Bool
    
    nonisolated public init(id: UUID = UUID(), key: String, value: String, isSecret: Bool = false) {
        self.id = id
        self.key = key
        self.value = value
        self.isSecret = isSecret
    }
}

// MARK: - Package.json Model (was AevonXCore.PackageJSON)

public struct PackageJSON: Codable, Sendable {
    public let name: String?
    public let version: String?
    public let description: String?
    public let main: String?
    public let scripts: [String: String]?
    public let dependencies: [String: String]?
    public let devDependencies: [String: String]?
    public let engines: EngineRequirements?
    
    public struct EngineRequirements: Codable, Sendable {
        public let node: String?
        public let npm: String?
    }
    
    nonisolated public var entryFile: String {
        if let startScript = scripts?["start"] {
            let parts = startScript.split(separator: " ")
            if let nodeIdx = parts.firstIndex(of: "node"), nodeIdx + 1 < parts.count {
                return String(parts[nodeIdx + 1])
            }
            if parts.count == 1, let file = parts.first, file.hasSuffix(".js") || file.hasSuffix(".ts") {
                return String(file)
            }
        }
        return main ?? "index.js"
    }
    
    public var dependencyCount: Int {
        (dependencies?.count ?? 0) + (devDependencies?.count ?? 0)
    }
}

// MARK: - PM2 Process (was AevonXCore.PM2Process)

public struct PM2Process: Codable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let status: PM2Status
    public let cpu: Double
    public let memory: Int64
    public let uptime: Int64?
    public let restarts: Int
    public let pid: Int?
    
    public enum PM2Status: String, Codable, Sendable {
        case online
        case stopped
        case errored
        case launching
        case unknown
        
        public init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(String.self).lowercased()
            self = PM2Status(rawValue: value) ?? .unknown
        }
    }
    
    public var memoryFormatted: String {
        let mb = Double(memory) / 1_048_576
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024) }
        return String(format: "%.1f MB", mb)
    }
    
    public var cpuFormatted: String { String(format: "%.1f%%", cpu) }
    
    public var uptimeFormatted: String? {
        guard let uptime = uptime else { return nil }
        let seconds = uptime / 1000
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 24 { return "\(hours / 24)d \(hours % 24)h" }
        else if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}


