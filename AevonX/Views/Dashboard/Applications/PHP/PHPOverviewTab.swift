
import SwiftUI
import AevonXCore

struct PHPOverviewTab: View {
    let application: ApplicationInstance
    @Binding var phpConfig: PHPConfigData
    let onReload: () -> Void
    let onTest: () -> Void
    let serverId: String
    
    @State private var showPHPInfo = false
    @State private var phpInfoText = ""
    @State private var isLoadingInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Header Section
            HStack(spacing: AXSpacing.xl) {
                Image("php-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .padding(AXSpacing.md)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.lg)
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("PHP Process Manager")
                        .font(AXTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    
                    Text("FastCGI implementation with advanced process management")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                
                Spacer()
            }
            .padding(.bottom, AXSpacing.md)

            // Service Status + FPM Workers — side by side
            HStack(spacing: AXSpacing.lg) {
                // Service Status Card
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Service Status")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        HStack(spacing: AXSpacing.xl) {
                            StatusItem(
                                label: "Status",
                                value: application.isRunning ? "Running" : "Stopped",
                                color: application.isRunning ? .axSuccess : .axError
                            )
                            
                            if let version = application.version {
                                StatusItem(
                                    label: "Version",
                                    value: version,
                                    color: .axAccentBlue
                                )
                            }
                        }
                        
                        HStack(spacing: AXSpacing.xl) {
                            if let memory = application.memoryUsage {
                                StatusItem(
                                    label: "Memory",
                                    value: String(format: "%.1f MB", memory),
                                    color: .axTextSecondary
                                )
                            }
                            
                            if let cpu = application.cpuUsage {
                                StatusItem(
                                    label: "CPU",
                                    value: String(format: "%.1f%%", cpu),
                                    color: .axTextSecondary
                                )
                            }
                        }
                    }
                }
                
                // FPM Workers Card
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("FPM Workers")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        HStack(spacing: AXSpacing.xl) {
                            WorkerStat(label: "Total", value: phpConfig.fpmStatus.totalProcesses, color: .axAccentBlue)
                            WorkerStat(label: "Active", value: phpConfig.fpmStatus.activeProcesses, color: .axSuccess)
                            WorkerStat(label: "Idle", value: phpConfig.fpmStatus.idleProcesses, color: .axTextTertiary)
                        }
                        
                        // Worker utilization bar
                        if phpConfig.fpmStatus.totalProcesses > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Utilization")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                                
                                GeometryReader { geo in
                                    let ratio = Double(phpConfig.fpmStatus.activeProcesses) / Double(max(phpConfig.fpmStatus.totalProcesses, 1))
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.axSurface.opacity(0.5))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(ratio > 0.8 ? Color.axError : Color.axSuccess)
                                            .frame(width: max(geo.size.width * ratio, 0))
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                }
            }
            
            // OPcache Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Text("OPcache")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
                        if phpConfig.opcacheStatus.enabled {
                            Text("Enabled")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axSuccess)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, 3)
                                .background(Color.axSuccess.opacity(0.1))
                                .cornerRadius(AXCornerRadius.xs)
                            
                            Button(action: {
                                Task {
                                    do {
                                        try await ApplicationManager.shared.resetPHPOPcache(serverId: serverId)
                                        GlobalToastManager.shared.showSuccess("OPcache reset successfully")
                                    } catch {
                                        GlobalToastManager.shared.showError("Failed to reset OPcache: \(error.localizedDescription)")
                                    }
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reset")
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.axWarning)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, 3)
                                .background(Color.axWarning.opacity(0.1))
                                .cornerRadius(AXCornerRadius.xs)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("Disabled")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.axTextMuted)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, 3)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.xs)
                        }
                    }
                    
                    if phpConfig.opcacheStatus.enabled {
                        HStack(spacing: AXSpacing.xl) {
                            OPcacheMetric(
                                label: "Hit Rate",
                                value: String(format: "%.1f%%", phpConfig.opcacheStatus.hitRate),
                                color: phpConfig.opcacheStatus.hitRate > 90 ? .axSuccess : .axWarning
                            )
                            OPcacheMetric(
                                label: "Used",
                                value: String(format: "%.0f MB", phpConfig.opcacheStatus.usedMemoryMB),
                                color: .axAccentBlue
                            )
                            OPcacheMetric(
                                label: "Free",
                                value: String(format: "%.0f MB", phpConfig.opcacheStatus.freeMemoryMB),
                                color: .axTextSecondary
                            )
                            OPcacheMetric(
                                label: "Cached Scripts",
                                value: "\(phpConfig.opcacheStatus.cachedScripts)",
                                color: .axAccentBlue
                            )
                        }
                    }
                }
            }
            
            // Quick Actions Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Quick Actions")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    HStack(spacing: AXSpacing.md) {
                        PHPActionButton(title: "Test Configuration", icon: "checkmark.circle", color: .axAccentBlue, action: onTest)
                        PHPActionButton(title: "Reload PHP-FPM", icon: "arrow.clockwise", color: .axSuccess, action: onReload)
                        PHPActionButton(title: "PHP Info", icon: "info.circle", color: .purple) {
                            Task {
                                isLoadingInfo = true
                                phpInfoText = (try? await ApplicationManager.shared.getPHPInfo(serverId: serverId)) ?? "Failed to load PHP info"
                                isLoadingInfo = false
                                showPHPInfo = true
                            }
                        }
                    }
                }
            }
            
            // PHP Info Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("PHP Information")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    PHPInfoRow(label: "Configuration Path", value: phpConfig.iniPath)
                    PHPInfoRow(label: "Log Path", value: phpConfig.logPath)
                    PHPInfoRow(label: "Installed Extensions", value: "\(phpConfig.installedExtensions.count)")
                    PHPInfoRow(label: "FPM Pools", value: "\(phpConfig.fpmPools.count)")
                    PHPInfoRow(label: "Disabled Functions", value: "\(phpConfig.disabledFunctions.count)")
                }
            }
        }
        .sheet(isPresented: $showPHPInfo) {
            PHPInfoSheet(phpInfoText: phpInfoText, isPresented: $showPHPInfo)
        }
    }
}

// MARK: - Worker Stat

private struct WorkerStat: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
        }
    }
}

// MARK: - OPcache Metric

private struct OPcacheMetric: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

// MARK: - Status Item

private struct StatusItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                
                Text(value)
                    .font(AXTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
        }
    }
}

// MARK: - PHP Action Button

private struct PHPActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(AXTypography.subheadline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PHP Info Row

private struct PHPInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            Spacer()
            Text(value)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .monospaced()
        }
    }
}

// MARK: - PHP Info Sheet

private struct PHPInfoSheet: View {
    let phpInfoText: String
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var filteredLines: [String] {
        let lines = phpInfoText.components(separatedBy: .newlines)
        if searchText.isEmpty { return lines }
        return lines.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PHP Info")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.axTextTertiary)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(AXTypography.body)
            }
            .padding(AXSpacing.sm)
            .background(Color.axSurface.opacity(0.5))
            .cornerRadius(AXCornerRadius.sm)
            .padding(.horizontal)
            
            // Content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(filteredLines.enumerated()), id: \.offset) { _, line in
                        if line.contains("=>") {
                            let parts = line.split(separator: "=>", maxSplits: 1)
                            HStack(alignment: .top) {
                                Text(parts.first.map(String.init) ?? "")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.axAccentBlue)
                                    .frame(minWidth: 200, alignment: .leading)
                                Text(parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : "")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, AXSpacing.sm)
                        } else {
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(line.hasPrefix("[") ? .axWarning : .axTextSecondary)
                                .padding(.horizontal, AXSpacing.sm)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color.axBackground)
    }
}
