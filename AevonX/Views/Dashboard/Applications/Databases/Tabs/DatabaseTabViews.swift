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
                Button(action: onReload) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reload Service")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onTest) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Test Configuration")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
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
                        Button("Reset") {
                            editedConfig = dbConfig.rawConfig
                            hasChanges = false
                        }
                        .buttonStyle(.bordered)
                        .disabled(!hasChanges)

                        Spacer()

                        Button("Save Configuration") {
                            Task {
                                await onSave(editedConfig)
                                hasChanges = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
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

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            AXCard {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Database Logs")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    // Simplified placeholder - AXAdvancedLogsView causes infinite layout loops
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.axAccentBlue)
                            Text("Log Source: \(logSourceForDatabaseType(databaseType).displayName)")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                        }

                        Divider()

                        Text("Logs viewer is temporarily disabled to prevent layout issues.")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                            .padding(.vertical, AXSpacing.md)

                        Text("This will be re-enabled with a stable implementation in the next update.")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    .padding(AXSpacing.lg)
                    .frame(minHeight: 300)
                    .background(Color.axSurface.opacity(0.3))
                    .cornerRadius(AXCornerRadius.md)
                }
            }
        }
        .id("\(databaseType.rawValue)-logs") // Stable ID to prevent recreation issues
    }

    private func logSourceForDatabaseType(_ type: DatabaseType) -> AXLogSource {
        switch type {
        case .mysql: return .mysqlService
        case .postgresql: return .postgresqlService
        case .redis: return .redisService
        case .mongodb: return .mongodbService
        case .mariadb: return .mariadbService
        case .cockroachdb: return .cockroachdbService
        case .cassandra: return .cassandraService
        case .elasticsearch: return .elasticsearchService
        default: return .genericService(name: type.displayName, path: "N/A")
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
