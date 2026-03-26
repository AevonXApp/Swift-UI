//
//  AddServerView.swift
//  AevonX
//
//  Premium server addition interface with glassmorphism and micro-animations
//

import SwiftUI
import AevonXCoreBridge

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddServerViewModel()
    @State private var showContent = false
    
    var onSave: (AddServerRequest) -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.axBackground, Color.axBackgroundSecondary.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle animated accent glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentBlue.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)
                .blur(radius: 60)
            
            VStack(spacing: 0) {
                // Premium Header
                headerSection
                    .padding(.bottom, AXSpacing.lg)
                
                // Form Content with Transitions
                VStack {
                    ZStack {
                        switch viewModel.currentStep {
                        case .identity:
                            AddServerIdentityStep(viewModel: viewModel)
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        case .connection:
                            AddServerConnectionStep(viewModel: viewModel)
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        case .authentication:
                            AddServerAuthStep(viewModel: viewModel)
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        case .verify:
                            AddServerVerifyStep(viewModel: viewModel)
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        }
                    }
                    .padding(.horizontal, AXSpacing.lg)
                    
                    Spacer()
                    
                    // Wizard Navigation
                    HStack(spacing: AXSpacing.md) {
                        if !viewModel.isFirstStep {
                            AXPrimaryButton(title: L10n.Button.back, icon: "chevron.left", action: {
                                withAnimation { viewModel.prevStep() }
                            }, style: .secondary)
                        } else {
                            AXPrimaryButton(title: L10n.Button.cancel, icon: nil, action: {
                                dismiss()
                            }, style: .secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.isLastStep {
                            AXPrimaryButton(
                                title: "Save Server",
                                icon: "checkmark.circle.fill",
                                action: {
                                    if let request = viewModel.buildRequest() {
                                        onSave(request)
                                        dismiss()
                                    }
                                },
                                isDisabled: !viewModel.isValid
                            )
                        } else {
                            AXPrimaryButton(
                                title: "Next",
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
            }
        }
        .preferredColorScheme(ThemeEngine.shared.colorScheme)
        .onAppear {
            withAnimation { showContent = true }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AXSpacing.md) {
            ZStack {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.axSurface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Server icon with glow
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color.axAccentBlue.opacity(0.3), Color.clear], center: .center, startRadius: 0, endRadius: 40))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "server.rack")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(LinearGradient(colors: [Color.axAccentBlue, Color.axAccentGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.top, AXSpacing.lg)
            
            VStack(spacing: AXSpacing.xs) {
                Text(viewModel.currentStep.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                
                Text(subtitleForStep(viewModel.currentStep))
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
            }
            
            // Progress indicator (Wizard Steps)
            HStack(spacing: AXSpacing.sm) {
                ForEach(AddServerViewModel.Step.allCases, id: \.self) { step in
                    stepIndicator(for: step)
                }
            }
            .padding(.top, AXSpacing.sm)
        }
    }
    
    private func subtitleForStep(_ step: AddServerViewModel.Step) -> String {
        switch step {
        case .identity: return "Define how your server appears in the fleet"
        case .connection: return "Specify the network address and port"
        case .authentication: return "How should we securely access the system?"
        case .verify: return "Let's test the connection before saving"
        }
    }
    
    private func stepIndicator(for step: AddServerViewModel.Step) -> some View {
        let isCurrent = viewModel.currentStep == step
        let isCompleted = viewModel.currentStep.rawValue > step.rawValue
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(isCurrent || isCompleted ? Color.axAccentBlue : Color.axBorder)
            .frame(width: isCurrent ? 32 : 12, height: 4)
            .animation(.spring(response: 0.3), value: viewModel.currentStep)
    }
}

#Preview {
    AddServerView { _ in }
}
