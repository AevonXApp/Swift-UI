//
//  ReverseProxySection.swift
//  AevonX
//
//  Nginx reverse proxy configuration for Node.js apps.
//  Generate, preview, and apply Nginx configs with SSL support.
//

import SwiftUI
import AevonXCoreBridge

struct ReverseProxySection: View {
    let serverId: String
    let appPath: String?

    @State private var domain = ""
    @State private var port: Int = 3000
    @State private var sslEnabled = false
    @State private var generatedConfig = ""
    @State private var isApplying = false
    @State private var currentConfig = ""
    @State private var showCurrentConfig = false

    private let configService = NodeJSConfigService()

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            configFormCard
            if !generatedConfig.isEmpty { configPreviewCard }
            if showCurrentConfig && !currentConfig.isEmpty { currentConfigCard }
        }
    }

    // MARK: - Config Form

    private var configFormCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                sectionHeader(title: "Reverse Proxy Configuration", icon: "network", color: Color(hex: "#00C853"))

                // Domain
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    fieldLabel(text: "Domain", icon: "globe")
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                        TextField("example.com", text: $domain)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                }

                // Port + SSL
                HStack(spacing: AXSpacing.xl) {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        fieldLabel(text: "Port", icon: "number")
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "number")
                                .font(.system(size: 11))
                                .foregroundColor(.axTextMuted)
                            TextField("3000", value: $port, format: .number)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                        }
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .frame(width: 120)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        fieldLabel(text: "SSL / HTTPS", icon: "lock.shield")
                        HStack(spacing: AXSpacing.sm) {
                            Toggle("", isOn: $sslEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .axSuccess))
                                .frame(width: 36)

                            Text(sslEnabled ? "Enabled" : "Disabled")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(sslEnabled ? .axSuccess : .axTextMuted)
                        }
                    }
                }

                Divider().overlay(Color.axBorder.opacity(0.3))

                // Actions
                HStack(spacing: AXSpacing.sm) {
                    actionButton(title: "Preview Config", icon: "doc.text.magnifyingglass", color: .axAccentBlue) {
                        Task { await generatePreview() }
                    }
                    actionButton(title: isApplying ? "Applying…" : "Apply to Nginx", icon: "checkmark.circle.fill", color: .axSuccess) {
                        Task { await applyConfig() }
                    }
                    actionButton(title: "View Current", icon: "eye", color: .axTextSecondary) {
                        Task { await loadCurrentConfig() }
                    }
                }
            }
        }
    }

    // MARK: - Config Preview

    private var configPreviewCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    sectionHeader(title: "Generated Config", icon: "doc.text.fill", color: Color(hex: "#00C853"))
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(generatedConfig, forType: .string)
                        GlobalToastManager.shared.showSuccess("Copied to clipboard")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                            Text("Copy")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)

                    Button { generatedConfig = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    Text(generatedConfig)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "#4EC9B0"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 300)
                .padding(AXSpacing.sm)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Current Config

    private var currentConfigCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    sectionHeader(title: "Current Nginx Config", icon: "server.rack", color: .axTextSecondary)
                    Spacer()
                    Button { showCurrentConfig = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    Text(currentConfig)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 300)
                .padding(AXSpacing.sm)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Reusable Components

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            Text(title)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
        }
    }

    private func fieldLabel(text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(.axTextMuted)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.axTextMuted)
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(color.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func generatePreview() async {
        guard !domain.isEmpty else {
            GlobalToastManager.shared.showError("Enter a domain name")
            return
        }
        generatedConfig = await configService.generateNginxConfig(domain: domain, port: port, sslEnabled: sslEnabled)
    }

    private func applyConfig() async {
        guard !domain.isEmpty else {
            GlobalToastManager.shared.showError("Enter a domain name")
            return
        }
        isApplying = true
        do {
            try await configService.applyNginxReverseProxy(domain: domain, port: port, sslEnabled: sslEnabled, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Nginx config applied for \(domain)")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        isApplying = false
    }

    private func loadCurrentConfig() async {
        guard !domain.isEmpty else {
            GlobalToastManager.shared.showError("Enter a domain to view its config")
            return
        }
        let output = await SSHBridge.shared.executeAsync(
            serverID: serverId,
            command: "cat /etc/nginx/sites-available/\(domain) 2>/dev/null || cat /etc/nginx/conf.d/\(domain).conf 2>/dev/null || echo 'No config found'"
        )
        currentConfig = output.trimmingCharacters(in: .whitespacesAndNewlines)
        showCurrentConfig = true
    }
}
