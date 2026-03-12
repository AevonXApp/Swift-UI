//
//  UnifiedProcessManagerView.swift
//  AevonX
//
//  Shared process management component that works across Python (Gunicorn/Supervisor)
//  and NodeJS (PM2). Provides a unified view for process listing, control, and scaling.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Process Item Model

struct ProcessItem: Identifiable {
    let id: String
    let name: String
    let pid: Int?
    let status: ProcessItemStatus
    let memoryMB: Double
    let cpuPercent: Double
    let uptime: String?
    let restarts: Int
    let type: ProcessType

    enum ProcessItemStatus: String {
        case running = "Running"
        case stopped = "Stopped"
        case errored = "Errored"
        case launching = "Launching"
        case unknown = "Unknown"

        var color: Color {
            switch self {
            case .running: return .axSuccess
            case .stopped: return .axTextMuted
            case .errored: return .axError
            case .launching: return .orange
            case .unknown: return .axTextMuted
            }
        }
    }

    enum ProcessType: String {
        case pm2 = "PM2"
        case gunicorn = "Gunicorn"
        case supervisor = "Supervisor"
        case systemd = "Systemd"
    }
}

// MARK: - Unified Process Manager View

struct UnifiedProcessManagerView: View {
    let title: String
    let processes: [ProcessItem]
    let accentColor: Color
    let isLoading: Bool

    // Actions
    var onStart: ((ProcessItem) -> Void)?
    var onStop: ((ProcessItem) -> Void)?
    var onRestart: ((ProcessItem) -> Void)?
    var onScale: ((ProcessItem, Int) -> Void)?
    var onReload: ((ProcessItem) -> Void)?
    var onRefresh: (() async -> Void)?

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Header
            HStack {
                Text(title)
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)

                if !processes.isEmpty {
                    let running = processes.filter { $0.status == .running }.count
                    Text("\(running)/\(processes.count) running")
                        .font(AXTypography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(running == processes.count ? Color.axSuccess : Color.orange)
                        .cornerRadius(AXCornerRadius.sm)
                }

                Spacer()

                if let onRefresh = onRefresh {
                    AXActionButton(label: "Refresh", icon: "arrow.clockwise", style: .ghost, size: .small) {
                        Task { await onRefresh() }
                    }
                }
            }

            if processes.isEmpty && !isLoading {
                AXPlaceholder(
                    icon: "cpu",
                    title: "No Processes Found",
                    subtitle: "Start a process to see it here"
                )
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(processes) { process in
                    processCard(process)
                }
            }
        }
    }

    // MARK: - Process Card

    @ViewBuilder
    private func processCard(_ process: ProcessItem) -> some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                // Header row
                HStack {
                    Circle()
                        .fill(process.status.color)
                        .frame(width: 10, height: 10)

                    Text(process.name)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    Text(process.type.rawValue)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.7))
                        .cornerRadius(4)

                    Spacer()

                    Text(process.status.rawValue)
                        .font(AXTypography.caption)
                        .foregroundColor(process.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(process.status.color.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }

                // Metrics row
                HStack(spacing: AXSpacing.lg) {
                    if let pid = process.pid {
                        metricItem(label: "PID", value: "\(pid)")
                    }
                    metricItem(label: "Memory", value: String(format: "%.1f MB", process.memoryMB))
                    metricItem(label: "CPU", value: String(format: "%.1f%%", process.cpuPercent))
                    if let uptime = process.uptime {
                        metricItem(label: "Uptime", value: uptime)
                    }
                    if process.restarts > 0 {
                        metricItem(label: "Restarts", value: "\(process.restarts)")
                    }
                }

                // Control buttons
                HStack(spacing: AXSpacing.sm) {
                    if process.status == .running {
                        if let onRestart = onRestart {
                            AXActionButton(label: "Restart", icon: "arrow.clockwise", style: .primary, size: .small) {
                                onRestart(process)
                            }
                        }
                        if let onReload = onReload {
                            AXActionButton(label: "Reload", icon: "arrow.triangle.2.circlepath", style: .ghost, size: .small) {
                                onReload(process)
                            }
                        }
                        if let onStop = onStop {
                            AXActionButton(label: "Stop", icon: "stop.fill", style: .destructive, size: .small) {
                                onStop(process)
                            }
                        }
                    } else {
                        if let onStart = onStart {
                            AXActionButton(label: "Start", icon: "play.fill", style: .primary, size: .small) {
                                onStart(process)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func metricItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(.caption2))
                .foregroundColor(.axTextMuted)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.axTextPrimary)
        }
    }
}
