//
//  ErrorResolutionView.swift
//  AevonX
//
//  Created by AevonX on 2026.
//

import SwiftUI
import AevonXCoreBridge

public struct ErrorResolutionView: View {
    @StateObject private var viewModel: ErrorResolutionViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(
        databaseType: DatabaseType,
        serverId: String,
        erroredStep: InstallationStep?,
        errorLog: InstallationLog?
    ) {
        _viewModel = StateObject(wrappedValue: ErrorResolutionViewModel(
            databaseType: databaseType,
            serverId: serverId,
            erroredStep: erroredStep,
            errorLog: errorLog
        ))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
                .background(Color.axBorder)
            
            contentView
                .padding(AXSpacing.xl)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.axBackground)
        .onAppear {
            Task {
                await viewModel.startAnalysis()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(L10n.ErrorResolution.title)
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                
                Text(viewModel.erroredStep?.title ?? L10n.ErrorResolution.installationError)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axError)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(AXTypography.body)
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
        switch viewModel.state {
        case .analyzing:
            loadingView
        case .solutionsReady:
            solutionsView
        case .executing:
            executingView
        case .resolved:
            successView
        case .failed:
            errorView
        default:
            EmptyView()
        }
    }
    
    // MARK: - States
    
    private var loadingView: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(L10n.ErrorResolution.analyzingError)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            Text(L10n.ErrorResolution.aiDiagnosing)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var solutionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Analysis Section
                if let analysis = viewModel.analysis {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text(L10n.ErrorResolution.diagnosis)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        Text(analysis.analysis)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextSecondary)
                        
                        HStack {
                            Text(L10n.ErrorResolution.rootCause)
                                .fontWeight(.semibold)
                            Text(analysis.rootCause)
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .padding(AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    
                    Divider().background(Color.axBorder)
                    
                    // Solutions Section
                    Text(L10n.ErrorResolution.suggestedSolutions)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    ForEach(analysis.solutions) { solution in
                        SolutionCard(solution: solution, accentColor: viewModel.databaseType.brandColor) {
                            Task {
                                await viewModel.executeSolution(solution)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var executingView: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            Text(L10n.ErrorResolution.executingSolution)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var successView: some View {
        VStack(spacing: AXSpacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axSuccess)
            
            Text(L10n.ErrorResolution.issueResolved)
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)
            
            Button(L10n.ErrorResolution.resumeInstallation) {
                dismiss() // Logic to resume needs to be handled by parent
            }
            .buttonStyle(PrimaryButtonStyle(accentColor: viewModel.databaseType.brandColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axError)
            
            Text(L10n.ErrorResolution.resolutionFailed)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            Text(viewModel.errorMessage ?? L10n.Error.generic)
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
            
            Button(L10n.Button.tryAgain) {
                Task {
                    await viewModel.startAnalysis()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Components

private struct SolutionCard: View {
    let solution: AIErrorSolution
    let accentColor: Color
    let onExecute: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Text(solution.title)
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                RiskBadge(level: solution.riskLevel)
            }
            
            Text(solution.description)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            
            if let command = solution.command {
                Text(command)
                    .font(.system(.caption, design: .monospaced))
                    .padding(AXSpacing.sm)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.sm)
            }
            
            Button(action: onExecute) {
                Text(solution.isAutomated ? L10n.ErrorResolution.autoFix : L10n.ErrorResolution.executeManually)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(accentColor: accentColor))
            .padding(.top, AXSpacing.sm)
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }
}

private struct RiskBadge: View {
    let level: SolutionRiskLevel
    
    var body: some View {
        Text(level.rawValue.uppercased())
            .font(AXTypography.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(AXCornerRadius.xs)
    }
    
    var color: Color {
        switch level {
        case .low: return .axSuccess
        case .medium: return .axWarning
        case .high: return .axError
        case .critical: return .axError
        }
    }
}

// Helper Button Styles (Assuming these exist or creating simple ones)
struct PrimaryButtonStyle: ButtonStyle {
    var accentColor: Color = .axAccentBlue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(accentColor)
            .foregroundColor(.white)
            .cornerRadius(AXCornerRadius.md)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.axSurface)
            .foregroundColor(.axTextPrimary)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
