//
//  PgSQLOptimizationSection.swift
//  AevonX
//
//  Form-based postgresql.conf tuning — visual controls for
//  shared_buffers, work_mem, WAL, connections, parallelism.
//

import SwiftUI
import AevonXCoreBridge

struct PgSQLOptimizationSection: View {
    let serverId: String

    // Settings state — maps to Go PgSQLOptimizationSettings
    @State private var sharedBuffers = "128MB"
    @State private var workMem = "4MB"
    @State private var maintenanceWorkMem = "64MB"
    @State private var effectiveCacheSize = "4GB"
    @State private var maxConnections = "100"
    @State private var walBuffers = "16MB"
    @State private var checkpointCompletionTarget = "0.9"
    @State private var randomPageCost = "4.0"
    @State private var effectiveIOConcurrency = "200"
    @State private var maxWorkerProcesses = "8"
    @State private var maxParallelWorkersPerGather = "2"
    @State private var maxParallelWorkers = "8"

    @State private var isLoading = true
    @State private var isSaving = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let pgsqlBlue = Color(red: 0.2, green: 0.4, blue: 0.57)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    // Memory
                    AppOptimizationGroup(title: "Memory", icon: "memorychip.fill", color: .purple) {
                        AppOptimizationRow(label: "shared_buffers", value: $sharedBuffers,
                                           hint: "Shared memory for caching. ~25% of RAM", placeholder: "128MB")
                        AppOptimizationRow(label: "work_mem", value: $workMem,
                                           hint: "Memory per sort/hash operation", placeholder: "4MB")
                        AppOptimizationRow(label: "maintenance_work_mem", value: $maintenanceWorkMem,
                                           hint: "Memory for VACUUM, CREATE INDEX", placeholder: "64MB")
                        AppOptimizationRow(label: "effective_cache_size", value: $effectiveCacheSize,
                                           hint: "Estimate of OS disk cache. ~75% of RAM", placeholder: "4GB")
                    }

                    // Connections
                    AppOptimizationGroup(title: "Connections", icon: "link.circle.fill", color: .axAccentBlue) {
                        AppOptimizationRow(label: "max_connections", value: $maxConnections,
                                           hint: "Maximum concurrent connections", placeholder: "100")
                    }

                    // WAL (Write-Ahead Log)
                    AppOptimizationGroup(title: "WAL", icon: "doc.text.fill", color: .orange) {
                        AppOptimizationRow(label: "wal_buffers", value: $walBuffers,
                                           hint: "WAL buffer memory (auto = 1/32 of shared_buffers)", placeholder: "16MB")
                        AppOptimizationRow(label: "checkpoint_completion_target", value: $checkpointCompletionTarget,
                                           hint: "Spread checkpoints over this fraction (0.0–1.0)", placeholder: "0.9")
                    }

                    // I/O & Planner
                    AppOptimizationGroup(title: "I/O & Planner", icon: "speedometer", color: .mint) {
                        AppOptimizationRow(label: "random_page_cost", value: $randomPageCost,
                                           hint: "SSD: 1.1, HDD: 4.0. Planner cost estimate", placeholder: "4.0")
                        AppOptimizationRow(label: "effective_io_concurrency", value: $effectiveIOConcurrency,
                                           hint: "SSD: 200. Concurrent I/O operations", placeholder: "200")
                    }

                    // Parallelism
                    AppOptimizationGroup(title: "Parallelism", icon: "cpu.fill", color: .cyan) {
                        AppOptimizationRow(label: "max_worker_processes", value: $maxWorkerProcesses,
                                           hint: "Maximum background workers", placeholder: "8")
                        AppOptimizationRow(label: "max_parallel_workers_per_gather", value: $maxParallelWorkersPerGather,
                                           hint: "Max parallel workers per query", placeholder: "2")
                        AppOptimizationRow(label: "max_parallel_workers", value: $maxParallelWorkers,
                                           hint: "Max total parallel workers", placeholder: "8")
                    }

                    // Save button
                    AppOptimizationSaveButton(title: "Save", color: pgsqlBlue, isSaving: isSaving) {
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
        let json = await bridge.getOptimization(serverID: serverId, appID: "pgsql")

        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let settingsData = resp["data"] as? [String: Any] {

            if let v = settingsData["shared_buffers"] as? String, !v.isEmpty { sharedBuffers = v }
            if let v = settingsData["work_mem"] as? String, !v.isEmpty { workMem = v }
            if let v = settingsData["maintenance_work_mem"] as? String, !v.isEmpty { maintenanceWorkMem = v }
            if let v = settingsData["effective_cache_size"] as? String, !v.isEmpty { effectiveCacheSize = v }
            if let v = settingsData["max_connections"] as? String, !v.isEmpty { maxConnections = v }
            if let v = settingsData["wal_buffers"] as? String, !v.isEmpty { walBuffers = v }
            if let v = settingsData["checkpoint_completion_target"] as? String, !v.isEmpty { checkpointCompletionTarget = v }
            if let v = settingsData["random_page_cost"] as? String, !v.isEmpty { randomPageCost = v }
            if let v = settingsData["effective_io_concurrency"] as? String, !v.isEmpty { effectiveIOConcurrency = v }
            if let v = settingsData["max_worker_processes"] as? String, !v.isEmpty { maxWorkerProcesses = v }
            if let v = settingsData["max_parallel_workers_per_gather"] as? String, !v.isEmpty { maxParallelWorkersPerGather = v }
            if let v = settingsData["max_parallel_workers"] as? String, !v.isEmpty { maxParallelWorkers = v }
        }

        isLoading = false
    }

    private func saveSettings() async {
        isSaving = true

        let settings: [String: String] = [
            "shared_buffers": sharedBuffers,
            "work_mem": workMem,
            "maintenance_work_mem": maintenanceWorkMem,
            "effective_cache_size": effectiveCacheSize,
            "max_connections": maxConnections,
            "wal_buffers": walBuffers,
            "checkpoint_completion_target": checkpointCompletionTarget,
            "random_page_cost": randomPageCost,
            "effective_io_concurrency": effectiveIOConcurrency,
            "max_worker_processes": maxWorkerProcesses,
            "max_parallel_workers_per_gather": maxParallelWorkersPerGather,
            "max_parallel_workers": maxParallelWorkers,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: settings),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            toast.showError("Failed to encode settings")
            isSaving = false
            return
        }

        let result = await bridge.saveOptimization(serverID: serverId, appID: "pgsql", settingsJSON: jsonStr)

        if let data = result.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Optimization saved — postgresql.conf updated")
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
