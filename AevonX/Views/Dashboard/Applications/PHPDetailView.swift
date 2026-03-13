//
//  PHPDetailView.swift
//  AevonX
//
//  Sidebar-driven PHP-FPM detail panel — lazy loading per section.
//  Only loads data when a section is selected. Status loads first.
//

import SwiftUI
import AevonXCoreBridge

struct PHPDetailView: View {
    let serverId: String
    let app: BridgeAppInfo
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    var onBack: () -> Void

    @State private var selectedItem: PHPSidebarItem = .overview

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
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        HStack(spacing: 0) {
            phpSidebar
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
            await loadStatus()
        }
        .onChange(of: selectedItem) {
            Task { await loadSectionData(for: selectedItem) }
        }
    }

    // MARK: - Lazy Section Loading

    private func loadStatus() async {
        let json = await bridge.getStatus(serverID: serverId, appID: "php-fpm")
        print("[PHP-DEBUG] loadStatus raw JSON: \(json.prefix(500))")
        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<BridgeAppStatus>.self, from: data),
           response.success {
            print("[PHP-DEBUG] loadStatus parsed: isRunning=\(response.data?.isRunning ?? false), state=\(response.data?.state ?? "nil"), pid=\(response.data?.pid ?? -1)")
            withAnimation(.easeOut(duration: 0.15)) {
                status = response.data
                statusLoaded = true
            }
        } else {
            print("[PHP-DEBUG] loadStatus FAILED to parse or success=false")
            statusLoaded = true
        }
    }

    private func loadSectionData(for item: PHPSidebarItem) async {
        switch item {
        case .overview:
            if !statusLoaded { await loadStatus() }
        case .config:
            if !configsLoaded { await loadConfigs() }
        case .versions:
            if !versionsLoaded { await loadVersions() }
        case .workers:
            if !workersLoaded { await loadWorkers() }
        case .extensions:
            if !modulesLoaded { await loadModules() }
        case .logs, .optimization, .security, .performance,
             .snapshots, .pools, .opcache, .doctor,
             .sessions, .xdebug, .composer:
            break // Self-managed sections
        }
    }

    private func loadConfigs() async {
        isLoadingSection = true
        let json = await bridge.getConfigs(serverID: serverId, appID: "php-fpm")
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

        // Installed versions via SSH
        let installedJSON = await bridge.getVersions(serverID: serverId, appID: "php-fpm")
        print("[PHP-DEBUG] getVersions raw: \(installedJSON.prefix(500))")
        if let d = installedJSON.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppVersion]>.self, from: d),
           r.success {
            versions = r.data ?? []
            print("[PHP-DEBUG] installed versions count: \(versions.count), versions: \(versions.map { $0.version })")
        } else {
            print("[PHP-DEBUG] getVersions FAILED to parse")
        }

        // Available versions via SSH-based detection (NOT static catalog)
        let availableJSON = await bridge.detectAvailableVersions(serverID: serverId, appID: "php-fpm")
        print("[PHP-DEBUG] detectAvailableVersions raw: \(availableJSON.prefix(500))")
        if let d = availableJSON.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppVersion]>.self, from: d),
           r.success {
            availableVersions = r.data ?? []
            print("[PHP-DEBUG] available versions count: \(availableVersions.count)")
        } else {
            print("[PHP-DEBUG] detectAvailableVersions FAILED to parse")
        }

        versionsLoaded = true
        isLoadingSection = false
    }

    private func loadWorkers() async {
        isLoadingSection = true
        let json = await bridge.getWorkers(serverID: serverId, appID: "php-fpm")
        if let d = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeWorkerInfo]>.self, from: d),
           r.success { workers = r.data ?? [] }
        workersLoaded = true
        isLoadingSection = false
    }

    private func loadModules() async {
        isLoadingSection = true
        let json = await bridge.getModules(serverID: serverId, appID: "php-fpm")
        if let d = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeModuleInfo]>.self, from: d),
           r.success { modules = r.data ?? [] }
        modulesLoaded = true
        isLoadingSection = false
    }

    func refreshStatus() async {
        statusLoaded = false
        await loadStatus()
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 140, height: 14).shimmer()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                    ForEach(0..<6, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            HStack {
                                RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 80, height: 14).shimmer()
                                Spacer()
                                RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 50, height: 16).shimmer()
                            }
                            RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 60, height: 10).shimmer()
                        }
                        .padding(AXSpacing.lg)
                        .background(Color.axSurface.opacity(0.5))
                        .cornerRadius(AXCornerRadius.lg)
                    }
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    // MARK: - Sidebar

    private var phpSidebar: some View {
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
                                        colors: [phpPurple, phpPurple.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .shadow(color: phpPurple.opacity(0.4), radius: 8, x: 0, y: 2)

                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("PHP-FPM")
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
                ForEach(PHPSidebarItem.categorizedItems(), id: \.0) { category, items in
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
        case .extensions:
            modulesLoaded = false
            await loadModules()
        case .workers:
            workersLoaded = false
            await loadWorkers()
        case .logs, .optimization, .security, .performance,
             .snapshots, .pools, .opcache, .doctor,
             .sessions, .xdebug, .composer:
            break
        }
    }

    // MARK: - Content Router

    @ViewBuilder
    private var contentView: some View {
        switch selectedItem {
        case .overview:
            PHPOverviewSection(serverId: serverId, app: app, status: $status, onAction: { _ in
                Task { await refreshStatus() }
            })
        case .config:
            PHPConfigSection(serverId: serverId, configs: $configs)
        case .versions:
            PHPVersionsSection(
                serverId: serverId,
                installedVersions: versions,
                availableVersions: availableVersions,
                connectionViewModel: connectionViewModel,
                onRefresh: {
                    versionsLoaded = false
                    await loadVersions()
                }
            )
        case .extensions:
            PHPExtensionsSection(serverId: serverId, modules: modules, onRefresh: {
                await loadModules()
            })
        case .workers:
            PHPWorkersSection(serverId: serverId)
        case .logs:
            PHPLogsSection(serverId: serverId)
        case .optimization:
            PHPOptimizationSection(serverId: serverId)
        case .security:
            PHPSecuritySection(serverId: serverId)
        case .performance:
            PHPPerformanceScoreSection(serverId: serverId)
        case .snapshots:
            PHPSnapshotsSection(serverId: serverId)
        case .pools:
            PHPPoolsSection(serverId: serverId)
        case .opcache:
            PHPOPcacheSection(serverId: serverId)
        case .doctor:
            PHPDoctorSection(serverId: serverId)
        case .sessions:
            PHPSessionsSection(serverId: serverId)
        case .xdebug:
            PHPXdebugSection(serverId: serverId)
        case .composer:
            PHPComposerSection(serverId: serverId)
        }
    }
}
