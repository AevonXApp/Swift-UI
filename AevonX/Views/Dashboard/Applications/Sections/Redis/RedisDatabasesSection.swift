//
//  RedisDatabasesSection.swift
//  AevonX
//
//  Keyspace stats — displays Redis databases with key counts.
//

import SwiftUI
import AevonXCoreBridge

struct RedisDatabasesSection: View {
    let serverId: String
    @State private var sites: [[String: Any]] = []
    @State private var isLoading = true
    @State private var searchText = ""
    private let bridge = ApplicationBridge.shared

    var filteredSites: [[String: Any]] {
        guard !searchText.isEmpty else { return sites }
        return sites.filter { ($0["name"] as? String ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.axTextMuted)
                TextField("Search keyspaces...", text: $searchText).textFieldStyle(.plain).font(.system(size: 12))
            }.padding(.horizontal, AXSpacing.md).padding(.vertical, 8).background(Color.axSurface).cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1)).padding(AXSpacing.xl)

            if isLoading {
                VStack(spacing: AXSpacing.sm) { ForEach(0..<4, id: \.self) { _ in AXSkeletonRow().padding(.horizontal, AXSpacing.xl) } }
                    .padding(.top, AXSpacing.lg); Spacer()
            } else if filteredSites.isEmpty {
                Spacer()
                VStack(spacing: AXSpacing.md) {
                    ZStack { Circle().fill(Color.axAccentBlue.opacity(0.08)).frame(width: 60, height: 60)
                        Image(systemName: "key.fill").font(.system(size: 24, weight: .medium)).foregroundColor(.axTextMuted) }
                    Text(searchText.isEmpty ? "No keyspaces found" : "No results for \"\(searchText)\"")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.axTextSecondary)
                    if searchText.isEmpty {
                        Text(L10n.Apps.redisKeyspaceDataWillAppearHereWhenDetected)
                            .font(.system(size: 11)).foregroundColor(.axTextMuted).multilineTextAlignment(.center).frame(maxWidth: 280)
                    }
                }; Spacer()
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) { ForEach(filteredSites.indices, id: \.self) { i in siteCard(filteredSites[i]) } }
                        .padding(.horizontal, AXSpacing.xl).padding(.bottom, AXSpacing.xl)
                }
            }
        }.task { await loadSites() }
    }

    private func siteCard(_ site: [String: Any]) -> some View {
        let name = site["name"] as? String ?? ""
        let domain = site["domain"] as? String ?? ""
        let port = site["port"] as? String ?? ""

        return VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: "key.fill").font(.system(size: 12)).foregroundColor(Color(red: 0.86, green: 0.23, blue: 0.23))
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
                    if !domain.isEmpty { Text("keys=\(domain)").font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextSecondary) }
                    if !port.isEmpty { Text("expires=\(port)").font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextMuted) }
                }; Spacer()
            }
        }.padding(AXSpacing.lg).background(Color.axSurface).cornerRadius(AXCornerRadius.md)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.15), lineWidth: 1))
    }

    private func loadSites() async {
        isLoading = true
        let json = await bridge.listSites(serverID: serverId, appID: "redis")
        if let d = json.data(using: .utf8), let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           let list = r["data"] as? [[String: Any]] { sites = list }
        isLoading = false
    }
}
