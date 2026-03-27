//
//  AXLaunchStep5ReviewLaunch.swift
//  AevonX
//
//  Step 5: Review summary + env vars + post-steps + launch.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStep5ReviewLaunch: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel
    @State private var showEnvSection = false
    @State private var showPostSteps = false

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                AXLaunchStepHeader(
                    stepIndex: 5, totalSteps: viewModel.totalWizardSteps,
                    title: L10n.AXLaunch.stepReview
                )
                summaryCard
                envVarsSection
                postStepsSection
                saveToggle
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 0) {
            summaryRow(icon: "server.rack", label: L10n.AXLaunch.Review.server, value: serverText)
            summaryDivider
            summaryRow(icon: "hammer", label: L10n.AXLaunch.Review.framework, value: frameworkText)
            summaryDivider
            summaryRow(icon: "folder", label: L10n.AXLaunch.Review.path, value: viewModel.fullRemotePath)
            summaryDivider
            summaryRow(icon: "globe", label: L10n.AXLaunch.Review.domain, value: domainText)
            summaryDivider
            summaryRow(icon: "cylinder", label: L10n.AXLaunch.Review.database, value: databaseText)
        }
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.axAccentBlue)
                .frame(width: 20)
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }

    private var summaryDivider: some View {
        Divider().background(Color.axBorder).padding(.horizontal, AXSpacing.lg)
    }

    private var serverText: String {
        viewModel.server.name + " (\(viewModel.server.host))"
    }

    private var frameworkText: String {
        let fw = viewModel.manualFramework ?? viewModel.projectInfo?.type ?? "unknown"
        if let ver = viewModel.projectInfo?.version, !ver.isEmpty {
            return "\(fw.capitalized) \(ver)"
        }
        return fw.capitalized
    }

    private var domainText: String {
        if viewModel.domainMode == .skip { return "\u{2014}" }
        var text = viewModel.domainName
        if viewModel.domainMode == .newDomain { text += " (new)" }
        if viewModel.useSSL { text += " + SSL" }
        return text
    }

    private var databaseText: String {
        switch viewModel.dbMode {
        case .none: return "\u{2014}"
        case .autoCreate: return "\(viewModel.dbEngine.capitalized) \u{00B7} \(viewModel.dbName) (auto)"
        case .manual: return "\(viewModel.dbEngine.capitalized) \u{00B7} \(viewModel.dbName)"
        case .existing: return "\(viewModel.dbEngine.capitalized) \u{00B7} \(viewModel.dbName) (existing)"
        }
    }

    // MARK: - Env Vars Section

    private var envVarsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Button {
                withAnimation { showEnvSection.toggle() }
            } label: {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.axTextMuted)
                        .rotationEffect(showEnvSection ? .degrees(90) : .zero)

                    Text(L10n.AXLaunch.envVars)
                        .font(AXTypography.subheadline.weight(.medium))
                        .foregroundColor(.axTextPrimary)

                    if !viewModel.envValues.isEmpty {
                        Text("\(viewModel.envValues.count)")
                            .font(AXTypography.caption)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }

                    Spacer()

                    Button(action: { viewModel.loadEnvExample() }) {
                        Text(L10n.AXLaunch.loadEnvExample)
                            .font(AXTypography.caption)
                            .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .buttonStyle(.plain)

            if showEnvSection {
                envContent
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    private var envContent: some View {
        VStack(spacing: AXSpacing.xs) {
            if viewModel.envValues.isEmpty {
                Text(L10n.AXLaunch.noEnvVars)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.md)
            } else {
                ForEach($viewModel.envValues) { $entry in
                    envRow(entry: $entry)
                }
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

    private func envRow(entry: Binding<EnvEntry>) -> some View {
        HStack(spacing: AXSpacing.xs) {
            TextField("KEY", text: entry.key)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 140)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)

            TextField("value", text: entry.value)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)

            Button { viewModel.removeEnvVariable(id: entry.wrappedValue.id) } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.axTextMuted)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Post Steps Section

    private var postStepsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Button {
                withAnimation { showPostSteps.toggle() }
            } label: {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.axTextMuted)
                        .rotationEffect(showPostSteps ? .degrees(90) : .zero)

                    Text(L10n.AXLaunch.postSteps)
                        .font(AXTypography.subheadline.weight(.medium))
                        .foregroundColor(.axTextPrimary)

                    let count = activePostStepsCount
                    if count > 0 {
                        Text("\(count)")
                            .font(AXTypography.caption)
                            .foregroundColor(.axAccentGreen)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xxxs)
                            .background(Color.axAccentGreen.opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if showPostSteps {
                postStepsContent
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    private var postStepsContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            postToggle(L10n.AXLaunch.stepInstallDeps, $viewModel.postSteps.installDeps)
            postToggle(L10n.AXLaunch.stepRunMigrations, $viewModel.postSteps.runMigrations)
            postToggle(L10n.AXLaunch.stepRunSeeders, $viewModel.postSteps.runSeeders)
            postToggle(L10n.AXLaunch.stepRunBuild, $viewModel.postSteps.runBuild)
            postToggle(L10n.AXLaunch.stepClearCaches, $viewModel.postSteps.clearCaches)
            postToggle(L10n.AXLaunch.stepRestartService, $viewModel.postSteps.restartService)
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

    private var activePostStepsCount: Int {
        var c = 0
        if viewModel.postSteps.installDeps { c += 1 }
        if viewModel.postSteps.runMigrations { c += 1 }
        if viewModel.postSteps.runSeeders { c += 1 }
        if viewModel.postSteps.runBuild { c += 1 }
        if viewModel.postSteps.clearCaches { c += 1 }
        if viewModel.postSteps.restartService { c += 1 }
        return c
    }

    // MARK: - Save Toggle

    private var saveToggle: some View {
        Toggle(isOn: $viewModel.saveConfig) {
            Text(L10n.AXLaunch.saveConfig)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
        }
        .toggleStyle(.checkbox)
    }
}
