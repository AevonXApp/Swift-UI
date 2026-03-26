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
    case traffic = "Traffic"
    case domains = "Domains"
    case ipManagement = "IP Guard"
    case modules = "Modules"
    case honeypot = "Honeypot"
    case alerts = "Alerts"
    case threatFeed = "Threat Intel"
    case compliance = "Compliance"
    case sessions = "Sessions"
    case customRules = "Rules"

    var icon: String {
        switch self {
        case .dashboard: return "shield.checkered"
        case .attacks: return "exclamationmark.triangle.fill"
        case .traffic: return "chart.bar.xaxis"
        case .domains: return "globe"
        case .ipManagement: return "network.badge.shield.half.filled"
        case .modules: return "square.grid.3x3.fill"
        case .honeypot: return "ant.fill"
        case .alerts: return "bell.badge.fill"
        case .threatFeed: return "sensor.tag.radiowaves.forward.fill"
        case .compliance: return "checkmark.shield.fill"
        case .sessions: return "person.2.circle.fill"
        case .customRules: return "doc.text.magnifyingglass"
        }
    }

    var color: Color {
        switch self {
        case .dashboard:    return .axAccentBlue
        case .attacks:      return .axError
        case .traffic:      return .axAccentGreen
        case .domains:      return .mint
        case .ipManagement: return .axAccentPurple
        case .modules:      return .indigo
        case .honeypot:     return .axWarning
        case .alerts:       return .axError
        case .threatFeed:   return .axAccentPurple
        case .compliance:   return .axAccentGreen
        case .sessions:     return .cyan
        case .customRules:  return .axAccentBlue
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

    // MARK: - Domain Management

    @Published var domains: [WAFDomainInfo] = []
    @Published var webServerInfo: WAFWebServerInfo?
    @Published var domainOperationInProgress = false

    // MARK: - Domain Stats

    @Published var domainStats: [String: DomainStats] = [:]

    // MARK: - Extended Stats

    @Published var responseTimes: WAFResponseTimes?
    @Published var statusCodes: [WAFStatusCode] = []
    @Published var botDetails: WAFBotDetails?
    @Published var recentAlerts: [WAFAlertEvent] = []
    @Published var accessLog: [WAFAccessLogEntry] = []
    @Published var blockLog: [WAFBlockLogEntry] = []

    // MARK: - Service Lifecycle

    @Published var serviceOperationInProgress = false

    // MARK: - Threat Intelligence

    @Published var threatFeedStatus: WAFThreatFeedStatus?
    @Published var threatFeedLoading = false

    // MARK: - Compliance

    @Published var complianceReport: WAFComplianceReport?
    @Published var complianceLoading = false

    // MARK: - Virtual Patching

    @Published var vPatches: [WAFVirtualPatch] = []

    // MARK: - Anomaly Detection

    @Published var anomalyStatus: WAFAnomalyStatus?
    @Published var anomalyLoading = false

    // MARK: - Session Tracking

    @Published var sessionStatus: WAFSessionStatus?
    @Published var sessionLoading = false

    // MARK: - Custom Rules

    @Published var customRules: [WAFCustomRule] = []
    @Published var rulesLoading = false

    // MARK: - Config Backups

    @Published var configBackups: [WAFConfigBackup] = []

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

    // MARK: - Domain Management

    func loadDomains() async {
        do {
            async let d = cerberus.listDomains(on: serverId)
            async let w = cerberus.detectWebServer(on: serverId)
            let (domainList, wsInfo) = try await (d, w)
            domains = domainList
            webServerInfo = wsInfo
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addDomain(_ domain: String) async {
        domainOperationInProgress = true
        do {
            try await cerberus.addDomain(domain, on: serverId)
            GlobalToastManager.shared.showSuccess("Added \(domain)")
            await loadDomains()
        } catch {
            GlobalToastManager.shared.showError("Failed to add \(domain): \(error.localizedDescription)")
        }
        domainOperationInProgress = false
    }

    func removeDomain(_ domain: String) async {
        domainOperationInProgress = true
        do {
            try await cerberus.removeDomain(domain, on: serverId)
            GlobalToastManager.shared.showSuccess("Removed \(domain)")
            await loadDomains()
        } catch {
            GlobalToastManager.shared.showError("Failed to remove \(domain): \(error.localizedDescription)")
        }
        domainOperationInProgress = false
    }

    func toggleDomain(_ domain: String, enabled: Bool) async {
        domainOperationInProgress = true
        do {
            if enabled {
                try await cerberus.enableDomain(domain, on: serverId)
            } else {
                try await cerberus.disableDomain(domain, on: serverId)
            }
            await loadDomains()
        } catch {
            GlobalToastManager.shared.showError("Failed: \(error.localizedDescription)")
        }
        domainOperationInProgress = false
    }

    func syncDomains() async {
        domainOperationInProgress = true
        do {
            let result = try await cerberus.syncDomains(on: serverId)
            if result.synced > 0 {
                GlobalToastManager.shared.showSuccess("Synced \(result.synced) new domain(s)")
            } else {
                GlobalToastManager.shared.showSuccess("All domains up to date")
            }
            await loadDomains()
        } catch {
            GlobalToastManager.shared.showError("Sync failed: \(error.localizedDescription)")
        }
        domainOperationInProgress = false
    }

    // MARK: - Load Extended Stats

    func loadTrafficAnalytics() async {
        isLoading = true
        do {
            async let ds = cerberus.getDomainStats(on: serverId)
            async let rt = cerberus.getResponseTimes(on: serverId)
            async let sc = cerberus.getStatusCodes(on: serverId)
            async let bd = cerberus.getBotDetails(on: serverId)

            let (domains, times, codes, bots) = try await (ds, rt, sc, bd)
            domainStats = domains
            responseTimes = times
            statusCodes = codes
            botDetails = bots
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadAlerts() async {
        isLoading = true
        do {
            recentAlerts = try await cerberus.getRecentAlerts(on: serverId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadAccessLog() async {
        do {
            accessLog = try await cerberus.getAccessLog(on: serverId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadBlockLog() async {
        do {
            blockLog = try await cerberus.getBlockLog(on: serverId)
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

    // MARK: - Service Lifecycle Actions

    func startService() async {
        guard !serviceOperationInProgress else { return }
        serviceOperationInProgress = true
        do {
            _ = try await cerberus.serviceStart(on: serverId)
            serviceStatus = try? await cerberus.getServiceStatus(on: serverId)
            GlobalToastManager.shared.showSuccess("WAF service started")
        } catch {
            GlobalToastManager.shared.showError("Start failed: \(error.localizedDescription)")
        }
        serviceOperationInProgress = false
    }

    func stopService() async {
        guard !serviceOperationInProgress else { return }
        serviceOperationInProgress = true
        do {
            _ = try await cerberus.serviceStop(on: serverId)
            serviceStatus = try? await cerberus.getServiceStatus(on: serverId)
            GlobalToastManager.shared.showSuccess("WAF service stopped")
        } catch {
            GlobalToastManager.shared.showError("Stop failed: \(error.localizedDescription)")
        }
        serviceOperationInProgress = false
    }

    func restartService() async {
        guard !serviceOperationInProgress else { return }
        serviceOperationInProgress = true
        do {
            _ = try await cerberus.serviceRestart(on: serverId)
            serviceStatus = try? await cerberus.getServiceStatus(on: serverId)
            GlobalToastManager.shared.showSuccess("WAF service restarted")
        } catch {
            GlobalToastManager.shared.showError("Restart failed: \(error.localizedDescription)")
        }
        serviceOperationInProgress = false
    }

    func reloadService() async {
        guard !serviceOperationInProgress else { return }
        serviceOperationInProgress = true
        do {
            _ = try await cerberus.serviceReload(on: serverId)
            GlobalToastManager.shared.showSuccess("WAF config reloaded")
        } catch {
            GlobalToastManager.shared.showError("Reload failed: \(error.localizedDescription)")
        }
        serviceOperationInProgress = false
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

    // MARK: - Threat Feed

    func loadThreatFeedStatus() async {

        threatFeedLoading = true
        do {
            threatFeedStatus = try await cerberus.getThreatFeedStatus(on: serverId)
        } catch {
            GlobalToastManager.shared.showError("Threat feed: \(error.localizedDescription)")
        }
        threatFeedLoading = false
    }

    func updateThreatFeed() async {

        threatFeedLoading = true
        do {
            threatFeedStatus = try await cerberus.updateThreatFeed(on: serverId)
            GlobalToastManager.shared.showSuccess("Threat feeds updated")
        } catch {
            GlobalToastManager.shared.showError("Threat feed update: \(error.localizedDescription)")
        }
        threatFeedLoading = false
    }

    // MARK: - Compliance

    func loadComplianceReport() async {

        complianceLoading = true
        do {
            complianceReport = try await cerberus.getComplianceReport(on: serverId)
        } catch {
            GlobalToastManager.shared.showError("Compliance: \(error.localizedDescription)")
        }
        complianceLoading = false
    }

    // MARK: - Virtual Patching

    func loadVPatches() async {

        do {
            vPatches = try await cerberus.listVPatches(on: serverId)
        } catch {
            GlobalToastManager.shared.showError("VPatches: \(error.localizedDescription)")
        }
    }

    func removeVPatch(_ id: String) async {

        do {
            try await cerberus.removeVPatch(id, on: serverId)
            await loadVPatches()
            GlobalToastManager.shared.showSuccess("Virtual patch removed")
        } catch {
            GlobalToastManager.shared.showError("Remove vpatch: \(error.localizedDescription)")
        }
    }

    // MARK: - Config Backups

    func loadConfigBackups() async {

        do {
            configBackups = try await cerberus.listConfigBackups(on: serverId)
        } catch {
            GlobalToastManager.shared.showError("Backups: \(error.localizedDescription)")
        }
    }

    func createConfigBackup() async {

        do {
            _ = try await cerberus.configBackup(on: serverId)
            await loadConfigBackups()
            GlobalToastManager.shared.showSuccess("Config backup created")
        } catch {
            GlobalToastManager.shared.showError("Backup: \(error.localizedDescription)")
        }
    }

    // MARK: - Anomaly Detection

    func loadAnomalyStatus() async {
        anomalyLoading = true
        do {
            anomalyStatus = try await cerberus.getAnomalyStatus(on: serverId)
        } catch {
            GlobalToastManager.shared.showError("Anomaly: \(error.localizedDescription)")
        }
        anomalyLoading = false
    }

    // MARK: - Session Tracking

    func loadSessionStatus() async {
        sessionLoading = true
        do {
            sessionStatus = try await cerberus.getSessionStatus(on: serverId)
        } catch {
            GlobalToastManager.shared.showError("Session: \(error.localizedDescription)")
        }
        sessionLoading = false
    }

    // MARK: - Custom Rules

    func loadCustomRules() async {
        rulesLoading = true
        do {
            customRules = try await cerberus.listRules(on: serverId)
        } catch {
            GlobalToastManager.shared.showError("Rules: \(error.localizedDescription)")
        }
        rulesLoading = false
    }

    func addCustomRule(id: String, expression: String) async {
        do {
            try await cerberus.addRule(id: id, expression: expression, on: serverId)
            await loadCustomRules()
            GlobalToastManager.shared.showSuccess("Rule added")
        } catch {
            GlobalToastManager.shared.showError("Add rule: \(error.localizedDescription)")
        }
    }

    func removeCustomRule(id: String) async {
        do {
            try await cerberus.removeRule(id: id, on: serverId)
            await loadCustomRules()
            GlobalToastManager.shared.showSuccess("Rule removed")
        } catch {
            GlobalToastManager.shared.showError("Remove rule: \(error.localizedDescription)")
        }
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
