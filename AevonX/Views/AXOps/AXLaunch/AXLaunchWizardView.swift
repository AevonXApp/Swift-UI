//
//  AXLaunchWizardView.swift
//  AevonX
//
//  Sheet container for the AXLaunch deployment wizard.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AXLaunchWizardViewModel
    @State private var showContent = false

    init(server: Server, localPath: String? = nil) {
        _viewModel = StateObject(wrappedValue: AXLaunchWizardViewModel(server: server, localPath: localPath))
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
        .frame(minWidth: 600, minHeight: 560)
        .preferredColorScheme(ThemeEngine.shared.colorScheme)
        .onAppear {
            withAnimation { showContent = true }
            if !viewModel.localPath.isEmpty {
                Task { await viewModel.detectProject() }
            }
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
                    Text(viewModel.server.name)
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
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
            case .detect:
                AXLaunchStep2Detect(viewModel: viewModel)
                    .transition(stepTransition)
            case .configure:
                AXLaunchStep3Configure(viewModel: viewModel)
                    .transition(stepTransition)
            case .domain:
                AXLaunchStep4Domain(viewModel: viewModel)
                    .transition(stepTransition)
            case .database:
                AXLaunchStep5Database(viewModel: viewModel)
                    .transition(stepTransition)
            case .review:
                AXLaunchStep6Review(viewModel: viewModel)
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
                AXPrimaryButton(
                    title: viewModel.isUpdate ? L10n.AXLaunch.updateNow : L10n.AXLaunch.launchNow,
                    icon: "paperplane.fill",
                    action: { Task { await viewModel.startLaunch() } },
                    isDisabled: !viewModel.isCurrentStepValid
                )
            } else {
                AXPrimaryButton(
                    title: L10n.Button.continue,
                    icon: "chevron.right",
                    action: {
                        withAnimation { viewModel.nextStep() }
                        if viewModel.currentStep == .detect && viewModel.projectInfo == nil {
                            Task { await viewModel.detectProject() }
                        }
                    },
                    isDisabled: !viewModel.isCurrentStepValid
                )
            }
        }
        .padding(AXSpacing.xl)
    }
}
