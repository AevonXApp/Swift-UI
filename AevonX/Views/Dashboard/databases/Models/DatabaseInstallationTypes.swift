//
//  DatabaseInstallationTypes.swift
//  AevonX
//
//  Local type definitions for database installation types.
//  These replace the types from AIInstallationAPIService.swift (AevonXCore).
//

import Foundation
import AevonXCoreBridge

// MARK: - AI Installation Response

public struct AIInstallationResponse {
    public let databaseType: DatabaseType
    public let recommendations: [DatabaseVersionRecommendation]
    public let systemRequirements: SystemRequirements
    public let installationSteps: [InstallationStep]
    public let postInstallationConfig: [ConfigurationRecommendation]
    public let warnings: [String]
    public let estimatedInstallTime: TimeInterval

    public init(
        databaseType: DatabaseType = .unknown,
        recommendations: [DatabaseVersionRecommendation] = [],
        systemRequirements: SystemRequirements = SystemRequirements(),
        installationSteps: [InstallationStep] = [],
        postInstallationConfig: [ConfigurationRecommendation] = [],
        warnings: [String] = [],
        estimatedInstallTime: TimeInterval = 300
    ) {
        self.databaseType = databaseType
        self.recommendations = recommendations
        self.systemRequirements = systemRequirements
        self.installationSteps = installationSteps
        self.postInstallationConfig = postInstallationConfig
        self.warnings = warnings
        self.estimatedInstallTime = estimatedInstallTime
    }
}

// MARK: - Version Recommendation

public struct DatabaseVersionRecommendation: Identifiable {
    public let id = UUID()
    public var version: String
    public var isRecommended: Bool
    public var isLTS: Bool
    public var compatibilityScore: Int
    public var reasoning: String
    public var installCommands: [PackageManagerCommand]
    public var clientVersion: String?
    public var securityStatus: SecurityStatus
    public var endOfLifeDate: Date?
    public var performanceProfile: PerformanceProfile

    public init(
        version: String = "",
        isRecommended: Bool = false,
        isLTS: Bool = false,
        compatibilityScore: Int = 0,
        reasoning: String = "",
        installCommands: [PackageManagerCommand] = [],
        clientVersion: String? = nil,
        securityStatus: SecurityStatus = .unknown,
        endOfLifeDate: Date? = nil,
        performanceProfile: PerformanceProfile = PerformanceProfile()
    ) {
        self.version = version
        self.isRecommended = isRecommended
        self.isLTS = isLTS
        self.compatibilityScore = compatibilityScore
        self.reasoning = reasoning
        self.installCommands = installCommands
        self.clientVersion = clientVersion
        self.securityStatus = securityStatus
        self.endOfLifeDate = endOfLifeDate
        self.performanceProfile = performanceProfile
    }
}

// MARK: - Security & Performance

public enum SecurityStatus: String, Codable {
    case secure = "secure"
    case updatesAvailable = "updates_available"
    case critical = "critical"
    case unknown = "unknown"
    case endOfLife = "end_of_life"
}

public struct PerformanceProfile {
    public var memoryUsage: ResourceUsage
    public var diskUsage: ResourceUsage
    public var cpuUsage: ResourceUsage
    public var recommendedFor: [DatabaseUseCase]

    public init(memoryUsage: ResourceUsage = .medium, diskUsage: ResourceUsage = .medium, cpuUsage: ResourceUsage = .medium, recommendedFor: [DatabaseUseCase] = []) {
        self.memoryUsage = memoryUsage; self.diskUsage = diskUsage
        self.cpuUsage = cpuUsage; self.recommendedFor = recommendedFor
    }
}

public enum ResourceUsage: String, Codable {
    case minimal, low, medium, high, veryHigh
}

public enum DatabaseUseCase: String, Codable, CaseIterable, Sendable {
    case webApplication, dataWarehouse, caching, realTimeAnalytics
    case contentManagement, ecommerce, microservices, development, testing
}

// MARK: - Package Manager

public enum PackageManager: String, CaseIterable, Sendable {
    case apt, yum, dnf, pacman, brew, apk, zypper, unknown

    public var displayName: String {
        switch self {
        case .apt: return "APT (Debian/Ubuntu)"
        case .yum: return "YUM (RHEL/CentOS 7)"
        case .dnf: return "DNF (RHEL/CentOS 8+)"
        case .pacman: return "Pacman (Arch)"
        case .brew: return "Homebrew (macOS)"
        case .apk: return "APK (Alpine)"
        case .zypper: return "Zypper (openSUSE)"
        case .unknown: return "Unknown"
        }
    }

    public static func detect(from osInfo: ServerOSInfo) -> PackageManager {
        let id = osInfo.id.lowercased()
        let idLike = osInfo.idLike.lowercased()
        if id.contains("debian") || id.contains("ubuntu") || idLike.contains("debian") { return .apt }
        else if id.contains("fedora") || (id.contains("centos") && id.contains("8")) || id.contains("rhel") { return .dnf }
        else if id.contains("centos") || idLike.contains("rhel") { return .yum }
        else if id.contains("arch") || idLike.contains("arch") { return .pacman }
        else if id.contains("alpine") { return .apk }
        else if id.contains("opensuse") || id.contains("suse") { return .zypper }
        else if id.contains("darwin") || id.contains("macos") { return .brew }
        return .unknown
    }
}

public struct PackageManagerCommand {
    public var packageManager: PackageManager
    public var commands: [String]
    public var preInstallCommands: [String]
    public var postInstallCommands: [String]
    public var repositorySetup: String?

    public init(packageManager: PackageManager = .unknown, commands: [String] = [], preInstallCommands: [String] = [], postInstallCommands: [String] = [], repositorySetup: String? = nil) {
        self.packageManager = packageManager; self.commands = commands
        self.preInstallCommands = preInstallCommands; self.postInstallCommands = postInstallCommands
        self.repositorySetup = repositorySetup
    }
}

// MARK: - Server Info

public struct ServerOSInfo: Codable, Sendable {
    public let id: String
    public let idLike: String
    public let versionId: String
    public let version: String
    public let prettyName: String
    public let kernelVersion: String
    public let architecture: String

    nonisolated public init(id: String = "", idLike: String = "", versionId: String = "", version: String = "",
                prettyName: String = "", kernelVersion: String = "", architecture: String = "") {
        self.id = id; self.idLike = idLike; self.versionId = versionId
        self.version = version; self.prettyName = prettyName
        self.kernelVersion = kernelVersion; self.architecture = architecture
    }

    public var fullDisplayName: String {
        prettyName.isEmpty ? "\(id) \(version)" : prettyName
    }

    public var isDebianBased: Bool {
        id.lowercased().contains("debian") || id.lowercased().contains("ubuntu") ||
        idLike.lowercased().contains("debian")
    }
}

public struct ServerResources: Codable, Sendable {
    public var totalMemoryMB: Int
    public var availableMemoryMB: Int
    public var totalDiskGB: Int
    public var availableDiskGB: Int
    public var cpuCount: Int
    public var cpuArchitecture: String

    nonisolated public init(totalMemoryMB: Int = 0, availableMemoryMB: Int = 0, totalDiskGB: Int = 0,
                availableDiskGB: Int = 0, cpuCount: Int = 0, cpuArchitecture: String = "") {
        self.totalMemoryMB = totalMemoryMB; self.availableMemoryMB = availableMemoryMB
        self.totalDiskGB = totalDiskGB; self.availableDiskGB = availableDiskGB
        self.cpuCount = cpuCount; self.cpuArchitecture = cpuArchitecture
    }
}

// MARK: - System Requirements

public struct SystemRequirements {
    public var minimumMemoryMB: Int
    public var recommendedMemoryMB: Int
    public var minimumDiskGB: Int
    public var recommendedDiskGB: Int
    public var minimumCpuCores: Int
    public var requiredPorts: [Int]
    public var conflictingPackages: [String]
    public var requiredLibraries: [String]

    public init(minimumMemoryMB: Int = 512, recommendedMemoryMB: Int = 2048, minimumDiskGB: Int = 5,
                recommendedDiskGB: Int = 20, minimumCpuCores: Int = 1, requiredPorts: [Int] = [],
                conflictingPackages: [String] = [], requiredLibraries: [String] = []) {
        self.minimumMemoryMB = minimumMemoryMB; self.recommendedMemoryMB = recommendedMemoryMB
        self.minimumDiskGB = minimumDiskGB; self.recommendedDiskGB = recommendedDiskGB
        self.minimumCpuCores = minimumCpuCores; self.requiredPorts = requiredPorts
        self.conflictingPackages = conflictingPackages; self.requiredLibraries = requiredLibraries
    }
}


// Installation types, config recommendations, AI error resolution
// → DatabaseInstallationTypes+Extended.swift
