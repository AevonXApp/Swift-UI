//
//  LiteSpeedConfigSection.swift
//  AevonX
//
//  Configuration management for LiteSpeed — file list, read, edit, validate.
//  Mirrors ApacheConfigSection pattern.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedConfigSection: View {
    let serverId: String
    let configs: [BridgeAppConfig]

    @State private var selectedConfig: BridgeAppConfig?
    @State private var configContent = ""
    @State private var isLoadingContent = false
    @State private var isSaving = false
    @State private var isTesting = false
    @State private var testResult: String?

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    var body: some View {
        HStack(spacing: 0) {
            configList
            Divider().background(Color.axBorder.opacity(0.3))
            configEditor
        }
    }

    // MARK: - Config List

    private var configList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Config Files")
                .font(AXTypography.subheadline).fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(configs, id: \.name) { config in
                        Button {
                            selectedConfig = config
                            Task { await loadConfigContent(config) }
                        } label: {
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: config.isMain ? "doc.text.fill" : "doc.text")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(config.isMain ? lsGreen : .axTextMuted)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(config.name)
                                        .font(AXTypography.subheadline).fontWeight(.medium)
                                        .foregroundColor(.axTextPrimary)
                                        .lineLimit(1)
                                    if !config.path.isEmpty && config.path != config.name {
                                        Text(config.path)
                                            .font(AXTypography.caption2)
                                            .foregroundColor(.axTextMuted)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                if config.isMain {
                                    Text("MAIN")
                                        .font(AXTypography.monoXxxs).fontWeight(.bold)
                                        .foregroundColor(lsGreen)
                                        .padding(.horizontal, 4).padding(.vertical, 2)
                                        .background(lsGreen.opacity(0.1))
                                        .cornerRadius(3)
                                }
                            }
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(selectedConfig?.name == config.name ? lsGreen.opacity(0.08) : Color.clear)
                            .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, AXSpacing.xs)
            }
        }
        .frame(width: 240)
        .background(Color.axSurface.opacity(0.3))
    }

    // MARK: - Config Editor

    private var configEditor: some View {
        VStack(spacing: 0) {
            if let config = selectedConfig {
                // Toolbar
                HStack(spacing: AXSpacing.sm) {
                    Text(config.name)
                        .font(AXTypography.subheadline).fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    Spacer()

                    Button {
                        Task { await testConfig() }
                    } label: {
                        HStack(spacing: 4) {
                            if isTesting {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .font(AXTypography.footnote)
                            }
                            Text("Validate")
                                .font(AXTypography.footnote).fontWeight(.medium)
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.sm).padding(.vertical, 4)
                        .background(Color.axAccentBlue.opacity(0.08))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isTesting)

                    Button {
                        Task { await saveConfig(config) }
                    } label: {
                        HStack(spacing: 4) {
                            if isSaving {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(AXTypography.footnote)
                            }
                            Text(L10n.Button.save)
                                .font(AXTypography.footnote).fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.md).padding(.vertical, 4)
                        .background(lsGreen)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSaving)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSurface.opacity(0.5))

                Divider().background(Color.axBorder.opacity(0.2))

                // Test result banner
                if let result = testResult {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: result.contains("OK") || result.contains("ok") ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.contains("OK") || result.contains("ok") ? .axSuccess : .axError)
                        Text(result)
                            .font(AXTypography.footnote)
                            .foregroundColor(.axTextSecondary)
                        Spacer()
                        Button { testResult = nil } label: {
                            Image(systemName: "xmark").font(AXTypography.caption2).foregroundColor(.axTextMuted)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(AXSpacing.sm)
                    .background((result.contains("OK") || result.contains("ok") ? Color.axSuccess : Color.axError).opacity(0.08))
                }

                // Editor
                if isLoadingContent {
                    VStack { Spacer(); ProgressView("Loading..."); Spacer() }
                } else {
                    TextEditor(text: $configContent)
                        .font(AXTypography.monoMd)
                        .foregroundColor(.axTextPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.axBackground)
                        .padding(AXSpacing.sm)
                }
            } else {
                VStack(spacing: AXSpacing.md) {
                    Spacer()
                    Image(systemName: "doc.text").font(AXTypography.largeTitle).foregroundColor(.axTextMuted.opacity(0.3))
                    Text("Select a config file to view").font(AXTypography.callout).foregroundColor(.axTextMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Data

    private func loadConfigContent(_ config: BridgeAppConfig) async {
        isLoadingContent = true
        let path = config.path.isEmpty ? config.name : config.path
        let json = await bridge.readConfig(serverID: serverId, path: path)
        if let data = json.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeDataResponse<String>.self, from: data),
           resp.success {
            configContent = resp.data ?? ""
        }
        isLoadingContent = false
    }

    private func saveConfig(_ config: BridgeAppConfig) async {
        isSaving = true
        let path = config.path.isEmpty ? config.name : config.path
        let json = await bridge.saveConfig(serverID: serverId, path: path, content: configContent)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Config saved")
        } else {
            toast.showError("Failed to save config")
        }
        isSaving = false
    }

    private func testConfig() async {
        isTesting = true
        let json = await bridge.configTest(serverID: serverId, appID: "litespeed")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if resp["success"] as? Bool == true {
                testResult = "✓ Configuration syntax OK"
            } else {
                testResult = resp["error"] as? String ?? "Config test failed"
            }
        }
        isTesting = false
    }
}
