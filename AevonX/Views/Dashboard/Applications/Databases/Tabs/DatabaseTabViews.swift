//
//  DatabaseTabViews.swift
//  AevonX
//
//  Tab view components for unified database engine management
//  These are placeholder implementations following the PHP/Nginx pattern
//

import SwiftUI
import AevonXCore

// MARK: - Overview Tab

struct DatabaseOverviewTab: View {
    let application: ApplicationInstance
    let databaseType: DatabaseType
    @Binding var dbConfig: DatabaseConfigData
    let serverId: String
    let onReload: () -> Void
    let onTest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Service Status Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Service Status")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    HStack {
                        StatusRow(label: "Status", value: application.isRunning ? "Running" : "Stopped", color: application.isRunning ? .axSuccess : .axError)
                    }

                    if let version = application.version {
                        StatusRow(label: "Version", value: version)
                    }

                    let port = databaseType.defaultPort
                    if port > 0 {
                        StatusRow(label: "Port", value: "\(port)")
                    }

                    StatusRow(label: "Auto-start", value: application.autoStart ? "Enabled" : "Disabled")
                }
            }

            // Configuration Path Card
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Paths")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    StatusRow(label: "Config", value: dbConfig.configPath.isEmpty ? "N/A" : dbConfig.configPath)
                    StatusRow(label: "Logs", value: dbConfig.logPath.isEmpty ? "N/A" : dbConfig.logPath)
                    StatusRow(label: "Data", value: dbConfig.dataPath.isEmpty ? "N/A" : dbConfig.dataPath)
                }
            }

            // Actions
            HStack(spacing: AXSpacing.md) {
                AXActionButton(label: "Reload Service", icon: "arrow.clockwise", style: .ghost, fullWidth: true) {
                    onReload()
                }

                AXActionButton(label: "Test Configuration", icon: "checkmark.circle", style: .ghost, fullWidth: true) {
                    onTest()
                }
            }
        }
    }
}

// MARK: - Configuration Tab

struct DatabaseConfigurationTab: View {
    let application: ApplicationInstance
    let databaseType: DatabaseType
    @Binding var dbConfig: DatabaseConfigData
    let serverId: String
    let onSave: (String) async -> Void

    @State private var editedConfig: String = ""
    @State private var hasChanges: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Text("Configuration File")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Spacer()

                        Text(dbConfig.configPath)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                            .monospaced()
                    }

                    TextEditor(text: $editedConfig)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 500)
                        .padding(AXSpacing.sm)
                        .background(Color.axSurface.opacity(0.3))
                        .cornerRadius(AXCornerRadius.md)

                    HStack {
                        AXActionButton(label: "Reset", icon: "arrow.uturn.backward", style: .ghost) {
                            editedConfig = dbConfig.rawConfig
                            hasChanges = false
                        }
                        .disabled(!hasChanges)

                        Spacer()

                        AXActionButton(label: "Save Configuration", icon: "checkmark", style: .primary) {
                            Task {
                                await onSave(editedConfig)
                                hasChanges = false
                            }
                        }
                        .disabled(!hasChanges)
                    }
                }
            }
        }
        .task(id: dbConfig.rawConfig) {
            // Initialize or update config only when it actually changes
            if editedConfig != dbConfig.rawConfig {
                editedConfig = dbConfig.rawConfig
                hasChanges = false
            }
        }
        .onChange(of: editedConfig) { oldValue, newValue in
            // Check for changes only when user edits
            if oldValue != newValue {
                hasChanges = (newValue != dbConfig.rawConfig)
            }
        }
    }
}

// MARK: - Logs Tab

struct DatabaseLogsTab: View {
    let application: ApplicationInstance
    let databaseType: DatabaseType
    let serverId: String
    let onSuccess: (String) -> Void
    let onError: (String) -> Void

    @State private var logLines: [String] = []
    @State private var isLoading = false

    private let logColumns: [AXLogColumn] = [
        AXLogColumn(id: "time", title: "Time", width: 140),
        AXLogColumn(id: "message", title: "Message", width: nil),
    ]

    var body: some View {
        AXLogTable(
            title: "\(databaseType.displayName) Logs",
            icon: "doc.text.fill",
            columns: logColumns,
            rows: buildRows(logLines),
            isLoading: isLoading,
            accentColor: databaseType.brandColor,
            onRefresh: { await loadLogs() }
        )
        .frame(minHeight: 400)
        .id("\(databaseType.rawValue)-logs")
        .task { await loadLogs() }
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
        isLoading = true
        defer { isLoading = false }
        do {
            let content = try await ApplicationManager.shared.readLogs(type: application.type, lines: 200, serverId: serverId)
            logLines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        } catch {
            logLines = ["Error loading logs: \(error.localizedDescription)"]
            onError(error.localizedDescription)
        }
    }
}

// MARK: - Versions Tab

struct DatabaseVersionsTab: View {
    let application: ApplicationInstance
    let databaseType: DatabaseType
    let serverId: String

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Version Management")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    Text("Current Version: \(application.version ?? "Unknown")")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)

                    Text("Version management coming soon...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .padding(.top, AXSpacing.xl)
                }
            }
        }
    }
}

// MARK: - Optimization Tab

struct DatabaseOptimizationTab: View {
    let application: ApplicationInstance
    let databaseType: DatabaseType
    let serverId: String

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Performance Optimization")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    Text("Optimization recommendations coming soon...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
            }
        }
    }
}

// MARK: - Access Tab

struct DatabaseAccessTab: View {
    let application: ApplicationInstance
    let databaseType: DatabaseType
    let serverId: String

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("User Access Control")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    Text("User management coming soon...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
            }
        }
    }
}

// MARK: - Helper Components

private struct StatusRow: View {
    let label: String
    let value: String
    var color: Color?

    var body: some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)

            Spacer()

            HStack(spacing: AXSpacing.xs) {
                if let color = color {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }

                Text(value)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextPrimary)
            }
        }
    }
}

// Note: AXLogSource enum cases are now defined in AXAdvancedLogsView.swift
// Including: .mysqlService, .postgresqlService, .redisService, .mongodbService, etc.
