//
//  PgSQLDatabasesSection.swift
//  AevonX
//
//  Database list — displays PostgreSQL databases with sizes.
//

import SwiftUI
import AevonXCoreBridge

struct PgSQLDatabasesSection: View {
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
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.axTextMuted)
                TextField("Search databases...", text: $searchText).textFieldStyle(.plain).font(.system(size: 12))
            }
            .padding(.horizontal, AXSpacing.md).padding(.vertical, 8)
            .background(Color.axSurface).cornerRadius(AXCornerRadius.sm)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
            .padding(AXSpacing.xl)

            if isLoading {
                VStack(spacing: AXSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in AXSkeletonRow().padding(.horizontal, AXSpacing.xl) }
                }.padding(.top, AXSpacing.lg)
                Spacer()
            } else if filteredSites.isEmpty {
                Spacer()
                VStack(spacing: AXSpacing.md) {
                    ZStack {
                        Circle().fill(Color.axAccentBlue.opacity(0.08)).frame(width: 60, height: 60)
                        Image(systemName: "cylinder.fill").font(.system(size: 24, weight: .medium)).foregroundColor(.axTextMuted)
                    }
                    Text(searchText.isEmpty ? "No databases found" : "No results for \"\(searchText)\"")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.axTextSecondary)
                    if searchText.isEmpty {
                        Text("PostgreSQL databases will appear here when detected")
                            .font(.system(size: 11)).foregroundColor(.axTextMuted).multilineTextAlignment(.center).frame(maxWidth: 280)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(filteredSites.indices, id: \.self) { i in siteCard(filteredSites[i]) }
                    }.padding(.horizontal, AXSpacing.xl).padding(.bottom, AXSpacing.xl)
                }
            }
        }
        .task { await loadSites() }
    }

    private func siteCard(_ site: [String: Any]) -> some View {
        let name = site["name"] as? String ?? ""
        let domain = site["domain"] as? String ?? "—"
        let port = site["port"] as? String ?? ""
        let enabled = site["enabled"] as? Bool ?? false

        return VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.md) {
                Circle().fill(enabled ? Color.green : Color.axTextMuted).frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 13, weight: .semibold)).foregroundColor(.axTextPrimary)
                    if !port.isEmpty {
                        Text("Size: \(port)").font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextSecondary)
                    }
                }
                Spacer()
            }
        }
        .padding(AXSpacing.lg).background(Color.axSurface).cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.15), lineWidth: 1))
    }

    private func loadSites() async {
        isLoading = true
        let json = await bridge.listSites(serverID: serverId, appID: "pgsql")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = resp["data"] as? [[String: Any]] { sites = list }
        isLoading = false
    }
}
