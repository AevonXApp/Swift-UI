//
//  BackupInfo.swift
//  AevonX
//
//  Models for per-site backup and restore operations
//

import Foundation
import SwiftUI

// MARK: - Backup Type

enum SiteBackupType: String, CaseIterable, Identifiable {
    case full = "Full Backup"
    case filesOnly = "Files Only"
    case databaseOnly = "Database Only"
    case incremental = "Incremental"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .full: return "archivebox.fill"
        case .filesOnly: return "folder.fill"
        case .databaseOnly: return "cylinder.fill"
        case .incremental: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .full: return .axAccentBlue
        case .filesOnly: return .axWarning
        case .databaseOnly: return .axSuccess
        case .incremental: return .purple
        }
    }
}

// MARK: - Backup Info

struct SiteBackupInfo: Identifiable, Hashable {
    let id = UUID()
    let filename: String
    let type: SiteBackupType
    let date: Date
    let size: String
    let path: String
    var includesDatabase: Bool

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Backup Schedule

struct BackupSchedule: Identifiable, Hashable {
    let id = UUID()
    var enabled: Bool
    var frequency: BackupFrequency
    var type: SiteBackupType
    var retentionDays: Int
    var cronExpression: String

    enum BackupFrequency: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"

        var id: String { rawValue }

        var cronPattern: String {
            switch self {
            case .daily: return "0 3 * * *"
            case .weekly: return "0 3 * * 0"
            case .monthly: return "0 3 1 * *"
            }
        }
    }
}

// MARK: - Restore Point

struct RestorePoint: Identifiable {
    let id = UUID()
    let backup: SiteBackupInfo
    var restoreFiles: Bool = true
    var restoreDatabase: Bool = true
    var targetPath: String
}
