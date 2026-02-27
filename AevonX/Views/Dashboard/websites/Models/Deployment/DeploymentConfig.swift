//
//  DeploymentConfig.swift
//  AevonX
//
//  Models for per-site deployment pipeline management
//

import Foundation
import SwiftUI

// MARK: - Deployment Status

enum SiteDeploymentStatus: String, CaseIterable, Identifiable {
    case idle = "Idle"
    case building = "Building"
    case deploying = "Deploying"
    case success = "Success"
    case failed = "Failed"
    case rolledBack = "Rolled Back"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .idle: return .axTextMuted
        case .building: return .axAccentBlue
        case .deploying: return .orange
        case .success: return .axSuccess
        case .failed: return .axError
        case .rolledBack: return .axWarning
        }
    }

    var icon: String {
        switch self {
        case .idle: return "circle"
        case .building: return "hammer.fill"
        case .deploying: return "arrow.up.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .rolledBack: return "arrow.uturn.backward.circle.fill"
        }
    }
}

// MARK: - Deployment Entry

struct DeploymentEntry: Identifiable {
    let id = UUID()
    let commitHash: String
    let commitMessage: String
    let branch: String
    let author: String
    let date: Date
    var status: SiteDeploymentStatus
    var duration: TimeInterval?
    var buildOutput: String?

    var shortHash: String {
        String(commitHash.prefix(7))
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        if duration < 60 {
            return String(format: "%.0fs", duration)
        }
        return String(format: "%.0fm %.0fs", duration / 60, duration.truncatingRemainder(dividingBy: 60))
    }
}

// MARK: - Build Command

struct BuildCommand: Identifiable, Hashable {
    let id = UUID()
    var command: String
    var description: String
    var order: Int
    var enabled: Bool

    static var presets: [String: [BuildCommand]] {
        [
            "Laravel": [
                BuildCommand(command: "composer install --no-dev --optimize-autoloader", description: "Install PHP dependencies", order: 1, enabled: true),
                BuildCommand(command: "php artisan migrate --force", description: "Run database migrations", order: 2, enabled: true),
                BuildCommand(command: "php artisan config:cache", description: "Cache configuration", order: 3, enabled: true),
                BuildCommand(command: "php artisan route:cache", description: "Cache routes", order: 4, enabled: true),
                BuildCommand(command: "php artisan view:cache", description: "Cache views", order: 5, enabled: true),
                BuildCommand(command: "npm run build", description: "Build frontend assets", order: 6, enabled: false),
            ],
            "WordPress": [
                BuildCommand(command: "wp core update", description: "Update WordPress core", order: 1, enabled: false),
                BuildCommand(command: "wp plugin update --all", description: "Update all plugins", order: 2, enabled: false),
            ],
            "Node.js": [
                BuildCommand(command: "npm ci", description: "Install dependencies", order: 1, enabled: true),
                BuildCommand(command: "npm run build", description: "Build application", order: 2, enabled: true),
                BuildCommand(command: "pm2 restart ecosystem.config.js", description: "Restart PM2", order: 3, enabled: true),
            ],
            "Static": [
                BuildCommand(command: "npm ci", description: "Install dependencies", order: 1, enabled: true),
                BuildCommand(command: "npm run build", description: "Build static site", order: 2, enabled: true),
            ],
        ]
    }
}

// MARK: - Deploy Lock

struct DeployLock {
    var isLocked: Bool
    var lockedBy: String?
    var lockedAt: Date?
    var reason: String?

    var formattedLockedAt: String {
        guard let date = lockedAt else { return "N/A" }
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Maintenance Mode

struct MaintenanceMode {
    var isEnabled: Bool
    var message: String = "We're currently performing maintenance. We'll be back shortly."
    var retryAfter: Int = 3600  // seconds
    var allowedIPs: [String] = []
}
