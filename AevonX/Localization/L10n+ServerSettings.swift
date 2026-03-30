import Foundation

extension L10n {

    // MARK: - Server Settings (ServerSettings.strings)
    enum ServerSettings {
        private static let table = "ServerSettings"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        // MARK: Connection State
        static let notConnected = s("ss.notConnected", "Not Connected")
        static let connectToManage = s("ss.connectToManage", "Connect to your server to manage settings, services, and resources.")

        // MARK: Hero
        static let publicIP = s("ss.publicIP", "Public IP")
        static let restartSSH = s("ss.restartSSH", "Restart SSH")
        static let checkUpdates = s("ss.checkUpdates", "Check Updates")
        static func upgrade(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Upgrade (\(count))"
            return String(localized: "ss.upgrade", defaultValue: dv, table: table)
        }

        // MARK: Server Info
        static let serverInfo = s("ss.serverInfo", "Server Info")
        static let systemDetails = s("ss.systemDetails", "System details")
        static let hostname = s("ss.hostname", "Hostname")
        static let os = s("ss.os", "OS")
        static let kernel = s("ss.kernel", "Kernel")
        static let architecture = s("ss.architecture", "Architecture")
        static let cpu = s("ss.cpu", "CPU")
        static let totalRAM = s("ss.totalRAM", "Total RAM")
        static let uptime = s("ss.uptime", "Uptime")
        static let timezone = s("ss.timezone", "Timezone")
        static let noPartitions = s("ss.noPartitions", "No partitions found")
        static let diskStorage = s("ss.diskStorage", "Disk & Storage")
        static let partitionUsage = s("ss.partitionUsage", "Partition usage")

        // MARK: Network Card
        static let network = s("ss.network", "Network")
        static let ipDNSConfig = s("ss.ipDNSConfig", "IP & DNS configuration")
        static let privateIP = s("ss.privateIP", "Private IP")
        static let gateway = s("ss.gateway", "Gateway")
        static let dnsServers = s("ss.dnsServers", "DNS Servers")

        // MARK: Connection Card
        static let connection = s("ss.connection", "Connection")
        static let sshConnectionDetails = s("ss.sshConnectionDetails", "SSH connection details")
        static let status = s("ss.status", "Status")

        // MARK: System Card
        static let system = s("ss.system", "System")
        static let swapMemory = s("ss.swapMemory", "Swap Memory")

        // MARK: SSH Security
        static let sshSecurity = s("ss.sshSecurity", "SSH Security")
        static let sshdConfigMgmt = s("ss.sshdConfigMgmt", "sshd_config management")
        static let sshPort = s("ss.sshPort", "SSH Port")
        static let permitRootLogin = s("ss.permitRootLogin", "Permit Root Login")
        static let passwordAuth = s("ss.passwordAuth", "Password Auth")
        static let maxAuthTries = s("ss.maxAuthTries", "Max Auth Tries")
        static let authorizedKeys = s("ss.authorizedKeys", "Authorized Keys")
        static let saveReloadSSH = s("ss.saveReloadSSH", "Save & Reload SSH")

        // MARK: SSH Security Audit
        static let sshSecurityAudit = s("ss.sshSecurityAudit", "SSH Security Audit")
        static let keysLoginsHardening = s("ss.keysLoginsHardening", "Keys, logins, and hardening")
        static let noIssuesFound = s("ss.noIssuesFound", "No issues found")
        static let x11Forwarding = s("ss.x11Forwarding", "X11Forwarding")
        static let allowUsers = s("ss.allowUsers", "AllowUsers")
        static func securityScore(_ score: Int) -> String {
            let dv: String.LocalizationValue = "Security Score: \(score)/100"
            return String(localized: "ss.securityScore", defaultValue: dv, table: table)
        }

        // MARK: SSH Keys
        static let hostKeyFingerprints = s("ss.hostKeyFingerprints", "Host Key Fingerprints")
        static let noHostKeys = s("ss.noHostKeys", "No host keys found")
        static let pastePublicKey = s("ss.pastePublicKey", "Paste public key (ssh-rsa ...)")
        static func authorizedKeysCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Authorized Keys (\(count))"
            return String(localized: "ss.authorizedKeysCount", defaultValue: dv, table: table)
        }
        static func bits(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) bits"
            return String(localized: "ss.bits", defaultValue: dv, table: table)
        }

        // MARK: SSH Logins
        static let showingLast10 = s("ss.showingLast10", "showing last 10")
        static let noFailedLogins = s("ss.noFailedLogins", "No failed logins detected")
        static let recentLogins = s("ss.recentLogins", "Recent Logins")
        static let noRecentLogins = s("ss.noRecentLogins", "No recent logins")
        static func failedLogins(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Failed Logins (\(count))"
            return String(localized: "ss.failedLogins", defaultValue: dv, table: table)
        }

        // MARK: Firewall
        static let firewall = s("ss.firewall", "Firewall")
        static let notDetected = s("ss.notDetected", "Not detected")
        static let noFirewallDetected = s("ss.noFirewallDetected", "No firewall detected (ufw, firewalld, or iptables)")
        static let addRule = s("ss.addRule", "Add Rule")
        static let tcp = s("ss.tcp", "TCP")
        static let udp = s("ss.udp", "UDP")
        static let allow = s("ss.allow", "Allow")
        static let deny = s("ss.deny", "Deny")
        static let ssh = s("ss.ssh", "SSH")
        static let http = s("ss.http", "HTTP")
        static let https = s("ss.https", "HTTPS")
        static let blockIPPlaceholder = s("ss.blockIPPlaceholder", "Block IP address...")
        static let block = s("ss.block", "Block")
        static let noRulesConfigured = s("ss.noRulesConfigured", "No rules configured")
        static let action = s("ss.action", "Action")
        static let proto = s("ss.proto", "Proto")
        static let source = s("ss.source", "Source")
        static func rulesCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Rules (\(count))"
            return String(localized: "ss.rulesCount", defaultValue: dv, table: table)
        }

        // MARK: Fail2Ban
        static let fail2ban = s("ss.fail2ban", "Fail2Ban")
        static let notInstalled = s("ss.notInstalled", "Not installed")
        static let fail2banNotInstalled = s("ss.fail2banNotInstalled", "Fail2Ban is not installed")
        static let installFail2banDesc = s("ss.installFail2banDesc", "Install it to protect against brute-force attacks")
        static let noJailsConfigured = s("ss.noJailsConfigured", "No jails configured")
        static let banned = s("ss.banned", "Banned")
        static let totalBanned = s("ss.totalBanned", "Total Banned")
        static let totalFailed = s("ss.totalFailed", "Total Failed")
        static let currentlyBanned = s("ss.currentlyBanned", "Currently Banned:")
        static let unban = s("ss.unban", "Unban")
        static let banLog = s("ss.banLog", "Ban Log")
        static let last20Entries = s("ss.last20Entries", "last 20 entries")
        static let noBanLogEntries = s("ss.noBanLogEntries", "No ban log entries")
        static func jailsCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) jails"
            return String(localized: "ss.jailsCount", defaultValue: dv, table: table)
        }

        // MARK: Network Management
        static let networkConnections = s("ss.networkConnections", "Network & Connections")
        static let interfaces = s("ss.interfaces", "Interfaces")
        static let listeningPorts = s("ss.listeningPorts", "Listening Ports")
        static let filterPlaceholder = s("ss.filterPlaceholder", "Filter...")
        static let noPortsMatch = s("ss.noPortsMatch", "No ports match search")
        static let activeConnections = s("ss.activeConnections", "Active Connections")
        static let noActiveConnections = s("ss.noActiveConnections", "No active connections")
        static let local = s("ss.local", "Local")
        static let remoteAddress = s("ss.remoteAddress", "Remote Address")
        static let process = s("ss.process", "Process")
        static let routingTable = s("ss.routingTable", "Routing Table")
        static let noRoutesFound = s("ss.noRoutesFound", "No routes found")
        static let destination = s("ss.destination", "Destination")
        static let interfaceCol = s("ss.interfaceCol", "Interface")
        static let flags = s("ss.flags", "Flags")
        static let dnsConfiguration = s("ss.dnsConfiguration", "DNS Configuration")
        static let hostsFile = s("ss.hostsFile", "Hosts File")
        static let socketStatistics = s("ss.socketStatistics", "Socket Statistics")
        static func interfacesPortsSummary(_ ifaces: Int, _ ports: Int) -> String {
            let dv: String.LocalizationValue = "\(ifaces) interfaces · \(ports) ports"
            return String(localized: "ss.interfacesPortsSummary", defaultValue: dv, table: table)
        }
        static func portNum(_ port: Int) -> String {
            let dv: String.LocalizationValue = "Port \(port)"
            return String(localized: "ss.portNum", defaultValue: dv, table: table)
        }
        static func moreConnections(_ count: Int) -> String {
            let dv: String.LocalizationValue = "+ \(count) more"
            return String(localized: "ss.moreConnections", defaultValue: dv, table: table)
        }
        static func pidLabel(_ pid: String) -> String {
            let dv: String.LocalizationValue = "PID \(pid)"
            return String(localized: "ss.pidLabel", defaultValue: dv, table: table)
        }

        // MARK: Resource Monitor
        static let resourceMonitor = s("ss.resourceMonitor", "Resource Monitor")
        static let realTimeMetrics = s("ss.realTimeMetrics", "Real-time server metrics")
        static let off = s("ss.off", "Off")
        static let ram = s("ss.ram", "RAM")
        static let swap = s("ss.swap", "Swap")
        static let load = s("ss.load", "Load")
        static let ioWait = s("ss.ioWait", "IO Wait")
        static let diskLatency = s("ss.diskLatency", "disk latency")
        static let processes = s("ss.processes", "Processes")
        static let networkLabel = s("ss.networkLabel", "Network")
        static let temp = s("ss.temp", "Temp")
        static let normal = s("ss.normal", "Normal")
        static let warm = s("ss.warm", "Warm")
        static let hot = s("ss.hot", "Hot")
        static let diskIO = s("ss.diskIO", "Disk I/O")
        static let sectors = s("ss.sectors", "sectors")
        static let total = s("ss.total", "total")
        static let topProcesses = s("ss.topProcesses", "Top Processes")
        static let pid = s("ss.pid", "PID")
        static let cpuPercent = s("ss.cpuPercent", "CPU%")
        static let memPercent = s("ss.memPercent", "MEM%")
        static let command = s("ss.command", "Command")
        static let diskUsage = s("ss.diskUsage", "Disk Usage")
        static let coresLabel = s("ss.coresLabel", "Cores")
        static func cores(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) cores"
            return String(localized: "ss.cores", defaultValue: dv, table: table)
        }
        static func inodePercent(_ pct: Int) -> String {
            let dv: String.LocalizationValue = "Inode: \(pct)%"
            return String(localized: "ss.inodePercent", defaultValue: dv, table: table)
        }

        // MARK: User Management
        static let userManagement = s("ss.userManagement", "User Management")
        static let systemUsersAccess = s("ss.systemUsersAccess", "System users & access")
        static let advancedUsers = s("ss.advancedUsers", "Advanced Users")
        static let noActiveSessions = s("ss.noActiveSessions", "No active sessions")
        static let groupsSudo = s("ss.groupsSudo", "Groups & Sudo")
        static let sudoUsers = s("ss.sudoUsers", "Sudo users:")
        static let newGroupPlaceholder = s("ss.newGroupPlaceholder", "New group name")
        static let passwordStatus = s("ss.passwordStatus", "Password Status")
        static let noPasswordData = s("ss.noPasswordData", "No password data")
        static let unlock = s("ss.unlock", "Unlock")
        static let lock = s("ss.lock", "Lock")
        static let revokeSudo = s("ss.revokeSudo", "Revoke sudo")
        static let grantSudo = s("ss.grantSudo", "Grant sudo")
        static let diskUsagePerUser = s("ss.diskUsagePerUser", "Disk Usage per User")
        static let noDiskUsageData = s("ss.noDiskUsageData", "No disk usage data")
        static let loginHistory = s("ss.loginHistory", "Login History")
        static let noLoginHistory = s("ss.noLoginHistory", "No login history")
        static func activeSessions(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Active Sessions (\(count))"
            return String(localized: "ss.activeSessions", defaultValue: dv, table: table)
        }
        static func sessionsGroupsSummary(_ sessions: Int, _ groups: Int) -> String {
            let dv: String.LocalizationValue = "\(sessions) sessions · \(groups) groups"
            return String(localized: "ss.sessionsGroupsSummary", defaultValue: dv, table: table)
        }
        static func uidLabel(_ uid: Int) -> String {
            let dv: String.LocalizationValue = "UID:\(uid)"
            return String(localized: "ss.uidLabel", defaultValue: dv, table: table)
        }
        static func gidLabel(_ gid: Int) -> String {
            let dv: String.LocalizationValue = "GID:\(gid)"
            return String(localized: "ss.gidLabel", defaultValue: dv, table: table)
        }
        static func changedDate(_ date: String) -> String {
            let dv: String.LocalizationValue = "Changed: \(date)"
            return String(localized: "ss.changedDate", defaultValue: dv, table: table)
        }

        // MARK: Services
        static let services = s("ss.services", "Services")
        static let searchServicesPlaceholder = s("ss.searchServicesPlaceholder", "Search services...")
        static let noServicesMatch = s("ss.noServicesMatch", "No services match filter")
        static let serviceLogs = s("ss.serviceLogs", "Service Logs")
        static let lines = s("ss.lines", "Lines")
        static let noLogsAvailable = s("ss.noLogsAvailable", "No logs available")
        static func servicesCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) services"
            return String(localized: "ss.servicesCount", defaultValue: dv, table: table)
        }
        static func serviceLogsTitle(_ name: String) -> String {
            let dv: String.LocalizationValue = "Service Logs: \(name)"
            return String(localized: "ss.serviceLogsTitle", defaultValue: dv, table: table)
        }

        // MARK: Password Management
        static let passwordManagement = s("ss.passwordManagement", "Password Management")
        static let changePasswords = s("ss.changePasswords", "Change system & database passwords")
        static let rootPassword = s("ss.rootPassword", "Root Password")
        static let linuxRootUser = s("ss.linuxRootUser", "Linux root user")
        static let mysqlRoot = s("ss.mysqlRoot", "MySQL Root")
        static let mysqlRootDesc = s("ss.mysqlRootDesc", "MySQL database root user")
        static let postgresql = s("ss.postgresql", "PostgreSQL")
        static let postgresqlDesc = s("ss.postgresqlDesc", "PostgreSQL postgres user")
        static let newPassword = s("ss.newPassword", "New Password")
        static let confirmPassword = s("ss.confirmPassword", "Confirm")

        // MARK: System Control
        static let systemControl = s("ss.systemControl", "System Control")
        static let hardwareSystem = s("ss.hardwareSystem", "Hardware & System")
        static let totalDisk = s("ss.totalDisk", "Total Disk")
        static let virtualization = s("ss.virtualization", "Virtualization")
        static let securityModule = s("ss.securityModule", "Security Module:")
        static let none = s("ss.none", "None")
        static let rebootRequired = s("ss.rebootRequired", "Reboot Required")
        static let powerControl = s("ss.powerControl", "Power Control")
        static let reboot = s("ss.reboot", "Reboot")
        static let shutdown = s("ss.shutdown", "Shutdown")
        static let min = s("ss.min", "min")
        static let schedule = s("ss.schedule", "Schedule")
        static let confirmReboot = s("ss.confirmReboot", "Are you sure you want to reboot?")
        static let confirmShutdown = s("ss.confirmShutdown", "Are you sure you want to shutdown?")
        static let noSwapConfigured = s("ss.noSwapConfigured", "No swap configured")
        static let sizeMB = s("ss.sizeMB", "Size (MB)")
        static let mb = s("ss.mb", "MB")
        static let resizeSwap = s("ss.resizeSwap", "Resize Swap")
        static let disableSwap = s("ss.disableSwap", "Disable Swap")
        static func sizeValue(_ size: String) -> String {
            let dv: String.LocalizationValue = "Size: \(size)"
            return String(localized: "ss.sizeValue", defaultValue: dv, table: table)
        }
        static func usedValue(_ used: String) -> String {
            let dv: String.LocalizationValue = "Used: \(used)"
            return String(localized: "ss.usedValue", defaultValue: dv, table: table)
        }
        static let kernelParameters = s("ss.kernelParameters", "Kernel Parameters")
        static let noKernelParams = s("ss.noKernelParams", "No kernel parameters loaded")
        static func scheduled(_ time: String) -> String {
            let dv: String.LocalizationValue = "Scheduled: \(time)"
            return String(localized: "ss.scheduled", defaultValue: dv, table: table)
        }

        // MARK: Updates
        static let systemUpdates = s("ss.systemUpdates", "System Updates")
        static let packageUpdates = s("ss.packageUpdates", "Package updates & security patches")
        static let checkForUpdates = s("ss.checkForUpdates", "Check for Updates")
        static let checkForUpdatesDesc = s("ss.checkForUpdatesDesc", "Scan your server for available package updates and security patches.")
        static let checkNow = s("ss.checkNow", "Check Now")
        static let checkingUpdates = s("ss.checkingUpdates", "Checking for updates...")
        static let upToDate = s("ss.upToDate", "Up to date")
        static let sec = s("ss.sec", "SEC")
        static let update = s("ss.update", "Update")
        static func securityCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) Security"
            return String(localized: "ss.securityCount", defaultValue: dv, table: table)
        }
        static func totalCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) Total"
            return String(localized: "ss.totalCount", defaultValue: dv, table: table)
        }
        static func securityOnly(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Security Only (\(count))"
            return String(localized: "ss.securityOnly", defaultValue: dv, table: table)
        }
        static func updateAll(_ count: Int) -> String {
            let dv: String.LocalizationValue = "Update All (\(count))"
            return String(localized: "ss.updateAll", defaultValue: dv, table: table)
        }
        static func morePackages(_ count: Int) -> String {
            let dv: String.LocalizationValue = "+ \(count) more packages"
            return String(localized: "ss.morePackages", defaultValue: dv, table: table)
        }

        // MARK: System Logs
        static let systemLogs = s("ss.systemLogs", "System Logs")
        static let sourcePicker = s("ss.sourcePicker", "Source")
        static let priorityPicker = s("ss.priorityPicker", "Priority")
        static let servicePlaceholder = s("ss.servicePlaceholder", "Service...")
        static let searchPlaceholder = s("ss.searchPlaceholder", "Search...")
        static let query = s("ss.query", "Query")
        static let noLogEntries = s("ss.noLogEntries", "No log entries")
        static let logFileSizes = s("ss.logFileSizes", "Log File Sizes")
        static let rotateAll = s("ss.rotateAll", "Rotate All")
        static func logFilesCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) log files"
            return String(localized: "ss.logFilesCount", defaultValue: dv, table: table)
        }

        // MARK: Log Priority Labels
        static let priorityAll = s("ss.priorityAll", "All")
        static let priorityError = s("ss.priorityError", "Error")
        static let priorityWarning = s("ss.priorityWarning", "Warning")
        static let priorityInfo = s("ss.priorityInfo", "Info")
        static let priorityDebug = s("ss.priorityDebug", "Debug")

        // MARK: Cron Jobs
        static let cronJobs = s("ss.cronJobs", "Cron Jobs")
        static let noCronJobs = s("ss.noCronJobs", "No cron jobs found")
        static let addCronJob = s("ss.addCronJob", "Add Cron Job")
        static let user = s("ss.user", "User")
        static let commandPlaceholder = s("ss.commandPlaceholder", "Command...")
        static let templates = s("ss.templates", "Templates:")
        static let everyHour = s("ss.everyHour", "Every hour")
        static let daily3AM = s("ss.daily3AM", "Daily 3AM")
        static let weeklySun = s("ss.weeklySun", "Weekly Sun")
        static let monthly1st = s("ss.monthly1st", "Monthly 1st")
        static let cronLog = s("ss.cronLog", "Cron Log")
        static let noCronLogEntries = s("ss.noCronLogEntries", "No cron log entries")
        static func cronJobsCount(_ count: Int) -> String {
            let dv: String.LocalizationValue = "\(count) jobs"
            return String(localized: "ss.cronJobsCount", defaultValue: dv, table: table)
        }

        // MARK: Danger Zone
        static let dangerZone = s("ss.dangerZone", "Danger Zone")
        static let destructiveActions = s("ss.destructiveActions", "Destructive actions")
        static let removeServer = s("ss.removeServer", "Remove Server")
        static let removeServerDesc = s("ss.removeServerDesc", "Permanently remove from your fleet")
        static let removeServerTitle = s("ss.removeServerTitle", "Remove Server?")
        static let removeServerWarning = s("ss.removeServerWarning", "This will permanently remove the server from your fleet. This cannot be undone.")
        static let deleteUserTitle = s("ss.deleteUserTitle", "Delete System User?")
        static let deleteUserWarning = s("ss.deleteUserWarning", "This will remove the system user and may affect running services.")

        // MARK: Messages
        static let logCleared = s("ss.logCleared", "Log cleared")
        static let logClearFailed = s("ss.logClearFailed", "Failed to clear log")
        static let cronJobAdded = s("ss.cronJobAdded", "Cron job added")
        static let cronJobAddFailed = s("ss.cronJobAddFailed", "Failed to add cron job")
        static let cronJobDeleted = s("ss.cronJobDeleted", "Cron job deleted")
        static let cronJobDeleteFailed = s("ss.cronJobDeleteFailed", "Failed to delete cron job")
        static let keyAdded = s("ss.keyAdded", "Key added")
        static let keyAddFailed = s("ss.keyAddFailed", "Failed to add key")
        static let keyRemoved = s("ss.keyRemoved", "Key removed")
        static let keyRemoveFailed = s("ss.keyRemoveFailed", "Failed to remove key")
        static let firewallDisabled = s("ss.firewallDisabled", "Firewall disabled")
        static let firewallEnabled = s("ss.firewallEnabled", "Firewall enabled")
        static let firewallToggleFailed = s("ss.firewallToggleFailed", "Failed to toggle firewall")
        static let ruleAdded = s("ss.ruleAdded", "Rule added")
        static let ruleAddFailed = s("ss.ruleAddFailed", "Failed to add rule")
        static let ruleDeleted = s("ss.ruleDeleted", "Rule deleted")
        static let ruleDeleteFailed = s("ss.ruleDeleteFailed", "Failed to delete rule")
        static let ipBlocked = s("ss.ipBlocked", "IP blocked")
        static let ipBlockFailed = s("ss.ipBlockFailed", "Failed to block IP")
        static let ipUnblocked = s("ss.ipUnblocked", "IP unblocked")
        static let ipUnblockFailed = s("ss.ipUnblockFailed", "Failed to unblock IP")
        static let ipUnbanned = s("ss.ipUnbanned", "IP unbanned")
        static let ipUnbanFailed = s("ss.ipUnbanFailed", "Failed to unban IP")

        // User Management Messages
        static let sessionTerminated = s("ss.sessionTerminated", "Session terminated")
        static let sessionTerminateFailed = s("ss.sessionTerminateFailed", "Failed to kill session")
        static let groupCreated = s("ss.groupCreated", "Group created")
        static let groupCreateFailed = s("ss.groupCreateFailed", "Failed to create group")
        static let groupDeleted = s("ss.groupDeleted", "Group deleted")
        static let groupDeleteFailed = s("ss.groupDeleteFailed", "Failed to delete group")
        static let userAddedToGroup = s("ss.userAddedToGroup", "User added to group")
        static let userAddToGroupFailed = s("ss.userAddToGroupFailed", "Failed to add user to group")
        static let userRemovedFromGroup = s("ss.userRemovedFromGroup", "User removed from group")
        static let userRemoveFromGroupFailed = s("ss.userRemoveFromGroupFailed", "Failed to remove user from group")
        static let sudoGranted = s("ss.sudoGranted", "Sudo granted")
        static let sudoGrantFailed = s("ss.sudoGrantFailed", "Failed to grant sudo")
        static let sudoRevoked = s("ss.sudoRevoked", "Sudo revoked")
        static let sudoRevokeFailed = s("ss.sudoRevokeFailed", "Failed to revoke sudo")
        static let shellChanged = s("ss.shellChanged", "Shell changed")
        static let shellChangeFailed = s("ss.shellChangeFailed", "Failed to change shell")
        static let userLocked = s("ss.userLocked", "User locked")
        static let userLockFailed = s("ss.userLockFailed", "Failed to lock user")
        static let userUnlocked = s("ss.userUnlocked", "User unlocked")
        static let userUnlockFailed = s("ss.userUnlockFailed", "Failed to unlock user")

        // System Control Messages
        static let rebootInitiated = s("ss.rebootInitiated", "Reboot initiated")
        static let shutdownInitiated = s("ss.shutdownInitiated", "Shutdown initiated")
        static let rebootScheduled = s("ss.rebootScheduled", "Reboot scheduled")
        static let rebootScheduleFailed = s("ss.rebootScheduleFailed", "Failed to schedule reboot")
        static let rebootCancelled = s("ss.rebootCancelled", "Scheduled reboot cancelled")
        static let rebootCancelFailed = s("ss.rebootCancelFailed", "Failed to cancel reboot")
        static let swapResized = s("ss.swapResized", "Swap resized")
        static let swapResizeFailed = s("ss.swapResizeFailed", "Failed to resize swap")
        static let paramUpdated = s("ss.paramUpdated", "Parameter updated")
        static let paramUpdateFailed = s("ss.paramUpdateFailed", "Failed to update parameter")
    }
}
