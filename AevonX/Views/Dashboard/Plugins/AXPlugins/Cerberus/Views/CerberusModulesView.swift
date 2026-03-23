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
                modulesHeaderCard
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

    // MARK: - Header

    private var modulesHeaderCard: some View {
        AXGlassCard {
            HStack(spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(AXTypography.headline)
                            .foregroundStyle(Color.axAccentBlue)
                        Text("Security Control Center")
                            .font(AXTypography.headline)
                            .foregroundStyle(Color.axTextPrimary)
                    }
                    Text("Toggle modules live · edit config in real time · changes reload instantly")
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextTertiary)
                }
                Spacer()
                if viewModel.configOperationInProgress {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                AXBadge(text: "\(moduleCards.filter(\.enabled).count)/\(moduleCards.count) active",
                        color: .axAccentGreen, style: .soft)
            }
        }
    }

    // MARK: - Module Toggle Grid

    private var moduleToggleGrid: some View {
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

    private func moduleToggleCard(_ module: ModuleCard) -> some View {
        AXCard(accentColor: module.enabled ? module.color : .axTextMuted) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                moduleToggleHeader(module)
                Text(module.description)
                    .font(AXTypography.caption)
                    .foregroundStyle(module.enabled ? Color.axTextTertiary : Color.axTextMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    AXBadge(text: module.layer, color: module.enabled ? module.color : .axTextMuted, style: .soft)
                    Spacer()
                    moduleStatusDot(enabled: module.enabled)
                }
            }
        }
        .opacity(module.enabled ? 1.0 : 0.7)
    }

    private func moduleToggleHeader(_ module: ModuleCard) -> some View {
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

    private func moduleStatusDot(enabled: Bool) -> some View {
        HStack(spacing: AXSpacing.xxxs) {
            Circle()
                .fill(enabled ? Color.axAccentGreen : Color.axTextMuted)
                .frame(width: 6, height: 6)
            Text(enabled ? "Active" : "Disabled")
                .font(AXTypography.caption)
                .foregroundStyle(enabled ? Color.axAccentGreen : Color.axTextMuted)
        }
    }

    private func updateModuleState(key: String, enabled: Bool) {
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

    // MARK: - Rate Limit Panel

    private var rateLimitPanel: some View {
        configSection(
            icon: "gauge.with.dots.needle.33percent",
            title: "Rate Limiter",
            color: .axWarning,
            enabled: viewModel.rateLimitEnabled
        ) {
            configSlider(label: "Global Limit", value: $viewModel.globalRateLimit,
                         range: 10...2000, unit: "req/min", color: .axWarning)
            configSlider(label: "Login Limit", value: $viewModel.loginRateLimit,
                         range: 1...100, unit: "req/min", color: .axError)
            configSlider(label: "API Limit", value: $viewModel.apiRateLimit,
                         range: 10...1000, unit: "req/min", color: .axAccentBlue)
            configToggleRow(label: "Throttle Mode", subtitle: "Delay instead of hard block",
                            value: $viewModel.throttleMode, color: .axWarning)
            saveButton(label: "Save Rate Limits") { await viewModel.saveRateLimitConfig() }
        }
    }

    // MARK: - DDoS Panel

    private var ddosPanel: some View {
        configSection(
            icon: "bolt.shield",
            title: "DDoS Shield",
            color: .axError,
            enabled: viewModel.ddosEnabled
        ) {
            configSlider(label: "Spike Multiplier", value: $viewModel.ddosSpikeMultiplier,
                         range: 1.5...20, unit: "×", color: .axError)
            configSlider(label: "Max Conns / IP", value: $viewModel.ddosMaxConnsPerIP,
                         range: 5...500, unit: "conns", color: .axWarning)
            configToggleRow(label: "Auto Mitigate", subtitle: "Escalate level automatically",
                            value: $viewModel.ddosAutoMitigate, color: .axError)
            saveButton(label: "Save DDoS Config") { await viewModel.saveDDoSConfig() }
        }
    }

    // MARK: - Credential Panel

    private var credentialPanel: some View {
        configSection(
            icon: "key.fill",
            title: "Credential Guard",
            color: .axError,
            enabled: viewModel.credentialEnabled
        ) {
            configSlider(label: "Max Attempts / IP", value: $viewModel.credMaxPerIP,
                         range: 3...200, unit: "per hour", color: .axError)
            configSlider(label: "Max Attempts / User", value: $viewModel.credMaxPerUser,
                         range: 3...100, unit: "per hour", color: .axWarning)
            saveButton(label: "Save Credential Config") { await viewModel.saveCredentialConfig() }
        }
    }

    // MARK: - DLP Panel

    private var dlpPanel: some View {
        configSection(
            icon: "doc.text.magnifyingglass",
            title: "DLP Scanner",
            color: .axAccentPurple,
            enabled: viewModel.dlpEnabled
        ) {
            dlpModePicker
            configToggleRow(label: "Credit Cards", subtitle: "Luhn-validated detection",
                            value: $viewModel.dlpCreditCards, color: .axAccentPurple)
            configToggleRow(label: "API Keys & Tokens", subtitle: "Bearer tokens, secret keys",
                            value: $viewModel.dlpAPIKeys, color: .axAccentPurple)
            configToggleRow(label: "Stack Traces", subtitle: "Exception and DB error leaks",
                            value: $viewModel.dlpStackTraces, color: .axAccentPurple)
            saveButton(label: "Save DLP Config") { await viewModel.saveDLPConfig() }
        }
    }

    private var dlpModePicker: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text("Action Mode")
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
            HStack(spacing: AXSpacing.sm) {
                ForEach(["log", "mask", "block"], id: \.self) { mode in
                    Button {
                        viewModel.dlpMode = mode
                    } label: {
                        Text(mode.capitalized)
                            .font(AXTypography.monoSm)
                            .foregroundStyle(viewModel.dlpMode == mode ? Color.axTextPrimary : Color.axTextMuted)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .fill(viewModel.dlpMode == mode
                                          ? Color.axAccentPurple.opacity(0.2)
                                          : Color.axSurface.opacity(0.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                modeInfoBadge
            }
        }
    }

    private var modeInfoBadge: some View {
        let (text, color): (String, Color) = {
            switch viewModel.dlpMode {
            case "block": return ("Blocks response", .axError)
            case "mask":  return ("Redacts data", .axWarning)
            default:      return ("Logs only", .axAccentGreen)
            }
        }()
        return AXBadge(text: text, color: color, style: .soft)
    }

    // MARK: - Honeypot Panel

    private var honeypotPanel: some View {
        configSection(
            icon: "ant",
            title: "Honeypot",
            color: .axWarning,
            enabled: viewModel.honeypotEnabled
        ) {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Trap Paths")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
                AXTextField(
                    placeholder: "/wp-admin,/.env,/phpmyadmin",
                    text: $viewModel.honeypotPaths,
                    icon: "ant",
                    accentColor: .axWarning
                )
            }
            configToggleRow(label: "Auto-Block Visitors", subtitle: "Block IPs that hit trap paths",
                            value: $viewModel.honeypotAutoBlock, color: .axWarning)
            saveButton(label: "Save Honeypot Config") { await viewModel.saveHoneypotConfig() }
        }
    }

    // MARK: - Alerts Panel

    private var alertsPanel: some View {
        configSection(
            icon: "bell.badge",
            title: "Alert Dispatcher",
            color: .axAccentGreen,
            enabled: viewModel.alertsEnabled
        ) {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Webhook URL")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
                AXTextField(
                    placeholder: "https://hooks.example.com/...",
                    text: $viewModel.alertWebhookURL,
                    icon: "link",
                    accentColor: .axAccentGreen
                )
            }
            configSlider(label: "Max Alerts / Hour", value: $viewModel.alertMaxPerHour,
                         range: 1...100, unit: "alerts", color: .axAccentGreen)
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Minimum Severity")
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
                HStack(spacing: AXSpacing.sm) {
                    ForEach(["low", "medium", "high", "critical"], id: \.self) { sev in
                        Button {
                            viewModel.alertSeverity = sev
                        } label: {
                            Text(sev.capitalized)
                                .font(AXTypography.monoXs)
                                .foregroundStyle(viewModel.alertSeverity == sev
                                                 ? Color.axTextPrimary : Color.axTextMuted)
                                .padding(.horizontal, AXSpacing.xs)
                                .padding(.vertical, AXSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                        .fill(viewModel.alertSeverity == sev
                                              ? Color.axAccentGreen.opacity(0.2)
                                              : Color.axSurface.opacity(0.5))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }
            saveButton(label: "Save Alert Config") { await viewModel.saveAlertsConfig() }
        }
    }

    // MARK: - Reusable Config Components

    private func configSection<Content: View>(
        icon: String, title: String, color: Color, enabled: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        AXCard(accentColor: enabled ? color : .axTextMuted) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
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
                        AXBadge(text: "Disabled", color: .axTextMuted, style: .soft)
                    }
                }
                if enabled {
                    content()
                } else {
                    Text("Enable this module to configure it.")
                        .font(AXTypography.caption)
                        .foregroundStyle(Color.axTextMuted)
                        .padding(.vertical, AXSpacing.sm)
                }
            }
        }
        .opacity(enabled ? 1.0 : 0.65)
    }

    private func configSlider(
        label: String, value: Binding<Double>,
        range: ClosedRange<Double>, unit: String, color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            HStack {
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextTertiary)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(AXTypography.monoSm)
                    .foregroundStyle(color)
            }
            Slider(value: value, in: range)
                .tint(color)
        }
    }

    private func configToggleRow(
        label: String, subtitle: String,
        value: Binding<Bool>, color: Color
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(label)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextPrimary)
                Text(subtitle)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextMuted)
            }
            Spacer()
            Toggle("", isOn: value)
                .toggleStyle(.switch)
                .tint(color)
                .labelsHidden()
        }
    }

    private func saveButton(label: String, action: @escaping () async -> Void) -> some View {
        HStack {
            Spacer()
            AXPrimaryButton(
                title: label,
                icon: "checkmark.circle.fill",
                action: { Task { await action() } },
                isLoading: viewModel.configOperationInProgress
            )
        }
    }

    // MARK: - Module Card Data

    private var moduleCards: [ModuleCard] {[
        ModuleCard(key: "waf_enabled", name: "WAF Engine", icon: "shield.checkered",
                   color: .axAccentBlue, category: "Core", layer: "L7",
                   description: "Coraza ModSecurity — SQLi, XSS, path traversal",
                   enabled: viewModel.wafEnabled),
        ModuleCard(key: "rate_limit_enabled", name: "Rate Limiter", icon: "gauge.with.dots.needle.33percent",
                   color: .axWarning, category: "Traffic", layer: "L7",
                   description: "Per-IP sliding-window rate limiting (3 tiers)",
                   enabled: viewModel.rateLimitEnabled),
        ModuleCard(key: "ddos_enabled", name: "DDoS Shield", icon: "bolt.shield",
                   color: .axError, category: "Defense", layer: "L7",
                   description: "EWMA baseline spike detection + auto-mitigation",
                   enabled: viewModel.ddosEnabled),
        ModuleCard(key: "bot_detection_enabled", name: "Bot Detector", icon: "cpu",
                   color: .axInfo, category: "Detection", layer: "L7",
                   description: "User-Agent classification (human/bot/malicious)",
                   enabled: viewModel.botDetectionEnabled),
        ModuleCard(key: "honeypot_enabled", name: "Honeypot", icon: "ant",
                   color: .axWarning, category: "Detection", layer: "L7",
                   description: "Trap endpoints to detect and log attackers",
                   enabled: viewModel.honeypotEnabled),
        ModuleCard(key: "credential_protection_enabled", name: "Credential Guard", icon: "key.fill",
                   color: .axError, category: "Auth", layer: "L7",
                   description: "Brute force and credential stuffing detection",
                   enabled: viewModel.credentialEnabled),
        ModuleCard(key: "dlp_enabled", name: "DLP Scanner", icon: "doc.text.magnifyingglass",
                   color: .axAccentPurple, category: "Data", layer: "L7",
                   description: "Scans responses for credit cards, API keys, traces",
                   enabled: viewModel.dlpEnabled),
        ModuleCard(key: "ssrf_enabled", name: "SSRF Detector", icon: "arrow.triangle.branch",
                   color: .axWarning, category: "Detection", layer: "L7",
                   description: "Prevents Server-Side Request Forgery attacks",
                   enabled: viewModel.ssrfEnabled),
        ModuleCard(key: "alerts_enabled", name: "Alert Dispatcher", icon: "bell.badge",
                   color: .axAccentGreen, category: "Alerting", layer: "SVC",
                   description: "Routes security events to webhooks",
                   enabled: viewModel.alertsEnabled),
    ]}
}

// MARK: - Module Card Model

private struct ModuleCard {
    let key: String
    let name: String
    let icon: String
    let color: Color
    let category: String
    let layer: String
    let description: String
    let enabled: Bool
}
