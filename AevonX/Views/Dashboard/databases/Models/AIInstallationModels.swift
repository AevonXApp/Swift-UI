//
//  AIInstallationModels.swift
//  AevonX
//
//  UI-specific models for AI-assisted database installation
//  Note: Core types are defined in AevonXCore.AIInstallationAPIService
//

import Foundation
import AevonXCore

// MARK: - UI Extensions for Core Types

/// UI-specific extensions for AIInstallationResponse
extension AIInstallationResponse {
    
    /// The recommended version (highest compatibility score)
    public var recommendedVersion: DatabaseVersionRecommendation? {
        recommendations.first(where: { $0.isRecommended }) ?? recommendations.first
    }
    
    /// All available versions sorted by compatibility score
    public var sortedVersions: [DatabaseVersionRecommendation] {
        recommendations.sorted { $0.compatibilityScore > $1.compatibilityScore }
    }
    
    /// LTS versions only
    public var ltsVersions: [DatabaseVersionRecommendation] {
        recommendations.filter { $0.isLTS }
    }
    
    /// Whether the system meets minimum requirements
    public var meetsRequirements: Bool {
        // This would need server resources to compare
        return true
    }
}

extension DatabaseVersionRecommendation {
    
    /// Formatted version string with LTS indicator
    public var displayVersion: String {
        isLTS ? "\(version) (LTS)" : version
    }
    
    /// Compatibility score as percentage
    public var compatibilityPercentage: Int {
        min(max(compatibilityScore, 0), 100)
    }
    
    /// Security status display info
    public var securityDisplay: (icon: String, color: String) {
        switch securityStatus {
        case .secure:
            return ("checkmark.shield.fill", "axSuccess")
        case .updatesAvailable:
            return ("exclamationmark.shield.fill", "axWarning")
        case .critical:
            return ("xmark.shield.fill", "axError")
        case .endOfLife:
            return ("clock.badge.xmark", "axTextMuted")
        case .unknown:
            return ("questionmark.shield", "axTextSecondary")
        }
    }
    
    /// Get install commands for a specific package manager
    public func installCommands(for packageManager: PackageManager) -> PackageManagerCommand? {
        installCommands.first { $0.packageManager == packageManager }
    }
    
    /// Primary install command (first available)
    public var primaryInstallCommand: PackageManagerCommand? {
        installCommands.first
    }
}

extension InstallationProgress {
    
    /// Progress as a percentage (0-100)
    public var progressPercent: Int {
        Int(progressPercentage * 100)
    }
    
    /// Estimated time remaining in minutes
    public var estimatedMinutesRemaining: Int? {
        guard let estimatedCompletion = estimatedCompletionAt else { return nil }
        let remaining = estimatedCompletion.timeIntervalSince(Date())
        return max(0, Int(remaining / 60))
    }
    
    /// Whether the installation is in an active state
    public var isActive: Bool {
        switch status {
        case .pending, .analyzing, .downloading, .installing, .configuring, .validating, .rollingBack:
            return true
        case .completed, .failed, .cancelled:
            return false
        }
    }
    
    /// Whether the installation can be cancelled
    public var canCancel: Bool {
        switch status {
        case .pending, .analyzing, .downloading, .installing, .configuring:
            return true
        case .validating, .completed, .failed, .cancelled, .rollingBack:
            return false
        }
    }
    
    /// Status display info
    public var statusDisplay: (title: String, icon: String, color: String) {
        switch status {
        case .pending:
            return ("Pending", "hourglass", "axTextSecondary")
        case .analyzing:
            return ("Analyzing System", "magnifyingglass", "axInfo")
        case .downloading:
            return ("Downloading", "arrow.down.circle", "axAccentBlue")
        case .installing:
            return ("Installing", "gear", "axAccentBlue")
        case .configuring:
            return ("Configuring", "slider.horizontal.3", "axAccentGreen")
        case .validating:
            return ("Validating", "checkmark.circle", "axAccentGreen")
        case .completed:
            return ("Completed", "checkmark.circle.fill", "axSuccess")
        case .failed:
            return ("Failed", "xmark.circle.fill", "axError")
        case .cancelled:
            return ("Cancelled", "xmark.circle", "axTextMuted")
        case .rollingBack:
            return ("Rolling Back", "arrow.uturn.backward.circle", "axWarning")
        }
    }
    
    /// Recent logs (last 50)
    public var recentLogs: [InstallationLog] {
        Array(logs.suffix(50))
    }
    
    /// Error logs only
    public var errorLogs: [InstallationLog] {
        logs.filter { $0.level == .error }
    }
}

extension InstallationLog {
    
    /// Log level display info
    public var levelDisplay: (icon: String, color: String) {
        switch level {
        case .debug:
            return ("bug", "axTextMuted")
        case .info:
            return ("info.circle", "axInfo")
        case .warning:
            return ("exclamationmark.triangle", "axWarning")
        case .error:
            return ("xmark.octagon", "axError")
        case .success:
            return ("checkmark.circle", "axSuccess")
        }
    }
    
    /// Formatted timestamp
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

extension InstallationError {
    
    /// Error display info
    public var display: (icon: String, color: String, title: String) {
        switch code {
        case "NETWORK_ERROR":
            return ("wifi.exclamationmark", "axError", "Network Error")
        case "PERMISSION_DENIED":
            return ("lock.slash", "axError", "Permission Denied")
        case "INSUFFICIENT_RESOURCES":
            return ("memorychip", "axWarning", "Insufficient Resources")
        case "CONFLICT":
            return ("exclamationmark.triangle", "axWarning", "Conflict Detected")
        case "TIMEOUT":
            return ("clock.arrow.circlepath", "axWarning", "Installation Timeout")
        default:
            return ("xmark.octagon", "axError", "Installation Failed")
        }
    }
}

// MARK: - UI-Specific Types

/// Represents the current step in the installation wizard
public enum InstallationWizardStep: CaseIterable {
    case selectVersion
    case reviewRequirements
    case configureOptions
    case confirmInstallation
    case installing
    case completed
    
    public var title: String {
        switch self {
        case .selectVersion: return "Select Version"
        case .reviewRequirements: return "Review Requirements"
        case .configureOptions: return "Configure Options"
        case .confirmInstallation: return "Confirm"
        case .installing: return "Installing"
        case .completed: return "Completed"
        }
    }
    
    public var icon: String {
        switch self {
        case .selectVersion: return "number.circle"
        case .reviewRequirements: return "list.bullet.clipboard"
        case .configureOptions: return "gearshape.2"
        case .confirmInstallation: return "checkmark.circle"
        case .installing: return "arrow.down.circle"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

/// User preferences for database installation
public struct DatabaseInstallationPreferences {
    public var autoStartService: Bool
    public var enableRemoteAccess: Bool
    public var configureFirewall: Bool
    public var createDefaultDatabase: Bool
    public var optimizeForPerformance: Bool
    public var enableBackups: Bool
    public var backupSchedule: BackupSchedule
    
    public init(
        autoStartService: Bool = true,
        enableRemoteAccess: Bool = false,
        configureFirewall: Bool = true,
        createDefaultDatabase: Bool = true,
        optimizeForPerformance: Bool = true,
        enableBackups: Bool = true,
        backupSchedule: BackupSchedule = .daily
    ) {
        self.autoStartService = autoStartService
        self.enableRemoteAccess = enableRemoteAccess
        self.configureFirewall = configureFirewall
        self.createDefaultDatabase = createDefaultDatabase
        self.optimizeForPerformance = optimizeForPerformance
        self.enableBackups = enableBackups
        self.backupSchedule = backupSchedule
    }
}

/// Backup schedule options
public enum BackupSchedule: String, CaseIterable, Identifiable {
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case manual = "manual"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .hourly: return "Every Hour"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .manual: return "Manual Only"
        }
    }
}

// MARK: - View State Types

/// State for the AI installation view
public enum AIInstallationViewState: Equatable {
    case idle
    case loadingRecommendations
    case showingRecommendations
    case installing(InstallationProgress)
    case completed(DatabaseInfo)
    case failed(InstallationError)
    
    public static func == (lhs: AIInstallationViewState, rhs: AIInstallationViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loadingRecommendations, .loadingRecommendations),
             (.showingRecommendations, .showingRecommendations):
            return true
        case (.installing(let lhs), .installing(let rhs)):
            return lhs.installationId == rhs.installationId && lhs.status == rhs.status
        case (.completed(let lhs), .completed(let rhs)):
            return lhs.id == rhs.id
        case (.failed(let lhs), .failed(let rhs)):
            return lhs.id == rhs.id
        default:
            return false
        }
    }
}

/// Filter options for database list
public struct DatabaseListFilters {
    public var searchQuery: String
    public var selectedCategories: Set<DatabaseCategory>
    public var showInstalledOnly: Bool
    public var showAISupportedOnly: Bool
    public var sortBy: DatabaseSortOption
    
    public init(
        searchQuery: String = "",
        selectedCategories: Set<DatabaseCategory> = [],
        showInstalledOnly: Bool = false,
        showAISupportedOnly: Bool = false,
        sortBy: DatabaseSortOption = .name
    ) {
        self.searchQuery = searchQuery
        self.selectedCategories = selectedCategories
        self.showInstalledOnly = showInstalledOnly
        self.showAISupportedOnly = showAISupportedOnly
        self.sortBy = sortBy
    }
    
    public var isActive: Bool {
        !searchQuery.isEmpty ||
        !selectedCategories.isEmpty ||
        showInstalledOnly ||
        showAISupportedOnly ||
        sortBy != .name
    }
}

/// Sort options for database list
public enum DatabaseSortOption: String, CaseIterable, Identifiable {
    case name = "name"
    case type = "type"
    case status = "status"
    case size = "size"
    case lastUsed = "lastUsed"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .name: return "Name"
        case .type: return "Type"
        case .status: return "Status"
        case .size: return "Size"
        case .lastUsed: return "Last Used"
        }
    }
}
