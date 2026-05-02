//
//  LiteSpeedSitesSection.swift
//  AevonX
//
//  Virtual host management for LiteSpeed.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedSitesSection: View {
    let serverId: String

    @State private var sites: [[String: Any]] = []
    @State private var isLoading = false
    @State private var processingName = ""

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack {
                    AXSectionTitle(title: "Virtual Hosts (\(sites.count))", icon: "globe")
                    Spacer()
                    AXRefreshButton(isLoading: isLoading) { await loadSites() }
                }

                if isLoading && sites.isEmpty {
                    VStack { Spacer(); ProgressView("Loading virtual hosts..."); Spacer() }
                        .frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xl)
                } else if sites.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Spacer()
                        Image(systemName: "globe").font(AXTypography.largeTitle).foregroundColor(.axTextMuted.opacity(0.3))
                        Text(L10n.Apps.noVirtualHostsFound).font(AXTypography.callout).foregroundColor(.axTextMuted)
                        Spacer()
                    }.frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xl)
                } else {
                    ForEach(sites.indices, id: \.self) { i in
                        siteCard(sites[i])
                    }
                }

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadSites() }
    }

    private func siteCard(_ site: [String: Any]) -> some View {
        let name = site["name"] as? String ?? ""
        let domain = site["domain"] as? String ?? "—"
        let port = site["port"] as? String ?? "80"
        let ssl = site["ssl_enabled"] as? Bool ?? false
        let enabled = site["enabled"] as? Bool ?? false
        let root = site["root_dir"] as? String ?? ""
        let isProcessing = processingName == name

        return HStack(spacing: AXSpacing.md) {
            // Status indicator
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(enabled ? lsGreen.opacity(0.1) : Color.axError.opacity(0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: ssl ? "lock.fill" : "globe")
                    .font(AXTypography.body)
                    .foregroundColor(enabled ? lsGreen : .axTextMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AXSpacing.sm) {
                    Text(name)
                        .font(AXTypography.callout).fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                    if ssl {
                        Label("SSL", systemImage: "lock.fill")
                            .font(AXTypography.caption2).fontWeight(.bold)
                            .foregroundColor(lsGreen)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(lsGreen.opacity(0.1)).cornerRadius(3)
                    }
                }
                Text("\(domain):\(port)")
                    .font(AXTypography.monoSm)
                    .foregroundColor(.axTextSecondary)
                if !root.isEmpty {
                    Text(root)
                        .font(AXTypography.monoXxs)
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(enabled ? L10n.Status.enabled.uppercased() : L10n.Status.disabled.uppercased())
                .font(AXTypography.caption2).fontWeight(.bold)
                .foregroundColor(enabled ? lsGreen : .axError)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background((enabled ? lsGreen : Color.axError).opacity(0.1))
                .cornerRadius(3)

            // Toggle
            if isProcessing {
                ProgressView().scaleEffect(0.7)
            } else {
                Button {
                    Task { await toggleSite(name: name, isEnabled: enabled) }
                } label: {
                    Text(enabled ? "Disable" : "Enable")
                        .font(AXTypography.caption).fontWeight(.semibold)
                        .foregroundColor(enabled ? .axError : lsGreen)
                        .padding(.horizontal, AXSpacing.sm).padding(.vertical, 4)
                        .background((enabled ? Color.axError : lsGreen).opacity(0.08))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.1), lineWidth: 1)
        )
    }

    private func loadSites() async {
        isLoading = true
        let json = await bridge.listSites(serverID: serverId, appID: "litespeed")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = resp["data"] as? [[String: Any]] {
            sites = list
        }
        isLoading = false
    }

    private func toggleSite(name: String, isEnabled: Bool) async {
        processingName = name
        let json = isEnabled
            ? await bridge.disableSite(serverID: serverId, appID: "litespeed", name: name)
            : await bridge.enableSite(serverID: serverId, appID: "litespeed", name: name)

        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("\(name) \(isEnabled ? "disabled" : "enabled")")
            await loadSites()
        } else {
            toast.showError("Failed to toggle \(name)")
        }
        processingName = ""
    }
}
