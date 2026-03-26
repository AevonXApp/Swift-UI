//
//  PHPConfigSection.swift
//  AevonX

import SwiftUI
import AevonXCoreBridge

struct PHPConfigSection: View {
    let serverId: String
    @Binding var configs: [BridgeAppConfig]

    @State private var selectedConfig: BridgeAppConfig?
    @State private var configContent = ""
    @State private var isEditing = false
    @State private var isLoading = false
    @State private var isSaving = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        HStack(spacing: 0) {
            // Config file list
            VStack(alignment: .leading, spacing: 0) {
                AXSectionTitle(title: "Config Files", icon: "doc.text.fill")
                    .padding(AXSpacing.md)

                ScrollView {
                    VStack(spacing: AXSpacing.xs) {
                        ForEach(configs, id: \.path) { config in
                            configRow(config)
                        }
                    }
                    .padding(.horizontal, AXSpacing.md)
                }
            }
            .frame(width: 260)

            Divider().background(Color.axBorder.opacity(0.3))

            // Editor
            VStack(spacing: 0) {
                if let config = selectedConfig {
                    editorHeader(config)
                    Divider().background(Color.axBorder.opacity(0.3))

                    if isLoading {
                        Spacer()
                        ProgressView(L10n.Status.loading).foregroundColor(.axTextSecondary)
                        Spacer()
                    } else {
                        ScrollView {
                            Text(configContent)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                                .textSelection(.enabled)
                                .padding(AXSpacing.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else {
                    VStack(spacing: AXSpacing.lg) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 40))
                            .foregroundColor(phpPurple.opacity(0.3))
                        Text("Select a config file to view").font(AXTypography.body).foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private func configRow(_ config: BridgeAppConfig) -> some View {
        Button {
            selectedConfig = config
            Task { await loadConfigContent(path: config.path) }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 11))
                    .foregroundColor(selectedConfig?.path == config.path ? phpPurple : .axTextMuted)

                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name)
                        .font(.system(size: 12, weight: selectedConfig?.path == config.path ? .semibold : .regular))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)

                    Text(config.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextTertiary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(selectedConfig?.path == config.path ? phpPurple.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func editorHeader(_ config: BridgeAppConfig) -> some View {
        HStack {
            Text(config.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)
            Text(config.path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextMuted)
            Spacer()
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface.opacity(0.5))
    }

    private func loadConfigContent(path: String) async {
        isLoading = true
        let json = await bridge.readConfig(serverID: serverId, path: path)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let payload = resp["data"] as? [String: Any] {
            configContent = payload["content"] as? String ?? "Failed to read file"
        }
        isLoading = false
    }
}
