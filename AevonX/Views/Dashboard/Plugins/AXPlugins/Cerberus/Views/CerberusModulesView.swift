//
//  CerberusModulesView.swift
//  AevonX
//
//  Modules tab — live module toggles + per-section config control panels.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusModulesView: View {
    @ObservedObject var viewModel: CerberusViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                modulesHero
                moduleToggleGrid
                Divider().padding(.vertical, AXSpacing.xs)
                rateLimitPanel
                ddosPanel
                credentialPanel
                dlpPanel
                honeypotPanel
                alertsPanel
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadModuleConfig() }
    }
}

// MARK: - Hero

private extension CerberusModulesView {

    var modulesHero: some View {
        AXGlassCard(accentColor: .axAccentBlue) {
            HStack(spacing: AXSpacing.xl) {
                modulesHeroIcon
                modulesHeroText
                Spacer()
                modulesHeroStatus
            }
        }
    }

    var modulesHeroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentBlue.opacity(0.2), Color.axAccentBlue.opacity(0.04)],
                        center: .center, startRadius: 0, endRadius: 26
                    )
                )
                .frame(width: 48, height: 48)
            Circle()
                .stroke(Color.axAccentBlue.opacity(0.25), lineWidth: 1)
                .frame(width: 48, height: 48)
            Image(systemName: "square.grid.3x3.fill")
                .font(AXTypography.title3)
                .foregroundStyle(Color.axAccentBlue)
        }
    }

    var modulesHeroText: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(L10n.Cerberus.Modules.title)
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(L10n.Cerberus.Modules.subtitle)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    var modulesHeroStatus: some View {
        HStack(spacing: AXSpacing.md) {
            if viewModel.configOperationInProgress {
                ProgressView().scaleEffect(0.8)
            }
            AXBadge(
                text: "\(moduleCards.filter(\.enabled).count)/\(moduleCards.count) active",
                color: .axAccentGreen, style: .soft
            )
        }
    }
}

// MARK: - Module Toggle Grid

private extension CerberusModulesView {

    var moduleToggleGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.md) {
            ForEach(moduleCards, id: \.key) { module in
                moduleToggleCard(module)
            }
        }
    }

    func moduleToggleCard(_ module: ModuleCardData) -> some View {
        AXCard(accentColor: module.enabled ? module.color : .axTextMuted) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                moduleCardHeader(module)
                moduleCardDescription(module)
                moduleCardFooter(module)
            }
        }
        .opacity(module.enabled ? 1.0 : 0.7)
    }

    func moduleCardHeader(_ module: ModuleCardData) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill((module.enabled ? module.color : Color.axTextMuted).opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: module.icon)
                    .font(AXTypography.subheadline)
                    .foregroundStyle(module.enabled ? module.color : Color.axTextMuted)
            }
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(module.name)
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.axTextPrimary)
                Text(module.category)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { module.enabled },
                set: { newVal in
                    Task { await viewModel.toggleModule(key: module.key, enabled: newVal) }
                    updateModuleState(key: module.key, enabled: newVal)
                }
            ))
            .toggleStyle(.switch)
            .tint(module.color)
            .labelsHidden()
            .disabled(viewModel.configOperationInProgress)
        }
    }

    func moduleCardDescription(_ module: ModuleCardData) -> some View {
        Text(module.description)
            .font(AXTypography.caption)
            .foregroundStyle(module.enabled ? Color.axTextTertiary : Color.axTextMuted)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    func moduleCardFooter(_ module: ModuleCardData) -> some View {
        HStack {
            AXBadge(text: module.layer, color: module.enabled ? module.color : .axTextMuted, style: .soft)
            Spacer()
            HStack(spacing: AXSpacing.xxxs) {
                Circle()
                    .fill(module.enabled ? Color.axAccentGreen : Color.axTextMuted)
                    .frame(width: 6, height: 6)
                Text(module.enabled ? L10n.Status.active : L10n.Status.disabled)
                    .font(AXTypography.caption)
                    .foregroundStyle(module.enabled ? Color.axAccentGreen : Color.axTextMuted)
            }
        }
    }

    func updateModuleState(key: String, enabled: Bool) {
        switch key {
        case "waf_enabled":                   viewModel.wafEnabled = enabled
        case "rate_limit_enabled":            viewModel.rateLimitEnabled = enabled
        case "ddos_enabled":                  viewModel.ddosEnabled = enabled
        case "bot_detection_enabled":         viewModel.botDetectionEnabled = enabled
        case "honeypot_enabled":              viewModel.honeypotEnabled = enabled
        case "credential_protection_enabled": viewModel.credentialEnabled = enabled
        case "dlp_enabled":                   viewModel.dlpEnabled = enabled
        case "ssrf_enabled":                  viewModel.ssrfEnabled = enabled
        case "alerts_enabled":                viewModel.alertsEnabled = enabled
        default: break
        }
    }
}

// MARK: - Config Panels

private extension CerberusModulesView {

    var rateLimitPanel: some View {
        configSection(icon: "gauge.with.dots.needle.33percent", title: L10n.Cerberus.Modules.rateLimiter,
                      color: .axWarning, enabled: viewModel.rateLimitEnabled) {
            configSlider(label: L10n.Cerberus.Modules.globalLimit, value: $viewModel.globalRateLimit,
                         range: 10...2000, unit: "req/min", color: .axWarning)
            configSlider(label: L10n.Cerberus.Modules.loginLimit, value: $viewModel.loginRateLimit,
                         range: 1...100, unit: "req/min", color: .axError)
            configSlider(label: L10n.Cerberus.Modules.apiLimit, value: $viewModel.apiRateLimit,
                         range: 10...1000, unit: "req/min", color: .axAccentBlue)
            configToggle(label: L10n.Cerberus.Modules.throttleMode, sub: L10n.Cerberus.Modules.throttleDesc,
                         value: $viewModel.throttleMode, color: .axWarning)
            saveBtn(label: L10n.Cerberus.Modules.saveRateLimits) { await viewModel.saveRateLimitConfig() }
        }
    }

    var ddosPanel: some View {
        configSection(icon: "bolt.shield", title: L10n.Cerberus.Modules.ddosShield,
                      color: .axError, enabled: viewModel.ddosEnabled) {
            configSlider(label: L10n.Cerberus.Modules.spikeMultiplier, value: $viewModel.ddosSpikeMultiplier,
                         range: 1.5...20, unit: "×", color: .axError)
            configSlider(label: L10n.Cerberus.Modules.maxConnsPerIP, value: $viewModel.ddosMaxConnsPerIP,
                         range: 5...500, unit: "conns", color: .axWarning)
            configToggle(label: L10n.Cerberus.Modules.autoMitigate, sub: L10n.Cerberus.Modules.autoMitigateDesc,
                         value: $viewModel.ddosAutoMitigate, color: .axError)
            saveBtn(label: L10n.Cerberus.Modules.saveDDoSConfig) { await viewModel.saveDDoSConfig() }
        }
    }

    var credentialPanel: some View {
        configSection(icon: "key.fill", title: L10n.Cerberus.Modules.credentialGuard,
                      color: .axError, enabled: viewModel.credentialEnabled) {
            configSlider(label: L10n.Cerberus.Modules.maxAttemptsIP, value: $viewModel.credMaxPerIP,
                         range: 3...200, unit: "per hour", color: .axError)
            configSlider(label: L10n.Cerberus.Modules.maxAttemptsUser, value: $viewModel.credMaxPerUser,
                         range: 3...100, unit: "per hour", color: .axWarning)
            saveBtn(label: L10n.Cerberus.Modules.saveCredConfig) { await viewModel.saveCredentialConfig() }
        }
    }

    var dlpPanel: some View {
        configSection(icon: "doc.text.magnifyingglass", title: L10n.Cerberus.Modules.dlpScanner,
                      color: .axAccentPurple, enabled: viewModel.dlpEnabled) {
            dlpModePicker
            configToggle(label: L10n.Cerberus.Modules.creditCards, sub: L10n.Cerberus.Modules.creditCardsDesc,
                         value: $viewModel.dlpCreditCards, color: .axAccentPurple)
            configToggle(label: L10n.Cerberus.Modules.apiKeys, sub: L10n.Cerberus.Modules.apiKeysDesc,
                         value: $viewModel.dlpAPIKeys, color: .axAccentPurple)
            configToggle(label: L10n.Cerberus.Modules.stackTraces, sub: L10n.Cerberus.Modules.stackTracesDesc,
                         value: $viewModel.dlpStackTraces, color: .axAccentPurple)
            saveBtn(label: L10n.Cerberus.Modules.saveDLPConfig) { await viewModel.saveDLPConfig() }
        }
    }

    var honeypotPanel: some View {
        configSection(icon: "ant", title: L10n.Cerberus.Modules.honeypot,
                      color: .axWarning, enabled: viewModel.honeypotEnabled) {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(L10n.Cerberus.Modules.trapPaths).font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
                AXTextField(placeholder: "/wp-admin,/.env,/phpmyadmin", text: $viewModel.honeypotPaths,
                            icon: "ant", accentColor: .axWarning)
            }
            configToggle(label: L10n.Cerberus.Modules.autoBlockVisitors, sub: L10n.Cerberus.Modules.autoBlockDesc,
                         value: $viewModel.honeypotAutoBlock, color: .axWarning)
            saveBtn(label: L10n.Cerberus.Modules.saveHoneypotConfig) { await viewModel.saveHoneypotConfig() }
        }
    }

    var alertsPanel: some View {
        configSection(icon: "bell.badge", title: L10n.Cerberus.Modules.alertDispatcher,
                      color: .axAccentGreen, enabled: viewModel.alertsEnabled) {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(L10n.Cerberus.Modules.webhookURL).font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
                AXTextField(placeholder: "https://hooks.example.com/...", text: $viewModel.alertWebhookURL,
                            icon: "link", accentColor: .axAccentGreen)
            }
            configSlider(label: L10n.Cerberus.Modules.maxAlertsPerHour, value: $viewModel.alertMaxPerHour,
                         range: 1...100, unit: "alerts", color: .axAccentGreen)
            alertSeverityPicker
            saveBtn(label: L10n.Cerberus.Modules.saveAlertConfig) { await viewModel.saveAlertsConfig() }
        }
    }
}

// MARK: - DLP Mode Picker

private extension CerberusModulesView {

    var dlpModePicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.Cerberus.Modules.actionMode).font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
            HStack(spacing: AXSpacing.sm) {
                ForEach(["log", "mask", "block"], id: \.self) { mode in
                    Button { viewModel.dlpMode = mode } label: {
                        Text(mode.capitalized)
                            .font(AXTypography.monoSm)
                            .foregroundStyle(viewModel.dlpMode == mode ? Color.axTextPrimary : Color.axTextMuted)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .fill(viewModel.dlpMode == mode ? Color.axAccentPurple.opacity(0.2) : Color.axSurface.opacity(0.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                dlpModeInfo
            }
        }
    }

    var dlpModeInfo: some View {
        let (text, color): (String, Color) = {
            switch viewModel.dlpMode {
            case "block": return (L10n.Cerberus.Modules.dlpBlocksResponse, .axError)
            case "mask":  return (L10n.Cerberus.Modules.dlpRedactsData, .axWarning)
            default:      return (L10n.Cerberus.Modules.dlpLogsOnly, .axAccentGreen)
            }
        }()
        return AXBadge(text: text, color: color, style: .soft)
    }
}

// MARK: - Alert Severity Picker

private extension CerberusModulesView {

    var alertSeverityPicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.Cerberus.Modules.minimumSeverity).font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
            HStack(spacing: AXSpacing.sm) {
                ForEach(["low", "medium", "high", "critical"], id: \.self) { sev in
                    Button { viewModel.alertSeverity = sev } label: {
                        Text(sev.capitalized)
                            .font(AXTypography.monoXs)
                            .foregroundStyle(viewModel.alertSeverity == sev ? Color.axTextPrimary : Color.axTextMuted)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, AXSpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .fill(viewModel.alertSeverity == sev ? Color.axAccentGreen.opacity(0.2) : Color.axSurface.opacity(0.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Reusable Config Components

private extension CerberusModulesView {

    func configSection<Content: View>(
        icon: String, title: String, color: Color, enabled: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        AXCard(accentColor: enabled ? color : .axTextMuted) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                configSectionHeader(icon: icon, title: title, color: color, enabled: enabled)
                if enabled {
                    content()
                } else {
                    Text(L10n.Cerberus.Modules.enableToConfig)
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextMuted)
                        .padding(.vertical, AXSpacing.sm)
                }
            }
        }
        .opacity(enabled ? 1.0 : 0.65)
    }

    func configSectionHeader(icon: String, title: String, color: Color, enabled: Bool) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill((enabled ? color : Color.axTextMuted).opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(AXTypography.caption)
                    .foregroundStyle(enabled ? color : Color.axTextMuted)
            }
            Text(title)
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextPrimary)
            Spacer()
            if !enabled {
                AXBadge(text: L10n.Status.disabled, color: .axTextMuted, style: .soft)
            }
        }
    }

    func configSlider(
        label: String, value: Binding<Double>,
        range: ClosedRange<Double>, unit: String, color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            HStack {
                Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextTertiary)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(AXTypography.monoSm)
                    .foregroundStyle(color)
            }
            Slider(value: value, in: range).tint(color)
        }
    }

    func configToggle(
        label: String, sub: String, value: Binding<Bool>, color: Color
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(label).font(AXTypography.caption).foregroundStyle(Color.axTextPrimary)
                Text(sub).font(AXTypography.caption).foregroundStyle(Color.axTextMuted)
            }
            Spacer()
            Toggle("", isOn: value).toggleStyle(.switch).tint(color).labelsHidden()
        }
    }

    func saveBtn(label: String, action: @escaping () async -> Void) -> some View {
        HStack {
            Spacer()
            AXPrimaryButton(
                title: label, icon: "checkmark.circle.fill",
                action: { Task { await action() } },
                isLoading: viewModel.configOperationInProgress
            )
        }
    }
}

// MARK: - Module Card Data

private extension CerberusModulesView {

    var moduleCards: [ModuleCardData] {[
        ModuleCardData(key: "waf_enabled", name: L10n.Cerberus.Modules.wafEngine, icon: "shield.checkered",
                       color: .axAccentBlue, category: "Core", layer: "L7",
                       description: L10n.Cerberus.Modules.wafDesc,
                       enabled: viewModel.wafEnabled),
        ModuleCardData(key: "rate_limit_enabled", name: L10n.Cerberus.Modules.rateLimiter, icon: "gauge.with.dots.needle.33percent",
                       color: .axWarning, category: "Traffic", layer: "L7",
                       description: L10n.Cerberus.Modules.rateLimiterDesc,
                       enabled: viewModel.rateLimitEnabled),
        ModuleCardData(key: "ddos_enabled", name: L10n.Cerberus.Modules.ddosShield, icon: "bolt.shield",
                       color: .axError, category: "Defense", layer: "L7",
                       description: L10n.Cerberus.Modules.ddosDesc,
                       enabled: viewModel.ddosEnabled),
        ModuleCardData(key: "bot_detection_enabled", name: L10n.Cerberus.Modules.botDetector, icon: "cpu",
                       color: .axInfo, category: "Detection", layer: "L7",
                       description: L10n.Cerberus.Modules.botDesc,
                       enabled: viewModel.botDetectionEnabled),
        ModuleCardData(key: "honeypot_enabled", name: L10n.Cerberus.Modules.honeypot, icon: "ant",
                       color: .axWarning, category: "Detection", layer: "L7",
                       description: L10n.Cerberus.Modules.honeypotDesc,
                       enabled: viewModel.honeypotEnabled),
        ModuleCardData(key: "credential_protection_enabled", name: L10n.Cerberus.Modules.credentialGuard, icon: "key.fill",
                       color: .axError, category: "Auth", layer: "L7",
                       description: L10n.Cerberus.Modules.credDesc,
                       enabled: viewModel.credentialEnabled),
        ModuleCardData(key: "dlp_enabled", name: L10n.Cerberus.Modules.dlpScanner, icon: "doc.text.magnifyingglass",
                       color: .axAccentPurple, category: "Data", layer: "L7",
                       description: L10n.Cerberus.Modules.dlpDesc,
                       enabled: viewModel.dlpEnabled),
        ModuleCardData(key: "ssrf_enabled", name: L10n.Cerberus.Modules.ssrfDetector, icon: "arrow.triangle.branch",
                       color: .axWarning, category: "Detection", layer: "L7",
                       description: L10n.Cerberus.Modules.ssrfDesc,
                       enabled: viewModel.ssrfEnabled),
        ModuleCardData(key: "alerts_enabled", name: L10n.Cerberus.Modules.alertDispatcher, icon: "bell.badge",
                       color: .axAccentGreen, category: "Alerting", layer: "SVC",
                       description: L10n.Cerberus.Modules.alertDesc,
                       enabled: viewModel.alertsEnabled),
    ]}
}

private struct ModuleCardData {
    let key: String
    let name: String
    let icon: String
    let color: Color
    let category: String
    let layer: String
    let description: String
    let enabled: Bool
}
