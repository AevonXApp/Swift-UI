//
//  ModernAddDatabaseView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct ModernAddDatabaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddDatabaseViewModel
    let onCreated: () -> Void

    init(serverId: String?, installationStates: [DatabaseInstallationState], onCreated: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddDatabaseViewModel(
            serverId: serverId,
            installationStates: installationStates
        ))
        self.onCreated = onCreated
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.xl) {
                        engineSelectorSection
                        databaseNameSection
                        encodingSection
                        Divider()
                        userCreationSection
                    }
                    .padding(AXSpacing.xl)
                }
                Divider()
                footerSection
            }
            errorOverlay
        }
        .frame(width: 520, height: 550)
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Create Database")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Engine Selector

    @ViewBuilder
    private var engineSelectorSection: some View {
        if !viewModel.installedEngines.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Database Engine")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)

                HStack(spacing: AXSpacing.sm) {
                    ForEach(viewModel.installedEngines) { engine in
                        engineCard(engine)
                    }
                }
            }
        } else {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.axWarning)
                Text("No database engines installed on this server.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
            }
        }
    }

    private func engineCard(_ engine: DatabaseInstallationState) -> some View {
        let isSelected = viewModel.selectedType == engine.type
        return Button {
            viewModel.selectEngine(engine.type)
        } label: {
            VStack(spacing: AXSpacing.xs) {
                Image(systemName: engine.type.iconName)
                    .font(.system(size: 20))
                Text(engine.type.displayName)
                    .font(AXTypography.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? engine.type.brandColor : .axTextSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isSelected ? engine.type.brandColor.opacity(0.1) : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? engine.type.brandColor : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Database Name

    private var databaseNameSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Database Name")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)

            TextField("my_database", text: $viewModel.databaseName)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(viewModel.nameError != nil ? Color.axError : Color.axBorder, lineWidth: 1)
                )
                .onChange(of: viewModel.databaseName) { _, _ in
                    viewModel.validateDatabaseName()
                }

            if let error = viewModel.nameError {
                inlineError(error)
            }
        }
    }

    // MARK: - Encoding + Collation

    private var encodingSection: some View {
        HStack(spacing: AXSpacing.lg) {
            pickerField(title: "Encoding", selection: $viewModel.selectedCharset, options: viewModel.availableCharsets)
                .onChange(of: viewModel.selectedCharset) { _, _ in
                    let collations = viewModel.availableCollations
                    if !collations.contains(viewModel.selectedCollation) {
                        viewModel.selectedCollation = collations.first ?? "default"
                    }
                }

            pickerField(title: "Collation", selection: $viewModel.selectedCollation, options: viewModel.availableCollations)
        }
    }

    private func pickerField(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(title)
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)

            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.xs)
            .padding(.horizontal, AXSpacing.sm)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - User Creation

    @ViewBuilder
    private var userCreationSection: some View {
        if let type = viewModel.selectedType, type.supportsUserManagement {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Toggle(isOn: $viewModel.shouldCreateUser) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.selectedType?.brandColor ?? .axAccentBlue)
                        Text("Create database user")
                            .font(AXTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.axTextPrimary)
                    }
                }
                .toggleStyle(.switch)
                .tint(viewModel.selectedType?.brandColor ?? .axAccentBlue)

                if viewModel.shouldCreateUser {
                    userFieldsCard
                }
            }
        }
    }

    private var userFieldsCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            usernameField
            passwordField
            hostAndOptionsRow
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Username")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)

            TextField("db_user", text: $viewModel.username)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(viewModel.usernameError != nil ? Color.axError : Color.axBorder, lineWidth: 1)
                )
                .onChange(of: viewModel.username) { _, _ in
                    viewModel.validateUsername()
                }

            if let error = viewModel.usernameError {
                inlineError(error)
            }
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Password")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)

            HStack(spacing: AXSpacing.sm) {
                Group {
                    if viewModel.showPassword {
                        TextField("Password", text: $viewModel.password)
                    } else {
                        SecureField("Password", text: $viewModel.password)
                    }
                }
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .onChange(of: viewModel.password) { _, _ in
                    viewModel.validatePassword()
                }

                Button {
                    viewModel.showPassword.toggle()
                } label: {
                    Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 13))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.generatePassword()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(viewModel.passwordError != nil ? Color.axError : Color.axBorder, lineWidth: 1)
            )

            if let error = viewModel.passwordError {
                inlineError(error)
            }
        }
    }

    private var hostAndOptionsRow: some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Host Access")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)

                Picker("", selection: $viewModel.host) {
                    ForEach(viewModel.hostOptions, id: \.self) { option in
                        Text(option == "%" ? "Any Host (%)" : option).tag(option)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.vertical, AXSpacing.xs)
                .padding(.horizontal, AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Options")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)

                Toggle(isOn: $viewModel.forceSSL) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 12))
                        Text("Force SSL")
                            .font(AXTypography.subheadline)
                    }
                    .foregroundColor(.axTextPrimary)
                }
                .toggleStyle(.switch)
                .tint(.axAccentBlue)
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerSection: some View {
        HStack(spacing: AXSpacing.md) {
            if viewModel.didSucceed {
                successFooter
            } else {
                defaultFooter
            }
        }
        .padding(AXSpacing.xl)
    }

    private var successFooter: some View {
        Group {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.axSuccess)
                Text("Database created successfully!")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axSuccess)
            }
            Spacer()
            Button(action: {
                onCreated()
                dismiss()
            }) {
                Text("Done")
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.md)
                    .background(Color.axSuccess)
                    .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
        }
    }

    private var defaultFooter: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSubmitting)

            Button(action: {
                Task { await viewModel.submitForm() }
            }) {
                HStack(spacing: AXSpacing.sm) {
                    if viewModel.isSubmitting {
                        ProgressView()
                        .scaleEffect(0.7)
                        .tint(.axBackground)
                    }
                    Text(viewModel.isSubmitting ? "Creating..." : "Create Database")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(viewModel.isFormValid && !viewModel.isSubmitting ? (viewModel.selectedType?.brandColor ?? .axAccentBlue) : Color.axTextMuted.opacity(0.5))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
        }
    }

    // MARK: - Error Overlay

    @ViewBuilder
    private var errorOverlay: some View {
        if viewModel.operationResult.isFailure {
            VStack {
                Spacer()
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                    Text(viewModel.operationResult.message ?? "Operation failed")
                        .font(AXTypography.subheadline)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        viewModel.operationResult = .idle
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundColor(.axError)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundColor(.axError)
                .padding(AXSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axError.opacity(0.1))
                )
                .padding(AXSpacing.lg)
            }
        }
    }

    // MARK: - Helpers

    private func inlineError(_ message: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 11))
            Text(message)
                .font(AXTypography.caption2)
        }
        .foregroundColor(.axError)
    }
}
