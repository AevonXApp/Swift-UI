//
//  CerberusViewModel.swift
//  AevonX
//
//  ViewModel for AXCerberus WAF management UI.
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - Tab

enum CerberusTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case attacks = "Attacks"
    case websites = "Websites"
    case ipManagement = "IP Management"
    case modules = "Modules"
    case honeypot = "Honeypot"

    var icon: String {
        switch self {
        case .dashboard: return "shield.checkered"
        case .attacks: return "exclamationmark.triangle"
        case .websites: return "globe"
        case .ipManagement: return "network"
        case .modules: return "square.grid.2x2"
        case .honeypot: return "ant"
        }
    }
}

// MARK: - ViewModel

@MainActor
class CerberusViewModel: ObservableObject {

    // MARK: - Navigation

    @Published var selectedTab: CerberusTab = .dashboard

    // MARK: - Loading State

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dashboard Data

    @Published var overview: WAFOverview?
    @Published var timeline: [TimelineEntry] = []
    @Published var ddosStatus: DDoSStatus?
    @Published var serviceStatus: WAFServiceStatus?
    @Published var credentialStatus: CredentialStatus?

    // MARK: - Attacks Data

    @Published var attackTypes: [AttackTypeStats] = []
    @Published var topAttackers: [AttackerInfo] = []
    @Published var topURIs: [URIStats] = []
    @Published var countries: [CountryStats] = []

    // MARK: - IP Management

    @Published var blockedIPs: [String] = []
    @Published var allowedIPs: [String] = []
    @Published var ipOperationInProgress = false

    // MARK: - GeoIP

    @Published var blockedCountries: [String] = []
    @Published var geoIPOperationInProgress = false

    // MARK: - Honeypot

    @Published var honeypotHits: [HoneypotHit] = []

    // MARK: - Domain Stats

    @Published var domainStats: [String: DomainStats] = [:]

    // MARK: - Module Config State

    @Published var configOperationInProgress = false

    // Module toggles (by config key)
    @Published var wafEnabled = true
    @Published var rateLimitEnabled = true
    @Published var ddosEnabled = true
    @Published var botDetectionEnabled = true
    @Published var honeypotEnabled = false
    @Published var credentialEnabled = true
    @Published var dlpEnabled = true
    @Published var ssrfEnabled = true
    @Published var alertsEnabled = false

    // Rate Limit config
    @Published var globalRateLimit: Double = 300
    @Published var loginRateLimit: Double = 10
    @Published var apiRateLimit: Double = 120
    @Published var throttleMode = false

    // DLP config
    @Published var dlpMode = "log"
    @Published var dlpCreditCards = true
    @Published var dlpAPIKeys = true
    @Published var dlpStackTraces = true

    // Credential config
    @Published var credMaxPerIP: Double = 20
    @Published var credMaxPerUser: Double = 10

    // DDoS config
    @Published var ddosAutoMitigate = true
    @Published var ddosSpikeMultiplier: Double = 3.0
    @Published var ddosMaxConnsPerIP: Double = 100

    // Honeypot config
    @Published var honeypotPaths = "/wp-admin,/phpmyadmin,/.env"
    @Published var honeypotAutoBlock = true

    // Alerts config
    @Published var alertWebhookURL = ""
    @Published var alertMaxPerHour: Double = 10
    @Published var alertSeverity = "high"

    // MARK: - Config

    let serverId: String
    private let cerberus = CerberusManager.shared

    init(serverId: String) {
        self.serverId = serverId
    }

    // MARK: - Load All Dashboard Data

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            async let o  = cerberus.getOverview(on: serverId)
            async let t  = cerberus.getTimeline(on: serverId)
            async let d  = cerberus.getDDoSStatus(on: serverId)
            async let s  = cerberus.getServiceStatus(on: serverId)
            async let c  = cerberus.getCredentialStatus(on: serverId)
            async let co = cerberus.getCountries(on: serverId)

            let (ov, tl, dd, sv, cr, ctrs) = try await (o, t, d, s, c, co)
            overview        = ov
            timeline        = tl
            ddosStatus      = dd
            serviceStatus   = sv
            credentialStatus = cr
            countries       = ctrs
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load Attacks Data

    func loadAttacks() async {
        isLoading = true
        errorMessage = nil

        do {
            async let at = cerberus.getAttackTypes(on: serverId)
            async let ta = cerberus.getTopAttackers(on: serverId)
            async let tu = cerberus.getTopURIs(on: serverId)
            async let co = cerberus.getCountries(on: serverId)

            let (types, attackers, uris, ctrs) = try await (at, ta, tu, co)
            attackTypes = types
            topAttackers = attackers
            topURIs = uris
            countries = ctrs
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load IP Lists

    func loadIPLists() async {
        isLoading = true
        errorMessage = nil

        do {
            async let bl = cerberus.listBlockedIPs(on: serverId)
            async let al = cerberus.listAllowedIPs(on: serverId)

            let (blocked, allowed) = try await (bl, al)
            blockedIPs = blocked
            allowedIPs = allowed
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - IP Operations

    func blockIP(_ ip: String) async {
        ipOperationInProgress = true
        do {
            try await cerberus.blockIP(ip, on: serverId)
            GlobalToastManager.shared.showSuccess("Blocked \(ip)")
            await loadIPLists()
        } catch {
            GlobalToastManager.shared.showError("Failed to block \(ip): \(error.localizedDescription)")
        }
        ipOperationInProgress = false
    }

    func unblockIP(_ ip: String) async {
        ipOperationInProgress = true
        do {
            try await cerberus.unblockIP(ip, on: serverId)
            GlobalToastManager.shared.showSuccess("Unblocked \(ip)")
            await loadIPLists()
        } catch {
            GlobalToastManager.shared.showError("Failed to unblock \(ip): \(error.localizedDescription)")
        }
        ipOperationInProgress = false
    }

    func allowIP(_ ip: String) async {
        ipOperationInProgress = true
        do {
            try await cerberus.allowIP(ip, on: serverId)
            GlobalToastManager.shared.showSuccess("Allowed \(ip)")
            await loadIPLists()
        } catch {
            GlobalToastManager.shared.showError("Failed to allow \(ip): \(error.localizedDescription)")
        }
        ipOperationInProgress = false
    }

    func removeAllowedIP(_ ip: String) async {
        ipOperationInProgress = true
        do {
            try await cerberus.removeAllowedIP(ip, on: serverId)
            GlobalToastManager.shared.showSuccess("Removed \(ip) from allowlist")
            await loadIPLists()
        } catch {
            GlobalToastManager.shared.showError("Failed to remove \(ip): \(error.localizedDescription)")
        }
        ipOperationInProgress = false
    }

    // MARK: - GeoIP Operations

    func loadGeoIP() async {
        do {
            blockedCountries = try await cerberus.listBlockedCountries(on: serverId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func blockCountry(_ code: String) async {
        geoIPOperationInProgress = true
        do {
            try await cerberus.blockCountry(code, on: serverId)
            GlobalToastManager.shared.showSuccess("Blocked \(code)")
            await loadGeoIP()
        } catch {
            GlobalToastManager.shared.showError("Failed to block \(code): \(error.localizedDescription)")
        }
        geoIPOperationInProgress = false
    }

    func unblockCountry(_ code: String) async {
        geoIPOperationInProgress = true
        do {
            try await cerberus.unblockCountry(code, on: serverId)
            GlobalToastManager.shared.showSuccess("Unblocked \(code)")
            await loadGeoIP()
        } catch {
            GlobalToastManager.shared.showError("Failed to unblock \(code): \(error.localizedDescription)")
        }
        geoIPOperationInProgress = false
    }

    // MARK: - Load Honeypot

    func loadHoneypot() async {
        isLoading = true
        do {
            honeypotHits = try await cerberus.getHoneypotHits(on: serverId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Load Domain Stats

    func loadDomainStats() async {
        do {
            domainStats = try await cerberus.getDomainStats(on: serverId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Formatting Helpers

    func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }

    func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    func formatUptime(_ seconds: Int) -> String {
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let mins = (seconds % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }

    // MARK: - Load Module Config

    func loadModuleConfig() async {
        do {
            let cfg = try await cerberus.getFullConfig(on: serverId)
            applyConfig(cfg)
        } catch {
            // Non-fatal: config panel shows defaults
        }
    }

    private func applyConfig(_ cfg: [String: Any]) {
        wafEnabled          = cfg.bool("waf_enabled", default: true)
        rateLimitEnabled    = cfg.bool("rate_limit_enabled", default: true)
        ddosEnabled         = cfg.bool("ddos_enabled", default: true)
        botDetectionEnabled = cfg.bool("bot_detection_enabled", default: true)
        honeypotEnabled     = cfg.bool("honeypot_enabled", default: false)
        credentialEnabled   = cfg.bool("credential_protection_enabled", default: true)
        dlpEnabled          = cfg.bool("dlp_enabled", default: true)
        ssrfEnabled         = cfg.bool("ssrf_enabled", default: true)
        alertsEnabled       = cfg.bool("alerts_enabled", default: false)

        globalRateLimit     = cfg.double("global_rate_limit", default: 300)
        loginRateLimit      = cfg.double("login_rate_limit", default: 10)
        apiRateLimit        = cfg.double("api_rate_limit", default: 120)
        throttleMode        = cfg.bool("throttle_mode", default: false)

        dlpMode             = cfg.string("dlp_mode", default: "log")
        dlpCreditCards      = cfg.bool("dlp_credit_cards", default: true)
        dlpAPIKeys          = cfg.bool("dlp_api_keys", default: true)
        dlpStackTraces      = cfg.bool("dlp_stack_traces", default: true)

        credMaxPerIP        = cfg.double("max_login_attempts_per_ip", default: 20)
        credMaxPerUser      = cfg.double("max_login_attempts_per_username", default: 10)

        ddosAutoMitigate    = cfg.bool("ddos_auto_mitigate", default: true)
        ddosSpikeMultiplier = cfg.double("ddos_spike_multiplier", default: 3.0)
        ddosMaxConnsPerIP   = cfg.double("max_connections_per_ip", default: 100)

        honeypotPaths       = cfg.string("honeypot_paths", default: "/wp-admin,/.env")
        honeypotAutoBlock   = cfg.bool("honeypot_auto_block", default: true)

        alertWebhookURL     = cfg.string("alert_webhook_url", default: "")
        alertMaxPerHour     = cfg.double("alert_max_per_hour", default: 10)
        alertSeverity       = cfg.string("alert_severity_threshold", default: "high")
    }

    // MARK: - Toggle Module

    func toggleModule(key: String, enabled: Bool) async {
        configOperationInProgress = true
        do {
            try await cerberus.configSet(key: key, value: enabled ? "true" : "false", on: serverId)
            GlobalToastManager.shared.showSuccess(enabled ? "Module enabled" : "Module disabled")
        } catch {
            GlobalToastManager.shared.showError("Failed: \(error.localizedDescription)")
        }
        configOperationInProgress = false
    }

    // MARK: - Save Config Sections

    func saveRateLimitConfig() async {
        await batchConfigSet([
            ("rate_limit_enabled", rateLimitEnabled ? "true" : "false"),
            ("global_rate_limit",  "\(Int(globalRateLimit))"),
            ("login_rate_limit",   "\(Int(loginRateLimit))"),
            ("api_rate_limit",     "\(Int(apiRateLimit))"),
            ("throttle_mode",      throttleMode ? "true" : "false"),
        ], label: "Rate Limit")
    }

    func saveDLPConfig() async {
        await batchConfigSet([
            ("dlp_enabled",      dlpEnabled ? "true" : "false"),
            ("dlp_mode",         dlpMode),
            ("dlp_credit_cards", dlpCreditCards ? "true" : "false"),
            ("dlp_api_keys",     dlpAPIKeys ? "true" : "false"),
            ("dlp_stack_traces", dlpStackTraces ? "true" : "false"),
        ], label: "DLP")
    }

    func saveCredentialConfig() async {
        await batchConfigSet([
            ("credential_protection_enabled",    credentialEnabled ? "true" : "false"),
            ("max_login_attempts_per_ip",         "\(Int(credMaxPerIP))"),
            ("max_login_attempts_per_username",   "\(Int(credMaxPerUser))"),
        ], label: "Credential Guard")
    }

    func saveDDoSConfig() async {
        await batchConfigSet([
            ("ddos_enabled",          ddosEnabled ? "true" : "false"),
            ("ddos_auto_mitigate",    ddosAutoMitigate ? "true" : "false"),
            ("ddos_spike_multiplier", String(format: "%.1f", ddosSpikeMultiplier)),
            ("max_connections_per_ip","\(Int(ddosMaxConnsPerIP))"),
        ], label: "DDoS Shield")
    }

    func saveHoneypotConfig() async {
        await batchConfigSet([
            ("honeypot_enabled",    honeypotEnabled ? "true" : "false"),
            ("honeypot_paths",      honeypotPaths),
            ("honeypot_auto_block", honeypotAutoBlock ? "true" : "false"),
        ], label: "Honeypot")
    }

    func saveAlertsConfig() async {
        await batchConfigSet([
            ("alerts_enabled",           alertsEnabled ? "true" : "false"),
            ("alert_webhook_url",         alertWebhookURL),
            ("alert_max_per_hour",        "\(Int(alertMaxPerHour))"),
            ("alert_severity_threshold",  alertSeverity),
        ], label: "Alerts")
    }

    private func batchConfigSet(_ pairs: [(String, String)], label: String) async {
        configOperationInProgress = true
        var failed = false
        for (key, value) in pairs {
            do {
                try await cerberus.configSet(key: key, value: value, on: serverId)
            } catch {
                failed = true
                break
            }
        }
        if failed {
            GlobalToastManager.shared.showError("\(label) config save failed")
        } else {
            GlobalToastManager.shared.showSuccess("\(label) config saved")
        }
        configOperationInProgress = false
    }
}

// MARK: - Config Dict Helpers

private extension Dictionary where Key == String, Value == Any {
    func bool(_ key: String, default def: Bool) -> Bool {
        if let b = self[key] as? Bool { return b }
        if let n = self[key] as? Int  { return n != 0 }
        if let s = self[key] as? String { return s == "true" || s == "1" }
        return def
    }
    func double(_ key: String, default def: Double) -> Double {
        if let d = self[key] as? Double { return d }
        if let n = self[key] as? Int    { return Double(n) }
        if let s = self[key] as? String, let d = Double(s) { return d }
        return def
    }
    func string(_ key: String, default def: String) -> String {
        if let s = self[key] as? String { return s }
        return def
    }
}
