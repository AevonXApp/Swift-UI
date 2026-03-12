
import SwiftUI
import AevonXCoreBridge

@MainActor
public struct NginxPortsTab: View {
    let application: ApplicationInstance
    @Binding var nginxConfig: NginxConfigData
    let onSave: (Int) async -> Void

    @State private var newPort: String = "80"
    @State private var isUpdating = false

    public init(application: ApplicationInstance, nginxConfig: Binding<NginxConfigData>, onSave: @escaping (Int) async -> Void) {
        self.application = application
        self._nginxConfig = nginxConfig
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Current Config Summary
            HStack(spacing: AXSpacing.lg) {
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Active Ports")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                        
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "network")
                                .foregroundColor(.axAccentBlue)
                            Text(nginxConfig.listeningPorts.map { "\($0)" }.joined(separator: ", "))
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Default Service")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                        
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "server.rack")
                                .foregroundColor(.axSuccess)
                            Text("Standard HTTP")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text("Update Listening Port")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        Text("Change the primary port Nginx listens on for HTTP traffic")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }

                    HStack(spacing: AXSpacing.md) {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.axTextTertiary)
                            TextField("Port number", text: $newPort)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                        }
                        .padding(AXSpacing.md)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
                        )
                        .frame(width: 160)

                        AXActionButton(
                            label: isUpdating ? "Updating..." : "Update Port",
                            icon: "network",
                            style: .primary,
                            isLoading: isUpdating,
                            fullWidth: true
                        ) {
                            Task {
                                if let portInt = Int(newPort) {
                                    isUpdating = true
                                    await onSave(portInt)
                                    isUpdating = false
                                }
                            }
                        }
                        .disabled(isUpdating || newPort.isEmpty)
                    }

                    Divider()

                    HStack(alignment: .top, spacing: AXSpacing.sm) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.axAccentBlue)
                        Text("This action will scan nginx.conf and replace the 'listen 80;' directive. Make sure your firewall allows traffic on the new port.")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }
        }
    }
}
