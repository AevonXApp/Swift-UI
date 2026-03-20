//
//  LiteSpeedOptimizationSection.swift
//  AevonX
//
//  LiteSpeed performance tuning — connections, cache, timeouts.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedOptimizationSection: View {
    let serverId: String

    @State private var settings: [String: String] = [:]
    @State private var isLoading = true
    @State private var isSaving = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    private let directives: [(key: String, label: String, icon: String, placeholder: String)] = [
        ("max_connections", "Max Connections", "link.circle.fill", "10000"),
        ("max_keep_alive_req", "Max KeepAlive Requests", "arrow.triangle.2.circlepath", "10000"),
        ("keep_alive_timeout", "KeepAlive Timeout (s)", "clock.fill", "5"),
        ("conn_timeout", "Connection Timeout (s)", "timer", "300"),
        ("max_req_body_size", "Max Request Body Size", "doc.fill", "2047M"),
        ("max_dyn_req_len", "Max Dynamic Response", "arrow.right.doc.on.clipboard", "2047M"),
        ("max_cgi_instances", "Max CGI Instances", "terminal.fill", "20"),
        ("ext_app_timeout", "External App Timeout (s)", "clock.arrow.2.circlepath", "60"),
        ("cache_enabled", "Cache Enabled (1/0)", "tray.2.fill", "1"),
        ("cache_max_obj_size", "Cache Max Object Size", "internaldrive.fill", "10000000"),
        ("event_dispatcher", "Event Dispatcher", "bolt.fill", "best"),
        ("max_ssl_connections", "Max SSL Connections", "lock.shield.fill", "10000"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Performance Tuning", icon: "slider.horizontal.3")

                if isLoading {
                    VStack { Spacer(); ProgressView("Loading optimization settings..."); Spacer() }
                        .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xl)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: AXSpacing.md), GridItem(.flexible(), spacing: AXSpacing.md)], spacing: AXSpacing.md) {
                        ForEach(directives, id: \.key) { directive in
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                HStack(spacing: AXSpacing.xs) {
                                    Image(systemName: directive.icon)
                                        .font(AXTypography.caption)
                                        .foregroundColor(lsGreen)
                                    Text(directive.label)
                                        .font(AXTypography.footnote).fontWeight(.medium)
                                        .foregroundColor(.axTextSecondary)
                                }
                                TextField(directive.placeholder, text: binding(for: directive.key))
                                    .font(AXTypography.monoLg)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, AXSpacing.sm)
                                    .padding(.vertical, 6)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
                            }
                            .padding(AXSpacing.md)
                            .background(Color.axSurface.opacity(0.3))
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.1), lineWidth: 1))
                        }
                    }

                    HStack {
                        Spacer()
                        Button {
                            Task { await saveSettings() }
                        } label: {
                            HStack(spacing: AXSpacing.sm) {
                                if isSaving {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(AXTypography.subheadline)
                                }
                                Text("Save & Apply")
                                    .font(AXTypography.callout).fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.xl).padding(.vertical, AXSpacing.sm)
                            .background(lsGreen)
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isSaving)
                    }
                }

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadSettings() }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { settings[key] ?? "" },
            set: { settings[key] = $0 }
        )
    }

    private func loadSettings() async {
        isLoading = true
        let json = await bridge.getOptimization(serverID: serverId, appID: "litespeed")
        if let data = json.data(using: .utf8),
           let resp = try? JSONDecoder().decode(BridgeDataResponse<[String: String]>.self, from: data),
           resp.success {
            settings = resp.data ?? [:]
        }
        isLoading = false
    }

    private func saveSettings() async {
        isSaving = true
        guard let jsonData = try? JSONSerialization.data(withJSONObject: settings),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            toast.showError("Failed to encode settings"); isSaving = false; return
        }
        let json = await bridge.saveOptimization(serverID: serverId, appID: "litespeed", settingsJSON: jsonStr)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Optimization settings saved")
        } else {
            toast.showError("Failed to save optimization settings")
        }
        isSaving = false
    }
}
