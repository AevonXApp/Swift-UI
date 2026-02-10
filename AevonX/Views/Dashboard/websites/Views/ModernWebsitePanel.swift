//
//  ModernWebsitePanel.swift
//  AevonX
//
//  Premium redesigned website control panel with beautiful, modern UI
//  Inspired by best-in-class hosting control panels (cPanel, Plesk, Vercel, Netlify)
//

import SwiftUI
import AevonXCore

// MARK: - Sidebar Items

enum ModernSidebarItem: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case domainManager = "Domain & Port"
    case siteDirectory = "Site Directory"
    case urlRewrites = "URL Rewrites"
    case sslTls = "SSL/TLS"
    case phpSettings = "PHP Config"
    case trafficControl = "Traffic Analytics"
    case logs = "Logs"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .overview: return "house.fill"
        case .domainManager: return "globe"
        case .siteDirectory: return "folder.fill"
        case .urlRewrites: return "arrow.triangle.branch"
        case .sslTls: return "lock.shield.fill"
        case .phpSettings: return "chevron.left.forwardslash.chevron.right"
        case .trafficControl: return "chart.xyaxis.line"
        case .logs: return "text.alignleft"
        }
    }

    var description: String {
        switch self {
        case .overview: return "Quick status and metrics"
        case .domainManager: return "Configure domains and ports"
        case .siteDirectory: return "Browse and manage files"
        case .urlRewrites: return "Manage redirect rules"
        case .sslTls: return "SSL certificates & security"
        case .phpSettings: return "PHP version & extensions"
        case .trafficControl: return "Visitor stats & analytics"
        case .logs: return "Access & error logs"
        }
    }
}

// MARK: - Modern Website Panel

struct ModernWebsitePanel: View {
    @ObservedObject var viewModel: WebsiteDetailViewModel
    var onBack: () -> Void

    @State private var selectedItem: ModernSidebarItem = .overview
    @State private var isHoveringBack = false

    var body: some View {
        HStack(spacing: 0) {
            // Premium Sidebar
            premiumSidebar

            Divider()
                .background(Color.axBorder.opacity(0.5))

            // Main Content Area with Header
            VStack(spacing: 0) {
                premiumHeader

                Divider()
                    .background(Color.axBorder.opacity(0.3))

                // Content
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.axBackground)
            }
        }
        .onAppear {
            Task { await viewModel.loadWebsiteDetails() }
        }
    }

    // MARK: - Premium Sidebar

    private var premiumSidebar: some View {
        VStack(spacing: 0) {
            // Sidebar Header
            VStack(spacing: AXSpacing.md) {
                // Back Button
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("Back")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(isHoveringBack ? .white : .axAccentBlue)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(isHoveringBack ? Color.axAccentBlue : Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { hovering in
                        isHoveringBack = hovering
                    }

                    Spacer()
                }

                // Site Info Card
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.website.name)
                                .font(AXTypography.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.axTextPrimary)
                                .lineLimit(1)

                            Text(viewModel.website.domain)
                                .font(.system(size: 11))
                                .foregroundColor(.axTextTertiary)
                                .lineLimit(1)
                        }

                        Spacer()

                        statusIndicator
                    }

                    // Quick Stats
                    HStack(spacing: AXSpacing.md) {
                        quickStat(icon: "arrow.up.arrow.down", value: viewModel.website.formattedBandwidth, color: .axAccentBlue)
                        quickStat(icon: "internaldrive", value: viewModel.website.formattedDiskUsage, color: .axSuccess)
                    }
                    .padding(.top, AXSpacing.xs)
                }
                .padding(AXSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(Color.axBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
            .padding(AXSpacing.lg)

            Divider()
                .background(Color.axBorder.opacity(0.3))

            // Navigation Items
            ScrollView(showsIndicators: false) {
                VStack(spacing: AXSpacing.xs) {
                    ForEach(ModernSidebarItem.allCases) { item in
                        PremiumSidebarButton(
                            item: item,
                            isSelected: selectedItem == item,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedItem = item
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.lg)
            }

            Spacer()

            // Sidebar Footer
            sidebarFooter
        }
        .frame(width: 260)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.axSurface,
                    Color.axSurface.opacity(0.98)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func quickStat(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextSecondary)
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(viewModel.website.status.rawValue.capitalized)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, AXSpacing.xs)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.1))
        .cornerRadius(AXCornerRadius.xs)
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

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.axBorder.opacity(0.3))

            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.axAccentBlue.opacity(0.7))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Server: \(viewModel.serverId ?? "Unknown")")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                    Text("Runtime: \(viewModel.website.runtime.rawValue)")
                        .font(.system(size: 9))
                        .foregroundColor(.axTextTertiary)
                }

                Spacer()
            }
            .padding(AXSpacing.md)
            .background(Color.axBackground.opacity(0.5))
        }
    }

    // MARK: - Premium Header

    private var premiumHeader: some View {
        HStack(spacing: AXSpacing.lg) {
            // Section Title
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedItem.rawValue)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Text(selectedItem.description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Spacer()

            // Quick Actions
            HStack(spacing: AXSpacing.sm) {
                if viewModel.isLoadingStats {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, AXSpacing.xs)
                }

                // Domain Badge
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 11))
                        .foregroundColor(.axAccentBlue)
                    Text(viewModel.website.domain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 6)
                .background(Color.axAccentBlue.opacity(0.08))
                .cornerRadius(AXCornerRadius.sm)

                // Refresh Button (context-aware)
                Button(action: { Task { await refreshCurrentSection() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
        .background(
            Color.axSurface.opacity(0.5)
                .background(.ultraThinMaterial)
        )
    }

    // MARK: - Content Views

    @ViewBuilder
    private var contentView: some View {
        switch selectedItem {
        case .overview:
            overviewView
        case .domainManager:
            domainManagerView
        case .siteDirectory:
            siteDirectoryView
        case .urlRewrites:
            urlRewritesView
        case .sslTls:
            sslTlsView
        case .phpSettings:
            phpSettingsView
        case .trafficControl:
            trafficControlView
        case .logs:
            logsView
        }
    }

    // MARK: - Overview View (NEW)

    private var overviewView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Status Summary Cards
                HStack(spacing: AXSpacing.md) {
                    MetricCard(
                        icon: "globe",
                        title: "Domain Status",
                        value: viewModel.website.status.rawValue.capitalized,
                        color: statusColor,
                        trend: nil
                    )

                    MetricCard(
                        icon: "lock.shield.fill",
                        title: "SSL Certificate",
                        value: viewModel.website.sslEnabled ? "Active" : "Inactive",
                        color: viewModel.website.sslEnabled ? .axSuccess : .axWarning,
                        trend: viewModel.website.sslEnabled ? "Secure" : "Not Secure"
                    )

                    if let visitors = viewModel.website.monthlyVisitors {
                        MetricCard(
                            icon: "person.2.fill",
                            title: "Monthly Visitors",
                            value: "\(visitors)",
                            color: .axAccentBlue,
                            trend: nil
                        )
                    }
                }

                // Quick Info
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    SectionHeader(title: "Site Information", icon: "info.circle.fill")

                    InfoGrid(website: viewModel.website)
                }

                // SSL Details (if enabled)
                if viewModel.website.sslEnabled, let ssl = viewModel.website.sslInfo {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        SectionHeader(title: "SSL Certificate", icon: "lock.shield.fill")

                        SSLOverviewCard(ssl: ssl)
                    }
                }

                // Health Issues (if any)
                if !viewModel.website.healthIssues.isEmpty {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        SectionHeader(title: "Health Issues", icon: "exclamationmark.triangle.fill")

                        ForEach(viewModel.website.healthIssues) { issue in
                            HealthIssueRow(issue: issue)
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Domain Manager View

    private var domainManagerView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Port Configuration
                ConfigCard(
                    icon: "arrow.left.arrow.right.circle.fill",
                    title: "Listening Port",
                    description: "Configure the internal port for this website"
                ) {
                    HStack(spacing: AXSpacing.md) {
                        TextField("Port", value: $viewModel.customPort, formatter: NumberFormatter())
                            .textFieldStyle(AXTextFieldStyle())
                            .frame(width: 120)

                        Button(action: { Task { await viewModel.updatePort() } }) {
                            HStack(spacing: 6) {
                                if viewModel.isUpdatingPort {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                }
                                Text("Update Port")
                                    .font(AXTypography.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(viewModel.isUpdatingPort ? Color.axTextMuted : Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.isUpdatingPort)
                    }
                }

                // Domain Aliases
                ConfigCard(
                    icon: "link.circle.fill",
                    title: "Domain Aliases",
                    description: "Additional domains pointing to this website"
                ) {
                    if viewModel.website.aliases.isEmpty {
                        EmptyStateMessage(
                            icon: "link.badge.plus",
                            message: "No domain aliases configured"
                        )
                    } else {
                        VStack(spacing: AXSpacing.xs) {
                            ForEach(viewModel.website.aliases, id: \.self) { alias in
                                AliasRow(alias: alias)
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private var siteDirectoryView: some View {
        VStack(spacing: AXSpacing.xl) {
            Image(systemName: "folder.fill.badge.gearshape")
                .font(.system(size: 70))
                .foregroundColor(.axAccentBlue.opacity(0.3))
                .padding(.top, 60)

            VStack(spacing: AXSpacing.sm) {
                Text("Site Directory")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Text(viewModel.website.documentRoot ?? "/var/www/html")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }

            Button(action: { /* Future: Open file browser */ }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "folder.badge.plus")
                    Text("Browse Files")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.md)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var urlRewritesView: some View {
        URLRewriteSection(viewModel: viewModel.urlRewriteVM)
    }

    private var sslTlsView: some View {
        SSLManagementSection(viewModel: viewModel.sslManagementVM)
    }

    private var phpSettingsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                ConfigCard(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: "PHP Version",
                    description: "Select PHP-FPM version for this website"
                ) {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        if viewModel.isLoadingPHPVersions {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Loading PHP versions...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.axTextSecondary)
                            }
                            .padding()
                        } else if viewModel.installedPHPVersions.isEmpty {
                            // Empty state
                            VStack(spacing: AXSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.axWarning)
                                Text("No PHP versions found")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.axTextPrimary)
                                Text("PHP may not be installed on this server")
                                    .font(.system(size: 11))
                                    .foregroundColor(.axTextSecondary)
                            }
                            .padding(AXSpacing.lg)
                            .frame(maxWidth: .infinity)
                            .background(Color.axWarning.opacity(0.05))
                            .cornerRadius(AXCornerRadius.sm)
                        } else {
                            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                                Text("Current Version")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.axTextSecondary)

                                Picker("PHP Version", selection: $viewModel.phpVersion) {
                                    ForEach(viewModel.installedPHPVersions, id: \.self) { version in
                                        Text("PHP \(version)")
                                            .tag(version)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, 6)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }

                        if !viewModel.installedPHPVersions.isEmpty {
                            Divider()
                                .padding(.vertical, AXSpacing.xs)

                            Button(action: { Task { await viewModel.saveConfiguration() } }) {
                                HStack(spacing: 6) {
                                    if viewModel.isSavingConfig {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 11))
                                    }
                                    Text("Save PHP Configuration")
                                        .font(AXTypography.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, AXSpacing.lg)
                                .padding(.vertical, AXSpacing.sm)
                                .background(viewModel.isSavingConfig ? Color.axTextMuted : Color.axSuccess)
                                .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(viewModel.isSavingConfig)
                        }
                    }
                }

                // PHP Info Card
                if !viewModel.installedPHPVersions.isEmpty {
                    ConfigCard(
                        icon: "info.circle.fill",
                        title: "Available Versions",
                        description: "All PHP versions installed on this server"
                    ) {
                        VStack(spacing: AXSpacing.xs) {
                            ForEach(viewModel.installedPHPVersions, id: \.self) { version in
                                HStack {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.axAccentBlue)

                                    Text("PHP \(version)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)

                                    Spacer()

                                    if version == viewModel.phpVersion {
                                        Text("Active")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.axSuccess)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.axSuccess.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, AXSpacing.sm)
                                .background(version == viewModel.phpVersion ? Color.axAccentBlue.opacity(0.05) : Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            // Load PHP versions when the view appears
            if viewModel.installedPHPVersions.isEmpty && !viewModel.isLoadingPHPVersions {
                Task {
                    await viewModel.fetchInstalledPHPVersions()
                }
            }
        }
    }

    private var trafficControlView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Active Connections
                HStack(spacing: AXSpacing.md) {
                    MetricCard(
                        icon: "bolt.fill",
                        title: "Active Connections",
                        value: "\(viewModel.activeConnections)",
                        color: .axAccentBlue,
                        trend: "Live"
                    )

                    MetricCard(
                        icon: "chart.bar.fill",
                        title: "Total Requests",
                        value: "N/A",
                        color: .axSuccess,
                        trend: nil
                    )
                }

                // Connection List
                if !viewModel.connectionList.isEmpty {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        SectionHeader(title: "Active Connections", icon: "network")

                        VStack(spacing: AXSpacing.xs) {
                            ForEach(viewModel.connectionList) { connection in
                                ConnectionRow(connection: connection)
                            }
                        }
                    }
                } else {
                    EmptyStateCard(
                        icon: "wifi.slash",
                        title: "No Active Connections",
                        message: "No visitors are currently connected to your website"
                    )
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private var logsView: some View {
        AdvancedLogsView(
            websiteDomain: viewModel.website.domain,
            serverId: viewModel.serverId
        )
    }

    // MARK: - Helper Functions

    private func refreshCurrentSection() async {
        switch selectedItem {
        case .overview:
            await viewModel.loadWebsiteDetails()
        case .logs:
            await viewModel.fetchLogs()
        case .trafficControl:
            await viewModel.fetchRealTimeStats()
        default:
            await viewModel.loadWebsiteDetails()
        }
    }
}

// MARK: - Premium Components

struct PremiumSidebarButton: View {
    let item: ModernSidebarItem
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(isSelected ? Color.axAccentBlue.opacity(0.15) : Color.axBackground.opacity(isHovered ? 0.5 : 0))
                        .frame(width: 32, height: 32)

                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                }

                // Title
                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)

                Spacer()

                // Selection Indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.axAccentBlue)
                        .frame(width: 3, height: 16)
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axAccentBlue.opacity(0.05) : (isHovered ? Color.axBackground.opacity(0.5) : Color.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let trend: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.axAccentBlue)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.axTextPrimary)
        }
    }
}

struct ConfigCard<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    let content: () -> Content

    init(icon: String, title: String, description: String, @ViewBuilder content: @escaping () -> Content) {
        self.icon = icon
        self.title = title
        self.description = description
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axAccentBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextTertiary)
                }
            }

            content()
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

struct InfoGrid: View {
    let website: WebsiteInfo

    var body: some View {
        VStack(spacing: AXSpacing.xs) {
            InfoRow(label: "Document Root", value: website.documentRoot ?? "Not set")
            InfoRow(label: "Runtime", value: website.runtime.rawValue)
            InfoRow(label: "Disk Usage", value: website.formattedDiskUsage)
            InfoRow(label: "Bandwidth", value: website.formattedBandwidth)
            if let deployed = website.lastDeployed {
                InfoRow(label: "Last Deployed", value: deployed.formatted())
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.axTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextPrimary)
        }
        .padding(.vertical, 4)
    }
}

struct SSLOverviewCard: View {
    let ssl: SSLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Provider")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                    Text(ssl.provider.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                    Text(ssl.status.rawValue.capitalized)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ssl.status == .active ? .axSuccess : .axWarning)
                }
            }

            if ssl.isExpiringSoon, let days = ssl.daysUntilExpiry {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.axWarning)
                    Text("Certificate expires in \(days) days")
                        .font(.system(size: 12))
                        .foregroundColor(.axWarning)
                }
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axWarning.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

struct HealthIssueRow: View {
    let issue: WebsiteHealthIssue

    var body: some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            Image(systemName: severityIcon)
                .font(.system(size: 16))
                .foregroundColor(severityColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Text(issue.description)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)

                if let recommendation = issue.recommendation {
                    Text(recommendation)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextTertiary)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(AXSpacing.md)
        .background(severityColor.opacity(0.05))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(severityColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var severityIcon: String {
        switch issue.severity {
        case .critical: return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
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

struct AliasRow: View {
    let alias: String

    var body: some View {
        HStack {
            Image(systemName: "link")
                .font(.system(size: 11))
                .foregroundColor(.axAccentBlue)

            Text(alias)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.axTextPrimary)

            Spacer()
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.sm)
    }
}

struct ConnectionRow: View {
    let connection: DetailedConnection

    var body: some View {
        HStack {
            Image(systemName: "wifi")
                .font(.system(size: 12))
                .foregroundColor(.axAccentBlue)

            Text(connection.ip)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.axTextPrimary)

            Spacer()

            Text("\(connection.count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.axAccentBlue)
                .cornerRadius(6)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

struct EmptyStateMessage: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.axTextTertiary)

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.axTextSecondary)
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.sm)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.axTextTertiary.opacity(0.5))

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AXSpacing.xxl)
        .frame(maxWidth: .infinity)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }
}
