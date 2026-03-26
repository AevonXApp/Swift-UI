//
//  ChronoModels.swift
//  AevonX
//
//  Codable models for AXChrono Stats API responses.
//

import Foundation

// MARK: - Daemon Status

struct ChronoDaemonStatus: Codable {
    let version: String
    let uptimeSeconds: Int
    let activeDeploys: Int
    let queuedDeploys: Int
    let trackedProjects: Int
    let totalDeploys: Int
    let totalRollbacks: Int
    let cacheSizeMB: Int
    let snapshotCount: Int
    let healthStatus: String
    let failedThisWeek: Int
    let secretsDetected: Int

    private enum CodingKeys: String, CodingKey {
        case version
        case uptimeSeconds = "uptime_seconds"
        case activeDeploys = "active_deploys"
        case queuedDeploys = "queued_deploys"
        case trackedProjects = "tracked_projects"
        case totalDeploys = "total_deploys"
        case totalRollbacks = "total_rollbacks"
        case cacheSizeMB = "cache_size_mb"
        case snapshotCount = "snapshot_count"
        case healthStatus = "health_status"
        case failedThisWeek = "failed_this_week"
        case secretsDetected = "secrets_detected"
    }
}

// MARK: - Project

struct ChronoProject: Codable, Identifiable {
    let id: String
    let name: String
    let path: String
    let repoURL: String
    let branch: String
    let framework: String
    let lastCommit: String
    let lastDeploy: String?
    let lastDeployStatus: String
    let healthStatus: String
    let autoDeploy: Bool
    let enabled: Bool
    let pendingCommits: Int
    let watchMode: String

    private enum CodingKeys: String, CodingKey {
        case id, name, path, branch, framework, enabled
        case repoURL = "repo_url"
        case lastCommit = "last_commit"
        case lastDeploy = "last_deploy"
        case lastDeployStatus = "last_deploy_status"
        case healthStatus = "health_status"
        case autoDeploy = "auto_deploy"
        case pendingCommits = "pending_commits"
        case watchMode = "watch_mode"
    }
}

// MARK: - Deploy

struct ChronoDeploy: Codable, Identifiable {
    let id: String
    let projectId: String
    let projectName: String
    let commit: String
    let prevCommit: String
    let status: String
    let durationMS: Int
    let startedAt: String
    let finishedAt: String?
    let trigger: String
    let filesChanged: Int
    let steps: [ChronoDeployStep]

    private enum CodingKeys: String, CodingKey {
        case id, commit, status, trigger, steps
        case projectId = "project_id"
        case projectName = "project_name"
        case prevCommit = "prev_commit"
        case durationMS = "duration_ms"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
        case filesChanged = "files_changed"
    }
}

struct ChronoDeployStep: Codable, Identifiable {
    var id: String { name }
    let name: String
    let status: String
    let durationMS: Int
    let message: String?

    private enum CodingKeys: String, CodingKey {
        case name, status, message
        case durationMS = "duration_ms"
    }
}

// MARK: - Snapshot

struct ChronoSnapshot: Codable, Identifiable {
    let id: String
    let projectID: String
    let commitHash: String
    let createdAt: String
    let sizeBytes: Int64
    let fileCount: Int
    let type: String

    private enum CodingKeys: String, CodingKey {
        case id, type
        case projectID = "project_id"
        case commitHash = "commit_hash"
        case createdAt = "created_at"
        case sizeBytes = "size_bytes"
        case fileCount = "file_count"
    }
}

// MARK: - Hologram

struct ChronoHologram: Codable {
    let filesChanged: Int
    let filesModified: Int
    let filesAdded: Int
    let filesDeleted: Int
    let dependencyChanges: [String]
    let migrationsPending: [String]
    let buildSteps: [String]
    let estimatedDurationSec: Int
    let riskLevel: String
    let secretsDetected: Int
    let vulnsDetected: Int
    let estimatedDowntimeSec: Int

    private enum CodingKeys: String, CodingKey {
        case dependencyChanges = "dependency_changes"
        case migrationsPending = "migrations_pending"
        case buildSteps = "build_steps"
        case estimatedDurationSec = "estimated_duration_sec"
        case riskLevel = "risk_level"
        case secretsDetected = "secrets_detected"
        case vulnsDetected = "vulns_detected"
        case estimatedDowntimeSec = "estimated_downtime_sec"
        case filesChanged = "files_changed"
        case filesModified = "files_modified"
        case filesAdded = "files_added"
        case filesDeleted = "files_deleted"
    }
}

// MARK: - Approval

struct ChronoApproval: Codable, Identifiable {
    let id: String
    let type: String
    let projectId: String
    let projectName: String
    let reason: String
    let requestedAt: String
    let expiresAt: String
    let details: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case id, type, reason, details
        case projectId = "project_id"
        case projectName = "project_name"
        case requestedAt = "requested_at"
        case expiresAt = "expires_at"
    }
}

struct ChronoApprovalHistory: Codable, Identifiable {
    let id: String
    let type: String
    let projectName: String
    let action: String
    let actionAt: String

    private enum CodingKeys: String, CodingKey {
        case id, type, action
        case projectName = "project_name"
        case actionAt = "action_at"
    }
}

// MARK: - Timeline

struct ChronoTimelineEntry: Codable, Identifiable {
    let id: String
    let projectId: String
    let projectName: String
    let event: String
    let status: String
    let message: String
    let timestamp: String
    let commitHash: String?

    private enum CodingKeys: String, CodingKey {
        case id, event, status, message, timestamp
        case projectId = "project_id"
        case projectName = "project_name"
        case commitHash = "commit_hash"
    }
}

// MARK: - Security

struct ChronoSecurityResults: Codable {
    let secretsFound: Int
    let vulnsFound: Int
    let driftFiles: Int
    let permissionIssues: Int
    let secrets: [ChronoSecretFinding]
    let vulns: [ChronoVulnFinding]
    let driftedFiles: [String]

    private enum CodingKeys: String, CodingKey {
        case secrets, vulns
        case secretsFound = "secrets_found"
        case vulnsFound = "vulns_found"
        case driftFiles = "drift_files"
        case permissionIssues = "permission_issues"
        case driftedFiles = "drifted_files"
    }
}

struct ChronoSecretFinding: Codable, Identifiable {
    var id: String { file + ":\(line)" }
    let file: String
    let line: Int
    let type: String
    let severity: String
}

struct ChronoVulnFinding: Codable, Identifiable {
    var id: String { package + ":" + version }
    let package: String
    let version: String
    let severity: String
    let advisory: String
}

// MARK: - Watcher Info

struct ChronoWatcherInfo: Codable, Identifiable {
    var id: String { projectId }
    let projectId: String
    let projectName: String
    let branch: String
    let mode: String
    let pollInterval: Int
    let lastCheck: String?
    let pendingCommits: Int

    private enum CodingKeys: String, CodingKey {
        case branch, mode
        case projectId = "project_id"
        case projectName = "project_name"
        case pollInterval = "poll_interval"
        case lastCheck = "last_check"
        case pendingCommits = "pending_commits"
    }
}

// MARK: - Alert

struct ChronoAlert: Codable, Identifiable {
    let id: String
    let type: String
    let projectName: String
    let message: String
    let timestamp: String
    let severity: String

    private enum CodingKeys: String, CodingKey {
        case id, type, message, timestamp, severity
        case projectName = "project_name"
    }
}

// MARK: - Webhook

struct ChronoWebhookStatus: Codable {
    let active: Bool
    let port: Int
    let webhookURL: String
    let githubSecret: String
    let gitlabSecret: String
    let bitbucketSecret: String
    let genericSecret: String
    let recentDeliveries: [ChronoWebhookDelivery]

    private enum CodingKeys: String, CodingKey {
        case active, port
        case webhookURL = "webhook_url"
        case githubSecret = "github_secret"
        case gitlabSecret = "gitlab_secret"
        case bitbucketSecret = "bitbucket_secret"
        case genericSecret = "generic_secret"
        case recentDeliveries = "recent_deliveries"
    }
}

struct ChronoWebhookDelivery: Codable, Identifiable {
    let id: String
    let provider: String
    let repo: String
    let branch: String
    let success: Bool
    let timestamp: String
}

// MARK: - Config

struct ChronoConfig: Codable {
    var gitpulseMode: String
    var gitpulsePollInterval: Int
    var gitpulseAdaptivePolling: Bool
    var zeroflipEnabled: Bool
    var zeroflipMaxReleases: Int
    var sentinelEnabled: Bool
    var sentinelAutoRollback: Bool
    var vaultscanEnabled: Bool
    var vaultscanMode: String
    var threatradarEnabled: Bool
    var selfhealEnabled: Bool
    var approvalMode: String
    var webhookListenPort: Int

    private enum CodingKeys: String, CodingKey {
        case gitpulseMode = "gitpulse_mode"
        case gitpulsePollInterval = "gitpulse_poll_interval"
        case gitpulseAdaptivePolling = "gitpulse_adaptive_polling"
        case zeroflipEnabled = "zeroflip_enabled"
        case zeroflipMaxReleases = "zeroflip_max_releases"
        case sentinelEnabled = "sentinel_enabled"
        case sentinelAutoRollback = "sentinel_auto_rollback"
        case vaultscanEnabled = "vaultscan_enabled"
        case vaultscanMode = "vaultscan_mode"
        case threatradarEnabled = "threatradar_enabled"
        case selfhealEnabled = "selfheal_enabled"
        case approvalMode = "approval_mode"
        case webhookListenPort = "webhook_listen_port"
    }
}

// MARK: - API Response Wrapper

struct ChronoAPIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

// MARK: - Health Probe

struct ChronoHealthProbe: Codable, Identifiable {
    let id: String
    let projectId: String
    let projectName: String
    let url: String
    let status: String
    let responseTimeMS: Int
    let lastCheck: String
    let uptimePercent: Double
    let consecutiveFailures: Int

    private enum CodingKeys: String, CodingKey {
        case id, url, status
        case projectId = "project_id"
        case projectName = "project_name"
        case responseTimeMS = "response_time_ms"
        case lastCheck = "last_check"
        case uptimePercent = "uptime_percent"
        case consecutiveFailures = "consecutive_failures"
    }
}

// MARK: - Service Status

struct ChronoServiceStatus: Codable {
    let isActive: Bool
    let pid: Int?
    let uptimeSeconds: Int?

    private enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
        case pid
        case uptimeSeconds = "uptime_seconds"
    }
}
