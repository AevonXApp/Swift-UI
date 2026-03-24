//
//  DatabaseInstallationService.swift
//  AevonX
//
//  UI Layer service for managing database installations.
//  Uses AevonXCoreBridge ONLY — no AevonXCore dependency.
//  All SSH operations go through SSHBridge.
//

import Foundation
import SwiftUI
import AevonXCoreBridge
import Combine

// MARK: - Database Installation Service

/// Service for managing database installations in the UI layer.
/// Coordinates between AI recommendations and actual server installation.
/// All server operations go through SSHBridge (Go Core).
@MainActor
public final class DatabaseInstallationService: ObservableObject {

    // MARK: - Singleton

    public static let shared = DatabaseInstallationService()

    // MARK: - Properties

    private let aiAPIService = AIInstallationAPIService.shared
    private let ssh = SSHBridge.shared

    // MARK: - Published State

    @Published public var currentInstallation: InstallationProgress?
    @Published public var isInstalling = false
    @Published public var installationError: InstallationError?
    @Published public var lastRecommendation: AIInstallationResponse?
    @Published public var errorResolutionContext: ErrorResolutionContext?

    public struct ErrorResolutionContext {
        public let databaseType: DatabaseType
        public let serverId: String
        public let step: InstallationStep?
        public let log: InstallationLog?
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - AI Recommendations

    /// Gets AI-powered installation recommendations
    public func getInstallationRecommendations(
        databaseType: DatabaseType,
        serverId: String,
        useCase: DatabaseUseCase? = nil,
        preferredVersion: String? = nil
    ) async throws -> AIInstallationResponse {

        CoreLogger.shared.debug("[DBInstall] Starting getInstallationRecommendations for \(databaseType.displayName)")

        // Gather server information via Bridge
        let osInfo: ServerOSInfo
        do {
            osInfo = try await DatabaseResourceService.shared.getServerOSInfo(serverId: serverId)
            CoreLogger.shared.debug("[DBInstall] OS Info: \(osInfo.prettyName) (\(osInfo.id))")
        } catch {
            CoreLogger.shared.error("[DBInstall] Getting OS info: \(error.localizedDescription)")
            throw DatabaseInstallationError.stepFailed(step: "Get OS Info", reason: error.localizedDescription)
        }

        let resources: ServerResources
        do {
            resources = try await DatabaseResourceService.shared.getServerResources(serverId: serverId)
            CoreLogger.shared.debug("[DBInstall] Resources: \(resources.totalMemoryMB)MB RAM, \(resources.availableDiskGB)GB disk")
        } catch {
            CoreLogger.shared.error("[DBInstall] Getting resources: \(error.localizedDescription)")
            throw DatabaseInstallationError.stepFailed(step: "Get Resources", reason: error.localizedDescription)
        }

        // Detect existing installations via Bridge
        let existingInstallations = await DatabaseEngineService.shared.detectInstalledDatabases(serverId: serverId)
        let existingTypes = existingInstallations.filter { $0.isInstalled }.compactMap { _ in databaseType }
        CoreLogger.shared.debug("[DBInstall] Found \(existingTypes.count) installed database types")

        // Call AI API service for recommendations
        let response: AIInstallationResponse
        do {
            response = try await aiAPIService.getInstallationRecommendations(
                databaseType: databaseType,
                serverId: serverId,
                serverOSInfo: osInfo,
                serverResources: resources,
                existingDatabases: existingTypes,
                useCase: useCase,
                preferredVersion: preferredVersion
            )
            CoreLogger.shared.debug("[DBInstall] Received \(response.recommendations.count) recommendations from AI")
        } catch {
            CoreLogger.shared.error("[DBInstall] AI API: \(error.localizedDescription)")
            throw error
        }

        lastRecommendation = response
        return response
    }

    // MARK: - Installation Execution

    /// Starts a database installation
    public func startInstallation(
        databaseType: DatabaseType,
        version: String,
        recommendation: AIInstallationResponse,
        serverId: String
    ) async throws {
        guard !isInstalling else { return }

        isInstalling = true
        installationError = nil

        do {
            // Build dynamic steps from recommendation + base install
            var dynamicSteps: [InstallationStep] = recommendation.installationSteps

            // Add recommended version install step if not already present
            if dynamicSteps.isEmpty {
                let installCmd = DatabasesBridge.shared.installCmd(engine: databaseType.rawValue, version: version)
                dynamicSteps.append(InstallationStep(
                    order: 1,
                    title: "Install \(databaseType.displayName) \(version)",
                    description: "Installing database engine",
                    command: installCmd,
                    estimatedDuration: 120,
                    canRollback: true,
                    rollbackCommand: DatabasesBridge.shared.uninstallCmd(engine: databaseType.rawValue)
                ))
            }

            // Add post-install config steps
            var orderId = dynamicSteps.count + 1
            for configRec in recommendation.postInstallationConfig {
                guard let cmd = configRec.configKey else { continue }
                dynamicSteps.append(InstallationStep(
                    order: orderId,
                    title: "Post-install: Configuration",
                    description: "Configuring database service",
                    command: cmd,
                    estimatedDuration: 10
                ))
                orderId += 1
            }

            // Start tracking
            let installationId = UUID().uuidString

            // Initialize progress tracking
            let progress = InstallationProgress(
                installationId: UUID(uuidString: installationId) ?? UUID(),
                databaseType: databaseType,
                selectedVersion: version,
                totalSteps: dynamicSteps.count,
                status: .analyzing,
                currentStepTitle: "Preparing installation",
                currentStepDescription: "Analyzing server environment..."
            )

            currentInstallation = progress

            // Execute installation steps via SSHBridge
            try await executeInstallationSteps(
                steps: dynamicSteps,
                recommendation: recommendation,
                serverId: serverId,
                installationId: installationId
            )

            // Mark as completed
            currentInstallation?.status = .completed
            currentInstallation?.progressPercentage = 100
            currentInstallation?.currentStepTitle = "Installation Complete"
            currentInstallation?.currentStepDescription = "\(databaseType.displayName) has been installed successfully."
            currentInstallation?.completedAt = Date()

            currentInstallation?.logs.append(InstallationLog(
                level: .success,
                message: "Successfully installed \(databaseType.displayName) \(version)"
            ))

            isInstalling = false
            CoreLogger.shared.debug("[DBInstall] Installation completed successfully for \(databaseType.displayName)")

        } catch {
            isInstalling = false
            installationError = InstallationError(
                code: "INSTALLATION_FAILED",
                message: error.localizedDescription,
                isRecoverable: true
            )
            CoreLogger.shared.error("[DBInstall] Installation failed: \(error.localizedDescription)")

            // Trigger Error Resolution Service
            if let stepError = error as? DatabaseInstallationError {
                if case .stepFailed(_, let reason) = stepError {
                    let errorLog = InstallationLog(
                        level: .error,
                        message: reason,
                        step: currentInstallation?.currentStep
                    )
                    self.errorResolutionContext = ErrorResolutionContext(
                        databaseType: databaseType,
                        serverId: serverId,
                        step: nil,
                        log: errorLog
                    )
                }
            }

            throw error
        }
    }

    /// Cancels the current installation
    public func cancelInstallation() async {
        guard currentInstallation != nil else { return }

        currentInstallation?.status = .cancelled
        isInstalling = false

        CoreLogger.shared.debug("[DBInstall] Installation cancelled by user")
    }

    // MARK: - Private Helpers

    private func executeInstallationSteps(
        steps: [InstallationStep],
        recommendation: AIInstallationResponse,
        serverId: String,
        installationId: String
    ) async throws {

        for (index, step) in steps.enumerated() {
            // Check if cancelled
            guard currentInstallation?.status != .cancelled else {
                throw DatabaseInstallationError.cancelled
            }

            // Update progress
            let progressPercentage = Double(index) / Double(steps.count) * 100

            currentInstallation?.currentStep = index + 1
            currentInstallation?.status = .installing
            currentInstallation?.currentStepTitle = step.title
            currentInstallation?.currentStepDescription = step.description
            currentInstallation?.progressPercentage = progressPercentage

            // Execute step command via SSHBridge
            if let command = step.command {
                CoreLogger.shared.debug("[DBInstall] Executing step \(index + 1): \(step.title)")

                currentInstallation?.logs.append(InstallationLog(
                    level: .info,
                    message: "Executing: \(command)",
                    step: index + 1
                ))

                let result = await ssh.executeAsync(serverID: serverId, command: command)

                // Log output
                if !result.isEmpty {
                    currentInstallation?.logs.append(InstallationLog(
                        level: .debug,
                        message: result,
                        step: index + 1
                    ))
                }

                // Check for errors in output
                let lowerResult = result.lowercased()
                if lowerResult.contains("error") && !lowerResult.contains("already") && !lowerResult.contains("warning") {
                    currentInstallation?.logs.append(InstallationLog(
                        level: .error,
                        message: "Step may have failed: \(result)",
                        step: index + 1
                    ))
                    throw DatabaseInstallationError.stepFailed(
                        step: step.title,
                        reason: result
                    )
                }

                currentInstallation?.logs.append(InstallationLog(
                    level: .success,
                    message: "Step completed successfully",
                    step: index + 1
                ))
            }

            // Validate step if validation command exists
            if let validationCommand = step.validationCommand {
                CoreLogger.shared.debug("[DBInstall] Validating step \(index + 1)")

                let validationResult = await ssh.executeAsync(serverID: serverId, command: validationCommand)

                if validationResult.lowercased().contains("error") || validationResult.lowercased().contains("failed") {
                    throw DatabaseInstallationError.validationFailed(
                        step: step.title,
                        reason: validationResult.isEmpty ? "Validation failed" : validationResult
                    )
                }
            }

            // Small delay to show progress in UI
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }
}

// MARK: - Database Installation Error

public enum DatabaseInstallationError: LocalizedError {
    case stepFailed(step: String, reason: String)
    case validationFailed(step: String, reason: String)
    case cancelled
    case missingRecommendation

    public var errorDescription: String? {
        switch self {
        case .stepFailed(let step, let reason):
            return "Step '\(step)' failed: \(reason)"
        case .validationFailed(let step, let reason):
            return "Validation for '\(step)' failed: \(reason)"
        case .cancelled:
            return "Installation was cancelled"
        case .missingRecommendation:
            return "No installation recommendation available"
        }
    }
}
