
import SwiftUI
import AevonXCore

struct PHPOverviewTab: View {
    let application: ApplicationInstance
    @Binding var phpConfig: PHPConfigData
    let onReload: () -> Void
    let onTest: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
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
            
            // Quick Actions Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Quick Actions")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    HStack(spacing: AXSpacing.md) {
                        PHPActionButton(title: "Test Configuration", icon: "checkmark.circle", color: .axAccentBlue, action: onTest)
                        PHPActionButton(title: "Reload PHP-FPM", icon: "arrow.clockwise", color: .axSuccess, action: onReload)
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
                }
            }
        }
    }
}

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
