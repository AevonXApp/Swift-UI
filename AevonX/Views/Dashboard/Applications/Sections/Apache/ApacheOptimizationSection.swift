//
//  ApacheOptimizationSection.swift
//  AevonX
//
//  Form-based Apache optimization — MPM, KeepAlive, timeouts.
//  Uses shared AppOptimizationGroup/Row/Toggle/SaveButton components.
//

import SwiftUI
import AevonXCoreBridge

struct ApacheOptimizationSection: View {
    let serverId: String

    // KeepAlive
    @State private var keepAlive = "On"
    @State private var maxKeepAliveRequests = "100"
    @State private var keepAliveTimeout = "5"

    // Timeouts
    @State private var timeout = "300"
    @State private var requestTimeout = "0"

    // MPM
    @State private var maxRequestWorkers = "150"
    @State private var serverLimit = "16"
    @State private var startServers = "5"
    @State private var minSpareThreads = "25"
    @State private var maxSpareThreads = "75"
    @State private var threadsPerChild = "25"

    @State private var isLoading = true
    @State private var isSaving = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let apacheRed = Color(red: 0.82, green: 0.13, blue: 0.16)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    // KeepAlive
                    AppOptimizationGroup(title: "KeepAlive", icon: "link", color: apacheRed) {
                        AppOptimizationToggle(label: "KeepAlive", value: $keepAlive, hint: "Enable persistent connections")
                        AppOptimizationRow(label: "MaxKeepAliveRequests", value: $maxKeepAliveRequests, hint: "Requests per connection", placeholder: "100")
                        AppOptimizationRow(label: "KeepAliveTimeout", value: $keepAliveTimeout, hint: "Seconds to wait for next request", placeholder: "5")
                    }

                    // Timeouts
                    AppOptimizationGroup(title: "Timeouts", icon: "timer", color: .orange) {
                        AppOptimizationRow(label: "Timeout", value: $timeout, hint: "General timeout in seconds", placeholder: "300")
                        AppOptimizationRow(label: "RequestReadTimeout", value: $requestTimeout, hint: "Request read timeout (0=infinite)", placeholder: "0")
                    }

                    // MPM
                    AppOptimizationGroup(title: "MPM (Multi-Processing)", icon: "cpu.fill", color: .cyan) {
                        AppOptimizationRow(label: "MaxRequestWorkers", value: $maxRequestWorkers, hint: "Max simultaneous connections", placeholder: "150")
                        AppOptimizationRow(label: "ServerLimit", value: $serverLimit, hint: "Upper bound on MaxRequestWorkers", placeholder: "16")
                        AppOptimizationRow(label: "StartServers", value: $startServers, hint: "Server processes at startup", placeholder: "5")
                        AppOptimizationRow(label: "MinSpareThreads", value: $minSpareThreads, hint: "Min idle threads", placeholder: "25")
                        AppOptimizationRow(label: "MaxSpareThreads", value: $maxSpareThreads, hint: "Max idle threads", placeholder: "75")
                        AppOptimizationRow(label: "ThreadsPerChild", value: $threadsPerChild, hint: "Threads per server process", placeholder: "25")
                    }

                    // Save
                    AppOptimizationSaveButton(title: "Save", color: apacheRed, isSaving: isSaving) {
                        Task { await saveSettings() }
                    }
                    .padding(.top, AXSpacing.md)
                }
                .padding(AXSpacing.xl)
            }
        }
        .task { await loadSettings() }
    }

    // MARK: - Data

    private func loadSettings() async {
        isLoading = true
        let json = await bridge.getOptimization(serverID: serverId, appID: "apache")

        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let s = resp["data"] as? [String: Any] {

            if let v = s["keep_alive"] as? String, !v.isEmpty { keepAlive = v }
            if let v = s["max_keep_alive_requests"] as? String, !v.isEmpty { maxKeepAliveRequests = v }
            if let v = s["keep_alive_timeout"] as? String, !v.isEmpty { keepAliveTimeout = v }
            if let v = s["timeout"] as? String, !v.isEmpty { timeout = v }
            if let v = s["request_timeout"] as? String, !v.isEmpty { requestTimeout = v }
            if let v = s["max_request_workers"] as? String, !v.isEmpty { maxRequestWorkers = v }
            if let v = s["server_limit"] as? String, !v.isEmpty { serverLimit = v }
            if let v = s["start_servers"] as? String, !v.isEmpty { startServers = v }
            if let v = s["min_spare_threads"] as? String, !v.isEmpty { minSpareThreads = v }
            if let v = s["max_spare_threads"] as? String, !v.isEmpty { maxSpareThreads = v }
            if let v = s["threads_per_child"] as? String, !v.isEmpty { threadsPerChild = v }
        }

        isLoading = false
    }

    private func saveSettings() async {
        isSaving = true

        let settings: [String: String] = [
            "keep_alive": keepAlive,
            "max_keep_alive_requests": maxKeepAliveRequests,
            "keep_alive_timeout": keepAliveTimeout,
            "timeout": timeout,
            "request_timeout": requestTimeout,
            "max_request_workers": maxRequestWorkers,
            "server_limit": serverLimit,
            "start_servers": startServers,
            "min_spare_threads": minSpareThreads,
            "max_spare_threads": maxSpareThreads,
            "threads_per_child": threadsPerChild,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: settings),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            toast.showError("Failed to encode settings")
            isSaving = false
            return
        }

        let result = await bridge.saveOptimization(serverID: serverId, appID: "apache", settingsJSON: jsonStr)

        if let data = result.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Apache optimization saved")
        } else {
            var errMsg = "Failed to save optimization settings"
            if let data = result.data(using: .utf8),
               let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = resp["error"] as? String { errMsg = err }
            toast.showError(errMsg)
        }

        isSaving = false
    }
}
