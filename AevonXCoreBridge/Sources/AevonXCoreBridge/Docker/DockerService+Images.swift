//
//  DockerService+Images.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    public func tagImage(id: String, newTag: String, serverId: String) async throws {
        try await runDockerCommand("tag \(id) \(shellQuote(newTag))", serverId: serverId)
    }

    public func pushImage(tag: String, serverId: String) async throws -> String {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) push \(shellQuote(tag)) 2>&1", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("push", result.stderr) }
        return result.stdout
    }

    public func getImageLayers(id: String, serverId: String) async throws -> [ImageLayer] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let cmd = "\(dockerPath) history --no-trunc --format '{{.CreatedAt}}|||{{.CreatedBy}}|||{{.Size}}' \(id)"
        let result = await sshExec(cmd, serverId: serverId)
        guard result.exitCode == 0 else { return [] }

        return result.stdout.components(separatedBy: .newlines).compactMap { line in
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            return ImageLayer(created: parts[0], createdBy: parts[1], size: parts[2])
        }
    }

    public func searchHub(query: String, limit: Int = 25, serverId: String) async throws -> [HubSearchResult] {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let cmd = "\(dockerPath) search --limit \(limit) --format '{{.Name}}|||{{.Description}}|||{{.StarCount}}|||{{.IsOfficial}}|||{{.IsAutomated}}' \(shellQuote(query))"
        let result = await sshExec(cmd, serverId: serverId)
        guard result.exitCode == 0 else { return [] }

        return result.stdout.components(separatedBy: .newlines).compactMap { line in
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 5 else { return nil }
            return HubSearchResult(
                name: parts[0], description: parts[1],
                stars: Int(parts[2]) ?? 0, isOfficial: parts[3] == "true", isAutomated: parts[4] == "true"
            )
        }
    }

    public func buildImageFromDockerfile(content: String, tag: String, serverId: String,
                                          progress: @escaping @Sendable (String, Double) -> Void) async throws {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let buildDir = "/tmp/aevonx-docker-build-\(UUID().uuidString.prefix(8))"

        progress("Preparing build context...", 0.1)
        let escaped = content.replacingOccurrences(of: "'", with: "'\\''")
        let setupResult = await sshExec("mkdir -p \(buildDir) && echo '\(escaped)' > \(buildDir)/Dockerfile", serverId: serverId)
        guard setupResult.exitCode == 0 else { throw DockerError.commandFailed("setup build", setupResult.stderr) }

        progress("Building image...", 0.3)
        let buildResult = await sshExec("\(dockerPath) build -t \(shellQuote(tag)) \(buildDir) 2>&1", serverId: serverId)

        let _ = await sshExec("rm -rf \(buildDir)", serverId: serverId)

        guard buildResult.exitCode == 0 else { throw DockerError.commandFailed("docker build", buildResult.stderr) }
        progress("Image built successfully ✅", 1.0)
    }

    /// Convenience overload without progress callback, returns build output
    public func buildImageFromDockerfile(content: String, tag: String, serverId: String) async throws -> String {
        var output = ""
        try await buildImageFromDockerfile(content: content, tag: tag, serverId: serverId) { msg, _ in
            output += msg + "\n"
        }
        return output
    }

    public func checkImageUpdate(image: String, serverId: String) async throws -> ImageUpdateInfo {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let components = image.components(separatedBy: ":")
        let repo = components[0]
        let tag = components.count > 1 ? components[1] : "latest"

        let localCmd = "\(dockerPath) inspect --format '{{index .RepoDigests 0}}' \(shellQuote(image)) 2>/dev/null || echo 'none'"
        let localResult = await sshExec(localCmd, serverId: serverId)
        let localDigest = localResult.stdout

        let remoteCmd = "\(dockerPath) manifest inspect \(shellQuote(image)) 2>/dev/null | grep -m1 '\"digest\"' | awk -F'\"' '{print $4}'"
        let remoteResult = await sshExec(remoteCmd, serverId: serverId)
        let remoteDigest = remoteResult.stdout

        let isOutdated: Bool
        if localDigest == "none" || localDigest.isEmpty {
            isOutdated = true
        } else if remoteDigest.isEmpty {
            isOutdated = false
        } else {
            let localSha = localDigest.components(separatedBy: "@").last ?? localDigest
            isOutdated = localSha != remoteDigest
        }

        return ImageUpdateInfo(repository: repo, tag: tag, localDigest: localDigest, remoteDigest: remoteDigest, isOutdated: isOutdated)
    }

    public func getImageSize(id: String, serverId: String) async throws -> String {
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("\(dockerPath) inspect --format '{{.Size}}' \(id)", serverId: serverId)
        guard let bytes = Int64(result.stdout) else { return "Unknown" }
        return DockerFormatter.formatBytes(bytes)
    }
}
