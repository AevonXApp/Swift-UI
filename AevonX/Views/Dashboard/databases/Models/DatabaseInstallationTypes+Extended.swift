//
//  DatabaseInstallationTypes+Extended.swift
//  AevonX
//
//  Installation steps, logs, progress, error types,
//  configuration recommendations, and AI error resolution types.
//

import Foundation
import AevonXCoreBridge

// MARK: - Installation Types

public struct InstallationStep: Identifiable {
    public let id = UUID()
    public var order: Int
    public var title: String
    public var description: String
    public var command: String?
    public var isManual: Bool
    public var estimatedDuration: TimeInterval
    public var canRollback: Bool
    public var rollbackCommand: String?
    public var validationCommand: String?

    public init(order: Int = 0, title: String = "", description: String = "", command: String? = nil,
                isManual: Bool = false, estimatedDuration: TimeInterval = 30, canRollback: Bool = false,
                rollbackCommand: String? = nil, validationCommand: String? = nil) {
        self.order = order; self.title = title; self.description = description
        self.command = command; self.isManual = isManual
        self.estimatedDuration = estimatedDuration; self.canRollback = canRollback
        self.rollbackCommand = rollbackCommand; self.validationCommand = validationCommand
    }
}

public struct InstallationLog: Identifiable, Codable, Sendable {
    public let id: UUID
    public var timestamp: Date
    public var level: InstallationLogLevel
    public var message: String
    public var step: Int?

    public init(id: UUID = UUID(), timestamp: Date = Date(), level: InstallationLogLevel = .info,
                message: String = "", step: Int? = nil) {
        self.id = id; self.timestamp = timestamp; self.level = level
        self.message = message; self.step = step
    }
}

public enum InstallationLogLevel: String, Codable {
    case debug, info, warning, error, success
}

public enum InstallationStatus: String, Codable {
    case pending, analyzing, downloading, installing
    case configuring, validating, completed, failed
    case cancelled, rollingBack
}

public struct InstallationProgress: Identifiable, Sendable {
    public var id: UUID { installationId }
    public var installationId: UUID
    public var databaseType: DatabaseType
    public var selectedVersion: String
    public var currentStep: Int
    public var totalSteps: Int
    public var status: InstallationStatus
    public var currentStepTitle: String
    public var currentStepDescription: String
    public var progressPercentage: Double
    public var logs: [InstallationLog]
    public var startedAt: Date
    public var estimatedCompletionAt: Date?
    public var completedAt: Date?
    public var error: InstallationError?

    public init(installationId: UUID = UUID(), databaseType: DatabaseType = .unknown,
                selectedVersion: String = "", currentStep: Int = 0, totalSteps: Int = 0,
                status: InstallationStatus = .pending, currentStepTitle: String = "",
                currentStepDescription: String = "", progressPercentage: Double = 0,
                logs: [InstallationLog] = [], startedAt: Date = Date(),
                estimatedCompletionAt: Date? = nil, completedAt: Date? = nil,
                error: InstallationError? = nil) {
        self.installationId = installationId; self.databaseType = databaseType
        self.selectedVersion = selectedVersion; self.currentStep = currentStep
        self.totalSteps = totalSteps; self.status = status
        self.currentStepTitle = currentStepTitle; self.currentStepDescription = currentStepDescription
        self.progressPercentage = progressPercentage; self.logs = logs
        self.startedAt = startedAt; self.estimatedCompletionAt = estimatedCompletionAt
        self.completedAt = completedAt; self.error = error
    }
}

public struct InstallationError: Codable, Identifiable, Sendable {
    public let id: UUID
    public var code: String
    public var message: String
    public var details: String?
    public var isRecoverable: Bool

    public init(id: UUID = UUID(), code: String = "", message: String = "", details: String? = nil,
                isRecoverable: Bool = false) {
        self.id = id; self.code = code; self.message = message
        self.details = details; self.isRecoverable = isRecoverable
    }
}

// MARK: - Configuration Recommendation

public struct ConfigurationRecommendation: Identifiable {
    public let id = UUID()
    public var category: ConfigCategory
    public var title: String
    public var description: String
    public var currentValue: String?
    public var recommendedValue: String
    public var reasoning: String
    public var isCritical: Bool
    public var configFile: String?
    public var configKey: String?

    public init(category: ConfigCategory = .performance, title: String = "", description: String = "",
                currentValue: String? = nil, recommendedValue: String = "", reasoning: String = "",
                isCritical: Bool = false, configFile: String? = nil, configKey: String? = nil) {
        self.category = category; self.title = title; self.description = description
        self.currentValue = currentValue; self.recommendedValue = recommendedValue
        self.reasoning = reasoning; self.isCritical = isCritical
        self.configFile = configFile; self.configKey = configKey
    }
}

public enum ConfigCategory: String, Codable, CaseIterable {
    case memory, performance, security, networking, logging, backup, replication
}

// MARK: - AI Error Resolution Types

public struct AIErrorResolution {
    public var errorMessage: String
    public var databaseType: DatabaseType
    public var solutions: [AIErrorSolution]
    public var diagnosticInfo: String

    /// Computed alias for views that reference 'analysis'
    public var analysis: String { diagnosticInfo }
    /// Computed alias for root cause extraction
    public var rootCause: String { errorMessage }

    public init(errorMessage: String = "", databaseType: DatabaseType = .unknown,
                solutions: [AIErrorSolution] = [], diagnosticInfo: String = "") {
        self.errorMessage = errorMessage; self.databaseType = databaseType
        self.solutions = solutions; self.diagnosticInfo = diagnosticInfo
    }
}

public struct AIErrorSolution: Identifiable {
    public let id = UUID()
    public var title: String
    public var description: String
    public var commands: [String]
    public var riskLevel: SolutionRiskLevel
    public var isRecommended: Bool

    /// Computed alias — returns first command or nil
    public var command: String? { commands.first }
    /// Computed alias for 'isAutomated'
    public var isAutomated: Bool { isRecommended }

    public init(title: String = "", description: String = "", commands: [String] = [],
                riskLevel: SolutionRiskLevel = .low, isRecommended: Bool = false) {
        self.title = title; self.description = description
        self.commands = commands; self.riskLevel = riskLevel
        self.isRecommended = isRecommended
    }
}

public enum SolutionRiskLevel: String, Codable {
    case low, medium, high, critical
    /// Alias for views that use 'safe'
    static var safe: SolutionRiskLevel { .low }
}

// MARK: - AI Installation API Service (Bridge-backed stub)

/// Local stub replacing AevonXCore's AIInstallationAPIService.
/// Uses SSHBridge for server queries. Can be enhanced with real AI in future.
public final class AIInstallationAPIService: @unchecked Sendable {
    public static let shared = AIInstallationAPIService()
    private let ssh = SSHBridge.shared
    private init() {}

    public func getInstallationRecommendations(
        databaseType: DatabaseType,
        serverId: String,
        serverOSInfo: ServerOSInfo = .init(),
        serverResources: ServerResources = .init(),
        existingDatabases: [DatabaseType] = [],
        useCase: DatabaseUseCase? = nil,
        preferredVersion: String? = nil
    ) async throws -> AIInstallationResponse {
        return AIInstallationResponse(databaseType: databaseType)
    }

    public func analyzeError(
        databaseType: DatabaseType,
        errorMessage: String,
        command: String,
        exitCode: Int?,
        serverId: String,
        serverName: String,
        osInfo: ServerOSInfo,
        resources: ServerResources,
        installedDatabases: [DatabaseType]
    ) async throws -> AIErrorResolution {
        return AIErrorResolution(errorMessage: errorMessage, databaseType: databaseType)
    }

    public func startInstallationTracking(
        databaseType: DatabaseType,
        version: String,
        steps: [InstallationStep]
    ) -> InstallationProgress {
        return InstallationProgress(databaseType: databaseType, selectedVersion: version,
                                    totalSteps: steps.count, status: .pending)
    }

    public func updateInstallationProgress(
        _ progress: inout InstallationProgress,
        step: Int,
        status: InstallationStatus,
        message: String
    ) {
        progress.currentStep = step
        progress.status = status
        progress.currentStepDescription = message
        progress.progressPercentage = Double(step) / max(Double(progress.totalSteps), 1.0) * 100
    }

    public func executeSolution(
        errorId: String,
        solution: AIErrorSolution,
        serverId: String
    ) async throws -> String {
        guard let command = solution.commands.first else { return "" }
        return await ssh.executeAsync(serverID: serverId, command: command)
    }
}

// MARK: - Database Resource Service (Bridge-backed)

/// Local replacement for AevonXCore's DatabaseResourceService.
/// Gathers server info via SSHBridge.
public actor DatabaseResourceService {
    public static let shared = DatabaseResourceService()
    private let ssh = SSHBridge.shared
    private init() {}

    public func getServerOSInfo(serverId: String) async throws -> ServerOSInfo {
        let output = await ssh.executeAsync(serverID: serverId,
            command: "cat /etc/os-release 2>/dev/null || echo 'ID=unknown'")
        return parseOSInfo(output)
    }

    public func getServerResources(serverId: String) async throws -> ServerResources {
        let memOutput = await ssh.executeAsync(serverID: serverId,
            command: "free -m 2>/dev/null | awk '/^Mem:/{print $2,$7}'")
        let diskOutput = await ssh.executeAsync(serverID: serverId,
            command: "df -BG / 2>/dev/null | awk 'NR==2{print $2,$4}'")
        let cpuOutput = await ssh.executeAsync(serverID: serverId,
            command: "nproc 2>/dev/null || echo 1")
        let archOutput = await ssh.executeAsync(serverID: serverId,
            command: "uname -m 2>/dev/null || echo unknown")

        let memParts = memOutput.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        let diskParts = diskOutput.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")

        return ServerResources(
            totalMemoryMB: Int(memParts.first ?? "0") ?? 0,
            availableMemoryMB: Int(memParts.last ?? "0") ?? 0,
            totalDiskGB: Int(diskParts.first?.replacingOccurrences(of: "G", with: "") ?? "0") ?? 0,
            availableDiskGB: Int(diskParts.last?.replacingOccurrences(of: "G", with: "") ?? "0") ?? 0,
            cpuCount: Int(cpuOutput.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1,
            cpuArchitecture: archOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func parseOSInfo(_ output: String) -> ServerOSInfo {
        var dict: [String: String] = [:]
        for line in output.components(separatedBy: .newlines) {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let val = String(parts[1]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
            dict[key] = val
        }
        return ServerOSInfo(
            id: dict["ID"] ?? "unknown",
            idLike: dict["ID_LIKE"] ?? "",
            versionId: dict["VERSION_ID"] ?? "",
            version: dict["VERSION"] ?? "",
            prettyName: dict["PRETTY_NAME"] ?? "",
            kernelVersion: "",
            architecture: ""
        )
    }
}
