
import SwiftUI
import AevonXCore

@MainActor
public struct NginxConfigurationTab: View {
    let application: ApplicationInstance
    @Binding var nginxConfig: NginxConfigData
    let onSave: (String) async -> Void

    @State private var editedConfig: String = ""
    @State private var isSaving = false
    
    // Quick Settings State
    @State private var workerProcesses: Int = 1
    @State private var gzipEnabled: Bool = true
    @State private var autoIndex: Bool = false

    public init(application: ApplicationInstance, nginxConfig: Binding<NginxConfigData>, onSave: @escaping (String) async -> Void) {
        self.application = application
        self._nginxConfig = nginxConfig
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Quick Settings Section
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.axAccentBlue)
                        Text("Quick Settings")
                            .font(AXTypography.headline)
                        
                        Spacer()
                        
                        Text("Beta")
                            .font(AXTypography.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .foregroundColor(.axAccentBlue)
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: AXSpacing.xl) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Worker Processes")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                            Stepper("\(workerProcesses)", value: $workerProcesses, in: 1...32)
                                .labelsHidden()
                        }
                        
                        Divider().frame(height: 30)
                        
                        Toggle("Gzip Compression", isOn: $gzipEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                            .font(AXTypography.subheadline)
                        
                        Divider().frame(height: 30)
                        
                        Toggle("Autoindex", isOn: $autoIndex)
                            .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                            .font(AXTypography.subheadline)
                    }
                }
            }

            AXCodeEditor(
                text: $editedConfig,
                title: "nginx.conf",
                isSaving: isSaving,
                onSave: {
                    Task {
                        isSaving = true
                        await onSave(editedConfig)
                        isSaving = false
                    }
                },
                originalText: nginxConfig.rawConfig
            )
            .frame(minHeight: 600)
            
            // Extra Information Info Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.axAccentBlue)
                        Text("Configuration Details")
                            .font(AXTypography.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        DetailItem(label: "Main Config File", value: nginxConfig.configPath)
                        DetailItem(label: "Include Directory", value: "/etc/nginx/conf.d/*.conf")
                        DetailItem(label: "Logs Directory", value: nginxConfig.logPath)
                    }
                }
            }
        }
        .onAppear {
            if editedConfig.isEmpty {
                editedConfig = nginxConfig.rawConfig
            }
        }
        .onChange(of: nginxConfig.rawConfig) { old, newValue in
            if editedConfig == "" || editedConfig == newValue {
                editedConfig = newValue
            }
        }
    }
}

private struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.axTextPrimary)
        }
    }
}
