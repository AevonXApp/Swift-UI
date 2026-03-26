//
//  OverviewTab.swift
//  AevonX
//
//  Overview tab with real-time system vitals from SSH connection
//  Binds to ServerConnectionViewModel for live data
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
            VStack(spacing: AXSpacing.xl) {
                
                // MARK: - Connection Status Bar
                ConnectionStatusBar(viewModel: viewModel)
                
                // MARK: - Fresh Server Banner (auto-shown after scan)
                if settings.showFreshServerBanner, viewModel.isConnected, let qi = viewModel.quickInstallVM, !qi.isVisible == false,
                   qi.serverScan?.isEmpty == true, !qi.isInstalling {
                    FreshServerBanner {
                        viewModel.quickInstallVM?.isVisible = true
                        viewModel.quickInstallVM?.isMinimized = false
                    }
                }
                
                // MARK: - Quick Vitals Grid
                if settings.showQuickVitals { AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Image(systemName: "bolt.heart.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.axAccentBlue)
                            
                            Text("Quick Vitals")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            Spacer()
                            
                            // Live indicator - only show when connected
                            if viewModel.isConnected {
                                HStack(spacing: AXSpacing.xs) {
                                    Circle()
                                        .fill(Color.axSuccess)
                                        .frame(width: 6, height: 6)
                                    
                                    Text("Live")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                }
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.xxs)
                                .background(Color.axSuccess.opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        // Vitals Grid - 4 columns for CPU, RAM, Disk, Temp
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: AXSpacing.lg),
                            GridItem(.flexible(), spacing: AXSpacing.lg),
                            GridItem(.flexible(), spacing: AXSpacing.lg),
                            GridItem(.flexible(), spacing: AXSpacing.lg)
                        ], spacing: AXSpacing.lg) {
                            
                            // CPU Card
                            QuickVitalCard(
                                title: "CPU",
                                value: viewModel.cpuUsage,
                                unit: "%",
                                icon: "cpu",
                                color: .axAccentBlue,
                                history: viewModel.cpuUsageHistory,
                                detail: viewModel.isConnected ? "Real-time" : "Not connected"
                            )
                            
                            // Memory Card
                            QuickVitalCard(
                                title: "RAM",
                                value: viewModel.memoryUsage,
                                unit: "%",
                                icon: "memorychip",
                                color: .axAccentGreen,
                                history: viewModel.memoryUsageHistory,
                                detail: viewModel.isConnected ? "Real-time" : "Not connected"
                            )
                            
                            // Disk Card
                            QuickVitalCard(
                                title: "Disk",
                                value: viewModel.diskUsage,
                                unit: "%",
                                icon: "internaldrive",
                                color: .axWarning,
                                history: viewModel.diskUsageHistory,
                                detail: viewModel.isConnected ? "Real-time" : "Not connected"
                            )
                            
                            // Temperature Card
                            QuickVitalCard(
                                title: "Temp",
                                value: viewModel.cpuTemperature ?? 0,
                                unit: "°C",
                                icon: "thermometer",
                                color: tempColor(viewModel.cpuTemperature ?? 0),
                                history: viewModel.temperatureHistory,
                                detail: viewModel.isConnected ? "CPU Package" : "Not connected"
                            )
                        }
                    }
                } }

                // MARK: - Inventory Summary & System Info Row
                HStack(spacing: AXSpacing.lg) {
                    
                    // Inventory Summary
                    if settings.showInventory { AXCard {
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            HStack {
                                Image(systemName: "cube.box")
                                    .font(.system(size: 16))
                                    .foregroundColor(.axAccentGreen)
                                
                                Text("Inventory")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                            }
                            
                            Divider()
                                .background(Color.axBorder)
                            
                            VStack(spacing: AXSpacing.md) {
                                Button(action: {
                                    viewModel.selectedTab = .websites
                                }) {
                                    InventoryRow(
                                        icon: "globe",
                                        color: .axAccentBlue,
                                        title: "Websites",
                                        count: viewModel.websiteCount,
                                        subtitle: viewModel.isConnected ? "Nginx vhosts" : "Connect to view"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!viewModel.isConnected)
    
                                Button(action: {
                                    viewModel.selectedTab = .databases
                                }) {
                                    InventoryRow(
                                        icon: "cylinder.split.1x2",
                                        color: .axAccentGreen,
                                        title: "Databases",
                                        count: viewModel.databaseCount,
                                        subtitle: viewModel.isConnected ? "MySQL & PostgreSQL" : "Connect to view"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!viewModel.isConnected)
    
                                Button(action: {
                                    viewModel.selectedTab = .applications
                                }) {
                                    InventoryRow(
                                        icon: "square.stack.3d.up",
                                        color: .axWarning,
                                        title: "Applications",
                                        count: viewModel.applicationCount,
                                        subtitle: viewModel.isConnected ? "Active services" : "Connect to view"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!viewModel.isConnected)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) }

                    // System Info
                    AXCard {
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(.axInfo)
                                
                                Text("System Info")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                            }
                            
                            Divider()
                                .background(Color.axBorder)
                            
                            VStack(spacing: AXSpacing.md) {
                                SystemInfoRow(label: "Operating System", value: server.os ?? "Unknown")
                                SystemInfoRow(label: "IP Address", value: isMaskingDashboard ? PrivacyMask.ip(server.host) : server.host)
                                SystemInfoRow(label: "Hostname", value: isMaskingDashboard ? PrivacyMask.hostname(server.host) : server.host)
                                SystemInfoRow(label: "Uptime", value: viewModel.uptime)
                                SystemInfoRow(label: "Load Average", value: viewModel.loadAverage)
                                SystemInfoRow(label: "Connection", value: viewModel.connectionStage.rawValue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // MARK: - Quick Actions
                if settings.showQuickActions { AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Image(systemName: "bolt.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.axWarning)
                            
                            Text("Quick Actions")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.axBorder)
                        
                        HStack(spacing: AXSpacing.lg) {
                            QuickActionButton(
                                icon: "bolt.circle.fill",
                                title: "Setup Server",
                                color: .axAccentBlue,
                                isEnabled: viewModel.isConnected,
                                action: {
                                    let qi = QuickInstallViewModel(
                                        serverId: serverId,
                                        profile: viewModel.serverProfile
                                    )
                                    viewModel.quickInstallVM = qi
                                    // Start server scan in background
                                    Task { await qi.scanServer() }
                                }
                            )
                            QuickActionButton(
                                icon: "terminal",
                                title: "Terminal",
                                color: .axAccentBlue,
                                isEnabled: viewModel.isConnected,
                                action: {
                                    viewModel.selectedTab = .terminal
                                }
                            )
                            QuickActionButton(
                                icon: "arrow.up.doc",
                                title: "Deploy",
                                color: .axAccentGreen,
                                isEnabled: viewModel.isConnected,
                                action: {
                                    CoreLogger.shared.info("Deploy action triggered", module: "OverviewTab")
                                }
                            )
                            QuickActionButton(
                                icon: "arrow.counterclockwise",
                                title: "Restart",
                                color: .axWarning,
                                isEnabled: viewModel.isConnected,
                                action: {
                                    viewModel.isRestartConfirming = true
                                }
                            )
                            QuickActionButton(
                                icon: "exclamationmark.shield",
                                title: "Logs",
                                color: .axInfo,
                                isEnabled: viewModel.isConnected,
                                action: {
                                    viewModel.selectedTab = .terminal
                                }
                            )
                            QuickActionButton(
                                icon: "gearshape",
                                title: "Config",
                                color: .axTextSecondary,
                                isEnabled: viewModel.isConnected,
                                action: {
                                    viewModel.selectedTab = .settings
                                }
                            )
                            Spacer()
                        }
                    }
                } }
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            // Note: Connection is managed by parent ServerDashboardView
            // We don't auto-connect here to avoid duplicate connections
            CoreLogger.shared.debug("onAppear - isConnected: \(viewModel.isConnected)", module: "OverviewTab")
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                viewModel.appWillEnterForeground()
            case .background, .inactive:
                viewModel.appDidEnterBackground()
            @unknown default:
                break
            }
        }
    }
    
    private func tempColor(_ temp: Double) -> Color {
        if temp < 50 {
            return .axAccentGreen
        } else if temp < 70 {
            return .axWarning
        } else {
            return .axError
        }
    }

    private var isMaskingDashboard: Bool {
        settings.maskServerInfo && settings.maskInDashboard && settings.maskIPAddresses
    }
}

// MARK: - Connection Status Bar

struct ConnectionStatusBar: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    @State private var showDisconnectConfirm = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Connection Status Indicator
            HStack(spacing: AXSpacing.sm) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
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
            
            if viewModel.isConnecting {
                // Progress indicator
                ProgressView(value: viewModel.connectionProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .axAccentBlue))
                    .frame(width: 120)
                
                Text(viewModel.connectionStage.rawValue)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    
                Spacer()
                
                Button("Cancel") {
                    Task {
                        await viewModel.disconnect()
                    }
                }
                .font(AXTypography.caption)
                .foregroundColor(.axError)
            } else if let error = viewModel.connectionError {
                Spacer()
                
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.axError)
                    
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button("Retry") {
                    Task {
                        await viewModel.connect()
                    }
                }
                .font(AXTypography.caption)
                .foregroundColor(.axAccentBlue)
            } else if viewModel.isConnected {
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
                    Button("Disconnect", role: .destructive) {
                        Task { await viewModel.disconnect() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to disconnect from this server?")
                }
            } else {
                Spacer()
                
                Button("Connect") {
                    Task {
                        await viewModel.connect()
                    }
                }
                .font(AXTypography.caption)
                .foregroundColor(.axAccentBlue)
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
    
    private var statusColor: Color {
        if viewModel.isConnected {
            return .axSuccess
        } else if viewModel.isConnecting {
            return .axWarning
        } else if viewModel.connectionError != nil {
            return .axError
        } else {
            return .axTextMuted
        }
    }
    
    private var statusText: String {
        if viewModel.isConnected {
            return "Connected"
        } else if viewModel.isConnecting {
            return "Connecting..."
        } else if viewModel.connectionError != nil {
            return "Connection Failed"
        } else {
            return "Disconnected"
        }
    }
}

// MARK: - Quick Vital Card
struct QuickVitalCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color
    let history: [Double]
    let detail: String
    
    var body: some View {
        VStack(spacing: AXSpacing.sm) {
            // Header with icon
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                Spacer()
                
                // Trend indicator
                if history.count >= 2 {
                    Image(systemName: trendIcon)
                        .font(.system(size: 8))
                        .foregroundColor(trendColor)
                }
            }
            
            // Value with ring
            ZStack {
                ProgressRing(
                    progress: min(value, 100),
                    color: color,
                    lineWidth: 4,
                    size: 56
                )
                
                VStack(spacing: 0) {
                    Text("\(Int(value))\(unit)")
                        .font(AXTypography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                }
            }
            
            // Sparkline
            if !history.isEmpty && history.contains(where: { $0 > 0 }) {
                SparklineView(data: history, color: color, lineWidth: 1.5, fillGradient: true)
                    .frame(height: 24)
            } else {
                // Placeholder when no data
                Rectangle()
                    .fill(Color.axBackgroundTertiary)
                    .frame(height: 24)
                    .cornerRadius(AXCornerRadius.sm)
            }
            
            // Detail
            Text(detail)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextTertiary)
                .lineLimit(1)
        }
        .padding(AXSpacing.md)
        .background(Color.axBackgroundTertiary)
        .cornerRadius(AXCornerRadius.md)
    }
    
    private var trendIcon: String {
        guard let last = history.last, let first = history.first, history.count >= 2 else { return "minus" }
        if last > first { return "arrow.up" }
        if last < first { return "arrow.down" }
        return "minus"
    }
    
    private var trendColor: Color {
        guard let last = history.last, let first = history.first, history.count >= 2 else { return .axTextMuted }
        if title == "Temp" || title == "CPU" {
            return last > first ? .axError : .axSuccess
        }
        return last > first ? .axWarning : .axSuccess
    }
}

// MARK: - Inventory Row
struct InventoryRow: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int
    let subtitle: String
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: AXSpacing.xs) {
                    Text("\(count)")
                        .font(AXTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(title)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                
                Text(subtitle)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
        }
    }
}

// MARK: - System Info Row
struct SystemInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.axTextPrimary)
                .monospaced()
        }
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
                    .background(isEnabled ? color.opacity(0.1) : Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.lg)
                
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(isEnabled ? .axTextSecondary : .axTextMuted)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
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
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

// MARK: - Sparkline View

struct SparklineView: View {
    let data: [Double]
    let color: Color
    let lineWidth: CGFloat
    let fillGradient: Bool

    /// Produces the array of CGPoints for the given geometry size.
    private func sparklinePoints(in size: CGSize) -> [CGPoint] {
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
            let points = sparklinePoints(in: geometry.size)

            if !points.isEmpty {
                // Stroke path
                Path { path in
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color, lineWidth: lineWidth)

                // Fill gradient (optional)
                if fillGradient {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(color.opacity(0.1))
                }
            }
        }
    }
}

// MARK: - Fresh Server Banner

/// Shown automatically in OverviewTab when the server scan detects a fresh/empty server
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
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Setup Server")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(
                    LinearGradient(
                        colors: [.axAccentBlue, .axAccentBlue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AXCornerRadius.md)
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
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

#Preview {
    let previewServer = Server.placeholder(name: "Preview Server")
    let previewViewModel = ServerConnectionViewModel(
        server: previewServer,
        serverId: "preview-id"
    )
    OverviewTab(server: previewServer, serverId: "preview-id", viewModel: previewViewModel)
        .padding()
        .background(Color.axBackground)
}
