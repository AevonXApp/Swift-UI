//
//  AddWebsiteView.swift
//  AevonX
//
//  Modal view for creating new websites
//  Production-ready with validation and real API integration
//

import SwiftUI

// MARK: - Add Website View

struct AddWebsiteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddWebsiteViewModel

    let onCreated: () -> Void

    init(serverId: String?, onCreated: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddWebsiteViewModel(serverId: serverId))
        self.onCreated = onCreated
    }

    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Header
            header

            Divider()
                .background(Color.axBorder)

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    domainField
                    nameField
                    runtimePicker

                    if viewModel.runtime == .php {
                        phpVersionPicker
                    }

                    documentRootField
                    environmentPicker
                    sslToggle
                }
                .padding(.horizontal, AXSpacing.md)
            }

            Spacer()

            // Error message
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            // Actions
            actions
        }
        .padding(AXSpacing.xl)
        .frame(width: 500, height: 600)
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Add New Website")
                .font(AXTypography.title)
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
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Form Fields

    private var domainField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Domain Name")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            TextField("example.com", text: $viewModel.domain)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(
                            viewModel.validationErrors["domain"] != nil ? Color.axError : Color.axBorder,
                            lineWidth: 1
                        )
                )
                .cornerRadius(AXCornerRadius.md)

            if let error = viewModel.validationErrors["domain"] {
                Text(error)
                    .font(AXTypography.caption)
                    .foregroundColor(.axError)
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Website Name")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            TextField("My Website", text: $viewModel.name)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .cornerRadius(AXCornerRadius.md)
        }
    }

    private var runtimePicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Runtime")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            Picker("", selection: $viewModel.runtime) {
                ForEach(viewModel.availableRuntimes, id: \.self) { runtime in
                    Text(runtime.rawValue).tag(runtime)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var phpVersionPicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("PHP Version")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            Picker("", selection: $viewModel.phpVersion) {
                ForEach(viewModel.availablePHPVersions, id: \.self) { version in
                    Text(version).tag(version)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var documentRootField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Document Root (Optional)")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            TextField("/var/www/html", text: $viewModel.documentRoot)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .cornerRadius(AXCornerRadius.md)
        }
    }

    private var environmentPicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Environment")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            Picker("", selection: $viewModel.environment) {
                ForEach(EnvironmentType.allCases, id: \.self) { env in
                    Text(env.rawValue).tag(env)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var sslToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text("Enable SSL")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)

                Text("Auto-generate Let's Encrypt certificate")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()

            Toggle("", isOn: $viewModel.enableSSL)
                .toggleStyle(SwitchToggleStyle(tint: .axAccentGreen))
                .frame(width: 40)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.axError)

            Text(message)
                .font(AXTypography.caption)
                .foregroundColor(.axError)

            Spacer()
        }
        .padding(AXSpacing.md)
        .background(Color.axError.opacity(0.1))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Actions

    private var actions: some View {
        HStack(spacing: AXSpacing.md) {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isCreating)

            Button(action: createWebsite) {
                HStack(spacing: AXSpacing.sm) {
                    if viewModel.isCreating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                    }

                    Text(viewModel.isCreating ? "Creating..." : "Create Website")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(viewModel.isCreating ? Color.axAccentBlue.opacity(0.6) : Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isCreating)
        }
    }

    // MARK: - Actions

    private func createWebsite() {
        Task {
            do {
                try await viewModel.createWebsite()
                onCreated()
                dismiss()
            } catch {
                // Error is already set in viewModel
            }
        }
    }
}

#Preview {
    AddWebsiteView(serverId: nil, onCreated: {})
        .background(Color.axBackground)
}
