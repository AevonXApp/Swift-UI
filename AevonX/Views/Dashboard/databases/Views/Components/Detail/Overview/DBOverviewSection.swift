//
//  DBOverviewSection.swift
//  AevonX
//
//  Premium database overview with glass stat cards,
//  server info, connection details, table size breakdown,
//  quick SQL input, and enhanced table list.
//

import SwiftUI
import AevonXCoreBridge

struct DBOverviewSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    @State private var appear = false
    @State private var quickSQL = ""
    @State private var showTableSizeChart = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                databaseInfoHeader
                heroStatsRow
                secondaryStatsRow
                quickSQLCard
                quickActionsCard
                serverInfoCard
                connectionDetailsCard
                tableSizeBreakdownCard
                tablesCard
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5)) { appear = true }
        }
    }

    // MARK: - Database Info Header

    private var databaseInfoHeader: some View {
        HStack(spacing: AXSpacing.lg) {
            // Large DB icon
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Color.axAccentBlue.opacity(0.2), Color.axAccentBlue.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1)
                    )
                Image(systemName: "cylinder.split.1x2.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(viewModel.database.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                HStack(spacing: AXSpacing.md) {
                    // Engine badge
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 9))
                        Text("\(viewModel.database.type.displayName) \(viewModel.database.version ?? "")")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 3)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)

                    // Status
                    HStack(spacing: AXSpacing.xxs) {
                        Circle()
                            .fill(Color.axSuccess)
                            .frame(width: 6, height: 6)
                        Text("Connected")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axSuccess)

                    // Charset
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "character.textbox")
                            .font(.system(size: 9))
                        Text(viewModel.database.characterSet ?? "UTF-8")
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextMuted)

                    if let collation = viewModel.database.collation {
                        Text(collation)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.axTextMuted.opacity(0.7))
                    }
                }
            }

            Spacer()

            // Quick connect info
            VStack(alignment: .trailing, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.xs) {
                    Text("Port 3306")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                }
                Text(AXFormatter.formatSizeMB(viewModel.database.size))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                Text("Total Size")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }
        }
        .padding(AXSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [Color.axGlassBorder, Color.axBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5), value: appear)
    }

    // MARK: - Hero Stats

    private var heroStatsRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
            AXStatCard(
                icon: "cylinder",
                label: "Engine",
                value: viewModel.database.type.displayName,
                color: .axAccentBlue,
                style: .glass
            )
            AXStatCard(
                icon: "internaldrive",
                label: "Size",
                value: AXFormatter.formatSizeMB(viewModel.database.size),
                color: .axAccentGreen,
                style: .glass
            )
            AXStatCard(
                icon: "tablecells",
                label: "Tables",
                value: "\(viewModel.tables.count)",
                color: .axWarning,
                style: .glass
            )
            AXStatCard(
                icon: "bolt.horizontal",
                label: "Connections",
                value: "\(viewModel.database.connections)",
                color: .axInfo,
                style: .glass
            )
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.05), value: appear)
    }

    // MARK: - Secondary Stats Row (NEW)

    private var secondaryStatsRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
            miniStatCard(
                icon: "arrow.up.arrow.down",
                label: "Total Rows",
                value: "\(viewModel.tables.reduce(0) { $0 + Int($1.rowCount) })",
                color: .purple
            )
            miniStatCard(
                icon: "key.fill",
                label: "Indexed",
                value: "\(viewModel.tables.filter { $0.engine != nil }.count)",
                color: .mint
            )
            miniStatCard(
                icon: "clock",
                label: "Avg Row Size",
                value: viewModel.tables.isEmpty ? "—" : AXFormatter.formatBytes(
                    viewModel.tables.reduce(0) { $0 + $1.dataSize } / Int64(max(viewModel.tables.count, 1))
                ),
                color: .teal
            )
            miniStatCard(
                icon: "chart.bar.fill",
                label: "Index Size",
                value: AXFormatter.formatBytes(viewModel.tables.reduce(0) { $0 + $1.indexSize }),
                color: .indigo
            )
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.07), value: appear)
    }

    private func miniStatCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.1))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.4))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Quick SQL Card (NEW)

    private var quickSQLCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.purple)
                Text("QUICK SQL")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
                Spacer()
                Text("⌘+Enter to execute")
                    .font(.system(size: 9))
                    .foregroundColor(.axTextMuted.opacity(0.5))
            }
            HStack(spacing: AXSpacing.sm) {
                TextField("Type SQL query...", text: $quickSQL)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !quickSQL.isEmpty {
                            viewModel.queryText = quickSQL
                            viewModel.currentSection = .queryConsole
                            Task { await viewModel.executeQuery() }
                        }
                    }

                Button {
                    if !quickSQL.isEmpty {
                        viewModel.queryText = quickSQL
                        viewModel.currentSection = .queryConsole
                        Task { await viewModel.executeQuery() }
                    }
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(quickSQL.isEmpty ? Color.axTextMuted.opacity(0.3) : Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(quickSQL.isEmpty)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface.opacity(0.5))
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder.opacity(0.3), lineWidth: 1)
            )

            // Quick presets
            HStack(spacing: AXSpacing.xs) {
                quickSQLPreset("SHOW TABLES")
                quickSQLPreset("SHOW DATABASES")
                quickSQLPreset("SHOW PROCESSLIST")
                quickSQLPreset("SHOW STATUS")
                quickSQLPreset("SHOW VARIABLES")
            }
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.08), value: appear)
    }

    private func quickSQLPreset(_ query: String) -> some View {
        Button {
            quickSQL = query
            viewModel.queryText = query
            viewModel.currentSection = .queryConsole
            Task { await viewModel.executeQuery() }
        } label: {
            Text(query)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.axSurface.opacity(0.6))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Actions

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "bolt.fill")
                    .font(AXTypography.caption)
                    .foregroundColor(.axAccentBlue)
                Text("QUICK ACTIONS")
                    .font(AXTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
            }

            HStack(spacing: AXSpacing.md) {
                quickActionButton(icon: "plus.circle", title: "Create Table", color: .axAccentBlue) {
                    viewModel.currentSection = .tables
                    viewModel.showCreateTable = true
                }
                quickActionButton(icon: "terminal", title: "Run Query", color: .axAccentGreen) {
                    viewModel.currentSection = .queryConsole
                }
                quickActionButton(icon: "arrow.down.doc", title: "Create Backup", color: .axWarning) {
                    viewModel.currentSection = .backup
                }
                quickActionButton(icon: "tablecells.badge.ellipsis", title: "Browse Data", color: .axInfo) {
                    if let firstTable = viewModel.tables.first {
                        viewModel.selectedTable = firstTable
                        viewModel.currentSection = .tables
                    }
                }
                quickActionButton(icon: "arrow.up.doc", title: "Import SQL", color: .purple) {
                    viewModel.currentSection = .importSQL
                }
                quickActionButton(icon: "clock", title: "Activity Log", color: .axTextSecondary) {
                    viewModel.currentSection = .activityLog
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [Color.axGlassBorder, Color.axBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.1), value: appear)
    }

    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(AXTypography.headline)
                        .foregroundColor(color)
                }
                Text(title)
                    .font(AXTypography.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axSurface.opacity(0.4))
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Server Info Card (NEW)

    private var serverInfoCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "server.rack")
                    .font(.system(size: 10))
                    .foregroundColor(.teal)
                Text("SERVER INFO")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    var info = "Database: \(viewModel.database.name)\n"
                    info += "Engine: \(viewModel.database.type.displayName) \(viewModel.database.version ?? "")\n"
                    info += "Charset: \(viewModel.database.characterSet ?? "UTF-8")\n"
                    info += "Collation: \(viewModel.database.collation ?? "N/A")\n"
                    info += "Size: \(AXFormatter.formatSizeMB(viewModel.database.size))\n"
                    info += "Tables: \(viewModel.tables.count)\n"
                    info += "Connections: \(viewModel.database.connections)"
                    NSPasteboard.general.setString(info, forType: .string)
                    GlobalToastManager.shared.showSuccess("Server info copied")
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 8))
                        Text("Copy")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.sm) {
                serverInfoRow(label: "Engine", value: viewModel.database.type.displayName, icon: "gearshape")
                serverInfoRow(label: "Version", value: viewModel.database.version ?? "N/A", icon: "tag")
                serverInfoRow(label: "Charset", value: viewModel.database.characterSet ?? "UTF-8", icon: "character")
                serverInfoRow(label: "Collation", value: viewModel.database.collation ?? "N/A", icon: "text.justify")
                serverInfoRow(label: "Data Size", value: AXFormatter.formatBytes(viewModel.tables.reduce(0) { $0 + $1.dataSize }), icon: "doc")
                serverInfoRow(label: "Index Size", value: AXFormatter.formatBytes(viewModel.tables.reduce(0) { $0 + $1.indexSize }), icon: "list.number")
                serverInfoRow(label: "Total Rows", value: "\(viewModel.tables.reduce(0) { $0 + Int($1.rowCount) })", icon: "number")
                serverInfoRow(label: "Tables", value: "\(viewModel.tables.count)", icon: "tablecells")
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.12), value: appear)
    }

    private func serverInfoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(.axTextMuted)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.axTextMuted)
                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axSurface.opacity(0.4))
        .cornerRadius(AXCornerRadius.sm)
    }

    // MARK: - Connection Details Card (NEW)

    private var connectionDetailsCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "network")
                    .font(.system(size: 10))
                    .foregroundColor(.indigo)
                Text("CONNECTION")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
                Spacer()
                // Connection status indicator
                HStack(spacing: AXSpacing.xxs) {
                    Circle()
                        .fill(Color.axSuccess)
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.axSuccess)
                }
            }

            HStack(spacing: AXSpacing.md) {
                connectionField(label: "Host", value: "localhost", icon: "desktopcomputer")
                connectionField(label: "Port", value: portForEngine(), icon: "number")
                connectionField(label: "User", value: "root", icon: "person")
                connectionField(label: "Database", value: viewModel.database.name, icon: "cylinder")
            }

            // Connection string
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Connection String")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.axTextMuted)
                HStack {
                    Text(connectionString())
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(connectionString(), forType: .string)
                        GlobalToastManager.shared.showSuccess("Connection string copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 9))
                            .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axSurface.opacity(0.6))
                .cornerRadius(AXCornerRadius.sm)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.14), value: appear)
    }

    private func connectionField(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(.axTextMuted)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.axTextMuted)
            }
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AXSpacing.sm)
        .background(Color.axSurface.opacity(0.4))
        .cornerRadius(AXCornerRadius.sm)
    }

    private func portForEngine() -> String {
        switch viewModel.database.type {
        case .mysql, .mariadb: return "3306"
        case .postgresql: return "5432"
        case .redis: return "6379"
        case .mongodb: return "27017"
        case .cassandra: return "9042"
        case .cockroachdb: return "26257"
        case .elasticsearch: return "9200"
        default: return "3306"
        }
    }

    private func connectionString() -> String {
        let port = portForEngine()
        switch viewModel.database.type {
        case .mysql, .mariadb:
            return "mysql://root@localhost:\(port)/\(viewModel.database.name)"
        case .postgresql:
            return "postgresql://root@localhost:\(port)/\(viewModel.database.name)"
        case .redis:
            return "redis://localhost:\(port)"
        case .mongodb:
            return "mongodb://localhost:\(port)/\(viewModel.database.name)"
        default:
            return "\(viewModel.database.type.rawValue)://localhost:\(port)/\(viewModel.database.name)"
        }
    }

    // MARK: - Table Size Breakdown Card (NEW)

    private var tableSizeBreakdownCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                Text("TABLE SIZE BREAKDOWN")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
                Spacer()
                Text("\(viewModel.tables.count) tables")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.axTextMuted)
            }

            if viewModel.tables.isEmpty {
                Text("No tables to analyze")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.lg)
            } else {
                let sortedTables = viewModel.tables.sorted { ($0.dataSize + $0.indexSize) > ($1.dataSize + $1.indexSize) }
                let totalSize = max(sortedTables.reduce(0) { $0 + $1.dataSize + $1.indexSize }, 1)
                let colors: [Color] = [.axAccentBlue, .axAccentGreen, .axWarning, .purple, .mint, .indigo, .teal, .orange, .pink, .cyan]

                // Bar chart
                VStack(spacing: AXSpacing.xs) {
                    ForEach(Array(sortedTables.prefix(8).enumerated()), id: \.element.name) { index, table in
                        let size = table.dataSize + table.indexSize
                        let pct = Double(size) / Double(totalSize)
                        let color = colors[index % colors.count]

                        HStack(spacing: AXSpacing.sm) {
                            Text(table.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.axTextPrimary)
                                .frame(width: 120, alignment: .leading)
                                .lineLimit(1)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.axSurface.opacity(0.3))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: [color, color.opacity(0.6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(geo.size.width * pct, 4))
                                }
                            }
                            .frame(height: 14)

                            Text(AXFormatter.formatBytes(size))
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.axTextMuted)
                                .frame(width: 60, alignment: .trailing)

                            Text(String(format: "%.1f%%", pct * 100))
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(color)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }

                    if sortedTables.count > 8 {
                        Text("+ \(sortedTables.count - 8) more tables")
                            .font(.system(size: 9))
                            .foregroundColor(.axTextMuted)
                            .padding(.top, AXSpacing.xxs)
                    }
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.16), value: appear)
    }

    // MARK: - Tables Card

    private var tablesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "tablecells")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                    Text("Tables")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    if !viewModel.tables.isEmpty {
                        Text("\(viewModel.tables.count)")
                            .font(AXTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.full)
                    }
                }

                Spacer()

                Button {
                    viewModel.currentSection = .tables
                    viewModel.showCreateTable = true
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(AXTypography.caption2)
                        Text("New Table")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)

            Divider().background(Color.axBorder)

            // Table rows
            if viewModel.tables.isEmpty {
                emptyTablesState
            } else {
                // Column headers
                tableColumnHeaders
                Divider().background(Color.axBorder.opacity(0.5))

                ForEach(Array(viewModel.tables.enumerated()), id: \.element.id) { index, table in
                    tableRow(table, index: index)
                    if index < viewModel.tables.count - 1 {
                        Divider().background(Color.axBorder.opacity(0.3))
                    }
                }
            }
        }
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.18), value: appear)
    }

    private var tableColumnHeaders: some View {
        HStack(spacing: 0) {
            Text("Name")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Engine")
                .frame(width: 70, alignment: .center)
            Text("Rows")
                .frame(width: 70, alignment: .trailing)
            Text("Data")
                .frame(width: 70, alignment: .trailing)
            Text("Index")
                .frame(width: 70, alignment: .trailing)
        }
        .font(AXTypography.caption2)
        .fontWeight(.semibold)
        .foregroundColor(.axTextMuted)
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.6))
    }

    private func tableRow(_ table: TableInfo, index: Int) -> some View {
        VStack(spacing: 0) {
            Button {
                viewModel.selectedTable = table
                viewModel.currentSection = .tables
            } label: {
                HStack(spacing: 0) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "tablecells")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axAccentBlue)
                            .frame(width: 18)
                        Text(table.name)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(table.engine ?? "—")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 70, alignment: .center)

                    Text("\(table.rowCount)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 70, alignment: .trailing)

                    Text(AXFormatter.formatBytes(table.dataSize))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 70, alignment: .trailing)

                    Text(AXFormatter.formatBytes(table.indexSize))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.axTextMuted.opacity(0.7))
                        .frame(width: 70, alignment: .trailing)

                    // Table row actions — AXActionMenu
                    AXActionMenu(sections: [
                        AXMenuSection("Info", items: [
                            AXMenuItem("Copy Table Name", icon: "doc.on.doc", color: .axAccentBlue) {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(table.name, forType: .string)
                                GlobalToastManager.shared.showSuccess("Table name copied")
                            },
                            AXMenuItem("Copy SELECT Query", icon: "chevron.left.forwardslash.chevron.right", color: .cyan) {
                                let selectSQL = "SELECT * FROM `\(table.name)` LIMIT 100"
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(selectSQL, forType: .string)
                                GlobalToastManager.shared.showSuccess("SELECT query copied")
                            },
                        ]),
                        AXMenuSection("Navigate", items: [
                            AXMenuItem("Browse Data", icon: "tablecells", color: .mint) {
                                viewModel.selectedTable = table
                                viewModel.currentSection = .tables
                            },
                            AXMenuItem("Count Rows", icon: "number", color: .indigo) {
                                viewModel.queryText = "SELECT COUNT(*) as total FROM `\(table.name)`"
                                viewModel.currentSection = .queryConsole
                                Task { await viewModel.executeQuery() }
                            },
                            AXMenuItem("Describe Table", icon: "info.circle", color: .axAccentGreen) {
                                viewModel.queryText = "DESCRIBE `\(table.name)`"
                                viewModel.currentSection = .queryConsole
                                Task { await viewModel.executeQuery() }
                            },
                        ]),
                        AXMenuSection("Maintenance", items: [
                            AXMenuItem("Optimize Table", icon: "wand.and.stars", color: .orange) {
                                viewModel.queryText = "OPTIMIZE TABLE `\(table.name)`"
                                viewModel.currentSection = .queryConsole
                                Task { await viewModel.executeQuery() }
                            },
                            AXMenuItem("Check Table", icon: "checkmark.shield", color: .axSuccess) {
                                viewModel.queryText = "CHECK TABLE `\(table.name)`"
                                viewModel.currentSection = .queryConsole
                                Task { await viewModel.executeQuery() }
                            },
                        ]),
                        AXMenuSection(items: [
                            AXMenuItem("Drop Table", icon: "trash", isDestructive: true) {
                                viewModel.selectedTable = table
                                viewModel.activeAlert = .confirmDropTable(table.name)
                            },
                        ]),
                    ], triggerIcon: "ellipsis", triggerSize: 22)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm + 2)
                .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyTablesState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundColor(.axTextMuted)
            Text("No tables yet")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Button {
                viewModel.currentSection = .tables
                viewModel.showCreateTable = true
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(AXTypography.caption)
                    Text("Create First Table")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.xxl)
    }
}
