//
//  AXLaunchStep3Configure.swift
//  AevonX
//
//  Step 3: Remote path, env vars, post-launch steps.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStep3Configure: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                AXLaunchStepHeader(
                    stepIndex: 3, totalSteps: viewModel.totalWizardSteps,
                    title: L10n.AXLaunch.stepConfigure
                )
                remotePathSection
                envVarsSection
                postStepsSection
            }
        }
    }

    // MARK: - Remote Path

    private var remotePathSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.AXLaunch.remotePath)
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(.axTextPrimary)
            HStack(spacing: 0) {
                Text(viewModel.remotePath)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)

                TextField("myapp", text: $viewModel.remoteAppName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.sm)
            }
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Env Vars

    private var envVarsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Text(L10n.AXLaunch.envVars)
                    .font(AXTypography.subheadline.weight(.medium))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button(action: { viewModel.loadEnvExample() }) {
                    Text(L10n.AXLaunch.loadEnvExample)
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }

            if viewModel.envValues.isEmpty {
                emptyEnvPlaceholder
            } else {
                envList
            }

            Button(action: { viewModel.addEnvVariable() }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.AXLaunch.addVariable)
                }
                .font(AXTypography.caption)
                .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyEnvPlaceholder: some View {
        Text("No environment variables configured")
            .font(AXTypography.caption)
            .foregroundColor(.axTextMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.lg)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
    }

    private var envList: some View {
        VStack(spacing: AXSpacing.xs) {
            ForEach($viewModel.envValues) { $entry in
                envRow(entry: $entry)
            }
        }
    }

    private func envRow(entry: Binding<EnvEntry>) -> some View {
        HStack(spacing: AXSpacing.xs) {
            TextField("KEY", text: entry.key)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 140)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)

            TextField("value", text: entry.value)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)

            Button { viewModel.removeEnvVariable(id: entry.wrappedValue.id) } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.axTextMuted)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Post Steps

    private var postStepsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.AXLaunch.postSteps)
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(.axTextPrimary)

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                postToggle(L10n.AXLaunch.stepInstallDeps, $viewModel.postSteps.installDeps)
                postToggle(L10n.AXLaunch.stepRunMigrations, $viewModel.postSteps.runMigrations)
                postToggle(L10n.AXLaunch.stepRunSeeders, $viewModel.postSteps.runSeeders)
                postToggle(L10n.AXLaunch.stepRunBuild, $viewModel.postSteps.runBuild)
                postToggle(L10n.AXLaunch.stepClearCaches, $viewModel.postSteps.clearCaches)
                postToggle(L10n.AXLaunch.stepRestartService, $viewModel.postSteps.restartService)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
        }
    }

    private func postToggle(_ label: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(label)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
        }
        .toggleStyle(.checkbox)
    }
}
