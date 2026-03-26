import Foundation

extension L10n {

    // MARK: - Docker (Docker.strings)
    enum Docker {
        private static let table = "Docker"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        // Container Actions
        static let newContainer = s("docker.newContainer", "New Container")
        static let deployTemplate = s("docker.deployTemplate", "Deploy Template")
        static let viewLogs = s("docker.viewLogs", "View Logs")
        static let openTerminal = s("docker.openTerminal", "Open Terminal")
        static let inspect = s("docker.inspect", "Inspect")
        static let rollback = s("docker.rollback", "Rollback")
        static let clone = s("docker.clone", "Clone")
        static let backup = s("docker.backup", "Backup")

        // Security
        static let securityAudit = s("docker.securityAudit", "Security Audit")
        static let autoUpdate = s("docker.autoUpdate", "Auto Update")
        static let vulnScan = s("docker.vulnScan", "Image Vulnerability Scan")

        // Resources
        static let memoryLimit = s("docker.memoryLimit", "Memory Limit (MB)")
        static let cpuLimit = s("docker.cpuLimit", "CPU Limit (cores)")

        // Tools
        static let containerScheduler = s("docker.containerScheduler", "Container Scheduler")
        static let secretsManager = s("docker.secretsManager", "Secrets Manager")
        static let runToCompose = s("docker.runToCompose", "Run → Compose Converter")

        // Compose
        static let composeUp = s("docker.composeUp", "Up")
        static let composeDown = s("docker.composeDown", "Down")
        static let composeRestart = s("docker.composeRestart", "Restart")
        static let composeLogs = s("docker.composeLogs", "Logs")
        static let composeValidate = s("docker.composeValidate", "Validate")
        static let composeScale = s("docker.composeScale", "Scale")

        // Networks
        static let inspectNetwork = s("docker.inspectNetwork", "Inspect Network")
        static let removeNetwork = s("docker.removeNetwork", "Remove Network")
        static let createNetwork = s("docker.createNetwork", "Create")

        // Images
        static let pullImage = s("docker.pullImage", "Pull")
        static let viewLayers = s("docker.viewLayers", "View Layers")
        static let tagPush = s("docker.tagPush", "Tag & Push")
        static let removeImage = s("docker.removeImage", "Remove Image")

        // Volumes
        static let removeVolume = s("docker.removeVolume", "Remove Volume")
        static let createVolume = s("docker.createVolume", "Create")
    }
}
