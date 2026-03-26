import Foundation

extension L10n {

    // MARK: - Cerberus WAF (Cerberus.strings)
    enum Cerberus {
        private static let table = "Cerberus"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        // MARK: Tabs
        enum Tab {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let dashboard    = s("cerberus.tab.dashboard", "Dashboard")
            static let attacks      = s("cerberus.tab.attacks", "Attacks")
            static let traffic      = s("cerberus.tab.traffic", "Traffic")
            static let domains      = s("cerberus.tab.domains", "Domains")
            static let ipGuard      = s("cerberus.tab.ipGuard", "IP Guard")
            static let modules      = s("cerberus.tab.modules", "Modules")
            static let honeypot     = s("cerberus.tab.honeypot", "Honeypot")
            static let alerts       = s("cerberus.tab.alerts", "Alerts")
            static let threatIntel  = s("cerberus.tab.threatIntel", "Threat Intel")
            static let compliance   = s("cerberus.tab.compliance", "Compliance")
            static let sessions     = s("cerberus.tab.sessions", "Sessions")
            static let rules        = s("cerberus.tab.rules", "Rules")
        }

        // MARK: Root / Header
        enum Root {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let brand            = s("cerberus.root.brand", "AXCerberus")
            static let waf              = s("cerberus.root.waf", "WAF")
            static let subtitle         = s("cerberus.root.subtitle", "Layer 7 Web Application Firewall")
            static let requests         = s("cerberus.root.requests", "Requests")
            static let blockRate        = s("cerberus.root.blockRate", "Block Rate")
            static let qps              = s("cerberus.root.qps", "QPS")
            static let stopWAF          = s("cerberus.root.stopWAF", "Stop WAF")
            static let restartWAF       = s("cerberus.root.restartWAF", "Restart WAF")
            static let startWAF         = s("cerberus.root.startWAF", "Start WAF")
            static let sidebarTitle     = s("cerberus.root.sidebarTitle", "CERBERUS")
            static let catOverview      = s("cerberus.root.catOverview", "Overview")
            static let catSecurity      = s("cerberus.root.catSecurity", "Security")
            static let catIntelligence  = s("cerberus.root.catIntelligence", "Intelligence")
            static let catManagement    = s("cerberus.root.catManagement", "Management")

            static func modulesCount(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) modules"
                return String(localized: "cerberus.root.modulesCount", defaultValue: dv, table: table)
            }
        }

        // MARK: Dashboard
        enum Dashboard {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let heroSubtitle     = s("cerberus.dashboard.heroSubtitle", "AXCerberus · Layer 7 WAF")
            static let underAttack      = s("cerberus.dashboard.underAttack", "UNDER ATTACK")
            static let blocked          = s("cerberus.dashboard.blocked", "blocked")
            static let protectionRate   = s("cerberus.dashboard.protectionRate", "Protection Rate")
            static let totalRequests    = s("cerberus.dashboard.totalRequests", "Total Requests")
            static let requestsPerSec   = s("cerberus.dashboard.requestsPerSec", "Requests / sec")
            static let uptime           = s("cerberus.dashboard.uptime", "Uptime")
            static let statBlocked      = s("cerberus.dashboard.statBlocked", "Blocked")
            static let statAllowed      = s("cerberus.dashboard.statAllowed", "Allowed")
            static let statQPS          = s("cerberus.dashboard.statQPS", "QPS")
            static let allTraffic       = s("cerberus.dashboard.allTraffic", "all traffic")
            static let passedThrough    = s("cerberus.dashboard.passedThrough", "passed through")
            static let queriesSec       = s("cerberus.dashboard.queriesSec", "queries/sec")
            static let hourTraffic      = s("cerberus.dashboard.24hTraffic", "24-Hour Traffic")
            static let legendAllowed    = s("cerberus.dashboard.legendAllowed", "Allowed")
            static let legendBlocked    = s("cerberus.dashboard.legendBlocked", "Blocked")
            static let noTimelineData   = s("cerberus.dashboard.noTimelineData", "No timeline data")
            static let attackOrigins    = s("cerberus.dashboard.attackOrigins", "Attack Origins")
            static let noData           = s("cerberus.dashboard.noData", "No Data")
            static let noAttackOrigins  = s("cerberus.dashboard.noAttackOrigins", "No attack origins recorded yet.")
            static let bytesIn          = s("cerberus.dashboard.bytesIn", "Bytes In")
            static let bytesOut         = s("cerberus.dashboard.bytesOut", "Bytes Out")
            static let botRequests      = s("cerberus.dashboard.botRequests", "Bot Requests")
            static let inbound          = s("cerberus.dashboard.inbound", "inbound")
            static let outbound         = s("cerberus.dashboard.outbound", "outbound")
            static let continuous       = s("cerberus.dashboard.continuous", "continuous")
            static let ddosShield       = s("cerberus.dashboard.ddosShield", "DDoS Shield")
            static let currentQPS       = s("cerberus.dashboard.currentQPS", "Current QPS")
            static let baselineQPS      = s("cerberus.dashboard.baselineQPS", "Baseline QPS")
            static let spikeRatio       = s("cerberus.dashboard.spikeRatio", "Spike Ratio")
            static let lvl              = s("cerberus.dashboard.lvl", "LVL")
            static let moduleActivity   = s("cerberus.dashboard.moduleActivity", "Module Activity")
            static let today            = s("cerberus.dashboard.today", "today")
            static let honeypotLabel    = s("cerberus.dashboard.honeypot", "Honeypot")
            static let credentialLabel  = s("cerberus.dashboard.credential", "Credential")
            static let dlpLabel         = s("cerberus.dashboard.dlp", "DLP")
            static let alertsLabel      = s("cerberus.dashboard.alerts", "Alerts")
            static let recentBlocks     = s("cerberus.dashboard.recentBlocks", "Recent Blocks")
            static let noRecentBlocks   = s("cerberus.dashboard.noRecentBlocks", "No recent blocks")
            static let protected        = s("cerberus.dashboard.protected", "Protected")
            static let monitoring       = s("cerberus.dashboard.monitoring", "Monitoring")
            static let alert            = s("cerberus.dashboard.alert", "Alert")
            static let underAttackLabel = s("cerberus.dashboard.underAttackLabel", "Under Attack")

            static func levelName(_ level: Int, _ name: String) -> String {
                let dv: String.LocalizationValue = "Level \(level): \(name)"
                return String(localized: "cerberus.dashboard.levelName", defaultValue: dv, table: table)
            }

            static func peakHour(_ hour: Int) -> String {
                let dv: String.LocalizationValue = "Peak: \(hour):00"
                return String(localized: "cerberus.dashboard.peakHour", defaultValue: dv, table: table)
            }

            static func blockedCount(_ count: String) -> String {
                let dv: String.LocalizationValue = "\(count) blocked"
                return String(localized: "cerberus.dashboard.blockedCount", defaultValue: dv, table: table)
            }
        }

        // MARK: Attacks
        enum Attacks {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let overview             = s("cerberus.attacks.overview", "Overview")
            static let blockLog             = s("cerberus.attacks.blockLog", "Block Log")
            static let threatAnalytics      = s("cerberus.attacks.threatAnalytics", "Threat Analytics")
            static let attacks              = s("cerberus.attacks.attacks", "Attacks")
            static let sources              = s("cerberus.attacks.sources", "Sources")
            static let vectors              = s("cerberus.attacks.vectors", "Vectors")
            static let blocks               = s("cerberus.attacks.blocks", "Blocks")
            static let attackVectors        = s("cerberus.attacks.attackVectors", "Attack Vectors")
            static let noAttackData         = s("cerberus.attacks.noAttackData", "No attack data available")
            static let distribution         = s("cerberus.attacks.distribution", "Distribution")
            static let noDistData           = s("cerberus.attacks.noDistData", "No data")
            static let topAttackers         = s("cerberus.attacks.topAttackers", "Top Attackers")
            static let noAttackers          = s("cerberus.attacks.noAttackers", "No attackers detected")
            static let targetedURIs         = s("cerberus.attacks.targetedURIs", "Targeted URIs")
            static let noURIData            = s("cerberus.attacks.noURIData", "No URI data")
            static let attackOrigins        = s("cerberus.attacks.attackOrigins", "Attack Origins")
            static let noCountryData        = s("cerberus.attacks.noCountryData", "No country data")
            static let filterPlaceholder    = s("cerberus.attacks.filterPlaceholder", "Filter by IP, rule, path...")
            static let totalBlocks          = s("cerberus.attacks.totalBlocks", "Total Blocks")
            static let critical             = s("cerberus.attacks.critical", "Critical")
            static let high                 = s("cerberus.attacks.high", "High")
            static let uniqueIPs            = s("cerberus.attacks.uniqueIPs", "Unique IPs")
            static let noBlockLog           = s("cerberus.attacks.noBlockLog", "No block log entries")
            static let colTime              = s("cerberus.attacks.colTime", "Time")
            static let colIP                = s("cerberus.attacks.colIP", "IP")
            static let colCountry           = s("cerberus.attacks.colCountry", "Country")
            static let colMethod            = s("cerberus.attacks.colMethod", "Method")
            static let colRule              = s("cerberus.attacks.colRule", "Rule")
            static let colSeverity          = s("cerberus.attacks.colSeverity", "Severity")
            static let ipAddress            = s("cerberus.attacks.ipAddress", "IP Address")
            static let totalAttacks         = s("cerberus.attacks.totalAttacks", "Total Attacks")
            static let lastSeen             = s("cerberus.attacks.lastSeen", "Last Seen")
            static let country              = s("cerberus.attacks.country", "Country")
            static let countryCode          = s("cerberus.attacks.countryCode", "Country Code")
            static let blockIP              = s("cerberus.attacks.blockIP", "Block IP")

            static func vectorsDetected(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) vectors detected"
                return String(localized: "cerberus.attacks.vectorsDetected", defaultValue: dv, table: table)
            }
        }

        // MARK: Traffic
        enum Traffic {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let analytics            = s("cerberus.traffic.analytics", "Analytics")
            static let accessLog            = s("cerberus.traffic.accessLog", "Access Log")
            static let domains              = s("cerberus.traffic.domains", "Domains")
            static let requests             = s("cerberus.traffic.requests", "Requests")
            static let p95Latency           = s("cerberus.traffic.p95Latency", "P95 Latency")
            static let botTraffic           = s("cerberus.traffic.botTraffic", "Bot Traffic")
            static let responseLatency      = s("cerberus.traffic.responseLatency", "Response Latency")
            static let noLatencyData        = s("cerberus.traffic.noLatencyData", "No latency data")
            static let botAnalysis          = s("cerberus.traffic.botAnalysis", "Bot Analysis")
            static let noClassData          = s("cerberus.traffic.noClassData", "No classification data")
            static let human                = s("cerberus.traffic.human", "Human")
            static let bot                  = s("cerberus.traffic.bot", "Bot")
            static let statusCodes          = s("cerberus.traffic.statusCodes", "Status Codes")
            static let noDomainTraffic      = s("cerberus.traffic.noDomainTraffic", "No domain traffic yet")
            static let domainTrafficTitle   = s("cerberus.traffic.domainTrafficTitle", "Domain Traffic Analysis")
            static let recentRequests       = s("cerberus.traffic.recentRequests", "Recent Requests")
            static let noAccessLog          = s("cerberus.traffic.noAccessLog", "No access log entries")
            static let total                = s("cerberus.traffic.total", "Total")
            static let statBlocked          = s("cerberus.traffic.statBlocked", "Blocked")
            static let blockRate            = s("cerberus.traffic.blockRate", "Block Rate")
            static let bytesIn              = s("cerberus.traffic.bytesIn", "Bytes In")
            static let bytesOut             = s("cerberus.traffic.bytesOut", "Bytes Out")
            static let filterPlaceholder    = s("cerberus.traffic.filterPlaceholder", "Filter by IP, path, host, country...")
            static let uniqueIPs            = s("cerberus.traffic.uniqueIPs", "Unique IPs")
            static let bots                 = s("cerberus.traffic.bots", "Bots")
            static let avgLatency           = s("cerberus.traffic.avgLatency", "Avg Latency")
            static let colTime              = s("cerberus.traffic.colTime", "Time")
            static let colIP                = s("cerberus.traffic.colIP", "IP")
            static let colMethod            = s("cerberus.traffic.colMethod", "Method")
            static let colStatus            = s("cerberus.traffic.colStatus", "Status")
            static let colLatency           = s("cerberus.traffic.colLatency", "Latency")
            static let colBot               = s("cerberus.traffic.colBot", "Bot")
            static let noStatusCodeData     = s("cerberus.traffic.noStatusCodeData", "No status code data")

            static func blockedPct(_ pct: String) -> String {
                let dv: String.LocalizationValue = "\(pct) blocked"
                return String(localized: "cerberus.traffic.blockedPct", defaultValue: dv, table: table)
            }

            static func allowedPct(_ pct: String) -> String {
                let dv: String.LocalizationValue = "\(pct) allowed"
                return String(localized: "cerberus.traffic.allowedPct", defaultValue: dv, table: table)
            }
        }

        // MARK: IP Management
        enum IP {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title                = s("cerberus.ip.title", "IP Guard")
            static let subtitle             = s("cerberus.ip.subtitle", "Manage blocklists, allowlists, and geo-restrictions")
            static let statBlocked          = s("cerberus.ip.statBlocked", "Blocked")
            static let statAllowed          = s("cerberus.ip.statAllowed", "Allowed")
            static let statCountries        = s("cerberus.ip.statCountries", "Countries")
            static let totalRules           = s("cerberus.ip.totalRules", "Total Rules")
            static let searchPlaceholder    = s("cerberus.ip.searchPlaceholder", "Search IPs...")
            static let noBlockedIPs         = s("cerberus.ip.noBlockedIPs", "No blocked IPs")
            static let blockedIPs           = s("cerberus.ip.blockedIPs", "Blocked IPs")
            static let noAllowedIPs         = s("cerberus.ip.noAllowedIPs", "No allowed IPs")
            static let allowedIPs           = s("cerberus.ip.allowedIPs", "Allowed IPs")
            static let geoIPDesc            = s("cerberus.ip.geoIPDesc", "Block all traffic from specific countries via MaxMind GeoLite2.")
            static let noCountriesBlocked   = s("cerberus.ip.noCountriesBlocked", "No countries blocked")
            static let countryBlocking      = s("cerberus.ip.countryBlocking", "Country Blocking (GeoIP)")
            static let blockIPTitle         = s("cerberus.ip.blockIPTitle", "Block IP Address")
            static let allowIPTitle         = s("cerberus.ip.allowIPTitle", "Allow IP Address")
            static let blockIPDesc          = s("cerberus.ip.blockIPDesc", "Add an IP or CIDR range to the blocklist")
            static let allowIPDesc          = s("cerberus.ip.allowIPDesc", "Whitelist a trusted IP or CIDR range")
            static let ipLabel              = s("cerberus.ip.ipLabel", "IP Address / CIDR")
            static let ipPlaceholder        = s("cerberus.ip.ipPlaceholder", "e.g. 203.0.113.42 or 10.0.0.0/24")
            static let ipHint              = s("cerberus.ip.ipHint", "Supports IPv4, IPv6 and CIDR notation")
            static let blockIPBtn           = s("cerberus.ip.blockIPBtn", "Block IP")
            static let allowIPBtn           = s("cerberus.ip.allowIPBtn", "Allow IP")
            static let blockCountryTitle    = s("cerberus.ip.blockCountryTitle", "Block Country")
            static let blockCountryDesc     = s("cerberus.ip.blockCountryDesc", "Block all traffic from a specific country via GeoIP")
            static let countryCodeLabel     = s("cerberus.ip.countryCodeLabel", "Country Code")
            static let countryCodePlaceholder = s("cerberus.ip.countryCodePlaceholder", "e.g. CN, RU, KP")
            static let countryCodeHint      = s("cerberus.ip.countryCodeHint", "ISO 3166-1 alpha-2 code (2 letters)")
            static let blockCountryBtn      = s("cerberus.ip.blockCountryBtn", "Block Country")
        }

        // MARK: Domains
        enum Domains {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title                = s("cerberus.domains.title", "Domain Management")
            static let subtitle             = s("cerberus.domains.subtitle", "Configure and monitor websites protected by AXCerberus WAF")
            static let sync                 = s("cerberus.domains.sync", "Sync")
            static let addDomain            = s("cerberus.domains.addDomain", "Add Domain")
            static let noWebServer          = s("cerberus.domains.noWebServer", "No Web Server Detected")
            static let detectingServer      = s("cerberus.domains.detectingServer", "Detecting web server...")
            static let totalDomains         = s("cerberus.domains.totalDomains", "Total Domains")
            static let protected            = s("cerberus.domains.protected", "Protected")
            static let unprotected          = s("cerberus.domains.unprotected", "Unprotected")
            static let configuredDomains    = s("cerberus.domains.configuredDomains", "Configured Domains")
            static let noDomains            = s("cerberus.domains.noDomains", "No Domains Configured")
            static let noDomainsDesc        = s("cerberus.domains.noDomainsDesc", "Sync to auto-detect domains from your web server or add them manually.")
            static let syncDomains          = s("cerberus.domains.syncDomains", "Sync Domains")
            static let unknownServer        = s("cerberus.domains.unknownServer", "Unknown server")
            static let addDomainTitle       = s("cerberus.domains.addDomainTitle", "Add Domain")
            static let addDomainDesc        = s("cerberus.domains.addDomainDesc", "Enter the fully qualified domain name to protect")
            static let domainName           = s("cerberus.domains.domainName", "Domain Name")
            static let domainPlaceholder    = s("cerberus.domains.domainPlaceholder", "example.com")
            static let domainHint           = s("cerberus.domains.domainHint", "Subdomains like api.example.com are supported")
        }

        // MARK: Alerts
        enum Alerts {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title                = s("cerberus.alerts.title", "Security Alerts")
            static let subtitle             = s("cerberus.alerts.subtitle", "Real-time threat event stream")
            static let critical             = s("cerberus.alerts.critical", "Critical")
            static let high                 = s("cerberus.alerts.high", "High")
            static let other                = s("cerberus.alerts.other", "Other")
            static let totalAlerts          = s("cerberus.alerts.totalAlerts", "Total Alerts")
            static let mediumLow            = s("cerberus.alerts.mediumLow", "Medium / Low")
            static let securityEvents       = s("cerberus.alerts.securityEvents", "Security Events")
            static let allClear             = s("cerberus.alerts.allClear", "All Clear")
            static let noEventsDesc         = s("cerberus.alerts.noEventsDesc", "No security events match your filter. Alerts appear when the WAF detects threats.")
            static let message              = s("cerberus.alerts.message", "Message")
            static let type                 = s("cerberus.alerts.type", "Type")
            static let severity             = s("cerberus.alerts.severity", "Severity")
            static let timestamp            = s("cerberus.alerts.timestamp", "Timestamp")
        }

        // MARK: Modules
        enum Modules {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title                = s("cerberus.modules.title", "Security Control Center")
            static let subtitle             = s("cerberus.modules.subtitle", "Toggle modules live · edit config in real time · changes reload instantly")
            static let enableToConfig       = s("cerberus.modules.enableToConfig", "Enable this module to configure it.")
            // Module names
            static let wafEngine            = s("cerberus.modules.wafEngine", "WAF Engine")
            static let rateLimiter          = s("cerberus.modules.rateLimiter", "Rate Limiter")
            static let ddosShield           = s("cerberus.modules.ddosShield", "DDoS Shield")
            static let botDetector          = s("cerberus.modules.botDetector", "Bot Detector")
            static let honeypot             = s("cerberus.modules.honeypot", "Honeypot")
            static let credentialGuard      = s("cerberus.modules.credentialGuard", "Credential Guard")
            static let dlpScanner           = s("cerberus.modules.dlpScanner", "DLP Scanner")
            static let ssrfDetector         = s("cerberus.modules.ssrfDetector", "SSRF Detector")
            static let alertDispatcher      = s("cerberus.modules.alertDispatcher", "Alert Dispatcher")
            // Module descriptions
            static let wafDesc              = s("cerberus.modules.wafDesc", "Coraza ModSecurity — SQLi, XSS, path traversal")
            static let rateLimiterDesc      = s("cerberus.modules.rateLimiterDesc", "Per-IP sliding-window rate limiting (3 tiers)")
            static let ddosDesc             = s("cerberus.modules.ddosDesc", "EWMA baseline spike detection + auto-mitigation")
            static let botDesc              = s("cerberus.modules.botDesc", "User-Agent classification (human/bot/malicious)")
            static let honeypotDesc         = s("cerberus.modules.honeypotDesc", "Trap endpoints to detect and log attackers")
            static let credDesc             = s("cerberus.modules.credDesc", "Brute force and credential stuffing detection")
            static let dlpDesc              = s("cerberus.modules.dlpDesc", "Scans responses for credit cards, API keys, traces")
            static let ssrfDesc             = s("cerberus.modules.ssrfDesc", "Prevents Server-Side Request Forgery attacks")
            static let alertDesc            = s("cerberus.modules.alertDesc", "Routes security events to webhooks")
            // Config labels
            static let globalLimit          = s("cerberus.modules.globalLimit", "Global Limit")
            static let loginLimit           = s("cerberus.modules.loginLimit", "Login Limit")
            static let apiLimit             = s("cerberus.modules.apiLimit", "API Limit")
            static let throttleMode         = s("cerberus.modules.throttleMode", "Throttle Mode")
            static let throttleDesc         = s("cerberus.modules.throttleDesc", "Delay instead of hard block")
            static let saveRateLimits       = s("cerberus.modules.saveRateLimits", "Save Rate Limits")
            static let spikeMultiplier      = s("cerberus.modules.spikeMultiplier", "Spike Multiplier")
            static let maxConnsPerIP        = s("cerberus.modules.maxConnsPerIP", "Max Conns / IP")
            static let autoMitigate         = s("cerberus.modules.autoMitigate", "Auto Mitigate")
            static let autoMitigateDesc     = s("cerberus.modules.autoMitigateDesc", "Escalate level automatically")
            static let saveDDoSConfig       = s("cerberus.modules.saveDDoSConfig", "Save DDoS Config")
            static let maxAttemptsIP        = s("cerberus.modules.maxAttemptsIP", "Max Attempts / IP")
            static let maxAttemptsUser      = s("cerberus.modules.maxAttemptsUser", "Max Attempts / User")
            static let saveCredConfig       = s("cerberus.modules.saveCredConfig", "Save Credential Config")
            static let actionMode           = s("cerberus.modules.actionMode", "Action Mode")
            static let creditCards          = s("cerberus.modules.creditCards", "Credit Cards")
            static let creditCardsDesc      = s("cerberus.modules.creditCardsDesc", "Luhn-validated detection")
            static let apiKeys              = s("cerberus.modules.apiKeys", "API Keys & Tokens")
            static let apiKeysDesc          = s("cerberus.modules.apiKeysDesc", "Bearer tokens, secret keys")
            static let stackTraces          = s("cerberus.modules.stackTraces", "Stack Traces")
            static let stackTracesDesc      = s("cerberus.modules.stackTracesDesc", "Exception and DB error leaks")
            static let saveDLPConfig        = s("cerberus.modules.saveDLPConfig", "Save DLP Config")
            static let dlpBlocksResponse    = s("cerberus.modules.dlpBlocksResponse", "Blocks response")
            static let dlpRedactsData       = s("cerberus.modules.dlpRedactsData", "Redacts data")
            static let dlpLogsOnly          = s("cerberus.modules.dlpLogsOnly", "Logs only")
            static let trapPaths            = s("cerberus.modules.trapPaths", "Trap Paths")
            static let autoBlockVisitors    = s("cerberus.modules.autoBlockVisitors", "Auto-Block Visitors")
            static let autoBlockDesc        = s("cerberus.modules.autoBlockDesc", "Block IPs that hit trap paths")
            static let saveHoneypotConfig   = s("cerberus.modules.saveHoneypotConfig", "Save Honeypot Config")
            static let webhookURL           = s("cerberus.modules.webhookURL", "Webhook URL")
            static let maxAlertsPerHour     = s("cerberus.modules.maxAlertsPerHour", "Max Alerts / Hour")
            static let minimumSeverity      = s("cerberus.modules.minimumSeverity", "Minimum Severity")
            static let saveAlertConfig      = s("cerberus.modules.saveAlertConfig", "Save Alert Config")
        }

        // MARK: Sessions
        enum Sessions {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title                = s("cerberus.sessions.title", "Session Tracking")
            static let activeMonitoring     = s("cerberus.sessions.activeMonitoring", "Actively monitoring user sessions")
            static let disabled             = s("cerberus.sessions.disabled", "Session tracking is disabled")
            static let activeSessions       = s("cerberus.sessions.activeSessions", "Active Sessions")
            static let totalTracked         = s("cerberus.sessions.totalTracked", "Total Tracked")
            static let atoDetections        = s("cerberus.sessions.atoDetections", "ATO Detections")
            static let rateLimited          = s("cerberus.sessions.rateLimited", "Rate Limited")
            static let sessionSecurity      = s("cerberus.sessions.sessionSecurity", "Session Security")
            static let sessionCookie        = s("cerberus.sessions.sessionCookie", "Session Cookie")
            static let rateLimit            = s("cerberus.sessions.rateLimit", "Rate Limit")
            static let enforced             = s("cerberus.sessions.enforced", "enforced")
            static let atoDetection         = s("cerberus.sessions.atoDetection", "ATO Detection")
            static let noThreats            = s("cerberus.sessions.noThreats", "No threats")
            static let disabledTitle        = s("cerberus.sessions.disabledTitle", "Session Tracking Disabled")
            static let disabledDesc         = s("cerberus.sessions.disabledDesc", "Enable session tracking in your WAF configuration to monitor user sessions, detect account takeover attempts, and enforce per-session rate limits.")

            static func threatsDetected(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) threat\(count == 1 ? "" : "s") detected"
                return String(localized: "cerberus.sessions.threatsDetected", defaultValue: dv, table: table)
            }
        }

        // MARK: Honeypot
        enum Honeypot {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title            = s("cerberus.honeypot.title", "Honeypot Traps")
            static let subtitle         = s("cerberus.honeypot.subtitle", "Decoy endpoints detecting automated scanners")
            static let totalHits        = s("cerberus.honeypot.totalHits", "Total Hits")
            static let uniqueIPs        = s("cerberus.honeypot.uniqueIPs", "Unique IPs")
            static let trapPaths        = s("cerberus.honeypot.trapPaths", "Trap Paths")
            static let honeypotHits     = s("cerberus.honeypot.honeypotHits", "Honeypot Hits")
            static let blockIP          = s("cerberus.honeypot.blockIP", "Block IP")
            static let colIP            = s("cerberus.honeypot.colIP", "IP Address")
            static let colTrapPath      = s("cerberus.honeypot.colTrapPath", "Trap Path")
            static let colMethod        = s("cerberus.honeypot.colMethod", "Method")
            static let colUserAgent     = s("cerberus.honeypot.colUserAgent", "User Agent")
            static let colTimestamp     = s("cerberus.honeypot.colTimestamp", "Timestamp")
            static let detailIP         = s("cerberus.honeypot.detailIP", "IP")
            static let detailPath       = s("cerberus.honeypot.detailPath", "Path")
            static let detailMethod     = s("cerberus.honeypot.detailMethod", "Method")
            static let detailTime       = s("cerberus.honeypot.detailTime", "Time")
            static let detailUA         = s("cerberus.honeypot.detailUA", "User-Agent")
            static let detailBody       = s("cerberus.honeypot.detailBody", "Body")
        }

        // MARK: Custom Rules
        enum Rules {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title            = s("cerberus.rules.title", "Custom Rules Engine")
            static let subtitle         = s("cerberus.rules.subtitle", "DSL-based request matching & filtering")
            static let addRule          = s("cerberus.rules.addRule", "Add Rule")
            static let totalRules       = s("cerberus.rules.totalRules", "Total Rules")
            static let syntaxReference  = s("cerberus.rules.syntaxReference", "Syntax Reference")
            static let syntaxFormat     = s("cerberus.rules.syntaxFormat", "WHEN <conditions> THEN <action>")
            static let noRules          = s("cerberus.rules.noRules", "No Custom Rules")
            static let noRulesDesc      = s("cerberus.rules.noRulesDesc", "Define DSL-based rules to match and filter incoming requests with precision.")
            static let newRuleTitle     = s("cerberus.rules.newRuleTitle", "New Custom Rule")
            static let newRuleDesc      = s("cerberus.rules.newRuleDesc", "Define a DSL expression to match and act on requests")
            static let ruleID           = s("cerberus.rules.ruleID", "Rule ID")
            static let ruleIDPlaceholder = s("cerberus.rules.ruleIDPlaceholder", "e.g. block-php-admin")
            static let ruleExpression   = s("cerberus.rules.ruleExpression", "Rule Expression")
            static let syntaxExample    = s("cerberus.rules.syntaxExample", "Syntax Example")
        }

        // MARK: Threat Feed
        enum ThreatFeed {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title            = s("cerberus.threatFeed.title", "Threat Intelligence")
            static let disabledTitle    = s("cerberus.threatFeed.disabledTitle", "Threat Intelligence Disabled")
            static let disabledDesc     = s("cerberus.threatFeed.disabledDesc", "Enable threat_feed_enabled in WAF config to activate intelligence feeds from Spamhaus, Emerging Threats, and FireHOL.")
            static let neverUpdated     = s("cerberus.threatFeed.neverUpdated", "Never updated")
            static let totalEntries     = s("cerberus.threatFeed.totalEntries", "Total Entries")
            static let threatsBlocked   = s("cerberus.threatFeed.threatsBlocked", "Threats Blocked")
            static let feedSources      = s("cerberus.threatFeed.feedSources", "Feed Sources")
            static let blockedByFeed    = s("cerberus.threatFeed.blockedByFeed", "Blocked by Feed")
            static let sourcesActive    = s("cerberus.threatFeed.sourcesActive", "Sources Active")
            static let sourceBreakdown  = s("cerberus.threatFeed.sourceBreakdown", "Source Breakdown")

            static func updated(_ date: String) -> String {
                let dv: String.LocalizationValue = "Updated: \(date)"
                return String(localized: "cerberus.threatFeed.updated", defaultValue: dv, table: table)
            }
        }

        // MARK: Compliance
        enum Compliance {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let complianceScore  = s("cerberus.compliance.score", "Compliance Score")
            static let passed           = s("cerberus.compliance.passed", "Passed")
            static let failed           = s("cerberus.compliance.failed", "Failed")
            static let warnings         = s("cerberus.compliance.warnings", "Warnings")
            static let checks           = s("cerberus.compliance.checks", "Compliance Checks")
            static let noReport         = s("cerberus.compliance.noReport", "No Compliance Report")
            static let noReportDesc     = s("cerberus.compliance.noReportDesc", "Connect to a server and run an audit to generate your compliance report.")
            static let generateReport   = s("cerberus.compliance.generateReport", "Generate Report")
        }

        // MARK: Toast Messages (ViewModel)
        enum Toast {
            private static let table = "Cerberus"

            static func blocked(_ ip: String) -> String {
                let dv: String.LocalizationValue = "Blocked \(ip)"
                return String(localized: "cerberus.toast.blocked", defaultValue: dv, table: table)
            }
            static func unblocked(_ ip: String) -> String {
                let dv: String.LocalizationValue = "Unblocked \(ip)"
                return String(localized: "cerberus.toast.unblocked", defaultValue: dv, table: table)
            }
            static func allowed(_ ip: String) -> String {
                let dv: String.LocalizationValue = "Allowed \(ip)"
                return String(localized: "cerberus.toast.allowed", defaultValue: dv, table: table)
            }
            static func removedFromAllowlist(_ ip: String) -> String {
                let dv: String.LocalizationValue = "Removed \(ip) from allowlist"
                return String(localized: "cerberus.toast.removedFromAllowlist", defaultValue: dv, table: table)
            }
            static func failedToBlock(_ ip: String, _ error: String) -> String {
                let dv: String.LocalizationValue = "Failed to block \(ip): \(error)"
                return String(localized: "cerberus.toast.failedToBlock", defaultValue: dv, table: table)
            }
            static func failedToUnblock(_ ip: String, _ error: String) -> String {
                let dv: String.LocalizationValue = "Failed to unblock \(ip): \(error)"
                return String(localized: "cerberus.toast.failedToUnblock", defaultValue: dv, table: table)
            }
            static func failedToAllow(_ ip: String, _ error: String) -> String {
                let dv: String.LocalizationValue = "Failed to allow \(ip): \(error)"
                return String(localized: "cerberus.toast.failedToAllow", defaultValue: dv, table: table)
            }
            static func failedToRemove(_ ip: String, _ error: String) -> String {
                let dv: String.LocalizationValue = "Failed to remove \(ip): \(error)"
                return String(localized: "cerberus.toast.failedToRemove", defaultValue: dv, table: table)
            }
            static func domainAdded(_ domain: String) -> String {
                let dv: String.LocalizationValue = "Added \(domain)"
                return String(localized: "cerberus.toast.domainAdded", defaultValue: dv, table: table)
            }
            static func domainAddFailed(_ domain: String, _ error: String) -> String {
                let dv: String.LocalizationValue = "Failed to add \(domain): \(error)"
                return String(localized: "cerberus.toast.domainAddFailed", defaultValue: dv, table: table)
            }
            static func domainRemoved(_ domain: String) -> String {
                let dv: String.LocalizationValue = "Removed \(domain)"
                return String(localized: "cerberus.toast.domainRemoved", defaultValue: dv, table: table)
            }
            static func domainRemoveFailed(_ domain: String, _ error: String) -> String {
                let dv: String.LocalizationValue = "Failed to remove \(domain): \(error)"
                return String(localized: "cerberus.toast.domainRemoveFailed", defaultValue: dv, table: table)
            }
            static func syncedDomains(_ count: Int) -> String {
                let dv: String.LocalizationValue = "Synced \(count) new domain(s)"
                return String(localized: "cerberus.toast.syncedDomains", defaultValue: dv, table: table)
            }
            static func failed(_ error: String) -> String {
                let dv: String.LocalizationValue = "Failed: \(error)"
                return String(localized: "cerberus.toast.failed", defaultValue: dv, table: table)
            }
            static func syncFailed(_ error: String) -> String {
                let dv: String.LocalizationValue = "Sync failed: \(error)"
                return String(localized: "cerberus.toast.syncFailed", defaultValue: dv, table: table)
            }
            static func configSaved(_ label: String) -> String {
                let dv: String.LocalizationValue = "\(label) config saved"
                return String(localized: "cerberus.toast.configSaved", defaultValue: dv, table: table)
            }
            static func configSaveFailed(_ label: String) -> String {
                let dv: String.LocalizationValue = "\(label) config save failed"
                return String(localized: "cerberus.toast.configSaveFailed", defaultValue: dv, table: table)
            }
            static func startFailed(_ error: String) -> String {
                let dv: String.LocalizationValue = "Start failed: \(error)"
                return String(localized: "cerberus.toast.startFailed", defaultValue: dv, table: table)
            }
            static func stopFailed(_ error: String) -> String {
                let dv: String.LocalizationValue = "Stop failed: \(error)"
                return String(localized: "cerberus.toast.stopFailed", defaultValue: dv, table: table)
            }
            static func restartFailed(_ error: String) -> String {
                let dv: String.LocalizationValue = "Restart failed: \(error)"
                return String(localized: "cerberus.toast.restartFailed", defaultValue: dv, table: table)
            }
            static func reloadFailed(_ error: String) -> String {
                let dv: String.LocalizationValue = "Reload failed: \(error)"
                return String(localized: "cerberus.toast.reloadFailed", defaultValue: dv, table: table)
            }
            static func errorPrefix(_ prefix: String, _ error: String) -> String {
                let dv: String.LocalizationValue = "\(prefix): \(error)"
                return String(localized: "cerberus.toast.errorPrefix", defaultValue: dv, table: table)
            }

            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let allDomainsUpToDate   = s("cerberus.toast.allDomainsUpToDate", "All domains up to date")
            static let moduleEnabled        = s("cerberus.toast.moduleEnabled", "Module enabled")
            static let moduleDisabled       = s("cerberus.toast.moduleDisabled", "Module disabled")
            static let wafStarted           = s("cerberus.toast.wafStarted", "WAF service started")
            static let wafStopped           = s("cerberus.toast.wafStopped", "WAF service stopped")
            static let wafRestarted         = s("cerberus.toast.wafRestarted", "WAF service restarted")
            static let wafReloaded          = s("cerberus.toast.wafReloaded", "WAF config reloaded")
            static let threatFeedsUpdated   = s("cerberus.toast.threatFeedsUpdated", "Threat feeds updated")
            static let virtualPatchRemoved  = s("cerberus.toast.virtualPatchRemoved", "Virtual patch removed")
            static let configBackupCreated  = s("cerberus.toast.configBackupCreated", "Config backup created")
            static let ruleAdded            = s("cerberus.toast.ruleAdded", "Rule added")
            static let ruleRemoved          = s("cerberus.toast.ruleRemoved", "Rule removed")
        }

        // MARK: Plugin Gate
        enum Gate {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let notInstalled         = s("cerberus.gate.notInstalled", "This plugin is not installed on this server.")
            static let free                 = s("cerberus.gate.free", "Free")
            static let paid                 = s("cerberus.gate.paid", "Paid")
            static let pro                  = s("cerberus.gate.pro", "Pro")
            static let getPlugin            = s("cerberus.gate.getPlugin", "Get Plugin")
            static let opensInBrowser       = s("cerberus.gate.opensInBrowser", "Opens in browser")
            static let installPlugin        = s("cerberus.gate.installPlugin", "Install Plugin")
            static let verifyingLicense     = s("cerberus.gate.verifyingLicense", "Verifying license...")
            static let preparingInstall     = s("cerberus.gate.preparingInstall", "Preparing secure install...")
            static let finalizing           = s("cerberus.gate.finalizing", "Finalizing...")
            static let installFailed        = s("cerberus.gate.installFailed", "Installation failed. Please try again later.")
            static let pluginInfoNA         = s("cerberus.gate.pluginInfoNA", "Plugin info not available")
            static let getLicense           = s("cerberus.gate.getLicense", "Get License")
            static let checkFailed          = s("cerberus.gate.checkFailed", "Failed to check plugin status")
            static let checkFailedDesc      = s("cerberus.gate.checkFailedDesc", "Unable to check plugin status. Please try again.")
            static let licenseRequired      = s("cerberus.gate.licenseRequired", "A valid license is required to use this plugin.")

            static func installedSuccessfully(_ name: String) -> String {
                let dv: String.LocalizationValue = "\(name) installed successfully"
                return String(localized: "cerberus.gate.installedSuccessfully", defaultValue: dv, table: table)
            }
        }
    }
}
