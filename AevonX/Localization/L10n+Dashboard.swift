import Foundation

extension L10n {

    // MARK: - Dashboard (Dashboard.strings)
    enum Dashboard {
        private static let table = "Dashboard"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let connectionError = s("dashboard.connectionError", "Connection Error")

        static func appInstallFailed(_ app: String, _ version: String) -> String {
            let dv: String.LocalizationValue = "Failed to install \(app) \(version)"
            return String(localized: "dashboard.appInstallFailed", defaultValue: dv, table: table)
        }
        static let load = s("dashboard.load", "Load")
        static let realTime = s("dashboard.realTime", "Real-time")
        static let disk = s("dashboard.disk", "Disk")
        static let total = s("dashboard.total", "Total")
        static let mount = s("dashboard.mount", "Mount")
        static let diskDetail = s("dashboard.diskDetail", "Disk Detail")
        static let loadAverage = s("dashboard.loadAverage", "Load Average")
        static let overview = s("dashboard.overview", "Overview")
        static let systemInfo = s("dashboard.systemInfo", "System Info")
        static let uptime = s("dashboard.uptime", "Uptime")
        static let quickActions = s("dashboard.quickActions", "Quick Actions")
        static let cpuDetail = s("dashboard.cpuDetail", "CPU Detail")
        static let samplingCores = s("dashboard.samplingCores", "Sampling cores…")
        static let noCoreData = s("dashboard.noCoreData", "No core data")
        static let ramDetail = s("dashboard.ramDetail", "RAM Detail")
        static let networkTraffic = s("dashboard.networkTraffic", "Network Traffic")
        static let sinceBoot = s("dashboard.sinceBoot", "Since boot")
        static let download = s("dashboard.download", "Download")
        static let upload = s("dashboard.upload", "Upload")
        static let networkIO = s("dashboard.networkIO", "Network I/O")
        static let serverLoad = s("dashboard.serverLoad", "Server Load")
        static let totalProcs = s("dashboard.totalProcs", "Total procs")
        static let running = s("dashboard.running", "Running")
        static let swap = s("dashboard.swap", "Swap")
        static let areYouSureYouWantToDisconnectFromThisServer = s("dashboard.areYouSureYouWantToDisconnectFromThisServer", "Are you sure you want to disconnect from this server?")
        static let freshServerDetected = s("dashboard.freshServerDetected", "Fresh server detected")
        static let noServicesFoundSetUpYourEnvironmentWithOneClick = s("dashboard.noServicesFoundSetUpYourEnvironmentWithOneClick", "No services found — set up your environment with one click")
        static let setupServer = s("dashboard.setupServer", "Setup Server")
        static let unsavedChanges = s("dashboard.unsavedChanges", "Unsaved changes")
        static let areYouSureYouWantToClearAllLogFilesForThisSourceThisActionCannotBeUndone = s("dashboard.areYouSureYouWantToClearAllLogFilesForThisSourceThisActionCannotBeUndone", "Are you sure you want to clear all log files for this source? This action cannot be undone.")
        static let time = s("dashboard.time", "Time")
        static let ipAddress = s("dashboard.ipAddress", "IP Address")
        static let method = s("dashboard.method", "Method")
        static let loadingLogs = s("dashboard.loadingLogs", "Loading logs...")
        static let noLogsFound = s("dashboard.noLogsFound", "No Logs Found")
        static let blockIpAddress = s("dashboard.blockIpAddress", "Block IP Address")
        static let duration = s("dashboard.duration", "Duration")
        static let reasonOptional = s("dashboard.reasonOptional", "Reason (Optional)")
        static let blockIp = s("dashboard.blockIp", "Block IP")
        static let logDetails = s("dashboard.logDetails", "Log Details")
        static let aiAnalysis = s("dashboard.aiAnalysis", "AI Analysis")
        static let servers = s("dashboard.servers", "Servers")
        static let preparingInstallation = s("dashboard.preparingInstallation", "Preparing installation...")
        static let minimize = s("dashboard.minimize", "Minimize")
        static let quickInstall = s("dashboard.quickInstall", "Quick Install")
        static let setUpYourServerEnvironmentInOneStep = s("dashboard.setUpYourServerEnvironmentInOneStep", "Set up your server environment in one step")
        static let scanning = s("dashboard.scanning", "Scanning...")
        static let quickPresets = s("dashboard.quickPresets", "QUICK PRESETS")
        static let selectPackagesAboveToBegin = s("dashboard.selectPackagesAboveToBegin", "Select packages above to begin")
        static let version = s("dashboard.version", "Version")
        static let live = s("dashboard.live", "Live")
        static let error = s("dashboard.error", "Error")
        static let hostname = s("dashboard.hostname", "Hostname")
        static let timezone = s("dashboard.timezone", "Timezone")
        static let noConnectionAvailable = s("dashboard.noConnectionAvailable", "No connection available")
    }
}
