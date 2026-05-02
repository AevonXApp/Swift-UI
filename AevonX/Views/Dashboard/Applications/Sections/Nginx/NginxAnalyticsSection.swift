//
//  NginxAnalyticsSection.swift
//  AevonX
//
//  Access log analytics — top IPs, URLs, status codes, error rate.
//

import SwiftUI
import AevonXCoreBridge

struct NginxAnalyticsSection: View {
    let serverId: String

    @State private var totalRequests = 0
    @State private var errorRate = 0.0
    @State private var topIPs: [CountItem] = []
    @State private var topURLs: [CountItem] = []
    @State private var statusCodes: [String: Int] = [:]
    @State private var isLoading = true
    @State private var selectedLines = 5000

    private let bridge = ApplicationBridge.shared

    struct CountItem: Identifiable {
        let id = UUID()
        let value: String
        let count: Int
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                // Controls
                HStack {
                    Text(L10n.Apps.analyzeLast)
                        .font(.system(size: 12))
                        .foregroundColor(.axTextSecondary)
                    Picker("", selection: $selectedLines) {
                        Text("1,000 lines").tag(1000)
                        Text("5,000 lines").tag(5000)
                        Text("10,000 lines").tag(10000)
                        Text("50,000 lines").tag(50000)
                    }
                    .frame(width: 140)
                    Button(L10n.Button.refresh) { Task { await loadAnalytics() } }
                        .buttonStyle(PlainButtonStyle())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axAccentBlue)
                }

                // Summary cards
                HStack(spacing: AXSpacing.lg) {
                    analyticsCard(title: "Total Requests", value: "\(totalRequests)", icon: "arrow.up.right", color: .axAccentBlue)
                    analyticsCard(title: "Error Rate", value: String(format: "%.1f%%", errorRate), icon: "exclamationmark.triangle", color: errorRate > 10 ? .red : .orange)
                    analyticsCard(title: "Unique IPs", value: "\(topIPs.count)", icon: "network", color: .purple)
                    analyticsCard(title: "Unique URLs", value: "\(topURLs.count)", icon: "link", color: .teal)
                }

                // Status codes
                if !statusCodes.isEmpty {
                    analyticsGroup(title: "Status Codes", icon: "number.circle.fill", color: .indigo) {
                        HStack(spacing: AXSpacing.lg) {
                            ForEach(statusCodes.sorted(by: { $0.key < $1.key }), id: \.key) { code, count in
                                VStack(spacing: 4) {
                                    Text(code)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(statusCodeColor(code))
                                    Text("\(count)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.axTextSecondary)
                                    Text(statusCodeLabel(code))
                                        .font(.system(size: 9))
                                        .foregroundColor(.axTextMuted)
                                }
                                .padding(AXSpacing.md)
                                .background(statusCodeColor(code).opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }
                        .padding(AXSpacing.lg)
                    }
                }

                // Top IPs
                if !topIPs.isEmpty {
                    analyticsGroup(title: "Top IPs", icon: "network.badge.shield.half.filled", color: .red) {
                        VStack(spacing: 1) {
                            ForEach(topIPs.prefix(10)) { item in
                                barRow(label: item.value, count: item.count, maxCount: topIPs.first?.count ?? 1, color: .red)
                            }
                        }
                    }
                }

                // Top URLs
                if !topURLs.isEmpty {
                    analyticsGroup(title: "Top URLs", icon: "link.circle.fill", color: .teal) {
                        VStack(spacing: 1) {
                            ForEach(topURLs.prefix(10)) { item in
                                barRow(label: item.value, count: item.count, maxCount: topURLs.first?.count ?? 1, color: .teal)
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await loadAnalytics() }
    }

    private func analyticsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
    }

    private func analyticsGroup<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 12, weight: .semibold))
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.axTextPrimary)
            }
            content()
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
        }
    }

    private func barRow(label: String, count: Int, maxCount: Int, color: Color) -> some View {
        let pct = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
        return HStack(spacing: AXSpacing.md) {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 180, alignment: .leading)
                .lineLimit(1)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.1)).frame(height: 16)
                    RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.6)).frame(width: geo.size.width * pct, height: 16)
                }
            }
            .frame(height: 16)
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.axTextSecondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, 6)
    }

    private func statusCodeColor(_ code: String) -> Color {
        let c = Int(code) ?? 0
        if c < 300 { return .green }
        if c < 400 { return .axAccentBlue }
        if c < 500 { return .orange }
        return .red
    }

    private func statusCodeLabel(_ code: String) -> String {
        switch code {
        case "200": return "OK"
        case "301": return "Redirect"
        case "302": return "Found"
        case "304": return "Not Modified"
        case "400": return "Bad Request"
        case "401": return "Unauthorized"
        case "403": return "Forbidden"
        case "404": return "Not Found"
        case "429": return "Rate Limited"
        case "500": return "Server Error"
        case "502": return "Bad Gateway"
        case "503": return "Unavailable"
        default: return code
        }
    }

    private func loadAnalytics() async {
        isLoading = true
        let json = await bridge.getLogAnalytics(serverID: serverId, appID: "nginx", lines: Int32(selectedLines))
        if let data = json.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let d = resp["data"] as? [String: Any] {

            totalRequests = d["total_requests"] as? Int ?? 0
            errorRate = d["error_rate"] as? Double ?? 0

            if let ips = d["top_ips"] as? [[String: Any]] {
                topIPs = ips.map { CountItem(value: $0["value"] as? String ?? "", count: $0["count"] as? Int ?? 0) }
            }
            if let urls = d["top_urls"] as? [[String: Any]] {
                topURLs = urls.map { CountItem(value: $0["value"] as? String ?? "", count: $0["count"] as? Int ?? 0) }
            }
            if let codes = d["status_codes"] as? [String: Int] {
                statusCodes = codes
            }
        }
        isLoading = false
    }
}
