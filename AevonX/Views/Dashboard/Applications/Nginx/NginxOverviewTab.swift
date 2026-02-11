
import SwiftUI
import AevonXCore

@MainActor
public struct NginxOverviewTab: View {
    let application: ApplicationInstance
    @Binding var nginxConfig: NginxConfigData
    let onReload: () -> Void
    let onTest: () -> Void

    public init(
        application: ApplicationInstance,
        nginxConfig: Binding<NginxConfigData>,
        onReload: @escaping () -> Void,
        onTest: @escaping () -> Void
    ) {
        self.application = application
        self._nginxConfig = nginxConfig
        self.onReload = onReload
        self.onTest = onTest
    }

    public var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Status Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Service Status")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    HStack {
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Running")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                            Text(application.isRunning ? "Active" : "Inactive")
                                .font(AXTypography.body)
                                .foregroundColor(application.isRunning ? .axSuccess : .axError)
                        }

                        Spacer()

                        Circle()
                            .fill(application.isRunning ? Color.axSuccess : Color.axError)
                            .frame(width: 12, height: 12)
                    }

                    Divider()

                    AppInfoRow(label: "Version", value: application.version ?? "Unknown")
                    AppInfoRow(label: "Auto-start", value: application.autoStart ? "Enabled" : "Disabled")

                    if let memory = application.memoryUsage {
                        AppInfoRow(label: "Memory Usage", value: String(format: "%.1f MB", memory))
                    }
                }
            }

            // Quick Controls Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Service Controls")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    HStack(spacing: AXSpacing.md) {
                        ControlButton(title: "Reload", icon: "arrow.clockwise", color: .axAccentBlue) {
                            onReload()
                        }
                        
                        ControlButton(title: "Test Config", icon: "checkmark.shield", color: .axSuccess) {
                            onTest()
                        }
                    }
                }
            }

            // Paths Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Configuration Paths")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    InfoField(label: "Main Configuration", value: nginxConfig.configPath, icon: "filemenu.and.selection")
                    InfoField(label: "Log Directory", value: nginxConfig.logPath, icon: "doc.text")
                    InfoField(label: "Static Content", value: nginxConfig.dataPath, icon: "folder")
                    
                    if let installPath = application.installPath {
                        InfoField(label: "Binary Path", value: installPath, icon: "terminal")
                    }
                }
            }

            // Performance & Security Summary
            HStack(spacing: AXSpacing.lg) {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Active Ports")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                        Text("\(nginxConfig.listeningPorts.count)")
                            .font(AXTypography.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Blocked IPs")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                        Text("\(nginxConfig.blockedIPs.count)")
                            .font(AXTypography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.axError)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct InfoField: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.axAccentBlue)
                
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(value, forType: .string) }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.sm)
            .background(Color.axBackground.opacity(0.5))
            .cornerRadius(AXCornerRadius.sm)
        }
    }
}

private struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(AXTypography.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.md)
            .background(color)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}
