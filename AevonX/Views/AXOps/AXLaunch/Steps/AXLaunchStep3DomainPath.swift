//
//  AXLaunchStep3DomainPath.swift
//  AevonX
//
//  Step 3: Domain configuration + remote path with server file browser.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStep3DomainPath: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel
    @State private var showFileBrowser = false

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                AXLaunchStepHeader(
                    stepIndex: 3, totalSteps: viewModel.totalWizardSteps,
                    title: L10n.AXLaunch.stepDomainPath
                )
                domainSection
                remotePathSection
            }
        }
    }

    // MARK: - Domain Section

    private var domainSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.AXLaunch.stepDomain)
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(.axTextPrimary)

            domainModeRow(.newDomain, L10n.AXLaunch.addNewDomain, "plus.circle")
            domainModeRow(.existingDomain, L10n.AXLaunch.useExistingDomain, "link")
            domainModeRow(.skip, L10n.AXLaunch.skipDomain, "forward.fill")

            domainDetail
        }
    }

    private func domainModeRow(
        _ mode: AXLaunchWizardViewModel.DomainMode,
        _ title: String, _ icon: String
    ) -> some View {
        let isSelected = viewModel.domainMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.domainMode = mode
                if mode == .existingDomain && viewModel.existingDomains.isEmpty {
                    Task { await viewModel.loadExistingDomains() }
                }
            }
        } label: {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                    .frame(width: 20)
                Text(title)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
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

    @ViewBuilder
    private var domainDetail: some View {
        switch viewModel.domainMode {
        case .newDomain:
            newDomainForm
        case .existingDomain:
            existingDomainPicker
        case .skip:
            EmptyView()
        }
    }

    private var newDomainForm: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            TextField("myapp.example.com", text: $viewModel.domainName)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )

            webServerPicker
            sslOptions
        }
    }

    private var existingDomainPicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            if viewModel.isLoadingDomains {
                HStack(spacing: AXSpacing.sm) {
                    ProgressView().scaleEffect(0.7)
                    Text(L10n.AXLaunch.loadingDomains)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .padding(AXSpacing.md)
            } else if viewModel.existingDomains.isEmpty {
                Text(L10n.AXLaunch.noDomainsFound)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .padding(AXSpacing.md)
            } else {
                existingDomainList
            }

            sslOptions
        }
    }

    private var existingDomainList: some View {
        VStack(spacing: AXSpacing.xs) {
            ForEach(viewModel.existingDomains, id: \.self) { domain in
                let isSelected = viewModel.domainName == domain
                Button {
                    viewModel.selectExistingDomain(domain)
                } label: {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                        Text(domain)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                        Spacer()
                    }
                    .padding(AXSpacing.sm)
                    .background(isSelected ? Color.axAccentBlue.opacity(0.08) : Color.clear)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private var webServerPicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.AXLaunch.webServer)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            HStack(spacing: AXSpacing.sm) {
                webServerButton("nginx", "Nginx")
                webServerButton("apache", "Apache")
                webServerButton("openlitespeed", "OLS")
            }
        }
    }

    private func webServerButton(_ value: String, _ label: String) -> some View {
        let isSelected = viewModel.webServer == value
        return Button { viewModel.webServer = value } label: {
            Text(label)
                .font(AXTypography.caption.weight(.medium))
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

    private var sslOptions: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Toggle(isOn: $viewModel.useSSL) {
                Text(L10n.AXLaunch.enableSSL)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
            }
            .toggleStyle(.checkbox)

            Toggle(isOn: $viewModel.forceHTTPS) {
                Text(L10n.AXLaunch.forceHTTPS)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
            }
            .toggleStyle(.checkbox)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Remote Path Section

    private var remotePathSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.AXLaunch.remotePath)
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(.axTextPrimary)

            // Path display
            HStack(spacing: 0) {
                Button {
                    showFileBrowser = true
                    Task { await viewModel.browseServerPath(viewModel.currentBrowsePath) }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                        Text(viewModel.remotePath)
                            .font(.system(size: 13, design: .monospaced))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)
                }
                .buttonStyle(.plain)

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

            Text(L10n.AXLaunch.fullPath + ": " + viewModel.fullRemotePath)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
        .sheet(isPresented: $showFileBrowser) {
            serverFileBrowserSheet
        }
    }

    // MARK: - Server File Browser Sheet

    private var serverFileBrowserSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.AXLaunch.selectRemotePath)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button { showFileBrowser = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 24, height: 24)
                        .background(Color.axSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)

            // Current path breadcrumb
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "folder.fill")
                    .foregroundColor(.axAccentBlue)
                    .font(.system(size: 12))
                Text(viewModel.currentBrowsePath)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.bottom, AXSpacing.sm)

            Divider().background(Color.axBorder)

            // Directory list
            if viewModel.isBrowsingServer {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Parent directory
                        if viewModel.currentBrowsePath != "/" {
                            fileBrowserRow(name: "..", icon: "arrow.up.circle", isDir: true) {
                                let parent = (viewModel.currentBrowsePath as NSString).deletingLastPathComponent
                                Task { await viewModel.browseServerPath(parent) }
                            }
                        }

                        ForEach(viewModel.serverDirectories, id: \.path) { item in
                            fileBrowserRow(name: item.name, icon: "folder.fill", isDir: true) {
                                Task { await viewModel.browseServerPath(item.path) }
                            }
                        }
                    }
                }
            }

            Divider().background(Color.axBorder)

            // Select button
            HStack {
                Spacer()
                Button {
                    viewModel.selectRemotePath(viewModel.currentBrowsePath)
                    showFileBrowser = false
                } label: {
                    Text(L10n.AXLaunch.selectThisPath)
                        .font(AXTypography.subheadline.weight(.medium))
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.xl)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
        }
        .frame(width: 440, height: 400)
        .background(Color.axBackground)
        .preferredColorScheme(ThemeEngine.shared.colorScheme)
    }

    private func fileBrowserRow(name: String, icon: String, isDir: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(.axAccentBlue)
                    .font(.system(size: 13))
                    .frame(width: 20)
                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                if isDir {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
