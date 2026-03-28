import Foundation

extension L10n {

    // MARK: - Chrono (Chrono.strings)
    enum Chrono {
        private static let table = "Chrono"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        // Root
        static let brand = s("chrono.brand", "AXChrono")
        static let subtitle = s("chrono.subtitle", "Autonomous Git Deployment")
        static let sidebarTitle = s("chrono.sidebarTitle", "AXCHRONO")

        // Categories
        static let catOverview = s("chrono.cat.overview", "Overview")
        static let catDeployment = s("chrono.cat.deployment", "Deployment")
        static let catIntelligence = s("chrono.cat.intelligence", "Intelligence")
        static let catManagement = s("chrono.cat.management", "Management")

        // Tabs
        static let tabDashboard = s("chrono.tab.dashboard", "Dashboard")
        static let tabProjects = s("chrono.tab.projects", "Projects")
        static let tabDeploys = s("chrono.tab.deploys", "Deploys")
        static let tabTimeline = s("chrono.tab.timeline", "Timeline")
        static let tabSecurity = s("chrono.tab.security", "Security")
        static let tabApprovals = s("chrono.tab.approvals", "Approvals")
        static let tabHologram = s("chrono.tab.hologram", "Hologram")
        static let tabSettings = s("chrono.tab.settings", "Settings")

        // Dashboard
        static let dashboardTitle = s("chrono.dashboard.title", "AXChrono Dashboard")
        static let activeProjects = s("chrono.dashboard.activeProjects", "Active Projects")
        static let totalDeploys = s("chrono.dashboard.totalDeploys", "Total Deploys")
        static let failedThisWeek = s("chrono.dashboard.failedThisWeek", "Failed This Week")
        static let healthStatus = s("chrono.dashboard.healthStatus", "Health")
        static let cacheSize = s("chrono.dashboard.cacheSize", "Cache")
        static let secretsDetected = s("chrono.dashboard.secretsDetected", "Secrets Detected")
        static let recentDeploys = s("chrono.dashboard.recentDeploys", "Recent Deploys")
        static let activeWatchers = s("chrono.dashboard.activeWatchers", "Active Watchers")
        static let alerts = s("chrono.dashboard.alerts", "Alerts")
        static let allHealthy = s("chrono.dashboard.allHealthy", "All Healthy")

        // Projects
        enum Projects {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let title = s("chrono.projects.title", "Tracked Projects")
            static let add = s("chrono.projects.add", "Add Project")
            static let empty = s("chrono.projects.empty", "No projects tracked yet")
            static let name = s("chrono.projects.name", "Project Name")
            static let path = s("chrono.projects.path", "Project Path")
            static let repoURL = s("chrono.projects.repoURL", "Git Remote URL")
            static let branch = s("chrono.projects.branch", "Branch to Track")
            static let autoDeploy = s("chrono.projects.autoDeploy", "Auto-deploy on push")
            static let healthURL = s("chrono.projects.healthURL", "Health check URL")
            static let gitAuth = s("chrono.projects.gitAuth", "Git Authentication")
            static let gitUsername = s("chrono.projects.gitUsername", "Username")
            static let gitToken = s("chrono.projects.gitToken", "Token")
            static let watchMode = s("chrono.projects.watchMode", "Watch Mode")
            static let pollOnly = s("chrono.projects.pollOnly", "Poll only")
            static let webhookPoll = s("chrono.projects.webhookPoll", "Webhook + Poll fallback")
            static let pendingCommits = s("chrono.projects.pendingCommits", "pending commits")
            static let lastDeploy = s("chrono.projects.lastDeploy", "Last deploy")
        }

        // Deploy
        enum Deploy {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let trigger = s("chrono.deploy.trigger", "Deploy Now")
            static let history = s("chrono.deploy.history", "Deploy History")
            static let live = s("chrono.deploy.live", "Live Log")
            static let success = s("chrono.deploy.status.success", "Success")
            static let failed = s("chrono.deploy.status.failed", "Failed")
            static let rolledBack = s("chrono.deploy.status.rolledBack", "Rolled Back")
            static let running = s("chrono.deploy.status.running", "Deploying...")
            static let queued = s("chrono.deploy.status.queued", "Queued")
            static let duration = s("chrono.deploy.duration", "Duration")
            static let filesChanged = s("chrono.deploy.filesChanged", "Files Changed")
            static let pipelineSteps = s("chrono.deploy.pipelineSteps", "Pipeline Steps")
            static let viewLog = s("chrono.deploy.viewLog", "View Full Log")
            static let empty = s("chrono.deploy.empty", "No deployments yet")
        }

        // Project Detail
        enum ProjectDetail {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let info = s("chrono.projectDetail.info", "Details")
            static let health = s("chrono.projectDetail.health", "Health Probe")
            static let snapshots = s("chrono.projectDetail.snapshots", "Snapshots")
            static let noHealth = s("chrono.projectDetail.noHealth", "No health probe configured")
            static let noSnapshots = s("chrono.projectDetail.noSnapshots", "No snapshots available")

            static func lastChecked(_ time: String) -> String {
                let dv: String.LocalizationValue = "Last checked \(time)"
                return String(localized: "chrono.projectDetail.lastChecked", defaultValue: dv, table: Chrono.table)
            }
        }

        // Snapshots
        enum Snapshots {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let title = s("chrono.snapshots.title", "Snapshots")
            static let empty = s("chrono.snapshots.empty", "No snapshots yet")
            static let restore = s("chrono.snapshots.restore", "Restore")
        }

        // Health
        enum Health {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let title = s("chrono.health.title", "Health Monitor")
            static let refresh = s("chrono.health.refresh", "Refresh")
            static let totalProbes = s("chrono.health.totalProbes", "Total Probes")
            static let healthy = s("chrono.health.healthy", "Healthy")
            static let degraded = s("chrono.health.degraded", "Degraded")
            static let down = s("chrono.health.down", "Down")
            static let empty = s("chrono.health.empty", "No health probes configured")
            static let emptyHint = s("chrono.health.emptyHint", "Add a health URL to a project to enable monitoring")
            static let responseTime = s("chrono.health.responseTime", "Response Time")

            static func lastCheck(_ time: String) -> String {
                let dv: String.LocalizationValue = "Checked \(time)"
                return String(localized: "chrono.health.lastCheck", defaultValue: dv, table: Chrono.table)
            }
        }

        // Rollback
        static let rollbackTitle = s("chrono.rollback.title", "Rollback")
        static let rollbackConfirm = s("chrono.rollback.confirm", "Are you sure you want to rollback to this snapshot?")

        // Hologram
        enum Hologram {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let title = s("chrono.hologram.title", "Deploy Hologram")
            static let riskLow = s("chrono.hologram.risk.low", "Low Risk")
            static let riskMedium = s("chrono.hologram.risk.medium", "Medium Risk")
            static let riskHigh = s("chrono.hologram.risk.high", "High Risk")
            static let filesChanged = s("chrono.hologram.filesChanged", "Files Changed")
            static let dependencies = s("chrono.hologram.dependencies", "Dependencies")
            static let migrations = s("chrono.hologram.migrations", "Migrations")
            static let security = s("chrono.hologram.security", "Security")
            static let buildSteps = s("chrono.hologram.buildSteps", "Build Steps")
            static let downtime = s("chrono.hologram.downtime", "Downtime")
        }

        // Approvals
        enum Approvals {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let title = s("chrono.approvals.title", "Pending Approvals")
            static let empty = s("chrono.approvals.empty", "No pending approvals")
            static let approve = s("chrono.approvals.approve", "Approve")
            static let deny = s("chrono.approvals.deny", "Deny")
            static let history = s("chrono.approvals.history", "Approval History")
            static let selfheal = s("chrono.approvals.selfheal", "SelfHeal — Rollback Request")
            static let migration = s("chrono.approvals.migration", "Migration — Apply to Production")
            static let canary = s("chrono.approvals.canary", "Canary — Advance Phase")
            static let ghost = s("chrono.approvals.ghost", "Ghost — Swap to Live")
            static let drift = s("chrono.approvals.drift", "Drift — Revert Changes")
            static let expired = s("chrono.approvals.expired", "Expired")

            static func timeout(_ minutes: Int) -> String {
                let dv: String.LocalizationValue = "\(minutes) minutes remaining"
                return String(localized: "chrono.approvals.timeout", defaultValue: dv, table: Chrono.table)
            }
        }

        // Timeline
        static let timelineTitle = s("chrono.timeline.title", "Timeline")
        static let timelineEmpty = s("chrono.timeline.empty", "No events yet")

        // Scanner
        enum Scanner {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let title = s("chrono.scanner.title", "Security Scanner")
            static let noIssues = s("chrono.scanner.noIssues", "No security issues found")
            static let vaultScan = s("chrono.scanner.vaultScan", "VaultScan")
            static let threatRadar = s("chrono.scanner.threatRadar", "ThreatRadar")
            static let driftDetector = s("chrono.scanner.driftDetector", "DriftDetector")
            static let permissions = s("chrono.scanner.permissions", "PermissionMatrix")
            static let noSecrets = s("chrono.scanner.noSecrets", "No secrets in diff")
            static let noVulns = s("chrono.scanner.noVulns", "No known vulnerabilities")
        }

        // Webhook
        enum Webhook {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let title = s("chrono.webhook.title", "Webhook Configuration")
            static let url = s("chrono.webhook.url", "Your Webhook URL")
            static let secrets = s("chrono.webhook.secrets", "Secrets (per provider)")
            static let regenerate = s("chrono.webhook.regenerate", "Regenerate All")
            static let test = s("chrono.webhook.test", "Test Connection")
            static let recentDeliveries = s("chrono.webhook.recentDeliveries", "Recent Deliveries")
            static let setupGuide = s("chrono.webhook.setupGuide", "Setup Guide")
        }

        // Settings
        enum Settings {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: Chrono.table) }

            static let title = s("chrono.settings.title", "AXChrono Settings")

            // GitPulse
            static let gitpulse = s("chrono.settings.gitpulse", "GitPulse Watcher")
            static let gitpulseDesc = s("chrono.settings.gitpulse.desc", "Monitors Git repositories for new commits and triggers deployments")
            static let pollInterval = s("chrono.settings.pollInterval", "Poll Interval")
            static let pollIntervalDesc = s("chrono.settings.pollInterval.desc", "How often to check for new commits (seconds)")
            static let adaptivePolling = s("chrono.settings.adaptivePolling", "Adaptive Polling")
            static let adaptivePollingDesc = s("chrono.settings.adaptivePolling.desc", "Automatically adjust poll frequency based on repository activity")
            static let watchMode = s("chrono.settings.watchMode", "Watch Mode")
            static let watchModeDesc = s("chrono.settings.watchMode.desc", "How GitPulse detects new commits")

            // ZeroFlip
            static let zeroflip = s("chrono.settings.zeroflip", "ZeroFlip Deployment")
            static let zeroflipDesc = s("chrono.settings.zeroflip.desc", "Zero-downtime deployment with instant rollback capability")
            static let zeroflipEnabled = s("chrono.settings.zeroflipEnabled", "Enable ZeroFlip")
            static let zeroflipEnabledDesc = s("chrono.settings.zeroflipEnabled.desc", "Use blue-green deployment strategy for zero-downtime releases")
            static let maxReleases = s("chrono.settings.maxReleases", "Max Release Versions")
            static let maxReleasesDesc = s("chrono.settings.maxReleases.desc", "Number of previous releases to keep for instant rollback")

            // Sentinel
            static let sentinel = s("chrono.settings.sentinel", "SentinelHealth")
            static let sentinelDesc = s("chrono.settings.sentinel.desc", "Continuous health monitoring and automatic failure recovery")
            static let sentinelEnabled = s("chrono.settings.sentinelEnabled", "Enable SentinelHealth")
            static let sentinelEnabledDesc = s("chrono.settings.sentinelEnabled.desc", "Monitor service health after deployments")
            static let autoRollback = s("chrono.settings.autoRollback", "Auto Rollback on Failure")
            static let autoRollbackDesc = s("chrono.settings.autoRollback.desc", "Automatically rollback if health checks fail after deployment")

            // VaultScan
            static let vaultScan = s("chrono.settings.vaultScan", "VaultScan & Security")
            static let vaultScanDesc = s("chrono.settings.vaultScan.desc", "Scan deployments for secrets, vulnerabilities, and drift")
            static let vaultScanEnabled = s("chrono.settings.vaultScanEnabled", "Enable VaultScan")
            static let vaultScanEnabledDesc = s("chrono.settings.vaultScanEnabled.desc", "Scan code for exposed secrets and credentials before deployment")
            static let vaultScanMode = s("chrono.settings.vaultScanMode", "Scan Mode")
            static let vaultScanModeDesc = s("chrono.settings.vaultScanMode.desc", "Passive: warn only. Active: block deployment. Aggressive: deep scan")
            static let threatRadar = s("chrono.settings.threatRadar", "ThreatRadar")
            static let threatRadarDesc = s("chrono.settings.threatRadar.desc", "Monitor dependencies for known vulnerabilities")
            static let selfHeal = s("chrono.settings.selfHeal", "SelfHeal Auto-Recovery")
            static let selfHealDesc = s("chrono.settings.selfHeal.desc", "Automatically recover services that crash or become unresponsive")

            // Approval
            static let approval = s("chrono.settings.approval", "Approval Workflow")
            static let approvalDesc = s("chrono.settings.approval.desc", "Control how deployments and critical operations are approved")
            static let approvalMode = s("chrono.settings.approvalMode", "Approval Mode")
            static let approvalModeDesc = s("chrono.settings.approvalMode.desc", "Auto: no approval needed. Manual: always require. Smart: risk-based")
            static let approvalAuto = s("chrono.settings.approvalMode.auto", "Auto")
            static let approvalManual = s("chrono.settings.approvalMode.manual", "Manual")
            static let approvalSmart = s("chrono.settings.approvalMode.smart", "Smart")

            // Webhook
            static let webhook = s("chrono.settings.webhook", "Webhook Configuration")
            static let webhookDesc = s("chrono.settings.webhook.desc", "Receive push notifications from Git providers for instant deployments")
            static let webhookPort = s("chrono.settings.webhookPort", "Listen Port")
            static let webhookPortDesc = s("chrono.settings.webhookPort.desc", "Port for incoming webhook requests")

            // Feedback
            static let saved = s("chrono.settings.saved", "Settings saved")
            static let saveFailed = s("chrono.settings.saveFailed", "Failed to save settings")
        }

        // Errors
        static let errorNoResponse = s("chrono.error.noResponse", "No response from daemon")
        static let errorParseFailed = s("chrono.error.parseFailed", "Failed to parse response")
        static let errorApiNotListening = s("chrono.error.apiNotListening", "Daemon running but API not listening on port 9444 — check daemon logs")

        // Service
        static let serviceStart = s("chrono.service.start", "Start AXChrono")
        static let serviceStop = s("chrono.service.stop", "Stop AXChrono")
        static let serviceRestart = s("chrono.service.restart", "Restart AXChrono")

        // Dynamic
        static func deploysCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) deploys"
            return String(localized: "chrono.deploysCount", defaultValue: dv, table: table)
        }

        static func pendingCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) pending"
            return String(localized: "chrono.pendingCount", defaultValue: dv, table: table)
        }

        static func driftFiles(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) files changed on server"
            return String(localized: "chrono.driftFiles", defaultValue: dv, table: table)
        }
    }
}
