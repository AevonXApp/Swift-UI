//
//  DatabaseLinkSection.swift
//  AevonX
//
//  Per-site database link management section — uses Core services
//

import SwiftUI
import AevonXCoreBridge

struct DatabaseLinkSection: View {
    let serverId: String
    let domain: String

    @State private var linkedDB: DatabaseLink?
    @State private var dbStats: DatabaseStats?
    @State private var dbName = ""
    @State private var dbUser = ""
    @State private var dbType: DatabaseLink.DatabaseType = .mysql
    @State private var selectedFormat: ConnectionStringFormat = .laravel
    @State private var isLoading = false
    @State private var showConnectionString = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Database Link", icon: "cylinder.fill")

                // Link DB Form
                AXConfigCard(icon: "link.badge.plus", title: "Link Database", subtitle: "Associate a database with this website") {
                    VStack(spacing: AXSpacing.md) {
                        Picker("Database Type", selection: $dbType) {
                            ForEach(DatabaseLink.DatabaseType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: AXSpacing.md) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Database Name")
                                    .font(AXTypography.footnote).foregroundColor(.axTextSecondary)
                                TextField("database_name", text: $dbName)
                                    .textFieldStyle(.roundedBorder)
                                    .font(AXTypography.monoMd)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Username")
                                    .font(AXTypography.footnote).foregroundColor(.axTextSecondary)
                                TextField("db_user", text: $dbUser)
                                    .textFieldStyle(.roundedBorder)
                                    .font(AXTypography.monoMd)
                            }
                        }

                        HStack {
                            Spacer()
                            Button(action: linkDatabase) {
                                Label("Link Database", systemImage: "link")
                                    .font(AXTypography.subheadline).fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(dbName.isEmpty)
                        }
                    }
                }

                // Linked DB Info
                if let db = linkedDB {
                    AXConfigCard(icon: "cylinder.fill", title: "Linked: \(db.databaseName)", subtitle: "\(db.databaseType.rawValue) on \(db.host):\(db.port)") {
                        VStack(spacing: AXSpacing.md) {
                            if let stats = dbStats {
                                HStack(spacing: AXSpacing.xl) {
                                    VStack(spacing: 4) {
                                        Text(stats.sizeFormatted)
                                            .font(AXTypography.title2).fontWeight(.bold)
                                            .foregroundColor(.axAccentBlue)
                                        Text("Size").font(AXTypography.footnote).foregroundColor(.axTextTertiary)
                                    }
                                    VStack(spacing: 4) {
                                        Text("\(stats.tableCount)")
                                            .font(AXTypography.title2).fontWeight(.bold)
                                            .foregroundColor(.axSuccess)
                                        Text("Tables").font(AXTypography.footnote).foregroundColor(.axTextTertiary)
                                    }
                                }

                                Divider()
                            }

                            HStack(spacing: AXSpacing.sm) {
                                Button(action: { Task { await refreshStats() } }) {
                                    Label("Refresh Stats", systemImage: "arrow.clockwise")
                                        .font(AXTypography.footnote)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)

                                Button(action: { showConnectionString.toggle() }) {
                                    Label("Connection String", systemImage: "doc.on.clipboard")
                                        .font(AXTypography.footnote)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                    }
                }

                // Connection String — generated locally, no SSH needed
                if showConnectionString, let db = linkedDB {
                    AXConfigCard(icon: "doc.on.clipboard", title: "Connection Strings", subtitle: "Copy the connection string for your framework") {
                        VStack(spacing: AXSpacing.md) {
                            Picker("Format", selection: $selectedFormat) {
                                ForEach(ConnectionStringFormat.allCases) { fmt in
                                    Text(fmt.rawValue).tag(fmt)
                                }
                            }

                            Text(selectedFormat.generate(link: db))
                                .font(AXTypography.monoMd)
                                .padding(AXSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                                .textSelection(.enabled)
                        }
                    }
                }

                if linkedDB == nil {
                    EmptyStateCard(icon: "cylinder", title: "No Database Linked", message: "Link a database to enable monitoring and connection string generation")
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
    }

    private func linkDatabase() {
        linkedDB = DatabaseLink(
            databaseName: dbName,
            databaseType: dbType,
            username: dbUser.isEmpty ? "root" : dbUser,
            port: dbType.defaultPort
        )
        Task { await refreshStats() }
    }

    private func refreshStats() async {
        guard let db = linkedDB else { return }
        isLoading = true
        defer { isLoading = false }

        // Use DatabaseManagementService from Core to list and find matching DB
        do {
            let dbTypeStr = db.databaseType == .postgresql ? "postgresql" : "mysql"
            let databases = try await DatabaseManagementService.shared.listDatabases(type: dbTypeStr, serverId: serverId)
            if let match = databases.first(where: { $0.name == db.databaseName }) {
                let sizeBytes = Int64(match.size * 1_048_576)
                dbStats = DatabaseStats(
                    databaseName: db.databaseName,
                    sizeBytes: sizeBytes,
                    tableCount: match.tables
                )
            }
        } catch {
            dbStats = nil
        }
    }
}
