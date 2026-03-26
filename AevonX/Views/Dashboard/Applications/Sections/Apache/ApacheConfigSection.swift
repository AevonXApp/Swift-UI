//
//  ApacheConfigSection.swift
//  AevonX
//
//  Config file list and editor for Apache.
//

import SwiftUI
import AevonXCoreBridge

struct ApacheConfigSection: View {
    let serverId: String
    let configs: [BridgeAppConfig]

    @State private var selectedConfig: BridgeAppConfig?
    @State private var configContent = ""
    @State private var isLoadingContent = false
    @State private var isSaving = false
    @State private var configTestResult: BridgeConfigTestResult?

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let apacheRed = Color(red: 0.82, green: 0.13, blue: 0.16)

    var body: some View {
        HSplitView {
            configList
                .frame(minWidth: 200, idealWidth: 260, maxWidth: 300)
            configEditor
        }
    }

    // MARK: - Config List

    private var configList: some View {
        VStack(spacing: 0) {
            HStack {
                AXSectionTitle(title: "Config Files", icon: "doc.text.fill")
                Spacer()
                Button {
                    Task { await testConfig() }
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 13))
                        .foregroundColor(configTestResult?.valid == true ? .axSuccess : .axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)

            Divider().background(Color.axBorder.opacity(0.3))

            if configs.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "doc.text").font(.system(size: 24)).foregroundColor(.axTextMuted)
                    Text("No config files").font(AXTypography.caption).foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(configs) { config in
                            configRow(config)
                        }
                    }
                    .padding(AXSpacing.xs)
                }
            }
        }
        .background(Color.axSurface.opacity(0.3))
    }

    private func configRow(_ config: BridgeAppConfig) -> some View {
        Button {
            selectedConfig = config
            Task { await readConfig(path: config.path) }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: config.isMain ? "doc.fill" : "doc.text")
                    .font(.system(size: 12))
                    .foregroundColor(config.isMain ? apacheRed : .axTextMuted)

                VStack(alignment: .leading, spacing: 1) {
                    Text(config.name)
                        .font(.system(size: 12, weight: config.isMain ? .semibold : .regular))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    Text(config.path)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }

                Spacer()

                if config.isMain {
                    Text("MAIN").font(.system(size: 8, weight: .bold))
                        .foregroundColor(apacheRed).padding(.horizontal, 4).padding(.vertical, 2)
                        .background(apacheRed.opacity(0.1)).cornerRadius(3)
                }

                if selectedConfig?.id == config.id {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(apacheRed)
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(selectedConfig?.id == config.id ? apacheRed.opacity(0.08) : Color.clear)
            .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Config Editor

    private var configEditor: some View {
        VStack(spacing: 0) {
            if selectedConfig != nil {
                HStack(spacing: AXSpacing.md) {
                    if let config = selectedConfig {
                        Text(config.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.axTextPrimary)
                        Text(config.path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axTextMuted)
                    }
                    Spacer()
                    Button {
                        Task { await saveConfig() }
                    } label: {
                        HStack(spacing: 4) {
                            if isSaving {
                                ProgressView().scaleEffect(0.5)
                            } else {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 11))
                            }
                            Text(L10n.Button.save)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(apacheRed)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 4)
                        .background(apacheRed.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSaving)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSurface.opacity(0.5))

                Divider().background(Color.axBorder.opacity(0.3))

                if isLoadingContent {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TextEditor(text: $configContent)
                        .font(.system(size: 12, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(Color.axBackground)
                        .padding(AXSpacing.sm)
                }
            } else {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32)).foregroundColor(.axTextMuted)
                    Text("Select a config file to edit")
                        .font(AXTypography.caption).foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Config test result
            if let result = configTestResult {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: result.valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.valid ? .axSuccess : .axError)
                    Text(result.output)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(result.valid ? .axSuccess : .axError)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(AXSpacing.sm)
                .background(result.valid ? Color.axSuccess.opacity(0.05) : Color.axError.opacity(0.05))
            }
        }
    }

    // MARK: - Data

    private func readConfig(path: String) async {
        isLoadingContent = true
        let json = await bridge.readConfig(serverID: serverId, path: path)
        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<[String: String]>.self, from: data),
           response.success,
           let content = response.data?["content"] {
            configContent = content
        }
        isLoadingContent = false
    }

    private func saveConfig() async {
        guard let config = selectedConfig else { return }
        isSaving = true
        let json = await bridge.saveConfig(serverID: serverId, path: config.path, content: configContent)
        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<[String: Bool]>.self, from: data),
           response.success {
            toast.showSuccess("Config saved — \(config.name)")
            await testConfig()
        } else {
            var errorMsg = "Failed to save configuration"
            if let data = json.data(using: .utf8),
               let errResp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errStr = errResp["error"] as? String {
                errorMsg = errStr
            }
            toast.showError(errorMsg)
        }
        isSaving = false
    }

    private func testConfig() async {
        let json = await bridge.configTest(serverID: serverId, appID: "apache")
        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<BridgeConfigTestResult>.self, from: data),
           response.success {
            configTestResult = response.data
        }
    }
}
