//
//  OverviewTab.swift
//  AevonX
//
//  Overview tab with real-time system vitals from SSH connection
//  Binds to ServerConnectionViewModel for live data
//

import SwiftUI
import AevonXCore

struct OverviewTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var viewModel: ServerConnectionViewModel
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
                
                // MARK: - Quick Vitals Grid
                AXCard {
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
                }
                
                // MARK: - Inventory Summary & System Info Row
                HStack(spacing: AXSpacing.lg) {
                    
                    // Inventory Summary
                    AXCard {
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
                                        count: viewModel.databases.count,
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
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
                                SystemInfoRow(label: "IP Address", value: server.host)
                                SystemInfoRow(label: "Hostname", value: server.host)
                                SystemInfoRow(label: "Uptime", value: viewModel.uptime)
                                SystemInfoRow(label: "Load Average", value: viewModel.loadAverage)
                                SystemInfoRow(label: "Connection", value: viewModel.connectionStage.rawValue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // MARK: - Quick Actions
                AXCard {
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
                                    // TODO: Open Deploy modal
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
                                    // Pre-fill with log viewing command
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        // The terminal will be opened, user can type log commands
                                    }
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
                }
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            // Note: Connection is managed by parent ServerDashboardView
            // We don't auto-connect here to avoid duplicate connections
            print("[OverviewTab] onAppear - isConnected: \(viewModel.isConnected)")
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
}

// MARK: - Connection Status Bar

struct ConnectionStatusBar: View {
    @ObservedObject var viewModel: ServerConnectionViewModel
    
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
                    Task {
                        await viewModel.disconnect()
                    }
                }
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
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
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1,
                      let maxValue = data.max(),
                      let minValue = data.min(),
                      maxValue > minValue else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                let range = maxValue - minValue
                
                var points: [CGPoint] = []
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - ((value - minValue) / range) * height
                    points.append(CGPoint(x: x, y: y))
                }
                
                guard let firstPoint = points.first else { return }
                path.move(to: firstPoint)
                
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(color, lineWidth: lineWidth)
            .background(
                fillGradient ? 
                Path { path in
                    guard data.count > 1,
                          let maxValue = data.max(),
                          let minValue = data.min(),
                          maxValue > minValue else { return }
                    
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(data.count - 1)
                    let range = maxValue - minValue
                    
                    var points: [CGPoint] = []
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - ((value - minValue) / range) * height
                        points.append(CGPoint(x: x, y: y))
                    }
                    
                    guard let firstPoint = points.first else { return }
                    path.move(to: firstPoint)
                    
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    
                    // Close the path for fill
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(color.opacity(0.1)) : nil
            )
        }
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
