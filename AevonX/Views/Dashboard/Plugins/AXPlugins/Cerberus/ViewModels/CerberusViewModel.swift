//
//  CerberusViewModel.swift
//  AevonX
//
//  ViewModel for AXCerberus WAF management UI.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
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
    case visitorLog = "Visitor Log"
    case settings = "Settings"

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
        case .visitorLog: return "list.bullet.rectangle.portrait"
        case .settings:   return "gearshape.2.fill"
        }
    }

    var label: String {
        switch self {
        case .dashboard:    return L10n.Cerberus.Tab.dashboard
        case .attacks:      return L10n.Cerberus.Tab.attacks
        case .traffic:      return L10n.Cerberus.Tab.traffic
        case .domains:      return L10n.Cerberus.Tab.domains
        case .ipManagement: return L10n.Cerberus.Tab.ipGuard
        case .modules:      return L10n.Cerberus.Tab.modules
        case .honeypot:     return L10n.Cerberus.Tab.honeypot
        case .alerts:       return L10n.Cerberus.Tab.alerts
        case .threatFeed:   return L10n.Cerberus.Tab.threatIntel
        case .compliance:   return L10n.Cerberus.Tab.compliance
        case .sessions:     return L10n.Cerberus.Tab.sessions
        case .customRules:  return L10n.Cerberus.Tab.rules
        case .visitorLog:   return L10n.Cerberus.Tab.visitorLog
        case .settings:     return L10n.Cerberus.Tab.settings
        }
    }

    var color: Color {
        switch self {
        case .dashboard:    return .axAccentBlue
        case .attacks:      return .axError
        case .traffic:      return .axAccentGreen
        case .domains:      return .mint
        case .ipManagement: return .axAccentBlue
        case .modules:      return .indigo
        case .honeypot:     return .axWarning
        case .alerts:       return .axError
        case .threatFeed:   return .axWarning
        case .compliance:   return .axAccentGreen
        case .sessions:     return .cyan
        case .customRules:  return .axAccentBlue
        case .visitorLog:   return .axAccentBlue
        case .settings:     return .axTextSecondary
        }
    }

}

// MARK: - ViewModel

@MainActor
class CerberusViewModel: ObservableObject {

    // MARK: - Navigation

    @Published var selectedTab: CerberusTab = .dashboard

    // MARK: - Loading State

    @Published var dashboardLoading = false
    @Published var attacksLoading = false
    @Published var trafficLoading = false
    @Published var ipLoading = false
    @Published var honeypotLoading = false
    @Published var domainsLoading = false
    @Published var alertsLoading = false
    @Published var visitorLogLoading = false
    @Published var errorMessage: String?
    @Published var configLoadFailed = false
    @Published var moduleConfig: [String: Any]?
    @Published var lastRefreshed: Date?

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

    // MARK: - Domain Detail

    @Published var selectedDomainTimeline: [TimelineEntry] = []
    @Published var selectedDomainCountries: [CountryStats] = []
    @Published var selectedDomainAccessLog: [WAFAccessLogEntry] = []
    @Published var selectedDomainBlockLog: [WAFBlockLogEntry] = []
    @Published var selectedDomainBlockedIPs: [String] = []
    @Published var selectedDomainBlockedCountries: [String] = []
    @Published var domainDetailLoading = false

    // MARK: - QPS

    @Published var currentQPS: Double?

    // MARK: - Extended Stats

    @Published var responseTimes: WAFResponseTimes?
    @Published var statusCodes: [WAFStatusCode] = []
    @Published var botDetails: WAFBotDetails?
    @Published var recentAlerts: [WAFAlertEvent] = []
    @Published var accessLog: [WAFAccessLogEntry] = []
    @Published var accessLogTotal: Int = 0
    @Published var blockLog: [WAFBlockLogEntry] = []
    @Published var blockLogTotal: Int = 0

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

    // MARK: - Time Series & Domain Countries

    @Published var timeSeries: [WAFTimeSeriesBucket] = []
    @Published var timeSeriesLoading = false
    @Published var domainCountries: [CountryStats] = []
    @Published var selectedTimeRange: WAFTimeRange = .hour24

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
    @Published var threatFeedEnabled = true
    @Published var apiSecEnabled = false
    @Published var securityHeadersEnabled = true
    @Published var challengeEnabled = true
    @Published var vpatchEnabled = false
    @Published var anomalyEnabled = false
    @Published var sessionEnabled = false
    @Published var customRulesEnabled = false
    @Published var statsAPIEnabled = true

    var enabledModuleCount: Int {
        [wafEnabled, rateLimitEnabled, ddosEnabled, botDetectionEnabled,
         honeypotEnabled, credentialEnabled, dlpEnabled, ssrfEnabled, alertsEnabled,
         threatFeedEnabled, apiSecEnabled, securityHeadersEnabled, challengeEnabled,
         vpatchEnabled, anomalyEnabled, sessionEnabled, customRulesEnabled, statsAPIEnabled]
            .filter { $0 }.count
    }

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
    @Published var honeypotPaths = "/wp-admin,/.env,/phpmyadmin,/wp-login.php,/xmlrpc.php,/.git/config,/actuator"
    @Published var honeypotAutoBlock = true

    // Alerts config
    @Published var alertWebhookURL = ""
    @Published var alertMaxPerHour: Double = 10
    @Published var alertSeverity = "high"

    // MARK: - Config

    let serverId: String
    private let cerberus = CerberusManager.shared
    private var refreshTask: Task<Void, Never>?
    private static let refreshDebounce: TimeInterval = 5

    init(serverId: String) {
        self.serverId = serverId
    }

    // MARK: - SSH Retry Helper

    /// Retries an async throwing closure once after a 2s delay if the error is SSH-related.
    private func withSSHRetry<T>(_ work: @escaping () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            let msg = error.localizedDescription
            guard msg.contains("ssh not connected") || msg.contains("ssh failed") else { throw error }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return try await work()
        }
    }

    // MARK: - Auto-Refresh

    func startAutoRefresh(interval: TimeInterval = 30) {
        stopAutoRefresh()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled, let self else { return }
                await self.refreshActiveTab()
            }
        }
    }

    private func refreshActiveTab() async {
        switch selectedTab {
        case .dashboard:
            await loadDashboard()
        case .attacks:
            await loadAttacks()
        case .traffic:
            // Independent requests — fetch them together.
            async let analytics: () = loadTrafficAnalytics()
            async let accessLog: () = loadAccessLog()
            _ = await (analytics, accessLog)
        case .visitorLog:
            await loadAccessLog()
        case .domains:
            await loadDomains()
        case .ipManagement:
            await loadIPLists()
        case .modules:
            await loadModuleConfig()
        case .honeypot:
            await loadHoneypot()
        case .alerts:
            await loadAlerts()
        case .threatFeed:
            await loadThreatFeedStatus()
        case .compliance:
            await loadComplianceReport()
        case .sessions:
            await loadSessionStatus()
        case .customRules:
            await loadCustomRules()
        case .settings:
            await loadConfigBackups()
            await loadVPatches()
        }
        lastRefreshed = Date()
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Debounced manual refresh — ignores calls within `refreshDebounce` of last load.
    func refreshIfNeeded() async {
        if let last = lastRefreshed,
           Date().timeIntervalSince(last) < Self.refreshDebounce {
            return
        }
        await loadDashboard()
    }

    // MARK: - Load All Dashboard Data

    func loadDashboard() async {
        dashboardLoading = true
        errorMessage = nil

        do {
            let bundle = try await withSSHRetry {
                try await self.cerberus.getDashboardBundle(on: self.serverId)
            }
            if let v = bundle.overview { overview = v }
            if let v = bundle.timeline { timeline = v }
            if let v = bundle.ddosStatus { ddosStatus = v }
            if let v = bundle.serviceStatus { serviceStatus = v }
            if let v = bundle.credentialStatus { credentialStatus = v }
            if let v = bundle.countries { countries = v }
            if let v = bundle.blockLog { blockLog = v }
            if let t = bundle.blockLogTotal { blockLogTotal = t }
            if let q = bundle.qps { currentQPS = q }
            if let a = bundle.anomalyStatus { anomalyStatus = a }
        } catch {
            errorMessage = error.localizedDescription
        }

        lastRefreshed = Date()
        dashboardLoading = false
    }

    // MARK: - Load Attacks Data

    func loadAttacks() async {
        attacksLoading = true
        errorMessage = nil

        async let at: Result<[AttackTypeStats], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getAttackTypes(on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let ta: Result<[AttackerInfo], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getTopAttackers(on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let tu: Result<[URIStats], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getTopURIs(on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let co: Result<[CountryStats], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getCountries(on: self.serverId) }) }
            catch { return .failure(error) }
        }()

        let (rat, rta, rtu, rco) = await (at, ta, tu, co)

        if case .success(let v) = rat { attackTypes = v }
        if case .success(let v) = rta { topAttackers = v }
        if case .success(let v) = rtu { topURIs = v }
        if case .success(let v) = rco { countries = v }

        if case .failure(let err) = rat { errorMessage = err.localizedDescription }
        else if case .failure(let err) = rta { errorMessage = err.localizedDescription }
        else if case .failure(let err) = rtu { errorMessage = err.localizedDescription }
        else if case .failure(let err) = rco { errorMessage = err.localizedDescription }

        attacksLoading = false
    }

    // MARK: - Load IP Lists

    func loadIPLists() async {
        ipLoading = true
        errorMessage = nil

        async let bl: Result<[String], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.listBlockedIPs(on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let al: Result<[String], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.listAllowedIPs(on: self.serverId) }) }
            catch { return .failure(error) }
        }()

        let (rbl, ral) = await (bl, al)

        if case .success(let v) = rbl { blockedIPs = v }
        if case .success(let v) = ral { allowedIPs = v }

        if case .failure(let err) = rbl { errorMessage = err.localizedDescription }
        else if case .failure(let err) = ral { errorMessage = err.localizedDescription }

        ipLoading = false
    }

    // MARK: - IP Operations

    func blockIP(_ ip: String) async {
        ipOperationInProgress = true
        do {
            try await cerberus.blockIP(ip, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.blocked(ip))
            await loadIPLists()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.failedToBlock(ip, error.localizedDescription))
        }
        ipOperationInProgress = false
    }

    func unblockIP(_ ip: String) async {
        ipOperationInProgress = true
        do {
            try await cerberus.unblockIP(ip, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.unblocked(ip))
            await loadIPLists()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.failedToUnblock(ip, error.localizedDescription))
        }
        ipOperationInProgress = false
    }

    func allowIP(_ ip: String) async {
        ipOperationInProgress = true
        do {
            try await cerberus.allowIP(ip, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.allowed(ip))
            await loadIPLists()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.failedToAllow(ip, error.localizedDescription))
        }
        ipOperationInProgress = false
    }

    func removeAllowedIP(_ ip: String) async {
        ipOperationInProgress = true
        do {
            try await cerberus.removeAllowedIP(ip, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.removedFromAllowlist(ip))
            await loadIPLists()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.failedToRemove(ip, error.localizedDescription))
        }
        ipOperationInProgress = false
    }

    func bulkBlockIPs(_ ips: [String]) async {
        ipOperationInProgress = true
        var failed: [String] = []
        for ip in ips {
            do { try await cerberus.blockIP(ip, on: serverId) }
            catch { failed.append(ip) }
        }
        if failed.isEmpty {
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.blocked("\(ips.count) IPs"))
        } else {
            GlobalToastManager.shared.showWarning(L10n.Cerberus.Toast.failedToBlock("\(failed.count)/\(ips.count)", "partial failure"))
        }
        await loadIPLists()
        ipOperationInProgress = false
    }

    func bulkAllowIPs(_ ips: [String]) async {
        ipOperationInProgress = true
        var failed: [String] = []
        for ip in ips {
            do { try await cerberus.allowIP(ip, on: serverId) }
            catch { failed.append(ip) }
        }
        if failed.isEmpty {
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.allowed("\(ips.count) IPs"))
        } else {
            GlobalToastManager.shared.showWarning(L10n.Cerberus.Toast.failedToAllow("\(failed.count)/\(ips.count)", "partial failure"))
        }
        await loadIPLists()
        ipOperationInProgress = false
    }

    // MARK: - GeoIP Operations

    func loadGeoIP() async {
        do {
            blockedCountries = try await withSSHRetry { try await self.cerberus.listBlockedCountries(on: self.serverId) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func blockCountry(_ code: String) async {
        geoIPOperationInProgress = true
        do {
            try await cerberus.blockCountry(code, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.blocked(code))
            await loadGeoIP()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.failedToBlock(code, error.localizedDescription))
        }
        geoIPOperationInProgress = false
    }

    func unblockCountry(_ code: String) async {
        geoIPOperationInProgress = true
        do {
            try await cerberus.unblockCountry(code, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.unblocked(code))
            await loadGeoIP()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.failedToUnblock(code, error.localizedDescription))
        }
        geoIPOperationInProgress = false
    }

    // MARK: - Load Honeypot

    func loadHoneypot() async {
        honeypotLoading = true
        do {
            honeypotHits = try await withSSHRetry { try await self.cerberus.getHoneypotHits(on: self.serverId) }
        } catch {
            errorMessage = error.localizedDescription
        }
        honeypotLoading = false
    }

    // MARK: - Load Domain Stats

    func loadDomainStats() async {
        do {
            domainStats = try await withSSHRetry { try await self.cerberus.getDomainStats(on: self.serverId) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Domain Management

    func loadDomains() async {
        domainsLoading = true

        async let d: Result<[WAFDomainInfo], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.listDomains(on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let w: Result<WAFWebServerInfo, Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.detectWebServer(on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let ds: Result<[String: DomainStats], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getDomainStats(on: self.serverId) }) }
            catch { return .failure(error) }
        }()

        let (rd, rw, rds) = await (d, w, ds)

        if case .success(let v) = rd { domains = v }
        if case .success(let v) = rw { webServerInfo = v }
        if case .success(let v) = rds { domainStats = v }

        if case .failure(let err) = rd { errorMessage = err.localizedDescription }
        else if case .failure(let err) = rw { errorMessage = err.localizedDescription }

        domainsLoading = false
    }

    func addDomain(_ domain: String) async {
        domainOperationInProgress = true
        do {
            try await cerberus.addDomain(domain, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.domainAdded(domain))
            await loadDomains()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.domainAddFailed(domain, error.localizedDescription))
        }
        domainOperationInProgress = false
    }

    func removeDomain(_ domain: String) async {
        domainOperationInProgress = true
        do {
            try await cerberus.removeDomain(domain, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.domainRemoved(domain))
            await loadDomains()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.domainRemoveFailed(domain, error.localizedDescription))
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
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.failed(error.localizedDescription))
        }
        domainOperationInProgress = false
    }

    func syncDomains() async {
        domainOperationInProgress = true
        do {
            let result = try await cerberus.syncDomains(on: serverId)
            if result.synced > 0 {
                GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.syncedDomains(result.synced))
            } else {
                GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.allDomainsUpToDate)
            }
            await loadDomains()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.syncFailed(error.localizedDescription))
        }
        domainOperationInProgress = false
    }

    // MARK: - Domain Detail

    func loadDomainDetail(domain: String) async {
        domainDetailLoading = true

        async let tl: Result<WAFDomainTimeline, Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getDomainTimeline(domain: domain, on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let co: Result<WAFDomainCountries, Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getDomainCountries(domain: domain, on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let al: Result<WAFAccessLogResponse, Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getDomainAccessLog(domain: domain, on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let bl: Result<WAFBlockLogResponse, Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getDomainBlockLog(domain: domain, on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let ips: Result<WAFDomainRulesIP, Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getDomainBlockedIPs(domain: domain, on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let ctrs: Result<WAFDomainRulesCountry, Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getDomainBlockedCountries(domain: domain, on: self.serverId) }) }
            catch { return .failure(error) }
        }()

        let (rtl, rco, ral, rbl, rips, rctrs) = await (tl, co, al, bl, ips, ctrs)

        if case .success(let v) = rtl { selectedDomainTimeline = v.timeline }
        if case .success(let v) = rco { selectedDomainCountries = v.countries }
        if case .success(let v) = ral { selectedDomainAccessLog = v.entries }
        if case .success(let v) = rbl { selectedDomainBlockLog = v.entries }
        if case .success(let v) = rips { selectedDomainBlockedIPs = v.blockedIPs }
        if case .success(let v) = rctrs { selectedDomainBlockedCountries = v.blockedCountries }

        domainDetailLoading = false
    }

    func domainBlockIP(_ ip: String, domain: String) async {
        domainOperationInProgress = true
        do {
            try await cerberus.domainBlockIP(ip, domain: domain, on: serverId)
            GlobalToastManager.shared.showSuccess("IP \(ip) blocked on \(domain)")
            selectedDomainBlockedIPs.append(ip)
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        domainOperationInProgress = false
    }

    func domainUnblockIP(_ ip: String, domain: String) async {
        domainOperationInProgress = true
        do {
            try await cerberus.domainUnblockIP(ip, domain: domain, on: serverId)
            GlobalToastManager.shared.showSuccess("IP \(ip) unblocked on \(domain)")
            selectedDomainBlockedIPs.removeAll { $0 == ip }
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        domainOperationInProgress = false
    }

    func domainBlockCountry(_ code: String, domain: String) async {
        domainOperationInProgress = true
        do {
            try await cerberus.domainBlockCountry(code, domain: domain, on: serverId)
            GlobalToastManager.shared.showSuccess("Country \(code) blocked on \(domain)")
            selectedDomainBlockedCountries.append(code)
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        domainOperationInProgress = false
    }

    func domainUnblockCountry(_ code: String, domain: String) async {
        domainOperationInProgress = true
        do {
            try await cerberus.domainUnblockCountry(code, domain: domain, on: serverId)
            GlobalToastManager.shared.showSuccess("Country \(code) unblocked on \(domain)")
            selectedDomainBlockedCountries.removeAll { $0 == code }
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        domainOperationInProgress = false
    }

    // MARK: - Load Extended Stats

    func loadTrafficAnalytics() async {
        trafficLoading = true

        async let ds: Result<[String: DomainStats], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getDomainStats(on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let rt: Result<WAFResponseTimes, Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getResponseTimes(on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let sc: Result<[WAFStatusCode], Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getStatusCodes(on: self.serverId) }) }
            catch { return .failure(error) }
        }()
        async let bd: Result<WAFBotDetails, Error> = {
            do { return .success(try await self.withSSHRetry { try await self.cerberus.getBotDetails(on: self.serverId) }) }
            catch { return .failure(error) }
        }()

        let (rds, rrt, rsc, rbd) = await (ds, rt, sc, bd)

        if case .success(let v) = rds { domainStats = v }
        if case .success(let v) = rrt { responseTimes = v }
        if case .success(let v) = rsc { statusCodes = v }
        if case .success(let v) = rbd { botDetails = v }

        if case .failure(let err) = rds {
            errorMessage = err.localizedDescription
        }

        trafficLoading = false
    }

    func loadAlerts() async {
        alertsLoading = true
        do {
            recentAlerts = try await withSSHRetry { try await self.cerberus.getRecentAlerts(on: self.serverId) }
        } catch {
            errorMessage = error.localizedDescription
        }
        alertsLoading = false
    }

    func loadAccessLog() async {
        visitorLogLoading = true
        do {
            let response = try await withSSHRetry { try await self.cerberus.getAccessLog(on: self.serverId) }
            accessLog = response.entries
            accessLogTotal = response.total
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Access log", error.localizedDescription))
        }
        visitorLogLoading = false
    }

    func loadBlockLog() async {
        do {
            let response = try await withSSHRetry { try await self.cerberus.getBlockLog(on: self.serverId) }
            blockLog = response.entries
            blockLogTotal = response.total
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
            let cfg = try await withSSHRetry { try await self.cerberus.getFullConfig(on: self.serverId) }
            configLoadFailed = false
            applyConfig(cfg)
        } catch {
            configLoadFailed = true
            errorMessage = L10n.Cerberus.Toast.configLoadFailed
        }
    }

    private func applyConfig(_ cfg: [String: Any]) {
        moduleConfig = cfg
        wafEnabled          = cfg.bool("waf_enabled", default: true)
        rateLimitEnabled    = cfg.bool("rate_limit_enabled", default: true)
        ddosEnabled         = cfg.bool("ddos_enabled", default: true)
        botDetectionEnabled = cfg.bool("bot_detection_enabled", default: true)
        honeypotEnabled     = cfg.bool("honeypot_enabled", default: false)
        credentialEnabled   = cfg.bool("credential_protection_enabled", default: true)
        dlpEnabled          = cfg.bool("dlp_enabled", default: true)
        ssrfEnabled         = cfg.bool("ssrf_enabled", default: true)
        alertsEnabled       = cfg.bool("alerts_enabled", default: false)
        threatFeedEnabled   = cfg.bool("threat_feed_enabled", default: true)
        apiSecEnabled       = cfg.bool("api_sec_enabled", default: false)
        securityHeadersEnabled = cfg.bool("security_headers_enabled", default: true)
        challengeEnabled    = cfg.bool("challenge_enabled", default: true)
        vpatchEnabled       = cfg.bool("vpatch_enabled", default: false)
        anomalyEnabled      = cfg.bool("anomaly_enabled", default: false)
        sessionEnabled      = cfg.bool("session_enabled", default: false)
        customRulesEnabled  = cfg.bool("custom_rules_enabled", default: false)
        statsAPIEnabled     = cfg.bool("stats_api_enabled", default: true)

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

        honeypotPaths       = cfg.string("honeypot_paths", default: "/wp-admin,/.env,/phpmyadmin,/wp-login.php,/xmlrpc.php,/.git/config,/actuator")
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
            GlobalToastManager.shared.showSuccess(enabled ? L10n.Cerberus.Toast.moduleEnabled : L10n.Cerberus.Toast.moduleDisabled)
            await loadModuleConfig()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.failed(error.localizedDescription))
            await loadModuleConfig()
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
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.wafStarted)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.startFailed(error.localizedDescription))
        }
        serviceOperationInProgress = false
    }

    func stopService() async {
        guard !serviceOperationInProgress else { return }
        serviceOperationInProgress = true
        do {
            _ = try await cerberus.serviceStop(on: serverId)
            serviceStatus = try? await cerberus.getServiceStatus(on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.wafStopped)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.stopFailed(error.localizedDescription))
        }
        serviceOperationInProgress = false
    }

    func restartService() async {
        guard !serviceOperationInProgress else { return }
        serviceOperationInProgress = true
        do {
            _ = try await cerberus.serviceRestart(on: serverId)
            serviceStatus = try? await cerberus.getServiceStatus(on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.wafRestarted)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.restartFailed(error.localizedDescription))
        }
        serviceOperationInProgress = false
    }

    func reloadService() async {
        guard !serviceOperationInProgress else { return }
        serviceOperationInProgress = true
        do {
            _ = try await cerberus.serviceReload(on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.wafReloaded)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.reloadFailed(error.localizedDescription))
        }
        serviceOperationInProgress = false
    }

    private func batchConfigSet(_ pairs: [(String, String)], label: String) async {
        configOperationInProgress = true

        // Create a backup before applying changes
        do {
            _ = try await cerberus.configBackup(on: serverId)
        } catch {
            // Backup failure is non-fatal — continue
        }

        // Try native batch API first, fall back to sequential
        let updates = Dictionary(pairs, uniquingKeysWith: { _, last in last })
        do {
            let result = try await cerberus.configSetBatch(updates, on: serverId)
            if result.failed == 0 {
                GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.configSaved(label))
            } else if result.succeeded == 0 {
                GlobalToastManager.shared.showError(L10n.Cerberus.Toast.configSaveFailed(label))
            } else {
                GlobalToastManager.shared.showWarning(L10n.Cerberus.Toast.configPartialFail(label, result.failed))
            }
        } catch {
            // Fallback: sequential config set
            var failedKeys: [String] = []
            for (key, value) in pairs {
                do {
                    try await cerberus.configSet(key: key, value: value, on: serverId)
                } catch {
                    failedKeys.append(key)
                }
            }
            if failedKeys.count == pairs.count {
                GlobalToastManager.shared.showError(L10n.Cerberus.Toast.configSaveFailed(label))
            } else if !failedKeys.isEmpty {
                GlobalToastManager.shared.showWarning(L10n.Cerberus.Toast.configPartialFail(label, failedKeys.count))
            } else {
                GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.configSaved(label))
            }
        }

        // Reload config to reflect actual backend state
        await loadModuleConfig()
        configOperationInProgress = false
    }

    // MARK: - Threat Feed

    func loadThreatFeedStatus() async {
        threatFeedLoading = true
        do {
            threatFeedStatus = try await withSSHRetry { try await self.cerberus.getThreatFeedStatus(on: self.serverId) }
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Threat feed", error.localizedDescription))
        }
        threatFeedLoading = false
    }

    func updateThreatFeed() async {

        threatFeedLoading = true
        do {
            threatFeedStatus = try await cerberus.updateThreatFeed(on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.threatFeedsUpdated)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Threat feed update", error.localizedDescription))
        }
        threatFeedLoading = false
    }

    // MARK: - Compliance

    func loadComplianceReport() async {
        complianceLoading = true
        do {
            complianceReport = try await withSSHRetry { try await self.cerberus.getComplianceReport(on: self.serverId) }
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Compliance", error.localizedDescription))
        }
        complianceLoading = false
    }

    // MARK: - Virtual Patching

    func loadVPatches() async {
        do {
            vPatches = try await withSSHRetry { try await self.cerberus.listVPatches(on: self.serverId) }
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("VPatches", error.localizedDescription))
        }
    }

    func removeVPatch(_ id: String) async {

        do {
            try await cerberus.removeVPatch(id, on: serverId)
            await loadVPatches()
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.virtualPatchRemoved)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Remove vpatch", error.localizedDescription))
        }
    }

    // MARK: - Config Backups

    func loadConfigBackups() async {
        do {
            configBackups = try await withSSHRetry { try await self.cerberus.listConfigBackups(on: self.serverId) }
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Backups", error.localizedDescription))
        }
    }

    func createConfigBackup() async {

        do {
            _ = try await cerberus.configBackup(on: serverId)
            await loadConfigBackups()
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.configBackupCreated)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Backup", error.localizedDescription))
        }
    }

    // MARK: - Anomaly Detection

    func loadAnomalyStatus() async {
        anomalyLoading = true
        do {
            anomalyStatus = try await withSSHRetry { try await self.cerberus.getAnomalyStatus(on: self.serverId) }
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Anomaly", error.localizedDescription))
        }
        anomalyLoading = false
    }

    // MARK: - Session Tracking

    func loadSessionStatus() async {
        sessionLoading = true
        do {
            sessionStatus = try await withSSHRetry { try await self.cerberus.getSessionStatus(on: self.serverId) }
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Session", error.localizedDescription))
        }
        sessionLoading = false
    }

    // MARK: - Custom Rules

    func loadCustomRules() async {
        rulesLoading = true
        do {
            let response = try await withSSHRetry { try await self.cerberus.listRules(on: self.serverId) }
            customRules = response.rules
            customRulesEnabled = response.enabled
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Rules", error.localizedDescription))
        }
        rulesLoading = false
    }

    func addCustomRule(id: String, expression: String) async {
        do {
            try await cerberus.addRule(id: id, expression: expression, on: serverId)
            await loadCustomRules()
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.ruleAdded)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Add rule", error.localizedDescription))
        }
    }

    func removeCustomRule(id: String) async {
        do {
            try await cerberus.removeRule(id: id, on: serverId)
            await loadCustomRules()
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.ruleRemoved)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Remove rule", error.localizedDescription))
        }
    }

    // MARK: - QPS

    func loadQPS() async {
        do {
            currentQPS = try await withSSHRetry { try await self.cerberus.getQPS(on: self.serverId) }
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("QPS", error.localizedDescription))
        }
    }

    // MARK: - Virtual Patch Apply

    func applyVirtualPatch(patchJSON: String) async {
        do {
            try await cerberus.applyVPatch(patchJSON, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.virtualPatchApplied)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("VPatch", error.localizedDescription))
        }
    }

    // MARK: - Log Export

    func exportLogData(logType: String) async {
        do {
            let result = try await cerberus.exportLogs(logType, on: serverId)
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "cerberus-\(logType)-export.json"
            panel.allowedContentTypes = [.json]
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.logsExported)
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Export", error.localizedDescription))
        }
    }

    // MARK: - Config Restore

    func restoreConfigBackup(name: String) async {
        do {
            try await cerberus.configRestore(name, on: serverId)
            GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.configRestored)
            await loadModuleConfig()
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Restore", error.localizedDescription))
        }
    }

    // MARK: - Per-Domain Countries

    func loadDomainCountries(domain: String) async {
        do {
            let result = try await cerberus.getDomainCountries(domain: domain, on: serverId)
            domainCountries = result.countries
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("Countries", error.localizedDescription))
        }
    }

    // MARK: - Extended Time Series

    func loadTimeSeries(start: String, end: String, granularity: String) async {
        timeSeriesLoading = true
        do {
            let result = try await cerberus.getTimeSeries(start: start, end: end, granularity: granularity, on: serverId)
            timeSeries = result.buckets
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix("TimeSeries", error.localizedDescription))
        }
        timeSeriesLoading = false
    }

    /// Convenience wrapper: computes ISO8601 start/end from a WAFTimeRange and loads time series data.
    func loadTimeSeries(range: WAFTimeRange) async {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        let start = fmt.string(from: range.startDate())
        let end   = fmt.string(from: Date())
        await loadTimeSeries(start: start, end: end, granularity: range.granularity)
    }

    // MARK: - Config Batch Update

    func configSetBatchNative(_ updates: [String: String], label: String) async {
        configOperationInProgress = true
        do {
            let result = try await cerberus.configSetBatch(updates, on: serverId)
            if result.failed == 0 {
                GlobalToastManager.shared.showSuccess(L10n.Cerberus.Toast.configSaved(label))
            } else if result.succeeded == 0 {
                GlobalToastManager.shared.showError(L10n.Cerberus.Toast.configSaveFailed(label))
            } else {
                GlobalToastManager.shared.showWarning(L10n.Cerberus.Toast.configPartialFail(label, result.failed))
            }
        } catch {
            GlobalToastManager.shared.showError(L10n.Cerberus.Toast.errorPrefix(label, error.localizedDescription))
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
