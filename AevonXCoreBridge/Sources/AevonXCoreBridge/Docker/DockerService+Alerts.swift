//
//  DockerService+Alerts.swift
//  AevonXCoreBridge
//

import Foundation
import AevonXCoreLib

extension DockerService {

    public func detectCrashedContainers(serverId: String) async throws -> [ContainerCrashInfo] {
        try await requireFeature(.dockerHealth)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }
        let fmt = "{{.ID}}|||{{.Names}}|||{{.State.RestartCount}}|||{{.State.ExitCode}}|||{{.State.Error}}|||{{.State.Restarting}}|||{{.State.StartedAt}}|||{{.State.FinishedAt}}"
        let result = await sshExec("\(dockerPath) inspect --format '\(fmt)' $(\(dockerPath) ps -aq) 2>/dev/null || echo ''", serverId: serverId)

        var crashes: [ContainerCrashInfo] = []
        for line in result.stdout.components(separatedBy: .newlines) where !line.isEmpty {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 8 else { continue }
            let restartCount = Int(parts[2]) ?? 0
            let exitCode = Int(parts[3]) ?? 0
            let isRestarting = parts[5] == "true"
            if restartCount > 3 || (exitCode != 0 && exitCode != 137) || isRestarting {
                crashes.append(ContainerCrashInfo(
                    containerId: parts[0], containerName: parts[1].replacingOccurrences(of: "/", with: ""),
                    restartCount: restartCount, lastExitCode: exitCode, lastError: parts[4],
                    isRestarting: isRestarting, lastStartedAt: parts[6], lastFinishedAt: parts[7]
                ))
            }
        }
        return crashes
    }

    public func checkResourceAlerts(serverId: String, cpuThreshold: Double = 90.0, memThreshold: Double = 85.0) async throws -> [ResourceAlert] {
        try await requireFeature(.dockerHealth)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }
        let fmt = "{{.ID}}|||{{.Name}}|||{{.CPUPerc}}|||{{.MemPerc}}"
        let result = await sshExec("\(dockerPath) stats --no-stream --format '\(fmt)' 2>/dev/null || echo ''", serverId: serverId)

        var alerts: [ResourceAlert] = []
        for line in result.stdout.components(separatedBy: .newlines) where !line.isEmpty {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 4 else { continue }
            let cpu = Double(parts[2].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            let mem = Double(parts[3].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            let name = parts[1].replacingOccurrences(of: "/", with: "")

            if cpu > cpuThreshold {
                alerts.append(ResourceAlert(containerId: parts[0], containerName: name, alertType: .highCPU, currentValue: cpu, threshold: cpuThreshold))
            }
            if mem > memThreshold {
                alerts.append(ResourceAlert(containerId: parts[0], containerName: name, alertType: .highMemory, currentValue: mem, threshold: memThreshold))
            }
        }
        return alerts
    }

    public func getContainerUptimes(serverId: String) async throws -> [ContainerUptime] {
        try await requireFeature(.dockerHealth)
        guard let dockerPath = try? await getDockerPath(serverId: serverId) else { return [] }
        let fmt = "{{.ID}}|||{{.Names}}|||{{.State.StartedAt}}|||{{.State.Status}}"
        let result = await sshExec("\(dockerPath) inspect --format '\(fmt)' $(\(dockerPath) ps -q) 2>/dev/null || echo ''", serverId: serverId)

        var uptimes: [ContainerUptime] = []
        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for line in result.stdout.components(separatedBy: .newlines) where !line.isEmpty {
            let parts = line.components(separatedBy: "|||")
            guard parts.count >= 4 else { continue }
            var uptimeSeconds = 0
            let startStr = parts[2].trimmingCharacters(in: .whitespaces)
            if let startDate = isoFormatter.date(from: startStr) {
                uptimeSeconds = Int(now.timeIntervalSince(startDate))
            }
            uptimes.append(ContainerUptime(
                containerId: parts[0], containerName: parts[1].replacingOccurrences(of: "/", with: ""),
                startedAt: startStr, uptimeSeconds: max(0, uptimeSeconds), status: parts[3]
            ))
        }
        return uptimes.sorted { $0.uptimeSeconds > $1.uptimeSeconds }
    }
}
