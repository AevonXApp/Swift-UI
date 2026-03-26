//
//  NginxVersionsSection.swift
//  AevonX
//
//  Version management — install, switch, and view versions.
//

import SwiftUI
import AevonXCoreBridge

struct NginxVersionsSection: View {
    let serverId: String
    let installedVersions: [BridgeAppVersion]
    let availableVersions: [BridgeAppVersion]
    var onRefresh: () async -> Void

    @State private var actionInProgress: String?
    @State private var searchText = ""

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    // Filter installed out of available to avoid duplicates
    private var filteredAvailable: [BridgeAppVersion] {
        let installedSet = Set(installedVersions.map { $0.version })
        let available = availableVersions.filter { !installedSet.contains($0.version) }
        if searchText.isEmpty { return available }
        return available.filter { $0.version.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredInstalled: [BridgeAppVersion] {
        if searchText.isEmpty { return installedVersions }
        return installedVersions.filter { $0.version.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: AXSpacing.md) {
                AXSearchBar(text: $searchText, placeholder: "Search versions...")

                Spacer()

                Text("\(installedVersions.count) installed · \(availableVersions.count) available")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            Divider().background(Color.axBorder.opacity(0.3))

            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    // Installed
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "Installed", icon: "checkmark.seal.fill")

                        if filteredInstalled.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.axWarning)
                                Text("No installed version detected")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                            }
                            .padding()
                        } else {
                            ForEach(filteredInstalled) { version in
                                installedVersionRow(version)
                            }
                        }
                    }

                    // Available
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "Available Versions", icon: "shippingbox.fill")

                        ForEach(filteredAvailable) { version in
                            availableVersionRow(version)
                        }
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
    }

    // MARK: - Installed Version Row

    private func installedVersionRow(_ version: BridgeAppVersion) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.axSuccess)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AXSpacing.sm) {
                    Text("v\(version.version)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.axTextPrimary)

                    if version.isActive {
                        Text("ACTIVE")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(.axSuccess)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axSuccess.opacity(0.1))
                            .cornerRadius(3)
                    }
                }

                if let channel = version.channel {
                    Text(channel.capitalized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(channel == "mainline" ? .orange : .axAccentBlue)
                }
            }

            Spacer()

            // Switch button (only for non-active installed versions)
            if !version.isActive {
                Button {
                    Task { await switchToVersion(version.version) }
                } label: {
                    HStack(spacing: 4) {
                        if actionInProgress == "switch_\(version.version)" {
                            ProgressView().scaleEffect(0.5)
                        } else {
                            Image(systemName: "arrow.triangle.swap")
                                .font(.system(size: 10))
                        }
                        Text(L10n.Database.switchVersion)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(actionInProgress != nil)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Available Version Row

    private func availableVersionRow(_ version: BridgeAppVersion) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "circle")
                .foregroundColor(.axTextMuted)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text("v\(version.version)")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)

                if let channel = version.channel {
                    Text(channel.capitalized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(channel == "mainline" ? .orange : .axAccentBlue)
                }
            }

            Spacer()

            // Install button
            Button {
                Task { await installVersion(version.version) }
            } label: {
                HStack(spacing: 4) {
                    if actionInProgress == "install_\(version.version)" {
                        ProgressView().scaleEffect(0.5)
                    } else {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 10))
                    }
                    Text(L10n.Button.install)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.axSuccess)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 4)
                .background(Color.axSuccess.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(actionInProgress != nil)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Actions

    private func installVersion(_ version: String) async {
        actionInProgress = "install_\(version)"
        let progressID = toast.showProgress("Installing Nginx v\(version)...")

        let json = await bridge.installVersion(serverID: serverId, appID: "nginx", version: version)

        toast.dismiss(id: progressID)

        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Nginx v\(version) installed successfully")
            await onRefresh()
        } else {
            var err = "Failed to install v\(version)"
            if let data = json.data(using: .utf8),
               let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errStr = resp["error"] as? String {
                err = errStr
            }
            toast.showError(err)
        }

        actionInProgress = nil
    }

    private func switchToVersion(_ version: String) async {
        actionInProgress = "switch_\(version)"
        let progressID = toast.showProgress("Switching to Nginx v\(version)...")

        let json = await bridge.switchVersion(serverID: serverId, appID: "nginx", version: version)

        toast.dismiss(id: progressID)

        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Switched to Nginx v\(version)")
            await onRefresh()
        } else {
            var err = "Failed to switch to v\(version)"
            if let data = json.data(using: .utf8),
               let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errStr = resp["error"] as? String {
                err = errStr
            }
            toast.showError(err)
        }

        actionInProgress = nil
    }
}
