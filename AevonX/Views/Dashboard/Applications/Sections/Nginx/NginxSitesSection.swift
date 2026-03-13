//
//  NginxSitesSection.swift
//  AevonX
//
//  Site Manager — list, enable, disable nginx server blocks.
//

import SwiftUI
import AevonXCoreBridge

struct NginxSitesSection: View {
    let serverId: String

    @State private var sites: [[String: Any]] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var processingName = ""

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    var filteredSites: [[String: Any]] {
        guard !searchText.isEmpty else { return sites }
        return sites.filter {
            let name = $0["name"] as? String ?? ""
            let domain = $0["domain"] as? String ?? ""
            return name.localizedCaseInsensitiveContains(searchText) || domain.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.axTextMuted)
                TextField("Search sites...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, 8)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
            .padding(AXSpacing.xl)

            if isLoading {
                // Skeleton loading
                VStack(spacing: AXSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        AXSkeletonRow()
                            .padding(.horizontal, AXSpacing.xl)
                    }
                }
                .padding(.top, AXSpacing.lg)
                Spacer()
            } else if filteredSites.isEmpty {
                Spacer()
                VStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.axAccentBlue.opacity(0.08))
                            .frame(width: 60, height: 60)
                        Image(systemName: "globe")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.axTextMuted)
                    }
                    Text(searchText.isEmpty ? "No sites found" : "No results for \"\(searchText)\"")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.axTextSecondary)
                    if searchText.isEmpty {
                        Text("Add server blocks in /etc/nginx/conf.d/ to manage sites here")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(filteredSites.indices, id: \.self) { i in
                            siteCard(filteredSites[i])
                        }
                    }
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.bottom, AXSpacing.xl)
                }
            }
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

        return VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.md) {
                // Status dot
                Circle()
                    .fill(enabled ? Color.green : Color.axTextMuted)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AXSpacing.sm) {
                        Text(name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.axTextPrimary)
                        if ssl {
                            Label("SSL", systemImage: "lock.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(3)
                        }
                    }
                    Text("\(domain):\(port)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                }

                Spacer()

                // Toggle enable/disable
                if isProcessing {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Button {
                        Task { await toggleSite(name: name, isEnabled: enabled) }
                    } label: {
                        Text(enabled ? "Disable" : "Enable")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(enabled ? .red : .green)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, 5)
                            .background((enabled ? Color.red : Color.green).opacity(0.1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if !root.isEmpty {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Text(root)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(enabled ? Color.green.opacity(0.2) : Color.axBorder.opacity(0.15), lineWidth: 1)
        )
    }

    private func loadSites() async {
        isLoading = true
        let json = await bridge.listSites(serverID: serverId, appID: "nginx")
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
            ? await bridge.disableSite(serverID: serverId, appID: "nginx", name: name)
            : await bridge.enableSite(serverID: serverId, appID: "nginx", name: name)

        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("\(name) \(isEnabled ? "disabled" : "enabled")")
            await loadSites()
        } else {
            toast.showError("Failed to \(isEnabled ? "disable" : "enable") \(name)")
        }
        processingName = ""
    }
}
