//
//  AIInstallationView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge
import Combine

public struct AIInstallationView: View {
    let databaseType: DatabaseType
    let serverId: String
    let onSuccess: (() -> Void)?
    
    @StateObject private var viewModel: AIInstallationViewModel
    @Environment(\.dismiss) var dismiss

    public init(databaseType: DatabaseType, serverId: String, onSuccess: (() -> Void)? = nil) {
        self.databaseType = databaseType
        self.serverId = serverId
        self.onSuccess = onSuccess
        _viewModel = StateObject(wrappedValue: AIInstallationViewModel(databaseType: databaseType, serverId: serverId))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            AIInstallHeader(databaseType: databaseType) {
                dismiss()
            }

            Divider()

            // Main Content
            contentView
        }
        .frame(width: 800, height: 600)
        .background(Color.axBackground)
        .onAppear {
            Task {
                await viewModel.analyzeServer()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            AIInstallLoadingView()
        } else if let error = viewModel.errorMessage {
            AIInstallErrorView(
                message: error,
                databaseType: databaseType,
                onRetry: { Task { await viewModel.analyzeServer() } }
            )
        } else if viewModel.isSuccess {
            AIInstallSuccessView(
                databaseType: databaseType,
                stepDescription: viewModel.currentStepDescription,
                logs: viewModel.logs,
                onDone: { 
                    onSuccess?()
                    dismiss() 
                }
            )
        } else if viewModel.isInstalling {
            AIInstallProgressView(
                databaseType: databaseType,
                progress: viewModel.installProgress,
                stepTitle: viewModel.currentStep,
                stepDescription: viewModel.currentStepDescription,
                logs: viewModel.logs,
                onCancel: { Task { await viewModel.cancelInstallation() } } // Task wrapper added
            )
        } else if let recommendation = viewModel.recommendation {
            AIInstallRecommendationsView(
                databaseType: databaseType,
                recommendation: recommendation,
                selectedVersion: viewModel.selectedVersion,
                isInstalling: viewModel.isInstalling,
                onSelectVersion: { viewModel.selectedVersion = $0 },
                onStartInstall: { Task { await viewModel.startInstallation() } },
                onCancel: { dismiss() }
            )
        } else {
            // Fallback empty state
            VStack {
                Text(L10n.Install.noRecommendationsAvailable)
                    .foregroundStyle(.secondary)
                Button(L10n.Button.retry) {
                    Task { await viewModel.analyzeServer() }
                }
            }
        }
    }
}

// MARK: - ViewModel

private class AIInstallationViewModel: ObservableObject {
    let databaseType: DatabaseType
    let serverId: String
    private let service = DatabaseInstallationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var recommendation: AIInstallationResponse?
    @Published var selectedVersion: DatabaseVersionRecommendation?
    
    @Published var isInstalling = false
    @Published var installProgress: Double = 0
    @Published var currentStep = ""
    @Published var currentStepDescription = ""
    @Published var logs: [InstallationLog] = []
    @Published var isSuccess = false
    
    init(databaseType: DatabaseType, serverId: String) {
        self.databaseType = databaseType
        self.serverId = serverId
        
        // Bind to service properties
        service.$isInstalling
            .receive(on: RunLoop.main)
            .assign(to: \.isInstalling, on: self)
            .store(in: &cancellables)
            
        service.$currentInstallation
            .receive(on: RunLoop.main)
            .sink { [weak self] installation in
                guard let self = self, let installation = installation else { return }
                self.installProgress = installation.progressPercentage / 100.0
                self.currentStep = installation.currentStepTitle
                self.currentStepDescription = installation.currentStepDescription
                self.logs = installation.logs
                self.isSuccess = installation.status == .completed
            }
            .store(in: &cancellables)
            
            service.$installationError
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorMessage = error.message
                    self?.isLoading = false
                    self?.isInstalling = false
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func analyzeServer() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await service.getInstallationRecommendations(
                databaseType: databaseType,
                serverId: serverId
            )
            self.recommendation = response
            self.selectedVersion = response.recommendations.first { $0.isRecommended } ?? response.recommendations.first
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    @MainActor
    func startInstallation() async {
        guard let version = selectedVersion else { return }
        guard let recommendation = recommendation else { return }
        
        isInstalling = true
        installProgress = 0
        logs = []
        isSuccess = false
        errorMessage = nil
        
        do {
            try await service.startInstallation(
                databaseType: databaseType,
                version: version.version,
                recommendation: recommendation,
                serverId: serverId
            )
        } catch {
            self.errorMessage = error.localizedDescription
            debugLog("Installation failed: \(error.localizedDescription)")
            // Error handled by service listener
        }
    }
    
    @MainActor
    func cancelInstallation() async {
        await service.cancelInstallation()
    }
}
