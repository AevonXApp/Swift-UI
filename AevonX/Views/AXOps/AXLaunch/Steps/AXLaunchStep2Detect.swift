//
//  AXLaunchStep2Detect.swift
//  AevonX
//
//  Step 2: Detection result display.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStep2Detect: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel
    @State private var showManualPicker = false

    private let frameworks = [
        "laravel", "wordpress", "nextjs", "react", "nodejs",
        "django", "fastapi", "go", "docker", "static"
    ]

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            AXLaunchStepHeader(
                stepIndex: 2, totalSteps: viewModel.totalWizardSteps,
                title: L10n.AXLaunch.stepDetect
            )

            if viewModel.isDetecting {
                detectingState
            } else if let info = viewModel.projectInfo {
                detectedContent(info)
            } else if let error = viewModel.detectionError {
                errorState(error)
            }

            Spacer()
        }
    }

    // MARK: - States

    private var detectingState: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .padding(.bottom, AXSpacing.sm)
            Text("Analyzing project...")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxl)
    }

    private func detectedContent(_ info: AXProjectInfo) -> some View {
        VStack(spacing: AXSpacing.lg) {
            AXLaunchFrameworkBadge(info: info)

            manualOverride
            ignoreListSection
        }
    }

    private func errorState(_ error: String) -> some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.axWarning)
            Text(L10n.AXLaunch.errorDetectionFailed)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
            Text(error)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            manualOverride
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xl)
    }

    // MARK: - Manual Override

    private var manualOverride: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Button {
                withAnimation { showManualPicker.toggle() }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Text(L10n.AXLaunch.notCorrect)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Text(L10n.AXLaunch.selectManually)
                        .font(AXTypography.caption.weight(.medium))
                        .foregroundColor(.axAccentBlue)
                    Image(systemName: showManualPicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.axAccentBlue)
                }
            }
            .buttonStyle(.plain)

            if showManualPicker {
                frameworkGrid
            }
        }
    }

    private var frameworkGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: AXSpacing.sm)], spacing: AXSpacing.sm) {
            ForEach(frameworks, id: \.self) { fw in
                let isSelected = viewModel.manualFramework == fw
                Button {
                    viewModel.manualFramework = fw
                } label: {
                    Text(fw.capitalized)
                        .font(AXTypography.caption.weight(.medium))
                        .foregroundColor(isSelected ? .axBackground : .axTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.sm)
                        .background(isSelected ? Color.axAccentBlue : Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Ignore List

    private var ignoreListSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.AXLaunch.ignoreList)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Text(viewModel.ignoreList.joined(separator: ", "))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
