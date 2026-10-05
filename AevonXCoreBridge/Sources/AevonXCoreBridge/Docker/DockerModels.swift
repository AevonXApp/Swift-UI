//
//  DockerModels.swift
//  AevonXCoreBridge
//
//  All Docker model types for the Bridge layer.
//  Replaces AevonXCore Docker models for cross-platform usage.
//

import Foundation

// MARK: - Service Status

public enum ServiceStatus: String, Codable, Sendable {
    case active
    case inactive
    case failed
    case unknown
}

// MARK: - Docker Error

public enum DockerError: LocalizedError {
    case commandFailed(String, String)
    case parsingFailed(String)
    case featureLocked(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let error):
            return "Command failed: \(command) — \(error)"
        case .parsingFailed(let detail):
            return "Parsing failed: \(detail)"
        case .featureLocked(let feature):
            return "This feature requires a Pro subscription: \(feature)"
        }
    }
}

// MARK: - Core Models (from DockerModels.swift)

public struct DockerContainer: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public let image: String
    public let command: String
    public let created: String
    public let status: String
    public let ports: String
    public let names: String

    public init(id: String, image: String, command: String, created: String, status: String, ports: String, names: String) {
        self.id = id
        self.image = image
        self.command = command
        self.created = created
        self.status = status
        self.ports = ports
        self.names = names
    }

    public var isRunning: Bool {
        status.lowercased().contains("up")
    }

    public var isPaused: Bool {
        status.lowercased().contains("paused")
    }

    public var shortId: String {
        String(id.prefix(12))
    }
}

public struct DockerImage: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public let repository: String
    public let tag: String
    public let created: String
    public let size: String

    public init(id: String, repository: String, tag: String, created: String, size: String) {
        self.id = id
        self.repository = repository
        self.tag = tag
        self.created = created
        self.size = size
    }

    public var shortId: String {
        String(id.prefix(12))
    }
}

public struct DockerVolume: Identifiable, Codable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let driver: String
    public let mountpoint: String

    public init(name: String, driver: String, mountpoint: String) {
        self.name = name
        self.driver = driver
        self.mountpoint = mountpoint
    }
}

public struct DockerInfo: Codable, Sendable {
    public let serverVersion: String
    public let containers: Int?
    public let containersRunning: Int?
    public let containersPaused: Int?
    public let containersStopped: Int?
    public let images: Int?
    public let driver: String?
    public let memoryLimit: Bool?
    public let swapLimit: Bool?
    public let cpuCfsPeriod: Bool?
    public let cpuCfsQuota: Bool?
    public let oomKillDisable: Bool?
    public let ipv4Forwarding: Bool?
    public let bridgeNfIptables: Bool?
    public let bridgeNfIp6tables: Bool?
    public let debug: Bool?
    public let nfd: Int?
    public let oomScoreAdj: Int?
    public let loggingDriver: String?
    public let cgroupDriver: String?
    public let nEventsListener: Int?
    public let kernelVersion: String?
    public let operatingSystem: String?
    public let osType: String?
    public let architecture: String?
    public let ncpu: Int?
    public let memTotal: Int64?
    public let dockerRootDir: String?

    public init(
        serverVersion: String, containers: Int? = nil, containersRunning: Int? = nil,
        containersPaused: Int? = nil, containersStopped: Int? = nil, images: Int? = nil,
        driver: String? = nil, memoryLimit: Bool? = nil, swapLimit: Bool? = nil,
        cpuCfsPeriod: Bool? = nil, cpuCfsQuota: Bool? = nil, oomKillDisable: Bool? = nil,
        ipv4Forwarding: Bool? = nil, bridgeNfIptables: Bool? = nil, bridgeNfIp6tables: Bool? = nil,
        debug: Bool? = nil, nfd: Int? = nil, oomScoreAdj: Int? = nil,
        loggingDriver: String? = nil, cgroupDriver: String? = nil, nEventsListener: Int? = nil,
        kernelVersion: String? = nil, operatingSystem: String? = nil, osType: String? = nil,
        architecture: String? = nil, ncpu: Int? = nil, memTotal: Int64? = nil,
        dockerRootDir: String? = nil
    ) {
        self.serverVersion = serverVersion
        self.containers = containers
        self.containersRunning = containersRunning
        self.containersPaused = containersPaused
        self.containersStopped = containersStopped
        self.images = images
        self.driver = driver
        self.memoryLimit = memoryLimit
        self.swapLimit = swapLimit
        self.cpuCfsPeriod = cpuCfsPeriod
        self.cpuCfsQuota = cpuCfsQuota
        self.oomKillDisable = oomKillDisable
        self.ipv4Forwarding = ipv4Forwarding
        self.bridgeNfIptables = bridgeNfIptables
        self.bridgeNfIp6tables = bridgeNfIp6tables
        self.debug = debug
        self.nfd = nfd
        self.oomScoreAdj = oomScoreAdj
        self.loggingDriver = loggingDriver
        self.cgroupDriver = cgroupDriver
        self.nEventsListener = nEventsListener
        self.kernelVersion = kernelVersion
        self.operatingSystem = operatingSystem
        self.osType = osType
        self.architecture = architecture
        self.ncpu = ncpu
        self.memTotal = memTotal
        self.dockerRootDir = dockerRootDir
    }
}

public struct DockerNetwork: Identifiable, Codable, Hashable, Sendable {
    public var id: String { networkId }
    public let networkId: String
    public let name: String
    public let driver: String
    public let scope: String
    public let created: String
    public let ipv6: Bool
    public let internalNetwork: Bool

    public init(networkId: String, name: String, driver: String, scope: String, created: String, ipv6: Bool, internalNetwork: Bool) {
        self.networkId = networkId
        self.name = name
        self.driver = driver
        self.scope = scope
        self.created = created
        self.ipv6 = ipv6
        self.internalNetwork = internalNetwork
    }
}

public struct DockerComposeProject: Identifiable, Codable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let status: String
    public let configFiles: String
    public let workingDir: String

    public init(name: String, status: String, configFiles: String, workingDir: String) {
        self.name = name
        self.status = status
        self.configFiles = configFiles
        self.workingDir = workingDir
    }
}

public enum RestartPolicy: String, CaseIterable, Identifiable, Codable, Sendable {
    case no = "no"
    case always = "always"
    case unlessStopped = "unless-stopped"
    case onFailure = "on-failure"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .no: return "No"
        case .always: return "Always"
        case .unlessStopped: return "Unless Stopped"
        case .onFailure: return "On Failure"
        }
    }
}

public struct PortMapping: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var hostPort: String
    public var containerPort: String
    public var proto: String

    public init(id: UUID = UUID(), hostPort: String = "", containerPort: String = "", proto: String = "tcp") {
        self.id = id; self.hostPort = hostPort; self.containerPort = containerPort; self.proto = proto
    }
}

public struct EnvVar: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var key: String
    public var value: String
    public var isSecret: Bool

    public init(id: UUID = UUID(), key: String = "", value: String = "", isSecret: Bool = false) {
        self.id = id; self.key = key; self.value = value; self.isSecret = isSecret
    }
}

public struct VolumeMount: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var hostPath: String
    public var containerPath: String
    public var readOnly: Bool

    public init(id: UUID = UUID(), hostPath: String = "", containerPath: String = "", readOnly: Bool = false) {
        self.id = id; self.hostPath = hostPath; self.containerPath = containerPath; self.readOnly = readOnly
    }
}

public struct ContainerConfig: Sendable {
    public var name: String
    public var image: String
    public var ports: [PortMapping]
    public var envVars: [EnvVar]
    public var volumes: [VolumeMount]
    public var restartPolicy: RestartPolicy
    public var network: String
    public var hostname: String
    public var workingDir: String
    public var entrypoint: String
    public var cmd: String
    public var user: String
    public var memoryLimitMB: Int
    public var cpuLimit: Double
    public var privileged: Bool
    public var labels: [String: String]
    public var healthCheckCmd: String

    public init(
        name: String = "", image: String = "", ports: [PortMapping] = [], envVars: [EnvVar] = [],
        volumes: [VolumeMount] = [], restartPolicy: RestartPolicy = .no, network: String = "",
        hostname: String = "", workingDir: String = "", entrypoint: String = "", cmd: String = "",
        user: String = "", memoryLimitMB: Int = 0, cpuLimit: Double = 0, privileged: Bool = false,
        labels: [String: String] = [:], healthCheckCmd: String = ""
    ) {
        self.name = name; self.image = image; self.ports = ports; self.envVars = envVars
        self.volumes = volumes; self.restartPolicy = restartPolicy; self.network = network
        self.hostname = hostname; self.workingDir = workingDir; self.entrypoint = entrypoint
        self.cmd = cmd; self.user = user; self.memoryLimitMB = memoryLimitMB
        self.cpuLimit = cpuLimit; self.privileged = privileged; self.labels = labels
        self.healthCheckCmd = healthCheckCmd
    }

    public func buildFlags() -> String {
        var flags = ["-d", "--name '\(name)'"]
        for p in ports where !p.hostPort.isEmpty && !p.containerPort.isEmpty {
            flags.append("-p \(p.hostPort):\(p.containerPort)/\(p.proto)")
        }
        for e in envVars where !e.key.isEmpty {
            let escaped = e.value.replacingOccurrences(of: "'", with: "'\\''")
            flags.append("-e '\(e.key)=\(escaped)'")
        }
        for v in volumes where !v.hostPath.isEmpty && !v.containerPath.isEmpty {
            flags.append("-v '\(v.hostPath):\(v.containerPath)\(v.readOnly ? ":ro" : "")'")
        }
        if restartPolicy != .no { flags.append("--restart=\(restartPolicy.rawValue)") }
        if !network.isEmpty { flags.append("--network '\(network)'") }
        if !hostname.isEmpty { flags.append("--hostname '\(hostname)'") }
        if !workingDir.isEmpty { flags.append("-w '\(workingDir)'") }
        if !entrypoint.isEmpty { flags.append("--entrypoint '\(entrypoint)'") }
        if !user.isEmpty { flags.append("--user '\(user)'") }
        if memoryLimitMB > 0 { flags.append("--memory \(memoryLimitMB)m") }
        if cpuLimit > 0 { flags.append("--cpus \(cpuLimit)") }
        if privileged { flags.append("--privileged") }
        for (k, v) in labels { flags.append("--label '\(k)=\(v)'") }
        if !healthCheckCmd.isEmpty { flags.append("--health-cmd '\(healthCheckCmd)'") }
        return flags.joined(separator: " ")
    }
}

public struct ContainerInspection: Sendable {
    public let envVars: [String]
    public let mounts: [InspectMount]
    public let networkSettings: [InspectNetwork]
    public let portBindings: [String]
    public let labels: [String: String]
    public let restartPolicy: String
    public let cpuShares: Int
    public let memory: Int64
    public let processes: [ContainerProcess]
    public let rawJSON: String

    public init(envVars: [String], mounts: [InspectMount], networkSettings: [InspectNetwork],
                portBindings: [String], labels: [String: String], restartPolicy: String,
                cpuShares: Int, memory: Int64, processes: [ContainerProcess], rawJSON: String) {
        self.envVars = envVars; self.mounts = mounts; self.networkSettings = networkSettings
        self.portBindings = portBindings; self.labels = labels; self.restartPolicy = restartPolicy
        self.cpuShares = cpuShares; self.memory = memory; self.processes = processes; self.rawJSON = rawJSON
    }
}

public struct InspectMount: Sendable {
    public let source: String
    public let destination: String
    public let mode: String
    public let type: String

    public init(source: String, destination: String, mode: String, type: String) {
        self.source = source; self.destination = destination; self.mode = mode; self.type = type
    }
}

public struct InspectNetwork: Sendable {
    public let name: String
    public let ipAddress: String
    public let gateway: String
    public let macAddress: String

    public init(name: String, ipAddress: String, gateway: String, macAddress: String) {
        self.name = name; self.ipAddress = ipAddress; self.gateway = gateway; self.macAddress = macAddress
    }
}

public struct ContainerProcess: Sendable {
    public let pid: String
    public let user: String
    public let command: String

    public init(pid: String, user: String, command: String) {
        self.pid = pid; self.user = user; self.command = command
    }
}

public struct ContainerStats: Sendable {
    public let cpuPercent: Double
    public let memUsageMB: Double
    public let memLimitMB: Double
    public let memPercent: Double
    public let netInputMB: Double
    public let netOutputMB: Double
    public let pids: Int

    public init(cpuPercent: Double = 0, memUsageMB: Double = 0, memLimitMB: Double = 0,
                memPercent: Double = 0, netInputMB: Double = 0, netOutputMB: Double = 0, pids: Int = 0) {
        self.cpuPercent = cpuPercent; self.memUsageMB = memUsageMB; self.memLimitMB = memLimitMB
        self.memPercent = memPercent; self.netInputMB = netInputMB; self.netOutputMB = netOutputMB
        self.pids = pids
    }
}

// MARK: - Extension Types (+Containers)

public struct ContainerLimits: Sendable {
    public let memoryMB: Int
    public let cpus: Double
    public let memorySwapMB: Int
    public let cpuShares: Int

    public init(memoryMB: Int, cpus: Double, memorySwapMB: Int, cpuShares: Int) {
        self.memoryMB = memoryMB; self.cpus = cpus; self.memorySwapMB = memorySwapMB; self.cpuShares = cpuShares
    }
}

public struct RestartPolicyInfo: Sendable {
    public let name: String
    public let maxRetries: Int

    public init(name: String, maxRetries: Int) {
        self.name = name; self.maxRetries = maxRetries
    }
}

public struct ContainerChange: Sendable {
    public let kind: String
    public let path: String

    public init(kind: String, path: String) {
        self.kind = kind; self.path = path
    }
}

public struct ContainerHealthInfo: Sendable {
    public let status: String
    public let failingStreak: Int
    public let lastOutput: String

    public init(status: String, failingStreak: Int, lastOutput: String) {
        self.status = status; self.failingStreak = failingStreak; self.lastOutput = lastOutput
    }
}

public struct ContainerFile: Sendable {
    public let name: String
    public let isDir: Bool
    public let size: String
    public let permissions: String
    public let modified: String

    public init(name: String, isDir: Bool, size: String, permissions: String, modified: String) {
        self.name = name; self.isDir = isDir; self.size = size; self.permissions = permissions; self.modified = modified
    }
}

public struct ContainerWaitResult: Sendable {
    public let statusCode: Int
    public let error: String?

    public init(statusCode: Int, error: String?) {
        self.statusCode = statusCode; self.error = error
    }
}

// MARK: - Extension Types (+Images)

public struct ImageLayer: Sendable {
    public let created: String
    public let createdBy: String
    public let size: String

    public init(created: String, createdBy: String, size: String) {
        self.created = created; self.createdBy = createdBy; self.size = size
    }
}

public struct HubSearchResult: Sendable {
    public let name: String
    public let description: String
    public let stars: Int
    public let isOfficial: Bool
    public let isAutomated: Bool

    public init(name: String, description: String, stars: Int, isOfficial: Bool, isAutomated: Bool) {
        self.name = name; self.description = description; self.stars = stars
        self.isOfficial = isOfficial; self.isAutomated = isAutomated
    }
}

public struct ImageUpdateInfo: Sendable {
    public let repository: String
    public let tag: String
    public let localDigest: String
    public let remoteDigest: String
    public let isOutdated: Bool

    public init(repository: String, tag: String, localDigest: String, remoteDigest: String, isOutdated: Bool) {
        self.repository = repository; self.tag = tag; self.localDigest = localDigest
        self.remoteDigest = remoteDigest; self.isOutdated = isOutdated
    }
}

// MARK: - Extension Types (+Compose)

public struct ComposeValidationResult: Sendable {
    public let isValid: Bool
    public let resolvedConfig: String?
    public let errorOutput: String?

    public init(isValid: Bool, resolvedConfig: String?, errorOutput: String?) {
        self.isValid = isValid; self.resolvedConfig = resolvedConfig; self.errorOutput = errorOutput
    }
}

public struct ComposeServiceInfo: Sendable {
    public let name: String
    public let replicas: Int

    public init(name: String, replicas: Int) {
        self.name = name; self.replicas = replicas
    }
}

public struct EnvEntry: Sendable {
    public let key: String
    public let value: String
    public let isSecret: Bool

    public init(key: String, value: String, isSecret: Bool) {
        self.key = key; self.value = value; self.isSecret = isSecret
    }
}

// MARK: - Extension Types (+Networks)

public struct NetworkInspection: Sendable {
    public let subnet: String
    public let gateway: String
    public let scope: String
    public let connectedContainers: [(name: String, ip: String, mac: String)]

    public init(subnet: String, gateway: String, scope: String, connectedContainers: [(name: String, ip: String, mac: String)]) {
        self.subnet = subnet; self.gateway = gateway; self.scope = scope; self.connectedContainers = connectedContainers
    }
}

public struct ContainerNetworkStats: Identifiable, Sendable {
    public var id: String { containerId }
    public let containerId: String
    public let containerName: String
    public let rxBytes: Int64
    public let txBytes: Int64

    public var rxFormatted: String { DockerFormatter.formatBytes(rxBytes) }
    public var txFormatted: String { DockerFormatter.formatBytes(txBytes) }

    public init(containerId: String, containerName: String, rxBytes: Int64, txBytes: Int64) {
        self.containerId = containerId; self.containerName = containerName
        self.rxBytes = rxBytes; self.txBytes = txBytes
    }
}

public struct AggregatedLogEntry: Identifiable, Sendable {
    public let id = UUID()
    public let containerName: String
    public let timestamp: String
    public let message: String

    public init(containerName: String, timestamp: String, message: String) {
        self.containerName = containerName; self.timestamp = timestamp; self.message = message
    }
}

public struct ContainerDependency: Sendable {
    public let sourceContainer: String
    public let targetContainer: String
    public let dependencyType: String

    public init(sourceContainer: String, targetContainer: String, dependencyType: String) {
        self.sourceContainer = sourceContainer; self.targetContainer = targetContainer; self.dependencyType = dependencyType
    }
}

// MARK: - Extension Types (+Security)

public struct VulnerabilityScan: Sendable {
    public let imageName: String
    public let scanner: String
    public let totalVulnerabilities: Int
    public let critical: Int
    public let high: Int
    public let medium: Int
    public let low: Int
    public let rawOutput: String

    public var severityColor: String {
        if critical > 0 { return "red" }
        if high > 0 { return "orange" }
        if medium > 0 { return "yellow" }
        return "green"
    }

    public var summary: String {
        if totalVulnerabilities == 0 { return "No vulnerabilities found ✅" }
        var parts: [String] = []
        if critical > 0 { parts.append("\(critical) Critical") }
        if high > 0 { parts.append("\(high) High") }
        if medium > 0 { parts.append("\(medium) Medium") }
        if low > 0 { parts.append("\(low) Low") }
        return parts.joined(separator: ", ")
    }

    public init(imageName: String, scanner: String, totalVulnerabilities: Int,
                critical: Int, high: Int, medium: Int, low: Int, rawOutput: String) {
        self.imageName = imageName; self.scanner = scanner; self.totalVulnerabilities = totalVulnerabilities
        self.critical = critical; self.high = high; self.medium = medium; self.low = low; self.rawOutput = rawOutput
    }
}

public struct SecurityAudit: Sendable {
    public let containerId: String
    public let containerName: String
    public let securityScore: Int
    public let findings: [SecurityFinding]

    public var grade: String {
        switch securityScore {
        case 90...100: return "A"
        case 75..<90: return "B"
        case 60..<75: return "C"
        case 40..<60: return "D"
        default: return "F"
        }
    }

    public init(containerId: String, containerName: String, securityScore: Int, findings: [SecurityFinding]) {
        self.containerId = containerId; self.containerName = containerName
        self.securityScore = securityScore; self.findings = findings
    }
}

public struct SecurityFinding: Sendable {
    public let severity: String
    public let title: String
    public let description: String

    public init(severity: String, title: String, description: String) {
        self.severity = severity; self.title = title; self.description = description
    }
}

// MARK: - Extension Types (+Backup)

public struct ContainerBackup: Sendable {
    public let containerName: String
    public let backupPath: String
    public let imageSaved: Bool
    public let volumesSaved: Int
    public let configSaved: Bool
    public let totalSizeMB: String
    public let createdAt: Date

    public init(containerName: String, backupPath: String, imageSaved: Bool, volumesSaved: Int,
                configSaved: Bool, totalSizeMB: String, createdAt: Date) {
        self.containerName = containerName; self.backupPath = backupPath; self.imageSaved = imageSaved
        self.volumesSaved = volumesSaved; self.configSaved = configSaved
        self.totalSizeMB = totalSizeMB; self.createdAt = createdAt
    }
}

public struct BackupEntry: Identifiable, Sendable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let size: String
    public let date: String
    public let hasImage: Bool
    public let hasConfig: Bool
    public let volumeCount: Int

    public init(name: String, path: String, size: String, date: String, hasImage: Bool, hasConfig: Bool, volumeCount: Int) {
        self.name = name; self.path = path; self.size = size; self.date = date
        self.hasImage = hasImage; self.hasConfig = hasConfig; self.volumeCount = volumeCount
    }
}

// MARK: - Extension Types (+Rollback)

public struct RollbackSnapshot: Codable, Identifiable, Sendable {
    public var id: String { snapshotImageId }
    public let snapshotImageId: String
    public let containerName: String
    public let originalImage: String
    public let snapshotTag: String
    public let createdAt: String
    public let ports: String
    public let envVars: [String]
    public let volumes: [String]
    public let networks: [String]
    public let restartPolicy: String
    public let labels: [String: String]

    public init(snapshotImageId: String, containerName: String, originalImage: String, snapshotTag: String,
                createdAt: String, ports: String, envVars: [String], volumes: [String], networks: [String],
                restartPolicy: String, labels: [String: String]) {
        self.snapshotImageId = snapshotImageId; self.containerName = containerName
        self.originalImage = originalImage; self.snapshotTag = snapshotTag
        self.createdAt = createdAt; self.ports = ports; self.envVars = envVars
        self.volumes = volumes; self.networks = networks
        self.restartPolicy = restartPolicy; self.labels = labels
    }
}

// MARK: - Extension Types (+Scheduler)

public struct ScheduledAction: Identifiable, Codable, Sendable {
    public var id: String { "\(containerName)-\(action)-\(schedule)" }
    public let containerName: String
    public let action: String
    public let schedule: String
    public let description: String
    public let isActive: Bool

    public init(containerName: String, action: String, schedule: String, description: String, isActive: Bool) {
        self.containerName = containerName; self.action = action; self.schedule = schedule
        self.description = description; self.isActive = isActive
    }
}

public struct PortConflict: Sendable {
    public let port: String
    public let usedByProcess: String
    public let usedByContainer: String?

    public init(port: String, usedByProcess: String, usedByContainer: String?) {
        self.port = port; self.usedByProcess = usedByProcess; self.usedByContainer = usedByContainer
    }
}

// MARK: - Extension Types (+Secrets)

public struct DockerSecret: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let createdAt: String
    public let updatedAt: String

    public init(name: String, createdAt: String, updatedAt: String) {
        self.name = name; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

public struct ContainerGroup: Identifiable, Sendable {
    public var id: String { label }
    public let label: String
    public let containerCount: Int
    public let containerNames: [String]

    public init(label: String, containerCount: Int, containerNames: [String]) {
        self.label = label; self.containerCount = containerCount; self.containerNames = containerNames
    }
}

public struct EnvTemplate: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let variables: [String]

    public init(id: String = UUID().uuidString, name: String, description: String, variables: [String]) {
        self.id = id; self.name = name; self.description = description; self.variables = variables
    }
}

public struct ContainerProfile: Codable, Sendable {
    public let version: String
    public let exportedAt: String
    public let containers: [ContainerProfileEntry]

    public init(version: String, exportedAt: String, containers: [ContainerProfileEntry]) {
        self.version = version; self.exportedAt = exportedAt; self.containers = containers
    }
}

public struct ContainerProfileEntry: Codable, Sendable {
    public let name: String
    public let image: String
    public let ports: [String]
    public let envVars: [String]
    public let volumes: [String]
    public let networks: [String]
    public let restartPolicy: String

    public init(name: String, image: String, ports: [String], envVars: [String],
                volumes: [String], networks: [String], restartPolicy: String) {
        self.name = name; self.image = image; self.ports = ports; self.envVars = envVars
        self.volumes = volumes; self.networks = networks; self.restartPolicy = restartPolicy
    }
}

// MARK: - Extension Types (+Alerts)

public struct ContainerCrashInfo: Sendable {
    public let containerId: String
    public let containerName: String
    public let restartCount: Int
    public let lastExitCode: Int
    public let lastError: String
    public let isRestarting: Bool
    public let lastStartedAt: String
    public let lastFinishedAt: String

    public init(containerId: String, containerName: String, restartCount: Int, lastExitCode: Int,
                lastError: String, isRestarting: Bool, lastStartedAt: String, lastFinishedAt: String) {
        self.containerId = containerId; self.containerName = containerName
        self.restartCount = restartCount; self.lastExitCode = lastExitCode; self.lastError = lastError
        self.isRestarting = isRestarting; self.lastStartedAt = lastStartedAt; self.lastFinishedAt = lastFinishedAt
    }
}

public struct ResourceAlert: Sendable {
    public let containerId: String
    public let containerName: String
    public let alertType: AlertType
    public let currentValue: Double
    public let threshold: Double

    public enum AlertType: String, Sendable {
        case highCPU = "High CPU"
        case highMemory = "High Memory"
        case highDiskIO = "High Disk I/O"
    }

    public init(containerId: String, containerName: String, alertType: AlertType, currentValue: Double, threshold: Double) {
        self.containerId = containerId; self.containerName = containerName
        self.alertType = alertType; self.currentValue = currentValue; self.threshold = threshold
    }
}

public struct ContainerUptime: Sendable {
    public let containerId: String
    public let containerName: String
    public let startedAt: String
    public let uptimeSeconds: Int
    public let status: String

    public var formattedUptime: String { DockerFormatter.formatUptime(TimeInterval(uptimeSeconds)) }

    public init(containerId: String, containerName: String, startedAt: String, uptimeSeconds: Int, status: String) {
        self.containerId = containerId; self.containerName = containerName
        self.startedAt = startedAt; self.uptimeSeconds = uptimeSeconds; self.status = status
    }
}

// MARK: - Extension Types (+AutoUpdate)

public struct ImageUpdateStatus: Identifiable, Sendable {
    public var id: String { imageName }
    public let imageName: String
    public let currentTag: String
    public let localDigest: String
    public let remoteDigest: String
    public let isOutdated: Bool
    public let containerIds: [String]
    public let containerNames: [String]
    public let lastChecked: Date

    public init(imageName: String, currentTag: String, localDigest: String, remoteDigest: String,
                isOutdated: Bool, containerIds: [String], containerNames: [String], lastChecked: Date) {
        self.imageName = imageName; self.currentTag = currentTag; self.localDigest = localDigest
        self.remoteDigest = remoteDigest; self.isOutdated = isOutdated
        self.containerIds = containerIds; self.containerNames = containerNames; self.lastChecked = lastChecked
    }
}

// MARK: - Extension Types (+System)

public struct VolumeFile: Sendable {
    public let name: String
    public let isDir: Bool
    public let size: String

    public init(name: String, isDir: Bool, size: String) {
        self.name = name; self.isDir = isDir; self.size = size
    }
}

public struct DockerEvent: Sendable {
    public let timestamp: String
    public let type: String
    public let action: String
    public let actor: String

    public init(timestamp: String, type: String, action: String, actor: String) {
        self.timestamp = timestamp; self.type = type; self.action = action; self.actor = actor
    }
}

public struct DiskUsageInfo: Sendable {
    public let imagesCount: Int
    public let imagesSize: String
    public let containersCount: Int
    public let containersSize: String
    public let volumesCount: Int
    public let volumesSize: String
    public let buildCacheSize: String
    public let totalReclaimable: String

    public init(imagesCount: Int, imagesSize: String, containersCount: Int, containersSize: String,
                volumesCount: Int, volumesSize: String, buildCacheSize: String, totalReclaimable: String) {
        self.imagesCount = imagesCount; self.imagesSize = imagesSize
        self.containersCount = containersCount; self.containersSize = containersSize
        self.volumesCount = volumesCount; self.volumesSize = volumesSize
        self.buildCacheSize = buildCacheSize; self.totalReclaimable = totalReclaimable
    }
}

// MARK: - Formatter (replaces AXFormatter)

public enum DockerFormatter {
    public static func formatBytes(_ bytes: Int64) -> String {
        if bytes >= 1_073_741_824 {
            return String(format: "%.1f GB", Double(bytes) / 1_073_741_824)
        } else if bytes >= 1_048_576 {
            return String(format: "%.1f MB", Double(bytes) / 1_048_576)
        } else if bytes >= 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        }
        return "\(bytes) B"
    }

    public static func formatUptime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s >= 86400 {
            let days = s / 86400
            let hours = (s % 86400) / 3600
            return "\(days)d \(hours)h"
        } else if s >= 3600 {
            let hours = s / 3600
            let mins = (s % 3600) / 60
            return "\(hours)h \(mins)m"
        } else if s >= 60 {
            return "\(s / 60)m \(s % 60)s"
        }
        return "\(s)s"
    }
}
