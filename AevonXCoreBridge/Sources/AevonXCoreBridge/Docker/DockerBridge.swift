//
//  DockerBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core Docker operations.
//  Delegates to GenericBridge internally — same public API.
//

import Foundation
import AevonXCoreLib

// MARK: - Docker Bridge

/// Bridge to Go Core Docker command generation and parsing.
/// Generates SSH commands via Go and parses Docker output.
public final class DockerBridge: @unchecked Sendable {

    /// Shared instance.
    public static let shared = DockerBridge()
    private let gb = GenericBridge.shared
    private init() {}

    // MARK: - Path & Service

    /// Cache the docker binary path for a server.
    public func setDockerPath(serverID: String, path: String) {
        _ = gb.callSync("docker.setPath", ["server_id": serverID, "path": path])
    }

    /// Get the cached docker path.
    public func getDockerPath(serverID: String) -> String? {
        let r = gb.callSync("docker.getPath", ["server_id": serverID])
        return Self.extractData(r, key: "path")
    }

    /// Clear cached docker path.
    public func clearDockerPath(serverID: String) {
        _ = gb.callSync("docker.clearPath", ["server_id": serverID])
    }

    /// Get the command to discover docker binary.
    public func discoverPathCmd() -> String {
        GenericBridge.command(from: gb.callSync("docker.discoverPathCmd"))
    }

    /// Get install commands.
    public func installCmds() -> [String] {
        Self.extractCommands(gb.callSync("docker.installCmds"))
    }

    /// Get service status command.
    public func serviceStatusCmd() -> String {
        GenericBridge.command(from: gb.callSync("docker.getServiceStatusCmd"))
    }

    /// Parse service status output.
    public func parseServiceStatus(output: String) -> String {
        Self.extractData(gb.callSync("docker.parseServiceStatus", ["output": output]), key: "status") ?? "unknown"
    }

    /// Get start command.
    public func startCmd() -> String {
        GenericBridge.command(from: gb.callSync("docker.startCmd"))
    }

    /// Get stop command.
    public func stopCmd() -> String {
        GenericBridge.command(from: gb.callSync("docker.stopCmd"))
    }

    // MARK: - Info

    /// Get docker info command.
    public func infoCmd(dockerPath: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.getInfoCmd", ["docker_path": dockerPath]))
    }

    /// Parse docker info output.
    public func parseInfo(output: String) -> BridgeResponse {
        Self.toBridgeResponse(gb.callSync("docker.parseInfo", ["output": output]))
    }

    // MARK: - Containers

    /// Get containers list command.
    public func containersCmd(dockerPath: String, all: Bool = true) -> String {
        GenericBridge.command(from: gb.callSync("docker.getContainersCmd", ["docker_path": dockerPath, "all": all]))
    }

    /// Parse containers output.
    public func parseContainers(output: String) -> BridgeResponse {
        Self.toBridgeResponse(gb.callSync("docker.parseContainers", ["output": output]))
    }

    /// Get container stats command.
    public func containerStatsCmd(dockerPath: String, id: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.containerStatsCmd", ["docker_path": dockerPath, "id": id]))
    }

    /// Get container logs command.
    public func containerLogsCmd(dockerPath: String, id: String, tail: Int = 100) -> String {
        GenericBridge.command(from: gb.callSync("docker.containerLogsCmd", ["docker_path": dockerPath, "id": id, "tail": tail]))
    }

    /// Get container inspect command.
    public func inspectContainerCmd(dockerPath: String, id: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.inspectContainerCmd", ["docker_path": dockerPath, "id": id]))
    }

    /// Get container health command.
    public func containerHealthCmd(dockerPath: String, id: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.containerHealthCmd", ["docker_path": dockerPath, "id": id]))
    }

    /// Get rename command.
    public func renameContainerCmd(dockerPath: String, id: String, newName: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.renameContainerCmd", ["docker_path": dockerPath, "id": id, "new_name": newName]))
    }

    /// Get export command.
    public func exportContainerCmd(dockerPath: String, id: String, path: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.exportContainerCmd", ["docker_path": dockerPath, "id": id, "path": path]))
    }

    // MARK: - Images

    /// Get images list command.
    public func imagesCmd(dockerPath: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.getImagesCmd", ["docker_path": dockerPath]))
    }

    /// Parse images output.
    public func parseImages(output: String) -> BridgeResponse {
        Self.toBridgeResponse(gb.callSync("docker.parseImages", ["output": output]))
    }

    /// Get pull command.
    public func pullImageCmd(dockerPath: String, image: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.pullImageCmd", ["docker_path": dockerPath, "image": image]))
    }

    /// Get remove image command.
    public func removeImageCmd(dockerPath: String, id: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.removeImageCmd", ["docker_path": dockerPath, "id": id]))
    }

    /// Get Docker Hub search command.
    public func hubSearchCmd(dockerPath: String, term: String, limit: Int = 25) -> String {
        GenericBridge.command(from: gb.callSync("docker.hubSearchCmd", ["docker_path": dockerPath, "term": term, "limit": limit]))
    }

    // MARK: - Compose

    /// Get compose up command.
    public func composeUpCmd(dockerPath: String, projectDir: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.composeUpCmd", ["docker_path": dockerPath, "project_dir": projectDir]))
    }

    /// Get compose down command.
    public func composeDownCmd(dockerPath: String, projectDir: String, removeVolumes: Bool = false) -> String {
        GenericBridge.command(from: gb.callSync("docker.composeDownCmd", ["docker_path": dockerPath, "project_dir": projectDir, "remove_volumes": removeVolumes]))
    }

    /// Get compose list command.
    public func composeListCmd(dockerPath: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.composeListCmd", ["docker_path": dockerPath]))
    }

    // MARK: - Volumes & Networks

    /// Get volumes list command.
    public func volumesCmd(dockerPath: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.getVolumesCmd", ["docker_path": dockerPath]))
    }

    /// Get networks list command.
    public func networksCmd(dockerPath: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.getNetworksCmd", ["docker_path": dockerPath]))
    }

    // MARK: - Security

    /// Get Scout scan command.
    public func scanWithScoutCmd(dockerPath: String, image: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.scanWithScoutCmd", ["docker_path": dockerPath, "image": image]))
    }

    /// Get Trivy scan command.
    public func scanWithTrivyCmd(image: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.scanWithTrivyCmd", ["image": image]))
    }

    /// Get security audit command.
    public func auditContainerCmd(dockerPath: String, id: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.auditContainerCmd", ["docker_path": dockerPath, "id": id]))
    }

    // MARK: - System

    /// Get system prune command.
    public func pruneCmd(dockerPath: String, all: Bool = false, volumes: Bool = false) -> String {
        GenericBridge.command(from: gb.callSync("docker.pruneCmd", ["docker_path": dockerPath, "all": all, "volumes": volumes]))
    }

    /// Get disk usage command.
    public func diskUsageCmd(dockerPath: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.diskUsageCmd", ["docker_path": dockerPath]))
    }

    /// Get events command.
    public func eventsCmd(dockerPath: String, since: Int, until: Int = 0) -> String {
        GenericBridge.command(from: gb.callSync("docker.eventsCmd", ["docker_path": dockerPath, "since": since, "until": until]))
    }

    // MARK: - Backup & Rollback

    /// Get backup commands.
    public func backupContainerCmds(dockerPath: String, id: String, name: String, backupDir: String, timestamp: String) -> [String] {
        Self.extractCommands(gb.callSync("docker.backupContainerCmds", ["docker_path": dockerPath, "id": id, "name": name, "backup_dir": backupDir, "timestamp": timestamp]))
    }

    /// Get list backups command.
    public func listBackupsCmd(backupDir: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.listBackupsCmd", ["backup_dir": backupDir]))
    }

    /// Get create snapshot command.
    public func createSnapshotCmd(dockerPath: String, id: String, name: String, timestamp: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.createSnapshotCmd", ["docker_path": dockerPath, "id": id, "name": name, "timestamp": timestamp]))
    }

    /// Get list snapshots command.
    public func listSnapshotsCmd(dockerPath: String) -> String {
        GenericBridge.command(from: gb.callSync("docker.listSnapshotsCmd", ["docker_path": dockerPath]))
    }

    // MARK: - Helpers

    private static func extractData(_ json: String, key: String) -> String? {
        guard let d = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let inner = obj["data"] as? [String: Any],
              let val = inner[key] as? String else { return nil }
        return val
    }

    private static func extractCommands(_ json: String) -> [String] {
        guard let d = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let inner = obj["data"] as? [String: Any],
              let arr = inner["commands"] as? [String] else { return [] }
        return arr
    }

    private static func toBridgeResponse(_ json: String) -> BridgeResponse {
        guard let d = json.data(using: .utf8),
              let r = try? JSONDecoder().decode(BridgeResponse.self, from: d) else {
            let errJSON = """
            {"success":false,"error":"decode failed"}
            """
            return try! JSONDecoder().decode(BridgeResponse.self, from: errJSON.data(using: .utf8)!)
        }
        return r
    }
}
