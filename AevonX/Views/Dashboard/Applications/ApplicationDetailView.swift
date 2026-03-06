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
    let onBack: (() -> Void)?

    init(application: ApplicationInstance, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.serverId = serverId
        self.onBack = onBack
    }

    var body: some View {
        Group {
            // Route to specific detail view based on application type
            switch application.type {
            case .nginx:
                NginxDetailView(application: application, serverId: serverId, onBack: onBack)
            case .phpFpm:
                PHPDetailView(application: application, serverId: serverId, onBack: onBack)
            case .apache:
                ApacheDetailView(application: application, serverId: serverId, onBack: onBack)

            case .nodejs:
                NodeJSDetailView(application: application, serverId: serverId, onBack: onBack)

            case .python:
                PythonDetailView(application: application, serverId: serverId, onBack: onBack)

            // ✅ NEW: Route database engines to unified detail view
            case .mysql, .postgresql, .redis, .mongodb, .mariadb, .sqlite, .cockroachdb, .cassandra, .elasticsearch:
                if let dbType = DatabaseType(rawValue: application.type.rawValue) {
                    UnifiedDatabaseDetailView(
                        application: application,
                        databaseType: dbType,
                        serverId: serverId,
                        onBack: onBack
                    )
                } else {
                    GenericApplicationDetailView(application: application, serverId: serverId)
                }

            default:
                GenericApplicationDetailView(application: application, serverId: serverId)
            }
        }
    }
}

// MARK: - Generic Application Detail View

struct GenericApplicationDetailView: View {
    let application: ApplicationInstance
    let serverId: String
    @State private var logLines: [String] = []
    @State private var isLoadingLogs = false

    private let logColumns: [AXLogColumn] = [
        AXLogColumn(id: "time", title: "Time", width: 140),
        AXLogColumn(id: "message", title: "Message", width: nil),
    ]

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
                            AXInfoRow(label: "Status", value: application.isRunning ? "Running" : "Stopped",
                                      valueColor: application.isRunning ? .axSuccess : .axError)
                            Spacer()
                            Circle()
                                .fill(application.isRunning ? Color.axSuccess : Color.axTextMuted)
                                .frame(width: 12, height: 12)
                        }

                        if let version = application.version {
                            AXInfoRow(label: "Version", value: version, valueColor: .axAccentBlue)
                        }

                        if let port = application.port {
                            AXInfoRow(label: "Port", value: "\(port)")
                        }

                        if let memoryUsage = application.memoryUsage {
                            AXInfoRow(label: "Memory", value: String(format: "%.1f MB", memoryUsage))
                        }

                        AXInfoRow(label: "Auto-start", value: application.autoStart ? "Enabled" : "Disabled",
                                  valueColor: application.autoStart ? .axSuccess : .axTextMuted)
                    }
                }

                // Logs via shared component
                AXLogTable(
                    title: "\(application.type.rawValue) Logs",
                    icon: "doc.text.fill",
                    columns: logColumns,
                    rows: buildRows(logLines),
                    isLoading: isLoadingLogs,
                    onRefresh: { await loadLogs() }
                )
                .frame(minHeight: 350)
            }
            .padding(AXSpacing.xl)
        }
        .task {
            await loadLogs()
        }
    }

    private func buildRows(_ lines: [String]) -> [AXLogRow] {
        lines.enumerated().map { index, line in
            AXLogRow(
                id: index,
                level: AXLogLevelDetector.detect(line),
                cells: [
                    "time": AXLogTimestamp.extract(line),
                    "message": line
                ],
                raw: line
            )
        }
    }

    private func loadLogs() async {
        isLoadingLogs = true
        do {
            let logContent = try await ApplicationManager.shared.readLogs(type: application.type, lines: 100, serverId: serverId)
            await MainActor.run {
                self.logLines = logContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
                self.isLoadingLogs = false
            }
        } catch {
            await MainActor.run {
                self.logLines = ["Failed to load logs: \(error.localizedDescription)"]
                self.isLoadingLogs = false
            }
        }
    }
}
