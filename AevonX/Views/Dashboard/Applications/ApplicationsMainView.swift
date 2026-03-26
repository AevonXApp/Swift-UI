//  ApplicationsMainView.swift
//  AevonX
//
//  Premium Applications dashboard — 3D-depth glass cards, hero stats bar,
//  pulse/glow animations, glassmorphism design, rich feature density.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Filter

enum AppFilterType: String, CaseIterable {
    case all     = "All"
    case daemon  = "Daemon"
    case runtime = "Runtime"

    var icon: String {
        switch self {
        case .all:     return "square.grid.2x2.fill"
        case .daemon:  return "gearshape.2.fill"
        case .runtime: return "cpu.fill"
        }
    }
}

// MARK: - ApplicationsMainView

struct ApplicationsMainView: View {
    let server: Server?
    let serverId: String?
    @ObservedObject var connectionViewModel: ServerConnectionViewModel

    @State private var apps: [BridgeAppInfo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedApp: BridgeAppInfo?
    @State private var actionInProgress: String?
    @State private var searchText = ""
    @State private var selectedFilter: AppFilterType = .all
    @State private var hoveredApp: String?

    private let bridge = ApplicationBridge.shared

    // MARK: - Derived State

    private var installed: [BridgeAppInfo] { apps.filter { $0.installed } }
    private var running: [BridgeAppInfo] { apps.filter { $0.isRunning } }

    private var filteredInstalled: [BridgeAppInfo] { filterApps(installed) }
    private var filteredNotInstalled: [BridgeAppInfo] { filterApps(apps.filter { !$0.installed }) }

    private func filterApps(_ source: [BridgeAppInfo]) -> [BridgeAppInfo] {
        var result = source
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if selectedFilter != .all {
            result = result.filter { $0.serviceType.lowercased() == selectedFilter.rawValue.lowercased() }
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let app = selectedApp {
                appDetailView(for: app)
            } else {
                mainView
            }
        }
        .task { await discoverApps() }
    }

    // MARK: - Main View

    private var mainView: some View {
        VStack(spacing: 0) {
            topBar
            Divider().background(Color.axBorder.opacity(0.2))

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // ── Hero Stats ────────────────────────────────────
                    if !isLoading {
                        heroStats
                            .padding(.horizontal, AXSpacing.xl)
                            .padding(.top, AXSpacing.xl)
                            .padding(.bottom, AXSpacing.lg)
                    }

                    // ── Installed Cards ───────────────────────────────
                    if isLoading {
                        skeletonSection
                            .padding(.horizontal, AXSpacing.xl)
                            .padding(.top, AXSpacing.xl)
                    } else {
                        installedSection
                            .padding(.horizontal, AXSpacing.xl)

                        if !filteredNotInstalled.isEmpty {
                            notInstalledSection
                                .padding(.horizontal, AXSpacing.xl)
                                .padding(.top, AXSpacing.xl)
                        }
                    }

                    if let error = errorMessage {
                        AXAlertBanner(message: error, type: .error, onDismiss: { errorMessage = nil })
                            .padding(.horizontal, AXSpacing.xl)
                            .padding(.top, AXSpacing.md)
                    }
                }
                .padding(.bottom, AXSpacing.xl)
            }
        }
        .background(Color.axBackground)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: AXSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Applications")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                if !isLoading {
                    Text("\(installed.count) installed · \(running.count) running")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            // Search
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextMuted)
                TextField("Search apps...", text: $searchText)
                    .font(.system(size: 12))
                    .foregroundColor(.axTextPrimary)
                    .textFieldStyle(.plain)
                    .frame(width: 150)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, 7)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.25), lineWidth: 1))

            // Filter pills
            HStack(spacing: 3) {
                ForEach(AppFilterType.allCases, id: \.self) { filter in
                    Button { withAnimation(.easeInOut(duration: 0.15)) { selectedFilter = filter } } label: {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon).font(.system(size: 9, weight: .semibold))
                            Text(filter.rawValue).font(.system(size: 11, weight: selectedFilter == filter ? .semibold : .regular))
                        }
                        .foregroundColor(selectedFilter == filter ? .axAccentBlue : .axTextSecondary)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .fill(selectedFilter == filter ? Color.axAccentBlue.opacity(0.12) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(selectedFilter == filter ? Color.axAccentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(3)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))

            AXRefreshButton(isLoading: isLoading) { await discoverApps() }
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface.opacity(0.4).background(.ultraThinMaterial))
    }

    // MARK: - Hero Stats

    private var heroStats: some View {
        HStack(spacing: AXSpacing.md) {
            statCard(
                value: "\(installed.count)",
                label: "Installed",
                icon: "checkmark.circle.fill",
                color: .axAccentBlue
            )
            statCard(
                value: "\(running.count)",
                label: "Running",
                icon: "play.circle.fill",
                color: .axSuccess
            )
            statCard(
                value: "\(installed.count - running.count)",
                label: "Stopped",
                icon: "stop.circle.fill",
                color: running.count < installed.count ? Color.axError : .axTextMuted
            )
            statCard(
                value: "\(apps.filter { !$0.installed }.count)",
                label: "Available",
                icon: "arrow.down.circle.fill",
                color: .indigo
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextMuted)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Installed Section

    private var installedSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionLabel(icon: "checkmark.circle.fill", title: "Installed", count: filteredInstalled.count, color: .axSuccess)

            if filteredInstalled.isEmpty {
                emptyState(
                    icon: searchText.isEmpty ? "app.dashed" : "magnifyingglass",
                    title: searchText.isEmpty ? "No Applications Installed" : "No results for \"\(searchText)\"",
                    subtitle: searchText.isEmpty ? "Install services via Quick Install" : "Try a different search term"
                )
            } else {
                // 3-column grid of premium 3D cards
                let columns = [GridItem(.flexible(), spacing: AXSpacing.md), GridItem(.flexible(), spacing: AXSpacing.md), GridItem(.flexible(), spacing: AXSpacing.md)]
                LazyVGrid(columns: columns, spacing: AXSpacing.md) {
                    ForEach(filteredInstalled) { app in
                        AppCard3D(
                            app: app,
                            accentColor: accentColor(for: app),
                            actionInProgress: actionInProgress,
                            isHovered: hoveredApp == app.id,
                            onHover: { h in hoveredApp = h ? app.id : nil },
                            onTap: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedApp = app } },
                            onAction: { action in Task { await performAction(action, appID: app.id) } }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Not Installed Section

    private var notInstalledSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionLabel(icon: "arrow.down.circle", title: "Available to Install", count: filteredNotInstalled.count, color: .indigo)

            VStack(spacing: 2) {
                ForEach(filteredNotInstalled) { app in
                    AvailableAppRow(
                        app: app,
                        accentColor: accentColor(for: app),
                        serverId: serverId ?? "",
                        connectionViewModel: connectionViewModel,
                        onInstalled: { Task { await discoverApps() } }
                    )
                }
            }
        }
    }

    // MARK: - Skeleton

    private var skeletonSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 90, height: 12).shimmer()
                RoundedRectangle(cornerRadius: 8).fill(Color.axSurface).frame(width: 24, height: 18).shimmer()
            }
            let columns = [GridItem(.flexible(), spacing: AXSpacing.md), GridItem(.flexible(), spacing: AXSpacing.md)]
            LazyVGrid(columns: columns, spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in SkeletonCard3D() }
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(icon: String, title: String, count: Int, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundColor(color)
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.axTextPrimary)
            Text("\(count)")
                .font(.system(size: 10, weight: .bold)).foregroundColor(color)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(color.opacity(0.12)).cornerRadius(7)
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: icon).font(.system(size: 32)).foregroundColor(.axTextMuted.opacity(0.4))
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextSecondary)
            Text(subtitle).font(.system(size: 11)).foregroundColor(.axTextMuted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xl)
    }

    private func accentColor(for app: BridgeAppInfo) -> Color {
        var h = app.accentHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return .axAccentBlue }
        return Color(red: Double((val >> 16) & 0xFF) / 255,
                     green: Double((val >> 8) & 0xFF) / 255,
                     blue: Double(val & 0xFF) / 255)
    }

    // MARK: - Detail Router

    @ViewBuilder
    private func appDetailView(for app: BridgeAppInfo) -> some View {
        switch app.id {
        case "nginx":
            NginxDetailView(
                serverId: serverId ?? "",
                app: app,
                onBack: { withAnimation { selectedApp = nil } }
            )
        case "php-fpm":
            PHPDetailView(
                serverId: serverId ?? "",
                app: app,
                connectionViewModel: connectionViewModel,
                onBack: { withAnimation { selectedApp = nil } }
            )
        case "apache":
            ApacheDetailView(
                serverId: serverId ?? "",
                app: app,
                onBack: { withAnimation { selectedApp = nil } }
            )
        case "litespeed":
            LiteSpeedDetailView(
                serverId: serverId ?? "",
                app: app,
                onBack: { withAnimation { selectedApp = nil } }
            )
        case "mysql":
            MySQLDetailView(
                serverId: serverId ?? "",
                app: app,
                onBack: { withAnimation { selectedApp = nil } }
            )
        case "pgsql":
            PgSQLDetailView(
                serverId: serverId ?? "",
                app: app,
                onBack: { withAnimation { selectedApp = nil } }
            )
        case "redis":
            RedisDetailView(
                serverId: serverId ?? "",
                app: app,
                onBack: { withAnimation { selectedApp = nil } }
            )
        default:
            VStack(spacing: AXSpacing.lg) {
                Text("\(app.name) Detail View").font(AXTypography.headline).foregroundColor(.axTextPrimary)
                Text("Coming soon").font(AXTypography.caption).foregroundColor(.axTextMuted)
                Button("← Back") { withAnimation { selectedApp = nil } }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.axBackground)
        }
    }

    // MARK: - Data Actions

    private func discoverApps() async {
        guard let sid = serverId else { return }
        isLoading = true
        errorMessage = nil
        bridge.invalidateDiscoveryCache(serverID: sid)
        let json = await bridge.discoverApps(serverID: sid)
        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppInfo]>.self, from: data),
           response.success {
            apps = response.data ?? []
        } else {
            let adapterJSON = await bridge.listAdapters()
            if let data = adapterJSON.data(using: .utf8),
               let response = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppInfo]>.self, from: data),
               response.success {
                apps = response.data ?? []
            } else {
                errorMessage = "Could not discover applications"
            }
        }
        isLoading = false
    }

    private func performAction(_ action: String, appID: String) async {
        guard let sid = serverId else { return }
        actionInProgress = "\(action)_\(appID)"
        let toast = GlobalToastManager.shared
        let resultJSON: String
        switch action {
        case "start":   resultJSON = await bridge.start(serverID: sid, appID: appID)
        case "stop":    resultJSON = await bridge.stop(serverID: sid, appID: appID)
        case "restart": resultJSON = await bridge.restart(serverID: sid, appID: appID)
        default:        resultJSON = ""
        }
        if let data = resultJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let success = resp["success"] as? Bool ?? false
            if success {
                toast.showSuccess("\(appID.capitalized) \(action) — success")
            } else {
                let err = resp["error"] as? String ?? "Action failed"
                toast.showError("\(appID.capitalized) \(action) failed: \(err)")
            }
        }
        actionInProgress = nil
        await discoverApps()
    }
}

// MARK: - AppCard3D (Premium 3D-depth Installed App Card)

private struct AppCard3D: View {
    let app: BridgeAppInfo
    let accentColor: Color
    let actionInProgress: String?
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onTap: () -> Void
    let onAction: (String) -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {

                // ── 3D Background layers ──────────────────────────────
                // Bottom layer: deep shadow base
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(accentColor.opacity(isHovered ? 0.08 : 0.03))
                    .shadow(color: accentColor.opacity(isHovered ? 0.25 : 0.08), radius: isHovered ? 20 : 8, y: isHovered ? 8 : 3)

                // Glass overlay
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.axSurface.opacity(0.95), location: 0),
                                .init(color: Color.axSurface.opacity(0.75), location: 1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Border: top-left bright highlight (3D rim light effect)
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.18 : 0.08),
                                accentColor.opacity(isHovered ? 0.35 : 0.12),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )

                // ── Content ───────────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {

                    // Top section: icon + status + actions
                    HStack(alignment: .top, spacing: 0) {

                        // ── App icon ─────────────────────
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                                .blur(radius: isHovered ? 6 : 3)

                            // Icon container with 3D feel
                            ZStack {
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(
                                        LinearGradient(
                                            colors: [accentColor.opacity(0.3), accentColor.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                    .shadow(color: accentColor.opacity(0.3), radius: 5, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 11)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.25), accentColor.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )

                                Image(systemName: app.icon)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [accentColor, accentColor.opacity(0.65)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: accentColor.opacity(0.4), radius: 4)
                            }
                        }

                        Spacer()

                        // ── Status indicator ──────────────
                        VStack(alignment: .trailing, spacing: AXSpacing.xs) {
                            // Status pill
                            HStack(spacing: 5) {
                                if app.isRunning {
                                    Circle()
                                        .fill(Color.axSuccess)
                                        .frame(width: 6, height: 6)
                                        .scaleEffect(pulseScale)
                                        .shadow(color: Color.axSuccess, radius: 3)
                                        .onAppear {
                                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                                pulseScale = 1.4
                                            }
                                        }
                                } else {
                                    Circle()
                                        .fill(Color.axError.opacity(0.6))
                                        .frame(width: 6, height: 6)
                                }
                                Text(app.isRunning ? L10n.Status.running : L10n.Status.stopped)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(app.isRunning ? .axSuccess : .axError)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(app.isRunning ? Color.axSuccess.opacity(0.1) : Color.axError.opacity(0.08))
                                    .overlay(
                                        Capsule()
                                            .stroke(app.isRunning ? Color.axSuccess.opacity(0.25) : Color.axError.opacity(0.2), lineWidth: 1)
                                    )
                            )

                            // Type badge
                            Text(app.serviceType.capitalized)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(accentColor.opacity(0.8))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(accentColor.opacity(0.1))
                                .cornerRadius(4)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(accentColor.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding(AXSpacing.md)

                    // ── Name and version ───────────────────────────────
                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.axTextPrimary)
                        if let v = app.version, !v.isEmpty {
                            Text("v\(v)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                        }
                    }
                    .padding(.horizontal, AXSpacing.md)

                    Spacer(minLength: AXSpacing.lg)

                    // ── Bottom: Action buttons + open hint ─────────────
                    HStack(spacing: AXSpacing.xs) {
                        actionBtn(
                            icon: app.isRunning ? "stop.fill" : "play.fill",
                            color: app.isRunning ? .axError : .axSuccess,
                            action: app.isRunning ? "stop" : "start"
                        )
                        actionBtn(icon: "arrow.clockwise", color: .axWarning, action: "restart")

                        Spacer()

                        // "Open details" hint on hover
                        HStack(spacing: 3) {
                            Text("Details")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(accentColor.opacity(0.7))
                            Image(systemName: "arrow.forward.circle")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(accentColor.opacity(0.7))
                        }
                        .opacity(isHovered ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.2), value: isHovered)
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.bottom, AXSpacing.md)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minHeight: 130)
        .scaleEffect(isHovered ? 1.025 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHovered)
        .onHover { onHover($0) }
    }

    private func actionBtn(icon: String, color: Color, action: String) -> some View {
        let key = "\(action)_\(app.id)"
        return Button { onAction(action) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.2), lineWidth: 1))
                    .frame(width: 30, height: 30)
                if actionInProgress == key {
                    ProgressView().scaleEffect(0.45)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(actionInProgress != nil)
    }
}

// MARK: - AvailableAppRow (Not Installed)

private struct AvailableAppRow: View {
    let app: BridgeAppInfo
    let accentColor: Color
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    var onInstalled: (() -> Void)?

    @State private var isHovered = false
    @State private var isInstalling = false

    private let toast = GlobalToastManager.shared

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(accentColor.opacity(0.07))
                    .frame(width: 36, height: 36)
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(accentColor.opacity(0.12), lineWidth: 1))
                Image(systemName: app.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(accentColor.opacity(0.55))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextSecondary)
                if let v = app.version, !v.isEmpty {
                    Text("v\(v) available").font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            Text(app.serviceType.capitalized)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Color.axSurface).cornerRadius(4)

            Button {
                installViaQuickInstall()
            } label: {
                HStack(spacing: 4) {
                    if isInstalling {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 11))
                    }
                    Text(L10n.Button.install)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(accentColor)
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isInstalling)
        }
        .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.sm)
        .background(isHovered ? accentColor.opacity(0.03) : Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.08), lineWidth: 1))
        .animation(.easeOut(duration: 0.18), value: isHovered)
        .onHover { isHovered = $0 }
    }

    // MARK: - Quick Install

    private func installViaQuickInstall() {
        let qi: QuickInstallViewModel
        if let existing = connectionViewModel.quickInstallVM {
            qi = existing
        } else {
            qi = QuickInstallViewModel(serverId: serverId, profile: connectionViewModel.serverProfile)
            connectionViewModel.quickInstallVM = qi
        }

        // Find matching package in QI catalog by app ID or name
        let appId = app.id.lowercased()
        guard let pkg = qi.bridgePackages.first(where: {
            $0.id.lowercased() == appId ||
            $0.id.lowercased().contains(appId) ||
            $0.name.lowercased().contains(appId)
        }) else {
            toast.showError("\(app.name) package not found in Quick Install catalog")
            return
        }

        // Pick the first (default) version or match
        let selectedVersion = pkg.versions.first
        let selection = BridgeQISelection(
            package_id: pkg.id,
            package_name: pkg.name,
            version_id: selectedVersion?.id ?? "",
            version_label: selectedVersion?.label ?? app.name
        )
        qi.selections = [selection]
        qi.isVisible = true
        qi.isMinimized = false

        isInstalling = true
        Task {
            await qi.beginInstallation()
            isInstalling = false
            onInstalled?()
        }
    }
}

// MARK: - SkeletonCard3D

private struct SkeletonCard3D: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.axSurface).frame(width: 48, height: 48).shimmer()
                Spacer()
                RoundedRectangle(cornerRadius: 10).fill(Color.axSurface).frame(width: 70, height: 22).shimmer()
            }
            RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 100, height: 14).shimmer()
            RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(width: 60, height: 10).shimmer()
            Spacer()
            HStack(spacing: AXSpacing.xs) {
                RoundedRectangle(cornerRadius: 7).fill(Color.axSurface).frame(width: 30, height: 30).shimmer()
                RoundedRectangle(cornerRadius: 7).fill(Color.axSurface).frame(width: 30, height: 30).shimmer()
            }
        }
        .padding(AXSpacing.md)
        .frame(minHeight: 160)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.12), lineWidth: 1))
        )
    }
}

// MARK: - Bridge Response Helper (shared)

struct BridgeDataResponse<T: Codable>: Codable {
    let success: Bool
    let error: String?
    let data: T?
}
