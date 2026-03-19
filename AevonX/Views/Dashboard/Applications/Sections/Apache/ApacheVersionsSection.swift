//
//  ApacheVersionsSection.swift
//  AevonX
//
//  Apache installed & available versions with install/uninstall actions.
//

import SwiftUI
import AevonXCoreBridge

struct ApacheVersionsSection: View {
    let serverId: String
    let installedVersions: [BridgeAppVersion]
    let availableVersions: [BridgeAppVersion]

    @State private var isInstalling: String?
    @State private var isUninstalling: String?

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let apacheRed = Color(red: 0.82, green: 0.13, blue: 0.16)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Installed
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    AXSectionTitle(title: "Installed Versions", icon: "checkmark.circle.fill")

                    if installedVersions.isEmpty {
                        emptyState(icon: "shippingbox", text: "No versions detected")
                    } else {
                        ForEach(installedVersions) { version in
                            versionRow(version, installed: true)
                        }
                    }
                }

                Divider().background(Color.axBorder.opacity(0.2))

                // Available
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    AXSectionTitle(title: "Available Versions", icon: "arrow.down.circle.fill")

                    ForEach(availableVersions) { version in
                        versionRow(version, installed: false)
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private func versionRow(_ version: BridgeAppVersion, installed: Bool) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: installed ? "checkmark.circle.fill" : "arrow.down.circle")
                .font(.system(size: 14))
                .foregroundColor(installed ? apacheRed : .axTextMuted)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AXSpacing.sm) {
                    Text(version.version)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                    if version.isActive {
                        Text("ACTIVE").font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white).padding(.horizontal, 5).padding(.vertical, 2)
                            .background(apacheRed).cornerRadius(3)
                    }
                }
                if let channel = version.channel, !channel.isEmpty {
                    Text(channel)
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            if installed && !version.isActive {
                Button {
                    Task { await uninstallVersion(version.version) }
                } label: {
                    if isUninstalling == version.version {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Text("Uninstall").font(.system(size: 11, weight: .medium))
                            .foregroundColor(.axError)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isUninstalling != nil)
            } else if !installed {
                Button {
                    Task { await installVersion(version.version) }
                } label: {
                    if isInstalling == version.version {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Text("Install").font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 4)
                            .background(apacheRed).cornerRadius(AXCornerRadius.sm)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isInstalling != nil)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.15), lineWidth: 1))
    }

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: icon).font(.system(size: 24)).foregroundColor(.axTextMuted)
            Text(text).font(AXTypography.caption).foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xl)
    }

    private func installVersion(_ version: String) async {
        isInstalling = version
        let json = await bridge.installVersion(serverID: serverId, appID: "apache", version: version)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Apache \(version) install started")
        } else { toast.showError("Failed to install Apache \(version)") }
        isInstalling = nil
    }

    private func uninstallVersion(_ version: String) async {
        isUninstalling = version
        let json = await bridge.uninstallVersion(serverID: serverId, appID: "apache", version: version)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Apache \(version) uninstalled")
        } else { toast.showError("Failed to uninstall Apache \(version)") }
        isUninstalling = nil
    }
}
