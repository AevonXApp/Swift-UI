//
//  PHPOptimizationSection.swift
//  AevonX
//
//  Memory, execution & upload limits.
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

    private let fields: [(key: String, label: String, icon: String)] = [
        ("memory_limit", "Memory Limit", "memorychip"),
        ("max_execution_time", "Max Execution Time", "clock"),
        ("max_input_time", "Max Input Time", "clock.arrow.circlepath"),
        ("upload_max_filesize", "Upload Max Filesize", "arrow.up.doc"),
        ("post_max_size", "Post Max Size", "doc.fill"),
        ("max_file_uploads", "Max File Uploads", "square.and.arrow.up"),
        ("max_input_vars", "Max Input Vars", "number"),
        ("realpath_cache_size", "Realpath Cache Size", "folder"),
        ("realpath_cache_ttl", "Realpath Cache TTL", "timer"),
        ("output_buffering", "Output Buffering", "arrow.up.arrow.down"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "PHP Optimization", icon: "slider.horizontal.3")

                if isLoading {
                    VStack(spacing: AXSpacing.md) {
                        ForEach(0..<5, id: \.self) { _ in AXSkeletonSettingRow() }
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.md) {
                        ForEach(fields, id: \.key) { f in
                            settingRow(key: f.key, label: f.label, icon: f.icon)
                        }
                    }

                    Button {
                        Task { await saveSettings() }
                    } label: {
                        HStack {
                            if isSaving { ProgressView().scaleEffect(0.7) }
                            Text("Save Optimization").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AXSpacing.md)
                        .background(phpPurple)
                        .foregroundColor(.white)
                        .cornerRadius(AXCornerRadius.lg)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSaving)
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadSettings() }
    }

    private func settingRow(key: String, label: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(phpPurple)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.axTextPrimary)
            Spacer()
            TextField("", text: Binding(
                get: { settings[key] ?? "" },
                set: { settings[key] = $0 }
            ))
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(.axTextPrimary)
            .frame(width: 120)
            .padding(.horizontal, AXSpacing.sm).padding(.vertical, 4)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

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
        if let jsonData = try? JSONSerialization.data(withJSONObject: settings),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            let result = await bridge.saveOptimization(serverID: serverId, appID: "php-fpm", settingsJSON: jsonStr)
            if let d = result.data(using: .utf8),
               let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
               r["success"] as? Bool == true {
                toast.showSuccess("PHP optimization settings saved")
            } else {
                toast.showError("Failed to save settings")
            }
        }
        isSaving = false
    }
}
