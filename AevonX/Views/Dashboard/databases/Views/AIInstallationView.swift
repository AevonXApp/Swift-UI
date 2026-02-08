//
//  AIInstallationView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore
import Combine

public struct AIInstallationView: View {
    let databaseType: DatabaseType
    @StateObject private var viewModel: AIInstallationViewModel
    @Environment(\.dismiss) var dismiss

    public init(databaseType: DatabaseType) {
        self.databaseType = databaseType
        _viewModel = StateObject(wrappedValue: AIInstallationViewModel(databaseType: databaseType))
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
                onDone: { dismiss() }
            )
        } else if viewModel.isInstalling {
            AIInstallProgressView(
                databaseType: databaseType,
                progress: viewModel.installProgress,
                stepTitle: viewModel.currentStep,
                stepDescription: viewModel.currentStepDescription,
                logs: viewModel.logs,
                onCancel: { viewModel.cancelInstallation() }
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
                Text("No recommendations available.")
                    .foregroundStyle(.secondary)
                Button("Retry") {
                    Task { await viewModel.analyzeServer() }
                }
            }
        }
    }
}

// MARK: - ViewModel

private class AIInstallationViewModel: ObservableObject {
    let databaseType: DatabaseType
    
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
    
    private var installTask: Task<Void, Never>?
    
    init(databaseType: DatabaseType) {
        self.databaseType = databaseType
    }
    
    @MainActor
    func analyzeServer() async {
        isLoading = true
        errorMessage = nil
        
        // Simulate AI Analysis
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Mock Response
        // Mock Response
        let response = AIInstallationResponse(
            databaseType: databaseType,
            recommendations: [
                DatabaseVersionRecommendation(
                    version: "16.1",
                    isRecommended: true,
                    isLTS: true,
                    compatibilityScore: 98,
                    reasoning: "Latest stable release with best performance for your hardware.",
                    securityStatus: .secure
                ),
                DatabaseVersionRecommendation(
                    version: "15.5",
                    isRecommended: false,
                    isLTS: true,
                    compatibilityScore: 90,
                    reasoning: "Proven stability, good for legacy compatibility.",
                    securityStatus: .secure
                ),
                DatabaseVersionRecommendation(
                    version: "14.10",
                    isRecommended: false,
                    isLTS: true,
                    compatibilityScore: 75,
                    reasoning: "Older stable version.",
                    securityStatus: .updatesAvailable
                )
            ],
            systemRequirements: SystemRequirements(
                minimumMemoryMB: 512,
                recommendedMemoryMB: 1024,
                minimumDiskGB: 10,
                recommendedDiskGB: 20,
                minimumCpuCores: 1
            ),
            installationSteps: [
                InstallationStep(order: 1, title: "Downloading Binaries", description: "Fetching packages from official repositories...", estimatedDuration: 10),
                InstallationStep(order: 2, title: "Verifying Checksums", description: "Ensuring package integrity...", estimatedDuration: 5),
                InstallationStep(order: 3, title: "Unpacking", description: "Extracting files to /usr/local/opt...", estimatedDuration: 15),
                InstallationStep(order: 4, title: "Configuring Environment", description: "Setting up environment variables and paths...", estimatedDuration: 10),
                InstallationStep(order: 5, title: "Optimizing Configuration", description: "Applying AI-recommended settings for 8GB RAM...", estimatedDuration: 5),
                InstallationStep(order: 6, title: "Initializing Database", description: "Creating default database cluster...", estimatedDuration: 20),
                InstallationStep(order: 7, title: "Starting Service", description: "Launching background service...", estimatedDuration: 5),
                InstallationStep(order: 8, title: "Finalizing", description: "Running health checks...", estimatedDuration: 10)
            ],
            warnings: [
                "Firewall port 5432 is currently closed. The installer will attempt to open it."
            ]
        )
        
        self.recommendation = response
        self.selectedVersion = response.recommendations.first
        self.isLoading = false
    }
    
    @MainActor
    func startInstallation() async {
        guard let version = selectedVersion else { return }
        
        isInstalling = true
        installProgress = 0
        logs = []
        isSuccess = false
        
        addLog("Starting installation of \(databaseType.displayName) \(version.version)...", level: .info)
        
        // Simulate Installation Steps
        let steps = [
            ("Downloading Binaries", "Fetching packages from official repositories...", 0.1),
            ("Verifying Checksums", "Ensuring package integrity...", 0.2),
            ("Unpacking", "Extracting files to /usr/local/opt...", 0.3),
            ("Configuring Environment", "Setting up environment variables and paths...", 0.5),
            ("Optimizing Configuration", "Applying AI-recommended settings for 8GB RAM...", 0.7),
            ("Initializing Database", "Creating default database cluster...", 0.8),
            ("Starting Service", "Launching background service...", 0.9),
            ("Finalizing", "Running health checks...", 1.0)
        ]
        
        installTask = Task {
            for (title, desc, progress) in steps {
                if Task.isCancelled { return }
                
                self.currentStep = title
                self.currentStepDescription = desc
                addLog("\(title)...", level: .info)
                
                // Simulate work
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                withAnimation {
                    self.installProgress = progress
                }
                
                if Double.random(in: 0...1) > 0.8 {
                    addLog("Optimizing parameter for generic workload...", level: .debug)
                }
            }
            
            if !Task.isCancelled {
                addLog("Installation completed successfully!", level: .success)
                self.isSuccess = true
                self.installProgress = 1.0
                self.currentStep = "Complete"
                self.currentStepDescription = "Installation finished successfully."
            }
        }
    }
    
    func cancelInstallation() {
        installTask?.cancel()
        installTask = nil
        isInstalling = false
        addLog("Installation cancelled by user.", level: .warning)
    }
    
    private func addLog(_ message: String, level: InstallationLogLevel) {
        let log = InstallationLog(timestamp: Date(), level: level, message: message)
        logs.append(log)
    }
}
