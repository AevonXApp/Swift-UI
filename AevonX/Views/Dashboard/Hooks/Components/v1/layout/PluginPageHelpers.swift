//
//  PluginPageHelpers.swift
//  AevonX
//
//  Helper views used by PluginPageComponent:
//  DashboardStatPill, DashboardDataTableCard, DashboardChartCard,
//  PluginLayoutCardView, ScanProgressData
//

import SwiftUI
import AevonXCore

// MARK: - Dashboard Stat Pill

struct DashboardStatPill: View {
    let card: HookLayoutCard
    let serverId: String
    let context: [String: String]
    var namespace: String? = nil
    @StateObject private var vm = HookPluginViewModel()
    @State private var displayValue: String?
    @State private var statusColor: Color = .axAccentBlue
    @State private var refreshTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Circle().fill(statusColor).frame(width: 8, height: 8)
                if let icon = card.icon {
                    Image(systemName: icon).font(.system(size: 13, weight: .medium)).foregroundColor(statusColor)
                }
                Text(card.title).font(.system(size: 11, weight: .semibold)).foregroundColor(.axTextSecondary)
                    .textCase(.uppercase).tracking(0.5)
            }
            if let value = displayValue, !value.isEmpty {
                Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.axTextPrimary)
                    .lineLimit(2).minimumScaleFactor(0.7)
            } else if vm.isLoading {
                HStack(spacing: AXSpacing.xs) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: statusColor)).scaleEffect(0.6)
                    Text("Loading…").font(AXTypography.caption2).foregroundColor(.axTextMuted)
                }
            } else {
                Text("—").font(.system(size: 20, weight: .bold)).foregroundColor(.axTextMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(AXSpacing.lg)
        .background(RoundedRectangle(cornerRadius: AXCornerRadius.lg).fill(Color.axSurface)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(statusColor.opacity(0.3), lineWidth: 1)))
        .task { await loadStatData(); scheduleAutoRefresh() }
        .onDisappear { refreshTask?.cancel(); refreshTask = nil }
        .onReceive(NotificationCenter.default.publisher(for: .pluginScanCompleted)) { _ in
            Task { displayValue = nil; await loadStatData() }
        }
    }

    private func scheduleAutoRefresh() {
        guard let interval = card.dataSource?.refreshInterval, interval > 0 else { return }
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { break }
                await loadStatData()
            }
        }
    }

    private func loadStatData() async {
        guard let ds = card.dataSource else { return }
        let command = HookPluginCommand(type: ds.type ?? .coreCmd, action: ds.action, payload: ds.payload, timeout: 15)
        await vm.execute(command: command, pluginId: "stat_\(card.title)", serverId: serverId, context: context, namespace: namespace)
        guard let output = vm.resultOutput, let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        parseStatValue(from: json)
    }

    private func parseStatValue(from json: [String: Any]) {
        if let valuePath = card.dataSource?.valuePath, !valuePath.isEmpty {
            if let extracted = extractValue(from: json, path: valuePath) {
                let title = card.title.lowercased()
                if title.contains("uptime") {
                    if let seconds = extracted as? Double { displayValue = AXFormatter.formatDuration(seconds: seconds) }
                    else if let seconds = extracted as? Int { displayValue = AXFormatter.formatDuration(seconds: Double(seconds)) }
                    else if valuePath.contains("ms"), let ms = extracted as? Double { displayValue = AXFormatter.formatDuration(seconds: ms / 1000.0) }
                    else if valuePath.contains("ms"), let ms = extracted as? Int { displayValue = AXFormatter.formatDuration(seconds: Double(ms) / 1000.0) }
                    else { displayValue = AXFormatter.formatValue(extracted) }
                } else { displayValue = AXFormatter.formatValue(extracted) }
                if let suffix = json["suffix"] as? String, !suffix.isEmpty { displayValue = (displayValue ?? "") + suffix }
                if let trend = json["trend"] as? String {
                    switch trend { case "up": displayValue = (displayValue ?? "") + " ↑"; case "down": displayValue = (displayValue ?? "") + " ↓"; default: break }
                }
                statusColor = detectStatusColor(for: extracted, title: title); return
            }
        }
        let title = card.title.lowercased()
        if title.contains("service") || title.contains("status") {
            let statusText = json["status_text"] as? String ?? "Unknown"
            let status = json["status"] as? String ?? ""
            let version = json["version"] as? String ?? ""
            if status == "active" {
                statusColor = .axSuccess; displayValue = "✓ \(statusText)"
                if !version.isEmpty && version != "unknown" {
                    let cleanVersion = version.hasPrefix("v") ? String(version.dropFirst()) : version
                    displayValue = "✓ \(statusText) · v\(cleanVersion)"
                }
            } else { statusColor = .axError; displayValue = "✗ \(statusText)" }
        } else if title.contains("uptime") {
            if let seconds = json["uptime_seconds"] as? Double { displayValue = AXFormatter.formatDuration(seconds: seconds); statusColor = .axSuccess }
            else if let seconds = json["uptime_seconds"] as? Int { displayValue = AXFormatter.formatDuration(seconds: Double(seconds)); statusColor = .axSuccess }
            else if let ms = json["uptime_ms"] as? Double { displayValue = AXFormatter.formatDuration(seconds: ms / 1000.0); statusColor = .axSuccess }
            else if let ms = json["uptime_ms"] as? Int { displayValue = AXFormatter.formatDuration(seconds: Double(ms) / 1000.0); statusColor = .axSuccess }
            else { displayValue = AXFormatter.formatValue(json["uptime"] ?? "—"); statusColor = .axSuccess }
        } else if title.contains("scan") || title.contains("summary") {
            let totalFindings = json["total_findings"] as? Int ?? 0; let filesScanned = json["files_scanned"] as? Int ?? 0
            statusColor = totalFindings > 0 ? .axWarning : .axSuccess
            displayValue = filesScanned > 0 ? "\(totalFindings) findings · \(filesScanned) files" : (json["message"] as? String ?? "No scans yet")
        } else if title.contains("policy") || title.contains("gate") {
            let policyPass = json["policy_pass"] as? Bool ?? true; let riskScore = json["risk_score"] as? Int ?? 0
            if policyPass { statusColor = .axSuccess; displayValue = riskScore > 0 ? "✓ PASS · Risk \(riskScore)" : "✓ PASS" }
            else { statusColor = .axError; displayValue = "✗ FAIL · Risk \(riskScore)" }
        } else if title.contains("severity") || title.contains("distribution") {
            if let bySeverity = json["by_severity"] as? [[String: Any]], !bySeverity.isEmpty {
                let parts = bySeverity.compactMap { item -> String? in
                    guard let label = item["label"] as? String, let value = item["value"] else { return nil }
                    return "\(value) \(label)"
                }
                displayValue = parts.joined(separator: " · "); statusColor = .axAccentBlue
            } else {
                let totalFindings = json["total_findings"] as? Int ?? 0
                displayValue = totalFindings > 0 ? "\(totalFindings) total" : "No findings"
                statusColor = totalFindings > 0 ? .axWarning : .axSuccess
            }
        } else {
            if let msg = json["message"] as? String { displayValue = msg }
            else { displayValue = json.values.compactMap { "\($0)" }.prefix(2).joined(separator: " · ") }
            statusColor = .axAccentBlue
        }
    }

    private func formatDuration(seconds: Double) -> String {
        AXFormatter.formatDuration(seconds: seconds)
    }

    private func extractValue(from json: [String: Any], path: String) -> Any? {
        let keys = path.split(separator: ".").map(String.init); var current: Any = json
        for key in keys { guard let dict = current as? [String: Any], let next = dict[key] else { return nil }; current = next }
        return current
    }

    private func formatStatValue(_ value: Any) -> String {
        AXFormatter.formatValue(value)
    }

    private func formatLargeNumber(_ num: Double) -> String {
        AXFormatter.formatNumber(num)
    }

    private func detectStatusColor(for value: Any, title: String) -> Color {
        if title.contains("block") || title.contains("threat") || title.contains("attack") {
            if let num = value as? Int, num > 0 { return .axWarning }
            if let num = value as? Double, num > 0 { return .axWarning }; return .axSuccess
        }
        if title.contains("protection") || title.contains("rate") {
            if let num = value as? Double {
                if num >= 90 { return .axSuccess }; if num >= 50 { return .axWarning }; return .axError
            }
        }
        if title.contains("qps") || title.contains("speed") || title.contains("request") { return .axAccentBlue }
        if title.contains("bot") { return .axWarning }
        if title.contains("human") || title.contains("uptime") { return .axSuccess }
        return .axAccentBlue
    }
}
