//
//  DockerService+Scheduler.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    public func scheduleContainerAction(containerName: String, action: String, schedule: String, serverId: String) async throws {
        try await requireFeature(.dockerTools)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let safeName = shellQuote(containerName)

        let cronCmd: String
        switch action.lowercased() {
        case "restart": cronCmd = "\(dockerPath) restart \(safeName)"
        case "stop": cronCmd = "\(dockerPath) stop \(safeName)"
        case "start": cronCmd = "\(dockerPath) start \(safeName)"
        default: throw DockerError.commandFailed("schedule", "Unknown action: \(action)")
        }

        let cronEntry = "\(schedule) \(cronCmd) # aevonx-docker-\(containerName)-\(action)"
        let addCmd = "(crontab -l 2>/dev/null | grep -v 'aevonx-docker-\(containerName)-\(action)'; echo '# AevonX Docker Schedule: \(action) \(containerName)'; echo '\(cronEntry)') | crontab -"
        let result = await sshExec(addCmd, serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("crontab", result.stderr) }
    }

    public func listScheduledActions(serverId: String) async throws -> [ScheduledAction] {
        try await requireFeature(.dockerTools)
        let result = await sshExec("crontab -l 2>/dev/null | grep 'aevonx-docker-' || echo ''", serverId: serverId)
        var actions: [ScheduledAction] = []

        for line in result.stdout.components(separatedBy: .newlines) where line.contains("aevonx-docker-") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("#") else { continue }
            let parts = trimmed.split(separator: " ", maxSplits: 5).map(String.init)
            guard parts.count >= 6 else { continue }
            let schedule = parts[0...4].joined(separator: " ")

            if let tagRange = trimmed.range(of: "aevonx-docker-") {
                let tag = String(trimmed[tagRange.upperBound...])
                let tagParts = tag.components(separatedBy: "-")
                let action = tagParts.last ?? "unknown"
                let containerName = tagParts.dropLast().joined(separator: "-")
                actions.append(ScheduledAction(containerName: containerName, action: action, schedule: schedule,
                                               description: "\(action.capitalized) \(containerName)", isActive: true))
            }
        }
        return actions
    }

    public func removeScheduledAction(containerName: String, action: String, serverId: String) async throws {
        try await requireFeature(.dockerTools)
        let result = await sshExec("crontab -l 2>/dev/null | grep -v 'aevonx-docker-\(containerName)-\(action)' | crontab -", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("remove schedule", result.stderr) }
    }

    // MARK: - Port Conflict Detection

    public func checkPortConflicts(ports: [String], serverId: String) async throws -> [PortConflict] {
        try await requireFeature(.dockerTools)
        var conflicts: [PortConflict] = []
        for port in ports where !port.isEmpty {
            let hostPort = port.components(separatedBy: ":").first ?? port
            let result = await sshExec("ss -tlnp 'sport = :\(hostPort)' 2>/dev/null | tail -n +2 || netstat -tlnp 2>/dev/null | grep ':\(hostPort) '", serverId: serverId)
            if !result.stdout.isEmpty {
                if let dockerPath = try? await getDockerPath(serverId: serverId) {
                    let dockerResult = await sshExec("\(dockerPath) ps --filter 'publish=\(hostPort)' --format '{{.Names}}' 2>/dev/null", serverId: serverId)
                    let containerName = dockerResult.stdout
                    conflicts.append(PortConflict(port: hostPort, usedByProcess: result.stdout.components(separatedBy: .newlines).first ?? "unknown",
                                                  usedByContainer: containerName.isEmpty ? nil : containerName))
                }
            }
        }
        return conflicts
    }

    public func suggestAvailablePorts(near port: Int, count: Int = 3, serverId: String) async throws -> [Int] {
        try await requireFeature(.dockerTools)
        var available: [Int] = []; var candidate = port + 1
        while available.count < count && candidate < 65535 {
            let result = await sshExec("ss -tlnp 'sport = :\(candidate)' 2>/dev/null | tail -n +2", serverId: serverId)
            if result.stdout.isEmpty { available.append(candidate) }
            candidate += 1
        }
        return available
    }

    // MARK: - Container Cloning

    public func cloneContainer(containerId: String, newName: String, serverId: String,
                                progress: @escaping @Sendable (String) -> Void) async throws {
        try await requireFeature(.dockerTools)
        let dockerPath = try await getDockerPath(serverId: serverId)

        progress("Reading container configuration...")
        let fmt = "{{.Config.Image}}|||{{.HostConfig.RestartPolicy.Name}}|||{{range .Config.Env}}{{.}};;;{{end}}|||{{range .Mounts}}{{.Type}}:{{.Source}}:{{.Destination}},{{end}}|||{{range $k,$v := .NetworkSettings.Networks}}{{$k}},{{end}}"
        let result = await sshExec("\(dockerPath) inspect --format '\(fmt)' \(containerId)", serverId: serverId)
        let parts = result.stdout.components(separatedBy: "|||")

        let image = parts.count > 0 ? parts[0] : ""
        guard !image.isEmpty else { throw DockerError.commandFailed("clone", "Could not determine image") }

        progress("Creating cloned container...")
        var runFlags = ["-d", "--name \(shellQuote(newName))"]
        let restartPolicy = parts.count > 1 ? parts[1] : "no"
        if restartPolicy != "no" && !restartPolicy.isEmpty { runFlags.append("--restart=\(restartPolicy)") }

        let systemPrefixes = ["PATH=", "HOSTNAME=", "HOME="]
        let envStr = parts.count > 2 ? parts[2] : ""
        for env in envStr.components(separatedBy: ";;;") where !env.isEmpty {
            if !systemPrefixes.contains(where: { env.hasPrefix($0) }) {
                runFlags.append("-e '\(env.replacingOccurrences(of: "'", with: "'\\''"))'")
            }
        }

        let networkStr = parts.count > 4 ? parts[4] : ""
        if let firstNet = networkStr.components(separatedBy: ",").first(where: { !$0.isEmpty }) {
            runFlags.append("--network \(shellQuote(firstNet))")
        }

        let runResult = await sshExec("\(dockerPath) run \(runFlags.joined(separator: " ")) \(shellQuote(image))", serverId: serverId)
        guard runResult.exitCode == 0 else { throw DockerError.commandFailed("clone", runResult.stderr) }
        progress("Container cloned ✅")
    }
}
