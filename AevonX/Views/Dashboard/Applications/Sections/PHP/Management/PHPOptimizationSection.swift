//
//  PHPOptimizationSection.swift
//  AevonX
//
//  Memory, execution & upload limits — now using shared grouped design.
//

import SwiftUI
import AevonXCoreBridge

struct PHPOptimizationSection: View {
    let serverId: String
    @State private var settings: [String: String] = [:]
    @State private var isLoading = true
    @State private var isSaving = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    if isLoading {
                        AppOptimizationGroup(title: L10n.Status.loading, icon: "slider.horizontal.3", color: phpPurple) {
                            ForEach(0..<5, id: \.self) { _ in AppOptimizationSkeletonRow() }
                        }
                    } else {
                        // Memory & Limits
                        AppOptimizationGroup(title: "Memory & Limits", icon: "memorychip", color: phpPurple) {
                            settingRow(key: "memory_limit", label: "memory_limit", hint: "Max memory per script")
                            settingRow(key: "max_input_vars", label: "max_input_vars", hint: "Max input variables")
                        }

                        // Execution
                        AppOptimizationGroup(title: "Execution", icon: "clock.fill", color: .orange) {
                            settingRow(key: "max_execution_time", label: "max_execution_time", hint: "Seconds. Max script execution time")
                            settingRow(key: "max_input_time", label: "max_input_time", hint: "Seconds. Max input parsing time")
                        }

                        // Upload
                        AppOptimizationGroup(title: "Upload", icon: "arrow.up.doc.fill", color: .cyan) {
                            settingRow(key: "upload_max_filesize", label: "upload_max_filesize", hint: "Maximum upload file size")
                            settingRow(key: "post_max_size", label: "post_max_size", hint: "Maximum POST data size")
                            settingRow(key: "max_file_uploads", label: "max_file_uploads", hint: "Max simultaneous file uploads")
                        }

                        // Cache
                        AppOptimizationGroup(title: "Cache & Buffering", icon: "folder.fill", color: .mint) {
                            settingRow(key: "realpath_cache_size", label: "realpath_cache_size", hint: "Realpath lookup cache size")
                            settingRow(key: "realpath_cache_ttl", label: "realpath_cache_ttl", hint: "Seconds. Cache TTL")
                            settingRow(key: "output_buffering", label: "output_buffering", hint: "Output buffer size")
                        }

                        // Save
                        AppOptimizationSaveButton(
                            title: "Save Optimization",
                            color: phpPurple,
                            isSaving: isSaving
                        ) {
                            Task { await saveSettings() }
                        }
                        .padding(.top, AXSpacing.md)
                    }
                    Spacer()
                }
                .padding(AXSpacing.xl)
            }
        }
        .task { await loadSettings() }
    }

    // MARK: - Setting Row (uses shared AppOptimizationRow pattern)

    private func settingRow(key: String, label: String, hint: String) -> some View {
        AppOptimizationRow(
            label: label,
            value: Binding(
                get: { settings[key] ?? "" },
                set: { settings[key] = $0 }
            ),
            hint: hint,
            placeholder: ""
        )
    }

    // MARK: - Data

    private func loadSettings() async {
        isLoading = true
        let json = await bridge.getOptimization(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let r = try? JSONDecoder().decode(BridgeDataResponse<[String: String]>.self, from: data),
           r.success, let d = r.data { settings = d }
        isLoading = false
    }

    private func saveSettings() async {
        isSaving = true
        defer { isSaving = false }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: settings),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            toast.showError("Invalid settings payload")
            return
        }

        let raw = await bridge.saveOptimization(serverID: serverId, appID: "php-fpm", settingsJSON: jsonStr)
        let outcome = parseOptSaveResponse(raw)
        showOptSaveToast(outcome, appTitle: "PHP-FPM", rawEnvelope: raw)

        // On any successful persistence (with or without restart) re-read
        // from the server so the UI reflects reality, not the user's edits.
        if case .failed = outcome { return }
        await loadSettings()
    }
}
