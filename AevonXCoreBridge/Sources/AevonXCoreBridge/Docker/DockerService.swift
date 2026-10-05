//
//  DockerService.swift
//  AevonXCoreBridge
//
//  Replaces AevonXCore.DockerManager with pure Bridge implementation.
//  Uses SSHBridge + DockerBridge for all Docker operations.
//

import Foundation
import AevonXCoreLib

// MARK: - Docker Service

public actor DockerService {

    public static let shared = DockerService()

    private var dockerPaths: [String: String] = [:]

    private init() {}

    // MARK: - SSH Execution Helpers

    /// Execute a command and return full result (stdout, stderr, exit_code).
    func sshExec(_ command: String, serverId: String) async -> SSHResult {
        let json = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: command)
        return SSHResult.parse(json)
    }

    /// Shell-quote a string to prevent injection.
    func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    // MARK: - Docker Path Discovery

    func getDockerPath(serverId: String) async throws -> String {
        if let cached = dockerPaths[serverId] {
            return cached
        }

        let result = await sshExec("which docker", serverId: serverId)
        if result.exitCode == 0, !result.stdout.isEmpty {
            dockerPaths[serverId] = result.stdout
            return result.stdout
        }

        let commonPaths = ["/usr/bin/docker", "/usr/local/bin/docker", "/opt/docker/bin/docker", "/usr/bin/docker-ce"]
        for path in commonPaths {
            let check = await sshExec("test -x \(path)", serverId: serverId)
            if check.exitCode == 0 {
                dockerPaths[serverId] = path
                return path
            }
        }

        throw DockerError.commandFailed("docker path", "Docker binary not found in PATH")
    }

    /// Run a docker subcommand (e.g. "start <id>")
    func runDockerCommand(_ action: String, serverId: String) async throws {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) \(action)", serverId: serverId)
        guard result.exitCode == 0 else {
            throw DockerError.commandFailed("docker \(action)", result.stderr)
        }
    }

    // MARK: - Feature Gate Enforcement

    /// Verify that a PRO feature is allowed by the Ed25519-signed permit.
    /// Throws `DockerError.featureLocked` if the feature is not enabled.
    /// This is the REAL enforcement layer — UI locks are cosmetic only.
    func requireFeature(_ key: FeatureKey) async throws {
        let allowed = await FeatureGateManager.shared.isFeatureEnabled(key.rawValue)
        guard allowed else {
            CoreLogger.shared.warning("Feature gate blocked: \(key.rawValue)", module: "DockerService")
            throw DockerError.featureLocked(key.rawValue)
        }
    }

    // MARK: - Core Checks

    public func isInstalled(serverId: String) async throws -> Bool {
        return (try? await getDockerPath(serverId: serverId)) != nil
    }

    public func installDocker(serverId: String, progress: @escaping @Sendable (String, Double) -> Void) async throws {
        progress("Downloading installation script...", 0.1)

        let cleanupApt = "if [ -x \"$(command -v apt-get)\" ]; then sudo rm -f /etc/apt/apt.conf.d/50command-not-found; fi"
        let installScript = "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
        let command = "\(cleanupApt); \(installScript)"

        // Non-streaming fallback: execute and report progress based on completion
        progress("Installing Docker Engine...", 0.3)
        let result = await sshExec(command, serverId: serverId)

        if result.exitCode != 0 && !result.stdout.contains("docker") {
            throw DockerError.commandFailed("installDocker", result.stderr)
        }

        // Clean up
        let _ = await sshExec("rm -f get-docker.sh", serverId: serverId)

        // Verify
        dockerPaths[serverId] = nil
        if try await isInstalled(serverId: serverId) {
            progress("Docker installed successfully", 1.0)
        } else {
            throw DockerError.commandFailed("installDocker", "Installation finished but docker binary not found")
        }
    }

    public func getVersion(serverId: String) async throws -> String? {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) --version | awk '{print $3}' | tr -d ','", serverId: serverId)
        return result.exitCode == 0 ? result.stdout : nil
    }

    public func getServiceStatus(serverId: String) async throws -> ServiceStatus {
        let result = await sshExec("systemctl is-active docker", serverId: serverId)
        switch result.stdout {
        case "active": return .active
        case "inactive": return .inactive
        default: return .unknown
        }
    }

    public func getMemoryUsage(serverId: String) async throws -> Double? {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) system df --format '{{.Size}}' | head -1", serverId: serverId)
        guard result.exitCode == 0 else { return nil }
        return parseHumanSize(result.stdout)
    }

    public func getCPUUsage(serverId: String) async throws -> Double? {
        let result = await sshExec("ps -C dockerd -o %cpu= | awk '{sum+=$1} END {print sum}'", serverId: serverId)
        return Double(result.stdout)
    }

    private func parseHumanSize(_ s: String) -> Double? {
        let trimmed = s.trimmingCharacters(in: .whitespaces).uppercased()
        if trimmed.hasSuffix("GB") { return Double(trimmed.dropLast(2)).map { $0 * 1024 } }
        if trimmed.hasSuffix("MB") { return Double(String(trimmed.dropLast(2))) }
        if trimmed.hasSuffix("KB") { return Double(trimmed.dropLast(2)).map { $0 / 1024 } }
        if trimmed.hasSuffix("B") { return Double(trimmed.dropLast(1)).map { $0 / 1_048_576 } }
        return Double(trimmed)
    }

    public func startService(serverId: String) async throws {
        let result = await sshExec("sudo systemctl start docker", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("start docker", result.stderr) }
    }

    public func stopService(serverId: String) async throws {
        let result = await sshExec("sudo systemctl stop docker", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("stop docker", result.stderr) }
    }

    // MARK: - Information Retrieval

    public func getDockerInfo(serverId: String) async throws -> DockerInfo {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let format = "{{.ServerVersion}}|{{.Containers}}|{{.ContainersRunning}}|{{.Images}}|{{.OSType}}|{{.Architecture}}|{{.KernelVersion}}|{{.DockerRootDir}}"
        let result = await sshExec("\(dockerPath) info --format \"\(format)\"", serverId: serverId)

        guard result.exitCode == 0 else {
            throw DockerError.commandFailed("docker info", result.stderr)
        }

        let parts = result.stdout.components(separatedBy: "|")
        guard parts.count >= 8 else { throw DockerError.parsingFailed("Failed to parse docker info output") }

        return DockerInfo(
            serverVersion: parts[0], containers: Int(parts[1]), containersRunning: Int(parts[2]),
            images: Int(parts[3]), kernelVersion: parts[6], osType: parts[4],
            architecture: parts[5], dockerRootDir: parts[7]
        )
    }

    public func getContainerWorkingDir(id: String, serverId: String) async throws -> String? {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let cmd = "\(dockerPath) inspect --format '{{.Config.WorkingDir}}|||{{range .Mounts}}{{.Destination}},{{end}}' \(id)"
        let result = await sshExec(cmd, serverId: serverId)

        if result.exitCode == 0 {
            let parts = result.stdout.components(separatedBy: "|||")
            let workDir = parts[0].trimmingCharacters(in: .whitespaces)
            if !workDir.isEmpty && workDir != "/" { return workDir }
            if parts.count > 1 {
                let mounts = parts[1].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if mounts.contains("/var/www") { return "/var/www" }
                if mounts.contains("/app") { return "/app" }
                if mounts.contains("/www") { return "/www" }
                if let firstMount = mounts.first(where: { !$0.isEmpty && $0 != "/" }) { return firstMount }
            }
        }
        return nil
    }

    // MARK: - Basic CRUD

    public func getContainers(serverId: String, all: Bool = true) async throws -> [DockerContainer] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let format = "{{.ID}}|{{.Image}}|{{.Command}}|{{.RunningFor}}|{{.Status}}|{{.Ports}}|{{.Names}}"
        let result = await sshExec("\(dockerPath) ps \(all ? "-a" : "") --format \"\(format)\"", serverId: serverId)

        guard result.exitCode == 0 else { throw DockerError.commandFailed("docker ps", result.stderr) }

        return result.stdout.components(separatedBy: .newlines).compactMap { line -> DockerContainer? in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 7 else { return nil }
            return DockerContainer(
                id: parts[0], image: parts[1],
                command: parts[2].trimmingCharacters(in: CharacterSet(charactersIn: "\"")),
                created: parts[3], status: parts[4], ports: parts[5], names: parts[6]
            )
        }
    }

    public func getImages(serverId: String) async throws -> [DockerImage] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let format = "{{.ID}}|{{.Repository}}|{{.Tag}}|{{.CreatedSince}}|{{.Size}}"
        let result = await sshExec("\(dockerPath) images --format \"\(format)\"", serverId: serverId)

        guard result.exitCode == 0 else { throw DockerError.commandFailed("docker images", result.stderr) }

        return result.stdout.components(separatedBy: .newlines).compactMap { line -> DockerImage? in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 5 else { return nil }
            return DockerImage(id: parts[0], repository: parts[1], tag: parts[2], created: parts[3], size: parts[4])
        }
    }

    public func runContainer(name: String, image: String, ports: String?, serverId: String) async throws {
        // Pre-pull image to ensure it exists locally
        let dockerPath = try await getDockerPath(serverId: serverId)
        let pullResult = await sshExec("\(dockerPath) pull \(shellQuote(image)) 2>&1", serverId: serverId)
        if pullResult.exitCode != 0 {
            let detail = pullResult.stderr.isEmpty ? pullResult.stdout : pullResult.stderr
            throw DockerError.commandFailed("docker pull \(image)", detail)
        }

        let safeName = shellQuote(name)
        let safeImage = shellQuote(image)
        var action = "run -d --name \(safeName)"
        if let ports = ports, !ports.isEmpty {
            let portArgs = ports.components(separatedBy: ",").map { "-p \($0.trimmingCharacters(in: .whitespaces))" }.joined(separator: " ")
            action += " \(portArgs)"
        }
        action += " \(safeImage)"
        try await runDockerCommand(action, serverId: serverId)
    }

    // MARK: - Container Actions

    public func startContainer(id: String, serverId: String) async throws {
        try await runDockerCommand("start \(id)", serverId: serverId)
    }

    public func stopContainer(id: String, serverId: String) async throws {
        try await runDockerCommand("stop \(id)", serverId: serverId)
    }

    public func restartContainer(id: String, serverId: String) async throws {
        try await runDockerCommand("restart \(id)", serverId: serverId)
    }

    public func pauseContainer(id: String, serverId: String) async throws {
        try await runDockerCommand("pause \(id)", serverId: serverId)
    }

    public func unpauseContainer(id: String, serverId: String) async throws {
        try await runDockerCommand("unpause \(id)", serverId: serverId)
    }

    public func removeContainer(id: String, force: Bool = false, serverId: String) async throws {
        try await runDockerCommand("rm \(force ? "-f" : "") \(id)", serverId: serverId)
    }

    // MARK: - Volume Actions

    public func getVolumes(serverId: String) async throws -> [DockerVolume] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let format = "{{.Name}}|{{.Driver}}|{{.Mountpoint}}"
        let result = await sshExec("\(dockerPath) volume ls --format \"\(format)\"", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("docker volume ls", result.stderr) }

        return result.stdout.components(separatedBy: .newlines).compactMap { line -> DockerVolume? in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 3 else { return nil }
            return DockerVolume(name: parts[0], driver: parts[1], mountpoint: parts[2])
        }
    }

    public func createVolume(name: String, driver: String = "local", serverId: String) async throws {
        try await runDockerCommand("volume create --driver \(shellQuote(driver)) \(shellQuote(name))", serverId: serverId)
    }

    public func removeVolume(name: String, force: Bool = false, serverId: String) async throws {
        try await runDockerCommand("volume rm \(force ? "-f" : "") \(name)", serverId: serverId)
    }

    // MARK: - Network Actions

    public func getNetworks(serverId: String) async throws -> [DockerNetwork] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let format = "{{.ID}}|{{.Name}}|{{.Driver}}|{{.Scope}}|{{.CreatedAt}}|{{.IPv6}}|{{.Internal}}"
        let result = await sshExec("\(dockerPath) network ls --format \"\(format)\"", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("docker network ls", result.stderr) }

        return result.stdout.components(separatedBy: .newlines).compactMap { line -> DockerNetwork? in
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 7 else { return nil }
            return DockerNetwork(
                networkId: parts[0], name: parts[1], driver: parts[2], scope: parts[3],
                created: parts[4], ipv6: parts[5] == "true", internalNetwork: parts[6] == "true"
            )
        }
    }

    public func createNetwork(name: String, driver: String = "bridge", serverId: String) async throws {
        try await runDockerCommand("network create --driver \(shellQuote(driver)) \(shellQuote(name))", serverId: serverId)
    }

    public func removeNetwork(id: String, serverId: String) async throws {
        try await runDockerCommand("network rm \(id)", serverId: serverId)
    }

    // MARK: - Image Actions

    public func pullImage(_ image: String, serverId: String) async throws {
        try await runDockerCommand("pull \(image)", serverId: serverId)
    }

    public func removeImage(id: String, force: Bool = false, serverId: String) async throws {
        try await runDockerCommand("rmi \(force ? "-f" : "") \(id)", serverId: serverId)
    }

    // MARK: - Logs

    public func getContainerLogs(id: String, tail: Int = 100, follow: Bool = false, serverId: String, onOutput: @escaping @Sendable (String) -> Void) async throws {
        let dockerPath = try await getDockerPath(serverId: serverId)
        // Non-streaming: always use --no-follow, return full output
        let command = "\(dockerPath) logs --tail \(tail) \(id)"
        let result = await sshExec(command, serverId: serverId)
        if result.exitCode == 0 {
            onOutput(result.stdout)
            if !result.stderr.isEmpty { onOutput(result.stderr) }
        } else {
            throw DockerError.commandFailed(command, result.stderr)
        }
    }
}
