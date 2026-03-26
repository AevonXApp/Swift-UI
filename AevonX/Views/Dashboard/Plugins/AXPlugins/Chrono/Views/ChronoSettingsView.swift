//
//  ChronoSettingsView.swift
//  AevonX
//
//  Full AXChrono daemon config UI + webhook setup.
//

import SwiftUI

struct ChronoSettingsView: View {
    @ObservedObject var viewModel: ChronoViewModel
    @State private var editConfig: ChronoConfig?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                header
                if let cfg = editConfig {
                    gitpulseSection(cfg)
                    zeroflipSection(cfg)
                    sentinelSection(cfg)
                    vaultScanSection(cfg)
                    approvalSection(cfg)
                    webhookSection
                    saveBar
                }
            }
            .padding(AXSpacing.xl)
        }
        .task {
            await viewModel.loadConfig()
            editConfig = viewModel.config
        }
    }

    // MARK: - Header

    private var header: some View {
        Text(L10n.Chrono.Settings.title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.axTextPrimary)
    }

    // MARK: - GitPulse

    private func gitpulseSection(_ cfg: ChronoConfig) -> some View {
        settingsCard(title: L10n.Chrono.Settings.gitpulse, icon: "antenna.radiowaves.left.and.right", color: .axAccentPurple) {
            VStack(spacing: AXSpacing.md) {
                settingsPicker("Mode", selection: binding(\.gitpulseMode), options: ["poll", "webhook", "hybrid"])
                settingsIntField(L10n.Chrono.Settings.pollInterval, value: binding(\.gitpulsePollInterval))
                settingsToggle(L10n.Chrono.Settings.adaptivePolling, isOn: binding(\.gitpulseAdaptivePolling))
            }
        }
    }

    // MARK: - ZeroFlip

    private func zeroflipSection(_ cfg: ChronoConfig) -> some View {
        settingsCard(title: L10n.Chrono.Settings.zeroflip, icon: "arrow.2.squarepath", color: .axAccentBlue) {
            VStack(spacing: AXSpacing.md) {
                settingsToggle(L10n.Chrono.Settings.zeroflip, isOn: binding(\.zeroflipEnabled))
                settingsIntField(L10n.Chrono.Settings.maxReleases, value: binding(\.zeroflipMaxReleases))
            }
        }
    }

    // MARK: - Sentinel

    private func sentinelSection(_ cfg: ChronoConfig) -> some View {
        settingsCard(title: L10n.Chrono.Settings.sentinel, icon: "heart.text.clipboard", color: .axSuccess) {
            VStack(spacing: AXSpacing.md) {
                settingsToggle(L10n.Chrono.Settings.sentinel, isOn: binding(\.sentinelEnabled))
                settingsToggle(L10n.Chrono.Settings.autoRollback, isOn: binding(\.sentinelAutoRollback))
            }
        }
    }

    // MARK: - VaultScan

    private func vaultScanSection(_ cfg: ChronoConfig) -> some View {
        settingsCard(title: L10n.Chrono.Scanner.vaultScan, icon: "lock.shield", color: .axError) {
            VStack(spacing: AXSpacing.md) {
                settingsToggle(L10n.Chrono.Scanner.vaultScan, isOn: binding(\.vaultscanEnabled))
                settingsPicker(L10n.Chrono.Settings.vaultScanMode, selection: binding(\.vaultscanMode), options: ["passive", "active", "aggressive"])
                settingsToggle(L10n.Chrono.Scanner.threatRadar, isOn: binding(\.threatradarEnabled))
                settingsToggle(L10n.Chrono.Settings.selfHeal, isOn: binding(\.selfhealEnabled))
            }
        }
    }

    // MARK: - Approval

    private func approvalSection(_ cfg: ChronoConfig) -> some View {
        settingsCard(title: L10n.Chrono.Settings.approvalMode, icon: "checkmark.seal", color: .axWarning) {
            VStack(spacing: AXSpacing.md) {
                settingsPicker(L10n.Chrono.Settings.approvalMode, selection: binding(\.approvalMode), options: ["auto", "manual", "smart"])
            }
        }
    }

    // MARK: - Webhook

    @ViewBuilder
    private var webhookSection: some View {
        if let wh = viewModel.webhookStatus {
            settingsCard(title: L10n.Chrono.Webhook.title, icon: "link", color: .axAccentGreen) {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    webhookField(L10n.Chrono.Webhook.url, value: wh.webhookURL)
                    settingsIntField("Port", value: binding(\.webhookListenPort))
                    webhookSecrets(wh)
                    webhookDeliveries(wh)
                }
            }
        }
    }

    private func webhookField(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.md)
        }
    }

    private func webhookSecrets(_ wh: ChronoWebhookStatus) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.Chrono.Webhook.secrets)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            secretRow("GitHub", secret: wh.githubSecret)
            secretRow("GitLab", secret: wh.gitlabSecret)
            secretRow("Bitbucket", secret: wh.bitbucketSecret)
            secretRow("Generic", secret: wh.genericSecret)
        }
    }

    private func secretRow(_ provider: String, secret: String) -> some View {
        HStack {
            Text(provider)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextSecondary)
                .frame(width: 80, alignment: .leading)
            Text(String(repeating: "•", count: 24))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextMuted)
            Spacer()
        }
    }

    @ViewBuilder
    private func webhookDeliveries(_ wh: ChronoWebhookStatus) -> some View {
        if !wh.recentDeliveries.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(L10n.Chrono.Webhook.recentDeliveries)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
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
        }
    }

    // MARK: - Save

    private var saveBar: some View {
        HStack {
            Spacer()
            Button {
                guard let cfg = editConfig else { return }
                Task { await viewModel.saveConfig(cfg) }
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
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.settingsSaving)
        }
    }

    // MARK: - Reusable Settings Components

    private func settingsCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
            }
            content()
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
    }

    private func settingsToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
        }
        .toggleStyle(.checkbox)
    }

    private func settingsPicker(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        HStack {
            Text(label)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt.capitalized).tag(opt)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 250)
        }
    }

    private func settingsIntField(_ label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
            Spacer()
            TextField("", value: value, format: .number)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .frame(width: 80)
                .padding(AXSpacing.xs)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .multilineTextAlignment(.trailing)
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
