//
//  AXLaunchStep4Database.swift
//  AevonX
//
//  Step 4: Database — auto-detect installed engines, existing DBs, SecureField.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStep4Database: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                AXLaunchStepHeader(
                    stepIndex: 4, totalSteps: viewModel.totalWizardSteps,
                    title: L10n.AXLaunch.stepDatabase
                )
                installedEnginesInfo
                modeSelector
                modeDetail
            }
        }
        .onAppear {
            if viewModel.installedDBEngines.isEmpty {
                Task { await viewModel.detectInstalledDBEngines() }
            }
        }
    }

    // MARK: - Installed Engines

    @ViewBuilder
    private var installedEnginesInfo: some View {
        if viewModel.isDetectingEngines {
            HStack(spacing: AXSpacing.sm) {
                ProgressView().scaleEffect(0.7)
                Text(L10n.AXLaunch.DB.detectingEngines)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
            .padding(AXSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
        } else if !viewModel.installedDBEngines.isEmpty {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.axSuccess)
                    .font(.system(size: 14))
                Text(L10n.AXLaunch.DB.detectedEngines)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                ForEach(viewModel.installedDBEngines, id: \.self) { engine in
                    Text(engine.capitalized)
                        .font(AXTypography.caption.weight(.medium))
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                Spacer()
            }
            .padding(AXSpacing.md)
            .background(Color.axSuccess.opacity(0.06))
            .cornerRadius(AXCornerRadius.md)
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        VStack(spacing: AXSpacing.sm) {
            dbModeRow(.autoCreate, L10n.AXLaunch.DB.autoCreate, L10n.AXLaunch.DB.autoCreateDesc, "wand.and.stars")
            dbModeRow(.manual, L10n.AXLaunch.DB.manual, L10n.AXLaunch.DB.manualDesc, "pencil.and.list.clipboard")
            dbModeRow(.existing, L10n.AXLaunch.DB.existing, L10n.AXLaunch.DB.existingDesc, "cylinder")
            dbModeRow(.none, L10n.AXLaunch.DB.none, L10n.AXLaunch.DB.noneDesc, "nosign")
        }
    }

    private func dbModeRow(
        _ mode: AXLaunchWizardViewModel.DBMode, _ title: String,
        _ desc: String, _ icon: String
    ) -> some View {
        let isSelected = viewModel.dbMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.dbMode = mode }
        } label: {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(title)
                        .font(AXTypography.subheadline.weight(.medium))
                        .foregroundColor(.axTextPrimary)
                    Text(desc)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
            }
            .padding(AXSpacing.md)
            .background(isSelected ? Color.axAccentBlue.opacity(0.08) : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mode Detail

    @ViewBuilder
    private var modeDetail: some View {
        switch viewModel.dbMode {
        case .autoCreate: autoCreateForm
        case .manual: manualForm
        case .existing: existingForm
        case .none: EmptyView()
        }
    }

    // MARK: - Auto Create

    private var autoCreateForm: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            enginePicker
            dbField(L10n.AXLaunch.DB.name, $viewModel.dbName)
            dbField(L10n.AXLaunch.DB.username, $viewModel.dbUsername)
            passwordField
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Manual

    private var manualForm: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            enginePicker
            HStack(spacing: AXSpacing.sm) {
                dbField(L10n.AXLaunch.DB.host, $viewModel.dbHost)
                dbField(L10n.AXLaunch.DB.port, $viewModel.dbPort)
                    .frame(width: 80)
            }
            dbField(L10n.AXLaunch.DB.name, $viewModel.dbName)
            dbField(L10n.AXLaunch.DB.username, $viewModel.dbUsername)
            passwordField
            testConnectionButton
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Existing

    private var existingForm: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            enginePicker
            dbField(L10n.AXLaunch.DB.username, $viewModel.dbUsername)
            passwordField
            testConnectionButton

            if !viewModel.existingDatabases.isEmpty {
                existingDBList
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .onAppear { Task { await viewModel.loadExistingDatabases() } }
    }

    private var existingDBList: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.AXLaunch.DB.selectDatabase)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            ForEach(viewModel.existingDatabases, id: \.self) { db in
                Button { viewModel.dbName = db } label: {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: viewModel.dbName == db ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(viewModel.dbName == db ? .axAccentBlue : .axTextMuted)
                        Text(db)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                        Spacer()
                    }
                    .padding(.vertical, AXSpacing.xxxs)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Shared Components

    private var enginePicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.AXLaunch.DB.engine)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            HStack(spacing: AXSpacing.sm) {
                engineButton("mysql", "MySQL")
                engineButton("postgres", "PostgreSQL")
            }
        }
    }

    private func engineButton(_ value: String, _ label: String) -> some View {
        let isSelected = viewModel.dbEngine == value
        let isInstalled = viewModel.installedDBEngines.contains(value)
        return Button { viewModel.dbEngine = value } label: {
            HStack(spacing: AXSpacing.xs) {
                Text(label)
                    .font(AXTypography.caption.weight(.medium))
                if isInstalled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axSuccess)
                }
            }
            .foregroundColor(isSelected ? .axBackground : .axTextPrimary)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.xs)
            .background(isSelected ? Color.axAccentBlue : Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func dbField(_ label: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            TextField(label, text: binding)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .padding(AXSpacing.sm)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(L10n.AXLaunch.DB.password)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            HStack(spacing: AXSpacing.xs) {
                SecureField(L10n.AXLaunch.DB.password, text: $viewModel.dbPassword)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(AXSpacing.sm)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                Button {
                    viewModel.regenerateDBPassword()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
                .help(L10n.AXLaunch.DB.regenerate)
            }
        }
    }

    private var testConnectionButton: some View {
        HStack {
            Button {
                Task { await viewModel.testDBConnection() }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if viewModel.isTestingDB {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text(L10n.AXLaunch.DB.testConnection)
                }
                .font(AXTypography.caption.weight(.medium))
                .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isTestingDB)

            if let result = viewModel.dbTestResult {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .axSuccess : .axError)
                if let err = result.error {
                    Text(err)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .lineLimit(1)
                }
            }
        }
    }
}
