//
//  PHPXdebugSection.swift
//  AevonX
//
//  Debug profiler toggle & config.
//

import SwiftUI
import AevonXCoreBridge

struct PHPXdebugSection: View {
    let serverId: String
    @State private var isLoading = true
    @State private var isInstalled = false
    @State private var isEnabled = false
    @State private var version = ""
    @State private var mode = "off"
    @State private var clientHost = ""
    @State private var clientPort = ""
    @State private var ideKey = ""
    @State private var isToggling = false
    @State private var isChangingMode = false

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Xdebug Manager", icon: "ant.fill")

                if isLoading {
                    VStack(spacing: AXSpacing.md) {
                        AXSkeletonStatCard()
                        ForEach(0..<3, id: \.self) { _ in AXSkeletonSettingRow() }
                    }
                } else {
                    HStack(spacing: AXSpacing.lg) {
                        ZStack {
                            Circle()
                                .fill(isInstalled ? phpPurple.opacity(0.15) : Color.axSurface)
                                .frame(width: 50, height: 50)
                            Image(systemName: isInstalled ? "ant.fill" : "ant")
                                .font(.system(size: 22))
                                .foregroundColor(isInstalled ? phpPurple : .axTextMuted)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: AXSpacing.sm) {
                                Text(isInstalled ? "Xdebug \(version)" : "Xdebug Not Found")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.axTextPrimary)
                            }
                            Text(isEnabled ? "⚠️ Active in production — disable for performance" : isInstalled ? "Disabled" : "Extension not installed")
                                .font(.system(size: 12))
                                .foregroundColor(isEnabled ? .axWarning : .axTextSecondary)
                        }
                        Spacer()

                        if isInstalled {
                            Button {
                                Task { await toggleXdebug() }
                            } label: {
                                HStack(spacing: 4) {
                                    if isToggling { ProgressView().scaleEffect(0.6) }
                                    Text(isEnabled ? "Disable" : "Enable")
                                        .font(.system(size: 12, weight: .black))
                                }
                                .foregroundColor(isEnabled ? .axWarning : .axSuccess)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(isEnabled ? Color.axWarning.opacity(0.12) : Color.axSuccess.opacity(0.12))
                                .cornerRadius(AXCornerRadius.md)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isToggling)
                        }
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface.opacity(0.4))
                    .cornerRadius(AXCornerRadius.lg)

                    if isInstalled {
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            AXSectionTitle(title: "Xdebug Mode", icon: "switch.2")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.sm) {
                                ForEach(["off", "debug", "profile", "trace", "coverage"], id: \.self) { m in
                                    modeButton(m)
                                }
                            }
                        }
                        .padding(AXSpacing.lg)
                        .background(Color.axSurface.opacity(0.3))
                        .cornerRadius(AXCornerRadius.lg)

                        if !clientHost.isEmpty || !clientPort.isEmpty {
                            VStack(alignment: .leading, spacing: AXSpacing.md) {
                                AXSectionTitle(title: "Configuration", icon: "gearshape.fill")
                                configRow(label: "client_host", value: clientHost)
                                configRow(label: "client_port", value: clientPort)
                                if !ideKey.isEmpty { configRow(label: "idekey", value: ideKey) }
                            }
                            .padding(AXSpacing.lg)
                            .background(Color.axSurface.opacity(0.3))
                            .cornerRadius(AXCornerRadius.lg)
                        }
                    }
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadXdebugInfo() }
    }

    private func modeButton(_ m: String) -> some View {
        Button {
            Task { await setMode(m) }
        } label: {
            Text(m)
                .font(.system(size: 12, weight: mode == m ? .bold : .medium))
                .foregroundColor(mode == m ? .white : .axTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(mode == m ? phpPurple : Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func configRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, design: .monospaced)).foregroundColor(.axTextSecondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundColor(.axTextPrimary)
        }
        .padding(.vertical, 2)
    }

    private func loadXdebugInfo() async {
        isLoading = true
        let json = await bridge.getXdebugInfo(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let info = resp["data"] as? [String: Any] {
            isInstalled = info["installed"] as? Bool ?? false
            isEnabled = info["enabled"] as? Bool ?? false
            version = info["version"] as? String ?? ""
            mode = info["mode"] as? String ?? "off"
            clientHost = info["client_host"] as? String ?? ""
            if let port = info["client_port"] as? Int { clientPort = "\(port)" }
            else { clientPort = info["client_port"] as? String ?? "" }
            ideKey = info["idekey"] as? String ?? ""
        }
        isLoading = false
    }

    private func toggleXdebug() async {
        isToggling = true
        let json = await bridge.toggleXdebug(serverID: serverId, appID: "php-fpm", enable: !isEnabled)
        if let d = json.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess(isEnabled ? "Xdebug disabled" : "Xdebug enabled")
            await loadXdebugInfo()
        } else {
            toast.showError("Failed to toggle Xdebug")
        }
        isToggling = false
    }

    private func setMode(_ newMode: String) async {
        isChangingMode = true
        let json = await bridge.setXdebugMode(serverID: serverId, appID: "php-fpm", mode: newMode)
        if let d = json.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            mode = newMode
            toast.showSuccess("Xdebug mode set to '\(newMode)'")
        } else {
            toast.showError("Failed to change Xdebug mode")
        }
        isChangingMode = false
    }
}
