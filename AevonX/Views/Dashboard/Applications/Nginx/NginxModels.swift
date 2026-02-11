
import Foundation
import AevonXCore

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
