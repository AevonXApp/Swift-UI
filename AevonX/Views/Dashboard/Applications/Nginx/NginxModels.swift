
import Foundation
import AevonXCoreBridge

public struct NginxConfigData {
    public var rawConfig: String = ""
    public var configPath: String = ""
    public var logPath: String = ""
    public var dataPath: String = ""
    public var listeningPorts: [Int] = []
    public var blockedIPs: [AXBlockedIP] = []
    
    public init(rawConfig: String = "", configPath: String = "", logPath: String = "", dataPath: String = "", listeningPorts: [Int] = [], blockedIPs: [AXBlockedIP] = []) {
        self.rawConfig = rawConfig
        self.configPath = configPath
        self.logPath = logPath
        self.dataPath = dataPath
        self.listeningPorts = listeningPorts
        self.blockedIPs = blockedIPs
    }
}

public enum NginxSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case configuration = "Configuration"
    case ports = "Ports"
    case security = "Security"
    case logs = "Logs"
    case versions = "Versions"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .configuration: return "doc.text"
        case .ports: return "network"
        case .security: return "shield"
        case .logs: return "list.bullet.rectangle"
        case .versions: return "arrow.up.and.down.circle"
        }
    }
}
