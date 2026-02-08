//
//  AIInstallationView.swift
//  AevonX
//
//  View for AI-assisted database installation
//  Shows recommendations and handles installation process
//

import SwiftUI
import Combine
import AevonXCore

// MARK: - AI Installation View

/// View for AI-assisted database installation
public struct AIInstallationView: View {
    let databaseType: DatabaseType
    let serverId: String
    
    @StateObject private var viewModel = AIInstallationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init(databaseType: DatabaseType, serverId: String) {
        self.databaseType = databaseType
        self.serverId = serverId
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
                .background(Color.axBorder)
            
            // Content
            contentView
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.axBackground)
        .onAppear {
            guard viewModel.recommendation == nil && !viewModel.isLoading else { return }
            Task {
                await viewModel.loadRecommendations(
                    databaseType: databaseType,
                    serverId: serverId
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Install \(databaseType.displayName)")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                
                Text("AI-assisted installation with optimal configuration")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.xl)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if let recommendation = viewModel.recommendation {
            if viewModel.installationCompleted {
                successView
            } else if viewModel.isInstalling {
                installationProgressView
            } else {
                recommendationsView(recommendation)
            }
        } else {
            emptyView
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing your server...")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
            
            Text("Our AI is determining the best database version and configuration for your system")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.axError)
            
            Text("Analysis Failed")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            Text(message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            Button("Try Again") {
                Task {
                    await viewModel.loadRecommendations(
                        databaseType: databaseType,
                        serverId: serverId
                    )
                }
            }
            .font(AXTypography.subheadline)
            .foregroundColor(databaseType.brandColor)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(databaseType.brandColor.opacity(0.1))
            .cornerRadius(AXCornerRadius.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)
            
            Text("No Recommendations")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Recommendations View
    
    private func recommendationsView(_ recommendation: AIInstallationResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // System Requirements
                systemRequirementsSection(recommendation.systemRequirements)
                
                // Version Recommendations
                versionRecommendationsSection(recommendation.recommendations)
                
                // Warnings
                if !recommendation.warnings.isEmpty {
                    warningsSection(recommendation.warnings)
                }
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(AXSpacing.xl)
        }
    }
    
    // MARK: - System Requirements Section
    
    private func systemRequirementsSection(_ requirements: SystemRequirements) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("System Requirements")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            HStack(spacing: AXSpacing.lg) {
                RequirementItem(
                    icon: "memorychip",
                    title: "Memory",
                    value: "\(requirements.minimumMemoryMB) MB min",
                    recommended: "\(requirements.recommendedMemoryMB) MB"
                )
                
                RequirementItem(
                    icon: "internaldrive",
                    title: "Disk",
                    value: "\(requirements.minimumDiskGB) GB min",
                    recommended: "\(requirements.recommendedDiskGB) GB"
                )
                
                RequirementItem(
                    icon: "cpu",
                    title: "CPU",
                    value: "\(requirements.minimumCpuCores) core min",
                    recommended: "\(requirements.minimumCpuCores * 2)+ cores"
                )
            }
        }
    }
    
    // MARK: - Version Recommendations Section
    
    private func versionRecommendationsSection(_ recommendations: [DatabaseVersionRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Recommended Versions")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            VStack(spacing: AXSpacing.md) {
                ForEach(recommendations) { rec in
                    VersionRecommendationCard(
                        recommendation: rec,
                        isSelected: viewModel.selectedVersion?.version == rec.version,
                        accentColor: databaseType.brandColor,
                        onSelect: {
                            viewModel.selectedVersion = rec
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Warnings Section
    
    private func warningsSection(_ warnings: [String]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Warnings")
                .font(AXTypography.headline)
                .foregroundColor(.axWarning)
            
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                ForEach(warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: AXSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.axWarning)
                        
                        Text(warning)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }
            .padding(AXSpacing.md)
            .background(Color.axWarning.opacity(0.1))
            .cornerRadius(AXCornerRadius.md)
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: AXSpacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.axSuccess)
            
            VStack(spacing: AXSpacing.md) {
                Text("Installation Successful!")
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                
                Text(viewModel.currentStepDescription)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            logOutputView
            
            Button("Done") {
                dismiss()
            }
            .font(AXTypography.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.axBackground)
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.vertical, AXSpacing.md)
            .background(databaseType.brandColor)
            .cornerRadius(AXCornerRadius.md)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        HStack(spacing: AXSpacing.md) {
            Button("Cancel") {
                dismiss()
            }
            .font(AXTypography.subheadline)
            .foregroundColor(.axTextSecondary)
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.startInstallation(serverId: serverId)
                }
            }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "arrow.down.circle")
                    Text("Install \(viewModel.selectedVersion?.version ?? "")")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(viewModel.selectedVersion != nil ? databaseType.brandColor : Color.axTextMuted)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.selectedVersion == nil || viewModel.isInstalling)
        }
    }
    
    // MARK: - Installation Progress View
    
    private var installationProgressView: some View {
        VStack(spacing: AXSpacing.xl) {
            // Progress indicator
            VStack(spacing: AXSpacing.lg) {
                ProgressView(value: viewModel.installationProgress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 400)
                
                HStack {
                    Text("\(Int(viewModel.installationProgress))%")
                        .font(AXTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(databaseType.brandColor)
                    
                    Spacer()
                    
                    Text(viewModel.currentStepTitle)
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                }
                .frame(width: 400)
            }
            
            // Current step description
            Text(viewModel.currentStepDescription)
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            // Log output
            logOutputView
            
            Spacer()
            
            // Cancel button
            Button("Cancel Installation") {
                Task {
                    await viewModel.cancelInstallation()
                }
            }
            .font(AXTypography.subheadline)
            .foregroundColor(.axError)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axError.opacity(0.1))
            .cornerRadius(AXCornerRadius.md)
        }
        .padding(AXSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Log Output View
    
    private var logOutputView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                ForEach(viewModel.installationLogs) { log in
                    HStack(spacing: AXSpacing.xs) {
                        let levelText = log.level.rawValue.uppercased()
                        Text("[") + Text(levelText) + Text("]")
                            .font(AXTypography.caption2)
                            .foregroundColor(logLevelColor(log.level))
                        
                        Text(log.message)
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AXSpacing.md)
        }
        .frame(width: 500, height: 200)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }
    
    // MARK: - Helpers
    
    private func logLevelColor(_ level: InstallationLogLevel) -> Color {
        switch level {
        case .debug:
            return .axTextMuted
        case .info:
            return .axInfo
        case .warning:
            return .axWarning
        case .error:
            return .axError
        case .success:
            return .axSuccess
        @unknown default:
            return .axTextMuted
        }
    }
}

// MARK: - Requirement Item

private struct RequirementItem: View {
    let icon: String
    let title: String
    let value: String
    let recommended: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
                
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            
            Text(value)
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.axTextPrimary)
            
            Text("Rec: \(recommended)")
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }
}

// MARK: - Version Recommendation Card

private struct VersionRecommendationCard: View {
    let recommendation: DatabaseVersionRecommendation
    let isSelected: Bool
    let accentColor: Color
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AXSpacing.md) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : Color.axBorder, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 10, height: 10)
                    }
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    HStack(spacing: AXSpacing.sm) {
                        Text("Version \(recommendation.version)")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        
                        if recommendation.isRecommended {
                            Badge(text: "Recommended", color: .axSuccess)
                        }
                        
                        if recommendation.isLTS {
                            Badge(text: "LTS", color: .axInfo)
                        }
                        
                        SecurityBadge(status: recommendation.securityStatus)
                    }
                    
                    Text(recommendation.reasoning)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Compatibility score
                VStack(alignment: .trailing, spacing: AXSpacing.xxs) {
                    Text("\(recommendation.compatibilityScore)%")
                        .font(AXTypography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(compatibilityColor)
                    
                    Text("Compatible")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            }
            .padding(AXSpacing.md)
            .background(isSelected ? accentColor.opacity(0.05) : Color.axSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? accentColor : Color.axBorder, lineWidth: 1)
            )
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var compatibilityColor: Color {
        if recommendation.compatibilityScore >= 90 {
            return .axSuccess
        } else if recommendation.compatibilityScore >= 70 {
            return .axWarning
        } else {
            return .axError
        }
    }
}

// MARK: - Badge

private struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(AXTypography.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(color.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
    }
}

// MARK: - Security Badge

private struct SecurityBadge: View {
    let status: SecurityStatus
    
    var body: some View {
        HStack(spacing: AXSpacing.xxs) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusDisplayName)
                .font(AXTypography.caption2)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, AXSpacing.xs)
        .padding(.vertical, AXSpacing.xxxs)
        .background(statusColor.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private var statusColor: Color {
        switch status {
        case .secure:
            return .axSuccess
        case .updatesAvailable:
            return .axWarning
        case .critical, .endOfLife:
            return .axError
        case .unknown:
            return .axTextMuted
        @unknown default:
            return .axTextMuted
        }
    }
    
    private var statusDisplayName: String {
        switch status {
        case .secure:
            return "Secure"
        case .updatesAvailable:
            return "Updates Available"
        case .critical:
            return "Critical"
        case .endOfLife:
            return "End of Life"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - View Model

@MainActor
private class AIInstallationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recommendation: AIInstallationResponse?
    @Published var selectedVersion: DatabaseVersionRecommendation?
    @Published var isInstalling = false
    @Published var installationProgress: Double = 0
    @Published var currentStepTitle = ""
    @Published var currentStepDescription = ""
    @Published var installationLogs: [InstallationLog] = []
    @Published var installationCompleted = false

    private let installationService = DatabaseInstallationService.shared
    private var monitorTask: Task<Void, Never>?

    deinit {
        monitorTask?.cancel()
    }

    func loadRecommendations(databaseType: DatabaseType, serverId: String) async {
        // Reset state
        isLoading = true
        errorMessage = nil
        recommendation = nil
        selectedVersion = nil

        // Validate inputs
        guard !serverId.isEmpty else {
            errorMessage = "Server ID is not configured"
            isLoading = false
            return
        }

        do {
            let response = try await installationService.getInstallationRecommendations(
                databaseType: databaseType,
                serverId: serverId
            )

            recommendation = response

            // Select recommended version, or first available
            if let recommended = response.recommendations.first(where: { $0.isRecommended }) {
                selectedVersion = recommended
            } else {
                selectedVersion = response.recommendations.first
            }

            // Clear error if successful
            errorMessage = nil

        } catch let error as AIInstallationAPIError {
            // Handle specific API errors
            switch error {
            case .noAuthToken:
                errorMessage = "Authentication required. Please log in again."
            case .aiServiceUnavailable:
                errorMessage = "AI installation service is temporarily unavailable. Please try again later."
            case .unsupportedDatabaseType:
                errorMessage = "This database type is not supported for AI installation."
            case .serverNotFound:
                errorMessage = "Server not found or not accessible."
            case .networkError(let underlying):
                errorMessage = "Network error: \(underlying.localizedDescription)"
            case .decodingError:
                errorMessage = "Failed to process AI response. Please try again."
            default:
                errorMessage = error.localizedDescription
            }
        } catch let error as DatabaseInstallationError {
            // Handle installation errors
            errorMessage = error.localizedDescription
        } catch let error as SSHConnectionError {
            // Handle SSH connection errors
            switch error {
            case .notConnected:
                errorMessage = "Not connected to server. Please connect first."
            case .connectionFailed(let reason):
                errorMessage = "Connection failed: \(reason)"
            case .timeout:
                errorMessage = "Connection timed out. Please check server accessibility."
            default:
                errorMessage = "SSH Error: \(error.localizedDescription)"
            }
        } catch {
            // Fallback for other errors
            errorMessage = "Failed to get recommendations: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func startInstallation(serverId: String) async {
        // Validate prerequisites
        guard let recommendation = recommendation else {
            errorMessage = "No installation recommendations available"
            return
        }

        guard let version = selectedVersion else {
            errorMessage = "Please select a version to install"
            return
        }

        guard !serverId.isEmpty else {
            errorMessage = "Server ID is not configured"
            return
        }

        // Reset installation state
        isInstalling = true
        installationProgress = 0
        installationLogs = []
        installationCompleted = false
        errorMessage = nil
        currentStepTitle = "Starting installation..."
        currentStepDescription = "Preparing to install \(recommendation.databaseType.displayName) \(version.version)"

        do {
            // Start monitoring before the installation (so we can track progress)
            monitorTask = Task { [weak self] in
                await self?.monitorInstallationProgress()
            }

            try await installationService.startInstallation(
                databaseType: recommendation.databaseType,
                version: version.version,
                serverId: serverId,
                recommendation: recommendation
            )

            // Installation completed successfully
            installationCompleted = true
            currentStepTitle = "Installation Complete"
            currentStepDescription = "\(recommendation.databaseType.displayName) \(version.version) has been installed successfully."

        } catch let error as DatabaseInstallationError {
            switch error {
            case .alreadyInProgress:
                errorMessage = "An installation is already in progress. Please wait or cancel it first."
            case .cancelled:
                errorMessage = nil // User cancelled, not an error
                currentStepTitle = "Installation Cancelled"
                currentStepDescription = "The installation was cancelled."
            case .stepFailed(let step, let reason):
                errorMessage = "Installation failed at '\(step)': \(reason)"
            case .validationFailed(let step, let reason):
                errorMessage = "Validation failed at '\(step)': \(reason)"
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = "Installation failed: \(error.localizedDescription)"
        }

        monitorTask?.cancel()
        isInstalling = false
    }

    func cancelInstallation() async {
        currentStepTitle = "Cancelling..."
        currentStepDescription = "Stopping the installation process..."

        await installationService.cancelInstallation()

        monitorTask?.cancel()
        isInstalling = false
        currentStepTitle = "Installation Cancelled"
        currentStepDescription = "The installation was cancelled by user."
    }

    private func monitorInstallationProgress() async {
        // Monitor installation progress from the service
        while !Task.isCancelled && isInstalling && installationProgress < 100 {
            // Small delay between updates
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // Check if still installing
            guard isInstalling else { break }

            // Update from installation service
            if let progress = installationService.currentInstallation {
                installationProgress = progress.progressPercentage
                currentStepTitle = progress.currentStepTitle
                currentStepDescription = progress.currentStepDescription
                installationLogs = progress.logs

                // Check if completed
                if progress.status == .completed {
                    installationCompleted = true
                    break
                }

                // Check if failed
                if progress.status == .failed {
                    if let error = progress.error {
                        errorMessage = error.message
                    }
                    break
                }
            }
        }
    }
}
