//
//  PerformanceTuningViewModel.swift
//  AevonX
//
//  ViewModel for performance tuning — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class PerformanceTuningViewModel: ObservableObject {
    @Published var directives: [DirectiveItem] = []
    @Published var workerInfo: WorkerInfoItem?
    @Published var isLoading = false
    @Published var selectedPreset = "balanced"

    let serverId: String
    let domain: String
    private let bridge = WebsitesBridge.shared
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadSettings() async {
        isLoading = true; defer { isLoading = false }
        await detectPathsIfNeeded()
        let configPath = resolveConfigPath()
        let cmd = bridge.readPerfCmd(configPath: configPath)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parsePerfSettings(content: result)

        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let settingsList = resp["data"] as? [[String: Any]] {
            directives = settingsList.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let value = dict["value"] as? String else { return nil }
                return DirectiveItem(name: name, value: value, isSet: dict["is_set"] as? Bool ?? false)
            }
        }

        // Worker info via bridge (returns cpu:N, worker_processes, worker_connections)
        let workerOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.readWorkerInfoCmd(nginxMainConf: serverPaths.nginxMainConf))
        let workerLines = workerOutput.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var cpuCores = 1
        var procs = "auto"
        var conns = 1024
        for line in workerLines {
            if line.hasPrefix("cpu:") {
                cpuCores = Int(line.replacingOccurrences(of: "cpu:", with: "")) ?? 1
            } else if !line.isEmpty && procs == "auto" && workerLines.firstIndex(of: line) == 1 {
                procs = line
            } else if !line.isEmpty && workerLines.firstIndex(of: line) == 2 {
                conns = Int(line) ?? 1024
            }
        }
        workerInfo = WorkerInfoItem(cpuCores: cpuCores, workerProcesses: procs, workerConnections: conns)
    }

    func applyDirective(_ name: String, value: String) async {
        isLoading = true; defer { isLoading = false }
        let configPath = resolveConfigPath()
        let cmd = bridge.applyPerfSettingCmd(configPath: configPath, directive: name, value: value)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
        if let idx = directives.firstIndex(where: { $0.name == name }) {
            directives[idx] = DirectiveItem(name: name, value: value, isSet: true)
        }
        GlobalToastManager.shared.showSuccess("\(name) updated")
    }

    func applyPreset() async {
        isLoading = true; defer { isLoading = false }
        let configPath = resolveConfigPath()
        let cmds = bridge.applyPresetCmds(configPath: configPath, preset: selectedPreset)
        for cmd in cmds {
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
        GlobalToastManager.shared.showSuccess("\(selectedPreset.capitalized) preset applied")
        await loadSettings()
    }

    func toggleGzip(_ enable: Bool) async {
        let configPath = serverPaths.nginxMainConf
        let value = enable ? "on" : "off"
        let cmd = bridge.applyPerfSettingCmd(configPath: configPath, directive: "gzip", value: value)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
        GlobalToastManager.shared.showSuccess(enable ? "Gzip enabled" : "Gzip disabled")
        await loadSettings()
    }

    private func detectPathsIfNeeded() async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }

    /// Returns the resolved config path for this domain, adding .conf for BT Panel.
    private func resolveConfigPath() -> String {
        let sa = serverPaths.nginxSitesAvailable
        if serverPaths.serverType == "bt_panel" || sa.contains("/www/server") || sa.contains("/conf.d") || sa.contains("/vhost") {
            return "\(sa)/\(domain).conf"
        }
        return "\(sa)/\(domain)"
    }
}

// MARK: - UI Models

struct DirectiveItem: Identifiable {
    let id: String
    let name: String
    var value: String
    let isSet: Bool

    init(name: String, value: String, isSet: Bool) {
        self.id = name
        self.name = name
        self.value = value
        self.isSet = isSet
    }

    var category: String {
        if name.contains("gzip") || name.contains("http2") { return "Compression" }
        if name.contains("timeout") || name.contains("keepalive") { return "Timeouts" }
        if name.contains("buffer") || name.contains("body_size") { return "Buffers" }
        return "Other"
    }
}

struct WorkerInfoItem {
    let cpuCores: Int
    let workerProcesses: String
    let workerConnections: Int
}
