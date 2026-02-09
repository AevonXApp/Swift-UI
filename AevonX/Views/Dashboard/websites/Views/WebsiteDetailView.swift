//
//  WebsiteDetailView.swift
//  AevonX
//
//  Detailed view for individual website management
//

import SwiftUI

// MARK: - Website Detail View

struct WebsiteDetailView: View {
    @StateObject private var viewModel: WebsiteDetailViewModel
    let onBack: () -> Void
    var initialTab: Int = 0

    @State private var selectedTab: Int

    init(website: WebsiteInfo, serverId: String?, onBack: @escaping () -> Void, initialTab: Int = 0) {
        self._viewModel = StateObject(wrappedValue: WebsiteDetailViewModel(website: website, serverId: serverId))
        self.onBack = onBack
        self.initialTab = initialTab
        self._selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ModernWebsitePanel(viewModel: viewModel, onBack: onBack)
            .background(Color.axBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: AXSpacing.md) {
            Button(action: onBack) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                    Text("Back")
                }
                .font(AXTypography.body)
                .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            VStack(alignment: .trailing, spacing: AXSpacing.xxs) {
                Text(viewModel.website.name)
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                Text(viewModel.website.domain)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()

            statusBadge
                .onTapGesture {
                    Task { await viewModel.toggleStatus() }
                }
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
    }

    private var statusBadge: some View {
        HStack(spacing: AXSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(viewModel.website.status.rawValue.capitalized)
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.axTextSecondary)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .cornerRadius(AXCornerRadius.sm)
    }

    private var statusColor: Color {
        switch viewModel.website.status {
        case .online: return .axSuccess
        case .offline: return .axTextMuted
        case .maintenance: return .axWarning
        case .error: return .axError
        case .deploying: return .axAccentBlue
        case .unknown: return .axTextMuted
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            WebsiteTabButton(title: "Overview", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            WebsiteTabButton(title: "Configuration", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            WebsiteTabButton(title: "Deployment", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            WebsiteTabButton(title: "Logs", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
            Spacer()
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
    }

    // MARK: - Tab Views

    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                // Website stats
                statsSection

                // SSL Information
                if viewModel.website.sslEnabled, let ssl = viewModel.website.sslInfo {
                    sslSection(ssl)
                }

                // Health issues
                if !viewModel.website.healthIssues.isEmpty {
                    healthIssuesSection
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private var configurationTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text("Settings")
                            .font(AXTypography.title2)
                            .foregroundColor(.axTextPrimary)
                        Text("Manage your website's server-side configuration")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                    Spacer()
                    
                    Button(action: { Task { await viewModel.saveConfiguration() } }) {
                        if viewModel.isSavingConfig {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                VStack(spacing: AXSpacing.md) {
                    // Document Root with Browser
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Document Root")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                        
                        HStack(spacing: AXSpacing.sm) {
                            TextField("/var/www/domain.com", text: $viewModel.documentRoot)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(AXSpacing.sm)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            
                            Button(action: { viewModel.startBrowsing() }) {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(.axAccentBlue)
                                    .padding(AXSpacing.sm)
                                    .background(Color.axAccentBlue.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // PHP Version Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PHP Version")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                        
                        if viewModel.website.runtime == .php {
                            if viewModel.isLoadingPHPVersions {
                                ProgressView().scaleEffect(0.6)
                            } else {
                                Picker("", selection: $viewModel.phpVersion) {
                                    if !viewModel.installedPHPVersions.contains(viewModel.phpVersion) && !viewModel.phpVersion.isEmpty {
                                        Text(viewModel.phpVersion).tag(viewModel.phpVersion)
                                    }
                                    ForEach(viewModel.installedPHPVersions, id: \.self) { version in
                                        Text("PHP \(version)").tag(version)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(AXSpacing.xxs)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            }
                        } else {
                            Text("Not applicable for \(viewModel.website.runtime.rawValue) runtime")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(AXSpacing.sm)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.lg)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder, lineWidth: 1))

                Text("Configuration Path: \(viewModel.website.configPath ?? "Default")")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, AXSpacing.xs)
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            if viewModel.website.runtime == .php {
                Task { await viewModel.fetchInstalledPHPVersions() }
            }
        }
        .sheet(isPresented: $viewModel.isBrowsingPath) {
            DirectoryBrowserView(viewModel: viewModel)
        }
    }
    
    private func configField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            TextField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(AXSpacing.sm)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
        }
    }

    private var deploymentTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text("Deployment")
                            .font(AXTypography.title2)
                            .foregroundColor(.axTextPrimary)
                        Text("Update your website's code from the repository")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                    Spacer()
                    
                    Button(action: { Task { await viewModel.deploy() } }) {
                        HStack(spacing: AXSpacing.sm) {
                            if viewModel.isDeploying {
                                ProgressView().scaleEffect(0.6)
                            } else {
                                Image(systemName: "rocket.fill")
                                Text("Deploy Now")
                            }
                        }
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }

                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.axTextTertiary)
                        Text("Last Deployed:")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextSecondary)
                        Spacer()
                        Text(viewModel.website.lastDeployed?.formatted() ?? "Never")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                    }
                    
                    if let branch = viewModel.website.gitBranch {
                        HStack {
                            Image(systemName: "arrow.branch")
                                .foregroundColor(.axTextTertiary)
                            Text("Git Branch:")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                            Spacer()
                            Text(branch)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                        }
                    }
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.lg)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder, lineWidth: 1))

                if !viewModel.deploymentLogs.isEmpty {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text("Deployment Logs")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        Text(viewModel.deploymentLogs)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.axSuccess)
                            .padding(AXSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(AXCornerRadius.md)
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private var logsTab: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text("Server Logs")
                        .font(AXTypography.title2)
                        .foregroundColor(.axTextPrimary)
                    Text("Real-time output from access and error logs")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                Spacer()
                
                Button(action: { Task { await viewModel.fetchLogs() } }) {
                    HStack(spacing: AXSpacing.sm) {
                        if viewModel.isLoadingLogs {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                    }
                }
                .font(AXTypography.caption)
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            }
            .padding(AXSpacing.xl)

            ScrollView {
                Text(viewModel.logs.isEmpty ? "No logs available. Click refresh to fetch logs." : viewModel.logs)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .padding(AXSpacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.axBackgroundTertiary)
        }
        .onAppear {
            if viewModel.logs.isEmpty {
                Task { await viewModel.fetchLogs() }
            }
        }
    }

    // MARK: - Sections

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Statistics")
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)

            HStack(spacing: AXSpacing.md) {
                WebsiteStatItem(label: "Disk Usage", value: viewModel.website.formattedDiskUsage)
                WebsiteStatItem(label: "Bandwidth", value: viewModel.website.formattedBandwidth)
                if let visitors = viewModel.website.monthlyVisitors {
                    WebsiteStatItem(label: "Monthly Visitors", value: "\(visitors)")
                }
            }
        }
    }

    private func sslSection(_ ssl: SSLInfo) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("SSL Certificate")
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)

            HStack(spacing: AXSpacing.md) {
                WebsiteStatItem(label: "Provider", value: ssl.provider.rawValue)
                WebsiteStatItem(label: "Status", value: ssl.status.rawValue.capitalized)
                if let days = ssl.daysUntilExpiry {
                    WebsiteStatItem(label: "Expires In", value: "\(days) days")
                }
            }

            if ssl.isExpiringSoon {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.axWarning)

                    Text("Certificate is expiring soon")
                        .font(AXTypography.body)
                        .foregroundColor(.axWarning)
                }
                .padding(AXSpacing.md)
                .background(Color.axWarning.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            }
        }
    }

    private var healthIssuesSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Health Issues")
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)

            ForEach(viewModel.website.healthIssues) { issue in
                HealthIssueCard(issue: issue)
            }
        }
    }
}

// MARK: - Website Tab Button

struct WebsiteTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AXSpacing.xs) {
                Text(title)
                    .font(AXTypography.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)

                if isSelected {
                    Rectangle()
                        .fill(Color.axAccentBlue)
                        .frame(height: 2)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, AXSpacing.md)
    }
}

// MARK: - Website Stat Item

struct WebsiteStatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            Text(value)
                .font(AXTypography.body)
                .fontWeight(.medium)
                .foregroundColor(.axTextPrimary)
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }
}

// MARK: - Health Issue Card

struct HealthIssueCard: View {
    let issue: WebsiteHealthIssue

    var body: some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(issue.title)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)

                Text(issue.description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)

                if let recommendation = issue.recommendation {
                    Text("Recommendation: \(recommendation)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(AXSpacing.md)
        .background(severityColor.opacity(0.1))
        .cornerRadius(AXCornerRadius.md)
    }

    private var severityIcon: String {
        switch issue.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var severityColor: Color {
        switch issue.severity {
        case .critical: return .axError
        case .warning: return .axWarning
        case .info: return .axAccentBlue
        }
    }
}
