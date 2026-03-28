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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(String.self, forKey: .version) ?? "0.0.0"
        uptimeSeconds = try c.decodeIfPresent(Int.self, forKey: .uptimeSeconds) ?? 0
        activeDeploys = try c.decodeIfPresent(Int.self, forKey: .activeDeploys) ?? 0
        queuedDeploys = try c.decodeIfPresent(Int.self, forKey: .queuedDeploys) ?? 0
        trackedProjects = try c.decodeIfPresent(Int.self, forKey: .trackedProjects) ?? 0
        totalDeploys = try c.decodeIfPresent(Int.self, forKey: .totalDeploys) ?? 0
        totalRollbacks = try c.decodeIfPresent(Int.self, forKey: .totalRollbacks) ?? 0
        cacheSizeMB = try c.decodeIfPresent(Int.self, forKey: .cacheSizeMB) ?? 0
        snapshotCount = try c.decodeIfPresent(Int.self, forKey: .snapshotCount) ?? 0
        healthStatus = try c.decodeIfPresent(String.self, forKey: .healthStatus) ?? "unknown"
        failedThisWeek = try c.decodeIfPresent(Int.self, forKey: .failedThisWeek) ?? 0
        secretsDetected = try c.decodeIfPresent(Int.self, forKey: .secretsDetected) ?? 0
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
        case watchMode = "mode"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        path = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
        repoURL = try c.decodeIfPresent(String.self, forKey: .repoURL) ?? ""
        branch = try c.decodeIfPresent(String.self, forKey: .branch) ?? "main"
        framework = try c.decodeIfPresent(String.self, forKey: .framework) ?? ""
        lastCommit = try c.decodeIfPresent(String.self, forKey: .lastCommit) ?? ""
        lastDeploy = try c.decodeIfPresent(String.self, forKey: .lastDeploy)
        lastDeployStatus = try c.decodeIfPresent(String.self, forKey: .lastDeployStatus) ?? "unknown"
        healthStatus = try c.decodeIfPresent(String.self, forKey: .healthStatus) ?? "unknown"
        autoDeploy = try c.decodeIfPresent(Bool.self, forKey: .autoDeploy) ?? false
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        pendingCommits = try c.decodeIfPresent(Int.self, forKey: .pendingCommits) ?? 0
        watchMode = try c.decodeIfPresent(String.self, forKey: .watchMode) ?? "poll"
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        projectId = try c.decodeIfPresent(String.self, forKey: .projectId) ?? ""
        projectName = try c.decodeIfPresent(String.self, forKey: .projectName) ?? ""
        commit = try c.decodeIfPresent(String.self, forKey: .commit) ?? ""
        prevCommit = try c.decodeIfPresent(String.self, forKey: .prevCommit) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "unknown"
        durationMS = try c.decodeIfPresent(Int.self, forKey: .durationMS) ?? 0
        startedAt = try c.decodeIfPresent(String.self, forKey: .startedAt) ?? ""
        finishedAt = try c.decodeIfPresent(String.self, forKey: .finishedAt)
        trigger = try c.decodeIfPresent(String.self, forKey: .trigger) ?? ""
        filesChanged = try c.decodeIfPresent(Int.self, forKey: .filesChanged) ?? 0
        steps = try c.decodeIfPresent([ChronoDeployStep].self, forKey: .steps) ?? []
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "unknown"
        durationMS = try c.decodeIfPresent(Int.self, forKey: .durationMS) ?? 0
        message = try c.decodeIfPresent(String.self, forKey: .message)
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        projectID = try c.decodeIfPresent(String.self, forKey: .projectID) ?? ""
        commitHash = try c.decodeIfPresent(String.self, forKey: .commitHash) ?? ""
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        sizeBytes = try c.decodeIfPresent(Int64.self, forKey: .sizeBytes) ?? 0
        fileCount = try c.decodeIfPresent(Int.self, forKey: .fileCount) ?? 0
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "full"
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        filesChanged = try c.decodeIfPresent(Int.self, forKey: .filesChanged) ?? 0
        filesModified = try c.decodeIfPresent(Int.self, forKey: .filesModified) ?? 0
        filesAdded = try c.decodeIfPresent(Int.self, forKey: .filesAdded) ?? 0
        filesDeleted = try c.decodeIfPresent(Int.self, forKey: .filesDeleted) ?? 0
        dependencyChanges = try c.decodeIfPresent([String].self, forKey: .dependencyChanges) ?? []
        migrationsPending = try c.decodeIfPresent([String].self, forKey: .migrationsPending) ?? []
        buildSteps = try c.decodeIfPresent([String].self, forKey: .buildSteps) ?? []
        estimatedDurationSec = try c.decodeIfPresent(Int.self, forKey: .estimatedDurationSec) ?? 0
        riskLevel = try c.decodeIfPresent(String.self, forKey: .riskLevel) ?? "low"
        secretsDetected = try c.decodeIfPresent(Int.self, forKey: .secretsDetected) ?? 0
        vulnsDetected = try c.decodeIfPresent(Int.self, forKey: .vulnsDetected) ?? 0
        estimatedDowntimeSec = try c.decodeIfPresent(Int.self, forKey: .estimatedDowntimeSec) ?? 0
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? ""
        projectId = try c.decodeIfPresent(String.self, forKey: .projectId) ?? ""
        projectName = try c.decodeIfPresent(String.self, forKey: .projectName) ?? ""
        reason = try c.decodeIfPresent(String.self, forKey: .reason) ?? ""
        requestedAt = try c.decodeIfPresent(String.self, forKey: .requestedAt) ?? ""
        expiresAt = try c.decodeIfPresent(String.self, forKey: .expiresAt) ?? ""
        details = try c.decodeIfPresent([String: String].self, forKey: .details)
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? ""
        projectName = try c.decodeIfPresent(String.self, forKey: .projectName) ?? ""
        action = try c.decodeIfPresent(String.self, forKey: .action) ?? ""
        actionAt = try c.decodeIfPresent(String.self, forKey: .actionAt) ?? ""
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
        case id, status, timestamp
        case projectId = "project_id"
        case projectName = "project_name"
        case event = "type"
        case message
        case commitHash = "commit"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        projectId = try c.decodeIfPresent(String.self, forKey: .projectId) ?? ""
        projectName = try c.decodeIfPresent(String.self, forKey: .projectName) ?? ""
        event = try c.decodeIfPresent(String.self, forKey: .event) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? ""
        message = try c.decodeIfPresent(String.self, forKey: .message) ?? ""
        timestamp = try c.decodeIfPresent(String.self, forKey: .timestamp) ?? ""
        commitHash = try c.decodeIfPresent(String.self, forKey: .commitHash)
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        secretsFound = try c.decodeIfPresent(Int.self, forKey: .secretsFound) ?? 0
        vulnsFound = try c.decodeIfPresent(Int.self, forKey: .vulnsFound) ?? 0
        driftFiles = try c.decodeIfPresent(Int.self, forKey: .driftFiles) ?? 0
        permissionIssues = try c.decodeIfPresent(Int.self, forKey: .permissionIssues) ?? 0
        secrets = try c.decodeIfPresent([ChronoSecretFinding].self, forKey: .secrets) ?? []
        vulns = try c.decodeIfPresent([ChronoVulnFinding].self, forKey: .vulns) ?? []
        driftedFiles = try c.decodeIfPresent([String].self, forKey: .driftedFiles) ?? []
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try c.decodeIfPresent(String.self, forKey: .projectId) ?? ""
        projectName = try c.decodeIfPresent(String.self, forKey: .projectName) ?? ""
        branch = try c.decodeIfPresent(String.self, forKey: .branch) ?? ""
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "poll"
        pollInterval = try c.decodeIfPresent(Int.self, forKey: .pollInterval) ?? 60
        lastCheck = try c.decodeIfPresent(String.self, forKey: .lastCheck)
        pendingCommits = try c.decodeIfPresent(Int.self, forKey: .pendingCommits) ?? 0
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? ""
        projectName = try c.decodeIfPresent(String.self, forKey: .projectName) ?? ""
        message = try c.decodeIfPresent(String.self, forKey: .message) ?? ""
        timestamp = try c.decodeIfPresent(String.self, forKey: .timestamp) ?? ""
        severity = try c.decodeIfPresent(String.self, forKey: .severity) ?? "info"
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        active = try c.decodeIfPresent(Bool.self, forKey: .active) ?? false
        port = try c.decodeIfPresent(Int.self, forKey: .port) ?? 0
        webhookURL = try c.decodeIfPresent(String.self, forKey: .webhookURL) ?? ""
        githubSecret = try c.decodeIfPresent(String.self, forKey: .githubSecret) ?? ""
        gitlabSecret = try c.decodeIfPresent(String.self, forKey: .gitlabSecret) ?? ""
        bitbucketSecret = try c.decodeIfPresent(String.self, forKey: .bitbucketSecret) ?? ""
        genericSecret = try c.decodeIfPresent(String.self, forKey: .genericSecret) ?? ""
        recentDeliveries = try c.decodeIfPresent([ChronoWebhookDelivery].self, forKey: .recentDeliveries) ?? []
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gitpulseMode = try c.decodeIfPresent(String.self, forKey: .gitpulseMode) ?? "poll"
        gitpulsePollInterval = try c.decodeIfPresent(Int.self, forKey: .gitpulsePollInterval) ?? 60
        gitpulseAdaptivePolling = try c.decodeIfPresent(Bool.self, forKey: .gitpulseAdaptivePolling) ?? true
        zeroflipEnabled = try c.decodeIfPresent(Bool.self, forKey: .zeroflipEnabled) ?? true
        zeroflipMaxReleases = try c.decodeIfPresent(Int.self, forKey: .zeroflipMaxReleases) ?? 5
        sentinelEnabled = try c.decodeIfPresent(Bool.self, forKey: .sentinelEnabled) ?? true
        sentinelAutoRollback = try c.decodeIfPresent(Bool.self, forKey: .sentinelAutoRollback) ?? true
        vaultscanEnabled = try c.decodeIfPresent(Bool.self, forKey: .vaultscanEnabled) ?? true
        vaultscanMode = try c.decodeIfPresent(String.self, forKey: .vaultscanMode) ?? "block"
        threatradarEnabled = try c.decodeIfPresent(Bool.self, forKey: .threatradarEnabled) ?? true
        selfhealEnabled = try c.decodeIfPresent(Bool.self, forKey: .selfhealEnabled) ?? false
        approvalMode = try c.decodeIfPresent(String.self, forKey: .approvalMode) ?? "smart"
        webhookListenPort = try c.decodeIfPresent(Int.self, forKey: .webhookListenPort) ?? 9445
    }

    init(
        gitpulseMode: String = "poll", gitpulsePollInterval: Int = 60,
        gitpulseAdaptivePolling: Bool = true, zeroflipEnabled: Bool = true,
        zeroflipMaxReleases: Int = 5, sentinelEnabled: Bool = true,
        sentinelAutoRollback: Bool = true, vaultscanEnabled: Bool = true,
        vaultscanMode: String = "block", threatradarEnabled: Bool = true,
        selfhealEnabled: Bool = false, approvalMode: String = "smart",
        webhookListenPort: Int = 9445
    ) {
        self.gitpulseMode = gitpulseMode
        self.gitpulsePollInterval = gitpulsePollInterval
        self.gitpulseAdaptivePolling = gitpulseAdaptivePolling
        self.zeroflipEnabled = zeroflipEnabled
        self.zeroflipMaxReleases = zeroflipMaxReleases
        self.sentinelEnabled = sentinelEnabled
        self.sentinelAutoRollback = sentinelAutoRollback
        self.vaultscanEnabled = vaultscanEnabled
        self.vaultscanMode = vaultscanMode
        self.threatradarEnabled = threatradarEnabled
        self.selfhealEnabled = selfhealEnabled
        self.approvalMode = approvalMode
        self.webhookListenPort = webhookListenPort
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        projectId = try c.decodeIfPresent(String.self, forKey: .projectId) ?? ""
        projectName = try c.decodeIfPresent(String.self, forKey: .projectName) ?? ""
        url = try c.decodeIfPresent(String.self, forKey: .url) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? "unknown"
        responseTimeMS = try c.decodeIfPresent(Int.self, forKey: .responseTimeMS) ?? 0
        lastCheck = try c.decodeIfPresent(String.self, forKey: .lastCheck) ?? ""
        uptimePercent = try c.decodeIfPresent(Double.self, forKey: .uptimePercent) ?? 0.0
        consecutiveFailures = try c.decodeIfPresent(Int.self, forKey: .consecutiveFailures) ?? 0
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
