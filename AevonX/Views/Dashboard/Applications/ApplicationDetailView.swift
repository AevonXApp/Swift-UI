//
//  ApplicationDetailView.swift
//  AevonX
//
//  Detail view for application management
//  Shows full control panel for the selected application
//

import SwiftUI
import AevonXCore

struct ApplicationDetailView: View {
    let application: ApplicationInstance
    let serverId: String

    var body: some View {
        Group {
            // Route to specific detail view based on application type
            switch application.type {
            case .nginx:
                NginxDetailView(application: application, serverId: serverId)
            default:
                GenericApplicationDetailView(application: application, serverId: serverId)
            }
        }
        .navigationTitle(application.name)
    }
}

// MARK: - Generic Application Detail View

struct GenericApplicationDetailView: View {
    let application: ApplicationInstance
    let serverId: String
    @State private var logs: String = ""
    @State private var isLoadingLogs = false

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Status Card
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        Text("Status")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        HStack {
                            AppInfoRow(label: "Status", value: application.isRunning ? "Running" : "Stopped")
                            Spacer()
                            Circle()
                                .fill(application.isRunning ? Color.axSuccess : Color.axTextMuted)
                                .frame(width: 12, height: 12)
                        }

                        if let version = application.version {
                            AppInfoRow(label: "Version", value: version)
                        }

                        if let port = application.port {
                            AppInfoRow(label: "Port", value: "\(port)")
                        }

                        if let memoryUsage = application.memoryUsage {
                            AppInfoRow(label: "Memory", value: String(format: "%.1f MB", memoryUsage))
                        }

                        AppInfoRow(label: "Auto-start", value: application.autoStart ? "Enabled" : "Disabled")
                    }
                }

                // Logs Card
                AXCard {
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        HStack {
                            Text("Logs")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button("Refresh") {
                                Task { await loadLogs() }
                            }
                            .buttonStyle(.bordered)
                        }

                        if isLoadingLogs {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            ScrollView {
                                Text(logs.isEmpty ? "No logs available" : logs)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.axTextSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 300)
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .task {
            await loadLogs()
        }
    }

    private func loadLogs() async {
        isLoadingLogs = true

        do {
            let logContent = try await ApplicationManager.shared.readLogs(type: application.type, lines: 100, serverId: serverId)
            await MainActor.run {
                self.logs = logContent
                self.isLoadingLogs = false
            }
        } catch {
            await MainActor.run {
                self.logs = "Failed to load logs: \(error.localizedDescription)"
                self.isLoadingLogs = false
            }
        }
    }
}

// MARK: - App Info Row Component

struct AppInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            Spacer()
            Text(value)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
        }
    }
}
