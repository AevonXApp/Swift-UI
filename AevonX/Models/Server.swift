//
//  Server.swift
//  AevonX
//
//  Server model representing remote servers and local workspaces
//  Data comes from Core after decryption - NO MOCK DATA
//

import Foundation
import AevonXCore

enum ServerStatus: String, CaseIterable {
    case online = "Online"
    case offline = "Offline"
    case maintenance = "Maintenance"
    case error = "Error"
    
    var color: String {
        switch self {
        case .online: return "axSuccess"
        case .offline: return "axTextMuted"
        case .maintenance: return "axWarning"
        case .error: return "axError"
        }
    }
    
    var icon: String {
        switch self {
        case .online: return "checkmark.circle.fill"
        case .offline: return "xmark.circle.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

enum ServerType: String, CaseIterable {
    case remote = "Remote"
    case local = "Local"
}

/// Real server model - data comes from Core after decryption
struct Server: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var host: String
    var port: Int
    var username: String
    var status: ServerStatus
    var type: ServerType
    var tags: [String]
    var lastConnected: Date?
    var os: String?
    var location: String?
    
    // Customization
    var iconName: String
    var customColor: String
    
    // System vitals (for connected servers)
    var cpuUsage: Double?
    var memoryUsage: Double?
    var diskUsage: Double?
    var uptime: String?
    
    /// Creates a Server from decrypted Core data
    init(
        id: UUID? = nil,
        name: String,
        host: String,
        port: Int,
        username: String,
        status: ServerStatus,
        type: ServerType,
        tags: [String],
        lastConnected: Date?,
        os: String?,
        location: String?,
        iconName: String = "server.rack",
        customColor: String = "#007AFF",
        cpuUsage: Double? = nil,
        memoryUsage: Double? = nil,
        diskUsage: Double? = nil,
        uptime: String? = nil
    ) {
        self.id = id ?? UUID()
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.status = status
        self.type = type
        self.tags = tags
        self.lastConnected = lastConnected
        self.os = os
        self.location = location
        self.iconName = iconName
        self.customColor = customColor
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.uptime = uptime
    }
    
    /// Creates a placeholder server for loading states
    static func placeholder(name: String) -> Server {
        Server(
            name: name,
            host: "connecting...",
            port: 22,
            username: "...",
            status: .offline,
            type: .remote,
            tags: [],
            lastConnected: nil,
            os: nil,
            location: nil,
            iconName: "server.rack",
            customColor: "#007AFF"
        )
    }
}

struct Website: Identifiable {
    let id = UUID()
    var name: String
    var domain: String
    var status: ServerStatus
    var sslEnabled: Bool
    var phpVersion: String?
    var lastDeployed: Date?
    var diskUsage: Double
}

struct Database: Identifiable {
    let id = UUID()
    var name: String
    var type: String
    var version: String
    var status: ServerStatus
    var size: Double
    var tables: Int
    var connections: Int
}
 
struct Application: Identifiable {
    let id = UUID()
    var name: String
    var version: String
    var status: ServerStatus
    var isRunning: Bool
    var autoStart: Bool
    var port: Int?
    var memoryUsage: Double?
}
