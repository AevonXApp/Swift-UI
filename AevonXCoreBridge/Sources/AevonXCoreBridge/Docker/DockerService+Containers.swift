//
//  DockerService+Containers.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    // MARK: - Container Inspection

    public func inspectContainer(id: String, serverId: String) async throws -> ContainerInspection {
        let dockerPath = try await getDockerPath(serverId: serverId)

        let envCmd = "\(dockerPath) inspect --format '{{range .Config.Env}}{{.}}|||{{end}}' \(id)"
        let envResult = await sshExec(envCmd, serverId: serverId)
        let envVars = envResult.stdout.components(separatedBy: "|||").filter { !$0.isEmpty }

        let mountsCmd = "\(dockerPath) inspect --format '{{range .Mounts}}{{.Source}}|||{{.Destination}}|||{{.Mode}}|||{{.Type}};;;{{end}}' \(id)"
        let mountsResult = await sshExec(mountsCmd, serverId: serverId)
        let mounts: [InspectMount] = mountsResult.stdout.components(separatedBy: ";;;").compactMap { entry in
            let parts = entry.components(separatedBy: "|||")
            guard parts.count >= 4 else { return nil }
            return InspectMount(source: parts[0], destination: parts[1], mode: parts[2], type: parts[3])
        }

        let netCmd = "\(dockerPath) inspect --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}|||{{$v.IPAddress}}|||{{$v.Gateway}}|||{{$v.MacAddress}};;;{{end}}' \(id)"
        let netResult = await sshExec(netCmd, serverId: serverId)
        let networks: [InspectNetwork] = netResult.stdout.components(separatedBy: ";;;").compactMap { entry in
            let parts = entry.components(separatedBy: "|||")
            guard parts.count >= 4 else { return nil }
            return InspectNetwork(name: parts[0], ipAddress: parts[1], gateway: parts[2], macAddress: parts[3])
        }

        let miscCmd = "\(dockerPath) inspect --format '{{.HostConfig.RestartPolicy.Name}}|||{{.HostConfig.CpuShares}}|||{{.HostConfig.Memory}}' \(id)"
        let miscResult = await sshExec(miscCmd, serverId: serverId)
        let miscParts = miscResult.stdout.components(separatedBy: "|||")
        let restartPolicy = miscParts.count > 0 ? miscParts[0] : "no"
        let cpuShares = Int(miscParts.count > 1 ? miscParts[1] : "0") ?? 0
        let memory = Int64(miscParts.count > 2 ? miscParts[2] : "0") ?? 0

        let rawResult = await sshExec("\(dockerPath) inspect \(id)", serverId: serverId)

        return ContainerInspection(
            envVars: envVars, mounts: mounts, networkSettings: networks, portBindings: [],
            labels: [:], restartPolicy: restartPolicy, cpuShares: cpuShares, memory: memory,
            processes: [], rawJSON: rawResult.stdout
        )
    }

    public func getContainerProcesses(id: String, serverId: String) async throws -> [ContainerProcess] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) top \(id) -eo pid,user,comm 2>/dev/null || echo ''", serverId: serverId)
        guard result.exitCode == 0 else { return [] }

        return result.stdout.components(separatedBy: .newlines).dropFirst().compactMap { line in
            let parts = line.split(separator: " ", maxSplits: 2).map(String.init)
            guard parts.count >= 3 else { return nil }
            return ContainerProcess(pid: parts[0], user: parts[1], command: parts[2])
        }
    }

    public func getContainerStats(id: String, serverId: String) async throws -> ContainerStats {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let cmd = "\(dockerPath) stats --no-stream --format '{{.CPUPerc}}|||{{.MemUsage}}|||{{.MemPerc}}|||{{.NetIO}}|||{{.PIDs}}' \(id)"
        let result = await sshExec(cmd, serverId: serverId)

        let parts = result.stdout.components(separatedBy: "|||")
        let cpu = Double(parts[0].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
        let pids = Int(parts.count > 4 ? parts[4].trimmingCharacters(in: .whitespaces) : "0") ?? 0

        // Parse memory: "123.4MiB / 1.5GiB"
        var memUsage: Double = 0
        var memLimit: Double = 0
        if parts.count > 1 {
            let memParts = parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " / ")
            memUsage = parseMemoryToMB(memParts.first ?? "0")
            memLimit = parseMemoryToMB(memParts.count > 1 ? memParts[1] : "0")
        }
        let memPercent = Double(parts.count > 2 ? parts[2].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces) : "0") ?? 0

        // Parse network: "1.5kB / 2.3MB"
        var netIn: Double = 0
        var netOut: Double = 0
        if parts.count > 3 {
            let netParts = parts[3].trimmingCharacters(in: .whitespaces).components(separatedBy: " / ")
            netIn = parseMemoryToMB(netParts.first ?? "0")
            netOut = parseMemoryToMB(netParts.count > 1 ? netParts[1] : "0")
        }

        return ContainerStats(cpuPercent: cpu, memUsageMB: memUsage, memLimitMB: memLimit,
                              memPercent: memPercent, netInputMB: netIn, netOutputMB: netOut, pids: pids)
    }

    private func parseMemoryToMB(_ str: String) -> Double {
        let s = str.trimmingCharacters(in: .whitespaces)
        if s.hasSuffix("GiB") || s.hasSuffix("GB") {
            return (Double(s.replacingOccurrences(of: "GiB", with: "").replacingOccurrences(of: "GB", with: "").trimmingCharacters(in: .whitespaces)) ?? 0) * 1024
        } else if s.hasSuffix("MiB") || s.hasSuffix("MB") {
            return Double(s.replacingOccurrences(of: "MiB", with: "").replacingOccurrences(of: "MB", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
        } else if s.hasSuffix("kB") || s.hasSuffix("KiB") {
            return (Double(s.replacingOccurrences(of: "kB", with: "").replacingOccurrences(of: "KiB", with: "").trimmingCharacters(in: .whitespaces)) ?? 0) / 1024
        } else if s.hasSuffix("B") {
            return (Double(s.replacingOccurrences(of: "B", with: "").trimmingCharacters(in: .whitespaces)) ?? 0) / (1024 * 1024)
        }
        return Double(s) ?? 0
    }

    public func renameContainer(id: String, newName: String, serverId: String) async throws {
        try await runDockerCommand("rename \(id) \(shellQuote(newName))", serverId: serverId)
    }

    public func commitContainer(id: String, imageName: String, tag: String, serverId: String) async throws {
        try await runDockerCommand("commit \(id) \(shellQuote(imageName)):\(shellQuote(tag))", serverId: serverId)
    }

    // MARK: - Resource Limits

    public func getContainerLimits(id: String, serverId: String) async throws -> ContainerLimits {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let cmd = "\(dockerPath) inspect --format '{{.HostConfig.Memory}}|||{{.HostConfig.NanoCpus}}|||{{.HostConfig.MemorySwap}}|||{{.HostConfig.CpuShares}}' \(id)"
        let result = await sshExec(cmd, serverId: serverId)
        let parts = result.stdout.components(separatedBy: "|||")

        let memBytes = Int64(parts[0]) ?? 0
        let nanoCpus = Int64(parts.count > 1 ? parts[1] : "0") ?? 0
        let swapBytes = Int64(parts.count > 2 ? parts[2] : "0") ?? 0
        let cpuShares = Int(parts.count > 3 ? parts[3] : "0") ?? 0

        return ContainerLimits(
            memoryMB: Int(memBytes / 1_048_576),
            cpus: Double(nanoCpus) / 1_000_000_000,
            memorySwapMB: Int(swapBytes / 1_048_576),
            cpuShares: cpuShares
        )
    }

    public func updateContainerLimits(id: String, memoryMB: Int?, cpus: Double?, serverId: String) async throws {
        let dockerPath = try await getDockerPath(serverId: serverId)
        var flags: [String] = []
        if let mem = memoryMB { flags.append("--memory \(mem)m") }
        if let cpu = cpus { flags.append("--cpus \(cpu)") }
        guard !flags.isEmpty else { return }

        let cmd = "\(dockerPath) update \(flags.joined(separator: " ")) \(id)"
        let result = await sshExec(cmd, serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("update limits", result.stderr) }
    }

    /// Convenience overload accepting raw flags array
    public func updateContainerLimits(id: String, flags: [String], serverId: String) async throws {
        let dockerPath = try await getDockerPath(serverId: serverId)
        guard !flags.isEmpty else { return }
        let cmd = "\(dockerPath) update \(flags.joined(separator: " ")) \(id)"
        let result = await sshExec(cmd, serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("update limits", result.stderr) }
    }

    // MARK: - Restart Policy

    public func getRestartPolicy(id: String, serverId: String) async throws -> RestartPolicyInfo {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let cmd = "\(dockerPath) inspect --format '{{.HostConfig.RestartPolicy.Name}}|||{{.HostConfig.RestartPolicy.MaximumRetryCount}}' \(id)"
        let result = await sshExec(cmd, serverId: serverId)
        let parts = result.stdout.components(separatedBy: "|||")
        return RestartPolicyInfo(name: parts[0], maxRetries: Int(parts.count > 1 ? parts[1] : "0") ?? 0)
    }

    public func updateRestartPolicy(id: String, policy: String, serverId: String) async throws {
        try await runDockerCommand("update --restart=\(policy) \(id)", serverId: serverId)
    }

    // MARK: - Diff, Health, Exec

    public func diffContainer(id: String, serverId: String) async throws -> [ContainerChange] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) diff \(id) 2>/dev/null || echo ''", serverId: serverId)

        return result.stdout.components(separatedBy: .newlines).compactMap { line in
            guard line.count > 2 else { return nil }
            let kind: String
            switch line.prefix(1) {
            case "C": kind = "Changed"
            case "A": kind = "Added"
            case "D": kind = "Deleted"
            default: kind = "Unknown"
            }
            return ContainerChange(kind: kind, path: String(line.dropFirst(2)))
        }
    }

    public func fetchContainerHealth(id: String, serverId: String) async throws -> ContainerHealthInfo {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let cmd = "\(dockerPath) inspect --format '{{.State.Health.Status}}|||{{.State.Health.FailingStreak}}|||{{with (index .State.Health.Log 0)}}{{.Output}}{{end}}' \(id) 2>/dev/null || echo 'none|||0|||'"
        let result = await sshExec(cmd, serverId: serverId)
        let parts = result.stdout.components(separatedBy: "|||")
        return ContainerHealthInfo(
            status: parts[0], failingStreak: Int(parts.count > 1 ? parts[1] : "0") ?? 0,
            lastOutput: parts.count > 2 ? parts[2] : ""
        )
    }

    public func execInContainer(id: String, command: String, serverId: String) async throws -> String {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) exec \(id) \(command) 2>&1", serverId: serverId)
        return result.stdout + result.stderr
    }

    public func getContainerPorts(id: String, serverId: String) async throws -> [String] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) port \(id) 2>/dev/null || echo ''", serverId: serverId)
        return result.stdout.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }

    public func getContainerRestartCount(id: String, serverId: String) async throws -> Int {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) inspect --format '{{.RestartCount}}' \(id)", serverId: serverId)
        return Int(result.stdout) ?? 0
    }

    public func waitForContainer(id: String, serverId: String) async throws -> ContainerWaitResult {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) wait \(id)", serverId: serverId)
        return ContainerWaitResult(statusCode: Int(result.stdout) ?? -1, error: result.exitCode != 0 ? result.stderr : nil)
    }

    // MARK: - File Operations

    public func listContainerFiles(id: String, path: String, serverId: String) async throws -> [ContainerFile] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        let cmd = "\(dockerPath) exec \(id) ls -lahF '\(escaped)' 2>/dev/null | tail -n +2"
        let result = await sshExec(cmd, serverId: serverId)

        return result.stdout.components(separatedBy: .newlines).compactMap { line in
            let parts = line.split(separator: " ", maxSplits: 8).map(String.init)
            guard parts.count >= 9 else { return nil }
            let fileName = parts[8].trimmingCharacters(in: .whitespaces)
            if fileName == "." || fileName == ".." || fileName == "./" || fileName == "../" { return nil }
            let isDir = fileName.hasSuffix("/") || parts[0].hasPrefix("d")
            let cleanName = fileName.hasSuffix("/") ? String(fileName.dropLast()) : fileName
            return ContainerFile(name: cleanName, isDir: isDir, size: parts[4], permissions: parts[0], modified: "\(parts[5]) \(parts[6]) \(parts[7])")
        }
    }

    public func readContainerFile(id: String, path: String, serverId: String) async throws -> String {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        let result = await sshExec("\(dockerPath) exec \(id) cat '\(escaped)' 2>&1", serverId: serverId)
        return result.stdout
    }

    // MARK: - Export/Import

    public func exportContainer(id: String, path: String, serverId: String) async throws {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) export \(id) | gzip > \(shellQuote(path))", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("export", result.stderr) }
    }

    public func importContainer(path: String, imageName: String, serverId: String) async throws {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("zcat \(shellQuote(path)) | \(dockerPath) import - \(shellQuote(imageName))", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("import", result.stderr) }
    }

    // MARK: - Domain Connect (Nginx proxy)

    public func connectDomain(domain: String, containerId: String, containerPort: Int, serverId: String,
                               progress: @escaping @Sendable (String) -> Void) async throws {
        let dockerPath = try await getDockerPath(serverId: serverId)

        progress("Checking container ports...")
        let portsResult = await sshExec("\(dockerPath) port \(containerId) 2>/dev/null", serverId: serverId)
        let ports = portsResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let hostPort: String
        if ports.isEmpty {
            hostPort = "\(containerPort)"
        } else {
            let firstPort = ports.components(separatedBy: .newlines).first ?? ""
            hostPort = firstPort.components(separatedBy: ":").last ?? "\(containerPort)"
        }

        progress("Creating Nginx config...")
        let config = """
        server {
            listen 80;
            server_name \(domain);
            location / {
                proxy_pass http://127.0.0.1:\(hostPort);
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
            }
        }
        """
        let safeDomain = domain.replacingOccurrences(of: "'", with: "'\\''")
        let safeConfig = config.replacingOccurrences(of: "'", with: "'\\''")

        let writeResult = await sshExec("echo '\(safeConfig)' | sudo tee /etc/nginx/sites-available/\(safeDomain) > /dev/null", serverId: serverId)
        guard writeResult.exitCode == 0 else { throw DockerError.commandFailed("write nginx config", writeResult.stderr) }

        let _ = await sshExec("sudo ln -sf /etc/nginx/sites-available/\(safeDomain) /etc/nginx/sites-enabled/\(safeDomain)", serverId: serverId)

        progress("Testing Nginx config...")
        let testResult = await sshExec("sudo nginx -t 2>&1", serverId: serverId)
        guard testResult.stdout.contains("successful") || testResult.stderr.contains("successful") else {
            throw DockerError.commandFailed("nginx test", testResult.stderr)
        }

        let _ = await sshExec("sudo systemctl reload nginx", serverId: serverId)

        progress("Setting up SSL with certbot...")
        let sslResult = await sshExec("sudo certbot --nginx -d \(safeDomain) --non-interactive --agree-tos --redirect 2>&1 || true", serverId: serverId)
        let sslOutput = sslResult.stdout + sslResult.stderr
        if !sslOutput.contains("Congratulations") && !sslOutput.contains("success") {
            print("[DockerService] SSL setup warning for \(domain): \(sslOutput.prefix(300))")
        }

        progress("Domain connected ✅")
    }

    public func disconnectDomain(domain: String, serverId: String) async throws {
        let safeDomain = domain.replacingOccurrences(of: "'", with: "'\\''")
        let _ = await sshExec("sudo rm -f /etc/nginx/sites-enabled/\(safeDomain) /etc/nginx/sites-available/\(safeDomain)", serverId: serverId)
        let _ = await sshExec("sudo systemctl reload nginx 2>/dev/null || true", serverId: serverId)
    }

    // MARK: - Advanced Run

    public func runContainerAdvanced(config: ContainerConfig, serverId: String) async throws {
        let dockerPath = try await getDockerPath(serverId: serverId)

        // Pre-pull image to ensure it exists locally (docker run can fail silently without it)
        let pullResult = await sshExec("\(dockerPath) pull \(shellQuote(config.image)) 2>&1", serverId: serverId)
        if pullResult.exitCode != 0 {
            let detail = pullResult.stderr.isEmpty ? pullResult.stdout : pullResult.stderr
            throw DockerError.commandFailed("docker pull \(config.image)", detail)
        }

        let flags = config.buildFlags()
        let result = await sshExec("\(dockerPath) run \(flags) \(shellQuote(config.image)) 2>&1", serverId: serverId)
        guard result.exitCode == 0 else {
            let detail = result.stderr.isEmpty ? result.stdout : result.stderr
            throw DockerError.commandFailed("docker run", detail)
        }
    }

    public func fetchContainerLogs(id: String, tail: Int = 100, timestamps: Bool = false, since: String? = nil, serverId: String) async throws -> String {
        let dockerPath = try await getDockerPath(serverId: serverId)
        var cmd = "\(dockerPath) logs --tail \(tail)"
        if timestamps { cmd += " --timestamps" }
        if let since = since { cmd += " --since \(since)" }
        cmd += " \(id) 2>&1"
        let result = await sshExec(cmd, serverId: serverId)
        return result.stdout
    }
}
