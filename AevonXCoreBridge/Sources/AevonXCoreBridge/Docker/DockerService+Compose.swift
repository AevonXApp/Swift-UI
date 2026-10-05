//
//  DockerService+Compose.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    public func listComposeProjects(serverId: String) async throws -> [DockerComposeProject] {
        try await requireFeature(.dockerCompose)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let fmt = "{{.Name}}|||{{.Status}}|||{{.ConfigFiles}}"
        let cmd = "\(dockerPath) compose ls --format 'table' 2>/dev/null || echo ''"
        let result = await sshExec(cmd, serverId: serverId)
        guard result.exitCode == 0 else { return [] }

        let composeCmd = "\(dockerPath) compose ls --format '\\(fmt)' 2>/dev/null || echo ''"
        let composeResult = await sshExec(composeCmd, serverId: serverId)

        return composeResult.stdout.components(separatedBy: .newlines).compactMap { line in
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            return DockerComposeProject(
                name: parts[0], status: parts[1], configFiles: parts[2],
                workingDir: parts[2].components(separatedBy: "/").dropLast().joined(separator: "/")
            )
        }
    }

    public func composeUp(workingDir: String, serverId: String) async throws {
        try await requireFeature(.dockerCompose)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("cd \(shellQuote(workingDir)) && \(dockerPath) compose up -d 2>&1", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("compose up", result.stderr) }
    }

    public func composeDown(workingDir: String, serverId: String) async throws {
        try await requireFeature(.dockerCompose)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("cd \(shellQuote(workingDir)) && \(dockerPath) compose down 2>&1", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("compose down", result.stderr) }
    }

    public func composeRestart(workingDir: String, serverId: String) async throws {
        try await requireFeature(.dockerCompose)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("cd \(shellQuote(workingDir)) && \(dockerPath) compose restart 2>&1", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("compose restart", result.stderr) }
    }

    public func composeLogs(workingDir: String, tail: Int = 100, serverId: String) async throws -> String {
        try await requireFeature(.dockerCompose)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("cd \(shellQuote(workingDir)) && \(dockerPath) compose logs --tail \(tail) 2>&1", serverId: serverId)
        return result.stdout
    }

    public func deployTemplate(name: String, compose: String, workingDir: String, serverId: String) async throws {
        try await requireFeature(.dockerCompose)
        let safeName = name.lowercased().replacingOccurrences(of: " ", with: "-")
        let dir = "\(workingDir)/\(safeName)"
        let escaped = compose.replacingOccurrences(of: "'", with: "'\\''")

        let setupResult = await sshExec("sudo mkdir -p \(shellQuote(dir)) && sudo chown -R $USER:$USER \(shellQuote(dir))", serverId: serverId)
        guard setupResult.exitCode == 0 else { throw DockerError.commandFailed("mkdir", setupResult.stderr) }

        let writeResult = await sshExec("printf '%s' '\(escaped)' > \(shellQuote(dir))/docker-compose.yml", serverId: serverId)
        guard writeResult.exitCode == 0 else { throw DockerError.commandFailed("write compose", writeResult.stderr) }

        try await composeUp(workingDir: dir, serverId: serverId)
    }

    /// Convenience overload used by AI Compose Generator (no workingDir, uses /opt/docker)
    public func deployTemplate(name: String, composeContent: String, serverId: String) async throws {
        try await requireFeature(.dockerCompose)
        try await deployTemplate(name: name, compose: composeContent, workingDir: "/opt/docker", serverId: serverId)
    }

    public func readComposeFile(workingDir: String, serverId: String) async throws -> String {
        try await requireFeature(.dockerCompose)
        let result = await sshExec("cat \(shellQuote(workingDir))/docker-compose.yml 2>/dev/null || cat \(shellQuote(workingDir))/docker-compose.yaml 2>/dev/null || echo ''", serverId: serverId)
        return result.stdout
    }

    public func writeComposeFile(content: String, workingDir: String, serverId: String) async throws {
        try await requireFeature(.dockerCompose)
        let escaped = content.replacingOccurrences(of: "'", with: "'\\''")
        let result = await sshExec("printf '%s' '\(escaped)' > \(shellQuote(workingDir))/docker-compose.yml", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("write compose", result.stderr) }
    }

    public func composeScale(service: String, replicas: Int, workingDir: String, serverId: String) async throws {
        try await requireFeature(.dockerCompose)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("cd \(shellQuote(workingDir)) && \(dockerPath) compose up -d --scale \(shellQuote(service))=\(replicas) 2>&1", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("compose scale", result.stderr) }
    }

    public func composeValidate(workingDir: String, serverId: String) async throws -> ComposeValidationResult {
        try await requireFeature(.dockerCompose)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("cd \(shellQuote(workingDir)) && \(dockerPath) compose config 2>&1", serverId: serverId)
        return ComposeValidationResult(
            isValid: result.exitCode == 0,
            resolvedConfig: result.exitCode == 0 ? result.stdout : nil,
            errorOutput: result.exitCode != 0 ? result.stdout : nil
        )
    }

    public func getComposeServices(workingDir: String, serverId: String) async throws -> [ComposeServiceInfo] {
        try await requireFeature(.dockerCompose)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let cmd = "cd \(shellQuote(workingDir)) && \(dockerPath) compose ps --format '{{.Name}}|||{{.Service}}|||{{.Replicas}}' 2>/dev/null || echo ''"
        let result = await sshExec(cmd, serverId: serverId)

        return result.stdout.components(separatedBy: .newlines).compactMap { line in
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            let replicas = Int(parts[2].components(separatedBy: "/").first ?? "1") ?? 1
            return ComposeServiceInfo(name: parts[1], replicas: replicas)
        }
    }

    public func readEnvFile(workingDir: String, serverId: String) async throws -> [EnvEntry] {
        try await requireFeature(.dockerCompose)
        let result = await sshExec("cat \(shellQuote(workingDir))/.env 2>/dev/null || echo ''", serverId: serverId)
        return result.stdout.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
            let kv = trimmed.components(separatedBy: "=")
            guard kv.count >= 2 else { return nil }
            let key = kv[0]
            let value = kv.dropFirst().joined(separator: "=")
            let isSecret = key.lowercased().contains("password") || key.lowercased().contains("secret") || key.lowercased().contains("key")
            return EnvEntry(key: key, value: value, isSecret: isSecret)
        }
    }

    public func writeEnvFile(workingDir: String, content: String, serverId: String) async throws {
        try await requireFeature(.dockerCompose)
        let escaped = content.replacingOccurrences(of: "'", with: "'\\''")
        let result = await sshExec("printf '%s' '\(escaped)' > \(shellQuote(workingDir))/.env", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("write .env", result.stderr) }
    }

    public func writeEnvFile(workingDir: String, entries: [EnvEntry], serverId: String) async throws {
        try await requireFeature(.dockerCompose)
        let content = entries.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
        try await writeEnvFile(workingDir: workingDir, content: content, serverId: serverId)
    }
}
