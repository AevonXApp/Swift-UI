//
//  DockerService+AutoUpdate.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    public func checkAllImageUpdates(serverId: String) async throws -> [ImageUpdateStatus] {
        try await requireFeature(.dockerTools)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }

        let fmt = "{{.ID}}|||{{.Image}}|||{{.Names}}"
        let result = await sshExec("\(dockerPath) ps --format '\(fmt)'", serverId: serverId)

        var imageContainers: [String: (ids: [String], names: [String])] = [:]
        for line in result.stdout.components(separatedBy: .newlines) where !line.isEmpty {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 3 else { continue }
            var entry = imageContainers[parts[1]] ?? (ids: [], names: [])
            entry.ids.append(parts[0]); entry.names.append(parts[2])
            imageContainers[parts[1]] = entry
        }

        var statuses: [ImageUpdateStatus] = []
        for (image, containers) in imageContainers {
            let components = image.components(separatedBy: ":")
            let tag = components.count > 1 ? components[1] : "latest"

            let localResult = await sshExec("\(dockerPath) inspect --format '{{index .RepoDigests 0}}' \(shellQuote(image)) 2>/dev/null || echo 'none'", serverId: serverId)
            let localDigest = localResult.stdout

            let remoteResult = await sshExec("\(dockerPath) manifest inspect \(shellQuote(image)) 2>/dev/null | grep -m1 '\"digest\"' | awk -F'\"' '{print $4}'", serverId: serverId)
            let remoteDigest = remoteResult.stdout

            let isOutdated: Bool
            if localDigest == "none" || localDigest.isEmpty { isOutdated = true }
            else if remoteDigest.isEmpty { isOutdated = false }
            else { isOutdated = (localDigest.components(separatedBy: "@").last ?? localDigest) != remoteDigest }

            statuses.append(ImageUpdateStatus(
                imageName: image, currentTag: tag, localDigest: localDigest, remoteDigest: remoteDigest,
                isOutdated: isOutdated, containerIds: containers.ids, containerNames: containers.names, lastChecked: Date()
            ))
        }
        return statuses.sorted { $0.isOutdated && !$1.isOutdated }
    }

    public func updateContainerImage(containerId: String, serverId: String, createSnapshot: Bool = true,
                                      progress: @escaping @Sendable (String, Double) -> Void) async throws {
        try await requireFeature(.dockerTools)
        let dockerPath = try await getDockerPath(serverId: serverId)

        progress("Inspecting container...", 0.1)
        let nameResult = await sshExec("\(dockerPath) inspect --format '{{.Name}}|||{{.Config.Image}}' \(containerId)", serverId: serverId)
        let nameParts = nameResult.stdout.components(separatedBy: "|||")
        let containerName = (nameParts.first ?? "").replacingOccurrences(of: "/", with: "")
        let imageName = nameParts.count > 1 ? nameParts[1] : ""
        guard !containerName.isEmpty, !imageName.isEmpty else { throw DockerError.commandFailed("update", "Could not determine name/image") }

        if createSnapshot {
            progress("Creating rollback snapshot...", 0.2)
            let _ = try await createRollbackSnapshot(containerId: containerId, containerName: containerName, serverId: serverId)
        }

        progress("Pulling latest image...", 0.4)
        let pullResult = await sshExec("\(dockerPath) pull \(shellQuote(imageName))", serverId: serverId)
        guard pullResult.exitCode == 0 else { throw DockerError.commandFailed("pull", pullResult.stderr) }

        progress("Stopping container...", 0.6)
        let _ = await sshExec("\(dockerPath) stop \(containerId)", serverId: serverId)

        let backupName = "\(containerName)-updating"
        let _ = await sshExec("\(dockerPath) rename \(containerId) \(shellQuote(backupName))", serverId: serverId)

        progress("Recreating container...", 0.7)
        let runResult = await sshExec("\(dockerPath) run -d --name \(shellQuote(containerName)) \(shellQuote(imageName))", serverId: serverId)

        if runResult.exitCode == 0 {
            progress("Cleaning up...", 0.9)
            let _ = await sshExec("\(dockerPath) rm -f \(shellQuote(backupName))", serverId: serverId)
            progress("Update completed ✅", 1.0)
        } else {
            progress("Update failed, restoring...", 0.9)
            let _ = await sshExec("\(dockerPath) rename \(shellQuote(backupName)) \(shellQuote(containerName))", serverId: serverId)
            let _ = await sshExec("\(dockerPath) start \(shellQuote(containerName))", serverId: serverId)
            throw DockerError.commandFailed("update", runResult.stderr)
        }
    }

    public func isWatchtowerRunning(serverId: String) async throws -> Bool {
        try await requireFeature(.dockerTools)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return false }
        let result = await sshExec("\(dockerPath) ps --filter 'name=watchtower' --format '{{.Names}}'", serverId: serverId)
        return result.stdout.contains("watchtower")
    }

    public func deployWatchtower(schedule: String = "0 0 4 * * *", cleanup: Bool = true, notifyOnly: Bool = false, serverId: String) async throws {
        try await requireFeature(.dockerTools)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let _ = await sshExec("\(dockerPath) rm -f watchtower 2>/dev/null || true", serverId: serverId)

        var flags = ["-d", "--name watchtower", "--restart unless-stopped", "-v /var/run/docker.sock:/var/run/docker.sock"]
        flags.append("-e WATCHTOWER_SCHEDULE='\(schedule)'")
        if cleanup { flags.append("-e WATCHTOWER_CLEANUP=true") }
        if notifyOnly { flags.append("-e WATCHTOWER_MONITOR_ONLY=true") }

        let result = await sshExec("\(dockerPath) run \(flags.joined(separator: " ")) containrrr/watchtower", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("deploy watchtower", result.stderr) }
    }

    public func removeWatchtower(serverId: String) async throws {
        try await requireFeature(.dockerTools)
        try await runDockerCommand("rm -f watchtower", serverId: serverId)
    }
}
