//
//  ModernWebsitePanel.swift
//  AevonX
//
//  Premium redesigned website control panel with beautiful, modern UI
//  Inspired by best-in-class hosting control panels (cPanel, Plesk, Vercel, Netlify)
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Sidebar Category

enum SidebarCategory: String, CaseIterable, Identifiable {
    case core = "Core"
    case security = "Security"
    case performance = "Performance"
    case tools = "Tools"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .core: return "pin.fill"
        case .security: return "lock.fill"
        case .performance: return "bolt.fill"
        case .tools: return "wrench.fill"
        }
    }
}

// MARK: - Sidebar Items

enum ModernSidebarItem: String, CaseIterable, Identifiable {
    // Core
    case overview = "Overview"
    case domainManager = "Domain"
    case siteDirectory = "Site Directory"
    case serverConfig = "Server Config"
    case runtimeConfig = "Runtime Config"
    // Security
    case sslTls = "SSL/TLS"
    case siteSecurity = "Site Security"
    case httpHeaders = "HTTP Headers"
    // Performance
    case cacheManager = "Cache Manager"
    case performance = "Performance"
    case monitoring = "Monitoring"
    // Tools
    case quickActions = "Quick Actions"
    case gitSource = "Git & Deploy"
    case urlRewrites = "URL Rewrites"
    case backupRestore = "Backups"
    case cloneMigrate = "Clone & Migrate"
    case databaseLink = "Database Link"
    case envVariables = "Environment"
    case processManager = "Process Manager"
    case logs = "Logs"

    var id: String { self.rawValue }

    var category: SidebarCategory {
        switch self {
        case .overview, .domainManager, .siteDirectory, .serverConfig, .runtimeConfig: return .core
        case .sslTls, .siteSecurity, .httpHeaders: return .security
        case .cacheManager, .performance, .monitoring: return .performance
        case .quickActions, .gitSource, .urlRewrites, .backupRestore, .cloneMigrate, .databaseLink, .envVariables, .processManager, .logs: return .tools
        }
    }

    var icon: String {
        switch self {
        case .overview: return "house.fill"
        case .domainManager: return "globe.americas.fill"
        case .siteDirectory: return "folder.fill"
        case .serverConfig: return "doc.badge.gearshape.fill"
        case .runtimeConfig: return "chevron.left.forwardslash.chevron.right"
        case .sslTls: return "lock.shield.fill"
        case .siteSecurity: return "shield.lefthalf.filled"
        case .httpHeaders: return "text.badge.plus"
        case .cacheManager: return "bolt.circle.fill"
        case .performance: return "gauge.with.dots.needle.67percent"
        case .monitoring: return "chart.xyaxis.line"
        case .quickActions: return "bolt.fill"
        case .gitSource: return "arrow.triangle.branch"
        case .urlRewrites: return "arrow.uturn.right"
        case .backupRestore: return "archivebox.fill"
        case .cloneMigrate: return "doc.on.doc.fill"
        case .databaseLink: return "cylinder.fill"
        case .envVariables: return "key.fill"
        case .processManager: return "gearshape.2.fill"
        case .logs: return "text.alignleft"
        }
    }

    var color: Color {
        switch self {
        case .overview: return .axSuccess
        case .domainManager: return .cyan
        case .siteDirectory: return .orange
        case .serverConfig: return .indigo
        case .runtimeConfig: return .purple
        case .sslTls: return .axSuccess
        case .siteSecurity: return .red
        case .httpHeaders: return .teal
        case .cacheManager: return .yellow
        case .performance: return .pink
        case .monitoring: return .mint
        case .quickActions: return .axAccentBlue
        case .gitSource: return .purple
        case .urlRewrites: return .orange
        case .backupRestore: return .indigo
        case .cloneMigrate: return .cyan
        case .databaseLink: return .teal
        case .envVariables: return .yellow
        case .processManager: return .red
        case .logs: return .mint
        }
    }

    func displayName(for runtime: RuntimeType) -> String {
        switch self {
        case .runtimeConfig:
            switch runtime {
            case .php: return "PHP Config"
            case .nodejs: return "Node.js Config"
            case .python: return "Python Config"
            case .ruby: return "Ruby Config"
            case .docker: return "Docker Config"
            case .static: return "Site Config"
            }
        default:
            return self.rawValue
        }
    }

    func icon(for runtime: RuntimeType) -> String {
        switch self {
        case .runtimeConfig: return runtime.icon
        default: return self.icon
        }
    }

    func description(for runtime: RuntimeType) -> String {
        switch self {
        case .overview: return "Quick status & health score"
        case .domainManager: return "Domains, aliases, subdomains & DNS"
        case .siteDirectory: return "Browse and manage files"
        case .serverConfig: return "Nginx/Apache site config editor"
        case .runtimeConfig:
            switch runtime {
            case .php: return "PHP version & extensions"
            case .nodejs: return "Node.js version & packages"
            case .python: return "Python version & packages"
            default: return "Runtime configuration"
            }
        case .sslTls: return "SSL certificates & HTTPS"
        case .siteSecurity: return "Hotlink, rate-limit, bot block"
        case .httpHeaders: return "CORS, CSP, security headers"
        case .cacheManager: return "FastCGI, Redis, browser cache"
        case .performance: return "Speed analysis & nginx tuning"
        case .monitoring: return "Uptime, traffic & analytics"
        case .gitSource: return "Git, build & deploy pipeline"
        case .urlRewrites: return "Redirect & rewrite rules"
        case .quickActions: return "Quick one-click server actions"
        case .backupRestore: return "Manual & scheduled backups"
        case .cloneMigrate: return "Clone, staging & migration"
        case .databaseLink: return "Link DB & connection strings"
        case .envVariables: return "Environment variables (.env)"
        case .processManager: return "PM2/Supervisor process control"
        case .logs: return "Log viewer, search & filtering"
        }
    }

    /// Returns sidebar items organized by category for the given runtime
    static func categorizedItems(for runtime: RuntimeType) -> [(SidebarCategory, [Self])] {
        var core: [Self] = [.overview, .domainManager, .siteDirectory, .serverConfig]
        let security: [Self] = [.sslTls, .siteSecurity, .httpHeaders]
        let perf: [Self] = [.cacheManager, .performance, .monitoring]
        var tools: [Self] = [.quickActions, .gitSource, .urlRewrites, .backupRestore, .cloneMigrate, .databaseLink]

        switch runtime {
        case .php:
            core.append(.runtimeConfig)
        case .nodejs, .python, .ruby, .docker:
            core.append(.runtimeConfig)
            tools.append(contentsOf: [.processManager, .envVariables])
        case .static:
            break
        }

        tools.append(contentsOf: [.logs])

        return [
            (.core, core),
            (.security, security),
            (.performance, perf),
            (.tools, tools),
        ]
    }

    /// Flat list for compatibility
    static func items(for runtime: RuntimeType) -> [Self] {
        categorizedItems(for: runtime).flatMap { $0.1 }
    }
}

// MARK: - Modern Website Panel

struct ModernWebsitePanel: View {
    @ObservedObject var viewModel: WebsiteDetailViewModel
    var onBack: () -> Void
    var initialItem: ModernSidebarItem = .overview

    @State private var selectedItem: ModernSidebarItem = .overview
    @State private var isHoveringBack = false
    @State private var showingDirectoryBrowser = false
    @State private var gitVM: GitViewModel?
    @State private var sectionFactory: WebsiteSectionFactory?

    /// Lazy factory for ViewModel caching across sidebar navigation
    private func getFactory() -> WebsiteSectionFactory {
        if let factory = sectionFactory {
            return factory
        }
        let factory = WebsiteSectionFactory(
            serverId: viewModel.serverId ?? "",
            domain: viewModel.website.domain,
            docRoot: viewModel.website.documentRoot ?? "/var/www/\(viewModel.website.domain)",
            runtime: viewModel.website.runtime
        )
        DispatchQueue.main.async { self.sectionFactory = factory }
        return factory
    }

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
            selectedItem = initialItem
            Task { await viewModel.loadWebsiteDetails() }
        }
    }

    // MARK: - Premium Sidebar

    private var premiumSidebar: some View {
        AXSidebarContainer(
            width: 260,
            header: {
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
            },
            items: {
                ForEach(ModernSidebarItem.categorizedItems(for: viewModel.website.runtime), id: \.0) { category, items in
                    AXSidebarCategoryHeader(title: category.rawValue, icon: category.icon)
                    ForEach(items) { item in
                        AXSidebarRow(
                            icon: item.icon(for: viewModel.website.runtime),
                            title: item.displayName(for: viewModel.website.runtime),
                            color: item.color,
                            isSelected: selectedItem == item,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedItem = item
                                }
                            }
                        )
                    }
                }
            },
            footer: {
                sidebarFooter
            }
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
                    Text(viewModel.website.domain)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(1)
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
                Text(selectedItem.displayName(for: viewModel.website.runtime))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Text(selectedItem.description(for: viewModel.website.runtime))
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
                
                // Action Menu (premium popover)
                AXActionMenu(sections: [
                    AXMenuSection("Server", items: [
                        AXMenuItem("Edit Nginx Config", icon: "doc.text", color: .axAccentBlue) {
                            selectedItem = .serverConfig
                        },
                        AXMenuItem(
                            viewModel.website.runtime == .php ? "Restart PHP-FPM" : (viewModel.website.runtime == .nodejs ? "Restart PM2" : "Restart Service"),
                            icon: "arrow.clockwise",
                            color: .orange
                        ) {
                            Task {
                                guard let serverId = viewModel.serverId else { return }
                                let service = SiteQuickActionsService.shared
                                if viewModel.website.runtime == .php {
                                    try? await service.restartPHPFPM(version: viewModel.phpVersion, serverId: serverId)
                                    GlobalToastManager.shared.showSuccess("PHP-FPM restarted")
                                } else if viewModel.website.runtime == .nodejs {
                                    try? await service.restartPM2(serverId: serverId)
                                    GlobalToastManager.shared.showSuccess("PM2 restarted")
                                }
                            }
                        },
                    ]),
                    AXMenuSection("Management", items: [
                        AXMenuItem("Quick Actions", icon: "bolt.fill", color: .axAccentBlue) {
                            selectedItem = .quickActions
                        },
                        AXMenuItem("Backup Site", icon: "archivebox", color: .axAccentGreen) {
                            selectedItem = .backupRestore
                        },
                    ]),
                    AXMenuSection(items: [
                        AXMenuItem("Delete Website", icon: "trash", isDestructive: true) {
                            Task {
                                guard let serverId = viewModel.serverId else { return }
                                try? await WebsiteLifecycleService.shared.deleteWebsite(
                                    websiteId: viewModel.website.domain,
                                    serverId: serverId
                                )
                                onBack()
                            }
                        },
                    ]),
                ])
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
            DomainSection(
                viewModel: getFactory().advancedDomainVM
            )
        case .siteDirectory:
            siteDirectoryView
        case .serverConfig:
            SiteConfigSection(
                viewModel: SiteConfigViewModel(
                    serverId: viewModel.serverId ?? "",
                    domain: viewModel.website.domain
                )
            )
        case .gitSource:
            gitSourceView
        case .urlRewrites:
            urlRewritesView
        case .sslTls:
            sslTlsView
        case .siteSecurity:
            SiteSecuritySection(
                viewModel: SiteSecurityViewModel(
                    serverId: viewModel.serverId ?? "",
                    domain: viewModel.website.domain,
                    docRoot: viewModel.website.documentRoot ?? "/var/www/\(viewModel.website.domain)"
                )
            )
        case .httpHeaders:
            HeadersSection(
                viewModel: HeadersViewModel(
                    serverId: viewModel.serverId ?? "",
                    domain: viewModel.website.domain
                )
            )
        case .cacheManager:
            CacheSection(
                viewModel: CacheViewModel(
                    serverId: viewModel.serverId ?? "",
                    domain: viewModel.website.domain
                )
            )
        case .performance:
            UnifiedPerformanceSection(
                serverId: viewModel.serverId ?? "",
                domain: viewModel.website.domain,
                docRoot: viewModel.website.documentRoot ?? "/var/www/\(viewModel.website.domain)",
                tuningVM: getFactory().performanceTuningVM
            )
        case .monitoring:
            MonitoringSection(
                viewModel: MonitoringViewModel(
                    serverId: viewModel.serverId ?? "",
                    domain: viewModel.website.domain
                )
            )
        case .backupRestore:
            UnifiedBackupSection(
                backupVM: getFactory().backupVM,
                scheduledVM: getFactory().scheduledBackupVM
            )
        case .databaseLink:
            DatabaseLinkSection(
                serverId: viewModel.serverId ?? "",
                domain: viewModel.website.domain
            )
        case .cloneMigrate:
            SiteCloningSection(
                viewModel: getFactory().siteCloningVM
            )
        case .runtimeConfig:
            runtimeConfigView
        case .quickActions:
            QuickActionsSection(
                viewModel: getFactory().quickActionsVM
            )
        case .processManager:
            processManagerView
        case .envVariables:
            envVariablesView
        case .logs:
            EnhancedLogsSection(
                viewModel: getFactory().logsVM
            )
        }
    }

    // MARK: - Overview View (NEW)

    private var overviewView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Status Summary Cards
                HStack(spacing: AXSpacing.md) {
                    AXStatCard(
                        icon: "globe",
                        label: "Domain Status",
                        value: viewModel.website.status.rawValue.capitalized,
                        color: statusColor
                    )

                    AXStatCard(
                        icon: "lock.shield.fill",
                        label: "SSL Certificate",
                        value: viewModel.website.sslEnabled ? "Active" : "Inactive",
                        color: viewModel.website.sslEnabled ? .axSuccess : .axWarning
                    )

                    if let visitors = viewModel.website.monthlyVisitors {
                        AXStatCard(
                            icon: "person.2.fill",
                            label: "Monthly Visitors",
                            value: "\(visitors)",
                            color: .axAccentBlue
                        )
                    }
                }

                // Quick Info
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    AXSectionTitle(title: "Site Information", icon: "info.circle.fill")

                    InfoGrid(website: viewModel.website)
                }

                // SSL Details (if enabled)
                if viewModel.website.sslEnabled, let ssl = viewModel.website.sslInfo {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "SSL Certificate", icon: "lock.shield.fill")

                        SSLOverviewCard(ssl: ssl)
                    }
                }

                // Health Issues (if any)
                if !viewModel.website.healthIssues.isEmpty {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "Health Issues", icon: "exclamationmark.triangle.fill")

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
                AXConfigCard(
                    icon: "arrow.left.arrow.right.circle.fill",
                    title: "Listening Port",
                    subtitle: "Configure the internal port for this website"
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
                AXConfigCard(
                    icon: "link.circle.fill",
                    title: "Domain Aliases",
                    subtitle: "Additional domains pointing to this website"
                ) {
                    if viewModel.website.aliases.isEmpty {
                        AXPlaceholder(
                            icon: "link.badge.plus",
                            title: "No domain aliases configured"
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
        VStack(spacing: 0) {
            // Current Document Root Card
            AXCard(padding: AXSpacing.lg) {
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "folder.fill.badge.gearshape")
                        .font(.system(size: 28))
                        .foregroundColor(.axAccentBlue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Document Root")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                        Text(viewModel.documentRoot.isEmpty ? "/var/www/html" : viewModel.documentRoot)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                    }

                    Spacer()

                    if viewModel.isSavingConfig {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.top, AXSpacing.lg)

            // Directory Browser
            AXCard(padding: 0) {
                VStack(spacing: 0) {
                    // Browser Toolbar
                    HStack(spacing: AXSpacing.md) {
                        // Back Button
                        Button(action: { viewModel.backToParent() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(viewModel.currentBrowsingPath == "/" ? .axTextMuted : .axTextPrimary)
                                .frame(width: 28, height: 28)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.currentBrowsingPath == "/")

                        // Up Button
                        Button(action: { viewModel.backToParent() }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(viewModel.currentBrowsingPath == "/" ? .axTextMuted : .axTextPrimary)
                                .frame(width: 28, height: 28)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.currentBrowsingPath == "/")

                        // Path Breadcrumb
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 2) {
                                let pathComponents = viewModel.currentBrowsingPath.split(separator: "/")
                                
                                // Root
                                Button(action: {
                                    viewModel.currentBrowsingPath = "/"
                                    Task { await viewModel.fetchBrowsingItems(path: "/") }
                                }) {
                                    Text("/")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.axAccentBlue)
                                }
                                .buttonStyle(PlainButtonStyle())

                                ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 8))
                                        .foregroundColor(.axTextMuted)
                                    
                                    Button(action: {
                                        let targetPath = "/" + pathComponents.prefix(index + 1).joined(separator: "/")
                                        viewModel.currentBrowsingPath = targetPath
                                        Task { await viewModel.fetchBrowsingItems(path: targetPath) }
                                    }) {
                                        Text(String(component))
                                            .font(.system(size: 12, weight: index == pathComponents.count - 1 ? .bold : .medium, design: .monospaced))
                                            .foregroundColor(index == pathComponents.count - 1 ? .axTextPrimary : .axAccentBlue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }

                        Spacer()

                        // Refresh
                        Button(action: {
                            Task { await viewModel.fetchBrowsingItems(path: viewModel.currentBrowsingPath) }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextSecondary)
                                .frame(width: 28, height: 28)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Set as Root
                        Button(action: {
                            viewModel.selectCurrentDirectory()
                            Task { await viewModel.saveConfiguration() }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                Text("Set as Root")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, 6)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(AXSpacing.md)
                    .background(Color.axBackgroundTertiary)

                    Divider().background(Color.axBorder)

                    // Directory Content
                    if viewModel.isLoadingBrowsingItems {
                        VStack(spacing: AXSpacing.md) {
                            ProgressView()
                            Text("Loading directories...")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else if viewModel.browsingItems.isEmpty {
                        VStack(spacing: AXSpacing.md) {
                            Image(systemName: "folder")
                                .font(.system(size: 36))
                                .foregroundColor(.axTextMuted)
                            Text("No subdirectories found")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextMuted)
                            Text(viewModel.currentBrowsingPath)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextTertiary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 1) {
                                ForEach(viewModel.browsingItems, id: \.self) { folder in
                                    Button(action: { viewModel.navigateToPath(folder) }) {
                                        HStack(spacing: AXSpacing.md) {
                                            Image(systemName: "folder.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.axWarning)
                                                .frame(width: 24)

                                            Text(folder)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.axTextPrimary)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.axTextMuted)
                                        }
                                        .padding(.horizontal, AXSpacing.lg)
                                        .padding(.vertical, AXSpacing.md)
                                        .background(Color.axBackground)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .onHover { hovering in
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                                }
                            }
                        }
                        .frame(minHeight: 200)
                    }
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.top, AXSpacing.md)

            Spacer()
        }
        .onAppear {
            viewModel.startBrowsing(initialPath: viewModel.website.documentRoot)
        }
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
                // Current PHP Version
                AXConfigCard(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: "PHP Version",
                    subtitle: "Active PHP-FPM version for this website"
                ) {
                    if viewModel.isLoadingPHPVersions {
                        HStack {
                            ProgressView().scaleEffect(0.7)
                            Text("Loading PHP versions...")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextSecondary)
                        }
                        .padding()
                    } else if viewModel.installedPHPVersions.isEmpty {
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
                        // Current active version display
                        HStack {
                            Text("Current:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.axTextSecondary)
                            Text("PHP \(viewModel.phpVersion)")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.axSuccess)
                        }
                        .padding(.bottom, AXSpacing.sm)
                    }
                }

                // Version list with one-click switching
                if !viewModel.installedPHPVersions.isEmpty {
                    AXConfigCard(
                        icon: "list.bullet",
                        title: "Switch PHP Version",
                        subtitle: "Click 'Switch' to change PHP-FPM for this website only"
                    ) {
                        VStack(spacing: AXSpacing.xs) {
                            ForEach(viewModel.installedPHPVersions, id: \.self) { version in
                                HStack {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.axAccentBlue)

                                    Text("PHP \(version)")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)

                                    Spacer()

                                    if version == viewModel.phpVersion {
                                        Text("Active")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.axSuccess)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.axSuccess.opacity(0.1))
                                            .cornerRadius(4)
                                    } else {
                                        Button(action: {
                                            Task { await viewModel.switchWebsitePHPVersion(to: version) }
                                        }) {
                                            HStack(spacing: 4) {
                                                if viewModel.isSavingConfig {
                                                    ProgressView().scaleEffect(0.5)
                                                } else {
                                                    Image(systemName: "arrow.right.circle.fill")
                                                        .font(.system(size: 10))
                                                }
                                                Text("Switch")
                                                    .font(.system(size: 10, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.axAccentBlue)
                                            .cornerRadius(4)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(viewModel.isSavingConfig)
                                    }
                                }
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, AXSpacing.sm)
                                .background(version == viewModel.phpVersion ? Color.axSuccess.opacity(0.03) : Color.axBackground.opacity(0.5))
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
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
                    AXStatCard(
                        icon: "bolt.fill",
                        label: "Active Connections",
                        value: "\(viewModel.activeConnections)",
                        color: .axAccentBlue
                    )

                    AXStatCard(
                        icon: "chart.bar.fill",
                        label: "Total Requests",
                        value: "N/A",
                        color: .axSuccess
                    )
                }

                // Connection List
                if !viewModel.connectionList.isEmpty {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "Active Connections", icon: "network")

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
        AXAdvancedLogsView(
            source: .website(domain: viewModel.website.domain),
            serverId: viewModel.serverId
        )
    }

    // MARK: - Git Source View

    private var gitSourceView: some View {
        Group {
            if let serverId = viewModel.serverId {
                let docRoot = viewModel.website.documentRoot ?? "/var/www/\(viewModel.website.domain)"
                let vm = gitVM ?? {
                    let newVM = GitViewModel(serverId: serverId, documentRoot: docRoot)
                    DispatchQueue.main.async { self.gitVM = newVM }
                    return newVM
                }()
                GitTab(vm: vm)
            } else {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28))
                        .foregroundColor(.axWarning)
                    Text("Server not connected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Runtime Config View (Dynamic)

    @ViewBuilder
    private var runtimeConfigView: some View {
        switch viewModel.website.runtime {
        case .php:
            phpSettingsView
        case .nodejs:
            NodeJSConfigTab(
                serverId: viewModel.serverId,
                appPath: viewModel.website.documentRoot ?? "/var/www/\(viewModel.website.domain)"
            )
        case .python:
            pythonConfigView
        default:
            genericRuntimeView
        }
    }


    // MARK: - Python Config View

    private var pythonConfigView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXConfigCard(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: "Python Runtime",
                    subtitle: "Python version and WSGI/ASGI configuration"
                ) {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundColor(.axWarning)
                            Text("Python")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.axTextPrimary)
                            Text("(detection pending)")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextTertiary)
                        }
                        Text("Full Python version management coming soon.")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Generic Runtime View

    private var genericRuntimeView: some View {
        VStack(spacing: AXSpacing.xl) {
            AXEmptyState(
                icon: "gearshape",
                title: "Runtime Configuration",
                description: "Configuration for \(viewModel.website.runtime.rawValue) is not yet available."
            )
        }
    }

    // MARK: - Process Manager View

    private var processManagerView: some View {
        ProcessManagerTab(
            serverId: viewModel.serverId,
            appName: viewModel.website.name,
            appPath: viewModel.website.documentRoot ?? "/var/www/\(viewModel.website.domain)"
        )
    }

    // MARK: - Environment Variables View

    private var envVariablesView: some View {
        EnvVariablesTab(
            serverId: viewModel.serverId,
            appPath: viewModel.website.documentRoot ?? "/var/www/\(viewModel.website.domain)"
        )
    }

    // MARK: - Helper Functions

    private func refreshCurrentSection() async {
        switch selectedItem {
        case .overview:
            await viewModel.loadWebsiteDetails()
        case .logs:
            await viewModel.fetchLogs()
        case .monitoring:
            await viewModel.fetchRealTimeStats()
        default:
            await viewModel.loadWebsiteDetails()
        }
    }
}

// Components moved to Views/Components/WebsitePanelComponents.swift
