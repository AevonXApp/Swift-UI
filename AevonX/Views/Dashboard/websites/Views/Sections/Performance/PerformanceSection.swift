//
//  PerformanceSection.swift
//  AevonX
//
//  Per-site performance analysis section — uses SiteMonitoringService from Core
//

import SwiftUI
import AevonXCore

struct PerformanceSection: View {
    let serverId: String
    let domain: String
    let docRoot: String

    @State private var responseTime: String = "—"
    @State private var largeFiles: [String] = []
    @State private var diskBreakdown: [(size: String, path: String)] = []
    @State private var isLoading = false

    private let service = SiteMonitoringService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                HStack {
                    AXSectionTitle(title: "Performance", icon: "gauge.with.dots.needle.67percent")
                    Spacer()
                    Button(action: { Task { await runAllChecks() } }) {
                        HStack(spacing: 4) {
                            if isLoading { ProgressView().scaleEffect(0.7) }
                            else { Image(systemName: "play.fill") }
                            Text("Run Analysis")
                        }
                        .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                // Speed Test
                AXStatCard(icon: "speedometer", label: "Response Time", value: responseTime, color: responseTimeColor)

                // Disk Usage Breakdown
                if !diskBreakdown.isEmpty {
                    AXConfigCard(icon: "internaldrive", title: "Disk Usage by Folder", subtitle: "Top 20 folders by size") {
                        VStack(spacing: AXSpacing.xs) {
                            ForEach(diskBreakdown, id: \.path) { entry in
                                HStack {
                                    Text(entry.size)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.axAccentBlue)
                                        .frame(width: 60, alignment: .trailing)
                                    Text(entry.path.replacingOccurrences(of: docRoot + "/", with: "./"))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                // Large Files
                if !largeFiles.isEmpty {
                    AXConfigCard(icon: "doc.fill", title: "Large Files (>10MB)", subtitle: "Files that may impact performance") {
                        VStack(spacing: AXSpacing.xs) {
                            ForEach(largeFiles, id: \.self) { file in
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.axWarning)
                                    Text(file.replacingOccurrences(of: docRoot + "/", with: "./"))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                if diskBreakdown.isEmpty && largeFiles.isEmpty && !isLoading {
                    EmptyStateCard(icon: "gauge.with.dots.needle.67percent", title: "Performance Analysis", message: "Click 'Run Analysis' to check response time, disk usage, and large files")
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    private var responseTimeColor: Color {
        guard let ms = Double(responseTime.replacingOccurrences(of: "ms", with: "").replacingOccurrences(of: "s", with: "")) else { return .axTextMuted }
        if responseTime.contains("ms") { return ms < 500 ? .axSuccess : .axWarning }
        return ms < 2 ? .axWarning : .axError
    }

    private func runAllChecks() async {
        isLoading = true
        defer { isLoading = false }

        // Speed test via Core
        if let seconds = try? await service.measureResponseTime(domain: domain, serverId: serverId) {
            responseTime = seconds < 1.0 ? String(format: "%.0fms", seconds * 1000) : String(format: "%.2fs", seconds)
        }

        // Disk breakdown via Core
        if let entries = try? await service.analyzeDiskUsage(docRoot: docRoot, serverId: serverId) {
            diskBreakdown = entries.map { (size: $0.size, path: $0.path) }
        }

        // Large files via Core
        if let files = try? await service.findLargeFiles(docRoot: docRoot, serverId: serverId) {
            largeFiles = files
        }
    }
}
