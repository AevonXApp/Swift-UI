//
//  LiteSpeedOverviewSection.swift
//  AevonX
//
//  Overview dashboard: service status, stat cards, and quick actions.
//  Receives pre-fetched data from detail view — zero SSH calls.
//  LiteSpeed accent color: #2E8B57 (sea green).
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedOverviewSection: View {
    let serverId: String
    let app: BridgeAppInfo
    @Binding var status: BridgeAppStatus?
    var onAction: (String) -> Void

    @State private var actionInProgress: String?

    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)
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
                                isRunning ? lsGreen : Color.axError,
                                isRunning ? lsGreen.opacity(0.3) : Color.axError.opacity(0.3),
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: (isRunning ? lsGreen : Color.axError).opacity(0.4), radius: 12, y: 4)

                Image(systemName: isRunning ? "checkmark" : "xmark")
                    .font(AXTypography.title).fontWeight(.black)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.sm) {
                    Text("LiteSpeed Service")
                        .font(AXTypography.title2).fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    if let s = status {
                        HStack(spacing: 3) {
                            Image(systemName: s.configValid ? "checkmark.seal.fill" : "xmark.seal.fill")
                                .font(AXTypography.caption)
                            Text(s.configValid ? "Config OK" : "Config Error")
                                .font(AXTypography.caption).fontWeight(.semibold)
                        }
                        .foregroundColor(s.configValid ? lsGreen : .axWarning)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(s.configValid ? lsGreen.opacity(0.12) : Color.axWarning.opacity(0.12))
                        )
                    }
                }

                Text(isRunning ? "Active & Healthy" : "Service Stopped")
                    .font(AXTypography.body)
                    .foregroundColor(isRunning ? .axTextSecondary : .axError)

                if let uptime = status?.uptime, !uptime.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                        Text("Up \(uptime)")
                            .font(AXTypography.footnote)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AXSpacing.xs) {
                if let s = status {
                    infoPill(icon: "number", label: "PID \(s.pid)", color: .axAccentBlue)
                    infoPill(icon: "shippingbox.fill", label: "v\(s.version)", color: lsGreen)
                } else if let version = app.version, !version.isEmpty {
                    infoPill(icon: "shippingbox.fill", label: "v\(version)", color: lsGreen)
                }
            }
        }
        .padding(AXSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            isRunning ? lsGreen.opacity(0.08) : Color.axError.opacity(0.08),
                            Color.axSurface,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(
                            (isRunning ? lsGreen : Color.axError).opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }

    private func infoPill(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(AXTypography.caption2).fontWeight(.semibold)
                .foregroundColor(color)
            Text(label)
                .font(AXTypography.monoSm).fontWeight(.medium)
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
                    .fill(Color.axSurface).frame(width: 16, height: 16).shimmer()
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color.axSurface).frame(width: 70, height: 13).shimmer()
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
                ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
            }
        }
    }

    // MARK: - Stat Cards

    private func statCardsSection(_ s: BridgeAppStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXSectionTitle(title: "Metrics", icon: "chart.bar.fill")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
                AXStatCard(icon: "link.circle.fill", label: "Connections", value: "\(s.connections)", color: .axAccentBlue, style: .glass)
                AXStatCard(icon: "cpu.fill", label: "Workers", value: "\(s.workerCount)", color: .cyan, style: .glass)
                AXStatCard(icon: "memorychip.fill", label: "Memory", value: s.memoryUsage ?? "N/A", color: .purple, style: .glass)
                AXStatCard(icon: "bolt.fill", label: "Req/sec", value: String(format: "%.1f", s.requestsPerSec), color: lsGreen, style: .glass)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            AXSectionTitle(title: "Quick Actions", icon: "bolt.fill")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
                quickAction(icon: isRunning ? "stop.fill" : "play.fill", title: isRunning ? "Stop" : "Start", color: isRunning ? .axError : .axSuccess, action: isRunning ? "stop" : "start")
                quickAction(icon: "arrow.clockwise", title: "Restart", color: .axWarning, action: "restart")
                quickAction(icon: "arrow.triangle.2.circlepath", title: "Reload", color: .axAccentBlue, action: "reload")
                quickAction(icon: "doc.text.magnifyingglass", title: "Test Config", color: .purple, action: "configtest")
            }
        }
    }

    private func quickAction(icon: String, title: String, color: Color, action: String) -> some View {
        LiteSpeedQuickActionButton(icon: icon, title: title, color: color,
                                isLoading: actionInProgress == action,
                                isDisabled: actionInProgress != nil,
                                onTap: { Task { await performAction(action, title: title) } })
    }

    // MARK: - Actions

    private func performAction(_ action: String, title: String) async {
        actionInProgress = action

        let resultJSON: String
        switch action {
        case "start":      resultJSON = await bridge.start(serverID: serverId, appID: "litespeed")
        case "stop":       resultJSON = await bridge.stop(serverID: serverId, appID: "litespeed")
        case "restart":    resultJSON = await bridge.restart(serverID: serverId, appID: "litespeed")
        case "reload":     resultJSON = await bridge.reload(serverID: serverId, appID: "litespeed")
        case "configtest": resultJSON = await bridge.configTest(serverID: serverId, appID: "litespeed")
        default:           resultJSON = ""
        }

        if let data = resultJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let success = resp["success"] as? Bool ?? false
            if success {
                toast.showSuccess("LiteSpeed \(title.lowercased()) — success")
            } else {
                let errStr = resp["error"] as? String ?? "Unknown error"
                toast.showError("LiteSpeed \(title.lowercased()) failed: \(errStr)")
            }
        }

        onAction(action)
        actionInProgress = nil
    }
}

// MARK: - LiteSpeedQuickActionButton

private struct LiteSpeedQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isLoading: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(isHovered ? 0.2 : 0.1), color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(color.opacity(isHovered ? 0.4 : 0.2), lineWidth: 1)
                        )

                    if isLoading {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: icon)
                            .font(AXTypography.title2)
                            .foregroundColor(color)
                    }
                }

                Text(title)
                    .font(AXTypography.subheadline).fontWeight(.medium)
                    .foregroundColor(.axTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(isHovered ? color.opacity(0.04) : Color.clear)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.25), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onHover { isHovered = $0 }
    }
}
