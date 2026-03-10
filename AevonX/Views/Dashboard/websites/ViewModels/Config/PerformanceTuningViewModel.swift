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

    init(serverId: String, domain: String) {
        self.serverId = serverId
        self.domain = domain
    }

    func loadSettings() async {
        isLoading = true; defer { isLoading = false }
        do {
            let configPath = "/etc/nginx/sites-available/\(domain)"
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

            // Worker info
            let cpuResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: "nproc")
            let workerResult = await SSHBridge.shared.executeAsync(serverID: serverId, command: "grep -E 'worker_processes|worker_connections' /etc/nginx/nginx.conf 2>/dev/null")
            let cpuCores = Int(cpuResult.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1
            var procs = "auto"
            var conns = 1024
            for line in workerResult.components(separatedBy: "\n") {
                if line.contains("worker_processes") {
                    procs = line.components(separatedBy: .whitespaces).last?.replacingOccurrences(of: ";", with: "") ?? "auto"
                }
                if line.contains("worker_connections") {
                    conns = Int(line.components(separatedBy: .whitespaces).last?.replacingOccurrences(of: ";", with: "") ?? "1024") ?? 1024
                }
            }
            workerInfo = WorkerInfoItem(cpuCores: cpuCores, workerProcesses: procs, workerConnections: conns)
        } catch { directives = [] }
    }

    func applyDirective(_ name: String, value: String) async {
        isLoading = true; defer { isLoading = false }
        do {
            let configPath = "/etc/nginx/sites-available/\(domain)"
            let cmd = bridge.applyPerfSettingCmd(configPath: configPath, directive: name, value: value)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            if let idx = directives.firstIndex(where: { $0.name == name }) {
                directives[idx] = DirectiveItem(name: name, value: value, isSet: true)
            }
            GlobalToastManager.shared.showSuccess("\(name) updated")
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func applyPreset() async {
        isLoading = true; defer { isLoading = false }
        do {
            let configPath = "/etc/nginx/sites-available/\(domain)"
            let cmds = bridge.applyPresetCmds(configPath: configPath, preset: selectedPreset)
            for cmd in cmds {
                _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            }
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            GlobalToastManager.shared.showSuccess("\(selectedPreset.capitalized) preset applied")
            await loadSettings()
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
    }

    func toggleGzip(_ enable: Bool) async {
        do {
            let configPath = "/etc/nginx/nginx.conf"
            let value = enable ? "on" : "off"
            let cmd = bridge.applyPerfSettingCmd(configPath: configPath, directive: "gzip", value: value)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            GlobalToastManager.shared.showSuccess(enable ? "Gzip enabled" : "Gzip disabled")
            await loadSettings()
        } catch { GlobalToastManager.shared.showError(error.localizedDescription) }
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
