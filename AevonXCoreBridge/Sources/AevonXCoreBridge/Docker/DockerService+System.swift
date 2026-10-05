//
//  DockerService+System.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    // MARK: - System Prune

    public func systemPrune(all: Bool, volumes: Bool, serverId: String) async throws -> String {
        let dockerPath = try await getDockerPath(serverId: serverId)
        var flags = "-f"
        if all { flags += " --all" }
        if volumes { flags += " --volumes" }
        let result = await sshExec("\(dockerPath) system prune \(flags) 2>&1", serverId: serverId)
        return result.stdout
    }

    // MARK: - Volume Browser

    public func browseVolume(name: String, path: String, serverId: String) async throws -> [VolumeFile] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        let cmd = "\(dockerPath) run --rm -v \(shellQuote(name)):/vol alpine ls -lahF '/vol\(escaped)' 2>/dev/null | tail -n +2"
        let result = await sshExec(cmd, serverId: serverId)

        return result.stdout.components(separatedBy: CharacterSet.newlines).compactMap { line -> VolumeFile? in
            let parts = line.split(separator: " ", maxSplits: 8).map(String.init)
            guard parts.count >= 9 else { return nil as VolumeFile? }
            let fileName = parts[8].trimmingCharacters(in: .whitespaces)
            if fileName == "." || fileName == ".." || fileName == "./" || fileName == "../" { return nil as VolumeFile? }
            let isDir = fileName.hasSuffix("/") || parts[0].hasPrefix("d")
            let cleanName = fileName.hasSuffix("/") ? String(fileName.dropLast()) : fileName
            return VolumeFile(name: cleanName, isDir: isDir, size: parts[4])
        }
    }

    // MARK: - Docker Events

    public func getRecentEvents(since: Int, until: Int, serverId: String) async throws -> [DockerEvent] {
        try await requireFeature(.dockerTools)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let cmd = "timeout 1 \(dockerPath) events --since \(since) --until \(until) --format '{{.Time}}|||{{.Type}}|||{{.Action}}|||{{.Actor.Attributes.name}}{{.Actor.Attributes.image}}' 2>/dev/null || true"
        let result = await sshExec(cmd, serverId: serverId)

        return result.stdout.components(separatedBy: CharacterSet.newlines).compactMap { line -> DockerEvent? in
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 4 else { return nil as DockerEvent? }
            return DockerEvent(timestamp: parts[0], type: parts[1], action: parts[2], actor: parts[3])
        }
    }

    // MARK: - Custom Templates

    public func saveCustomTemplate(name: String, description: String, category: String, compose: String, serverId: String) async throws {
        try await requireFeature(.dockerTemplates)
        let slug = name.lowercased().replacingOccurrences(of: " ", with: "-")
        let templateDir = "/opt/aevonx/custom-templates/\(slug)"

        let mkdirResult = await sshExec("sudo mkdir -p \"\(templateDir)\" && sudo chown -R $USER:$USER \"\(templateDir)\"", serverId: serverId)
        guard mkdirResult.exitCode == 0 else { throw DockerError.commandFailed("mkdir", mkdirResult.stderr) }

        let escapedCompose = compose.replacingOccurrences(of: "'", with: "'\\''")
        let writeResult = await sshExec("printf '%s' '\(escapedCompose)' > \"\(templateDir)/docker-compose.yml\"", serverId: serverId)
        guard writeResult.exitCode == 0 else { throw DockerError.commandFailed("write compose", writeResult.stderr) }

        let safeName = name.replacingOccurrences(of: "\"", with: "\\\"")
        let safeDesc = description.replacingOccurrences(of: "\"", with: "\\\"")
        let safeCat = category.replacingOccurrences(of: "\"", with: "\\\"")
        let meta = "{\"name\":\"\(safeName)\",\"description\":\"\(safeDesc)\",\"category\":\"\(safeCat)\"}"
        let _ = await sshExec("printf '%s' '\(meta.replacingOccurrences(of: "'", with: "'\\''"))' > \"\(templateDir)/template.json\"", serverId: serverId)

        try await composeUp(workingDir: templateDir, serverId: serverId)
    }

    // MARK: - Disk Usage

    public func getSystemDiskUsage(serverId: String) async throws -> DiskUsageInfo {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) system df --format '{{.Type}}|||{{.TotalCount}}|||{{.Size}}|||{{.Reclaimable}}'", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("system df", result.stderr) }

        var imagesCount = 0, containersCount = 0, volumesCount = 0
        var imagesSize = "0B", containersSize = "0B", volumesSize = "0B", buildCacheSize = "0B", totalReclaimable = "0B"

        for line in result.stdout.components(separatedBy: CharacterSet.newlines) {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 4 else { continue }
            let type = parts[0].trimmingCharacters(in: .whitespaces)
            let count = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
            let size = parts[2].trimmingCharacters(in: .whitespaces)
            let reclaim = parts[3].trimmingCharacters(in: .whitespaces)

            switch type {
            case "Images": imagesCount = count; imagesSize = size; totalReclaimable = reclaim
            case "Containers": containersCount = count; containersSize = size
            case "Local Volumes": volumesCount = count; volumesSize = size
            case "Build Cache": buildCacheSize = size
            default: break
            }
        }

        return DiskUsageInfo(imagesCount: imagesCount, imagesSize: imagesSize, containersCount: containersCount,
                             containersSize: containersSize, volumesCount: volumesCount, volumesSize: volumesSize,
                             buildCacheSize: buildCacheSize, totalReclaimable: totalReclaimable)
    }

    // MARK: - Networking Extensions

    public func getNetworkTrafficStats(serverId: String) async throws -> [ContainerNetworkStats] {
        try await requireFeature(.dockerTools)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }
        let fmt = "{{.ID}}|||{{.Name}}|||{{.NetIO}}"
        let result = await sshExec("\(dockerPath) stats --no-stream --format '\(fmt)' 2>/dev/null || echo ''", serverId: serverId)

        return result.stdout.components(separatedBy: CharacterSet.newlines).compactMap { line -> ContainerNetworkStats? in
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            let ioParts = parts[2].trimmingCharacters(in: .whitespaces).components(separatedBy: " / ")
            return ContainerNetworkStats(
                containerId: parts[0], containerName: parts[1].replacingOccurrences(of: "/", with: ""),
                rxBytes: parseNetworkBytes(ioParts.count > 0 ? ioParts[0] : "0B"),
                txBytes: parseNetworkBytes(ioParts.count > 1 ? ioParts[1] : "0B")
            )
        }.sorted { ($0.rxBytes + $0.txBytes) > ($1.rxBytes + $1.txBytes) }
    }

    public func getAggregatedLogs(containerIds: [String], tail: Int = 50, serverId: String) async throws -> [AggregatedLogEntry] {
        try await requireFeature(.dockerLogs)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }
        var allEntries: [AggregatedLogEntry] = []

        for containerId in containerIds {
            let nameResult = await sshExec("\(dockerPath) inspect --format '{{.Name}}' \(containerId) 2>/dev/null", serverId: serverId)
            let name = nameResult.stdout.replacingOccurrences(of: "/", with: "")
            let logsResult = await sshExec("\(dockerPath) logs --tail \(tail) --timestamps \(containerId) 2>&1", serverId: serverId)

            for line in logsResult.stdout.components(separatedBy: CharacterSet.newlines) where !line.isEmpty {
                let logParts = line.split(separator: " ", maxSplits: 1).map(String.init)
                allEntries.append(AggregatedLogEntry(
                    containerName: name.isEmpty ? String(containerId.prefix(12)) : name,
                    timestamp: logParts.count > 0 ? logParts[0] : "", message: logParts.count > 1 ? logParts[1] : line
                ))
            }
        }
        return allEntries.sorted { $0.timestamp > $1.timestamp }
    }

    public func detectContainerDependencies(serverId: String) async throws -> [ContainerDependency] {
        try await requireFeature(.dockerTools)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }
        let fmt = "{{.ID}}|||{{.Names}}|||{{range $k,$v := .NetworkSettings.Networks}}{{$k}},{{end}}|||{{range .Mounts}}{{.Name}},{{end}}"
        let result = await sshExec("\(dockerPath) inspect --format '\(fmt)' $(\(dockerPath) ps -q) 2>/dev/null || echo ''", serverId: serverId)

        struct CI { let id: String; let name: String; let networks: [String]; let volumes: [String] }
        var containers: [CI] = []
        for line in result.stdout.components(separatedBy: CharacterSet.newlines) where !line.isEmpty {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 4 else { continue }
            containers.append(CI(
                id: parts[0], name: parts[1].replacingOccurrences(of: "/", with: ""),
                networks: parts[2].components(separatedBy: ",").filter { !$0.isEmpty },
                volumes: parts[3].components(separatedBy: ",").filter { !$0.isEmpty }
            ))
        }

        var deps: [ContainerDependency] = []
        for i in 0..<containers.count {
            for j in (i+1)..<containers.count {
                for net in Set(containers[i].networks).intersection(Set(containers[j].networks)).filter({ $0 != "bridge" && $0 != "host" && $0 != "none" }) {
                    deps.append(ContainerDependency(sourceContainer: containers[i].name, targetContainer: containers[j].name, dependencyType: "network: \(net)"))
                }
                for vol in Set(containers[i].volumes).intersection(Set(containers[j].volumes)).filter({ !$0.isEmpty }) {
                    deps.append(ContainerDependency(sourceContainer: containers[i].name, targetContainer: containers[j].name, dependencyType: "volume: \(vol)"))
                }
            }
        }
        return deps
    }

    public func convertRunToCompose(runCommand: String) -> String {
        var serviceName = "app"; var image = ""; var ports: [String] = []; var envVars: [String] = []
        var volumes: [String] = []; var networks: [String] = []; var restartPolicy = ""
        let parts = tokenize(runCommand); var i = 0

        while i < parts.count {
            let part = parts[i]
            switch part {
            case "docker", "run", "-d", "--detach", "-it", "-i", "-t": break
            case "--name": i += 1; if i < parts.count { serviceName = parts[i] }
            case "-p", "--publish": i += 1; if i < parts.count { ports.append(parts[i]) }
            case "-e", "--env": i += 1; if i < parts.count { envVars.append(parts[i]) }
            case "-v", "--volume": i += 1; if i < parts.count { volumes.append(parts[i]) }
            case "--network": i += 1; if i < parts.count { networks.append(parts[i]) }
            case "--restart": i += 1; if i < parts.count { restartPolicy = parts[i] }
            default:
                if part.hasPrefix("--name=") { serviceName = String(part.dropFirst(7)) }
                else if !part.hasPrefix("-") && image.isEmpty { image = part }
            }; i += 1
        }

        var yaml = "version: '3.8'\n\nservices:\n  \(serviceName):\n    image: \(image)\n    container_name: \(serviceName)\n"
        if !restartPolicy.isEmpty { yaml += "    restart: \(restartPolicy)\n" }
        if !ports.isEmpty { yaml += "    ports:\n"; ports.forEach { yaml += "      - \"\($0)\"\n" } }
        if !envVars.isEmpty { yaml += "    environment:\n"; envVars.forEach { yaml += "      - \($0)\n" } }
        if !volumes.isEmpty { yaml += "    volumes:\n"; volumes.forEach { yaml += "      - \($0)\n" } }
        if !networks.isEmpty { yaml += "    networks:\n"; networks.forEach { yaml += "      - \($0)\n" }
            yaml += "\nnetworks:\n"; networks.forEach { yaml += "  \($0):\n    external: true\n" }
        }
        return yaml
    }

    public func inspectNetwork(id: String, serverId: String) async throws -> NetworkInspection {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let ipamResult = await sshExec("\(dockerPath) network inspect --format '{{range .IPAM.Config}}{{.Subnet}}|||{{.Gateway}}{{end}}|||{{.Scope}}' \(id)", serverId: serverId)
        let ipamParts = ipamResult.stdout.components(separatedBy: "|||")
        let subnet = ipamParts.count > 0 ? ipamParts[0] : ""
        let gateway = ipamParts.count > 1 ? ipamParts[1] : ""
        let scope = ipamParts.count > 2 ? ipamParts[2] : ""

        let containersResult = await sshExec("\(dockerPath) network inspect --format '{{range $k,$v := .Containers}}{{$v.Name}}|||{{$v.IPv4Address}}|||{{$v.MacAddress}};;;{{end}}' \(id)", serverId: serverId)
        let connectedContainers = containersResult.stdout.components(separatedBy: ";;;").compactMap { entry -> (name: String, ip: String, mac: String)? in
            let parts = entry.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            return (name: parts[0], ip: parts[1], mac: parts[2])
        }

        return NetworkInspection(subnet: subnet, gateway: gateway, scope: scope, connectedContainers: connectedContainers)
    }

    // MARK: - Private Helpers

    private func parseNetworkBytes(_ str: String) -> Int64 {
        let t = str.trimmingCharacters(in: .whitespaces).uppercased()
        if t.hasSuffix("GB") { return Int64((Double(t.dropLast(2)) ?? 0) * 1_073_741_824) }
        if t.hasSuffix("MB") { return Int64((Double(t.dropLast(2)) ?? 0) * 1_048_576) }
        if t.hasSuffix("KB") { return Int64((Double(t.dropLast(2)) ?? 0) * 1024) }
        if t.hasSuffix("B") { return Int64(t.dropLast(1)) ?? 0 }
        return Int64(t) ?? 0
    }

    private func tokenize(_ command: String) -> [String] {
        var tokens: [String] = []; var current = ""; var inQuote: Character? = nil
        for char in command {
            if let q = inQuote { if char == q { inQuote = nil } else { current.append(char) } }
            else if char == "'" || char == "\"" { inQuote = char }
            else if char == " " { if !current.isEmpty { tokens.append(current); current = "" } }
            else { current.append(char) }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}
