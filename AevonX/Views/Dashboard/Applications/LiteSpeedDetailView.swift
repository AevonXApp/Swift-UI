//
//  LiteSpeedDetailView.swift
//  AevonX
//
//  Sidebar-driven LiteSpeed detail panel — lazy loading per section.
//  Mirrors the ApacheDetailView pattern exactly.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedDetailView: View {
    let serverId: String
    let app: BridgeAppInfo
    var onBack: () -> Void

    @State private var selectedItem: LiteSpeedSidebarItem = .overview

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
    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    var body: some View {
        HStack(spacing: 0) {
            liteSpeedSidebar
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
        .task { await loadStatus() }
        .onChange(of: selectedItem) {
            Task { await loadSectionData(for: selectedItem) }
        }
    }

    // MARK: - Lazy Section Loading

    private func loadStatus() async {
        let json = await bridge.getStatus(serverID: serverId, appID: "litespeed")
        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<BridgeAppStatus>.self, from: data),
           response.success {
            withAnimation(.easeOut(duration: 0.15)) {
                status = response.data
                statusLoaded = true
            }
        } else {
            statusLoaded = true
        }
    }

    private func loadSectionData(for item: LiteSpeedSidebarItem) async {
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
             .sites, .snapshots, .doctor:
            break // Self-managed sections
        }
    }

    private func loadConfigs() async {
        isLoadingSection = true
        let json = await bridge.getConfigs(serverID: serverId, appID: "litespeed")
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
        async let installedJSON = bridge.getVersions(serverID: serverId, appID: "litespeed")
        async let availableJSON = bridge.getAvailableVersions(appID: "litespeed")
        let (installed, available) = await (installedJSON, availableJSON)

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
        let json = await bridge.getWorkers(serverID: serverId, appID: "litespeed")
        if let d = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[BridgeWorkerInfo]>.self, from: d),
           r.success { workers = r.data ?? [] }
        workersLoaded = true
        isLoadingSection = false
    }

    private func loadModules() async {
        isLoadingSection = true
        let json = await bridge.getModules(serverID: serverId, appID: "litespeed")
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
        VStack(spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.lg) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 60, height: 12).shimmer()
                        RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(height: 28).shimmer()
                    }
                    .padding(AXSpacing.lg).frame(maxWidth: .infinity)
                    .background(Color.axSurface.opacity(0.5)).cornerRadius(AXCornerRadius.lg)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
                }
            }.padding(.horizontal, AXSpacing.xl)
            VStack(spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: AXSpacing.md) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 120, height: 14).shimmer()
                        Spacer()
                        RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 80, height: 14).shimmer()
                    }.padding(AXSpacing.md).background(Color.axSurface.opacity(0.3)).cornerRadius(AXCornerRadius.md)
                }
            }.padding(.horizontal, AXSpacing.xl)
            Spacer()
        }
        .padding(.top, AXSpacing.xl).background(Color.axBackground)
    }

    // MARK: - Sidebar

    private var liteSpeedSidebar: some View {
        AXSidebarContainer(
            width: 260,
            header: {
                VStack(spacing: AXSpacing.md) {
                    HStack(spacing: AXSpacing.md) {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(AXTypography.subheadline).fontWeight(.bold)
                                .foregroundColor(.axTextSecondary)
                                .frame(width: 28, height: 28)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                        }.buttonStyle(PlainButtonStyle())

                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [lsGreen, lsGreen.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 40, height: 40)
                                .shadow(color: lsGreen.opacity(0.4), radius: 8, x: 0, y: 2)
                            Image(systemName: "bolt.fill")
                                .font(AXTypography.title2).fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("LiteSpeed")
                                .font(AXTypography.subheadline).fontWeight(.bold)
                                .foregroundColor(.axTextPrimary)
                            if let version = app.version, !version.isEmpty {
                                Text("v\(version)")
                                    .font(AXTypography.monoSm)
                                    .foregroundColor(.axTextTertiary)
                            }
                        }
                        Spacer()
                    }

                    HStack(spacing: AXSpacing.md) {
                        sidebarStat(icon: "circle.fill",
                                    label: (status?.isRunning ?? app.isRunning) ? L10n.Status.running : L10n.Status.stopped,
                                    color: (status?.isRunning ?? app.isRunning) ? .axSuccess : .axError)
                        sidebarStat(icon: "shippingbox.fill", label: app.version ?? L10n.Status.unknown, color: .axAccentBlue)
                    }
                }
                .padding(AXSpacing.lg)
            },
            items: {
                ForEach(LiteSpeedSidebarItem.categorizedItems(), id: \.0) { category, items in
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
            Image(systemName: icon).font(AXTypography.monoXxxs).foregroundColor(color)
            Text(label).font(AXTypography.caption).foregroundColor(.axTextSecondary)
        }
        .padding(.horizontal, AXSpacing.sm).padding(.vertical, 4)
        .background(color.opacity(0.08)).cornerRadius(AXCornerRadius.sm)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedItem.rawValue)
                    .font(AXTypography.title).fontWeight(.bold)
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
                Text((status?.isRunning ?? app.isRunning) ? L10n.Status.running : L10n.Status.stopped)
                    .font(AXTypography.caption)
                    .foregroundColor((status?.isRunning ?? app.isRunning) ? .axSuccess : .axError)
            }
            .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill((status?.isRunning ?? app.isRunning) ? Color.axSuccess.opacity(0.08) : Color.axError.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke((status?.isRunning ?? app.isRunning) ? Color.axSuccess.opacity(0.2) : Color.axError.opacity(0.2), lineWidth: 1))
            )
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
        .background(Color.axSurface.opacity(0.5).background(.ultraThinMaterial))
    }

    private func refreshCurrentSection() async {
        switch selectedItem {
        case .overview:
            statusLoaded = false; await loadStatus()
        case .config:
            configsLoaded = false; await loadConfigs()
        case .versions:
            versionsLoaded = false; await loadVersions()
        case .modules:
            modulesLoaded = false; await loadModules()
        case .workers:
            workersLoaded = false; await loadWorkers()
        case .logs, .optimization, .security,
             .sites, .snapshots, .doctor:
            break
        }
    }

    // MARK: - Content Router

    @ViewBuilder
    private var contentView: some View {
        switch selectedItem {
        case .overview:
            LiteSpeedOverviewSection(serverId: serverId, app: app, status: $status, onAction: { _ in
                Task { await refreshStatus() }
            })
        case .config:
            LiteSpeedConfigSection(serverId: serverId, configs: configs)
        case .versions:
            LiteSpeedVersionsSection(serverId: serverId, installedVersions: versions, availableVersions: availableVersions)
        case .modules:
            LiteSpeedModulesSection(modules: modules)
        case .workers:
            LiteSpeedWorkersSection(workers: workers)
        case .logs:
            LiteSpeedLogsSection(serverId: serverId)
        case .optimization:
            LiteSpeedOptimizationSection(serverId: serverId)
        case .security:
            LiteSpeedSecuritySection(serverId: serverId)
        case .sites:
            LiteSpeedSitesSection(serverId: serverId)
        case .snapshots:
            LiteSpeedSnapshotsSection(serverId: serverId)
        case .doctor:
            LiteSpeedDoctorSection(serverId: serverId)
        }
    }
}
