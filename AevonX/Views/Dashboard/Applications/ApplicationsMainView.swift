//
//  ApplicationsMainView.swift
//  AevonX
//
//  Master application dashboard — shows all installed/registered apps
//  with status badges, version info, and start/stop/restart controls.
//  Tapping an app opens its sidebar-driven detail view.
//

import SwiftUI
import AevonXCoreBridge

struct ApplicationsMainView: View {
    let server: Server?
    let serverId: String?
    @ObservedObject var connectionViewModel: ServerConnectionViewModel

    @State private var apps: [BridgeAppInfo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedApp: BridgeAppInfo?
    @State private var actionInProgress: String?

    private let bridge = ApplicationBridge.shared
    private let nginxGreen = Color(red: 0, green: 0.59, blue: 0.22)

    var body: some View {
        Group {
            if let app = selectedApp {
                // Detail view for selected app
                appDetailView(for: app)
            } else {
                // App list view
                appListView
            }
        }
        .task {
            await discoverApps()
        }
    }

    // MARK: - App List

    private var appListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Header
                appListHeader

                if isLoading {
                    AXLoadingState(message: "Discovering applications...")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if apps.isEmpty {
                    AXEmptyState(
                        icon: "app.dashed",
                        title: "No Applications Detected",
                        description: "Install services via Quick Install or the terminal"
                    )
                    .padding(.top, 40)
                } else {
                    // App Cards Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: AXSpacing.lg),
                            GridItem(.flexible(), spacing: AXSpacing.lg),
                        ],
                        spacing: AXSpacing.lg
                    ) {
                        ForEach(apps) { app in
                            appCard(for: app)
                        }
                    }
                }

                // Error banner
                if let error = errorMessage {
                    AXAlertBanner(
                        message: error,
                        type: .error,
                        onDismiss: { errorMessage = nil }
                    )
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    private var appListHeader: some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Applications")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Text("\(apps.filter { $0.installed }.count) installed · \(apps.filter { $0.isRunning }.count) running")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Spacer()

            // Refresh
            AXRefreshButton(isLoading: isLoading) {
                await discoverApps()
            }
        }
    }

    // MARK: - App Card

    private func appCard(for app: BridgeAppInfo) -> some View {
        Button {
            if app.installed {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedApp = app
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                // Header: icon + name + status
                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(accentColor(for: app).opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: app.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(accentColor(for: app))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.axTextPrimary)

                        if let version = app.version, !version.isEmpty {
                            Text("v\(version)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                        }
                    }

                    Spacer()

                    statusBadge(for: app)
                }

                // Action buttons (only if installed)
                if app.installed {
                    HStack(spacing: AXSpacing.sm) {
                        lifecycleButton(
                            icon: app.isRunning ? "stop.fill" : "play.fill",
                            label: app.isRunning ? "Stop" : "Start",
                            color: app.isRunning ? .axError : .axSuccess,
                            appID: app.id,
                            action: app.isRunning ? "stop" : "start"
                        )

                        lifecycleButton(
                            icon: "arrow.clockwise",
                            label: "Restart",
                            color: .axWarning,
                            appID: app.id,
                            action: "restart"
                        )

                        Spacer()

                        // Detail arrow
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.axTextMuted)
                    }
                } else {
                    Text("Not Installed")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .stroke(accentColor(for: app).opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Detail View Router

    @ViewBuilder
    private func appDetailView(for app: BridgeAppInfo) -> some View {
        switch app.id {
        case "nginx":
            NginxDetailView(
                serverId: serverId ?? "",
                app: app,
                onBack: { withAnimation { selectedApp = nil } }
            )
        default:
            // Generic placeholder for future apps
            VStack(spacing: AXSpacing.lg) {
                Text("\(app.name) Detail View")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text("Coming soon")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                Button("← Back") {
                    withAnimation { selectedApp = nil }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.axBackground)
        }
    }

    // MARK: - Helpers

    private func statusBadge(for app: BridgeAppInfo) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Circle()
                .fill(app.isRunning ? Color.axSuccess : (app.installed ? Color.axError : Color.axTextMuted))
                .frame(width: 7, height: 7)
            Text(app.isRunning ? "Running" : (app.installed ? "Stopped" : "Not Installed"))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(app.isRunning ? .axSuccess : (app.installed ? .axError : .axTextMuted))
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxxs)
        .background(
            Capsule().fill(
                app.isRunning ? Color.axSuccess.opacity(0.1) : (app.installed ? Color.axError.opacity(0.1) : Color.axTextMuted.opacity(0.1))
            )
        )
    }

    private func lifecycleButton(icon: String, label: String, color: Color, appID: String, action: String) -> some View {
        Button {
            Task { await performAction(action, appID: appID) }
        } label: {
            HStack(spacing: AXSpacing.xs) {
                if actionInProgress == "\(action)_\(appID)" {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                }
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(color.opacity(0.1))
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(actionInProgress != nil)
    }

    private func accentColor(for app: BridgeAppInfo) -> Color {
        var h = app.accentHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return .axAccentBlue }
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8) & 0xFF) / 255
        let b = Double(val & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }

    // MARK: - Actions

    private func discoverApps() async {
        guard let sid = serverId else { return }
        let start = CFAbsoluteTimeGetCurrent()
        print("[PERF-SWIFT] ApplicationsMainView.discoverApps: START")
        isLoading = true
        errorMessage = nil

        let json = await bridge.discoverApps(serverID: sid)
        let bridgeMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        print("[PERF-SWIFT] ApplicationsMainView: bridge.discoverApps took \(bridgeMs)ms (response: \(json.count) chars)")

        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppInfo]>.self, from: data),
           response.success {
            apps = response.data ?? []
            print("[PERF-SWIFT] ApplicationsMainView: \(apps.count) apps found")
        } else {
            print("[PERF-SWIFT] ApplicationsMainView: discoverApps FAILED, falling back to listAdapters")
            // Fallback: show registered adapters
            let adapterJSON = await bridge.listAdapters()
            if let data = adapterJSON.data(using: .utf8),
               let response = try? JSONDecoder().decode(BridgeDataResponse<[BridgeAppInfo]>.self, from: data),
               response.success {
                apps = response.data ?? []
            }
        }

        isLoading = false
        let totalMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        print("[PERF-SWIFT] ApplicationsMainView.discoverApps: TOTAL \(totalMs)ms")
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

        // Show toast based on result
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

// MARK: - Bridge Response Helper

struct BridgeDataResponse<T: Codable>: Codable {
    let success: Bool
    let error: String?
    let data: T?
}


