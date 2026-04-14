//
//  RedisOptimizationSection.swift
//  AevonX
//
//  Form-based redis.conf tuning — maxmemory, eviction, persistence, networking.
//

import SwiftUI
import AevonXCoreBridge

struct RedisOptimizationSection: View {
    let serverId: String

    @State private var maxmemory = "0"
    @State private var maxmemoryPolicy = "noeviction"
    @State private var maxmemorySamples = "5"
    @State private var timeout = "0"
    @State private var tcpKeepalive = "300"
    @State private var tcpBacklog = "511"
    @State private var databases = "16"
    @State private var save = "3600 1 300 100 60 10000"
    @State private var appendonly = "no"
    @State private var appendfsync = "everysec"
    @State private var maxclients = "10000"
    @State private var hzValue = "10"

    @State private var isLoading = true
    @State private var isSaving = false
    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let redisRed = Color(red: 0.86, green: 0.23, blue: 0.23)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    AppOptimizationGroup(title: "Memory", icon: "memorychip.fill", color: .purple) {
                        AppOptimizationRow(label: "maxmemory", value: $maxmemory, hint: "0 = unlimited. Use 256mb, 1gb etc.", placeholder: "0")
                        AppOptimizationRow(label: "maxmemory-policy", value: $maxmemoryPolicy,
                                           hint: "noeviction, allkeys-lru, volatile-lru, etc.", placeholder: "noeviction")
                        AppOptimizationRow(label: "maxmemory-samples", value: $maxmemorySamples, hint: "LRU/TTL approximation samples", placeholder: "5")
                    }

                    AppOptimizationGroup(title: "Connections", icon: "link.circle.fill", color: .axAccentBlue) {
                        AppOptimizationRow(label: "maxclients", value: $maxclients, hint: "Maximum simultaneous clients", placeholder: "10000")
                        AppOptimizationRow(label: "timeout", value: $timeout, hint: "Idle timeout seconds (0 = disabled)", placeholder: "0")
                        AppOptimizationRow(label: "tcp-keepalive", value: $tcpKeepalive, hint: "TCP keepalive interval", placeholder: "300")
                        AppOptimizationRow(label: "tcp-backlog", value: $tcpBacklog, hint: "TCP listen backlog", placeholder: "511")
                    }

                    AppOptimizationGroup(title: "Persistence", icon: "internaldrive.fill", color: .orange) {
                        AppOptimizationRow(label: "save", value: $save, hint: "RDB save intervals (sec changes)", placeholder: "3600 1 300 100")
                        AppOptimizationRow(label: "appendonly", value: $appendonly, hint: "AOF persistence (yes/no)", placeholder: "no")
                        AppOptimizationRow(label: "appendfsync", value: $appendfsync, hint: "always, everysec, or no", placeholder: "everysec")
                    }

                    AppOptimizationGroup(title: "General", icon: "gearshape.fill", color: .mint) {
                        AppOptimizationRow(label: "databases", value: $databases, hint: "Number of logical databases", placeholder: "16")
                        AppOptimizationRow(label: "hz", value: $hzValue, hint: "Server tick frequency (10-500)", placeholder: "10")
                    }

                    AppOptimizationSaveButton(title: L10n.Button.save, color: redisRed, isSaving: isSaving) { Task { await saveSettings() } }
                        .padding(.top, AXSpacing.md)
                }.padding(AXSpacing.xl)
            }
        }.task { await loadSettings() }
    }

    private func loadSettings() async {
        isLoading = true
        let json = await bridge.getOptimization(serverID: serverId, appID: "redis")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let s = resp["data"] as? [String: Any] {
            if let v = s["maxmemory"] as? String, !v.isEmpty { maxmemory = v }
            if let v = s["maxmemory_policy"] as? String, !v.isEmpty { maxmemoryPolicy = v }
            if let v = s["maxmemory_samples"] as? String, !v.isEmpty { maxmemorySamples = v }
            if let v = s["timeout"] as? String, !v.isEmpty { timeout = v }
            if let v = s["tcp_keepalive"] as? String, !v.isEmpty { tcpKeepalive = v }
            if let v = s["tcp_backlog"] as? String, !v.isEmpty { tcpBacklog = v }
            if let v = s["databases"] as? String, !v.isEmpty { databases = v }
            if let v = s["save"] as? String, !v.isEmpty { save = v }
            if let v = s["appendonly"] as? String, !v.isEmpty { appendonly = v }
            if let v = s["appendfsync"] as? String, !v.isEmpty { appendfsync = v }
            if let v = s["maxclients"] as? String, !v.isEmpty { maxclients = v }
            if let v = s["hz"] as? String, !v.isEmpty { hzValue = v }
        }
        isLoading = false
    }

    private func saveSettings() async {
        isSaving = true
        let settings: [String: String] = [
            "maxmemory": maxmemory, "maxmemory_policy": maxmemoryPolicy, "maxmemory_samples": maxmemorySamples,
            "timeout": timeout, "tcp_keepalive": tcpKeepalive, "tcp_backlog": tcpBacklog,
            "databases": databases, "save": save, "appendonly": appendonly, "appendfsync": appendfsync,
            "maxclients": maxclients, "hz": hzValue,
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: settings),
              let jsonStr = String(data: jsonData, encoding: .utf8) else { toast.showError("Failed to encode settings"); isSaving = false; return }
        let raw = await bridge.saveOptimization(serverID: serverId, appID: "redis", settingsJSON: jsonStr)
        let outcome = parseOptSaveResponse(raw)
        showOptSaveToast(outcome, appTitle: "Redis", rawEnvelope: raw)

        isSaving = false
        if case .failed = outcome { return }
        await loadSettings()
    }
}
