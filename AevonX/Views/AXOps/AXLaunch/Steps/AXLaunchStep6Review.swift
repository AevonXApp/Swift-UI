//
//  AXLaunchStep6Review.swift
//  AevonX
//
//  Step 6: Review summary before launching.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStep6Review: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                AXLaunchStepHeader(
                    stepIndex: 6, totalSteps: viewModel.totalWizardSteps,
                    title: L10n.AXLaunch.stepReview
                )
                summaryCard
                saveToggle
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(spacing: AXSpacing.sm) {
            reviewRow(L10n.AXLaunch.Review.server, viewModel.server.name + " (\(viewModel.server.host))")
            Divider().background(Color.axBorder)
            reviewRow(L10n.AXLaunch.Review.framework, frameworkText)
            Divider().background(Color.axBorder)
            reviewRow(L10n.AXLaunch.Review.path, viewModel.remotePath + viewModel.remoteAppName)
            Divider().background(Color.axBorder)
            reviewRow(L10n.AXLaunch.Review.domain, domainText)
            Divider().background(Color.axBorder)
            reviewRow(L10n.AXLaunch.Review.database, databaseText)
            Divider().background(Color.axBorder)
            reviewRow(L10n.AXLaunch.Review.steps, stepsText)
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private func reviewRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
            Spacer()
        }
    }

    private var frameworkText: String {
        let fw = viewModel.manualFramework ?? viewModel.projectInfo?.type ?? "unknown"
        if let ver = viewModel.projectInfo?.version, !ver.isEmpty {
            return "\(fw.capitalized) \(ver)"
        }
        return fw.capitalized
    }

    private var domainText: String {
        if viewModel.domainMode == .skip { return "—" }
        var text = viewModel.domainName
        if viewModel.domainMode == .newDomain { text += " (new)" }
        if viewModel.useSSL { text += " + SSL" }
        return text
    }

    private var databaseText: String {
        switch viewModel.dbMode {
        case .none: return "—"
        case .autoCreate: return "\(viewModel.dbEngine.capitalized) · \(viewModel.dbName) (auto)"
        case .manual: return "\(viewModel.dbEngine.capitalized) · \(viewModel.dbName)"
        case .existing: return "\(viewModel.dbEngine.capitalized) · \(viewModel.dbName) (existing)"
        }
    }

    private var stepsText: String {
        var parts: [String] = []
        if viewModel.postSteps.installDeps { parts.append("deps") }
        if viewModel.postSteps.runMigrations { parts.append("migrate") }
        if viewModel.postSteps.runSeeders { parts.append("seed") }
        if viewModel.postSteps.runBuild { parts.append("build") }
        if viewModel.postSteps.clearCaches { parts.append("cache") }
        if viewModel.postSteps.restartService { parts.append("restart") }
        return parts.isEmpty ? "—" : parts.joined(separator: ", ")
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
