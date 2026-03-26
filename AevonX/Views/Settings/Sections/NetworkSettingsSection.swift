//
//  NetworkSettingsSection.swift
//  AevonX
//
//  Network settings: SSH, proxy, performance
//

import SwiftUI

struct NetworkSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Network",
                description: "Connection & proxy configuration",
                icon: "network"
            )

            sshSection
            proxySection
            performanceSection
        }
        .onDisappear {
            settings.syncNetworkSettingsToCore()
        }
    }

    private var sshSection: some View {
        SettingsSection(title: "SSH", icon: "lock.doc") {
            SettingsIntSliderRow(
                title: "Connection Timeout",
                value: $settings.connectionTimeout,
                range: 5...120,
                step: 5,
                unit: "s"
            )
            SettingsIntSliderRow(
                title: "Keep-Alive Interval",
                value: $settings.keepAliveInterval,
                range: 10...120,
                step: 5,
                unit: "s"
            )
            SettingsStepperRow(
                title: "Max Retries",
                value: $settings.maxRetries,
                range: 0...10
            )
            SettingsToggleRow(
                title: "SSH Compression",
                subtitle: "Compress data over SSH connection",
                isOn: $settings.sshCompression
            )
            SettingsToggleRow(
                title: "Strict Host Key Checking",
                subtitle: "Require known host keys",
                isOn: $settings.strictHostKeyChecking
            )
        }
    }

    private var proxySection: some View {
        SettingsSection(title: "Proxy", icon: "globe") {
            SettingsToggleRow(
                title: "Use Proxy",
                isOn: $settings.useProxy
            )

            if settings.useProxy {
                SettingsPickerRow(
                    title: "Proxy Type",
                    selection: $settings.proxyType,
                    options: [
                        (label: "SOCKS5", value: "SOCKS5"),
                        (label: "SOCKS4", value: "SOCKS4"),
                        (label: "HTTP", value: "HTTP")
                    ]
                )

                HStack(spacing: AXSpacing.md) {
                    VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                        Text("Proxy Host")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                        TextField("hostname", text: $settings.proxyHost)
                            .textFieldStyle(.plain)
                            .font(AXTypography.monoMd)
                            .foregroundColor(.axTextPrimary)
                            .padding(AXSpacing.sm)
                            .background(Color.axBackground)
                            .cornerRadius(AXCornerRadius.sm)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                        Text("Port")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                        TextField("1080", value: $settings.proxyPort, format: .number)
                            .textFieldStyle(.plain)
                            .font(AXTypography.monoMd)
                            .foregroundColor(.axTextPrimary)
                            .padding(AXSpacing.sm)
                            .background(Color.axBackground)
                            .cornerRadius(AXCornerRadius.sm)
                            .frame(width: 80)
                    }
                }
            }
        }
    }

    private var performanceSection: some View {
        SettingsSection(title: "Performance", icon: "speedometer") {
            SettingsToggleRow(
                title: "Auto-disconnect Idle",
                subtitle: "Disconnect after period of inactivity",
                isOn: $settings.autoDisconnectIdle
            )
            if settings.autoDisconnectIdle {
                SettingsIntSliderRow(
                    title: "Idle Timeout",
                    value: $settings.idleTimeout,
                    range: 5...120,
                    step: 5,
                    unit: " min"
                )
            }
        }
    }
}
