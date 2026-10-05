//
//  FTPModels.swift
//  AevonXCoreBridge
//
//  Models for PureFTPd management — migrated from AevonXCore
//

import Foundation

// MARK: - FTP User Status

public enum FTPUserStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active"
    case inactive = "Inactive"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .inactive: return "xmark.circle.fill"
        }
    }

    public var color: String {
        switch self {
        case .active: return "axSuccess"
        case .inactive: return "axTextMuted"
        }
    }
}

// MARK: - FTP User

public struct FTPUser: Identifiable, Codable, Equatable {
    public var id: UUID
    public var username: String
    public var password: String
    public var status: FTPUserStatus
    public var documentRoot: String
    public var quota: Int  // MB, 0 = unlimited
    public var note: String

    public init(
        id: UUID = UUID(),
        username: String = "",
        password: String = "",
        status: FTPUserStatus = .active,
        documentRoot: String = "/www/wwwroot",
        quota: Int = 0,
        note: String = ""
    ) {
        self.id = id
        self.username = username
        self.password = password
        self.status = status
        self.documentRoot = documentRoot
        self.quota = quota
        self.note = note
    }

    public var quotaDisplay: String {
        quota == 0 ? "Unlimited" : "\(quota) MB"
    }

    public var maskedPassword: String {
        guard password.count > 2 else { return String(repeating: "•", count: 8) }
        return String(password.prefix(2)) + String(repeating: "•", count: max(password.count - 2, 6))
    }
}

// MARK: - FTP Server Info

public struct FTPServerInfo: Codable, Equatable {
    public var isInstalled: Bool
    public var isRunning: Bool
    public var version: String
    public var port: Int
    public var ftpAddress: String

    public init(
        isInstalled: Bool = false,
        isRunning: Bool = false,
        version: String = "",
        port: Int = 21,
        ftpAddress: String = ""
    ) {
        self.isInstalled = isInstalled
        self.isRunning = isRunning
        self.version = version
        self.port = port
        self.ftpAddress = ftpAddress
    }

    public var statusDisplay: String {
        if !isInstalled { return "Not Installed" }
        return isRunning ? "Running" : "Stopped"
    }
}

// MARK: - FTP Log Entry

public struct FTPLogEntry: Identifiable, Codable {
    public var id: UUID
    public var timestamp: String
    public var message: String
    public var type: FTPLogType

    public init(id: UUID = UUID(), timestamp: String, message: String, type: FTPLogType = .info) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
        self.type = type
    }
}

// MARK: - FTP Log Type

public enum FTPLogType: String, Codable {
    case info = "Info"
    case login = "Login"
    case logout = "Logout"
    case upload = "Upload"
    case download = "Download"
    case error = "Error"
}
