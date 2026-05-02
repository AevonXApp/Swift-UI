//
//  RedisVersionsSection.swift
//  AevonX
//
//  Version management — install, switch, and view Redis versions.
//

import SwiftUI
import AevonXCoreBridge

struct RedisVersionsSection: View {
    let serverId: String
    let installedVersions: [BridgeAppVersion]
    let availableVersions: [BridgeAppVersion]
    var onRefresh: () async -> Void
    @State private var actionInProgress: String?
    @State private var searchText = ""
    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    private var filteredAvailable: [BridgeAppVersion] {
        let s = Set(installedVersions.map { $0.version })
        let a = availableVersions.filter { !s.contains($0.version) }
        return searchText.isEmpty ? a : a.filter { $0.version.localizedCaseInsensitiveContains(searchText) }
    }
    private var filteredInstalled: [BridgeAppVersion] {
        searchText.isEmpty ? installedVersions : installedVersions.filter { $0.version.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                AXSearchBar(text: $searchText, placeholder: "Search versions..."); Spacer()
                Text("\(installedVersions.count) installed · \(availableVersions.count) available").font(.system(size: 11)).foregroundColor(.axTextMuted)
            }.padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.md).background(Color.axSurface.opacity(0.5))
            Divider().background(Color.axBorder.opacity(0.3))
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.xl) {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "Installed", icon: "checkmark.seal.fill")
                        if filteredInstalled.isEmpty {
                            HStack { Image(systemName: "exclamationmark.triangle").foregroundColor(.axWarning)
                                Text(L10n.Apps.noInstalledVersionDetected).font(AXTypography.caption).foregroundColor(.axTextMuted) }.padding()
                        } else { ForEach(filteredInstalled) { v in installedRow(v) } }
                    }
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "Available Versions", icon: "shippingbox.fill")
                        if filteredAvailable.isEmpty {
                            HStack { Image(systemName: "checkmark.seal").foregroundColor(.axTextMuted)
                                Text(L10n.Apps.noAdditionalVersionsAvailable).font(AXTypography.caption).foregroundColor(.axTextMuted) }.padding()
                        } else { ForEach(filteredAvailable) { v in availableRow(v) } }
                    }
                }.padding(AXSpacing.xl)
            }
        }
    }

    private func installedRow(_ version: BridgeAppVersion) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.axSuccess).font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AXSpacing.sm) {
                    Text("v\(version.version)").font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundColor(.axTextPrimary)
                    if version.isActive { Text(L10n.Label.active).font(.system(size: 8, weight: .heavy)).foregroundColor(.axSuccess)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(Color.axSuccess.opacity(0.1)).cornerRadius(3) }
                }
                if let ch = version.channel { Text(ch.capitalized).font(.system(size: 10, weight: .medium)).foregroundColor(.axAccentBlue) }
            }; Spacer()
        }.padding(AXSpacing.md).background(Color.axSurface).cornerRadius(AXCornerRadius.md)
    }

    private func availableRow(_ version: BridgeAppVersion) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "circle").foregroundColor(.axTextMuted).font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text("v\(version.version)").font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundColor(.axTextPrimary)
                if let ch = version.channel { Text(ch.capitalized).font(.system(size: 10, weight: .medium)).foregroundColor(.axAccentBlue) }
            }; Spacer()
            Button { Task { await installVersion(version.version) } } label: {
                HStack(spacing: 4) {
                    if actionInProgress == "install_\(version.version)" { ProgressView().scaleEffect(0.5) }
                    else { Image(systemName: "arrow.down.circle").font(.system(size: 10)) }
                    Text(L10n.Button.install).font(.system(size: 11, weight: .medium))
                }.foregroundColor(.axSuccess).padding(.horizontal, AXSpacing.sm).padding(.vertical, 4)
                    .background(Color.axSuccess.opacity(0.1)).cornerRadius(AXCornerRadius.sm)
            }.buttonStyle(PlainButtonStyle()).disabled(actionInProgress != nil)
        }.padding(AXSpacing.md).background(Color.axSurface).cornerRadius(AXCornerRadius.md)
    }

    private func installVersion(_ version: String) async {
        actionInProgress = "install_\(version)"
        let pid = toast.showProgress("Installing Redis v\(version)...")
        let json = await bridge.installVersion(serverID: serverId, appID: "redis", version: version); toast.dismiss(id: pid)
        if let d = json.data(using: .utf8), let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any], r["success"] as? Bool == true {
            toast.showSuccess("Redis v\(version) installed"); await onRefresh()
        } else { toast.showError("Failed to install v\(version)") }
        actionInProgress = nil
    }
}
