//
//  DockerService+Secrets.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    public func listSecrets(serverId: String) async throws -> [DockerSecret] {
        try await requireFeature(.dockerTools)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }
        let fmt = "{{.ID}}|||{{.Name}}|||{{.CreatedAt}}|||{{.UpdatedAt}}"
        let result = await sshExec("\(dockerPath) secret ls --format '\(fmt)' 2>/dev/null || echo ''", serverId: serverId)

        return result.stdout.components(separatedBy: .newlines).compactMap { line in
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 4 else { return nil }
            return DockerSecret(name: parts[1], createdAt: parts[2], updatedAt: parts[3])
        }
    }

    public func createSecret(name: String, value: String, serverId: String) async throws {
        try await requireFeature(.dockerTools)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let result = await sshExec("echo \(shellQuote(value)) | \(dockerPath) secret create \(shellQuote(name)) -", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("secret create", result.stderr) }
    }

    public func deleteSecret(name: String, serverId: String) async throws {
        try await requireFeature(.dockerTools)
        try await runDockerCommand("secret rm \(shellQuote(name))", serverId: serverId)
    }

    // MARK: - Container Groups

    public func getContainerGroups(serverId: String) async throws -> [ContainerGroup] {
        try await requireFeature(.dockerTools)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }
        let fmt = "{{.Names}}|||{{index .Labels \"aevonx.group\"}}"
        let result = await sshExec("\(dockerPath) ps -a --format '\(fmt)' 2>/dev/null || echo ''", serverId: serverId)

        var groups: [String: [String]] = [:]
        for line in result.stdout.components(separatedBy: .newlines) where !line.isEmpty {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 2 else { continue }
            let group = parts[1].trimmingCharacters(in: .whitespaces)
            groups[group.isEmpty ? "Ungrouped" : group, default: []].append(parts[0])
        }
        return groups.map { ContainerGroup(label: $0.key, containerCount: $0.value.count, containerNames: $0.value) }.sorted { $0.label < $1.label }
    }

    public func setContainerGroup(containerId: String, group: String, serverId: String) async throws {
        try await requireFeature(.dockerTools)
        let result = await sshExec("mkdir -p /opt/aevonx/docker-groups && echo '\(containerId)=\(shellQuote(group))' >> /opt/aevonx/docker-groups/mappings.txt", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("set group", result.stderr) }
    }

    // MARK: - Env Templates

    public func saveEnvTemplate(_ template: EnvTemplate, serverId: String) async throws {
        try await requireFeature(.dockerTemplates)
        let dir = "/opt/aevonx/docker-templates"
        let _ = await sshExec("mkdir -p \(shellQuote(dir))", serverId: serverId)
        let encoder = JSONEncoder(); encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(template)
        guard let jsonStr = String(data: data, encoding: .utf8) else { throw DockerError.commandFailed("template", "Encode failed") }
        let escaped = jsonStr.replacingOccurrences(of: "'", with: "'\\''")
        let result = await sshExec("echo '\(escaped)' > \(shellQuote(dir))/\(shellQuote(template.id)).json", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("save template", result.stderr) }
    }

    public func listEnvTemplates(serverId: String) async throws -> [EnvTemplate] {
        try await requireFeature(.dockerTemplates)
        let result = await sshExec("cat /opt/aevonx/docker-templates/*.json 2>/dev/null || echo '[]'", serverId: serverId)
        let output = result.stdout
        let jsonStrings = output.components(separatedBy: "}\n{").enumerated().map { index, part -> String in
            var s = part
            if index > 0 { s = "{" + s }
            if index < output.components(separatedBy: "}\n{").count - 1 { s = s + "}" }
            return s
        }
        var templates: [EnvTemplate] = []
        for jsonStr in jsonStrings {
            if let data = jsonStr.data(using: .utf8), let t = try? JSONDecoder().decode(EnvTemplate.self, from: data) { templates.append(t) }
        }
        return templates
    }

    public func deleteEnvTemplate(id: String, serverId: String) async throws {
        try await requireFeature(.dockerTemplates)
        let result = await sshExec("rm -f /opt/aevonx/docker-templates/\(shellQuote(id)).json", serverId: serverId)
        guard result.exitCode == 0 else { throw DockerError.commandFailed("delete template", result.stderr) }
    }

    // MARK: - Export/Import Profile

    public func exportContainerProfile(serverId: String) async throws -> String {
        try await requireFeature(.dockerExport)
        let dockerPath = try await getDockerPath(serverId: serverId)
        let fmt = "{{.Names}}|||{{.Image}}|||{{range .Ports}}{{.IP}}:{{.PublicPort}}:{{.PrivatePort}}/{{.Type}},{{end}}|||{{range .Config.Env}}{{.}};;;{{end}}|||{{range .Mounts}}{{.Source}}:{{.Destination}},{{end}}|||{{range $k,$v := .NetworkSettings.Networks}}{{$k}},{{end}}|||{{.HostConfig.RestartPolicy.Name}}"
        let result = await sshExec("\(dockerPath) inspect --format '\(fmt)' $(\(dockerPath) ps -aq) 2>/dev/null || echo ''", serverId: serverId)

        var entries: [ContainerProfileEntry] = []
        for line in result.stdout.components(separatedBy: .newlines) where !line.isEmpty {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 7 else { continue }
            entries.append(ContainerProfileEntry(
                name: parts[0].replacingOccurrences(of: "/", with: ""), image: parts[1],
                ports: parts[2].components(separatedBy: ",").filter { !$0.isEmpty },
                envVars: parts[3].components(separatedBy: ";;;").filter { !$0.isEmpty },
                volumes: parts[4].components(separatedBy: ",").filter { !$0.isEmpty },
                networks: parts[5].components(separatedBy: ",").filter { !$0.isEmpty },
                restartPolicy: parts[6]
            ))
        }

        let profile = ContainerProfile(version: "1.0", exportedAt: ISO8601DateFormatter().string(from: Date()), containers: entries)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(profile)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    public func importContainerProfile(json: String, serverId: String,
                                        progress: @escaping @Sendable (String, Double) -> Void) async throws {
        try await requireFeature(.dockerExport)
        let dockerPath = try await getDockerPath(serverId: serverId)
        guard let data = json.data(using: .utf8) else { throw DockerError.commandFailed("import", "Invalid JSON") }
        let profile = try JSONDecoder().decode(ContainerProfile.self, from: data)
        let total = Double(profile.containers.count)

        for (index, entry) in profile.containers.enumerated() {
            progress("Creating \(entry.name)...", Double(index) / total)
            var flags = ["-d", "--name \(shellQuote(entry.name))"]
            if !entry.restartPolicy.isEmpty && entry.restartPolicy != "no" { flags.append("--restart=\(entry.restartPolicy)") }
            for port in entry.ports where !port.isEmpty { flags.append("-p \(port)") }
            for env in entry.envVars where !env.isEmpty { flags.append("-e '\(env.replacingOccurrences(of: "'", with: "'\\''"))'") }
            for vol in entry.volumes where !vol.isEmpty { flags.append("-v \(shellQuote(vol))") }
            let _ = await sshExec("\(dockerPath) run \(flags.joined(separator: " ")) \(shellQuote(entry.image))", serverId: serverId)
        }
        progress("Import completed ✅", 1.0)
    }
}
