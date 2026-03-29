//
//  OverviewTab.swift
//  AevonX
//
//  Overview tab — real-time server vitals, resource details, load average, and inventory.
//  Redesigned with depth-layered 3D look, reactive color indicators, and hover effects.
//

import SwiftUI
import AevonXCoreBridge

struct OverviewTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var viewModel: ServerConnectionViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @Environment(\.scenePhase) private var scenePhase

    init(server: Server, serverId: String, viewModel: ServerConnectionViewModel) {
        self.server = server
        self.serverId = serverId
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                ConnectionStatusBar(viewModel: viewModel)
                freshBannerSection
                serverHeroSection
                if viewModel.isConnected { sysVitalsSection }
                if settings.showInventory { InventoryCard(viewModel: viewModel) }
                trafficAndLoadRow
                bottomInfoRow
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            CoreLogger.shared.debug("onAppear - isConnected: \(viewModel.isConnected)", module: "OverviewTab")
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active: viewModel.appWillEnterForeground()
            case .background, .inactive: viewModel.appDidEnterBackground()
            @unknown default: break
            }
        }
    }

    // MARK: - Section: Fresh Banner

    @ViewBuilder
    private var freshBannerSection: some View {
        if settings.showFreshServerBanner, viewModel.isConnected,
           let qi = viewModel.quickInstallVM, !qi.isVisible == false,
           qi.serverScan?.isEmpty == true, !qi.isInstalling {
            FreshServerBanner {
                viewModel.quickInstallVM?.isVisible = true
                viewModel.quickInstallVM?.isMinimized = false
            }
        }
    }

    // MARK: - Section: Server Hero

    @ViewBuilder
    private var serverHeroSection: some View {
        ServerHeroCard(server: server, viewModel: viewModel, isMasking: isMaskingDashboard)
    }

    // MARK: - Section: Sys Vitals (4 metric cards — Load, CPU, RAM, Disk)

    @ViewBuilder
    private var sysVitalsSection: some View {
        HStack(spacing: AXSpacing.md) {
            LoadMetricCard(viewModel: viewModel)
            CPUMetricCard(viewModel: viewModel)
            RAMMetricCard(viewModel: viewModel)
            DiskMetricCard(viewModel: viewModel)
        }
    }

    // MARK: - Section: Traffic + Server Load (side by side)

    @ViewBuilder
    private var trafficAndLoadRow: some View {
        HStack(alignment: .top, spacing: AXSpacing.lg) {
            TrafficCard(viewModel: viewModel)
                .frame(maxWidth: .infinity)
            ServerLoadCard(viewModel: viewModel)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Section: System Info + Quick Actions (side by side)

    @ViewBuilder
    private var bottomInfoRow: some View {
        HStack(alignment: .top, spacing: AXSpacing.lg) {
            SystemInfoCard(server: server, viewModel: viewModel, isMasking: isMaskingDashboard)
                .frame(maxWidth: .infinity)
            if settings.showQuickActions {
                QuickActionsCard(serverId: serverId, viewModel: viewModel)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Helpers

    private var isMaskingDashboard: Bool {
        settings.maskServerInfo && settings.maskInDashboard && settings.maskIPAddresses
    }
}

// MARK: - Server Hero Card

private struct ServerHeroCard: View {
    let server: Server
    @ObservedObject var viewModel: ServerConnectionViewModel
    let isMasking: Bool

    var body: some View {
        AXDepthCard {
            HStack(spacing: AXSpacing.lg) {
                serverIconView
                serverIdentityView
                Spacer()
                statusColumnView
            }
        }
    }

    private var osDisplayName: String? {
        if let os = server.os, !os.isEmpty, os != "Unknown" { return os }
        if let detected = viewModel.detectedOS, !detected.isEmpty { return detected }
        return nil
    }

    private var serverIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color.axAccentBlue.opacity(0.25), Color.axAccentBlue.opacity(0.08)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                )
            Image(systemName: "server.rack")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.axAccentBlue)
        }
    }

    private var serverIdentityView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            HStack(spacing: AXSpacing.sm) {
                Text(server.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                if let osDisplay = osDisplayName {
                    Text(osDisplay)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, 2)
                        .background(Color.axBackgroundTertiary)
                        .cornerRadius(AXCornerRadius.xs)
                }
            }

            Text(isMasking ? PrivacyMask.ip(server.host) : server.host)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextSecondary)

            if viewModel.isConnected && viewModel.cpuCores > 0 {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "cpu")
                        .font(.system(size: 9))
                    Text("\(viewModel.cpuCores) cores")
                        .font(.system(size: 10))
                }
                .foregroundColor(.axTextTertiary)
            }
        }
    }

    private var statusColumnView: some View {
        VStack(alignment: .trailing, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill(viewModel.isConnected ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 7, height: 7)
                    .shadow(color: viewModel.isConnected ? Color.axSuccess.opacity(0.6) : .clear, radius: 4)
                Text(viewModel.isConnected ? "Online" : "Offline")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.isConnected ? .axSuccess : .axTextMuted)
            }

            if viewModel.isConnected, viewModel.uptime != "N/A" {
                Text(viewModel.uptime)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

// MARK: - Load Metric Card

private struct LoadMetricCard: View {
    @ObservedObject var viewModel: ServerConnectionViewModel

    private var loadParsed: (l1: Double, l5: Double, l15: Double) {
        let p = viewModel.loadAverage.split(separator: " ").compactMap { Double($0) }
        return (p.count > 0 ? p[0] : 0, p.count > 1 ? p[1] : 0, p.count > 2 ? p[2] : 0)
    }

    private var loadPct: Double {
        let cores = max(1, viewModel.cpuCores)
        return min(loadParsed.l1 / Double(cores) * 100, 100)
    }

    private var reactiveColor: Color {
        if loadPct < 50 { return .axAccentGreen }
        if loadPct < 85 { return .axWarning }
        return .axError
    }

    private var statusLabel: String {
        if loadPct < 50 { return "Low" }
        if loadPct < 85 { return "Moderate" }
        return "High"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            loadCardHeader
            loadRingDetail
            loadSparkline
        }
        .padding(AXSpacing.md)
        .background(loadCardBg)
        .overlay(loadCardBorder)
        .shadow(color: reactiveColor.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private var loadCardHeader: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(reactiveColor)
            Text("Load")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            Spacer()
        }
    }

    private var loadRingDetail: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                ProgressRing(progress: loadPct, color: reactiveColor, lineWidth: 5, size: 64)
                Text(String(format: "%.0f%%", loadPct))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(viewModel.cpuCores > 0 ? "\(viewModel.cpuCores) cores" : "—")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextPrimary)
                HStack(spacing: 3) {
                    Circle().fill(reactiveColor).frame(width: 5, height: 5)
                    Text(statusLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(reactiveColor)
                }
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, 2)
                .background(reactiveColor.opacity(0.1))
                .cornerRadius(AXCornerRadius.xs)
                Text(String(format: "%.2f / %.2f / %.2f", loadParsed.l1, loadParsed.l5, loadParsed.l15))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private var loadSparkline: some View {
        Group {
            if viewModel.cpuUsageHistory.contains(where: { $0 > 0 }) {
                SparklineView(data: viewModel.cpuUsageHistory, color: reactiveColor, lineWidth: 1.5, fillGradient: true)
                    .frame(height: 28)
            } else {
                Rectangle()
                    .fill(Color.axBackgroundTertiary.opacity(0.5))
                    .frame(height: 28)
                    .cornerRadius(AXCornerRadius.xs)
            }
        }
    }

    private var loadCardBg: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .fill(LinearGradient(
                colors: [Color(red: 0.10, green: 0.22, blue: 0.22).opacity(0.5), Color.axBackgroundTertiary.opacity(0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
    }

    private var loadCardBorder: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .stroke(LinearGradient(
                colors: [reactiveColor.opacity(0.18), Color.axBorder.opacity(0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ), lineWidth: 1)
    }
}

// MARK: - Resource Metric Card

struct ResourceMetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let history: [Double]
    let detail: String
    let isConnected: Bool
    var overrideColor: Color? = nil
    var tintColor: Color? = nil

    private var reactiveColor: Color {
        if let override = overrideColor { return override }
        if value < 50 { return .axAccentBlue }
        if value < 75 { return .axWarning }
        return .axError
    }

    private var statusLabel: String {
        if !isConnected { return "Offline" }
        if value < 50 { return "Normal" }
        if value < 75 { return "Moderate" }
        return "High"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            cardHeader
            ringAndDetail
            sparklineRow
        }
        .padding(AXSpacing.md)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: reactiveColor.opacity(0.06), radius: 5, x: 0, y: 3)
        .drawingGroup()
    }

    private var cardHeader: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(reactiveColor)
            Text(title)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            Spacer()
        }
    }

    private var ringAndDetail: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                ProgressRing(progress: min(value, 100), color: reactiveColor, lineWidth: 5, size: 64)
                VStack(spacing: 0) {
                    Text(unit == "°C" && value == 0 ? "N/A" : "\(Int(value))\(unit)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.axTextPrimary)
                }
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                HStack(spacing: 3) {
                    Circle()
                        .fill(reactiveColor)
                        .frame(width: 5, height: 5)
                    Text(statusLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(reactiveColor)
                }
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, 2)
                .background(reactiveColor.opacity(0.1))
                .cornerRadius(AXCornerRadius.xs)

                if isConnected {
                    Text("Real-time")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextTertiary)
                }
            }
        }
    }

    private var sparklineRow: some View {
        Group {
            if !history.isEmpty && history.contains(where: { $0 > 0 }) {
                SparklineView(data: history, color: reactiveColor, lineWidth: 1.5, fillGradient: true)
                    .frame(height: 28)
            } else {
                Rectangle()
                    .fill(Color.axBackgroundTertiary.opacity(0.5))
                    .frame(height: 28)
                    .cornerRadius(AXCornerRadius.xs)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .fill(
                LinearGradient(
                    colors: [
                        tintColor != nil
                            ? Color(red: 0.30, green: 0.20, blue: 0.10).opacity(0.4)
                            : Color.axBackgroundTertiary,
                        Color.axBackgroundTertiary.opacity(0.85)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .stroke(
                LinearGradient(
                    colors: [reactiveColor.opacity(0.12), Color.axBorder.opacity(0.25)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Load Average Card

// MARK: - Disk Metric Card (with detail popup)

private struct DiskMetricCard: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    @State private var showPopover = false
    @State private var hoverTask: Task<Void, Never>?

    private var reactiveColor: Color {
        if viewModel.diskUsage < 50 { return .axAccentBlue }
        if viewModel.diskUsage < 75 { return .axWarning }
        return .axError
    }

    private var diskDetail: String {
        guard viewModel.totalDiskGB > 0 else { return "Real-time" }
        return String(format: "%.0f / %.0f GB", viewModel.usedDiskGB, viewModel.totalDiskGB)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            diskCardHeader
            diskRingDetail
            diskSparkline
        }
        .padding(AXSpacing.md)
        .background(diskCardBg)
        .overlay(diskCardBorder)
        .shadow(color: reactiveColor.opacity(0.06), radius: 5, x: 0, y: 3)
        .onHover { hovering in
            hoverTask?.cancel()
            if hovering {
                hoverTask = Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    guard !Task.isCancelled else { return }
                    showPopover = true
                }
            } else {
                showPopover = false
            }
        }
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            DiskDetailPopover(viewModel: viewModel)
        }
    }

    private var diskCardHeader: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "internaldrive")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(reactiveColor)
            Text("Disk")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            Spacer()
        }
    }

    private var diskRingDetail: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                ProgressRing(progress: min(viewModel.diskUsage, 100), color: reactiveColor, lineWidth: 5, size: 64)
                Text("\(Int(viewModel.diskUsage))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(diskDetail)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                HStack(spacing: 3) {
                    Circle().fill(reactiveColor).frame(width: 5, height: 5)
                    Text(viewModel.diskUsage < 50 ? "Normal" : viewModel.diskUsage < 75 ? "Moderate" : "High")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(reactiveColor)
                }
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, 2)
                .background(reactiveColor.opacity(0.1))
                .cornerRadius(AXCornerRadius.xs)
                Text("Real-time")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
            }
        }
    }

    private var diskSparkline: some View {
        Group {
            if viewModel.diskUsageHistory.contains(where: { $0 > 0 }) {
                SparklineView(data: viewModel.diskUsageHistory, color: reactiveColor, lineWidth: 1.5, fillGradient: true)
                    .frame(height: 28)
            } else {
                Rectangle()
                    .fill(Color.axBackgroundTertiary.opacity(0.5))
                    .frame(height: 28)
                    .cornerRadius(AXCornerRadius.xs)
            }
        }
    }

    private var diskCardBg: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .fill(LinearGradient(
                colors: [Color(red: 0.12, green: 0.25, blue: 0.20).opacity(0.5), Color.axBackgroundTertiary.opacity(0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
    }

    private var diskCardBorder: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .stroke(LinearGradient(
                colors: [Color.axAccentGreen.opacity(0.18), Color.axBorder.opacity(0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ), lineWidth: 1)
    }
}

// MARK: - Disk Detail Popover

private struct DiskDetailPopover: View {
    @ObservedObject var viewModel: ServerConnectionViewModel

    private var freeGB: Double {
        max(0, viewModel.totalDiskGB - viewModel.usedDiskGB)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            diskPopoverHeader
            Divider()
            if viewModel.totalDiskGB > 0 { diskVisualBar }
            Divider()
            diskRowItem(label: "Used", valueGB: viewModel.usedDiskGB, color: .axError)
            diskRowItem(label: "Free", valueGB: freeGB, color: .axAccentGreen)
            Divider()
            HStack {
                Text("Total").font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextSecondary)
                Spacer()
                Text(String(format: "%.0f GB", viewModel.totalDiskGB))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
            HStack {
                Text("Mount").font(.system(size: 11)).foregroundColor(.axTextSecondary)
                Spacer()
                Text("/").font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
            }
        }
        .padding(AXSpacing.lg)
        .frame(width: 260)
        .background(Color.axSurface)
    }

    private var diskPopoverHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "internaldrive").font(.system(size: 13)).foregroundColor(.axAccentBlue)
            Text("Disk Detail").font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
            Spacer()
            Text(String(format: "%.1f%%", viewModel.diskUsage))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(viewModel.diskUsage < 75 ? .axAccentGreen : .axError)
        }
    }

    @ViewBuilder
    private var diskVisualBar: some View {
        let total = max(1.0, viewModel.totalDiskGB)
        let usedRatio = min(1.0, viewModel.usedDiskGB / total)

        VStack(spacing: AXSpacing.xs) {
            GeometryReader { geo in
                HStack(spacing: 1) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.axError.opacity(0.85))
                        .frame(width: max(4, geo.size.width * usedRatio))
                    Spacer()
                }
            }
            .frame(height: 10)
            .background(RoundedRectangle(cornerRadius: 3).fill(Color.axAccentGreen.opacity(0.2)))
            .cornerRadius(3)

            HStack(spacing: AXSpacing.md) {
                diskLegendDot(color: .axError, label: "Used")
                diskLegendDot(color: .axAccentGreen, label: "Free")
                Spacer()
            }
        }
    }

    private func diskLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9)).foregroundColor(.axTextTertiary)
        }
    }

    private func diskRowItem(label: String, valueGB: Double, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 11)).foregroundColor(.axTextSecondary)
            Spacer()
            Text(String(format: "%.2f GB", valueGB))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
        }
    }
}

// MARK: - Load Average Card

private struct LoadAverageCard: View {
    @ObservedObject var viewModel: ServerConnectionViewModel

    private var loadValues: (load1: Double, load5: Double, load15: Double) {
        let parts = viewModel.loadAverage.split(separator: " ").compactMap { Double($0) }
        return (
            load1: parts.count > 0 ? parts[0] : 0,
            load5: parts.count > 1 ? parts[1] : 0,
            load15: parts.count > 2 ? parts[2] : 0
        )
    }

    var body: some View {
        AXDepthCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                loadHeader
                Divider().background(Color.axBorder)
                loadBarsSection
            }
        }
    }

    private var loadHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 14))
                .foregroundColor(.axAccentBlue)
            Text("Load Average")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Spacer()
            if viewModel.cpuCores > 0 {
                Text("\(viewModel.cpuCores) cores")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.xs)
            }
        }
    }

    private var loadBarsSection: some View {
        let values = loadValues
        return VStack(spacing: AXSpacing.md) {
            LoadAverageBar(label: "1m", value: values.load1, cpuCores: viewModel.cpuCores)
            LoadAverageBar(label: "5m", value: values.load5, cpuCores: viewModel.cpuCores)
            LoadAverageBar(label: "15m", value: values.load15, cpuCores: viewModel.cpuCores)
        }
    }
}

// MARK: - Load Average Bar

struct LoadAverageBar: View {
    let label: String
    let value: Double
    let cpuCores: Int

    private var normalizedLoad: Double {
        guard cpuCores > 0 else { return min(value / 4.0, 1.0) }
        return min(value / Double(cpuCores), 1.0)
    }

    private var loadColor: Color {
        let ratio = cpuCores > 0 ? value / Double(cpuCores) : value / 4.0
        if ratio < 0.5 { return .axAccentGreen }
        if ratio < 0.85 { return .axWarning }
        return .axError
    }

    private var loadStatus: String {
        let ratio = cpuCores > 0 ? value / Double(cpuCores) : value / 4.0
        if ratio < 0.5 { return "Low" }
        if ratio < 0.85 { return "Med" }
        return "High"
    }

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .frame(width: 28, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.axBackgroundTertiary)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [loadColor.opacity(0.6), loadColor],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * normalizedLoad)
                        .animation(.easeInOut(duration: 0.6), value: normalizedLoad)
                }
            }
            .frame(height: 7)

            Text(String(format: "%.2f", value))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 38, alignment: .trailing)

            Text(loadStatus)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(loadColor)
                .frame(width: 26, alignment: .leading)
        }
    }
}

// MARK: - Inventory Card

private struct InventoryCard: View {
    @ObservedObject var viewModel: ServerConnectionViewModel

    var body: some View {
        AXDepthCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                inventoryHeader
                Divider().background(Color.axBorder)
                inventoryRows
            }
        }
    }

    private var inventoryHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 14))
                .foregroundColor(.axAccentGreen)
            Text("Overview")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Spacer()
        }
    }

    private var inventoryRows: some View {
        VStack(spacing: AXSpacing.sm) {
            inventoryRow(
                icon: "globe",
                color: .axAccentBlue,
                title: "Websites",
                count: viewModel.websiteCount,
                subtitle: viewModel.websiteCount > 0 ? "ALL: \(viewModel.websiteCount)" : "No sites detected",
                tab: .websites
            )
            inventoryRow(
                icon: "cylinder.split.1x2",
                color: .axAccentGreen,
                title: "Databases",
                count: viewModel.databaseCount,
                subtitle: viewModel.databaseCount > 0 ? "ALL: \(viewModel.databaseCount)" : "No databases detected",
                tab: .databases
            )
            inventoryRow(
                icon: "square.stack.3d.up",
                color: .axWarning,
                title: "Services",
                count: viewModel.applicationCount,
                subtitle: viewModel.applicationCount > 0 ? "\(viewModel.applicationCount) active" : "Scanning services",
                tab: .applications
            )
        }
    }

    private func inventoryRow(icon: String, color: Color, title: String, count: Int, subtitle: String, tab: DashboardTab) -> some View {
        Button { viewModel.selectedTab = tab } label: {
            HoverableInventoryRow(icon: icon, color: color, title: title, count: count, subtitle: subtitle, isEnabled: viewModel.isConnected)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!viewModel.isConnected)
    }
}

// MARK: - Hoverable Inventory Row

private struct HoverableInventoryRow: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int
    let subtitle: String
    let isEnabled: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(isHovered ? 0.2 : 0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: AXSpacing.xs) {
                    Text("\(count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.axTextPrimary)
                    Text(title)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                Text(isEnabled ? subtitle : "Connect to view")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isHovered ? color : .axTextMuted)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isHovered ? color.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - System Info Card

private struct SystemInfoCard: View {
    let server: Server
    @ObservedObject var viewModel: ServerConnectionViewModel
    let isMasking: Bool

    private var osDisplayValue: String {
        if let os = server.os, !os.isEmpty, os != "Unknown" { return os }
        return viewModel.detectedOS ?? "Unknown"
    }

    private var ramDisplay: String {
        guard viewModel.totalRAMMB > 0 else { return "" }
        return viewModel.totalRAMMB >= 1024
            ? String(format: "%.0f GB", Double(viewModel.totalRAMMB) / 1024)
            : "\(viewModel.totalRAMMB) MB"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "server.rack")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.45, green: 0.72, blue: 0.90))
                Text("System Info")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                Spacer()
                // Connection badge
                HStack(spacing: 3) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.axAccentGreen : Color.axTextTertiary)
                        .frame(width: 5, height: 5)
                    Text(viewModel.isConnected ? "Connected" : "Offline")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(viewModel.isConnected ? Color.axAccentGreen : Color.axTextTertiary)
                }
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, 2)
                .background((viewModel.isConnected ? Color.axAccentGreen : Color.axTextTertiary).opacity(0.12))
                .cornerRadius(AXCornerRadius.full)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.top, AXSpacing.md)
            .padding(.bottom, AXSpacing.sm)

            // OS row (prominent)
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: osIcon(osDisplayValue))
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(Color(red: 0.45, green: 0.72, blue: 0.90))
                VStack(alignment: .leading, spacing: 1) {
                    Text(osDisplayValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    Text(isMasking ? PrivacyMask.ip(server.host) : server.host)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Uptime")
                        .font(.system(size: 9))
                        .foregroundColor(.axTextTertiary)
                    Text(viewModel.uptime)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)

            Divider()
                .background(Color(red: 0.45, green: 0.72, blue: 0.90).opacity(0.15))
                .padding(.horizontal, AXSpacing.md)

            // Hardware specs row
            HStack(spacing: 0) {
                sysInfoSpecCell(icon: "memorychip", label: "RAM", value: ramDisplay.isEmpty ? "—" : ramDisplay)
                sysInfoDivider
                sysInfoSpecCell(icon: "internaldrive", label: "Disk",
                    value: viewModel.totalDiskGB > 0 ? String(format: "%.0f GB", viewModel.totalDiskGB) : "—")
                sysInfoDivider
                sysInfoSpecCell(icon: "cpu", label: "Cores",
                    value: viewModel.cpuCores > 0 ? "\(viewModel.cpuCores)" : "—")
            }
            .padding(.vertical, AXSpacing.sm)

            // CPU model (if known)
            if !viewModel.cpuModelName.isEmpty {
                Text(viewModel.cpuModelName)
                    .font(.system(size: 10))
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(1)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.bottom, AXSpacing.sm)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(LinearGradient(
                    colors: [Color(red: 0.12, green: 0.20, blue: 0.30).opacity(0.55), Color.axBackgroundTertiary.opacity(0.85)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .strokeBorder(Color(red: 0.45, green: 0.72, blue: 0.90).opacity(0.12), lineWidth: 1)
        )
    }

    private func osIcon(_ os: String) -> String {
        let lower = os.lowercased()
        if lower.contains("ubuntu") || lower.contains("debian") { return "ubuntu.fill" }
        if lower.contains("centos") || lower.contains("rhel") || lower.contains("fedora") || lower.contains("rocky") { return "server.rack" }
        if lower.contains("arch") { return "archivebox" }
        if lower.contains("windows") { return "desktopcomputer" }
        return "terminal"
    }

    private func sysInfoSpecCell(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(Color(red: 0.45, green: 0.72, blue: 0.90).opacity(0.8))
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.axTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var sysInfoDivider: some View {
        Rectangle()
            .fill(Color(red: 0.45, green: 0.72, blue: 0.90).opacity(0.10))
            .frame(width: 1, height: 36)
    }
}

// MARK: - Quick Actions Card

private struct QuickActionsCard: View {
    let serverId: String
    @ObservedObject var viewModel: ServerConnectionViewModel

    private let actions: [(icon: String, title: String, subtitle: String, color: Color, tag: Int)] = [
        ("bolt.circle.fill",        "Setup",    "Install stack",   Color(red: 0.25, green: 0.55, blue: 0.95), 0),
        ("terminal",                "Terminal", "SSH shell",       Color(red: 0.35, green: 0.72, blue: 0.95), 1),
        ("arrow.up.doc",            "Deploy",   "Push code",       Color(red: 0.25, green: 0.75, blue: 0.55), 2),
        ("arrow.counterclockwise",  "Restart",  "Reboot server",   Color(red: 0.95, green: 0.65, blue: 0.20), 3),
        ("doc.text.magnifyingglass","Logs",     "View logs",       Color(red: 0.40, green: 0.75, blue: 0.85), 4),
        ("gearshape",               "Config",   "Settings",        Color(red: 0.60, green: 0.60, blue: 0.70), 5),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.25))
                Text("Quick Actions")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.top, AXSpacing.md)
            .padding(.bottom, AXSpacing.sm)

            Divider()
                .background(Color(red: 0.95, green: 0.75, blue: 0.25).opacity(0.15))
                .padding(.horizontal, AXSpacing.md)

            // 3×2 action grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AXSpacing.sm),
                GridItem(.flexible(), spacing: AXSpacing.sm),
                GridItem(.flexible(), spacing: AXSpacing.sm),
            ], spacing: AXSpacing.sm) {
                ForEach(actions, id: \.tag) { action in
                    QuickActionTile(
                        icon: action.icon,
                        title: action.title,
                        subtitle: action.subtitle,
                        color: action.color,
                        isEnabled: viewModel.isConnected
                    ) {
                        handleAction(tag: action.tag)
                    }
                }
            }
            .padding(AXSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(LinearGradient(
                    colors: [Color(red: 0.22, green: 0.18, blue: 0.10).opacity(0.55), Color.axBackgroundTertiary.opacity(0.85)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .strokeBorder(Color(red: 0.95, green: 0.75, blue: 0.25).opacity(0.12), lineWidth: 1)
        )
    }

    private func handleAction(tag: Int) {
        switch tag {
        case 0:
            let qi = QuickInstallViewModel(serverId: serverId, profile: viewModel.serverProfile)
            viewModel.quickInstallVM = qi
            Task { await qi.scanServer() }
        case 1:
            viewModel.selectedTab = .terminal
        case 2:
            CoreLogger.shared.info("Deploy action triggered", module: "OverviewTab")
        case 3:
            viewModel.isRestartConfirming = true
        case 4, 5:
            viewModel.selectedTab = .settings
        default:
            break
        }
    }
}

private struct QuickActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(isEnabled ? color : color.opacity(0.35))
                    .frame(height: 22)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isEnabled ? .axTextPrimary : .axTextTertiary)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.axTextTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isHovered && isEnabled
                        ? color.opacity(0.18)
                        : color.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .strokeBorder(isHovered && isEnabled ? color.opacity(0.35) : color.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in isHovered = hovering }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - CPU Metric Card (with per-core hover popup)

private struct CPUMetricCard: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    @State private var showPopover = false
    @State private var hoverTask: Task<Void, Never>?

    private var reactiveColor: Color {
        if viewModel.cpuUsage < 50 { return .axAccentBlue }
        if viewModel.cpuUsage < 75 { return .axWarning }
        return .axError
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            cpuCardHeader
            cpuRingDetail
            cpuSparkline
        }
        .padding(AXSpacing.md)
        .background(cpuCardBg)
        .overlay(cpuCardBorder)
        .shadow(color: reactiveColor.opacity(0.08), radius: 4, x: 0, y: 2)
        .onHover { hovering in
            hoverTask?.cancel()
            if hovering {
                hoverTask = Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    guard !Task.isCancelled else { return }
                    showPopover = true
                    await viewModel.fetchCPUCores()
                }
            } else {
                showPopover = false
            }
        }
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            CPUDetailPopover(viewModel: viewModel)
        }
    }

    private var cpuCardHeader: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "cpu")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(reactiveColor)
            Text("CPU")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            Spacer()
        }
    }

    private var cpuRingDetail: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                ProgressRing(progress: min(viewModel.cpuUsage, 100), color: reactiveColor, lineWidth: 5, size: 64)
                Text("\(Int(viewModel.cpuUsage))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(viewModel.cpuCores > 0 ? "\(viewModel.cpuCores) cores" : "—")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextPrimary)
                HStack(spacing: 3) {
                    Circle().fill(reactiveColor).frame(width: 5, height: 5)
                    Text(viewModel.cpuUsage < 50 ? "Normal" : viewModel.cpuUsage < 75 ? "Moderate" : "High")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(reactiveColor)
                }
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, 2)
                .background(reactiveColor.opacity(0.1))
                .cornerRadius(AXCornerRadius.xs)
                Text("Real-time")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
            }
        }
    }

    private var cpuSparkline: some View {
        Group {
            if viewModel.cpuUsageHistory.contains(where: { $0 > 0 }) {
                SparklineView(data: viewModel.cpuUsageHistory, color: reactiveColor, lineWidth: 1.5, fillGradient: true)
                    .frame(height: 28)
            } else {
                Rectangle()
                    .fill(Color.axBackgroundTertiary.opacity(0.5))
                    .frame(height: 28)
                    .cornerRadius(AXCornerRadius.xs)
            }
        }
    }

    private var cpuCardBg: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .fill(LinearGradient(
                colors: [Color(red: 0.15, green: 0.22, blue: 0.35).opacity(0.5), Color.axBackgroundTertiary.opacity(0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
    }

    private var cpuCardBorder: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .stroke(LinearGradient(
                colors: [Color.axAccentBlue.opacity(0.2), Color.axBorder.opacity(0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ), lineWidth: 1)
    }
}

// MARK: - CPU Detail Popover

private struct CPUDetailPopover: View {
    @ObservedObject var viewModel: ServerConnectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            cpuPopoverHeader
            if !viewModel.cpuModelName.isEmpty {
                Text(viewModel.cpuModelName + (viewModel.cpuCores > 0 ? " × \(viewModel.cpuCores)" : ""))
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(2)
            }
            Divider()
            cpuCoresList
            Divider()
            cpuBreakdownGrid
            Divider()
            cpuProcessRow
        }
        .padding(AXSpacing.lg)
        .frame(width: 300)
        .background(Color.axSurface)
    }

    private var cpuPopoverHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "cpu").font(.system(size: 13)).foregroundColor(.axAccentBlue)
            Text("CPU Detail").font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
            Spacer()
            if viewModel.stats.isFetchingCPUDetail {
                ProgressView().scaleEffect(0.6)
            }
        }
    }

    @ViewBuilder
    private var cpuCoresList: some View {
        if !viewModel.cpuCoreLoads.isEmpty {
            VStack(spacing: 5) {
                ForEach(Array(viewModel.cpuCoreLoads.enumerated()), id: \.offset) { idx, load in
                    CoreLoadRow(coreIndex: idx, load: load)
                }
            }
        } else if viewModel.stats.isFetchingCPUDetail {
            HStack {
                ProgressView().scaleEffect(0.5)
                Text("Sampling cores…")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
        } else {
            Text("No core data")
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
        }
    }

    @ViewBuilder
    private var cpuBreakdownGrid: some View {
        if viewModel.cpuUserPct > 0 || viewModel.cpuIdlePct > 0 {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.xs) {
                CpuBreakdownItem(label: "User",   value: viewModel.cpuUserPct,   color: .axAccentBlue)
                CpuBreakdownItem(label: "System", value: viewModel.cpuSystemPct, color: .axWarning)
                CpuBreakdownItem(label: "IOWait", value: viewModel.cpuIowaitPct, color: .axError)
                CpuBreakdownItem(label: "Idle",   value: viewModel.cpuIdlePct,   color: .axAccentGreen)
                CpuBreakdownItem(label: "Steal",  value: viewModel.cpuStealPct,  color: .axTextMuted)
            }
        }
    }

    private var cpuProcessRow: some View {
        HStack(spacing: AXSpacing.xl) {
            CpuStatLabel(label: "Total Procs",   value: "\(viewModel.processesTotal)")
            CpuStatLabel(label: "Running",       value: "\(viewModel.processesRunning)")
            Spacer()
        }
    }
}

// MARK: - CPU Detail Sub-views

private struct CoreLoadRow: View {
    let coreIndex: Int
    let load: Double

    private var loadColor: Color {
        if load < 50 { return .axAccentGreen }
        if load < 80 { return .axWarning }
        return .axError
    }

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Text("Core \(coreIndex + 1)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .frame(width: 50, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.axBackgroundTertiary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [loadColor.opacity(0.7), loadColor],
                                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(load / 100.0, 1.0))
                        .animation(.easeOut(duration: 0.4), value: load)
                }
            }
            .frame(height: 6)
            Text(String(format: "%.0f%%", load))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(loadColor)
                .frame(width: 34, alignment: .trailing)
        }
    }
}

private struct CpuBreakdownItem: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f%%", value))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.axTextTertiary)
        }
    }
}

private struct CpuStatLabel: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)
            Text(label).font(.system(size: 9)).foregroundColor(.axTextTertiary)
        }
    }
}

// MARK: - RAM Metric Card (with detail hover popup)

private struct RAMMetricCard: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    @State private var showPopover = false
    @State private var hoverTask: Task<Void, Never>?

    private var reactiveColor: Color {
        if viewModel.memoryUsage < 50 { return .axAccentBlue }
        if viewModel.memoryUsage < 75 { return .axWarning }
        return .axError
    }

    private var ramDetail: String {
        guard viewModel.totalRAMMB > 0 else { return "Real-time" }
        if viewModel.totalRAMMB >= 1024 {
            return String(format: "%.1f / %.1f GB",
                Double(viewModel.usedRAMMB) / 1024,
                Double(viewModel.totalRAMMB) / 1024)
        }
        return "\(viewModel.usedRAMMB) / \(viewModel.totalRAMMB) MB"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            ramCardHeader
            ramRingDetail
            ramSparkline
        }
        .padding(AXSpacing.md)
        .background(ramCardBg)
        .overlay(ramCardBorder)
        .shadow(color: reactiveColor.opacity(0.06), radius: 5, x: 0, y: 3)
        .onHover { hovering in
            hoverTask?.cancel()
            if hovering {
                hoverTask = Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    guard !Task.isCancelled else { return }
                    showPopover = true
                }
            } else {
                showPopover = false
            }
        }
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            RAMDetailPopover(viewModel: viewModel)
        }
    }

    private var ramCardHeader: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "memorychip")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(reactiveColor)
            Text("RAM")
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            Spacer()
        }
    }

    private var ramRingDetail: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                ProgressRing(progress: min(viewModel.memoryUsage, 100), color: reactiveColor, lineWidth: 5, size: 64)
                Text("\(Int(viewModel.memoryUsage))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(ramDetail)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                HStack(spacing: 3) {
                    Circle().fill(reactiveColor).frame(width: 5, height: 5)
                    Text(viewModel.memoryUsage < 50 ? "Normal" : viewModel.memoryUsage < 75 ? "Moderate" : "High")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(reactiveColor)
                }
                .padding(.horizontal, AXSpacing.xs)
                .padding(.vertical, 2)
                .background(reactiveColor.opacity(0.1))
                .cornerRadius(AXCornerRadius.xs)
                Text("Real-time")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
            }
        }
    }

    private var ramSparkline: some View {
        Group {
            if viewModel.memoryUsageHistory.contains(where: { $0 > 0 }) {
                SparklineView(data: viewModel.memoryUsageHistory, color: reactiveColor, lineWidth: 1.5, fillGradient: true)
                    .frame(height: 28)
            } else {
                Rectangle()
                    .fill(Color.axBackgroundTertiary.opacity(0.5))
                    .frame(height: 28)
                    .cornerRadius(AXCornerRadius.xs)
            }
        }
    }

    private var ramCardBg: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .fill(LinearGradient(
                colors: [Color(red: 0.22, green: 0.16, blue: 0.32).opacity(0.5), Color.axBackgroundTertiary.opacity(0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
    }

    private var ramCardBorder: some View {
        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
            .stroke(LinearGradient(
                colors: [Color.purple.opacity(0.18), Color.axBorder.opacity(0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ), lineWidth: 1)
    }
}

// MARK: - RAM Detail Popover

private struct RAMDetailPopover: View {
    @ObservedObject var viewModel: ServerConnectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            ramPopoverHeader
            Divider()
            if viewModel.totalRAMMB > 0 {
                ramVisualBar
                Divider()
            }
            ramRowItem(label: "Used",       valueMB: viewModel.usedRAMMB,      color: .axError)
            ramRowItem(label: "Available",  valueMB: viewModel.ramAvailableMB, color: .axAccentGreen)
            ramRowItem(label: "Buff/Cache", valueMB: viewModel.ramBuffCacheMB, color: .axInfo)
            Divider()
            HStack {
                Text("Total").font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextSecondary)
                Spacer()
                Text(formatMB(viewModel.totalRAMMB))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
        }
        .padding(AXSpacing.lg)
        .frame(width: 260)
        .background(Color.axSurface)
    }

    private var ramPopoverHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "memorychip").font(.system(size: 13)).foregroundColor(.axAccentBlue)
            Text("RAM Detail").font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
            Spacer()
        }
    }

    @ViewBuilder
    private var ramVisualBar: some View {
        let total = Double(max(1, viewModel.totalRAMMB))
        let usedRatio   = min(1.0, Double(viewModel.usedRAMMB)      / total)
        let cacheRatio  = min(1.0 - usedRatio, Double(viewModel.ramBuffCacheMB) / total)

        VStack(spacing: AXSpacing.xs) {
            GeometryReader { geo in
                HStack(spacing: 1) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.axError.opacity(0.85))
                        .frame(width: max(4, geo.size.width * usedRatio))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.axInfo.opacity(0.65))
                        .frame(width: max(2, geo.size.width * cacheRatio))
                    Spacer()
                }
            }
            .frame(height: 10)
            .background(RoundedRectangle(cornerRadius: 3).fill(Color.axAccentGreen.opacity(0.2)))
            .cornerRadius(3)

            HStack(spacing: AXSpacing.md) {
                ramLegendDot(color: .axError,       label: "Used")
                ramLegendDot(color: .axInfo,        label: "Cache")
                ramLegendDot(color: .axAccentGreen, label: "Free")
                Spacer()
            }
        }
    }

    private func ramLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9)).foregroundColor(.axTextTertiary)
        }
    }

    private func ramRowItem(label: String, valueMB: Int, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 11)).foregroundColor(.axTextSecondary)
            Spacer()
            Text(formatMB(valueMB))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
        }
    }

    private func formatMB(_ mb: Int) -> String {
        if mb >= 1024 { return String(format: "%.2f GB", Double(mb) / 1024) }
        return "\(mb) MB"
    }
}

// MARK: - Traffic Card (replaces NetworkIOCard with real-time speeds + graphs)

private struct TrafficCard: View {
    @ObservedObject var viewModel: ServerConnectionViewModel

    var body: some View {
        AXDepthCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                trafficHeader
                Divider().background(Color.axBorder)
                trafficSpeedRow
                trafficGraphs
                Divider().background(Color.axBorder)
                trafficTotalsRow
            }
        }
    }

    private var trafficHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14))
                .foregroundColor(.axAccentBlue)
            Text("Network Traffic")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(viewModel.isConnected ? Color.axAccentGreen : Color.axTextMuted)
                    .frame(width: 5, height: 5)
                Text(viewModel.isConnected ? "Live" : "Offline")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(viewModel.isConnected ? .axAccentGreen : .axTextMuted)
            }
        }
    }

    private var trafficSpeedRow: some View {
        HStack(spacing: AXSpacing.xxl) {
            TrafficSpeedItem(icon: "arrow.down.circle.fill", label: "Download",
                             speedKBs: viewModel.netRxSpeedKBs, color: .axAccentGreen)
            TrafficSpeedItem(icon: "arrow.up.circle.fill", label: "Upload",
                             speedKBs: viewModel.netTxSpeedKBs, color: .axAccentBlue)
            Spacer()
        }
    }

    private var trafficGraphs: some View {
        TrafficChartView(
            rxData: viewModel.netRxSpeedHistory,
            txData: viewModel.netTxSpeedHistory
        )
        .frame(height: 100)
        .drawingGroup()
    }

    private var trafficTotalsRow: some View {
        HStack(spacing: AXSpacing.xl) {
            TrafficTotalItem(label: "Total received", value: formatGB(viewModel.netRxGB), color: .axAccentGreen)
            TrafficTotalItem(label: "Total sent", value: formatGB(viewModel.netTxGB), color: .axAccentBlue)
            Spacer()
            Text("Since boot")
                .font(.system(size: 9))
                .foregroundColor(.axTextTertiary)
        }
    }

    private func formatGB(_ gb: Double) -> String {
        if gb >= 1 { return String(format: "%.2f GB", gb) }
        return String(format: "%.0f MB", gb * 1024)
    }
}

// MARK: - Traffic Chart (combined RX/TX with Y-axis labels)

private struct TrafficChartView: View {
    let rxData: [Double]
    let txData: [Double]

    private var maxValue: Double {
        let allMax = max(rxData.max() ?? 0, txData.max() ?? 0)
        return max(allMax, 1) // Avoid division by zero
    }

    private func yLabels(maxVal: Double) -> [String] {
        if maxVal >= 1024 * 1024 {
            let top = maxVal / 1024 / 1024
            return [String(format: "%.1f GB/s", top), String(format: "%.1f", top / 2), "0"]
        } else if maxVal >= 1024 {
            let top = maxVal / 1024
            return [String(format: "%.0f MB/s", top), String(format: "%.0f", top / 2), "0"]
        } else {
            let top = maxVal
            return [String(format: "%.0f KB/s", top), String(format: "%.0f", top / 2), "0"]
        }
    }

    var body: some View {
        let labels = yLabels(maxVal: maxValue)
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: AXSpacing.xs) {
                // Y-axis labels
                VStack {
                    Text(labels[0])
                    Spacer()
                    Text(labels[1])
                    Spacer()
                    Text(labels[2])
                }
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.axTextTertiary)
                .frame(width: 52, alignment: .trailing)

                // Chart area
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        // Grid lines
                        ForEach(0..<3) { i in
                            let y = geo.size.height * CGFloat(i) / 2.0
                            Path { p in
                                p.move(to: CGPoint(x: 0, y: y))
                                p.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                            .stroke(Color.axBorder.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        }

                        // RX (download) filled area + line
                        trafficPath(data: rxData, in: geo.size, filled: true)
                            .fill(
                                LinearGradient(
                                    colors: [Color.axAccentGreen.opacity(0.25), Color.axAccentGreen.opacity(0.02)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        trafficPath(data: rxData, in: geo.size, filled: false)
                            .stroke(Color.axAccentGreen, lineWidth: 1.5)

                        // TX (upload) filled area + line
                        trafficPath(data: txData, in: geo.size, filled: true)
                            .fill(
                                LinearGradient(
                                    colors: [Color.axAccentBlue.opacity(0.20), Color.axAccentBlue.opacity(0.02)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        trafficPath(data: txData, in: geo.size, filled: false)
                            .stroke(Color.axAccentBlue, lineWidth: 1.5)
                    }
                }
                .background(Color.axBackgroundTertiary.opacity(0.3).cornerRadius(AXCornerRadius.sm))
            }

            // Legend
            HStack(spacing: AXSpacing.lg) {
                Spacer().frame(width: 52)
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1).fill(Color.axAccentGreen).frame(width: 12, height: 3)
                    Text("Download").font(.system(size: 9)).foregroundColor(.axTextTertiary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1).fill(Color.axAccentBlue).frame(width: 12, height: 3)
                    Text("Upload").font(.system(size: 9)).foregroundColor(.axTextTertiary)
                }
                Spacer()
            }
            .padding(.top, 2)
        }
    }

    private func trafficPath(data: [Double], in size: CGSize, filled: Bool) -> Path {
        Path { path in
            guard data.count > 1 else { return }
            let maxVal = maxValue
            let stepX = size.width / CGFloat(data.count - 1)

            let startY = size.height - (CGFloat(data[0] / maxVal) * size.height)
            path.move(to: CGPoint(x: 0, y: startY))

            for (i, val) in data.enumerated().dropFirst() {
                let x = CGFloat(i) * stepX
                let y = size.height - (CGFloat(val / maxVal) * size.height)
                path.addLine(to: CGPoint(x: x, y: y))
            }

            if filled {
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
            }
        }
    }
}

private struct TrafficSpeedItem: View {
    let icon: String
    let label: String
    let speedKBs: Double
    let color: Color

    private var speedFormatted: (value: String, unit: String) {
        if speedKBs >= 1024 * 1024 { return (String(format: "%.2f", speedKBs / 1024 / 1024), "GB/s") }
        if speedKBs >= 1024        { return (String(format: "%.2f", speedKBs / 1024),          "MB/s") }
        return (String(format: "%.0f", speedKBs), "KB/s")
    }

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(speedFormatted.value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.axTextPrimary)
                    Text(speedFormatted.unit)
                        .font(.system(size: 10))
                        .foregroundColor(.axTextSecondary)
                }
            }
        }
    }
}

private struct TrafficTotalItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Circle().fill(color).frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 9)).foregroundColor(.axTextTertiary)
                Text(value).font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextPrimary)
            }
        }
    }
}

// MARK: - Network I/O Card (legacy — kept for compatibility, use TrafficCard for new layouts)

private struct NetworkIOCard: View {
    @ObservedObject var viewModel: ServerConnectionViewModel

    private func formatGB(_ gb: Double) -> String {
        if gb >= 1 { return String(format: "%.2f GB", gb) }
        return String(format: "%.0f MB", gb * 1024)
    }

    var body: some View {
        AXDepthCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "network")
                        .font(.system(size: 14))
                        .foregroundColor(.axAccentBlue)
                    Text("Network I/O")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Spacer()
                    Text("Since boot")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextTertiary)
                }

                Divider().background(Color.axBorder)

                HStack(spacing: AXSpacing.xl) {
                    NetworkStatItem(
                        icon: "arrow.down.circle.fill",
                        label: "Received",
                        value: formatGB(viewModel.netRxGB),
                        color: .axAccentGreen
                    )
                    NetworkStatItem(
                        icon: "arrow.up.circle.fill",
                        label: "Sent",
                        value: formatGB(viewModel.netTxGB),
                        color: .axAccentBlue
                    )
                    Spacer()
                }
            }
        }
    }
}

private struct NetworkStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
            }
        }
    }
}

// MARK: - Server Load Card (replaces Swap — shows load detail + swap if configured)

private struct ServerLoadCard: View {
    @ObservedObject var viewModel: ServerConnectionViewModel

    private var loadValues: (l1: Double, l5: Double, l15: Double) {
        let p = viewModel.loadAverage.split(separator: " ").compactMap { Double($0) }
        return (p.count > 0 ? p[0] : 0, p.count > 1 ? p[1] : 0, p.count > 2 ? p[2] : 0)
    }

    private var swapDetail: String {
        guard viewModel.swapTotalMB > 0 else { return "" }
        if viewModel.swapTotalMB >= 1024 {
            return String(format: "%.1f / %.1f GB",
                Double(viewModel.swapUsedMB) / 1024, Double(viewModel.swapTotalMB) / 1024)
        }
        return "\(viewModel.swapUsedMB) / \(viewModel.swapTotalMB) MB"
    }

    var body: some View {
        AXDepthCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                cardHeader
                Divider().background(Color.axBorder)
                loadAverageRows
                if viewModel.cpuUserPct > 0 || viewModel.cpuIdlePct > 0 {
                    Divider().background(Color.axBorder)
                    cpuBreakdownRows
                }
                if viewModel.processesTotal > 0 {
                    Divider().background(Color.axBorder)
                    processRow
                }
                if viewModel.swapTotalMB > 0 {
                    Divider().background(Color.axBorder)
                    swapRow
                }
            }
        }
    }

    private var cardHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "speedometer")
                .font(.system(size: 14))
                .foregroundColor(.axAccentBlue)
            Text("Server Load")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Spacer()
            if viewModel.cpuCores > 0 {
                Text("\(viewModel.cpuCores) cores")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.xs)
            }
        }
    }

    private var loadAverageRows: some View {
        VStack(spacing: AXSpacing.sm) {
            loadRow(label: "1 min",  value: loadValues.l1)
            loadRow(label: "5 min",  value: loadValues.l5)
            loadRow(label: "15 min", value: loadValues.l15)
        }
    }

    private func loadRow(label: String, value: Double) -> some View {
        let cores = max(1, viewModel.cpuCores)
        let ratio = min(value / Double(cores), 1.0)
        let color: Color = ratio < 0.5 ? .axAccentGreen : ratio < 0.85 ? .axWarning : .axError
        return HStack(spacing: AXSpacing.sm) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .frame(width: 42, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.axBackgroundTertiary)
                    RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.7)).frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 6)
            Text(String(format: "%.2f", value))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 34, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var cpuBreakdownRows: some View {
        let items: [(String, Double, Color)] = [
            ("User",   viewModel.cpuUserPct,   .axAccentBlue),
            ("System", viewModel.cpuSystemPct, .axWarning),
            ("IOWait", viewModel.cpuIowaitPct, .axError),
            ("Idle",   viewModel.cpuIdlePct,   .axAccentGreen),
        ]
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.xs) {
            ForEach(items, id: \.0) { item in
                HStack(spacing: AXSpacing.xs) {
                    Circle().fill(item.2).frame(width: 5, height: 5)
                    Text(item.0).font(.system(size: 9)).foregroundColor(.axTextTertiary)
                    Spacer()
                    Text(String(format: "%.1f%%", item.1))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(item.2)
                }
            }
        }
    }

    private var processRow: some View {
        HStack(spacing: AXSpacing.xl) {
            VStack(spacing: 1) {
                Text("\(viewModel.processesTotal)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                Text("Total procs").font(.system(size: 9)).foregroundColor(.axTextTertiary)
            }
            VStack(spacing: 1) {
                Text("\(viewModel.processesRunning)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.axAccentGreen)
                Text("Running").font(.system(size: 9)).foregroundColor(.axTextTertiary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var swapRow: some View {
        let swapColor: Color = viewModel.swapUsage < 50 ? .axAccentGreen : viewModel.swapUsage < 80 ? .axWarning : .axError
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "memorychip.fill").font(.system(size: 12)).foregroundColor(.axInfo)
            Text("Swap").font(.system(size: 11)).foregroundColor(.axTextSecondary)
            Spacer()
            Text(swapDetail).font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextPrimary)
            Text(String(format: "%.0f%%", viewModel.swapUsage))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(swapColor)
        }
    }
}

// MARK: - AX Depth Card (3D-look wrapper)

struct AXDepthCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(AXSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [Color.axSurface, Color.axSurface.opacity(0.82)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.axBorder.opacity(0.35),
                                Color.black.opacity(0.12)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Connection Status Bar

struct ConnectionStatusBar: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    @State private var showDisconnectConfirm = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            statusIndicator
            if viewModel.isConnecting {
                connectingContent
            } else if let error = viewModel.connectionError {
                errorContent(error)
            } else if viewModel.isConnected {
                connectedContent
            } else {
                disconnectedContent
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(AXCornerRadius.md)
    }

    private var statusIndicator: some View {
        HStack(spacing: AXSpacing.sm) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.6), radius: 4)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 2)
                        .scaleEffect(viewModel.isConnecting ? 1.5 : 1.0)
                        .opacity(viewModel.isConnecting ? 0 : 1)
                )
            Text(statusText)
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
    }

    @ViewBuilder
    private var connectingContent: some View {
        ProgressView(value: viewModel.connectionProgress)
            .progressViewStyle(LinearProgressViewStyle(tint: .axAccentBlue))
            .frame(width: 120)
        Text(viewModel.connectionStage.rawValue)
            .font(AXTypography.caption)
            .foregroundColor(.axTextSecondary)
        Spacer()
        Button("Cancel") { Task { await viewModel.disconnect() } }
            .font(AXTypography.caption)
            .foregroundColor(.axError)
    }

    @ViewBuilder
    private func errorContent(_ error: String) -> some View {
        Spacer()
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.axError)
            Text(error).font(AXTypography.caption).foregroundColor(.axError).lineLimit(1)
        }
        Spacer()
        Button("Retry") { Task { await viewModel.connect() } }
            .font(AXTypography.caption).foregroundColor(.axAccentBlue)
    }

    @ViewBuilder
    private var connectedContent: some View {
        Spacer()
        Button("Disconnect") {
            if AppSettingsManager.shared.shouldConfirm(for: SettingsKey.confirmDisconnectServer) {
                showDisconnectConfirm = true
            } else {
                Task { await viewModel.disconnect() }
            }
        }
        .font(AXTypography.caption)
        .foregroundColor(.axTextSecondary)
        .alert("Disconnect Server", isPresented: $showDisconnectConfirm) {
            Button("Disconnect", role: .destructive) { Task { await viewModel.disconnect() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to disconnect from this server?")
        }
    }

    @ViewBuilder
    private var disconnectedContent: some View {
        Spacer()
        Button("Connect") { Task { await viewModel.connect() } }
            .font(AXTypography.caption).foregroundColor(.axAccentBlue)
    }

    private var statusColor: Color {
        if viewModel.isConnected { return .axSuccess }
        if viewModel.isConnecting { return .axWarning }
        if viewModel.connectionError != nil { return .axError }
        return .axTextMuted
    }

    private var statusText: String {
        if viewModel.isConnected { return "Connected" }
        if viewModel.isConnecting { return "Connecting..." }
        if viewModel.connectionError != nil { return "Connection Failed" }
        return "Disconnected"
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var isEnabled: Bool = true
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isEnabled ? color : .axTextMuted)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(isEnabled ? color.opacity(0.1) : Color.axBackgroundTertiary)
                    )

                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(isEnabled ? .axTextSecondary : .axTextMuted)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}

// MARK: - System Info Row

struct SystemInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextTertiary)
                .lineLimit(1)
            Text(value)
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.axTextPrimary)
                .monospaced()
                .lineLimit(1)
        }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.axBackgroundTertiary, lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: min(progress / 100, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Sparkline View

struct SparklineView: View {
    let data: [Double]
    let color: Color
    let lineWidth: CGFloat
    let fillGradient: Bool

    private func points(in size: CGSize) -> [CGPoint] {
        guard data.count > 1,
              let maxValue = data.max(),
              let minValue = data.min(),
              maxValue > minValue else { return [] }
        let stepX = size.width / CGFloat(data.count - 1)
        let range = maxValue - minValue
        return data.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * stepX,
                y: size.height - ((value - minValue) / range) * size.height
            )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let pts = points(in: geometry.size)
            if !pts.isEmpty {
                Path { path in
                    path.move(to: pts[0])
                    for pt in pts.dropFirst() { path.addLine(to: pt) }
                }
                .stroke(color, lineWidth: lineWidth)

                if fillGradient {
                    Path { path in
                        path.move(to: pts[0])
                        for pt in pts.dropFirst() { path.addLine(to: pt) }
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Fresh Server Banner

struct FreshServerBanner: View {
    let onSetup: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.axAccentBlue.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Fresh server detected")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text("No services found — set up your environment with one click")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }

            Spacer()

            Button(action: onSetup) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "bolt.fill").font(.system(size: 11, weight: .semibold))
                    Text("Setup Server").font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    LinearGradient(
                        colors: [.axAccentBlue, .axAccentBlue.opacity(0.8)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(AXCornerRadius.md)
                .scaleEffect(isHovered ? 1.03 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovered = $0 }
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axAccentBlue.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axAccentBlue.opacity(0.25), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Inventory Row (legacy — kept for compatibility)

struct InventoryRow: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int
    let subtitle: String

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: AXSpacing.xs) {
                    Text("\(count)").font(AXTypography.title3).fontWeight(.bold).foregroundColor(.axTextPrimary)
                    Text(title).font(AXTypography.caption).foregroundColor(.axTextSecondary)
                }
                Text(subtitle).font(AXTypography.caption2).foregroundColor(.axTextTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(.axTextMuted)
        }
    }
}

// MARK: - Preview

#Preview {
    let previewServer = Server.placeholder(name: "No Touch")
    let previewViewModel = ServerConnectionViewModel(server: previewServer, serverId: "preview-id")
    OverviewTab(server: previewServer, serverId: "preview-id", viewModel: previewViewModel)
        .padding()
        .background(Color.axBackground)
}
