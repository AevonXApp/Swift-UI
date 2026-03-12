
import SwiftUI
import AevonXCoreBridge

struct ApacheOverviewTab: View {
    let application: ApplicationInstance
    @Binding var apacheConfig: ApacheConfigData
    let onReload: () -> Void
    let onTest: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Header Section
            HStack(spacing: AXSpacing.xl) {
                Image("apache-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .padding(AXSpacing.md)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(AXCornerRadius.lg)
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("Apache HTTP Server")
                        .font(AXTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    
                    Text("Robust and feature-rich open-source web server")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                
                Spacer()
            }
            .padding(.bottom, AXSpacing.md)

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
                        ApacheActionButton(title: "Test Configuration", icon: "checkmark.circle", color: .axAccentBlue, action: onTest)
                        ApacheActionButton(title: "Reload Service", icon: "arrow.clockwise", color: .axSuccess, action: onReload)
                    }
                }
            }
            
            // Apache Info Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Apache Information")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    ApacheInfoRow(label: "Configuration Path", value: apacheConfig.configPath)
                    ApacheInfoRow(label: "Document Root", value: apacheConfig.documentRoot)
                    ApacheInfoRow(label: "Enabled Modules", value: "\(apacheConfig.modules.filter { $0.isEnabled }.count)")
                    ApacheInfoRow(label: "Virtual Hosts", value: "\(apacheConfig.virtualHosts.count)")
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

private struct ApacheActionButton: View {
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

private struct ApacheInfoRow: View {
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
