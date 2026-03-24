//
//  NginxDetailView.swift
//  AevonX
//
//  Sidebar-driven Nginx detail panel — lazy loading per section.
//  Only loads data when a section is selected. Status loads first.
//

import SwiftUI
import AevonXCoreBridge

struct NginxDetailView: View {
    let serverId: String
    let app: BridgeAppInfo
    var onBack: () -> Void

    @State private var selectedItem: NginxSidebarItem = .overview

    // Section-level loading states
    @State private var statusLoaded = false
    @State private var configsLoaded = false
    @State private var versionsLoaded = false
    @State private var workersLoaded = false
    @State private var modulesLoaded = false

    // Data
    @State private var status: BridgeAppStatus?
    @State private var configs: [BridgeAppConfig] = []
    @State private var versions: [BridgeAppVersion] = []
    @State private var availableVersions: [BridgeAppVersion] = []
    @State private var workers: [BridgeWorkerInfo] = []
    @State private var modules: [BridgeModuleInfo] = []
    @State private var isLoadingSection = false

    private let bridge = ApplicationBridge.shared
    private let nginxGreen = Color(red: 0, green: 0.59, blue: 0.22)

    var body: some View {
        HStack(spacing: 0) {
            nginxSidebar
            Divider().background(Color.axBorder.opacity(0.5))
            VStack(spacing: 0) {
                sectionHeader
                Divider().background(Color.axBorder.opacity(0.3))

                if isLoadingSection {
                    skeletonContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    contentView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.axBackground)
                }
            }
        }
        .background(Color.axBackground)
        .task {
            // Only load status on initial appear — fast!
            await loadStatus()
        }
        .onChange(of: selectedItem) {
            Task { await loadSectionData(for: selectedItem) }
        }
    }

    // MARK: - Lazy Section Loading

    /// Load only status (fast — single SSH command)
    private func loadStatus() async {
        let start = CFAbsoluteTimeGetCurrent()
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadStatus START")

        let json = await bridge.getStatus(serverID: serverId, appID: "nginx")
        let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadStatus took \(ms)ms")

        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<BridgeAppStatus>.self, from: data),
           response.success {
            withAnimation(.easeOut(duration: 0.15)) {
                status = response.data
                statusLoaded = true
            }
        } else {
            CoreLogger.shared.debug("[Perf] NginxDetailView: loadStatus FAILED — response: \(json.prefix(200))")
            statusLoaded = true
        }
    }

    /// Load data for a specific section — only when selected
    private func loadSectionData(for item: NginxSidebarItem) async {
        switch item {
        case .overview:
            if !statusLoaded { await loadStatus() }
        case .config:
            if !configsLoaded { await loadConfigs() }
        case .versions:
            if !versionsLoaded { await loadVersions() }
        case .modules:
            if !modulesLoaded { await loadModules() }
        case .workers:
            if !workersLoaded { await loadWorkers() }
        case .logs, .optimization, .security,
             .performance, .sites, .snapshots, .analytics,
             .cache, .benchmark, .proxy, .doctor:
            break // Self-managed sections
        }
    }

    private func loadConfigs() async {
        isLoadingSection = true
        let start = CFAbsoluteTimeGetCurrent()
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadConfigs START")

        let json = await bridge.getConfigs(serverID: serverId, appID: "nginx")
        let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadConfigs took \(ms)ms")

        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppConfig]>.self, from: data),
           response.success {
            configs = response.data ?? []
        }
        configsLoaded = true
        isLoadingSection = false
    }

    private func loadVersions() async {
        isLoadingSection = true
        let start = CFAbsoluteTimeGetCurrent()
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadVersions START")

        async let installedJSON = bridge.getVersions(serverID: serverId, appID: "nginx")
        async let availableJSON = bridge.getAvailableVersions(appID: "nginx")

        let (installed, available) = await (installedJSON, availableJSON)
        let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadVersions took \(ms)ms")

        if let d = installed.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppVersion]>.self, from: d),
           r.success { versions = r.data ?? [] }

        if let d = available.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppVersion]>.self, from: d),
           r.success { availableVersions = r.data ?? [] }

        versionsLoaded = true
        isLoadingSection = false
    }

    private func loadWorkers() async {
        isLoadingSection = true
        let start = CFAbsoluteTimeGetCurrent()
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadWorkers START")

        let json = await bridge.getWorkers(serverID: serverId, appID: "nginx")
        let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadWorkers took \(ms)ms")

        if let d = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeWorkerInfo]>.self, from: d),
           r.success { workers = r.data ?? [] }

        workersLoaded = true
        isLoadingSection = false
    }

    private func loadModules() async {
        isLoadingSection = true
        let start = CFAbsoluteTimeGetCurrent()
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadModules START")

        let json = await bridge.getModules(serverID: serverId, appID: "nginx")
        let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        CoreLogger.shared.debug("[Perf] NginxDetailView: loadModules took \(ms)ms")

        if let d = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeModuleInfo]>.self, from: d),
           r.success { modules = r.data ?? [] }

        modulesLoaded = true
        isLoadingSection = false
    }

    /// Refresh just the status (after lifecycle actions)
    func refreshStatus() async {
        statusLoaded = false
        await loadStatus()
    }

    // MARK: - Skeleton Placeholder

    private var skeletonContent: some View {
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.lg) {
                ForEach(0..<3, id: \.self) { _ in skeletonCard }
            }
            .padding(.horizontal, AXSpacing.xl)

            VStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in skeletonRow }
            }
            .padding(.horizontal, AXSpacing.xl)

            Spacer()
        }
        .padding(.top, AXSpacing.xl)
        .background(Color.axBackground)
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.axSurface)
                .frame(width: 60, height: 12)
                .shimmer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.axSurface)
                .frame(height: 28)
                .shimmer()
        }
        .padding(AXSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.2), lineWidth: 1)
        )
    }

    private var skeletonRow: some View {
        HStack(spacing: AXSpacing.md) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.axSurface)
                .frame(width: 120, height: 14)
                .shimmer()
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.axSurface)
                .frame(width: 80, height: 14)
                .shimmer()
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Sidebar

    private var nginxSidebar: some View {
        AXSidebarContainer(
            width: 260,
            header: {
                VStack(spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.md) {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.axTextSecondary)
                                .frame(width: 28, height: 28)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [nginxGreen, nginxGreen.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .shadow(color: nginxGreen.opacity(0.4), radius: 8, x: 0, y: 2)

                            Image(systemName: "server.rack")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nginx")
                                .font(AXTypography.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.axTextPrimary)

                            if let version = app.version, !version.isEmpty {
                                Text("v\(version)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.axTextTertiary)
                            }
                        }

                        Spacer()
                    }

                    HStack(spacing: AXSpacing.md) {
                        sidebarStat(icon: "circle.fill",
                                    label: (status?.isRunning ?? app.isRunning) ? "Running" : "Stopped",
                                    color: (status?.isRunning ?? app.isRunning) ? .axSuccess : .axError)
                        sidebarStat(icon: "shippingbox.fill", label: app.version ?? "Unknown",
                                    color: .axAccentBlue)
                    }
                }
                .padding(AXSpacing.lg)
            },
            items: {
                ForEach(NginxSidebarItem.categorizedItems(), id: \.0) { category, items in
                    AXSidebarCategoryHeader(title: category.rawValue, icon: "")
                    ForEach(items) { item in
                        AXSidebarRow(
                            icon: item.icon,
                            title: item.rawValue,
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
            footer: { EmptyView() }
        )
    }

    private func sidebarStat(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 6))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextSecondary)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedItem.rawValue)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Text(selectedItem.description)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Spacer()

            // Refresh button
            AXRefreshButton(isLoading: isLoadingSection) {
                await refreshCurrentSection()
            }

            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill((status?.isRunning ?? app.isRunning) ? Color.axSuccess : Color.axError)
                    .frame(width: 8, height: 8)
                    .shadow(color: (status?.isRunning ?? app.isRunning) ? .axSuccess.opacity(0.5) : .clear, radius: 4)

                Text((status?.isRunning ?? app.isRunning) ? "Running" : "Stopped")
                    .font(AXTypography.caption)
                    .foregroundColor((status?.isRunning ?? app.isRunning) ? .axSuccess : .axError)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill((status?.isRunning ?? app.isRunning) ? Color.axSuccess.opacity(0.08) : Color.axError.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke((status?.isRunning ?? app.isRunning) ? Color.axSuccess.opacity(0.2) : Color.axError.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
        .background(Color.axSurface.opacity(0.5).background(.ultraThinMaterial))
    }

    /// Force-refresh current section
    private func refreshCurrentSection() async {
        switch selectedItem {
        case .overview:
            statusLoaded = false
            await loadStatus()
        case .config:
            configsLoaded = false
            await loadConfigs()
        case .versions:
            versionsLoaded = false
            await loadVersions()
        case .modules:
            modulesLoaded = false
            await loadModules()
        case .workers:
            workersLoaded = false
            await loadWorkers()
        case .logs, .optimization, .security,
             .performance, .sites, .snapshots, .analytics,
             .cache, .benchmark, .proxy, .doctor:
            break
        }
    }

    // MARK: - Content Router — data loaded lazily per section

    @ViewBuilder
    private var contentView: some View {
        switch selectedItem {
        case .overview:
            NginxOverviewSection(serverId: serverId, app: app, status: $status, onAction: { _ in
                Task { await refreshStatus() }
            })
        case .config:
            NginxConfigSection(serverId: serverId, configs: $configs)
        case .versions:
            NginxVersionsSection(
                serverId: serverId,
                installedVersions: versions,
                availableVersions: availableVersions,
                onRefresh: {
                    versionsLoaded = false
                    await loadVersions()
                }
            )
        case .modules:
            NginxModulesSection(modules: modules)
        case .workers:
            NginxWorkersSection(workers: workers)
        case .logs:
            NginxLogsSection(serverId: serverId)
        case .optimization:
            NginxOptimizationSection(serverId: serverId)
        case .security:
            NginxSecuritySection(serverId: serverId)
        case .performance:
            NginxPerformanceScoreSection(serverId: serverId)
        case .sites:
            NginxSitesSection(serverId: serverId)
        case .snapshots:
            NginxSnapshotsSection(serverId: serverId)
        case .analytics:
            NginxAnalyticsSection(serverId: serverId)
        case .cache:
            NginxCacheSection(serverId: serverId)
        case .benchmark:
            NginxBenchmarkSection(serverId: serverId)
        case .proxy:
            NginxProxySection(serverId: serverId)
        case .doctor:
            NginxDoctorSection(serverId: serverId)
        }
    }
}
