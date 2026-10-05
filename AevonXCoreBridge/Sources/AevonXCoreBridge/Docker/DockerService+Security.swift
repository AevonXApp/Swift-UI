//
//  DockerService+Security.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    public func scanImageVulnerabilities(image: String, serverId: String) async throws -> VulnerabilityScan {
        try await requireFeature(.dockerSecurity)
        let dockerPath = try await getDockerPath(serverId: serverId)

        // Try docker scout first
        let scoutCheck = await sshExec("command -v docker 2>/dev/null && \(dockerPath) scout version 2>/dev/null", serverId: serverId)

        if scoutCheck.exitCode == 0 && !scoutCheck.stdout.contains("not") {
            let cmd = "\(dockerPath) scout cves \(shellQuote(image)) --format json 2>/dev/null || \(dockerPath) scout cves \(shellQuote(image)) 2>&1"
            let result = await sshExec(cmd, serverId: serverId)
            let output = result.stdout + result.stderr
            return VulnerabilityScan(
                imageName: image, scanner: "Docker Scout", totalVulnerabilities: 0,
                critical: extractCount(from: output, pattern: #"(\d+)C"#),
                high: extractCount(from: output, pattern: #"(\d+)H"#),
                medium: extractCount(from: output, pattern: #"(\d+)M"#),
                low: extractCount(from: output, pattern: #"(\d+)L"#),
                rawOutput: output
            )
        }

        // Try trivy
        let trivyCheck = await sshExec("command -v trivy 2>/dev/null", serverId: serverId)
        if trivyCheck.exitCode == 0 {
            let cmd = "trivy image --severity CRITICAL,HIGH,MEDIUM,LOW --format table \(shellQuote(image)) 2>&1"
            let result = await sshExec(cmd, serverId: serverId)
            let output = result.stdout + result.stderr
            return VulnerabilityScan(
                imageName: image, scanner: "Trivy",
                totalVulnerabilities: 0,
                critical: countOccurrences(in: output, of: "CRITICAL"),
                high: countOccurrences(in: output, of: "HIGH"),
                medium: countOccurrences(in: output, of: "MEDIUM"),
                low: countOccurrences(in: output, of: "LOW"),
                rawOutput: output
            )
        }

        // Basic fallback
        let inspectCmd = "\(dockerPath) inspect --format '{{.Config.User}}' \(shellQuote(image)) 2>/dev/null || echo ''"
        let result = await sshExec(inspectCmd, serverId: serverId)
        let user = result.stdout
        let issues = (user.isEmpty || user == "root" || user == "0") ? 1 : 0

        return VulnerabilityScan(
            imageName: image, scanner: "Basic Check", totalVulnerabilities: issues,
            critical: 0, high: issues > 0 ? 1 : 0, medium: 0, low: 0,
            rawOutput: issues > 0 ? "⚠️ Container runs as root user" : "No obvious security issues found."
        )
    }

    public func auditContainerSecurity(containerId: String, serverId: String) async throws -> SecurityAudit {
        try await requireFeature(.dockerSecurity)
        let dockerPath = try await getDockerPath(serverId: serverId)
        var findings: [SecurityFinding] = []
        var score = 100

        // 1. Root check
        let userResult = await sshExec("\(dockerPath) inspect --format '{{.Config.User}}' \(containerId)", serverId: serverId)
        let user = userResult.stdout
        if user.isEmpty || user == "root" || user == "0" {
            findings.append(SecurityFinding(severity: "warning", title: "Running as Root", description: "Container runs as root user."))
            score -= 15
        }

        // 2. Privileged mode
        let privResult = await sshExec("\(dockerPath) inspect --format '{{.HostConfig.Privileged}}' \(containerId)", serverId: serverId)
        if privResult.stdout == "true" {
            findings.append(SecurityFinding(severity: "critical", title: "Privileged Mode", description: "Container runs in privileged mode!"))
            score -= 30
        }

        // 3. Exposed ports
        let portsResult = await sshExec("\(dockerPath) port \(containerId) 2>/dev/null || echo ''", serverId: serverId)
        let exposed = portsResult.stdout.components(separatedBy: .newlines).filter { $0.contains("0.0.0.0") }
        if !exposed.isEmpty {
            findings.append(SecurityFinding(severity: "warning", title: "Exposed on All Interfaces", description: "\(exposed.count) port(s) bound to 0.0.0.0."))
            score -= 10
        }

        // 4. Resource limits
        let limitsResult = await sshExec("\(dockerPath) inspect --format '{{.HostConfig.Memory}}|||{{.HostConfig.NanoCpus}}' \(containerId)", serverId: serverId)
        let limitsParts = limitsResult.stdout.components(separatedBy: "|||")
        let mem = Int64(limitsParts[0]) ?? 0
        let cpu = Int64(limitsParts.count > 1 ? limitsParts[1] : "0") ?? 0
        if mem == 0 && cpu == 0 {
            findings.append(SecurityFinding(severity: "info", title: "No Resource Limits", description: "No CPU/memory limits set."))
            score -= 10
        }

        // 5. Restart policy
        let restartResult = await sshExec("\(dockerPath) inspect --format '{{.HostConfig.RestartPolicy.Name}}' \(containerId)", serverId: serverId)
        if restartResult.stdout == "no" || restartResult.stdout.isEmpty {
            findings.append(SecurityFinding(severity: "info", title: "No Restart Policy", description: "Container won't auto-restart."))
            score -= 5
        }

        // 6. Dangerous mounts
        let mountsResult = await sshExec("\(dockerPath) inspect --format '{{range .Mounts}}{{.Source}},{{end}}' \(containerId)", serverId: serverId)
        let mounts = mountsResult.stdout.components(separatedBy: ",").filter { !$0.isEmpty }
        let dangerous = mounts.filter { $0 == "/var/run/docker.sock" || $0 == "/" || $0 == "/etc" }
        if !dangerous.isEmpty {
            findings.append(SecurityFinding(severity: "critical", title: "Dangerous Volume Mounts", description: "Sensitive paths: \(dangerous.joined(separator: ", "))"))
            score -= 20
        }

        let nameResult = await sshExec("\(dockerPath) inspect --format '{{.Name}}' \(containerId)", serverId: serverId)
        let containerName = nameResult.stdout.replacingOccurrences(of: "/", with: "")

        return SecurityAudit(containerId: containerId, containerName: containerName, securityScore: max(0, score), findings: findings)
    }

    // MARK: - Helpers

    private func extractCount(from text: String, pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return 0 }
        return Int(text[range]) ?? 0
    }

    private func countOccurrences(in text: String, of word: String) -> Int {
        var count = 0; var index = text.startIndex
        while let range = text.range(of: word, range: index..<text.endIndex) {
            count += 1; index = range.upperBound
        }
        return count
    }
}
