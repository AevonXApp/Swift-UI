//
//  PHPOPcacheSection.swift
//  AevonX
//
//  OPcache & JIT statistics.
//

import SwiftUI
import AevonXCoreBridge

struct PHPOPcacheSection: View {
    let serverId: String
    @State private var isLoading = true
    @State private var isResetting = false
    @State private var opcacheData: [String: Any] = [:]
    @State private var enabled = false
    @State private var hitRate = "N/A"
    @State private var cachedScripts = 0
    @State private var jitEnabled = false
    @State private var usedPct: Double = 0
    @State private var freePct: Double = 0
    @State private var wastedPct: Double = 0

    private let bridge = ApplicationBridge.shared
    private let toast = GlobalToastManager.shared
    private let phpPurple = Color(red: 0.47, green: 0.48, blue: 0.71)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "OPcache & JIT Dashboard", icon: "memorychip")

                if isLoading {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
                        ForEach(0..<4, id: \.self) { _ in AXSkeletonStatCard() }
                    }
                    VStack(spacing: AXSpacing.md) {
                        ForEach(0..<3, id: \.self) { _ in AXSkeletonSettingRow() }
                    }
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
                        AXStatCard(icon: "checkmark.circle.fill", label: "Status",
                                   value: enabled ? L10n.Status.enabled : L10n.Status.disabled,
                                   color: enabled ? .axSuccess : .axError, style: .glass)
                        AXStatCard(icon: "chart.line.uptrend.xyaxis", label: "Hit Rate",
                                   value: hitRate, color: phpPurple, style: .glass)
                        AXStatCard(icon: "doc.text.fill", label: "Cached Scripts",
                                   value: "\(cachedScripts)", color: .cyan, style: .glass)
                        AXStatCard(icon: "bolt.fill", label: "JIT",
                                   value: jitEnabled ? L10n.Status.active : "Off",
                                   color: jitEnabled ? .axSuccess : .axTextMuted, style: .glass)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        AXSectionTitle(title: "Memory Usage", icon: "memorychip.fill")
                        memoryBar(label: "Used", color: phpPurple, pct: usedPct)
                        memoryBar(label: "Free", color: .axSuccess, pct: freePct)
                        memoryBar(label: "Wasted", color: .axWarning, pct: wastedPct)
                    }
                    .padding(AXSpacing.lg)
                    .background(Color.axSurface.opacity(0.3))
                    .cornerRadius(AXCornerRadius.lg)

                    Button {
                        Task { await resetOPcache() }
                    } label: {
                        HStack(spacing: AXSpacing.xs) {
                            if isResetting { ProgressView().scaleEffect(0.65).frame(width: 14, height: 14) }
                            else { Image(systemName: "arrow.clockwise").font(.system(size: 12, weight: .semibold)) }
                            Text(L10n.Apps.resetOpcache).font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(AXSpacing.md)
                        .background(phpPurple)
                        .cornerRadius(AXCornerRadius.lg)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isResetting)
                }
                Spacer()
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadOPcache() }
    }

    private func memoryBar(label: String, color: Color, pct: Double) -> some View {
        HStack(spacing: AXSpacing.md) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(.axTextSecondary).frame(width: 60, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.axSurface).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(color).frame(width: geo.size.width * pct, height: 8)
                }
            }
            .frame(height: 8)
            Text("\(Int(pct * 100))%").font(.system(size: 11, design: .monospaced)).foregroundColor(.axTextMuted).frame(width: 40)
        }
    }

    private func loadOPcache() async {
        isLoading = true
        let json = await bridge.getOPcacheStatus(serverID: serverId, appID: "php-fpm")
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let info = resp["data"] as? [String: Any] {
            enabled = info["enabled"] as? Bool ?? false
            cachedScripts = info["cached_scripts"] as? Int ?? 0
            jitEnabled = info["jit_enabled"] as? Bool ?? false
            if let hr = info["hit_rate"] as? String { hitRate = "\(hr)%" }
            else if let hr = info["hit_rate"] as? Double { hitRate = String(format: "%.1f%%", hr) }
            let used = (info["used_memory"] as? Int64) ?? 0
            let free = (info["free_memory"] as? Int64) ?? 0
            let wasted = (info["wasted_memory"] as? Int64) ?? 0
            let total = max(Double(used + free + wasted), 1)
            usedPct = Double(used) / total
            freePct = Double(free) / total
            wastedPct = Double(wasted) / total
        }
        isLoading = false
    }

    private func resetOPcache() async {
        isResetting = true
        let result = await bridge.resetOPcache(serverID: serverId, appID: "php-fpm")
        if let d = result.data(using: .utf8),
           let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
           r["success"] as? Bool == true {
            toast.showSuccess("OPcache reset successfully")
            await loadOPcache()
        } else {
            toast.showError("Failed to reset OPcache")
        }
        isResetting = false
    }
}
