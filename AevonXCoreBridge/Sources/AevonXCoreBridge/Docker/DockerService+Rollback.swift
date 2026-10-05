//
//  DockerService+Rollback.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    public func createRollbackSnapshot(containerId: String, containerName: String, serverId: String) async throws -> RollbackSnapshot {
        try await requireFeature(.dockerTools)
        let dockerPath = try await getDockerPath(serverId: serverId)

        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: "+", with: "-")
        let safeName = containerName.lowercased().replacingOccurrences(of: "/", with: "").replacingOccurrences(of: " ", with: "-")
        let snapshotTag = "aevonx-rollback/\(safeName):\(timestamp)"

        let commitResult = await sshExec("\(dockerPath) commit \(containerId) \(shellQuote(snapshotTag))", serverId: serverId)
        guard commitResult.exitCode == 0 else { throw DockerError.commandFailed("commit", commitResult.stderr) }
        let snapshotImageId = commitResult.stdout

        let inspectFmt = "{{.Config.Image}}|||{{.HostConfig.RestartPolicy.Name}}|||{{range .Mounts}}{{.Source}}:{{.Destination}},{{end}}|||{{range $k,$v := .NetworkSettings.Networks}}{{$k}},{{end}}"
        let inspectResult = await sshExec("\(dockerPath) inspect --format '\(inspectFmt)' \(containerId)", serverId: serverId)
        let parts = inspectResult.stdout.components(separatedBy: "|||")

        let portsResult = await sshExec("\(dockerPath) port \(containerId) 2>/dev/null || echo ''", serverId: serverId)
        let envResult = await sshExec("\(dockerPath) inspect --format '{{range .Config.Env}}{{.}}|||{{end}}' \(containerId)", serverId: serverId)
        let labelsResult = await sshExec("\(dockerPath) inspect --format '{{range $k,$v := .Config.Labels}}{{$k}}={{$v}}|||{{end}}' \(containerId)", serverId: serverId)

        var labels: [String: String] = [:]
        for entry in labelsResult.stdout.components(separatedBy: "|||") where !entry.isEmpty {
            let kv = entry.components(separatedBy: "=")
            if kv.count >= 2 { labels[kv[0]] = kv.dropFirst().joined(separator: "=") }
        }

        let volumeStr = parts.count > 2 ? parts[2] : ""
        let networkStr = parts.count > 3 ? parts[3] : ""

        return RollbackSnapshot(
            snapshotImageId: snapshotImageId, containerName: containerName,
            originalImage: parts.count > 0 ? parts[0] : "", snapshotTag: snapshotTag, createdAt: timestamp,
            ports: portsResult.stdout, envVars: envResult.stdout.components(separatedBy: "|||").filter { !$0.isEmpty },
            volumes: volumeStr.components(separatedBy: ",").filter { !$0.isEmpty },
            networks: networkStr.components(separatedBy: ",").filter { !$0.isEmpty },
            restartPolicy: parts.count > 1 ? parts[1] : "no", labels: labels
        )
    }

    public func listRollbackSnapshots(serverId: String) async throws -> [RollbackSnapshot] {
        try await requireFeature(.dockerTools)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }

        let cmd = "\(dockerPath) images 'aevonx-rollback/*' --format '{{.ID}}|||{{.Repository}}|||{{.Tag}}|||{{.CreatedAt}}' 2>/dev/null || echo ''"
        let result = await sshExec(cmd, serverId: serverId)

        return result.stdout.components(separatedBy: .newlines).compactMap { line -> RollbackSnapshot? in
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 4 else { return nil }
            let containerName = parts[1].replacingOccurrences(of: "aevonx-rollback/", with: "")
            return RollbackSnapshot(snapshotImageId: parts[0], containerName: containerName, originalImage: "",
                                    snapshotTag: "\(parts[1]):\(parts[2])", createdAt: parts[3], ports: "",
                                    envVars: [], volumes: [], networks: [], restartPolicy: "", labels: [:])
        }
    }

    public func rollbackContainer(containerId: String, containerName: String, snapshot: RollbackSnapshot,
                                   serverId: String, progress: @escaping @Sendable (String) -> Void) async throws {
        try await requireFeature(.dockerTools)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let safeName = shellQuote(containerName.hasPrefix("/") ? String(containerName.dropFirst()) : containerName)

        progress("Stopping current container...")
        let _ = await sshExec("\(dockerPath) stop \(containerId)", serverId: serverId)

        progress("Backing up current container...")
        let backupName = "\(containerName)-pre-rollback"
        let _ = await sshExec("\(dockerPath) rename \(containerId) \(shellQuote(backupName))", serverId: serverId)

        progress("Creating rolled-back container...")
        var runFlags = ["-d", "--name \(safeName)"]
        if !snapshot.restartPolicy.isEmpty && snapshot.restartPolicy != "no" { runFlags.append("--restart=\(snapshot.restartPolicy)") }
        for vol in snapshot.volumes { runFlags.append("-v \(shellQuote(vol))") }
        for net in snapshot.networks { runFlags.append("--network \(shellQuote(net))") }
        let systemPrefixes = ["PATH=", "HOSTNAME=", "HOME="]
        for env in snapshot.envVars {
            if !systemPrefixes.contains(where: { env.hasPrefix($0) }) {
                let escaped = env.replacingOccurrences(of: "'", with: "'\\''")
                runFlags.append("-e '\(escaped)'")
            }
        }

        let runResult = await sshExec("\(dockerPath) run \(runFlags.joined(separator: " ")) \(shellQuote(snapshot.snapshotTag))", serverId: serverId)
        guard runResult.exitCode == 0 else {
            progress("Rollback failed, restoring original...")
            let _ = await sshExec("\(dockerPath) rename \(shellQuote(backupName)) \(safeName)", serverId: serverId)
            let _ = await sshExec("\(dockerPath) start \(safeName)", serverId: serverId)
            throw DockerError.commandFailed("rollback", runResult.stderr)
        }

        let _ = await sshExec("\(dockerPath) rm -f \(shellQuote(backupName))", serverId: serverId)
        progress("Rollback completed ✅")
    }

    public func deleteRollbackSnapshot(snapshotTag: String, serverId: String) async throws {
        try await requireFeature(.dockerTools)
        try await runDockerCommand("rmi \(shellQuote(snapshotTag))", serverId: serverId)
    }

    public func cleanupOldSnapshots(olderThanDays: Int, serverId: String) async throws -> Int {
        try await requireFeature(.dockerTools)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return 0 }
        let result = await sshExec("\(dockerPath) images 'aevonx-rollback/*' --format '{{.Repository}}:{{.Tag}}|||{{.CreatedAt}}' 2>/dev/null || echo ''", serverId: serverId)

        var removed = 0
        let cutoff = Date().addingTimeInterval(-Double(olderThanDays * 86400))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        for line in result.stdout.components(separatedBy: .newlines) where !line.isEmpty {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 2 else { continue }
            if let date = formatter.date(from: parts[1].trimmingCharacters(in: .whitespaces)), date < cutoff {
                let _ = await sshExec("\(dockerPath) rmi \(shellQuote(parts[0])) 2>/dev/null || true", serverId: serverId)
                removed += 1
            }
        }
        return removed
    }
}
