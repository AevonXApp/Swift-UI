//
//  ErrorResolutionService.swift
//  AevonX
//
//  Service for managing error resolution flow.
//  Uses AevonXCoreBridge ONLY — no AevonXCore dependency.
//

import Foundation
import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - Error Resolution Service

/// Service for managing error resolution flow
@MainActor
public final class ErrorResolutionService: ObservableObject {

    // MARK: - Singleton

    public static let shared = ErrorResolutionService()

    // MARK: - Properties

    private let aiAPIService = AIInstallationAPIService.shared
    private let ssh = SSHBridge.shared
    private var cancellables = Set<AnyCancellable>()

    @Published public var currentResolution: AIErrorResolution?
    @Published public var isAnalyzing = false
    @Published public var isExecutingSolution = false
    @Published public var error: String?

    // MARK: - Initialization

    private init() {}

    // MARK: - Analysis

    /// Analyzes an error and gets solutions from AI
    public func analyzeError(
        databaseType: DatabaseType,
        stepTitle: String,
        stepOrder: Int,
        command: String,
        errorOutput: String,
        exitCode: Int?,
        serverId: String
    ) async throws {

        isAnalyzing = true
        error = nil
        currentResolution = nil

        defer { isAnalyzing = false }

        do {
            // Gather server info via Bridge
            let osInfo = try await DatabaseResourceService.shared.getServerOSInfo(serverId: serverId)
            let resources = try await DatabaseResourceService.shared.getServerResources(serverId: serverId)
            let installed = await DatabaseEngineService.shared.detectInstalledDatabases(serverId: serverId)
            let engineOrder: [DatabaseType] = [.mysql, .mariadb, .postgresql, .redis, .mongodb, .cassandra, .cockroachdb, .elasticsearch]
            let installedTypes: [DatabaseType] = zip(engineOrder, installed)
                .filter { $0.1.isInstalled }
                .map { $0.0 }

            let serverName = "Server"

            let resolution = try await aiAPIService.analyzeError(
                databaseType: databaseType,
                errorMessage: errorOutput,
                command: command,
                exitCode: exitCode,
                serverId: serverId,
                serverName: serverName,
                osInfo: osInfo,
                resources: resources,
                installedDatabases: installedTypes
            )

            currentResolution = resolution

        } catch {
            self.error = L10n.ErrorResolution.analyzeFailed
            throw error
        }
    }

    // MARK: - Solution Execution

    /// Executes a selected solution
    public func executeSolution(
        solution: AIErrorSolution,
        stepOrder: Int,
        serverId: String
    ) async throws {

        guard currentResolution != nil else {
            throw ErrorResolutionError.noActiveResolution
        }

        isExecutingSolution = true
        error = nil

        defer { isExecutingSolution = false }

        do {
            // Execute commands via SSHBridge
            for command in solution.commands {
                guard !command.isEmpty else { continue }
                let result = await ssh.executeAsync(serverID: serverId, command: command)

                if result.lowercased().contains("error") && !result.lowercased().contains("already") {
                    throw ErrorResolutionError.solutionFailed(result)
                }
            }
        } catch {
            self.error = L10n.ErrorResolution.executeFailed
            throw error
        }
    }

    public func clear() {
        currentResolution = nil
        error = nil
        isAnalyzing = false
        isExecutingSolution = false
    }
}

public enum ErrorResolutionError: LocalizedError {
    case noActiveResolution
    case solutionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noActiveResolution:
            return L10n.ErrorResolution.noContext
        case .solutionFailed(let reason):
            return "\(L10n.ErrorResolution.solutionFailed): \(reason)"
        }
    }
}
