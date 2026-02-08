//
//  ErrorResolutionViewModel.swift
//  AevonX
//
//  Created by AevonX on 2026.
//

import Foundation
import Combine
import AevonXCore

@MainActor
public class ErrorResolutionViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published public var state: ErrorResolutionState = .idle
    @Published public var analysis: AIErrorResolution?
    @Published public var errorMessage: String?
    
    private let service = ErrorResolutionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Context
    let databaseType: DatabaseType
    let serverId: String
    let erroredStep: InstallationStep? // Or equivalent info
    let errorLog: InstallationLog?
    
    // MARK: - Initialization
    
    public init(
        databaseType: DatabaseType,
        serverId: String,
        erroredStep: InstallationStep?,
        errorLog: InstallationLog?
    ) {
        self.databaseType = databaseType
        self.serverId = serverId
        self.erroredStep = erroredStep
        self.errorLog = errorLog
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        service.$currentResolution
            .assign(to: \.analysis, on: self)
            .store(in: &cancellables)
            
        service.$error
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
            
        service.$isAnalyzing
            .map { $0 ? .analyzing : .idle } // Simplified mapping, needs refinement based on flow
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    public func startAnalysis() async {
        guard let step = erroredStep, let log = errorLog else {
            errorMessage = "Missing error context"
            return
        }
        
        state = .analyzing
        
        do {
            try await service.analyzeError(
                databaseType: databaseType,
                stepTitle: step.title,
                stepOrder: step.order,
                command: step.command ?? "",
                errorOutput: log.message,
                exitCode: nil, // We might need to capture this in InstallationLog
                serverId: serverId
            )
            state = .solutionsReady
        } catch {
            state = .failed
            errorMessage = error.localizedDescription
        }
    }
    
    public func executeSolution(_ solution: AIErrorSolution) async {
        state = .executing
        
        do {
            try await service.executeSolution(
                solution: solution,
                stepOrder: erroredStep?.order ?? 0,
                serverId: serverId
            )
            state = .resolved
        } catch {
            state = .failed
            errorMessage = error.localizedDescription
        }
    }
    
    public func retryOriginalStep() {
        // This would communicate back to DatabaseInstallationService to retry
        // Implementation depends on how we integrate this View
    }
}

public enum ErrorResolutionState {
    case idle
    case analyzing
    case solutionsReady
    case executing
    case resolved
    case failed
}
