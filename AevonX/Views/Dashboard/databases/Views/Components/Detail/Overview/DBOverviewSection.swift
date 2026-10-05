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

    @State var appear = false
    @State var quickSQL = ""
    @State var showTableSizeChart = false

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

    var databaseInfoHeader: some View {
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
                    .font(AXTypography.title)
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(viewModel.database.name)
                    .font(AXTypography.title).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)

                HStack(spacing: AXSpacing.md) {
                    // Engine badge
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "gearshape.fill")
                            .font(AXTypography.caption2)
                        Text("\(viewModel.database.type.displayName) \(viewModel.database.version ?? "")")
                    }
                    .font(AXTypography.footnote)
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
                        Text(L10n.Status.connected)
                    }
                    .font(AXTypography.footnote)
                    .foregroundColor(.axSuccess)

                    // Charset
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "character.textbox")
                            .font(AXTypography.caption2)
                        Text(viewModel.database.characterSet ?? "UTF-8")
                    }
                    .font(AXTypography.monoXs).fontWeight(.medium)
                    .foregroundColor(.axTextMuted)

                    if let collation = viewModel.database.collation {
                        Text(collation)
                            .font(AXTypography.monoXs).fontWeight(.medium)
                            .foregroundColor(.axTextMuted.opacity(0.7))
                    }
                }
            }

            Spacer()

            // Quick connect info
            VStack(alignment: .trailing, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(L10n.Database.portLabel(defaultPort))
                        .font(AXTypography.monoXs).fontWeight(.medium)
                        .foregroundColor(.axTextMuted)
                }
                Text(AXFormatter.formatSizeMB(viewModel.database.size))
                    .font(AXTypography.title2).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text(L10n.Database.totalSize)
                    .font(AXTypography.caption)
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

    var heroStatsRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
            AXStatCard(
                icon: "cylinder",
                label: L10n.Engine.engine,
                value: viewModel.database.type.displayName,
                color: .axAccentBlue,
                style: .glass
            )
            AXStatCard(
                icon: "internaldrive",
                label: L10n.Database.size,
                value: AXFormatter.formatSizeMB(viewModel.database.size),
                color: .axAccentGreen,
                style: .glass
            )
            AXStatCard(
                icon: "tablecells",
                label: L10n.Database.tables,
                value: "\(viewModel.tables.count)",
                color: .axWarning,
                style: .glass
            )
            AXStatCard(
                icon: "bolt.horizontal",
                label: L10n.Database.connections,
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

    var secondaryStatsRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
            miniStatCard(
                icon: "arrow.up.arrow.down",
                label: L10n.Database.totalRows,
                value: "\(viewModel.tables.reduce(0) { $0 + Int($1.rowCount) })",
                color: .purple
            )
            miniStatCard(
                icon: "key.fill",
                label: L10n.Database.indexed,
                value: "\(viewModel.tables.filter { $0.engine != nil }.count)",
                color: .mint
            )
            miniStatCard(
                icon: "clock",
                label: L10n.Database.avgRowSize,
                value: viewModel.tables.isEmpty ? "—" : AXFormatter.formatBytes(
                    viewModel.tables.reduce(0) { $0 + $1.dataSize } / Int64(max(viewModel.tables.count, 1))
                ),
                color: .teal
            )
            miniStatCard(
                icon: "chart.bar.fill",
                label: L10n.Database.indexSize,
                value: AXFormatter.formatBytes(viewModel.tables.reduce(0) { $0 + $1.indexSize }),
                color: .indigo
            )
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.07), value: appear)
    }

    func miniStatCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.1))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(AXTypography.subheadline)
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(AXTypography.callout).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                Text(label)
                    .font(AXTypography.caption2)
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

    var quickSQLCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "terminal.fill")
                    .font(AXTypography.caption)
                    .foregroundColor(.purple)
                Text(L10n.Database.quickSQL)
                    .font(AXTypography.caption2).fontWeight(.heavy)
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
                Spacer()
                Text(L10n.Database.cmdEnterToExecute)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted.opacity(0.5))
            }
            HStack(spacing: AXSpacing.sm) {
                TextField(L10n.Database.typeSQLQuery, text: $quickSQL)
                    .font(AXTypography.monoMd)
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
                        .font(AXTypography.caption)
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

    func quickSQLPreset(_ query: String) -> some View {
        Button {
            quickSQL = query
            viewModel.queryText = query
            viewModel.currentSection = .queryConsole
            Task { await viewModel.executeQuery() }
        } label: {
            Text(query)
                .font(AXTypography.monoXxs).fontWeight(.medium)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.axSurface.opacity(0.6))
                .cornerRadius(AXCornerRadius.xs)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Actions

    var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "bolt.fill")
                    .font(AXTypography.caption)
                    .foregroundColor(.axAccentBlue)
                Text(L10n.Database.quickActions)
                    .font(AXTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
            }

            HStack(spacing: AXSpacing.md) {
                quickActionButton(icon: "plus.circle", title: L10n.Database.createTable, color: .axAccentBlue) {
                    viewModel.currentSection = .tables
                    viewModel.showCreateTable = true
                }
                quickActionButton(icon: "terminal", title: L10n.Database.runQuery, color: .axAccentGreen) {
                    viewModel.currentSection = .queryConsole
                }
                quickActionButton(icon: "arrow.down.doc", title: L10n.Database.createBackup, color: .axWarning) {
                    viewModel.currentSection = .backup
                }
                quickActionButton(icon: "tablecells.badge.ellipsis", title: L10n.Database.browseData, color: .axInfo) {
                    if let firstTable = viewModel.tables.first {
                        viewModel.selectTable(firstTable, tab: .data)
                        viewModel.currentSection = .tables
                    }
                }
                quickActionButton(icon: "arrow.up.doc", title: L10n.Database.importSQL, color: .purple) {
                    viewModel.currentSection = .importSQL
                }
                quickActionButton(icon: "clock", title: L10n.Database.activityLog, color: .axTextSecondary) {
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

    func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
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


    private var defaultPort: String {
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

    // Server info, connection details, table size breakdown,
    // tables card → DBOverviewSection+Cards.swift
}
