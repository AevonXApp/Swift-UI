//
//  ErrorResolutionService.swift
//  AevonX
//
//  Created by AevonX on 2026.
//

import Foundation
import SwiftUI
import Combine
import AevonXCore

// MARK: - Error Resolution Service

/// Service for managing error resolution flow
@MainActor
public final class ErrorResolutionService: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = ErrorResolutionService()
    
    // MARK: - Properties
    
    private let aiAPIService = AIInstallationAPIService.shared
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
            // Gather server info
            let osInfo = try await CoreDatabaseService.shared.getServerOSInfo(serverId: serverId)
            let resources = try await CoreDatabaseService.shared.getServerResources(serverId: serverId)
            let installed = await CoreDatabaseService.shared.detectInstalledDatabases(serverId: serverId)
            let installedTypes = installed.filter { $0.isInstalled }.map { $0.type }
            
            // Get server name (mock for now or fetch from repository)
            let serverName = "Server" // Ideally fetched from a ServerRepository
            
            let resolution = try await aiAPIService.analyzeError(
                databaseType: databaseType,
                stepTitle: stepTitle,
                stepOrder: stepOrder,
                command: command,
                errorOutput: errorOutput,
                exitCode: exitCode,
                serverOSInfo: osInfo,
                serverResources: resources,
                installedDatabases: installedTypes,
                serverId: serverId,
                serverName: serverName
            )
            
            currentResolution = resolution
            
        } catch {
            self.error = "Failed to analyze error: \(error.localizedDescription)"
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
        
        guard let resolution = currentResolution else {
            throw ErrorResolutionError.noActiveResolution
        }
        
        isExecutingSolution = true
        error = nil
        
        defer { isExecutingSolution = false }
        
        do {
            // 1. Notify backend about execution
            try await aiAPIService.executeSolution(
                errorId: resolution.errorId,
                solutionId: solution.id,
                serverId: serverId,
                stepOrder: stepOrder,
                command: solution.command ?? ""
            )
            
            // 2. Execute command if available
            if let command = solution.command, !command.isEmpty {
                let result = try await CoreDatabaseService.shared.executeInstallationCommand(
                    command,
                    serverId: serverId
                )
                
                guard result.exitCode == 0 else {
                    throw ErrorResolutionError.solutionFailed(result.stderr)
                }
            }
            
        } catch {
            self.error = "Failed to execute solution: \(error.localizedDescription)"
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
            return "No active error resolution context"
        case .solutionFailed(let reason):
            return "Solution execution failed: \(reason)"
        }
    }
}
