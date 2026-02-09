//
//  DatabaseInstallationService.swift
//  AevonX
//
//  UI Layer service for managing database installations
//  Coordinates between UI, Core (AIInstallationAPIService), and server commands
//
//  ARCHITECTURE: UI Layer Service
//  - Uses CoreDatabaseService from Core layer for all server operations
//  - Uses AIInstallationAPIService from Core layer for AI recommendations
//  - NEVER executes SSH commands directly
//

import Foundation
import SwiftUI
import AevonXCore
import Combine

// MARK: - Database Installation Service

/// Service for managing database installations in the UI layer
/// Coordinates between AI recommendations and actual server installation
///
/// IMPORTANT: This service does NOT execute SSH commands directly.
/// All server operations go through CoreDatabaseService in the Core layer.
@MainActor
public final class DatabaseInstallationService: ObservableObject {

    // MARK: - Singleton

    public static let shared = DatabaseInstallationService()

    // MARK: - Properties (Core Layer Services)

    private let aiAPIService = AIInstallationAPIService.shared
    // NOTE: All SSH operations go through CoreDatabaseService

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
    /// - Parameters:
    ///   - databaseType: Type of database to install
    ///   - serverId: Server identifier
    ///   - useCase: Intended use case
    ///   - preferredVersion: Optional preferred version
    /// - Returns: AI installation response with recommendations
    public func getInstallationRecommendations(
        databaseType: DatabaseType,
        serverId: String,
        useCase: DatabaseUseCase? = nil,
        preferredVersion: String? = nil
    ) async throws -> AIInstallationResponse {

        CoreLogger.shared.info("Starting getInstallationRecommendations for \(databaseType.displayName)",
                              module: "DatabaseInstallationService")

        // Gather server information via Core layer
        let osInfo: ServerOSInfo
        do {
            osInfo = try await CoreDatabaseService.shared.getServerOSInfo(serverId: serverId)
            CoreLogger.shared.debug("OS Info: \(osInfo.prettyName) (\(osInfo.id))",
                                   module: "DatabaseInstallationService")
        } catch {
            CoreLogger.shared.error("ERROR getting OS info: \(error.localizedDescription)",
                                   module: "DatabaseInstallationService")
            throw DatabaseInstallationError.stepFailed(step: "Get OS Info", reason: error.localizedDescription)
        }

        let resources: ServerResources
        do {
            resources = try await CoreDatabaseService.shared.getServerResources(serverId: serverId)
            CoreLogger.shared.debug("Resources: \(resources.totalMemoryMB)MB RAM, \(resources.availableDiskGB)GB disk",
                                   module: "DatabaseInstallationService")
        } catch {
            CoreLogger.shared.error("ERROR getting resources: \(error.localizedDescription)",
                                   module: "DatabaseInstallationService")
            throw DatabaseInstallationError.stepFailed(step: "Get Resources", reason: error.localizedDescription)
        }

        // Detect existing installations via Core layer
        let existingInstallations = await CoreDatabaseService.shared.detectInstalledDatabases(serverId: serverId)
        let existingTypes = existingInstallations.filter { $0.isInstalled }.map { $0.type }
        CoreLogger.shared.debug("Found \(existingTypes.count) installed database types",
                               module: "DatabaseInstallationService")

        // Call Core layer API service for AI recommendations
        let response: AIInstallationResponse
        do {
            response = try await aiAPIService.getInstallationRecommendations(
                databaseType: databaseType,
                serverOSInfo: osInfo,
                serverResources: resources,
                existingDatabases: existingTypes,
                useCase: useCase,
                preferredVersion: preferredVersion
            )
            CoreLogger.shared.info("Received \(response.recommendations.count) recommendations from AI",
                                  module: "DatabaseInstallationService")
        } catch {
            CoreLogger.shared.error("ERROR from AI API: \(error.localizedDescription)",
                                   module: "DatabaseInstallationService")
            throw error
        }

        lastRecommendation = response
        return response
    }

    // MARK: - Installation Execution

    /// Starts a database installation
    /// - Parameters:
    ///   - databaseType: Type of database to install
    ///   - version: Selected version to install
    ///   - serverId: Server identifier
    ///   - recommendation: AI recommendation containing installation steps
    public func startInstallation(
        databaseType: DatabaseType,
        version: String,
        serverId: String,
        recommendation: AIInstallationResponse
    ) async throws {

        guard !isInstalling else {
            throw DatabaseInstallationError.alreadyInProgress
        }

        // Find the selected version recommendation to get specific commands
        guard let selectedVersion = recommendation.recommendations.first(where: { $0.version == version }) else {
             throw DatabaseInstallationError.stepFailed(step: "Initialization", reason: "Selected version not found in recommendations")
        }
        
        // Get the install commands (Backend filters for the correct package manager, so taking first is safe)
        guard let cmdSet = selectedVersion.installCommands.first else {
            throw DatabaseInstallationError.stepFailed(step: "Initialization", reason: "No installation commands available for this version")
        }

        isInstalling = true
        installationError = nil

        do {
            // Generate steps dynamically from the commands
            var dynamicSteps: [InstallationStep] = []
            var orderId = 1
            
            // Pre-install steps
            for cmd in cmdSet.preInstallCommands {
                dynamicSteps.append(InstallationStep(
                    order: orderId,
                    title: "Pre-install: Prepare Environment",
                    description: "Executing pre-installation task",
                    command: cmd,
                    isManual: false,
                    estimatedDuration: 10,
                    canRollback: false,
                    rollbackCommand: nil,
                    validationCommand: nil
                ))
                orderId += 1
            }
            
            // Install commands
            for cmd in cmdSet.commands {
                dynamicSteps.append(InstallationStep(
                    order: orderId,
                    title: "Install \(databaseType.displayName) \(version)",
                    description: "Installing database package",
                    command: cmd,
                    isManual: false,
                    estimatedDuration: 120,
                    canRollback: true,
                    rollbackCommand: nil, // We don't have this info from simplified AI
                    validationCommand: nil
                ))
                orderId += 1
            }
            
            // Post-install steps
            for cmd in cmdSet.postInstallCommands {
                dynamicSteps.append(InstallationStep(
                    order: orderId,
                    title: "Post-install: Configuration",
                    description: "Configuring database service",
                    command: cmd,
                    isManual: false,
                    estimatedDuration: 10,
                    canRollback: false,
                    rollbackCommand: nil,
                    validationCommand: nil
                ))
                orderId += 1
            }
            
            // Start tracking with backend
            let installationId: String
            do {
                installationId = try await aiAPIService.startInstallationTracking(
                    serverId: serverId,
                    databaseType: databaseType,
                    selectedVersion: version,
                    totalSteps: dynamicSteps.count
                )
            } catch {
                CoreLogger.shared.error("Failed to start installation tracking: \(error.localizedDescription)",
                                       module: "DatabaseInstallationService")
                // Generate a local ID if backend tracking fails
                installationId = UUID().uuidString
            }

            // Initialize progress tracking
            let progress = InstallationProgress(
                installationId: UUID(uuidString: installationId) ?? UUID(),
                databaseType: databaseType,
                selectedVersion: version,
                totalSteps: dynamicSteps.count,
                status: .analyzing,
                currentStepTitle: "Preparing installation",
                currentStepDescription: "Analyzing server environment...",
                progressPercentage: 0
            )

            currentInstallation = progress

            // Execute installation steps via Core layer
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
            
            // Add final success log
            let finalLog = InstallationLog(
                level: .success,
                message: "Successfully installed \(databaseType.displayName) \(version)"
            )
            currentInstallation?.logs.append(finalLog)
            
            isInstalling = false

            CoreLogger.shared.info("Installation completed successfully for \(databaseType.displayName)",
                                  module: "DatabaseInstallationService")
        } catch {
            isInstalling = false
            installationError = InstallationError(
                code: "INSTALLATION_FAILED",
                message: error.localizedDescription,
                isRecoverable: true
            )
            CoreLogger.shared.error("Installation failed: \(error.localizedDescription)",
                                   module: "DatabaseInstallationService")
            
            // Trigger Error Resolution Service
            if let stepError = error as? DatabaseInstallationError {
                if case .stepFailed(let stepName, let reason) = stepError {
                    // Create a log entry for context
                    let errorLog = InstallationLog(
                        level: .error,
                        message: reason,
                        step: currentInstallation?.currentStep
                    )
                    
                    // Set context for UI to pick up
                    self.errorResolutionContext = ErrorResolutionContext(
                        databaseType: databaseType,
                        serverId: serverId,
                        step: nil, // We don't have the failed step object easily matching generic steps
                        log: errorLog
                    )
                }
            }
            
            throw error
        }
    }

    /// Cancels the current installation
    public func cancelInstallation() async {
        guard let installation = currentInstallation else { return }

        currentInstallation?.status = .cancelled
        isInstalling = false

        // Notify backend (best effort)
        try? await aiAPIService.updateInstallationProgress(
            installationId: installation.installationId.uuidString,
            currentStep: installation.currentStep,
            status: .cancelled,
            stepTitle: "Installation cancelled",
            stepDescription: "User cancelled the installation",
            progressPercentage: installation.progressPercentage
        )

        CoreLogger.shared.info("Installation cancelled by user",
                              module: "DatabaseInstallationService")
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

            // Report progress to backend (best effort)
            try? await aiAPIService.updateInstallationProgress(
                installationId: installationId,
                currentStep: index + 1,
                status: .installing,
                stepTitle: step.title,
                stepDescription: step.description,
                progressPercentage: progressPercentage,
                logs: currentInstallation?.logs ?? []
            )

            // Execute step command via Core layer
            if let command = step.command {
                CoreLogger.shared.debug("Executing step \(index + 1): \(step.title)",
                                       module: "DatabaseInstallationService")

                // Add log for command start
                currentInstallation?.logs.append(InstallationLog(
                    level: .info,
                    message: "Executing: \(command)",
                    step: index + 1
                ))

                let result = try await CoreDatabaseService.shared.executeInstallationCommand(
                    command,
                    serverId: serverId
                )

                // Add output logs
                if !result.stdout.isEmpty {
                    currentInstallation?.logs.append(InstallationLog(
                        level: .debug,
                        message: result.stdout,
                        step: index + 1
                    ))
                }
                
                if !result.stderr.isEmpty {
                    currentInstallation?.logs.append(InstallationLog(
                        level: .warning,
                        message: result.stderr,
                        step: index + 1
                    ))
                }

                guard result.exitCode == 0 else {
                    let errorMessage = result.stderr.isEmpty ? "Command failed with exit code \(result.exitCode)" : result.stderr
                    currentInstallation?.logs.append(InstallationLog(
                        level: .error,
                        message: "Step failed: \(errorMessage)",
                        step: index + 1
                    ))
                    throw DatabaseInstallationError.stepFailed(
                        step: step.title,
                        reason: errorMessage
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
                CoreLogger.shared.debug("Validating step \(index + 1)",
                                       module: "DatabaseInstallationService")

                let validationResult = try await CoreDatabaseService.shared.executeInstallationCommand(
                    validationCommand,
                    serverId: serverId
                )

                guard validationResult.exitCode == 0 else {
                    let errorMessage = validationResult.stderr.isEmpty ? "Validation failed" : validationResult.stderr
                    throw DatabaseInstallationError.validationFailed(
                        step: step.title,
                        reason: errorMessage
                    )
                }
            }

            // Small delay to show progress in UI
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
    }
}

// MARK: - Database Installation Error

public enum DatabaseInstallationError: LocalizedError {
    case alreadyInProgress
    case cancelled
    case stepFailed(step: String, reason: String)
    case validationFailed(step: String, reason: String)
    case unsupportedOS(String)
    case insufficientResources(requirements: SystemRequirements, available: ServerResources)
    case connectionFailed

    public var errorDescription: String? {
        switch self {
        case .alreadyInProgress:
            return "An installation is already in progress"
        case .cancelled:
            return "Installation was cancelled"
        case .stepFailed(let step, let reason):
            return "Step '\(step)' failed: \(reason)"
        case .validationFailed(let step, let reason):
            return "Validation failed for '\(step)': \(reason)"
        case .unsupportedOS(let os):
            return "Operating system '\(os)' is not supported"
        case .insufficientResources:
            return "Server does not meet minimum requirements for installation"
        case .connectionFailed:
            return "Not connected to server"
        }
    }
}
