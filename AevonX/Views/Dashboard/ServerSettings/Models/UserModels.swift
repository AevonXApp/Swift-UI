//
//  UserModels.swift
//  AevonX
//
//  Data models for advanced user management.
//

import SwiftUI

// MARK: - Active Session

struct ActiveSession: Identifiable {
    let id = UUID()
    let user: String
    let terminal: String
    let fromIP: String
    let loginTime: String
}

// MARK: - System Group

struct SystemGroup: Identifiable {
    var id: String { name }
    let name: String
    let gid: String
    let members: [String]
}

// MARK: - Password Status

struct PasswordStatus: Identifiable {
    var id: String { username }
    let username: String
    let status: String      // P=set, L=locked, NP=no password
    let lastChanged: String
    let minDays: String
    let maxDays: String

    var statusLabel: String {
        switch status {
        case "P": return "Set"
        case "L": return "Locked"
        case "NP": return "No Password"
        default: return status
        }
    }

    var statusColor: Color {
        switch status {
        case "P": return .axSuccess
        case "L": return .axError
        case "NP": return .axWarning
        default: return .axTextMuted
        }
    }
}

// MARK: - User Disk Usage

struct UserDiskUsage: Identifiable {
    let id = UUID()
    let path: String
    let size: String

    var username: String {
        path.split(separator: "/").last.map(String.init) ?? path
    }
}
