//
//  AddWebsiteView.swift
//  AevonX
//
//  Modal view for creating new websites
//  Production-ready with validation, dynamic runtime detection, and directory browser
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

            if viewModel.isLoadingCapabilities {
                loadingView
            } else {
                // Form
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        domainField
                        runtimePicker
                        
                        if viewModel.runtimeHasVersions {
                            versionPicker
                        }

                        documentRootField
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
        }
        .padding(AXSpacing.xl)
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
        .task {
            await viewModel.loadServerCapabilities()
        }
        .sheet(isPresented: $viewModel.isShowingDirectoryBrowser) {
            DirectoryBrowserSheet(viewModel: viewModel)
        }
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

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: AXSpacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Detecting server capabilities...")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            Spacer()
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

    private var runtimePicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Runtime")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            Picker("", selection: $viewModel.runtime) {
                ForEach(viewModel.availableRuntimes, id: \.self) { rt in
                    Text(rt.rawValue).tag(rt)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var versionPicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("\(viewModel.runtime.rawValue) Version")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            if viewModel.currentVersions.isEmpty {
                Text("No versions detected")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
            } else {
                Picker("", selection: $viewModel.selectedVersion) {
                    ForEach(viewModel.currentVersions, id: \.self) { version in
                        Text(version).tag(version)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }

    private var documentRootField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Document Root")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            HStack(spacing: AXSpacing.sm) {
                TextField("/var/www/example.com", text: $viewModel.documentRoot)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
                    .padding(AXSpacing.md)
                    .background(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(
                                viewModel.validationErrors["documentRoot"] != nil ? Color.axError : Color.axBorder,
                                lineWidth: 1
                            )
                    )
                    .cornerRadius(AXCornerRadius.md)
                    .onChange(of: viewModel.documentRoot) { _, _ in
                        viewModel.userEditedDocumentRoot = true
                    }

                Button(action: {
                    viewModel.isShowingDirectoryBrowser = true
                    Task {
                        await viewModel.loadDirectories(at: viewModel.detectedWebRoot)
                    }
                }) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 16))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 38, height: 38)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .help("Browse server directories")
            }

            if let error = viewModel.validationErrors["documentRoot"] {
                Text(error)
                    .font(AXTypography.caption)
                    .foregroundColor(.axError)
            }
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
                .lineLimit(3)

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

// MARK: - Directory Browser Sheet

struct DirectoryBrowserSheet: View {
    @ObservedObject var viewModel: AddWebsiteViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Browse Server Directories")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 24, height: 24)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.lg)

            Divider().background(Color.axBorder)

            // Breadcrumb
            breadcrumb
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)

            Divider().background(Color.axBorder)

            // Directory list
            if viewModel.isLoadingDirectories {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Loading...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Go up button
                        if viewModel.browserCurrentPath != "/" {
                            Button(action: navigateUp) {
                                HStack(spacing: AXSpacing.sm) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 12))
                                        .foregroundColor(.axAccentBlue)
                                    Text("..")
                                        .font(AXTypography.body)
                                        .foregroundColor(.axAccentBlue)
                                    Spacer()
                                }
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider().background(Color.axBorder).padding(.leading, AXSpacing.lg)
                        }

                        if viewModel.browserDirectories.isEmpty {
                            HStack {
                                Text("No subdirectories")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                                Spacer()
                            }
                            .padding(AXSpacing.lg)
                        } else {
                            ForEach(viewModel.browserDirectories, id: \.self) { dir in
                                Button(action: {
                                    let newPath = viewModel.browserCurrentPath == "/"
                                        ? "/\(dir)"
                                        : "\(viewModel.browserCurrentPath)/\(dir)"
                                    Task {
                                        await viewModel.loadDirectories(at: newPath)
                                    }
                                }) {
                                    HStack(spacing: AXSpacing.sm) {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.axAccentBlue.opacity(0.8))
                                        Text(dir)
                                            .font(AXTypography.body)
                                            .foregroundColor(.axTextPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10))
                                            .foregroundColor(.axTextTertiary)
                                    }
                                    .padding(.horizontal, AXSpacing.lg)
                                    .padding(.vertical, AXSpacing.sm)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())

                                Divider().background(Color.axBorder).padding(.leading, AXSpacing.lg)
                            }
                        }
                    }
                }
            }

            Divider().background(Color.axBorder)

            // New folder
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)

                TextField("New folder name", text: $viewModel.newFolderName)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
                    .textFieldStyle(PlainTextFieldStyle())

                Button(action: {
                    Task { await viewModel.createNewFolder() }
                }) {
                    Text("Create")
                        .font(AXTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.xxs)
                        .background(viewModel.newFolderName.isEmpty ? Color.axAccentBlue.opacity(0.4) : Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.newFolderName.isEmpty)
            }
            .padding(AXSpacing.md)

            Divider().background(Color.axBorder)

            // Select current path
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected Path:")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                    Text(viewModel.browserCurrentPath)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    viewModel.selectDirectory(viewModel.browserCurrentPath)
                }) {
                    Text("Select")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.lg)
        }
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.axBackground)
    }

    // MARK: - Breadcrumb

    private var breadcrumb: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.xxs) {
                let components = pathComponents()

                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                            .foregroundColor(.axTextTertiary)
                    }

                    Button(action: {
                        let path = buildPath(upTo: index, from: components)
                        Task { await viewModel.loadDirectories(at: path) }
                    }) {
                        Text(component.isEmpty ? "/" : component)
                            .font(AXTypography.caption)
                            .foregroundColor(index == components.count - 1 ? .axTextPrimary : .axAccentBlue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func pathComponents() -> [String] {
        let path = viewModel.browserCurrentPath
        if path == "/" { return [""] }
        return [""] + path.split(separator: "/").map(String.init)
    }

    private func buildPath(upTo index: Int, from components: [String]) -> String {
        if index == 0 { return "/" }
        return "/" + components[1...index].joined(separator: "/")
    }

    private func navigateUp() {
        let current = viewModel.browserCurrentPath
        if let lastSlash = current.lastIndex(of: "/"), lastSlash != current.startIndex {
            let parent = String(current[current.startIndex..<lastSlash])
            Task { await viewModel.loadDirectories(at: parent) }
        } else {
            Task { await viewModel.loadDirectories(at: "/") }
        }
    }
}

#Preview {
    AddWebsiteView(serverId: nil, onCreated: {})
        .background(Color.axBackground)
}
