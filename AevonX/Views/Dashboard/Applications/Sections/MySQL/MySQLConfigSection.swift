//
//  MySQLConfigSection.swift
//  AevonX
//
//  Configuration management: file list from parent, read/save on demand.
//

import SwiftUI
import AevonXCoreBridge

struct MySQLConfigSection: View {
    let serverId: String
    @Binding var configs: [BridgeAppConfig]

    @State private var selectedConfig: BridgeAppConfig?
    @State private var configContent = ""
    @State private var isSaving = false
    @State private var configTestResult: BridgeConfigTestResult?
    @State private var isLoadingContent = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    var body: some View {
        HSplitView {
            configFileList
                .frame(minWidth: 200, idealWidth: 260, maxWidth: 300)
            configEditor
        }
    }

    // MARK: - File List

    private var configFileList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Config Files")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

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
                VStack(spacing: AXSpacing.sm) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 24))
                        .foregroundColor(.axTextMuted)
                    Text("No config files found")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(configs) { config in
                            configFileRow(config)
                        }
                    }
                    .padding(AXSpacing.xs)
                }
            }
        }
        .background(Color.axSurface.opacity(0.3))
    }

    private func configFileRow(_ config: BridgeAppConfig) -> some View {
        Button {
            selectedConfig = config
            Task { await readConfig(path: config.path) }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: config.name.hasSuffix("/") ? "folder.fill" : "doc.text.fill")
                    .font(.system(size: 12))
                    .foregroundColor(config.name.hasSuffix("/") ? .orange : .axAccentBlue)

                VStack(alignment: .leading, spacing: 1) {
                    Text(config.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)

                    Text(config.path)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }

                Spacer()

                if selectedConfig?.id == config.id {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.axAccentBlue)
                }
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xs)
            .background(selectedConfig?.id == config.id ? Color.axAccentBlue.opacity(0.08) : Color.clear)
            .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Editor

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
                            Text("Save")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.axAccentBlue.opacity(0.1))
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
                    Image(systemName: "doc.text")
                        .font(.system(size: 28))
                        .foregroundColor(.axTextMuted)
                    Text("Select a config file to edit")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

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

    // MARK: - Actions

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
        let json = await bridge.configTest(serverID: serverId, appID: "mysql")
        if let data = json.data(using: .utf8),
           let response = try? JSONDecoder().decode(BridgeDataResponse<BridgeConfigTestResult>.self, from: data),
           response.success {
            configTestResult = response.data
        }
    }
}
