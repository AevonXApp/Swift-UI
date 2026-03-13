//
//  NginxOverviewSection.swift
//  AevonX
//
//  Overview dashboard: service status, stat cards, and quick actions.
//  Receives pre-fetched data from NginxDetailView — zero SSH calls.
//

import SwiftUI
import AevonXCoreBridge

struct NginxOverviewSection: View {
    let serverId: String
    let app: BridgeAppInfo
    @Binding var status: BridgeAppStatus?
    var onAction: (String) -> Void

    @State private var actionInProgress: String?

    private let nginxGreen = Color(red: 0, green: 0.59, blue: 0.22)
    private let toast = GlobalToastManager.shared
    private let bridge = ApplicationBridge.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                statusCard

                if let status = status {
                    statCardsGrid(status)
                }

                quickActionsSection

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                (status?.isRunning ?? app.isRunning) ? nginxGreen : Color.axError,
                                (status?.isRunning ?? app.isRunning) ? nginxGreen.opacity(0.6) : Color.axError.opacity(0.6),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: ((status?.isRunning ?? app.isRunning) ? nginxGreen : Color.axError).opacity(0.3), radius: 10, x: 0, y: 4)

                Image(systemName: (status?.isRunning ?? app.isRunning) ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Nginx Service")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                HStack(spacing: AXSpacing.md) {
                    Text((status?.isRunning ?? app.isRunning) ? "Active & Healthy" : "Service Stopped")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)

                    if let uptime = status?.uptime, !uptime.isEmpty {
                        Text("· Up since \(uptime)")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                    }
                }
            }

            Spacer()

            if let status = status {
                VStack(spacing: 4) {
                    Image(systemName: status.configValid ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(status.configValid ? nginxGreen : .axWarning)
                    Text(status.configValid ? "Config OK" : "Config Error")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(status.configValid ? nginxGreen : .axWarning)
                }
                .padding(AXSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(status.configValid ? nginxGreen.opacity(0.08) : Color.axWarning.opacity(0.08))
                )
            }
        }
        .padding(AXSpacing.xl)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Stat Cards

    private func statCardsGrid(_ status: BridgeAppStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXSectionTitle(title: "Metrics", icon: "chart.bar.fill")

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ],
                spacing: AXSpacing.md
            ) {
                AXStatCard(icon: "link", label: "Connections",
                           value: "\(status.connections)", color: .axAccentBlue, style: .card)
                AXStatCard(icon: "cpu", label: "Workers",
                           value: "\(status.workerCount)", color: .cyan, style: .card)
                AXStatCard(icon: "memorychip", label: "Memory",
                           value: status.memoryUsage ?? "N/A", color: .purple, style: .card)
                AXStatCard(icon: "bolt.fill", label: "Req/sec",
                           value: String(format: "%.1f", status.requestsPerSec), color: nginxGreen, style: .card)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXSectionTitle(title: "Quick Actions", icon: "bolt.fill")

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: AXSpacing.md
            ) {
                quickAction(
                    icon: (status?.isRunning ?? app.isRunning) ? "stop.fill" : "play.fill",
                    title: (status?.isRunning ?? app.isRunning) ? "Stop" : "Start",
                    color: (status?.isRunning ?? app.isRunning) ? .axError : .axSuccess,
                    action: (status?.isRunning ?? app.isRunning) ? "stop" : "start"
                )
                quickAction(icon: "arrow.clockwise", title: "Restart", color: .axWarning, action: "restart")
                quickAction(icon: "arrow.triangle.2.circlepath", title: "Reload", color: .axAccentBlue, action: "reload")
                quickAction(icon: "doc.text.magnifyingglass", title: "Test Config", color: .purple, action: "configtest")
            }
        }
    }

    private func quickAction(icon: String, title: String, color: Color, action: String) -> some View {
        Button {
            Task { await performAction(action, title: title) }
        } label: {
            VStack(spacing: AXSpacing.sm) {
                if actionInProgress == action {
                    ProgressView().scaleEffect(0.7).frame(height: 20)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.lg)
            .background(color.opacity(0.06))
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(actionInProgress != nil)
    }

    private func performAction(_ action: String, title: String) async {
        actionInProgress = action

        let resultJSON: String
        switch action {
        case "start":      resultJSON = await bridge.start(serverID: serverId, appID: "nginx")
        case "stop":       resultJSON = await bridge.stop(serverID: serverId, appID: "nginx")
        case "restart":    resultJSON = await bridge.restart(serverID: serverId, appID: "nginx")
        case "reload":     resultJSON = await bridge.reload(serverID: serverId, appID: "nginx")
        case "configtest": resultJSON = await bridge.configTest(serverID: serverId, appID: "nginx")
        default:           resultJSON = ""
        }

        // Parse result and show toast
        if let data = resultJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let success = resp["success"] as? Bool ?? false
            if success {
                toast.showSuccess("Nginx \(title.lowercased()) — success")
            } else {
                let errStr = resp["error"] as? String ?? "Unknown error"
                toast.showError("Nginx \(title.lowercased()) failed: \(errStr)")
            }
        }

        // Refresh status
        onAction(action)
        actionInProgress = nil
    }
}
