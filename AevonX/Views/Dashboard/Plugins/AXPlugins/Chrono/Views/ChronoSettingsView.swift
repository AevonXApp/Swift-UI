//
//  ChronoSettingsView.swift
//  AevonX
//
//  Full AXChrono daemon config UI + webhook setup.
//  Uses the same SettingsRow components as the main app for consistent UX.
//

import SwiftUI

struct ChronoSettingsView: View {
    @ObservedObject var viewModel: ChronoViewModel
    @State private var editConfig: ChronoConfig?
    @State private var showSaveToast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xxxl) {
                if let _ = editConfig {
                    gitpulseSection
                    sectionDivider
                    zeroflipSection
                    sectionDivider
                    sentinelSection
                    sectionDivider
                    vaultScanSection
                    sectionDivider
                    approvalSection
                    sectionDivider
                    webhookSection
                    saveBar
                } else {
                    loadingState
                }
            }
            .padding(AXSpacing.xxl)
            .frame(maxWidth: 700, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { toastOverlay }
        .task {
            await viewModel.loadConfig()
            editConfig = viewModel.config
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView()
                .controlSize(.small)
            Text(L10n.Chrono.Settings.title)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, AXSpacing.xxxxl)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.axBorder.opacity(0.3))
            .frame(height: 1)
    }

    // MARK: - GitPulse Watcher

    private var gitpulseSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            SettingsSectionHeader(
                title: L10n.Chrono.Settings.gitpulse,
                description: L10n.Chrono.Settings.gitpulseDesc,
                icon: "antenna.radiowaves.left.and.right",
                iconColor: .axAccentPurple
            )

            VStack(spacing: AXSpacing.md) {
                SettingsSegmentedRow(
                    title: L10n.Chrono.Settings.watchMode,
                    subtitle: L10n.Chrono.Settings.watchModeDesc,
                    icon: "dot.radiowaves.left.and.right",
                    selection: binding(\.gitpulseMode),
                    options: [
                        (label: "Poll", value: "poll"),
                        (label: "Webhook", value: "webhook"),
                        (label: "Hybrid", value: "hybrid")
                    ]
                )

                SettingsStepperRow(
                    title: L10n.Chrono.Settings.pollInterval,
                    subtitle: L10n.Chrono.Settings.pollIntervalDesc,
                    icon: "timer",
                    value: binding(\.gitpulsePollInterval),
                    range: 10...600,
                    unit: "s"
                )

                SettingsToggleRow(
                    title: L10n.Chrono.Settings.adaptivePolling,
                    subtitle: L10n.Chrono.Settings.adaptivePollingDesc,
                    icon: "waveform.path.ecg",
                    isOn: binding(\.gitpulseAdaptivePolling),
                    tint: .axAccentPurple
                )
            }
            .settingsRowGroup()
        }
    }

    // MARK: - ZeroFlip Deployment

    private var zeroflipSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            SettingsSectionHeader(
                title: L10n.Chrono.Settings.zeroflip,
                description: L10n.Chrono.Settings.zeroflipDesc,
                icon: "arrow.2.squarepath",
                iconColor: .axAccentBlue
            )

            VStack(spacing: AXSpacing.md) {
                SettingsToggleRow(
                    title: L10n.Chrono.Settings.zeroflipEnabled,
                    subtitle: L10n.Chrono.Settings.zeroflipEnabledDesc,
                    icon: "power",
                    isOn: binding(\.zeroflipEnabled),
                    tint: .axAccentBlue
                )

                SettingsStepperRow(
                    title: L10n.Chrono.Settings.maxReleases,
                    subtitle: L10n.Chrono.Settings.maxReleasesDesc,
                    icon: "square.stack.3d.up",
                    value: binding(\.zeroflipMaxReleases),
                    range: 1...20
                )
            }
            .settingsRowGroup()
        }
    }

    // MARK: - SentinelHealth

    private var sentinelSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            SettingsSectionHeader(
                title: L10n.Chrono.Settings.sentinel,
                description: L10n.Chrono.Settings.sentinelDesc,
                icon: "heart.text.clipboard",
                iconColor: .axSuccess
            )

            VStack(spacing: AXSpacing.md) {
                SettingsToggleRow(
                    title: L10n.Chrono.Settings.sentinelEnabled,
                    subtitle: L10n.Chrono.Settings.sentinelEnabledDesc,
                    icon: "heart.circle",
                    isOn: binding(\.sentinelEnabled),
                    tint: .axSuccess
                )

                SettingsToggleRow(
                    title: L10n.Chrono.Settings.autoRollback,
                    subtitle: L10n.Chrono.Settings.autoRollbackDesc,
                    icon: "arrow.uturn.backward.circle",
                    isOn: binding(\.sentinelAutoRollback),
                    tint: .axWarning
                )
            }
            .settingsRowGroup()
        }
    }

    // MARK: - VaultScan & Security

    private var vaultScanSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            SettingsSectionHeader(
                title: L10n.Chrono.Settings.vaultScan,
                description: L10n.Chrono.Settings.vaultScanDesc,
                icon: "lock.shield",
                iconColor: .axError
            )

            VStack(spacing: AXSpacing.md) {
                SettingsToggleRow(
                    title: L10n.Chrono.Settings.vaultScanEnabled,
                    subtitle: L10n.Chrono.Settings.vaultScanEnabledDesc,
                    icon: "magnifyingglass.circle",
                    isOn: binding(\.vaultscanEnabled),
                    tint: .axError
                )

                SettingsSegmentedRow(
                    title: L10n.Chrono.Settings.vaultScanMode,
                    subtitle: L10n.Chrono.Settings.vaultScanModeDesc,
                    icon: "shield.lefthalf.filled",
                    selection: binding(\.vaultscanMode),
                    options: [
                        (label: "Passive", value: "passive"),
                        (label: "Active", value: "active"),
                        (label: "Aggressive", value: "aggressive")
                    ]
                )

                SettingsToggleRow(
                    title: L10n.Chrono.Settings.threatRadar,
                    subtitle: L10n.Chrono.Settings.threatRadarDesc,
                    icon: "exclamationmark.shield",
                    isOn: binding(\.threatradarEnabled),
                    tint: .axWarning
                )

                SettingsToggleRow(
                    title: L10n.Chrono.Settings.selfHeal,
                    subtitle: L10n.Chrono.Settings.selfHealDesc,
                    icon: "bandage",
                    isOn: binding(\.selfhealEnabled),
                    tint: .axAccentGreen
                )
            }
            .settingsRowGroup()
        }
    }

    // MARK: - Approval Workflow

    private var approvalSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            SettingsSectionHeader(
                title: L10n.Chrono.Settings.approval,
                description: L10n.Chrono.Settings.approvalDesc,
                icon: "checkmark.seal",
                iconColor: .axWarning
            )

            VStack(spacing: AXSpacing.md) {
                SettingsSegmentedRow(
                    title: L10n.Chrono.Settings.approvalMode,
                    subtitle: L10n.Chrono.Settings.approvalModeDesc,
                    icon: "hand.raised.circle",
                    selection: binding(\.approvalMode),
                    options: [
                        (label: L10n.Chrono.Settings.approvalAuto, value: "auto"),
                        (label: L10n.Chrono.Settings.approvalManual, value: "manual"),
                        (label: L10n.Chrono.Settings.approvalSmart, value: "smart")
                    ]
                )
            }
            .settingsRowGroup()
        }
    }

    // MARK: - Webhook

    private var webhookSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            SettingsSectionHeader(
                title: L10n.Chrono.Settings.webhook,
                description: L10n.Chrono.Settings.webhookDesc,
                icon: "link",
                iconColor: .axAccentGreen
            )

            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsStepperRow(
                    title: L10n.Chrono.Settings.webhookPort,
                    subtitle: L10n.Chrono.Settings.webhookPortDesc,
                    icon: "network",
                    value: binding(\.webhookListenPort),
                    range: 1024...65535
                )

                if let wh = viewModel.webhookStatus {
                    webhookURLRow(wh)
                    webhookSecretsRow(wh)
                    webhookDeliveriesRow(wh)
                }
            }
            .settingsRowGroup()
        }
    }

    private func webhookURLRow(_ wh: ChronoWebhookStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: "globe")
                    .font(.system(size: 13))
                    .foregroundColor(.axAccentGreen)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(L10n.Chrono.Webhook.url)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
            }
            Text(wh.webhookURL)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.md)
                .padding(.leading, 32)
        }
    }

    private func webhookSecretsRow(_ wh: ChronoWebhookStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: "key")
                    .font(.system(size: 13))
                    .foregroundColor(.axAccentGreen)
                    .frame(width: 20)
                Text(L10n.Chrono.Webhook.secrets)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
                Spacer()
            }

            VStack(spacing: AXSpacing.xs) {
                secretRow("GitHub", secret: wh.githubSecret)
                secretRow("GitLab", secret: wh.gitlabSecret)
                secretRow("Bitbucket", secret: wh.bitbucketSecret)
                secretRow("Generic", secret: wh.genericSecret)
            }
            .padding(.leading, 32)
        }
    }

    private func secretRow(_ provider: String, secret: String) -> some View {
        HStack(spacing: AXSpacing.md) {
            Text(provider)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .frame(width: 80, alignment: .leading)
            Text(secret.isEmpty ? "Not configured" : String(repeating: "\u{2022}", count: 24))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(secret.isEmpty ? .axTextMuted : .axTextTertiary)
            Spacer()
            if !secret.isEmpty {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(secret, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
                .help("Copy secret")
            }
        }
    }

    @ViewBuilder
    private func webhookDeliveriesRow(_ wh: ChronoWebhookStatus) -> some View {
        if !wh.recentDeliveries.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 13))
                        .foregroundColor(.axAccentGreen)
                        .frame(width: 20)
                    Text(L10n.Chrono.Webhook.recentDeliveries)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                    Spacer()
                }

                VStack(spacing: AXSpacing.xs) {
                    ForEach(wh.recentDeliveries) { delivery in
                        HStack(spacing: AXSpacing.sm) {
                            Circle()
                                .fill(delivery.success ? Color.axSuccess : Color.axError)
                                .frame(width: 6, height: 6)
                            Text(delivery.provider)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.axTextPrimary)
                            Text(delivery.repo)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                            Spacer()
                            Text(delivery.timestamp)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                        }
                    }
                }
                .padding(.leading, 32)
            }
        }
    }

    // MARK: - Save

    private var saveBar: some View {
        HStack {
            Spacer()
            Button {
                guard let cfg = editConfig else { return }
                Task {
                    let success = await viewModel.saveConfig(cfg)
                    showSaveToast = true
                    try? await Task.sleep(for: .seconds(2))
                    showSaveToast = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if viewModel.settingsSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(L10n.Button.save)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xxl)
                .padding(.vertical, AXSpacing.md)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.settingsSaving)
        }
        .padding(.top, AXSpacing.md)
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if showSaveToast {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.axSuccess)
                Text(L10n.Chrono.Settings.saved)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.lg)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .padding(.bottom, AXSpacing.xl)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.3), value: showSaveToast)
        }
    }

    // MARK: - Binding Helpers

    private func binding<T>(_ keyPath: WritableKeyPath<ChronoConfig, T>) -> Binding<T> {
        Binding(
            get: { editConfig![keyPath: keyPath] },
            set: { editConfig![keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - Settings Row Group Modifier

private extension View {
    func settingsRowGroup() -> some View {
        self
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.lg)
    }
}
