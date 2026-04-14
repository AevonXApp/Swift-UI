//
//  NginxOptimizationSection.swift
//  AevonX
//
//  Form-based nginx.conf tuning — no file editing needed.
//  Visual controls for worker_processes, gzip, buffers, timeouts, etc.
//

import SwiftUI
import AevonXCoreBridge

struct NginxOptimizationSection: View {
    let serverId: String

    // Settings state
    @State private var workerProcesses = "auto"
    @State private var workerConnections = "512"
    @State private var keepaliveTimeout = "65"
    @State private var gzip = "on"
    @State private var gzipMinLength = "1"
    @State private var gzipCompLevel = "2"
    @State private var clientMaxBodySize = "1"
    @State private var clientHeaderBufferSize = "32"
    @State private var clientBodyBufferSize = "512"
    @State private var serverNamesHashBucketSize = "512"
    @State private var typesHashMaxSize = "2048"
    @State private var sendfile = "on"
    @State private var tcpNopush = "on"
    @State private var tcpNodelay = "on"
    @State private var proxyBufferSize = "4k"
    @State private var proxyBuffers = "8 4k"

    @State private var isLoading = true
    @State private var isSaving = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    // Core
                    AppOptimizationGroup(title: "Core", icon: "cpu.fill", color: .cyan) {
                        AppOptimizationRow(
                            label: "worker_processes",
                            value: $workerProcesses,
                            hint: "Worker processes. Auto = CPU cores",
                            placeholder: "auto"
                        )
                        AppOptimizationRow(
                            label: "worker_connections",
                            value: $workerConnections,
                            hint: "Max connections per worker",
                            placeholder: "512"
                        )
                    }

                    // Timeouts
                    AppOptimizationGroup(title: "Connection", icon: "timer", color: .orange) {
                        AppOptimizationRow(
                            label: "keepalive_timeout",
                            value: $keepaliveTimeout,
                            hint: "Connection timeout in seconds",
                            placeholder: "65"
                        )
                    }

                    // Gzip
                    AppOptimizationGroup(title: "Compression", icon: "arrow.down.right.and.arrow.up.left", color: .purple) {
                        AppOptimizationToggle(
                            label: "gzip",
                            value: $gzip,
                            hint: "Enable compressed transmission"
                        )
                        AppOptimizationRow(
                            label: "gzip_min_length",
                            value: $gzipMinLength,
                            hint: "KB. Minimum file to compress",
                            placeholder: "1"
                        )
                        AppOptimizationRow(
                            label: "gzip_comp_level",
                            value: $gzipCompLevel,
                            hint: "Compression level (1-9)",
                            placeholder: "2"
                        )
                    }

                    // Client
                    AppOptimizationGroup(title: "Client", icon: "person.fill", color: .axAccentBlue) {
                        AppOptimizationRow(
                            label: "client_max_body_size",
                            value: $clientMaxBodySize,
                            hint: "MB. Maximum file to upload",
                            placeholder: "1"
                        )
                        AppOptimizationRow(
                            label: "client_header_buffer_size",
                            value: $clientHeaderBufferSize,
                            hint: "KB. Client header buffer size",
                            placeholder: "32"
                        )
                        AppOptimizationRow(
                            label: "client_body_buffer_size",
                            value: $clientBodyBufferSize,
                            hint: "KB. Client body buffer",
                            placeholder: "512"
                        )
                    }

                    // Hash
                    AppOptimizationGroup(title: "Hash Tables", icon: "number", color: .mint) {
                        AppOptimizationRow(
                            label: "server_names_hash_bucket_size",
                            value: $serverNamesHashBucketSize,
                            hint: "Hash table size of server name",
                            placeholder: "512"
                        )
                        AppOptimizationRow(
                            label: "types_hash_max_size",
                            value: $typesHashMaxSize,
                            hint: "MIME types hash table",
                            placeholder: "2048"
                        )
                    }

                    // Network
                    AppOptimizationGroup(title: "Network", icon: "network", color: Color(red: 0, green: 0.59, blue: 0.22)) {
                        AppOptimizationToggle(
                            label: "sendfile",
                            value: $sendfile,
                            hint: "Kernel-level file transfer"
                        )
                        AppOptimizationToggle(
                            label: "tcp_nopush",
                            value: $tcpNopush,
                            hint: "Optimize packet sending"
                        )
                        AppOptimizationToggle(
                            label: "tcp_nodelay",
                            value: $tcpNodelay,
                            hint: "Disable Nagle's algorithm"
                        )
                    }

                    // Proxy
                    AppOptimizationGroup(title: "Proxy Buffers", icon: "arrow.left.arrow.right", color: .indigo) {
                        AppOptimizationRow(
                            label: "proxy_buffer_size",
                            value: $proxyBufferSize,
                            hint: "Proxy response buffer",
                            placeholder: "4k"
                        )
                        AppOptimizationRow(
                            label: "proxy_buffers",
                            value: $proxyBuffers,
                            hint: "Number × size of buffers",
                            placeholder: "8 4k"
                        )
                    }

                    // Save button
                    AppOptimizationSaveButton(
                        title: L10n.Button.save,
                        color: Color(red: 0, green: 0.59, blue: 0.22),
                        isSaving: isSaving
                    ) {
                        Task { await saveSettings() }
                    }
                    .padding(.top, AXSpacing.md)
                }
                .padding(AXSpacing.xl)
            }
        }
        .task {
            await loadSettings()
        }
    }

    // MARK: - Data

    private func loadSettings() async {
        isLoading = true
        let json = await bridge.getOptimization(serverID: serverId, appID: "nginx")

        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let settingsData = resp["data"] as? [String: Any] {

            if let v = settingsData["worker_processes"] as? String, !v.isEmpty { workerProcesses = v }
            if let v = settingsData["worker_connections"] as? String, !v.isEmpty { workerConnections = v }
            if let v = settingsData["keepalive_timeout"] as? String, !v.isEmpty { keepaliveTimeout = v }
            if let v = settingsData["gzip"] as? String, !v.isEmpty { gzip = v }
            if let v = settingsData["gzip_min_length"] as? String, !v.isEmpty { gzipMinLength = v }
            if let v = settingsData["gzip_comp_level"] as? String, !v.isEmpty { gzipCompLevel = v }
            if let v = settingsData["client_max_body_size"] as? String, !v.isEmpty { clientMaxBodySize = v }
            if let v = settingsData["client_header_buffer_size"] as? String, !v.isEmpty { clientHeaderBufferSize = v }
            if let v = settingsData["client_body_buffer_size"] as? String, !v.isEmpty { clientBodyBufferSize = v }
            if let v = settingsData["server_names_hash_bucket_size"] as? String, !v.isEmpty { serverNamesHashBucketSize = v }
            if let v = settingsData["types_hash_max_size"] as? String, !v.isEmpty { typesHashMaxSize = v }
            if let v = settingsData["sendfile"] as? String, !v.isEmpty { sendfile = v }
            if let v = settingsData["tcp_nopush"] as? String, !v.isEmpty { tcpNopush = v }
            if let v = settingsData["tcp_nodelay"] as? String, !v.isEmpty { tcpNodelay = v }
            if let v = settingsData["proxy_buffer_size"] as? String, !v.isEmpty { proxyBufferSize = v }
            if let v = settingsData["proxy_buffers"] as? String, !v.isEmpty { proxyBuffers = v }
        }

        isLoading = false
    }

    private func saveSettings() async {
        isSaving = true

        let settings: [String: String] = [
            "worker_processes": workerProcesses,
            "worker_connections": workerConnections,
            "keepalive_timeout": keepaliveTimeout,
            "gzip": gzip,
            "gzip_min_length": gzipMinLength,
            "gzip_comp_level": gzipCompLevel,
            "client_max_body_size": clientMaxBodySize,
            "client_header_buffer_size": clientHeaderBufferSize,
            "client_body_buffer_size": clientBodyBufferSize,
            "server_names_hash_bucket_size": serverNamesHashBucketSize,
            "types_hash_max_size": typesHashMaxSize,
            "sendfile": sendfile,
            "tcp_nopush": tcpNopush,
            "tcp_nodelay": tcpNodelay,
            "proxy_buffer_size": proxyBufferSize,
            "proxy_buffers": proxyBuffers,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: settings),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            toast.showError("Failed to encode settings")
            isSaving = false
            return
        }

        let raw = await bridge.saveOptimization(serverID: serverId, appID: "nginx", settingsJSON: jsonStr)
        let outcome = parseOptSaveResponse(raw)
        showOptSaveToast(outcome, appTitle: "Nginx", rawEnvelope: raw)

        isSaving = false
        if case .failed = outcome { return }
        await loadSettings()
    }
}
