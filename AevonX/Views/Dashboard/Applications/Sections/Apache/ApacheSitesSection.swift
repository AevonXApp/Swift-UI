//
//  ApacheSitesSection.swift
//  AevonX
//
//  Apache VirtualHost site manager — list, enable, disable.
//

import SwiftUI
import AevonXCoreBridge

struct ApacheSitesSection: View {
    let serverId: String

    @State private var sites: [SiteItem] = []
    @State private var isLoading = true
    @State private var actionInProgress: String?

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let apacheRed = Color(red: 0.82, green: 0.13, blue: 0.16)

    struct SiteItem: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        var enabled: Bool
        let domain: String
        let port: String
        let ssl: Bool
        let root: String
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                AXSectionTitle(title: "Virtual Hosts", icon: "globe")
                Spacer()
                Button { Task { await loadSites() } } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11))
                        Text("Refresh").font(.system(size: 11, weight: .medium))
                    }.foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
                Text("\(sites.count) sites").font(.system(size: 11)).foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.md)
            .background(Color.axSurface.opacity(0.5))

            Divider().background(Color.axBorder.opacity(0.3))

            if isLoading {
                Spacer(); ProgressView("Loading sites..."); Spacer()
            } else if sites.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "globe").font(.system(size: 28)).foregroundColor(.axTextMuted)
                    Text("No virtual hosts found").font(AXTypography.caption).foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(sites) { site in siteRow(site) }
                    }.padding(AXSpacing.lg)
                }
            }
        }
        .task { await loadSites() }
    }

    private func siteRow(_ site: SiteItem) -> some View {
        HStack(spacing: AXSpacing.md) {
            Circle()
                .fill(site.enabled ? apacheRed : Color.axTextMuted.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(site.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    Text(site.domain).font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextSecondary)
                    Text(":\(site.port)").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(.axTextMuted)
                    if site.ssl {
                        HStack(spacing: 2) {
                            Image(systemName: "lock.fill").font(.system(size: 8))
                            Text("SSL").font(.system(size: 9, weight: .bold))
                        }.foregroundColor(.green).padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.green.opacity(0.1)).cornerRadius(3)
                    }
                }
                if !site.root.isEmpty {
                    Text(site.root).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextMuted).lineLimit(1)
                }
            }

            Spacer()

            Button {
                Task {
                    if site.enabled { await disableSite(site.name) } else { await enableSite(site.name) }
                }
            } label: {
                if actionInProgress == site.name {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Text(site.enabled ? "Disable" : "Enable")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(site.enabled ? .axError : apacheRed)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(actionInProgress != nil)
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(site.enabled ? 0.5 : 0.2))
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(site.enabled ? apacheRed.opacity(0.15) : Color.axBorder.opacity(0.1), lineWidth: 1))
    }

    private func loadSites() async {
        isLoading = true
        let json = await bridge.listSites(serverID: serverId, appID: "apache")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let rawSites = resp["data"] as? [[String: Any]] {
            sites = rawSites.map { s in
                SiteItem(name: s["name"] as? String ?? "", path: s["path"] as? String ?? "",
                         enabled: s["enabled"] as? Bool ?? false, domain: s["domain"] as? String ?? "",
                         port: s["port"] as? String ?? "80", ssl: s["ssl_enabled"] as? Bool ?? false,
                         root: s["root_dir"] as? String ?? "")
            }
        }
        isLoading = false
    }

    private func enableSite(_ name: String) async {
        actionInProgress = name
        let json = await bridge.enableSite(serverID: serverId, appID: "apache", name: name)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true { toast.showSuccess("Site \(name) enabled") }
        else { toast.showError("Failed to enable \(name)") }
        actionInProgress = nil
        await loadSites()
    }

    private func disableSite(_ name: String) async {
        actionInProgress = name
        let json = await bridge.disableSite(serverID: serverId, appID: "apache", name: name)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true { toast.showSuccess("Site \(name) disabled") }
        else { toast.showError("Failed to disable \(name)") }
        actionInProgress = nil
        await loadSites()
    }
}
