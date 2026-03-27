//
//  AXLaunchWizardView.swift
//  AevonX
//
//  Sheet container for the AXLaunch deployment wizard.
//  New flow: Source → Server → Domain & Path → Database → Review & Launch
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AXLaunchWizardViewModel
    @State private var showContent = false

    init(servers: [Server], selectedServer: Server? = nil, localPath: String? = nil, serverListViewModel: ServerListViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: AXLaunchWizardViewModel(
            servers: servers, selectedServer: selectedServer, localPath: localPath, serverListViewModel: serverListViewModel
        ))
    }

    var body: some View {
        ZStack {
            backgroundLayer
            VStack(spacing: 0) {
                headerSection
                stepContent
                if !viewModel.isProgressStep {
                    navigationBar
                }
            }
        }
        .frame(minWidth: 620, minHeight: 580)
        .preferredColorScheme(ThemeEngine.shared.colorScheme)
        .onAppear {
            withAnimation { showContent = true }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Sub-views

private extension AXLaunchWizardView {

    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color.axBackground, Color.axBackgroundSecondary.opacity(0.8)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(RadialGradient(
                    colors: [Color.axAccentBlue.opacity(0.12), Color.clear],
                    center: .center, startRadius: 0, endRadius: 220
                ))
                .frame(width: 440, height: 440)
                .offset(x: -120, y: -220)
                .blur(radius: 60)
        }
    }

    var headerSection: some View {
        VStack(spacing: AXSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(viewModel.isUpdate ? L10n.AXLaunch.update : L10n.AXLaunch.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.axTextPrimary)
                    if let server = viewModel.selectedServer {
                        Text(server.name)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextSecondary)
                    }
                }
                Spacer()
                if !viewModel.isProgressStep || viewModel.launchComplete || viewModel.launchFailed {
                    closeButton
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.lg)

            if !viewModel.isProgressStep {
                stepIndicators
            }
        }
    }

    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.axTextSecondary)
                .frame(width: 28, height: 28)
                .background(Color.axSurface)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    var stepIndicators: some View {
        HStack(spacing: AXSpacing.sm) {
            ForEach(AXLaunchWizardViewModel.Step.wizardSteps, id: \.self) { step in
                let isCurrent = viewModel.currentStep == step
                let isCompleted = viewModel.currentStep.rawValue > step.rawValue
                RoundedRectangle(cornerRadius: 2)
                    .fill(isCurrent || isCompleted ? Color.axAccentBlue : Color.axBorder)
                    .frame(width: isCurrent ? 32 : 12, height: 4)
                    .animation(.spring(response: 0.3), value: viewModel.currentStep)
            }
        }
        .padding(.bottom, AXSpacing.sm)
    }

    var stepContent: some View {
        ZStack {
            switch viewModel.currentStep {
            case .source:
                AXLaunchStep1Source(viewModel: viewModel)
                    .transition(stepTransition)
            case .server:
                AXLaunchStep2Server(viewModel: viewModel)
                    .transition(stepTransition)
            case .domainPath:
                AXLaunchStep3DomainPath(viewModel: viewModel)
                    .transition(stepTransition)
            case .database:
                AXLaunchStep4Database(viewModel: viewModel)
                    .transition(stepTransition)
            case .review:
                AXLaunchStep5ReviewLaunch(viewModel: viewModel)
                    .transition(stepTransition)
            case .progress:
                AXLaunchStepProgress(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, AXSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    var navigationBar: some View {
        HStack(spacing: AXSpacing.md) {
            if viewModel.isFirstStep {
                AXPrimaryButton(title: L10n.Button.cancel, icon: nil, action: {
                    dismiss()
                }, style: .secondary)
            } else {
                AXPrimaryButton(title: L10n.Button.back, icon: "chevron.left", action: {
                    withAnimation { viewModel.prevStep() }
                }, style: .secondary)
            }

            Spacer()

            if viewModel.isLastWizardStep {
                launchButton
            } else {
                AXPrimaryButton(
                    title: L10n.Button.continue,
                    icon: "chevron.right",
                    action: {
                        withAnimation { viewModel.nextStep() }
                    },
                    isDisabled: !viewModel.isCurrentStepValid
                )
            }
        }
        .padding(AXSpacing.xl)
    }

    var launchButton: some View {
        Button {
            Task { await viewModel.startLaunch() }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 13))
                Text(viewModel.isUpdate ? L10n.AXLaunch.updateNow : L10n.AXLaunch.launchNow)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.md)
            .background(
                LinearGradient(
                    colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(AXCornerRadius.lg)
            .shadow(color: Color.axAccentBlue.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isCurrentStepValid)
        .opacity(viewModel.isCurrentStepValid ? 1 : 0.5)
    }
}
