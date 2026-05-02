//
//  NginxCachePerformanceSection.swift
//  AevonX
//
//  Cache Manager + Performance Score sections.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Cache Manager

struct NginxCacheSection: View {
    let serverId: String
    @State private var caches: [[String: Any]] = []
    @State private var isLoading = true
    @State private var purgingPath = ""
    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading cache...").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if caches.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "memorychip").font(.system(size: 40)).foregroundColor(.axTextMuted)
                    Text(L10n.Apps.noCacheConfigured).font(.system(size: 14, weight: .semibold)).foregroundColor(.axTextSecondary)
                    Text(L10n.Apps.addFastcgiCachePathOrProxyCachePathToNginxConf).font(.system(size: 11)).foregroundColor(.axTextMuted).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.lg) {
                        ForEach(caches.indices, id: \.self) { i in cacheCard(caches[i]) }
                    }.padding(AXSpacing.xl)
                }
            }
        }
        .task { await loadCache() }
    }

    private func cacheCard(_ cache: [String: Any]) -> some View {
        let type = cache["type"] as? String ?? ""
        let path = cache["path"] as? String ?? ""
        let diskUsed = cache["disk_used"] as? String ?? "—"
        let keys = cache["keys"] as? Int ?? 0
        let isPurging = purgingPath == path

        return VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Label(type.uppercased() + " Cache", systemImage: type == "fastcgi" ? "bolt.fill" : "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.mint)
                Spacer()
                Button { Task { await purge(path: path) } } label: {
                    HStack(spacing: 4) {
                        if isPurging { ProgressView().scaleEffect(0.6) } else { Image(systemName: "trash.fill") }
                        Text(L10n.Apps.purge).font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.red).cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle()).disabled(isPurging)
            }
            HStack(spacing: AXSpacing.xl) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Apps.diskUsed).font(.system(size: 9)).foregroundColor(.axTextMuted)
                    Text(diskUsed).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(.axTextPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Apps.keys).font(.system(size: 9)).foregroundColor(.axTextMuted)
                    Text("\(keys)").font(.system(size: 12, weight: .semibold)).foregroundColor(.axTextPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Field.path).font(.system(size: 9)).foregroundColor(.axTextMuted)
                    Text(path).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextSecondary).lineLimit(1)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.mint.opacity(0.3), lineWidth: 1))
    }

    private func loadCache() async {
        isLoading = true
        let json = await bridge.listCache(serverID: serverId, appID: "nginx")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = resp["data"] as? [[String: Any]] { caches = list }
        isLoading = false
    }

    private func purge(path: String) async {
        purgingPath = path
        let json = await bridge.purgeCache(serverID: serverId, appID: "nginx", path: path)
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true {
            toast.showSuccess("Cache purged")
            await loadCache()
        } else { toast.showError("Purge failed") }
        purgingPath = ""
    }
}

// MARK: - Performance Score

struct NginxPerformanceScoreSection: View {
    let serverId: String
    @State private var total = 0
    @State private var categories: [(name: String, score: Int, details: String)] = []
    @State private var suggestions: [String] = []
    @State private var isLoading = true
    private let bridge = ApplicationBridge.shared

    private var scoreColor: Color { total >= 70 ? .green : total >= 40 ? .orange : .red }
    private var grade: String {
        switch total {
        case 90...100: return "A — Excellent"
        case 75..<90:  return "B — Good"
        case 50..<75:  return "C — Average"
        case 25..<50:  return "D — Needs Work"
        default:       return "F — Critical"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Score circle
                ZStack {
                    Circle().stroke(Color.axBorder.opacity(0.2), lineWidth: 12).frame(width: 130, height: 130)
                    Circle()
                        .trim(from: 0, to: CGFloat(total) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 130, height: 130).rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.2), value: total)
                    VStack(spacing: 2) {
                        Text("\(total)").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(scoreColor)
                        Text(grade).font(.system(size: 10, weight: .semibold)).foregroundColor(.axTextMuted)
                    }
                }
                .padding(.top, AXSpacing.xl)

                // Category bars
                if !categories.isEmpty {
                    VStack(spacing: 1) {
                        ForEach(categories, id: \.name) { cat in
                            HStack(spacing: AXSpacing.md) {
                                Text(cat.name).font(.system(size: 12, weight: .medium)).foregroundColor(.axTextPrimary).frame(width: 110, alignment: .leading)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4).fill(Color.axBorder.opacity(0.2)).frame(height: 12)
                                        RoundedRectangle(cornerRadius: 4).fill(cat.score >= 70 ? Color.green : cat.score >= 40 ? Color.orange : Color.red)
                                            .frame(width: geo.size.width * CGFloat(cat.score) / 100, height: 12)
                                            .animation(.easeInOut(duration: 0.8), value: cat.score)
                                    }
                                }.frame(height: 12)
                                Text("\(cat.score)").font(.system(size: 12, weight: .bold)).foregroundColor(cat.score >= 70 ? .green : cat.score >= 40 ? .orange : .red).frame(width: 28)
                                Text(cat.details).font(.system(size: 10)).foregroundColor(.axTextMuted)
                                Spacer()
                            }
                            .padding(.horizontal, AXSpacing.lg).padding(.vertical, 10).background(Color.axSurface)
                        }
                    }
                    .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, AXSpacing.xl)
                }

                // Suggestions
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(suggestions, id: \.self) { s in
                            HStack(spacing: AXSpacing.sm) {
                                Image(systemName: "arrow.up.circle.fill").foregroundColor(.axAccentBlue).font(.system(size: 12))
                                Text(s).font(.system(size: 12)).foregroundColor(.axTextPrimary)
                                Spacer()
                            }.padding(.horizontal, AXSpacing.lg).padding(.vertical, 8).background(Color.axSurface)
                        }
                    }
                    .background(Color.axSurface).cornerRadius(AXCornerRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, AXSpacing.xl)
                }
            }
            .padding(.bottom, AXSpacing.xl)
        }
        .task { await loadScore() }
    }

    private func loadScore() async {
        isLoading = true
        let json = await bridge.getPerformanceScore(serverID: serverId, appID: "nginx")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let d = resp["data"] as? [String: Any] {
            total = d["total"] as? Int ?? 0
            categories = (d["categories"] as? [[String: Any]] ?? []).map {
                (name: $0["name"] as? String ?? "",
                 score: $0["score"] as? Int ?? 0,
                 details: $0["details"] as? String ?? "")
            }
            suggestions = d["suggestions"] as? [String] ?? []
        }
        isLoading = false
    }
}
