//
//  SecurityModels.swift
//  AevonX
//
//  Data models for SSH security, firewall, and Fail2Ban.
//

import SwiftUI

// MARK: - SSH Authorized Key

struct SSHAuthorizedKey: Identifiable {
    let id: Int  // line number (1-based)
    let keyType: String
    let fingerprint: String
    let comment: String
    let fullLine: String
}

// MARK: - SSH Host Key Fingerprint

struct SSHHostKeyFingerprint: Identifiable {
    let id = UUID()
    let bits: String
    let hash: String
    let keyFile: String
    let keyType: String
}

// MARK: - Failed Login

struct SSHFailedLogin: Identifiable {
    let id = UUID()
    let timestamp: String
    let ip: String
    let user: String
    let message: String
}

// MARK: - Recent Login

struct SSHRecentLogin: Identifiable {
    let id = UUID()
    let user: String
    let terminal: String
    let fromIP: String
    let dateRange: String
}

// MARK: - SSH Security Score

struct SSHSecurityScore {
    let score: Int        // 0-100
    let grade: String     // A, B, C, D, F
    let issues: [String]

    var gradeColor: Color {
        switch grade {
        case "A": return .axSuccess
        case "B": return .axAccentGreen
        case "C": return .axWarning
        case "D": return .orange
        default: return .axError
        }
    }
}

// MARK: - Firewall Rule (Server Settings version)

struct ServerFirewallRule: Identifiable {
    let id: Int  // rule number
    let action: String
    let direction: String
    let proto: String
    let port: String
    let source: String
    let raw: String
}

// MARK: - Fail2Ban Jail

struct Fail2BanJail: Identifiable {
    let id: String  // jail name
    let name: String
    let currentlyBanned: Int
    let totalBanned: Int
    let currentlyFailed: Int
    let totalFailed: Int
    let bannedIPs: [String]
}

// MARK: - Fail2Ban Log Entry

struct Fail2BanLogEntry: Identifiable {
    let id = UUID()
    let timestamp: String
    let level: String
    let jail: String
    let action: String
    let ip: String
}
