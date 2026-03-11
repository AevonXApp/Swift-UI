//
//  DatabaseExtrasContent.swift
//  AevonX
//
//  Logs, Versions, Optimization, and Access tabs extracted from UnifiedDatabaseDetailView
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

extension UnifiedDatabaseDetailView {

    // MARK: - Logs Tab

    var logsContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("Logs")
                .font(AXTypography.title)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            AXAdvancedLogsView(
                source: logSourceForDatabaseType(databaseType),
                serverId: serverId
            )
            .frame(minHeight: 600)
        }
    }

    func logSourceForDatabaseType(_ type: AevonXCoreBridge.DatabaseType) -> AXLogSource {
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

    // MARK: - Versions Tab

    var versionsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            UnifiedVersionsView(
                title: "\(databaseType.displayName) Versions",
                serviceName: databaseType.displayName,
                currentVersion: viewModel.formattedVersion,
                versions: buildDatabaseVersionItems(),
                isLoading: viewModel.isFetchingVersions,
                serviceIcon: "cylinder.fill",
                accentColor: databaseAccentColor,
                onRefresh: { await viewModel.fetchAvailableVersions() },
                onInstall: { version in
                    if let dbVersion = viewModel.availableVersions.first(where: { $0.version == version }) {
                        viewModel.showInstallConfirmation(version: dbVersion)
                    }
                },
                onSwitch: { version in
                    if let dbVersion = viewModel.availableVersions.first(where: { $0.version == version }) {
                        viewModel.showInstallConfirmation(version: dbVersion)
                    }
                },
                onUninstall: nil,
                installerVM: AXStepInstallerViewModel(steps: []),
                showInstaller: false
            )
        }
        .task {
            if viewModel.availableVersions.isEmpty {
                await viewModel.fetchAvailableVersions()
            }
        }
    }

    private func buildDatabaseVersionItems() -> [VersionItem] {
        viewModel.availableVersions.map { dbVersion in
            let isCurrent = viewModel.formattedVersion.contains(dbVersion.version)
            let badge: String? = {
                if dbVersion.isRecommended { return "Recommended" }
                if dbVersion.isLTS { return "LTS" }
                return nil
            }()
            let badgeColor: Color = dbVersion.isRecommended ? .axSuccess : .axAccentBlue

            return VersionItem(
                version: dbVersion.version,
                isCurrent: isCurrent,
                isInstalled: isCurrent,
                badge: isCurrent ? nil : badge,
                badgeColor: badgeColor
            )
        }
    }

    private var databaseAccentColor: Color {
        switch databaseType {
        case .mysql: return Color(hex: "#4479A1")
        case .postgresql: return Color(hex: "#336791")
        case .redis: return Color(hex: "#DC382D")
        case .mongodb: return Color(hex: "#47A248")
        case .mariadb: return Color(hex: "#003545")
        case .elasticsearch: return Color(hex: "#FEC514")
        default: return .axAccentBlue
        }
    }

    // MARK: - Optimization Tab

    var optimizationContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("Performance Optimization")
                .font(AXTypography.title)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            AXConfigCard(icon: "gauge.with.dots.needle.33percent", title: "Performance Analysis") {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    if let stats = viewModel.performanceStats {
                        AXInfoRow(label: "Total Queries", value: "\(stats.totalQueries)")
                        AXInfoRow(label: "Avg Query Time", value: String(format: "%.2f ms", stats.avgQueryTime))
                        AXInfoRow(label: "Max Query Time", value: String(format: "%.2f ms", stats.maxQueryTime))
                        AXInfoRow(label: "Cache Hit Rate", value: String(format: "%.1f%%", stats.indexUsage * 100))
                    }

                    AXActionButton(label: "Analyze Performance", icon: "chart.line.uptrend.xyaxis", style: .primary, fullWidth: true) {
                        Task { await viewModel.analyzePerformance() }
                    }
                    .disabled(viewModel.isAnalyzingPerformance)
                }
            }

            AXConfigCard(icon: "wand.and.stars", title: "Optimization Presets", iconColor: .axWarning) {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    ForEach(["Web Application", "Data Warehouse", "Development"], id: \.self) { preset in
                        AXActionButton(label: preset, style: .ghost, fullWidth: true) {
                            Task { await viewModel.applyOptimizationPreset(preset) }
                        }
                        .disabled(viewModel.isOperationInProgress)
                    }
                }
            }
        }
    }

    // MARK: - Access Tab

    var accessContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("User Access Control")
                .font(AXTypography.title)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            AXConfigCard(icon: "person.2.fill", title: "Database Users", iconColor: .axAccentBlue) {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    if !viewModel.supportsUserManagement {
                        AXPlaceholder(
                            icon: "person.crop.circle.badge.xmark",
                            title: "Not Supported",
                            subtitle: "\(databaseType.displayName) does not support user management in this panel"
                        )
                    } else if viewModel.isLoadingUsers {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let error = viewModel.userLoadError {
                        Text(error)
                            .font(AXTypography.caption)
                            .foregroundColor(.axError)
                    } else if viewModel.databaseUsers.isEmpty {
                        AXPlaceholder(
                            icon: "person.2",
                            title: "No Users",
                            subtitle: "No database users found"
                        )
                    } else {
                        ForEach(viewModel.databaseUsers, id: \.username) { user in
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.axAccentBlue)
                                Text(user.username)
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextPrimary)
                                Spacer()
                            }
                            .padding(.vertical, AXSpacing.xs)
                        }
                    }

                    AXActionButton(label: "Refresh Users", icon: "arrow.clockwise", style: .primary, fullWidth: true) {
                        Task { await viewModel.loadUsers() }
                    }
                    .disabled(viewModel.isLoadingUsers || !viewModel.supportsUserManagement)
                }
            }
        }
        .task {
            if viewModel.supportsUserManagement {
                await viewModel.loadUsers()
            }
        }
    }
}
