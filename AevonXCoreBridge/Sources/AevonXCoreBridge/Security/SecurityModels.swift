//
//  SecurityModels.swift
//  AevonXCoreBridge
//
//  Typed return models for SecurityManager.
//  UI receives these structs — never raw SSH output.
//

import Foundation

// MARK: - System User

public struct SystemUser: Sendable {
    public let name: String
    public let uid: String
    public let shell: String
    public let home: String
    public let hasSudo: Bool
    
    public init(name: String, uid: String, shell: String, home: String, hasSudo: Bool) {
        self.name = name
        self.uid = uid
        self.shell = shell
        self.home = home
        self.hasSudo = hasSudo
    }
}

// MARK: - Network

public struct OpenPort: Sendable {
    public let port: String
    public let proto: String
    public let service: String
    
    public init(port: String, proto: String, service: String) {
        self.port = port
        self.proto = proto
        self.service = service
    }
}

public struct NetworkConnection: Sendable {
    public let ip: String
    public let count: Int
    
    public init(ip: String, count: Int) {
        self.ip = ip
        self.count = count
    }
}

// MARK: - Security Score

public struct SecurityScore: Sendable {
    public let value: Double
    public let firewallActive: Bool
    public let fail2banActive: Bool
    public let sshSecure: Bool
    public let activeRules: Int
    public let bannedIPs: Int
    public let failedLogins: Int
    public let hardeningData: [String: String]
    
    /// Converts hardeningData back to "KEY:VALUE\n" format for UI parsing
    public var rawData: String {
        hardeningData.map { "\($0.key):\($0.value)" }.joined(separator: "\n")
    }
    
    public init(
        value: Double, firewallActive: Bool, fail2banActive: Bool,
        sshSecure: Bool, activeRules: Int, bannedIPs: Int,
        failedLogins: Int, hardeningData: [String: String]
    ) {
        self.value = value
        self.firewallActive = firewallActive
        self.fail2banActive = fail2banActive
        self.sshSecure = sshSecure
        self.activeRules = activeRules
        self.bannedIPs = bannedIPs
        self.failedLogins = failedLogins
        self.hardeningData = hardeningData
    }
}

// MARK: - WAF

public struct WAFStatus: Sendable {
    public let installed: Bool
    public let enabled: Bool
    
    public init(installed: Bool, enabled: Bool) {
        self.installed = installed
        self.enabled = enabled
    }
}

// MARK: - Certificates

public struct CertificateInfo: Sendable {
    public let domain: String
    public let expiry: String
    public let daysLeft: Int
    public let issuer: String
    
    public init(domain: String, expiry: String, daysLeft: Int, issuer: String) {
        self.domain = domain
        self.expiry = expiry
        self.daysLeft = daysLeft
        self.issuer = issuer
    }
}

// MARK: - Malware

public struct MalwareScanResult: Sendable {
    public let file: String
    public let threat: String
    
    public init(file: String, threat: String) {
        self.file = file
        self.threat = threat
    }
}

// MARK: - GeoIP / Attack Source

public struct AttackSource: Sendable {
    public let ip: String
    public let count: Int
    
    public init(ip: String, count: Int) {
        self.ip = ip
        self.count = count
    }
}

// MARK: - AI Security Data

public struct AISecurityData: Sendable {
    public let failedLogins: Int
    public let acceptedLogins: Int
    public let topAttackers: [AttackSource]
    public let hardeningData: String
    public let sshConfig: String
    
    public init(
        failedLogins: Int, acceptedLogins: Int,
        topAttackers: [AttackSource], hardeningData: String, sshConfig: String
    ) {
        self.failedLogins = failedLogins
        self.acceptedLogins = acceptedLogins
        self.topAttackers = topAttackers
        self.hardeningData = hardeningData
        self.sshConfig = sshConfig
    }
}

// MARK: - Firewall Rule

public struct SecurityFirewallRule: Sendable {
    public let proto: String
    public let port: String
    public let target: String
    public let chain: String
    public let source: String
    
    public init(proto: String, port: String, target: String, chain: String, source: String) {
        self.proto = proto
        self.port = port
        self.target = target
        self.chain = chain
        self.source = source
    }
}

// MARK: - SSH Config

public struct SSHConfigData: Sendable {
    public let port: String
    public let permitRootLogin: String
    public let passwordAuth: String
    public let pubkeyAuth: String
    
    public init(port: String, permitRootLogin: String, passwordAuth: String, pubkeyAuth: String) {
        self.port = port
        self.permitRootLogin = permitRootLogin
        self.passwordAuth = passwordAuth
        self.pubkeyAuth = pubkeyAuth
    }
}
