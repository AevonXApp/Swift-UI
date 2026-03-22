//
//  PgSQLOverviewSection.swift
//  AevonX
//
//  Overview dashboard: service status, stat cards, and quick actions.
//  Receives pre-fetched data from PgSQLDetailView — zero SSH calls.
//

import SwiftUI
import AevonXCoreBridge

struct PgSQLOverviewSection: View {
    let serverId: String
    let app: BridgeAppInfo
    @Binding var status: BridgeAppStatus?
    var onAction: (String) -> Void

    @State private var actionInProgress: String?

    private let pgsqlBlue = Color(red: 0.2, green: 0.4, blue: 0.57)
    private let toast = GlobalToastManager.shared
    private let bridge = ApplicationBridge.shared

    private var isRunning: Bool { status?.isRunning ?? app.isRunning }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                statusBanner

                if let status = status {
                    statCardsSection(status)
                } else {
                    skeletonStats
                }

                quickActionsSection

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Status Banner

    private var statusBanner: some View {
        HStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                isRunning ? pgsqlBlue : Color.axError,
                                isRunning ? pgsqlBlue.opacity(0.3) : Color.axError.opacity(0.3),
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: (isRunning ? pgsqlBlue : Color.axError).opacity(0.4), radius: 12, y: 4)

                Image(systemName: isRunning ? "checkmark" : "xmark")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("PostgreSQL Service")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                Text(isRunning ? "Active & Healthy" : "Service Stopped")
                    .font(AXTypography.body)
                    .foregroundColor(isRunning ? .axTextSecondary : .axError)

                if let uptime = status?.uptime, !uptime.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Text("Up \(uptime)")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AXSpacing.xs) {
                if let s = status {
                    infoPill(icon: "number", label: "PID \(s.pid)", color: .axAccentBlue)
                    infoPill(icon: "shippingbox.fill", label: "v\(s.version)", color: pgsqlBlue)
                } else if let version = app.version, !version.isEmpty {
                    infoPill(icon: "shippingbox.fill", label: "v\(version)", color: pgsqlBlue)
                }
            }
        }
        .padding(AXSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            isRunning ? pgsqlBlue.opacity(0.08) : Color.axError.opacity(0.08),
                            Color.axSurface,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(
                            (isRunning ? pgsqlBlue : Color.axError).opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }

    private func infoPill(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextSecondary)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Skeleton Stats

    private var skeletonStats: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface)
                    .frame(width: 16, height: 16)
                    .shimmer()
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface)
                    .frame(width: 70, height: 13)
                    .shimmer()
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4),
                spacing: AXSpacing.md
            ) {
                ForEach(0..<4, id: \.self) { _ in
                    AXSkeletonStatCard()
                }
            }
        }
    }

    // MARK: - Stat Cards

    private func statCardsSection(_ s: BridgeAppStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXSectionTitle(title: "Metrics", icon: "chart.bar.fill")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4),
                spacing: AXSpacing.md
            ) {
                AXStatCard(icon: "link.circle.fill", label: "Connections",
                           value: "\(s.connections)", color: .axAccentBlue, style: .glass)
                AXStatCard(icon: "point.3.connected.trianglepath.dotted", label: "Active",
                           value: "\(s.workerCount)", color: .cyan, style: .glass)
                AXStatCard(icon: "memorychip.fill", label: "Memory",
                           value: s.memoryUsage ?? "N/A", color: .purple, style: .glass)
                AXStatCard(icon: "bolt.fill", label: "Queries/sec",
                           value: String(format: "%.1f", s.requestsPerSec), color: pgsqlBlue, style: .glass)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXSectionTitle(title: "Quick Actions", icon: "bolt.fill")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AXSpacing.md),
                    GridItem(.flexible(), spacing: AXSpacing.md),
                    GridItem(.flexible(), spacing: AXSpacing.md),
                    GridItem(.flexible(), spacing: AXSpacing.md),
                ],
                spacing: AXSpacing.md
            ) {
                quickAction(
                    icon: isRunning ? "stop.fill" : "play.fill",
                    title: isRunning ? "Stop" : "Start",
                    color: isRunning ? .axError : .axSuccess,
                    action: isRunning ? "stop" : "start"
                )
                quickAction(icon: "arrow.clockwise", title: "Restart", color: .axWarning, action: "restart")
                quickAction(icon: "arrow.triangle.2.circlepath", title: "Reload", color: .axAccentBlue, action: "reload")
                quickAction(icon: "doc.text.magnifyingglass", title: "Config Test", color: .purple, action: "configtest")
            }
        }
    }

    private func quickAction(icon: String, title: String, color: Color, action: String) -> some View {
        NginxQuickActionButton(
            icon: icon,
            title: title,
            color: color,
            isLoading: actionInProgress == action,
            isDisabled: actionInProgress != nil,
            onTap: { Task { await performAction(action, title: title) } }
        )
    }

    // MARK: - Actions

    private func performAction(_ action: String, title: String) async {
        actionInProgress = action

        let resultJSON: String
        switch action {
        case "start":      resultJSON = await bridge.start(serverID: serverId, appID: "pgsql")
        case "stop":       resultJSON = await bridge.stop(serverID: serverId, appID: "pgsql")
        case "restart":    resultJSON = await bridge.restart(serverID: serverId, appID: "pgsql")
        case "reload":     resultJSON = await bridge.reload(serverID: serverId, appID: "pgsql")
        case "configtest": resultJSON = await bridge.configTest(serverID: serverId, appID: "pgsql")
        default:           resultJSON = ""
        }

        if let data = resultJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let success = resp["success"] as? Bool ?? false
            if success {
                toast.showSuccess("PostgreSQL \(title.lowercased()) — success")
            } else {
                let errStr = resp["error"] as? String ?? "Unknown error"
                toast.showError("PostgreSQL \(title.lowercased()) failed: \(errStr)")
            }
        }

        onAction(action)
        actionInProgress = nil
    }
}
