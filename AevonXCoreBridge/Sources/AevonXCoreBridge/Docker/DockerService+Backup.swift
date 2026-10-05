//
//  DockerService+Backup.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    public func backupContainer(containerId: String, backupDir: String = "/opt/aevonx/docker-backups",
                                 serverId: String, progress: @escaping @Sendable (String, Double) -> Void) async throws -> ContainerBackup {
        try await requireFeature(.dockerExport)
        let dockerPath = try await getDockerPath(serverId: serverId)

        let nameResult = await sshExec("\(dockerPath) inspect --format '{{.Name}}' \(containerId)", serverId: serverId)
        let containerName = nameResult.stdout.replacingOccurrences(of: "/", with: "")

        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-")
        let safeName = containerName.replacingOccurrences(of: " ", with: "-")
        let backupPath = "\(backupDir)/\(safeName)-\(timestamp)"

        let mkdirResult = await sshExec("mkdir -p \(shellQuote(backupPath))", serverId: serverId)
        guard mkdirResult.exitCode == 0 else { throw DockerError.commandFailed("mkdir", mkdirResult.stderr) }

        // 1. Save image
        progress("Saving container image...", 0.2)
        let commitTag = "backup-\(safeName):\(timestamp)"
        let commitResult = await sshExec("\(dockerPath) commit \(containerId) \(shellQuote(commitTag))", serverId: serverId)
        let imageSaved = commitResult.exitCode == 0
        if imageSaved {
            let _ = await sshExec("\(dockerPath) save \(shellQuote(commitTag)) | gzip > \(shellQuote(backupPath))/image.tar.gz", serverId: serverId)
            let _ = await sshExec("\(dockerPath) rmi \(shellQuote(commitTag)) 2>/dev/null || true", serverId: serverId)
        }

        // 2. Backup volumes
        progress("Backing up volumes...", 0.5)
        let mountsResult = await sshExec("\(dockerPath) inspect --format '{{range .Mounts}}{{.Type}}|||{{.Source}}|||{{.Destination}}|||{{.Name}}\\n{{end}}' \(containerId)", serverId: serverId)
        var volumesSaved = 0
        for line in mountsResult.stdout.components(separatedBy: .newlines) where !line.isEmpty {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 4 else { continue }
            if parts[0] == "volume" && !parts[3].isEmpty {
                let volCmd = "\(dockerPath) run --rm -v \(shellQuote(parts[3])):/data -v \(shellQuote(backupPath)):/backup alpine tar czf /backup/vol-\(shellQuote(parts[3])).tar.gz -C /data ."
                let volResult = await sshExec(volCmd, serverId: serverId)
                if volResult.exitCode == 0 { volumesSaved += 1 }
            }
        }

        // 3. Save config
        progress("Saving configuration...", 0.8)
        let configResult = await sshExec("\(dockerPath) inspect \(containerId) > \(shellQuote(backupPath))/config.json", serverId: serverId)

        let sizeResult = await sshExec("du -sh \(shellQuote(backupPath)) | awk '{print $1}'", serverId: serverId)

        progress("Backup completed ✅", 1.0)
        return ContainerBackup(containerName: containerName, backupPath: backupPath, imageSaved: imageSaved,
                               volumesSaved: volumesSaved, configSaved: configResult.exitCode == 0,
                               totalSizeMB: sizeResult.stdout, createdAt: Date())
    }

    public func listBackups(backupDir: String = "/opt/aevonx/docker-backups", serverId: String) async throws -> [BackupEntry] {
        try await requireFeature(.dockerExport)
        let result = await sshExec("ls -1d \(shellQuote(backupDir))/*/ 2>/dev/null || echo ''", serverId: serverId)
        var backups: [BackupEntry] = []

        for dir in result.stdout.components(separatedBy: .newlines) where !dir.isEmpty && dir != backupDir {
            let cleanDir = dir.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let name = cleanDir.components(separatedBy: "/").last ?? cleanDir
            let lsResult = await sshExec("ls \(shellQuote(dir)) 2>/dev/null", serverId: serverId)
            let sizeResult = await sshExec("du -sh \(shellQuote(dir)) | awk '{print $1}'", serverId: serverId)
            let dateResult = await sshExec("stat -c '%Y' \(shellQuote(dir)) 2>/dev/null || stat -f '%m' \(shellQuote(dir)) 2>/dev/null", serverId: serverId)
            let volumeCount = lsResult.stdout.components(separatedBy: .newlines).filter { $0.contains("vol-") || $0.contains("bind") }.count

            backups.append(BackupEntry(name: name, path: dir, size: sizeResult.stdout,
                                       date: dateResult.stdout, hasImage: lsResult.stdout.contains("image.tar.gz"),
                                       hasConfig: lsResult.stdout.contains("config.json"), volumeCount: volumeCount))
        }
        return backups
    }

    public func restoreFromBackup(backupPath: String, newName: String? = nil, serverId: String,
                                   progress: @escaping @Sendable (String, Double) -> Void) async throws {
        try await requireFeature(.dockerExport)
        let dockerPath = try await getDockerPath(serverId: serverId)

        progress("Loading container image...", 0.2)
        let loadResult = await sshExec("gunzip -c \(shellQuote(backupPath))/image.tar.gz | \(dockerPath) load", serverId: serverId)
        guard loadResult.exitCode == 0 else { throw DockerError.commandFailed("docker load", loadResult.stderr) }

        let imageTag = loadResult.stdout.components(separatedBy: "Loaded image: ").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !imageTag.isEmpty else { throw DockerError.commandFailed("restore", "Could not determine loaded image name") }

        progress("Creating container...", 0.6)
        let containerName = newName ?? imageTag.components(separatedBy: ":").first?.replacingOccurrences(of: "backup-", with: "") ?? "restored"
        let runResult = await sshExec("\(dockerPath) run -d --name \(shellQuote(containerName)) \(shellQuote(imageTag))", serverId: serverId)
        guard runResult.exitCode == 0 else { throw DockerError.commandFailed("docker run", runResult.stderr) }

        progress("Container restored ✅", 1.0)
    }

    public func deleteBackup(backupPath: String, serverId: String) async throws {
        try await requireFeature(.dockerExport)
        let result = await sshExec("rm -rf \(shellQuote(backupPath))", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("delete backup", result.stderr) }
    }
}
