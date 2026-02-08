//
//  DatabaseDetailView.swift
//  AevonX
//
//  Full database detail/management view
//  Tables, structure, data browsing, SQL console, backup
//

import SwiftUI
import AevonXCore
import UniformTypeIdentifiers

// MARK: - Main Database Detail View

struct DatabaseDetailView: View {
    @StateObject private var viewModel: DatabaseDetailViewModel
    let onBack: () -> Void

    init(database: DatabaseInfo, serverId: String?, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DatabaseDetailViewModel(
            database: database,
            serverId: serverId
        ))
        self.onBack = onBack
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebarView
            Divider()
            mainContentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
        .alert(item: $viewModel.activeAlert) { alertItem in
            alertForItem(alertItem)
        }
        .task {
            await viewModel.loadTables()
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: AXSpacing.sm) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(viewModel.database.name)
                        .font(AXTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)

                    Text("\(viewModel.database.type.displayName) \(viewModel.database.version ?? "")")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
            }
            .padding(AXSpacing.lg)

            Divider()

            // Navigation
            VStack(spacing: AXSpacing.xxs) {
                ForEach(DatabaseDetailSection.allCases) { section in
                    sidebarRow(section)
                }
            }
            .padding(AXSpacing.sm)

            Spacer()
        }
        .frame(width: 220)
        .background(Color.axBackground)
    }

    private func sidebarRow(_ section: DatabaseDetailSection) -> some View {
        let isSelected = viewModel.currentSection == section
        return Button {
            viewModel.currentSection = section
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: section.iconName)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                    .frame(width: 20)
                Text(section.rawValue)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)
                Spacer()
                if section == .tables {
                    Text("\(viewModel.tables.count)")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                if section == .activityLog && !viewModel.activityLog.isEmpty {
                    Text("\(viewModel.activityLog.count)")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContentView: some View {
        switch viewModel.currentSection {
        case .overview:
            DBOverviewSection(viewModel: viewModel)
        case .tables:
            DBTablesSection(viewModel: viewModel)
        case .queryConsole:
            DBSQLConsoleSection(viewModel: viewModel)
        case .backup:
            DBBackupSection(viewModel: viewModel)
        case .activityLog:
            DBActivityLogSection(viewModel: viewModel)
        }
    }

    // MARK: - Alert Builder

    private func alertForItem(_ item: DatabaseDetailAlert) -> Alert {
        switch item {
        case .confirmDropTable(let name):
            return Alert(
                title: Text("Drop Table"),
                message: Text("Are you sure you want to drop '\(name)'? This will permanently delete the table and all its data. This action cannot be undone."),
                primaryButton: .destructive(Text("Drop Table")) {
                    Task { await viewModel.dropTable(name) }
                },
                secondaryButton: .cancel()
            )
        case .confirmTruncateTable(let name):
            return Alert(
                title: Text("Truncate Table"),
                message: Text("Are you sure you want to truncate '\(name)'? This will delete all rows but keep the table structure."),
                primaryButton: .destructive(Text("Truncate")) {
                    Task { await viewModel.truncateTable(name) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteDatabase:
            return Alert(
                title: Text("Delete Database"),
                message: Text("Are you sure you want to delete '\(viewModel.database.name)'? This is irreversible."),
                primaryButton: .destructive(Text("Delete")) { },
                secondaryButton: .cancel()
            )
        case .confirmDropColumn(let name):
            return Alert(
                title: Text("Drop Column"),
                message: Text("Are you sure you want to drop column '\(name)'? This will permanently delete the column and all its data."),
                primaryButton: .destructive(Text("Drop Column")) {
                    Task { await viewModel.dropColumn(name) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteRow(let index):
            return Alert(
                title: Text("Delete Row"),
                message: Text("Are you sure you want to delete this row? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { await viewModel.deleteRow(at: index) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteSelectedRows:
            return Alert(
                title: Text("Delete Selected Rows"),
                message: Text("Are you sure you want to delete \(viewModel.selectedRows.count) selected row(s)? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete \(viewModel.selectedRows.count) Rows")) {
                    Task { await viewModel.deleteSelectedRows() }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteBackup(let backupId):
            return Alert(
                title: Text("Delete Backup"),
                message: Text("Are you sure you want to delete this backup? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { await viewModel.deleteBackup(backupId) }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Overview Section

private struct DBOverviewSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                sectionTitle

                statsGrid

                tablesOverview
            }
            .padding(AXSpacing.xl)
        }
    }

    private var sectionTitle: some View {
        Text("Database Overview")
            .font(AXTypography.title2)
            .fontWeight(.bold)
            .foregroundColor(.axTextPrimary)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.lg) {
            overviewStat(icon: "cylinder", label: "Engine", value: viewModel.database.type.displayName, color: .axAccentBlue)
            overviewStat(icon: "internaldrive", label: "Size", value: formatSize(viewModel.database.size), color: .axAccentGreen)
            overviewStat(icon: "tablecells", label: "Tables", value: "\(viewModel.tables.count)", color: .axWarning)
            overviewStat(icon: "bolt.horizontal", label: "Connections", value: "\(viewModel.database.connections)", color: .axInfo)
        }
    }

    private func overviewStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private var tablesOverview: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Tables")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            if viewModel.tables.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Text("No tables found in this database.")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                    Button {
                        viewModel.currentSection = .tables
                        viewModel.showCreateTable = true
                    } label: {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 11))
                            Text("Create Table")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.lg)
            } else {
                ForEach(viewModel.tables.prefix(10)) { table in
                    tableOverviewRow(table)
                }
                if viewModel.tables.count > 10 {
                    Text("and \(viewModel.tables.count - 10) more...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .padding(.leading, AXSpacing.md)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private func tableOverviewRow(_ table: TableInfo) -> some View {
        HStack {
            Image(systemName: "tablecells")
                .font(.system(size: 12))
                .foregroundColor(.axAccentBlue)
                .frame(width: 20)
            Text(table.name)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Text("\(table.rowCount) rows")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Text(viewModel.formatBytes(table.dataSize))
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, AXSpacing.xs)
    }

    private func formatSize(_ mb: Double) -> String {
        if mb >= 1024 { return String(format: "%.1f GB", mb / 1024) }
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Tables Section

private struct DBTablesSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        HStack(spacing: 0) {
            tableListPanel
            if viewModel.selectedTable != nil {
                Divider()
                tableDetailPanel
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $viewModel.showCreateTable) {
            DBCreateTableView(viewModel: viewModel)
        }
    }

    // MARK: - Table List

    private var tableListPanel: some View {
        VStack(spacing: 0) {
            // Search bar + Create button
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
                TextField("Search tables...", text: $viewModel.tableSearchText)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
                    .textFieldStyle(.plain)

                Button { viewModel.showCreateTable = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 24, height: 24)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .padding(AXSpacing.md)

            Divider()

            // Table list
            if viewModel.isLoading && viewModel.tables.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.filteredTables.isEmpty && viewModel.tables.isEmpty {
                // No tables at all — prominent empty state
                Spacer()
                VStack(spacing: AXSpacing.lg) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 36))
                        .foregroundColor(.axTextMuted)
                    Text("No Tables")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text("This database has no tables yet.")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                        .multilineTextAlignment(.center)
                    Button {
                        viewModel.showCreateTable = true
                    } label: {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                            Text("Create Table")
                                .font(AXTypography.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.lg)
                Spacer()
            } else if viewModel.filteredTables.isEmpty {
                // Search returned no results
                Spacer()
                VStack(spacing: AXSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundColor(.axTextMuted)
                    Text("No matching tables")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.filteredTables) { table in
                            tableListRow(table)
                        }
                    }
                }
            }
        }
        .frame(width: viewModel.selectedTable != nil ? 260 : nil)
        .frame(maxWidth: viewModel.selectedTable != nil ? 260 : .infinity)
        .background(Color.axBackground)
    }

    private func tableListRow(_ table: TableInfo) -> some View {
        let isSelected = viewModel.selectedTable?.id == table.id
        return Button {
            viewModel.selectTable(table)
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "tablecells")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(table.name)
                        .font(AXTypography.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    Text("\(table.rowCount) rows")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
                Text(viewModel.formatBytes(table.dataSize))
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { Task { await viewModel.optimizeTable(table.name) } } label: {
                Label("Optimize", systemImage: "bolt")
            }
            Button { Task { await viewModel.analyzeTable(table.name) } } label: {
                Label("Analyze", systemImage: "chart.bar.xaxis")
            }
            Divider()
            Button { viewModel.confirmTruncateTable(table.name) } label: {
                Label("Truncate", systemImage: "trash.slash")
            }
            Button(role: .destructive) { viewModel.confirmDropTable(table.name) } label: {
                Label("Drop Table", systemImage: "trash")
            }
        }
    }

    // MARK: - Table Detail Panel

    private var tableDetailPanel: some View {
        VStack(spacing: 0) {
            tableDetailHeader
            Divider()
            tableDetailContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tableDetailHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button { viewModel.deselectTable() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)

                Text(viewModel.selectedTable?.name ?? "")
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)

                if let engine = viewModel.selectedTable?.engine {
                    Text(engine)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }

                Spacer()

                // Table actions
                Menu {
                    Button { Task { await viewModel.optimizeTable(viewModel.selectedTable?.name ?? "") } } label: {
                        Label("Optimize", systemImage: "bolt")
                    }
                    Button { Task { await viewModel.analyzeTable(viewModel.selectedTable?.name ?? "") } } label: {
                        Label("Analyze", systemImage: "chart.bar.xaxis")
                    }
                    Divider()
                    Button { viewModel.confirmTruncateTable(viewModel.selectedTable?.name ?? "") } label: {
                        Label("Truncate", systemImage: "trash.slash")
                    }
                    Button(role: .destructive) { viewModel.confirmDropTable(viewModel.selectedTable?.name ?? "") } label: {
                        Label("Drop Table", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 30)
            }
            .padding(AXSpacing.lg)

            // Tab bar
            HStack(spacing: 0) {
                ForEach(TableDetailTab.allCases) { tab in
                    tabButton(tab)
                }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.lg)
        }
    }

    private func tabButton(_ tab: TableDetailTab) -> some View {
        let isSelected = viewModel.tableDetailTab == tab
        return Button {
            viewModel.tableDetailTab = tab
            if tab == .data {
                Task { await viewModel.loadTableData() }
            }
        } label: {
            Text(tab.rawValue)
                .font(AXTypography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(Color.axAccentBlue)
                            .frame(height: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tableDetailContent: some View {
        switch viewModel.tableDetailTab {
        case .structure:
            DBTableStructureView(viewModel: viewModel)
        case .data:
            DBTableDataView(viewModel: viewModel)
        case .indexes:
            DBTableIndexesView(viewModel: viewModel)
        }
    }
}

// MARK: - Table Structure View

private struct DBTableStructureView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("\(viewModel.tableStructure?.columns.count ?? 0) columns")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                Spacer()
                Button { viewModel.showAddColumn = true } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Add Column")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)

            Divider()

            if viewModel.isLoading {
                VStack { Spacer(); ProgressView(); Spacer() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let structure = viewModel.tableStructure {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        structureHeader
                        Divider()
                        ForEach(structure.columns) { col in
                            structureRow(col)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.activeAlert = .confirmDropColumn(col.name)
                                    } label: {
                                        Label("Drop Column", systemImage: "trash")
                                    }
                                }
                            Divider()
                        }
                    }
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .padding(AXSpacing.lg)
                }
            } else {
                VStack { Spacer(); Text("No structure data").foregroundColor(.axTextMuted); Spacer() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $viewModel.showAddColumn) {
            DBAddColumnView(viewModel: viewModel)
        }
    }

    private var structureHeader: some View {
        HStack(spacing: 0) {
            headerCell("Column", width: 160)
            headerCell("Type", width: 140)
            headerCell("Null", width: 50)
            headerCell("Key", width: 50)
            headerCell("Default", width: 120)
            headerCell("Extra", width: nil)
        }
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.8))
    }

    private func headerCell(_ title: String, width: CGFloat?) -> some View {
        Text(title)
            .font(AXTypography.caption)
            .fontWeight(.bold)
            .foregroundColor(.axTextSecondary)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)
    }

    private func structureRow(_ col: ColumnInfo) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: AXSpacing.xs) {
                if col.isPrimaryKey {
                    Image(systemName: "key.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.axWarning)
                }
                Text(col.name)
                    .font(AXTypography.subheadline)
                    .fontWeight(col.isPrimaryKey ? .semibold : .regular)
                    .foregroundColor(.axTextPrimary)
            }
            .frame(width: 160, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)

            Text(col.type)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axAccentBlue)
                .frame(width: 140, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            Text(col.isNullable ? "YES" : "NO")
                .font(AXTypography.caption)
                .foregroundColor(col.isNullable ? .axTextMuted : .axWarning)
                .frame(width: 50, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            Text(col.isPrimaryKey ? "PRI" : "")
                .font(AXTypography.caption)
                .foregroundColor(.axWarning)
                .frame(width: 50, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            Text(col.defaultValue ?? "NULL")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(col.defaultValue != nil ? .axTextSecondary : .axTextMuted)
                .frame(width: 120, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            Text(col.extra ?? "")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.sm)

            Spacer()
        }
        .padding(.vertical, AXSpacing.sm)
    }
}

// MARK: - Table Data View

private struct DBTableDataView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Data toolbar
            dataToolbar
            Divider()

            if viewModel.isLoading && viewModel.browseResult == nil {
                Spacer()
                ProgressView()
                Spacer()
            } else if let result = viewModel.browseResult {
                dataTable(result)
                Divider()
                paginationBar
            } else {
                Spacer()
                VStack(spacing: AXSpacing.sm) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 28))
                        .foregroundColor(.axTextMuted)
                    Text("Loading data...")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if viewModel.tableStructure == nil {
                await viewModel.loadTableStructure()
            }
            if viewModel.browseResult == nil {
                await viewModel.loadTableData()
            }
        }
        .sheet(isPresented: $viewModel.showAddRow) {
            DBAddRowView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showEditRow) {
            DBEditRowView(viewModel: viewModel)
        }
    }

    private var dataToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: AXSpacing.md) {
                // Search field
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                    TextField("Search rows...", text: $viewModel.dataSearchText)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextPrimary)
                        .textFieldStyle(.plain)
                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 14, height: 14)
                    }
                    if !viewModel.dataSearchText.isEmpty {
                        Button {
                            Task { await viewModel.clearSearch() }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.axTextMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .frame(maxWidth: 250)

                // Row count
                if let result = viewModel.browseResult {
                    let tableCount = viewModel.selectedTable?.rowCount ?? 0
                    let displayCount = tableCount > 0 ? "\(tableCount) rows" : "\(result.rows.count) rows"
                    Text(displayCount)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                // Sort indicator
                if let sortCol = viewModel.sortColumn {
                    sortIndicator(sortCol)
                }

                Spacer()

                // Delete selected
                if !viewModel.selectedRows.isEmpty {
                    Button {
                        viewModel.activeAlert = .confirmDeleteSelectedRows
                    } label: {
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                            Text("Delete \(viewModel.selectedRows.count)")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axError)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }

                // Add Row
                Button { viewModel.showAddRow = true } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Add Row")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)

                // Page size
                HStack(spacing: AXSpacing.xs) {
                    Text("Rows:")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Picker("", selection: Binding(
                        get: { viewModel.pageSize },
                        set: { newSize in
                            viewModel.pageSize = newSize
                            viewModel.currentPage = 0
                            Task { await viewModel.loadTableData() }
                        }
                    )) {
                        Text("25").tag(25)
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                    }
                    .labelsHidden()
                    .frame(width: 70)
                }

                // Refresh
                Button {
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
        }
        .task(id: viewModel.dataSearchText) {
            guard !viewModel.dataSearchText.isEmpty else { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.searchData()
        }
    }

    private func sortIndicator(_ sortCol: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Text("Sorted by")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Text(sortCol)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axAccentBlue)
            Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                .font(.system(size: 9))
                .foregroundColor(.axAccentBlue)
            Button {
                viewModel.sortColumn = nil
                viewModel.currentPage = 0
                Task { await viewModel.loadTableData() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
        .background(Color.axAccentBlue.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }

    private func dataTable(_ result: QueryResult) -> some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // Column headers
                HStack(spacing: 0) {
                    // Select all checkbox
                    Button {
                        if viewModel.selectedRows.count == result.rows.count {
                            viewModel.deselectAllRows()
                        } else {
                            viewModel.selectAllRows()
                        }
                    } label: {
                        Image(systemName: viewModel.selectedRows.count == result.rows.count && !result.rows.isEmpty
                              ? "checkmark.square.fill" : "square")
                            .font(.system(size: 12))
                            .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32)
                    .padding(.vertical, AXSpacing.sm)

                    ForEach(result.columns, id: \.self) { col in
                        Button {
                            Task { await viewModel.sortBy(col) }
                        } label: {
                            HStack(spacing: AXSpacing.xxs) {
                                Text(col)
                                    .font(AXTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.axTextSecondary)
                                if viewModel.sortColumn == col {
                                    Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 8))
                                        .foregroundColor(.axAccentBlue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 120, alignment: .leading)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.sm)
                    }

                    // Actions header
                    Text("Actions")
                        .font(AXTypography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 70, alignment: .center)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.sm)
                }
                .background(Color.axSurface.opacity(0.8))

                Divider()

                // Data rows
                ForEach(Array(result.rows.enumerated()), id: \.offset) { index, row in
                    dataRow(index: index, row: row, columns: result.columns)
                }
            }
        }
    }

    private func dataRow(index: Int, row: [String?], columns: [String]) -> some View {
        let isSelected = viewModel.selectedRows.contains(index)
        return HStack(spacing: 0) {
            // Checkbox
            Button {
                viewModel.toggleRowSelection(index)
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextMuted)
            }
            .buttonStyle(.plain)
            .frame(width: 32)
            .padding(.vertical, AXSpacing.xs)

            ForEach(Array(row.enumerated()), id: \.offset) { colIdx, value in
                Text(value ?? "NULL")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(value != nil ? .axTextPrimary : .axTextMuted)
                    .lineLimit(1)
                    .frame(minWidth: 120, alignment: .leading)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
            }

            // Row action buttons
            HStack(spacing: AXSpacing.xs) {
                Button {
                    viewModel.startEditingRow(index)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 22, height: 22)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.activeAlert = .confirmDeleteRow(index)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.axError)
                        .frame(width: 22, height: 22)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AXSpacing.sm)
        }
        .background(isSelected ? Color.axAccentBlue.opacity(0.08) : (index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3)))
        .contextMenu {
            Button {
                viewModel.startEditingRow(index)
            } label: {
                Label("Edit Row", systemImage: "pencil")
            }
            Button {
                let values = row.map { $0 ?? "NULL" }.joined(separator: "\t")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(values, forType: .string)
            } label: {
                Label("Copy Row Values", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive) {
                viewModel.activeAlert = .confirmDeleteRow(index)
            } label: {
                Label("Delete Row", systemImage: "trash")
            }
        }
    }

    private var paginationBar: some View {
        HStack {
            Text("Showing \(viewModel.browseResult?.rows.count ?? 0) rows (offset \(viewModel.currentPage * viewModel.pageSize))")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            Spacer()

            HStack(spacing: AXSpacing.sm) {
                Button {
                    viewModel.currentPage = 0
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "chevron.left.2")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasPreviousPage)

                Button {
                    Task { await viewModel.previousPage() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasPreviousPage)

                Text("Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(minWidth: 80)

                Button {
                    Task { await viewModel.nextPage() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasNextPage)

                Button {
                    viewModel.currentPage = max(0, viewModel.totalPages - 1)
                    Task { await viewModel.loadTableData() }
                } label: {
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasNextPage)
            }
            .foregroundColor(.axAccentBlue)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
    }
}

// MARK: - Table Indexes View

private struct DBTableIndexesView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        ScrollView {
            if viewModel.tableIndexes.isEmpty {
                VStack {
                    Spacer(minLength: 100)
                    Text("No indexes found")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    indexHeader
                    Divider()
                    ForEach(viewModel.tableIndexes) { index in
                        indexRow(index)
                        Divider()
                    }
                }
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .padding(AXSpacing.lg)
            }
        }
    }

    private var indexHeader: some View {
        HStack(spacing: 0) {
            Text("Name")
                .frame(width: 200, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text("Columns")
                .frame(width: 250, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text("Unique")
                .frame(width: 70, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)
            Text("Type")
                .padding(.horizontal, AXSpacing.sm)
            Spacer()
        }
        .font(AXTypography.caption)
        .fontWeight(.bold)
        .foregroundColor(.axTextSecondary)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.8))
    }

    private func indexRow(_ index: TableIndex) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: index.isUnique ? "key.fill" : "list.bullet")
                    .font(.system(size: 10))
                    .foregroundColor(index.isUnique ? .axWarning : .axTextMuted)
                Text(index.name)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
            }
            .frame(width: 200, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)

            Text(index.columns.joined(separator: ", "))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axAccentBlue)
                .frame(width: 250, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            Text(index.isUnique ? "YES" : "NO")
                .font(AXTypography.caption)
                .foregroundColor(index.isUnique ? .axSuccess : .axTextMuted)
                .frame(width: 70, alignment: .leading)
                .padding(.horizontal, AXSpacing.sm)

            Text(index.type)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.sm)

            Spacer()
        }
        .padding(.vertical, AXSpacing.sm)
    }
}

// MARK: - SQL Console Section

private struct DBSQLConsoleSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            consoleHeader
            Divider()
            queryEditor
            Divider()
            queryResults
        }
    }

    private var consoleHeader: some View {
        HStack {
            Text("SQL Console")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            Spacer()

            if !viewModel.queryHistory.isEmpty {
                Menu {
                    ForEach(viewModel.queryHistory.prefix(10)) { entry in
                        Button {
                            viewModel.queryText = entry.query
                        } label: {
                            HStack {
                                Image(systemName: entry.success ? "checkmark.circle" : "xmark.circle")
                                Text(entry.query.prefix(60) + (entry.query.count > 60 ? "..." : ""))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                        Text("History")
                            .font(AXTypography.caption)
                    }
                    .foregroundColor(.axAccentBlue)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 90)
            }
        }
        .padding(AXSpacing.lg)
    }

    private var queryEditor: some View {
        VStack(spacing: AXSpacing.sm) {
            TextEditor(text: $viewModel.queryText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 150)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )

            HStack {
                Text("Database: \(viewModel.database.name)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)

                Spacer()

                Button {
                    Task { await viewModel.executeQuery() }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if viewModel.isExecutingQuery {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text("Execute")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(viewModel.queryText.isEmpty || viewModel.isExecutingQuery ? Color.axTextMuted.opacity(0.5) : Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.queryText.isEmpty || viewModel.isExecutingQuery)
            }
        }
        .padding(AXSpacing.lg)
    }

    @ViewBuilder
    private var queryResults: some View {
        if let result = viewModel.queryResult {
            VStack(alignment: .leading, spacing: 0) {
                // Result info bar
                HStack {
                    if result.isSelect {
                        Text("\(result.rows.count) rows returned")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    } else {
                        Text("Query executed successfully")
                            .font(AXTypography.caption)
                            .foregroundColor(.axSuccess)
                    }
                    Spacer()
                    Text(String(format: "%.3fs", result.executionTime))
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)

                if result.isSelect && !result.columns.isEmpty {
                    Divider()
                    queryResultsTable(result)
                }
            }
        } else {
            Spacer()
            VStack(spacing: AXSpacing.sm) {
                Image(systemName: "terminal")
                    .font(.system(size: 28))
                    .foregroundColor(.axTextMuted)
                Text("Enter a query and click Execute")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
        }
    }

    private func queryResultsTable(_ result: QueryResult) -> some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(result.columns, id: \.self) { col in
                        Text(col)
                            .font(AXTypography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextSecondary)
                            .frame(minWidth: 120, alignment: .leading)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.sm)
                    }
                }
                .background(Color.axSurface.opacity(0.8))

                Divider()

                ForEach(Array(result.rows.enumerated()), id: \.offset) { index, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, value in
                            Text(value ?? "NULL")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(value != nil ? .axTextPrimary : .axTextMuted)
                                .lineLimit(1)
                                .frame(minWidth: 120, alignment: .leading)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.xs)
                        }
                    }
                    .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                }
            }
        }
    }
}

// MARK: - Backup Section

private struct DBBackupSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                backupHeader
                createBackupCard
                importSQLCard
                backupList
            }
            .padding(AXSpacing.xl)
        }
        .task {
            await viewModel.loadBackups()
        }
        .sheet(isPresented: $viewModel.showImportSQL) {
            DBImportSQLView(viewModel: viewModel)
        }
    }

    private var backupHeader: some View {
        Text("Backup & Import")
            .font(AXTypography.title2)
            .fontWeight(.bold)
            .foregroundColor(.axTextPrimary)
    }

    private var createBackupCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.axAccentBlue)

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text("Create Backup")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text("Export '\(viewModel.database.name)' to a SQL dump file on the server.")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                Button {
                    Task { await viewModel.createBackup() }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if viewModel.isCreatingBackup {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                        Text(viewModel.isCreatingBackup ? "Creating..." : "Create Backup")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(viewModel.isCreatingBackup ? Color.axTextMuted.opacity(0.5) : Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isCreatingBackup)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private var importSQLCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.axAccentGreen)

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text("Import SQL")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    Text("Import a .sql file or paste SQL content into '\(viewModel.database.name)'.")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                Button { viewModel.showImportSQL = true } label: {
                    Text("Import SQL")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentGreen)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private var backupList: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text("Recent Backups")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)

            if viewModel.backups.isEmpty {
                Text("No backups found on the server.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
                    .padding(AXSpacing.lg)
            } else {
                ForEach(viewModel.backups, id: \.id) { backup in
                    backupRow(backup)
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
    }

    private func backupRow(_ backup: BackupInfo) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 16))
                .foregroundColor(.axAccentBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(URL(fileURLWithPath: backup.id).lastPathComponent)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                Text(backup.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            Text(String(format: "%.1f MB", backup.size))
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)

            // Download
            Button {
                Task { await viewModel.downloadBackup(backup.id) }
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isDownloadingBackup)

            // Delete
            Button {
                viewModel.confirmDeleteBackup(backup.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.axError)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AXSpacing.sm)
    }
}

// MARK: - Create Table View

private struct DBCreateTableView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var tableName = ""
    @State private var columns: [CreateTableColumnDefinition] = [
        CreateTableColumnDefinition(name: "id", type: "INT", length: nil, isNullable: false, isPrimaryKey: true, isAutoIncrement: true)
    ]
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 0) {
            createTableHeader
            Divider()
            createTableContent
            Divider()
            createTableFooter
        }
        .frame(width: 700, height: 550)
        .background(Color.axBackground)
    }

    private var createTableHeader: some View {
        HStack {
            Text("Create Table")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text("in \(viewModel.database.name)")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showCreateTable = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    private var createTableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                tableNameField
                columnsSection
            }
            .padding(AXSpacing.xl)
        }
    }

    private var tableNameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Table Name")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
            TextField("users", text: $tableName)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        }
    }

    private var columnsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Text("Columns")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                Spacer()
                Button { addColumn() } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Add Column")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }

            columnHeaderRow

            ForEach(Array(columns.enumerated()), id: \.element.id) { index, _ in
                columnRow(index: index)
            }
        }
    }

    private var columnHeaderRow: some View {
        HStack(spacing: AXSpacing.sm) {
            Text("Name")
                .frame(width: 130, alignment: .leading)
            Text("Type")
                .frame(width: 100, alignment: .leading)
            Text("Length")
                .frame(width: 60, alignment: .leading)
            Text("PK")
                .frame(width: 28, alignment: .center)
            Text("NN")
                .frame(width: 28, alignment: .center)
            Text("AI")
                .frame(width: 28, alignment: .center)
            Text("UQ")
                .frame(width: 28, alignment: .center)
            Spacer()
        }
        .font(AXTypography.caption2)
        .fontWeight(.bold)
        .foregroundColor(.axTextMuted)
        .padding(.horizontal, AXSpacing.sm)
    }

    private func columnRow(index: Int) -> some View {
        HStack(spacing: AXSpacing.sm) {
            TextField("column", text: $columns[index].name)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .textFieldStyle(.plain)
                .padding(AXSpacing.xs)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .frame(width: 130)

            Picker("", selection: $columns[index].type) {
                ForEach(mysqlColumnTypes, id: \.self) { t in
                    Text(t).tag(t)
                }
            }
            .labelsHidden()
            .frame(width: 100)

            TextField("", text: Binding(
                get: { columns[index].length ?? "" },
                set: { columns[index].length = $0.isEmpty ? nil : $0 }
            ))
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.axTextPrimary)
            .textFieldStyle(.plain)
            .padding(AXSpacing.xs)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            .frame(width: 60)

            Toggle("", isOn: $columns[index].isPrimaryKey)
                .toggleStyle(.checkbox)
                .frame(width: 28)

            Toggle("", isOn: Binding(
                get: { !columns[index].isNullable },
                set: { columns[index].isNullable = !$0 }
            ))
            .toggleStyle(.checkbox)
            .frame(width: 28)

            Toggle("", isOn: $columns[index].isAutoIncrement)
                .toggleStyle(.checkbox)
                .frame(width: 28)

            Toggle("", isOn: $columns[index].isUnique)
                .toggleStyle(.checkbox)
                .frame(width: 28)

            Spacer()

            if columns.count > 1 {
                Button { columns.remove(at: index) } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.axError)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
    }

    private var createTableFooter: some View {
        HStack(spacing: AXSpacing.md) {
            Text("\(columns.count) column\(columns.count == 1 ? "" : "s")")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showCreateTable = false } label: {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
            }
            .buttonStyle(.plain)

            Button {
                isSubmitting = true
                Task {
                    await viewModel.createTable(name: tableName, columns: columns)
                    isSubmitting = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isSubmitting {
                        ProgressView().scaleEffect(0.7).tint(.axBackground)
                    }
                    Text(isSubmitting ? "Creating..." : "Create Table")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(isFormValid && !isSubmitting ? Color.axAccentBlue : Color.axTextMuted.opacity(0.5))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || isSubmitting)
        }
        .padding(AXSpacing.xl)
    }

    private var isFormValid: Bool {
        !tableName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !columns.isEmpty &&
        columns.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func addColumn() {
        columns.append(CreateTableColumnDefinition())
    }

    private var mysqlColumnTypes: [String] {
        ["INT", "BIGINT", "SMALLINT", "TINYINT", "MEDIUMINT",
         "VARCHAR", "CHAR", "TEXT", "MEDIUMTEXT", "LONGTEXT",
         "DECIMAL", "FLOAT", "DOUBLE",
         "DATE", "DATETIME", "TIMESTAMP", "TIME", "YEAR",
         "BOOLEAN", "ENUM", "SET",
         "BLOB", "MEDIUMBLOB", "LONGBLOB",
         "JSON", "BINARY", "VARBINARY"]
    }
}

// MARK: - Add Column View

private struct DBAddColumnView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var column = CreateTableColumnDefinition()
    @State private var afterColumn: String = ""
    @State private var isSubmitting = false

    private var mysqlColumnTypes: [String] {
        ["INT", "BIGINT", "SMALLINT", "TINYINT", "MEDIUMINT",
         "VARCHAR", "CHAR", "TEXT", "MEDIUMTEXT", "LONGTEXT",
         "DECIMAL", "FLOAT", "DOUBLE",
         "DATE", "DATETIME", "TIMESTAMP", "TIME", "YEAR",
         "BOOLEAN", "ENUM", "SET",
         "BLOB", "MEDIUMBLOB", "LONGBLOB",
         "JSON", "BINARY", "VARBINARY"]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Column")
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text("to \(viewModel.selectedTable?.name ?? "")")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
                Spacer()
                Button { viewModel.showAddColumn = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.xl)

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    addColumnNameField
                    addColumnTypeRow
                    addColumnOptionsRow
                    addColumnPositionField
                }
                .padding(AXSpacing.xl)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button { viewModel.showAddColumn = false } label: {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                }
                .buttonStyle(.plain)

                Button {
                    isSubmitting = true
                    Task {
                        await viewModel.addColumn(column, afterColumn: afterColumn.isEmpty ? nil : afterColumn)
                        isSubmitting = false
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        if isSubmitting {
                            ProgressView().scaleEffect(0.7).tint(.axBackground)
                        }
                        Text(isSubmitting ? "Adding..." : "Add Column")
                    }
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.md)
                    .background(!column.name.isEmpty && !isSubmitting ? Color.axAccentBlue : Color.axTextMuted.opacity(0.5))
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(column.name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(AXSpacing.xl)
        }
        .frame(width: 500, height: 420)
        .background(Color.axBackground)
    }

    private var addColumnNameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Column Name")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
            TextField("column_name", text: $column.name)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
        }
    }

    private var addColumnTypeRow: some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Type")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                Picker("", selection: $column.type) {
                    ForEach(mysqlColumnTypes, id: \.self) { t in Text(t).tag(t) }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Length")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                TextField("255", text: Binding(
                    get: { column.length ?? "" },
                    set: { column.length = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
            }
            .frame(width: 100)
        }
    }

    private var addColumnOptionsRow: some View {
        HStack(spacing: AXSpacing.xl) {
            Toggle("Not Null", isOn: Binding(
                get: { !column.isNullable },
                set: { column.isNullable = !$0 }
            ))
            .toggleStyle(.checkbox)

            Toggle("Primary Key", isOn: $column.isPrimaryKey)
                .toggleStyle(.checkbox)

            Toggle("Auto Increment", isOn: $column.isAutoIncrement)
                .toggleStyle(.checkbox)

            Toggle("Unique", isOn: $column.isUnique)
                .toggleStyle(.checkbox)
        }
        .font(AXTypography.subheadline)
        .foregroundColor(.axTextPrimary)
    }

    private var addColumnPositionField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Position (After Column)")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)
            Picker("", selection: $afterColumn) {
                Text("End of table").tag("")
                if let structure = viewModel.tableStructure {
                    ForEach(structure.columns) { col in
                        Text("After \(col.name)").tag(col.name)
                    }
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Add Row View

private struct DBAddRowView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var values: [String: String] = [:]
    @State private var nullFlags: [String: Bool] = [:]
    @State private var isSubmitting = false

    private var columns: [ColumnInfo] {
        viewModel.tableStructure?.columns ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            addRowHeader
            Divider()
            addRowForm
            Divider()
            addRowFooter
        }
        .frame(width: 600, height: 500)
        .background(Color.axBackground)
        .onAppear { initDefaults() }
    }

    private var addRowHeader: some View {
        HStack {
            Text("Add Row")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text("to \(viewModel.selectedTable?.name ?? "")")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showAddRow = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    private var addRowForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                ForEach(columns) { col in
                    addRowField(col)
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private func addRowField(_ col: ColumnInfo) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                HStack(spacing: AXSpacing.xs) {
                    if col.isPrimaryKey {
                        Image(systemName: "key.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.axWarning)
                    }
                    Text(col.name)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                }
                Text(col.type)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                Spacer()
                if col.isNullable {
                    Toggle("NULL", isOn: Binding(
                        get: { nullFlags[col.name] ?? false },
                        set: { nullFlags[col.name] = $0 }
                    ))
                    .toggleStyle(.checkbox)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                }
            }
            if !(nullFlags[col.name] ?? false) {
                TextField(col.extra?.contains("auto_increment") == true ? "(auto)" : "value", text: Binding(
                    get: { values[col.name] ?? "" },
                    set: { values[col.name] = $0 }
                ))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .textFieldStyle(.plain)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                .disabled(col.extra?.contains("auto_increment") == true)
            }
        }
    }

    private var addRowFooter: some View {
        HStack {
            Text("\(columns.count) columns")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showAddRow = false } label: {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
            }
            .buttonStyle(.plain)

            Button {
                isSubmitting = true
                Task {
                    var finalValues: [String: String?] = [:]
                    for col in columns {
                        if col.extra?.contains("auto_increment") == true { continue }
                        if nullFlags[col.name] == true {
                            finalValues[col.name] = nil
                        } else {
                            let v = values[col.name] ?? ""
                            if !v.isEmpty { finalValues[col.name] = v }
                        }
                    }
                    await viewModel.insertRow(finalValues)
                    isSubmitting = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isSubmitting { ProgressView().scaleEffect(0.7).tint(.axBackground) }
                    Text(isSubmitting ? "Inserting..." : "Insert Row")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(isSubmitting ? Color.axTextMuted.opacity(0.5) : Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(AXSpacing.xl)
    }

    private func initDefaults() {
        for col in columns {
            values[col.name] = ""
            nullFlags[col.name] = false
        }
    }
}

// MARK: - Edit Row View

private struct DBEditRowView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var values: [String: String] = [:]
    @State private var nullFlags: [String: Bool] = [:]
    @State private var isSubmitting = false

    private var columns: [ColumnInfo] {
        viewModel.tableStructure?.columns ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            editRowHeader
            Divider()
            editRowForm
            Divider()
            editRowFooter
        }
        .frame(width: 600, height: 500)
        .background(Color.axBackground)
        .onAppear { initFromEditing() }
    }

    private var editRowHeader: some View {
        HStack {
            Text("Edit Row")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text("in \(viewModel.selectedTable?.name ?? "")")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showEditRow = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    private var editRowForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                ForEach(columns) { col in
                    editRowField(col)
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private func editRowField(_ col: ColumnInfo) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                HStack(spacing: AXSpacing.xs) {
                    if col.isPrimaryKey {
                        Image(systemName: "key.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.axWarning)
                    }
                    Text(col.name)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                }
                Text(col.type)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                Spacer()
                if col.isNullable {
                    Toggle("NULL", isOn: Binding(
                        get: { nullFlags[col.name] ?? false },
                        set: { nullFlags[col.name] = $0 }
                    ))
                    .toggleStyle(.checkbox)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                }
            }
            if !(nullFlags[col.name] ?? false) {
                TextField("value", text: Binding(
                    get: { values[col.name] ?? "" },
                    set: { values[col.name] = $0 }
                ))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .textFieldStyle(.plain)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
            }
        }
    }

    private var editRowFooter: some View {
        HStack {
            Spacer()
            Button { viewModel.showEditRow = false } label: {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
            }
            .buttonStyle(.plain)

            Button {
                isSubmitting = true
                Task {
                    // Build PK from original values
                    var pk: [String: String] = [:]
                    let pkCols = columns.filter { $0.isPrimaryKey }
                    for col in pkCols {
                        if let original = viewModel.editingRowValues[col.name], let v = original {
                            pk[col.name] = v
                        }
                    }

                    // Build updated values
                    var updatedValues: [String: String?] = [:]
                    for col in columns {
                        if nullFlags[col.name] == true {
                            updatedValues[col.name] = nil
                        } else {
                            updatedValues[col.name] = values[col.name]
                        }
                    }

                    await viewModel.updateRow(primaryKey: pk, values: updatedValues)
                    isSubmitting = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isSubmitting { ProgressView().scaleEffect(0.7).tint(.axBackground) }
                    Text(isSubmitting ? "Saving..." : "Save Changes")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(isSubmitting ? Color.axTextMuted.opacity(0.5) : Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(AXSpacing.xl)
    }

    private func initFromEditing() {
        for col in columns {
            if let optVal = viewModel.editingRowValues[col.name] {
                if let val = optVal {
                    values[col.name] = val
                    nullFlags[col.name] = false
                } else {
                    values[col.name] = ""
                    nullFlags[col.name] = true
                }
            } else {
                values[col.name] = ""
                nullFlags[col.name] = false
            }
        }
    }
}

// MARK: - Import SQL View

private struct DBImportSQLView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State private var sqlContent = ""
    @State private var selectedFileName: String?
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 0) {
            importHeader
            Divider()
            importContent
            Divider()
            importFooter
        }
        .frame(width: 650, height: 500)
        .background(Color.axBackground)
    }

    private var importHeader: some View {
        HStack {
            Text("Import SQL")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Text("into \(viewModel.database.name)")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showImportSQL = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    private var importContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // File picker
            HStack(spacing: AXSpacing.md) {
                Button {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [UTType(filenameExtension: "sql") ?? .plainText]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        selectedFileName = url.lastPathComponent
                        if let data = try? String(contentsOf: url, encoding: .utf8) {
                            sqlContent = data
                        }
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 12))
                        Text("Choose .sql File")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)

                if let name = selectedFileName {
                    Text(name)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
            }

            Text("Or paste SQL content below:")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            TextEditor(text: $sqlContent)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: .infinity)
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        }
        .padding(AXSpacing.xl)
    }

    private var importFooter: some View {
        HStack {
            Text("\(sqlContent.count) characters")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            Spacer()
            Button { viewModel.showImportSQL = false } label: {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
            }
            .buttonStyle(.plain)

            Button {
                isSubmitting = true
                Task {
                    await viewModel.importSQL(sqlContent)
                    isSubmitting = false
                }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    if isSubmitting { ProgressView().scaleEffect(0.7).tint(.axBackground) }
                    Text(isSubmitting ? "Importing..." : "Import")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(sqlContent.isEmpty || isSubmitting ? Color.axTextMuted.opacity(0.5) : Color.axAccentGreen)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(sqlContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        }
        .padding(AXSpacing.xl)
    }
}

// MARK: - Activity Log Section

private struct DBActivityLogSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            logHeader
            Divider()
            logContent
        }
    }

    private var logHeader: some View {
        HStack {
            Text("Activity Log")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            Text("\(viewModel.activityLog.count) entries")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            Spacer()

            if !viewModel.activityLog.isEmpty {
                Button {
                    viewModel.activityLog.removeAll()
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("Clear")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axError)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.lg)
    }

    @ViewBuilder
    private var logContent: some View {
        if viewModel.activityLog.isEmpty {
            logEmptyState
        } else {
            logList
        }
    }

    private var logEmptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: AXSpacing.md) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 36))
                    .foregroundColor(.axTextMuted)
                Text("No Activity Yet")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text("Actions you perform will be logged here.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var logList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.activityLog) { entry in
                    logRow(entry)
                    Divider()
                }
            }
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .padding(AXSpacing.lg)
        }
    }

    private func logRow(_ entry: ActivityLogEntry) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            // Status icon
            Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(entry.success ? .axSuccess : .axError)
                .frame(width: 20, alignment: .center)
                .padding(.top, 2)

            // Content
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(entry.action)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }

                Text(entry.detail)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(2)

                if let error = entry.errorMessage {
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .lineLimit(3)
                        .padding(.top, AXSpacing.xxxs)
                }
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
    }
}
