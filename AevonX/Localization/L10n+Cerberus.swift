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
            static let visitorLog   = s("cerberus.tab.visitorLog", "Visitor Log")
            static let settings     = s("cerberus.tab.settings", "Settings")
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
            static let domainHealth     = s("cerberus.dashboard.domainHealth", "Domain Health")
            static let protected        = s("cerberus.dashboard.protected", "Protected")
            static let monitoring       = s("cerberus.dashboard.monitoring", "Monitoring")
            static let alert            = s("cerberus.dashboard.alert", "Alert")
            static let underAttackLabel = s("cerberus.dashboard.underAttackLabel", "Under Attack")

            // DDoS level names (localized)
            static let ddosLevelNone    = s("cerberus.dashboard.ddosLevelNone", "None")
            static let ddosLevelLow     = s("cerberus.dashboard.ddosLevelLow", "Low")
            static let ddosLevelMedium  = s("cerberus.dashboard.ddosLevelMedium", "Medium")
            static let ddosLevelHigh    = s("cerberus.dashboard.ddosLevelHigh", "High")
            static let ddosLevelUnknown = s("cerberus.dashboard.ddosLevelUnknown", "Unknown")

            static func ddosLevelName(for key: String) -> String {
                switch key {
                case "none":    return ddosLevelNone
                case "low":     return ddosLevelLow
                case "medium":  return ddosLevelMedium
                case "high":    return ddosLevelHigh
                default:        return ddosLevelUnknown
                }
            }

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
            static let latencyAvg           = s("cerberus.traffic.latencyAvg", "Avg")
            static let latencyMax           = s("cerberus.traffic.latencyMax", "Max")

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

            // Validation
            static let validIP              = s("cerberus.ip.validIP", "Valid IP address")
            static func validCIDR(_ count: Int) -> String {
                let dv: String.LocalizationValue = "Valid CIDR range (\(count) addresses)"
                return String(localized: "cerberus.ip.validCIDR", defaultValue: dv, table: table)
            }
            static let invalidIP            = s("cerberus.ip.invalidIP", "Invalid IP or CIDR range")

            // Bulk mode
            static let modeSingle           = s("cerberus.ip.modeSingle", "Single")
            static let modeBulk             = s("cerberus.ip.modeBulk", "Bulk Import")
            static let bulkLabel            = s("cerberus.ip.bulkLabel", "IP Addresses (one per line)")
            static func bulkValid(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) valid"
                return String(localized: "cerberus.ip.bulkValid", defaultValue: dv, table: table)
            }
            static func bulkInvalid(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) invalid"
                return String(localized: "cerberus.ip.bulkInvalid", defaultValue: dv, table: table)
            }
            static func bulkAction(_ isBlock: Bool, _ count: Int) -> String {
                let label = isBlock ? "Block" : "Allow"
                let dv: String.LocalizationValue = "\(label) \(count) IPs"
                return String(localized: "cerberus.ip.bulkAction", defaultValue: dv, table: table)
            }

            // Delete confirmation
            static let confirmDeleteTitle   = s("cerberus.ip.confirmDeleteTitle", "Remove IP")
            static let confirmDeleteAction  = s("cerberus.ip.confirmDeleteAction", "Remove")
            static func confirmDeleteMessage(_ ip: String) -> String {
                let dv: String.LocalizationValue = "Are you sure you want to remove \(ip) from the list?"
                return String(localized: "cerberus.ip.confirmDeleteMessage", defaultValue: dv, table: table)
            }

            // Export
            static func copiedToClipboard(_ count: Int) -> String {
                let dv: String.LocalizationValue = "Copied \(count) IPs to clipboard"
                return String(localized: "cerberus.ip.copiedToClipboard", defaultValue: dv, table: table)
            }
            static let copyTooltip          = s("cerberus.ip.copyTooltip", "Copy all IPs to clipboard")

            // Country picker
            static let searchCountry        = s("cerberus.ip.searchCountry", "Search countries...")
            static let selectCountries      = s("cerberus.ip.selectCountries", "Select Countries to Block")
            static let selectCountriesDesc  = s("cerberus.ip.selectCountriesDesc", "Choose countries to block from a searchable list")
            static func blockCountries(_ count: Int) -> String {
                let dv: String.LocalizationValue = "Block \(count) Countries"
                return String(localized: "cerberus.ip.blockCountries", defaultValue: dv, table: table)
            }
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
            static let requests             = s("cerberus.domains.requests", "Requests")
            static let blocked              = s("cerberus.domains.blocked", "Blocked")
            static let blockRate            = s("cerberus.domains.blockRate", "Block Rate")
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

            // Severity filter chips
            static let filterAll            = s("cerberus.alerts.filterAll", "All")
            static let filterCritical       = s("cerberus.alerts.filterCritical", "Critical")
            static let filterHigh           = s("cerberus.alerts.filterHigh", "High")
            static let filterMedium         = s("cerberus.alerts.filterMedium", "Medium")
            static let filterLow            = s("cerberus.alerts.filterLow", "Low")

            static func filterLabel(for key: String) -> String {
                switch key {
                case "all":      return filterAll
                case "critical": return filterCritical
                case "high":     return filterHigh
                case "medium":   return filterMedium
                case "low":      return filterLow
                default:         return key.capitalized
                }
            }

            private static let alertTypeMap: [String: String] = [
                "waf_block": s("cerberus.alerts.type.waf_block", "WAF Block"),
                "rate_limit": s("cerberus.alerts.type.rate_limit", "Rate Limit"),
                "ddos_spike": s("cerberus.alerts.type.ddos_spike", "DDoS Spike"),
                "bot_detected": s("cerberus.alerts.type.bot_detected", "Bot Detected"),
                "credential_attack": s("cerberus.alerts.type.credential_attack", "Credential Attack"),
                "honeypot_hit": s("cerberus.alerts.type.honeypot_hit", "Honeypot Hit"),
                "ssrf_attempt": s("cerberus.alerts.type.ssrf_attempt", "SSRF Attempt"),
                "dlp_leak": s("cerberus.alerts.type.dlp_leak", "DLP Leak"),
                "anomaly": s("cerberus.alerts.type.anomaly", "Anomaly"),
                "session_hijack": s("cerberus.alerts.type.session_hijack", "Session Hijack"),
                "threat_feed": s("cerberus.alerts.type.threat_feed", "Threat Feed"),
                "custom_rule": s("cerberus.alerts.type.custom_rule", "Custom Rule"),
                "challenge_fail": s("cerberus.alerts.type.challenge_fail", "Challenge Fail"),
                "geo_block": s("cerberus.alerts.type.geo_block", "Geo Block"),
                "ip_block": s("cerberus.alerts.type.ip_block", "IP Block"),
            ]

            static func alertTypeDisplay(_ type: String) -> String {
                alertTypeMap[type] ?? type.replacingOccurrences(of: "_", with: " ").capitalized
            }
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
            static let threatFeed           = s("cerberus.modules.threatFeed", "Threat Feed")
            static let threatFeedDesc       = s("cerberus.modules.threatFeedDesc", "Auto-updated IP reputation lists")
            static let apiSecurity          = s("cerberus.modules.apiSecurity", "API Security")
            static let apiSecDesc           = s("cerberus.modules.apiSecDesc", "JSON validation, method enforcement, schema checks")
            static let securityHeaders      = s("cerberus.modules.securityHeaders", "Security Headers")
            static let secHeadersDesc       = s("cerberus.modules.secHeadersDesc", "HSTS, CSP, X-Frame-Options injection")
            static let challenge            = s("cerberus.modules.challenge", "Challenge Gate")
            static let challengeDesc        = s("cerberus.modules.challengeDesc", "Proof-of-Work challenge for suspicious traffic")
            static let vpatch               = s("cerberus.modules.vpatch", "Virtual Patching")
            static let vpatchDesc           = s("cerberus.modules.vpatchDesc", "Hot-fix rules for known CVEs without code changes")
            static let anomaly              = s("cerberus.modules.anomaly", "Anomaly Detection")
            static let anomalyDesc          = s("cerberus.modules.anomalyDesc", "Statistical baseline deviation alerting")
            static let session              = s("cerberus.modules.session", "Session Tracking")
            static let sessionDesc          = s("cerberus.modules.sessionDesc", "Session hijacking and ATO detection")
            static let customRules          = s("cerberus.modules.customRules", "Custom Rules")
            static let customRulesDesc      = s("cerberus.modules.customRulesDesc", "User-defined DSL-based matching rules")
            static let statsAPI             = s("cerberus.modules.statsAPI", "Stats API")
            static let statsAPIDesc         = s("cerberus.modules.statsAPIDesc", "Real-time metrics and log export API")
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
            // Config units
            static let unitReqPerMin        = s("cerberus.modules.unitReqPerMin", "req/min")
            static let unitTimes            = s("cerberus.modules.unitTimes", "×")
            static let unitConns            = s("cerberus.modules.unitConns", "conns")
            static let unitPerHour          = s("cerberus.modules.unitPerHour", "per hour")
            static let unitAlerts           = s("cerberus.modules.unitAlerts", "alerts")
            // Categories
            static let catCore              = s("cerberus.modules.catCore", "Core")
            static let catTraffic           = s("cerberus.modules.catTraffic", "Traffic")
            static let catDefense           = s("cerberus.modules.catDefense", "Defense")
            static let catDetection         = s("cerberus.modules.catDetection", "Detection")
            static let catAuth              = s("cerberus.modules.catAuth", "Auth")
            static let catData              = s("cerberus.modules.catData", "Data")
            static let catAlerting          = s("cerberus.modules.catAlerting", "Alerting")
            static let catIntelligence      = s("cerberus.modules.catIntelligence", "Intelligence")
            static let catAPI               = s("cerberus.modules.catAPI", "API")
            static let catHeaders           = s("cerberus.modules.catHeaders", "Headers")
            static let catProtection        = s("cerberus.modules.catProtection", "Protection")
            static let catTracking          = s("cerberus.modules.catTracking", "Tracking")
            static let catRules             = s("cerberus.modules.catRules", "Rules")
            static let catSystem            = s("cerberus.modules.catSystem", "System")
            // DLP Modes
            static let dlpModeLog           = s("cerberus.modules.dlpModeLog", "Log")
            static let dlpModeMask          = s("cerberus.modules.dlpModeMask", "Mask")
            static let dlpModeBlock         = s("cerberus.modules.dlpModeBlock", "Block")
            // Alert Severity
            static let sevLow               = s("cerberus.modules.sevLow", "Low")
            static let sevMedium            = s("cerberus.modules.sevMedium", "Medium")
            static let sevHigh              = s("cerberus.modules.sevHigh", "High")
            static let sevCritical          = s("cerberus.modules.sevCritical", "Critical")

            static func categoryLabel(for key: String) -> String {
                switch key {
                case "Core": return catCore
                case "Traffic": return catTraffic
                case "Defense": return catDefense
                case "Detection": return catDetection
                case "Auth": return catAuth
                case "Data": return catData
                case "Alerting": return catAlerting
                case "Intelligence": return catIntelligence
                case "API": return catAPI
                case "Headers": return catHeaders
                case "Protection": return catProtection
                case "Tracking": return catTracking
                case "Rules": return catRules
                case "System": return catSystem
                default: return key
                }
            }

            static func dlpModeLabel(for mode: String) -> String {
                switch mode {
                case "log": return dlpModeLog
                case "mask": return dlpModeMask
                case "block": return dlpModeBlock
                default: return mode.capitalized
                }
            }

            static func severityLabel(for sev: String) -> String {
                switch sev {
                case "low": return sevLow
                case "medium": return sevMedium
                case "high": return sevHigh
                case "critical": return sevCritical
                default: return sev.capitalized
                }
            }
            // Placeholders
            static let trapPathsPlaceholder = s("cerberus.modules.trapPathsPlaceholder", "/wp-admin,/.env,/phpmyadmin")
            static let webhookPlaceholder   = s("cerberus.modules.webhookPlaceholder", "https://hooks.example.com/...")
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
            static let headerPrefix     = s("cerberus.honeypot.headerPrefix", "Header")
        }

        // MARK: Domain Detail
        enum DomainDetail {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let tabOverview  = s("cerberus.domainDetail.tabOverview", "Overview")
            static let tabTraffic   = s("cerberus.domainDetail.tabTraffic", "Traffic")
            static let tabAttacks   = s("cerberus.domainDetail.tabAttacks", "Attacks")
            static let tabCountries = s("cerberus.domainDetail.tabCountries", "Countries")
            static let tabBlocking  = s("cerberus.domainDetail.tabBlocking", "Block Rules")
            static let requests     = s("cerberus.domainDetail.requests", "Requests")
            static let blocked      = s("cerberus.domainDetail.blocked", "Blocked")
            static let blockRate    = s("cerberus.domainDetail.blockRate", "Block Rate")
            static let avgLatency   = s("cerberus.domainDetail.avgLatency", "Avg Latency")
            static let topPaths     = s("cerberus.domainDetail.topPaths", "Top Paths")
            static let noTraffic    = s("cerberus.domainDetail.noTraffic", "No traffic data for this domain")
            static let noAttacks    = s("cerberus.domainDetail.noAttacks", "No blocked requests — looking good")
            static let noCountries  = s("cerberus.domainDetail.noCountries", "No country data available")
            static let trafficChart = s("cerberus.domainDetail.trafficChart", "Traffic Timeline")
            static let topCountries = s("cerberus.domainDetail.topCountries", "Top Countries")
            static let recentVisits = s("cerberus.domainDetail.recentVisits", "Recent Visits")
            static let blockedIPs       = s("cerberus.domainDetail.blockedIPs", "Blocked IPs")
            static let blockedCountries = s("cerberus.domainDetail.blockedCountries", "Blocked Countries")
            static let addIP            = s("cerberus.domainDetail.addIP", "Block IP")
            static let addCountry       = s("cerberus.domainDetail.addCountry", "Block Country")
            static let ipPlaceholder    = s("cerberus.domainDetail.ipPlaceholder", "e.g. 192.168.1.1")
            static let countryPlaceholder = s("cerberus.domainDetail.countryPlaceholder", "e.g. CN")
            static let noBlockedIPs     = s("cerberus.domainDetail.noBlockedIPs", "No IPs blocked for this domain")
            static let noBlockedCountries = s("cerberus.domainDetail.noBlockedCountries", "No countries blocked for this domain")
            static let allowed          = s("cerberus.domainDetail.allowed", "Allowed")
            static let today            = s("cerberus.domainDetail.today", "Today")
            static let week             = s("cerberus.domainDetail.week", "Week")
            static let month            = s("cerberus.domainDetail.month", "Month")
        }

        // MARK: Visitor Log
        enum VisitorLog {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title            = s("cerberus.visitorLog.title", "Visitor Log")
            static let subtitle         = s("cerberus.visitorLog.subtitle", "Real-time access log with request details")
            static let totalRequests    = s("cerberus.visitorLog.totalRequests", "Total Requests")
            static let botRequests      = s("cerberus.visitorLog.botRequests", "Bot Requests")
            static let avgLatency       = s("cerberus.visitorLog.avgLatency", "Avg Latency")
            static let errorRate        = s("cerberus.visitorLog.errorRate", "Error Rate")
            static let filterAll        = s("cerberus.visitorLog.filterAll", "All")
            static let filterSuccess    = s("cerberus.visitorLog.filterSuccess", "Success")
            static let filterErrors     = s("cerberus.visitorLog.filterErrors", "Errors")
            static let filterBlocked    = s("cerberus.visitorLog.filterBlocked", "Blocked")
            static let filterBots       = s("cerberus.visitorLog.filterBots", "Bots")
            static let searchPlaceholder = s("cerberus.visitorLog.searchPlaceholder", "Search by IP, path, or user agent...")
            static let colTime          = s("cerberus.visitorLog.colTime", "Time")
            static let colIP            = s("cerberus.visitorLog.colIP", "IP")
            static let colCountry       = s("cerberus.visitorLog.colCountry", "Country")
            static let colMethod        = s("cerberus.visitorLog.colMethod", "Method")
            static let colPath          = s("cerberus.visitorLog.colPath", "Path")
            static let colStatus        = s("cerberus.visitorLog.colStatus", "Status")
            static let colLatency       = s("cerberus.visitorLog.colLatency", "Latency")
            static let noEntries        = s("cerberus.visitorLog.noEntries", "No log entries")
            static let noEntriesDesc    = s("cerberus.visitorLog.noEntriesDesc", "Access log entries will appear here as traffic flows through the WAF.")
            static let allDomains       = s("cerberus.visitorLog.allDomains", "All Domains")
            static let detailHost       = s("cerberus.visitorLog.detailHost", "Host")
            static let detailBytesIn    = s("cerberus.visitorLog.detailBytesIn", "Bytes In")
            static let detailBytesOut   = s("cerberus.visitorLog.detailBytesOut", "Bytes Out")
            static let detailUserAgent  = s("cerberus.visitorLog.detailUserAgent", "User-Agent")
            static let detailBot        = s("cerberus.visitorLog.detailBot", "Bot")
            static let detailTimestamp  = s("cerberus.visitorLog.detailTimestamp", "Timestamp")
            static let yes              = s("cerberus.visitorLog.yes", "Yes")
            static let no               = s("cerberus.visitorLog.no", "No")

            static func showingEntries(_ from: Int, _ to: Int, _ total: Int) -> String {
                let dv: String.LocalizationValue = "Showing \(from)–\(to) of \(total)"
                return String(localized: "cerberus.visitorLog.showingEntries", defaultValue: dv, table: table)
            }
            static func pageOf(_ current: Int, _ total: Int) -> String {
                let dv: String.LocalizationValue = "\(current) / \(total)"
                return String(localized: "cerberus.visitorLog.pageOf", defaultValue: dv, table: table)
            }
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
            static let ruleExpression       = s("cerberus.rules.ruleExpression", "Rule Expression")
            static let syntaxExample        = s("cerberus.rules.syntaxExample", "Syntax Example")
            static let expressionPlaceholder = s("cerberus.rules.expressionPlaceholder", "WHEN ... THEN ...")
            static let syntaxHint           = s("cerberus.rules.syntaxHint", "WHEN path.startsWith(\"/api\") AND method == \"POST\" THEN block")
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

            static func totalChecks(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) total"
                return String(localized: "cerberus.compliance.totalChecks", defaultValue: dv, table: table)
            }
        }

        // MARK: Settings
        enum Settings {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let title            = s("cerberus.settings.title", "Settings")
            static let subtitle         = s("cerberus.settings.subtitle", "Backups, patches, exports & raw configuration")

            // Section picker
            static let sectionBackups   = s("cerberus.settings.sectionBackups", "Backups")
            static let sectionVPatches  = s("cerberus.settings.sectionVPatches", "Virtual Patches")
            static let sectionExport    = s("cerberus.settings.sectionExport", "Log Export")
            static let sectionRawConfig = s("cerberus.settings.sectionRawConfig", "Raw Config")

            // Backups
            static let backupsTitle     = s("cerberus.settings.backupsTitle", "Config Backups")
            static let backupsDesc      = s("cerberus.settings.backupsDesc", "Snapshot and restore WAF configuration state")
            static let createBackup     = s("cerberus.settings.createBackup", "Create Backup")
            static let savedBackups     = s("cerberus.settings.savedBackups", "Saved Backups")
            static let noBackups        = s("cerberus.settings.noBackups", "No config backups yet")
            static let restore          = s("cerberus.settings.restore", "Restore")

            // Virtual Patches
            static let vpatchesTitle    = s("cerberus.settings.vpatchesTitle", "Virtual Patches")
            static let vpatchesDesc     = s("cerberus.settings.vpatchesDesc", "Temporary vulnerability shields applied without code changes")
            static let activePatches    = s("cerberus.settings.activePatches", "Active Patches")
            static let noVPatches       = s("cerberus.settings.noVPatches", "No virtual patches applied")

            // Log Export
            static let exportAccess     = s("cerberus.settings.exportAccess", "Export Access Logs")
            static let exportAccessDesc = s("cerberus.settings.exportAccessDesc", "Download all access log entries as structured data")
            static let exportBlock      = s("cerberus.settings.exportBlock", "Export Block Logs")
            static let exportBlockDesc  = s("cerberus.settings.exportBlockDesc", "Download all blocked request entries as structured data")
            static let export           = s("cerberus.settings.export", "Export")

            // Raw Config
            static let rawConfigTitle   = s("cerberus.settings.rawConfigTitle", "Raw Configuration")
            static let rawConfigDesc    = s("cerberus.settings.rawConfigDesc", "All key-value pairs from the active WAF configuration")
            static let noConfig         = s("cerberus.settings.noConfig", "Configuration not loaded")
            static let configKey        = s("cerberus.settings.configKey", "Key")
            static let configValue      = s("cerberus.settings.configValue", "Value")
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
            static func configPartialFail(_ label: String, _ count: Int) -> String {
                let dv: String.LocalizationValue = "\(label) config partially saved — \(count) key(s) failed"
                return String(localized: "cerberus.toast.configPartialFail", defaultValue: dv, table: table)
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
            static let virtualPatchApplied  = s("cerberus.toast.virtualPatchApplied", "Virtual patch applied")
            static let configBackupCreated  = s("cerberus.toast.configBackupCreated", "Config backup created")
            static let configRestored       = s("cerberus.toast.configRestored", "Configuration restored from backup")
            static let logsExported         = s("cerberus.toast.logsExported", "Logs exported successfully")
            static let ruleAdded            = s("cerberus.toast.ruleAdded", "Rule added")
            static let ruleRemoved          = s("cerberus.toast.ruleRemoved", "Rule removed")
            static let configLoadFailed     = s("cerberus.toast.configLoadFailed", "Failed to load WAF configuration")
        }

        // MARK: Delete Confirmation Dialogs
        enum Dialog {
            private static let table = "Cerberus"
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

            static let delete       = s("cerberus.dialog.delete", "Delete")
            static let deleteRule   = s("cerberus.dialog.deleteRule", "Are you sure you want to delete this rule?")
            static let deleteDomain = s("cerberus.dialog.deleteDomain", "Are you sure you want to remove this domain?")
            static let deleteVPatch    = s("cerberus.dialog.deleteVPatch", "Are you sure you want to remove this virtual patch?")
            static let restoreBackup   = s("cerberus.dialog.restoreBackup", "Are you sure you want to restore this backup? Current configuration will be overwritten.")
        }

        // MARK: Pagination
        enum Pagination {
            private static let table = "Cerberus"

            static func showing(_ from: Int, _ to: Int, _ total: Int) -> String {
                let dv: String.LocalizationValue = "Showing \(from)–\(to) of \(total)"
                return String(localized: "cerberus.pagination.showing", defaultValue: dv, table: table)
            }
            static func page(_ current: Int, _ total: Int) -> String {
                let dv: String.LocalizationValue = "\(current) / \(total)"
                return String(localized: "cerberus.pagination.page", defaultValue: dv, table: table)
            }
        }

        // MARK: Badge Format Strings
        enum Badge {
            private static let table = "Cerberus"

            static func active(_ current: Int, _ total: Int) -> String {
                let dv: String.LocalizationValue = "\(current)/\(total) active"
                return String(localized: "cerberus.badge.active", defaultValue: dv, table: table)
            }
            static func entries(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) entries"
                return String(localized: "cerberus.badge.entries", defaultValue: dv, table: table)
            }
            static func entriesStr(_ count: String) -> String {
                let dv: String.LocalizationValue = "\(count) entries"
                return String(localized: "cerberus.badge.entriesStr", defaultValue: dv, table: table)
            }
            static func samples(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) samples"
                return String(localized: "cerberus.badge.samples", defaultValue: dv, table: table)
            }
            static func sources(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) sources"
                return String(localized: "cerberus.badge.sources", defaultValue: dv, table: table)
            }
            static func events(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) events"
                return String(localized: "cerberus.badge.events", defaultValue: dv, table: table)
            }
            static func types(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) types"
                return String(localized: "cerberus.badge.types", defaultValue: dv, table: table)
            }
            static func ips(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) IPs"
                return String(localized: "cerberus.badge.ips", defaultValue: dv, table: table)
            }
            static func paths(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) paths"
                return String(localized: "cerberus.badge.paths", defaultValue: dv, table: table)
            }
            static func countries(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) countries"
                return String(localized: "cerberus.badge.countries", defaultValue: dv, table: table)
            }
            static func rules(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) rules"
                return String(localized: "cerberus.badge.rules", defaultValue: dv, table: table)
            }
            static func domains(_ count: Int) -> String {
                let dv: String.LocalizationValue = "\(count) domains"
                return String(localized: "cerberus.badge.domains", defaultValue: dv, table: table)
            }
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
            static let buildingPlugin       = s("cerberus.gate.buildingPlugin", "Building secure binary... This may take a moment.")
            static let downloadingPlugin    = s("cerberus.gate.downloadingPlugin", "Downloading and deploying...")
            static let buildingProtection   = s("cerberus.gate.buildingProtection", "Building protected binary...")
            static let downloadingProgress  = s("cerberus.gate.downloadingProgress", "Downloading...")
            static let deployingToServer    = s("cerberus.gate.deployingToServer", "Deploying to server...")
            static let installingPlugin     = s("cerberus.gate.installingPlugin", "Installing plugin...")
            static let verifyingInstall     = s("cerberus.gate.verifyingInstall", "Verifying installation...")
            static let buildingAgent        = s("cerberus.gate.buildingAgent", "Building security agent...")
            static let downloadingAgent     = s("cerberus.gate.downloadingAgent", "Downloading agent...")
            static let uploadingToServer    = s("cerberus.gate.uploadingToServer", "Uploading to server...")
            static let installingService    = s("cerberus.gate.installingService", "Installing service...")
            static let verifyingService     = s("cerberus.gate.verifyingService", "Verifying service...")
            static let agentDeployed        = s("cerberus.gate.agentDeployed", "Agent deployed successfully")

            static func installedSuccessfully(_ name: String) -> String {
                let dv: String.LocalizationValue = "\(name) installed successfully"
                return String(localized: "cerberus.gate.installedSuccessfully", defaultValue: dv, table: table)
            }
        }
    }
}
