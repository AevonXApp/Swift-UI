//
//  DBTablesSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBTablesSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        HSplitView {
            tableListPanel
                .frame(minWidth: 200, maxWidth: 300)

            if let _ = viewModel.selectedTable {
                tableDetailPanel
            } else {
                tableEmptyState
            }
        }
        .sheet(isPresented: $viewModel.showCreateTable) {
            DBCreateTableView(viewModel: viewModel) // We will extract this soon
        }
    }

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
                        .foregroundColor(viewModel.database.type.brandColor)
                        .frame(width: 24, height: 24)
                        .background(viewModel.database.type.brandColor.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)

            Divider()

            List(selection: Binding(
                get: { viewModel.selectedTable?.name },
                set: { name in
                    if let name = name, let table = viewModel.tables.first(where: { $0.name == name }) {
                        viewModel.selectTable(table)
                    } else {
                        viewModel.deselectTable()
                    }
                }
            )) {
                ForEach(viewModel.filteredTables) { table in
                    tableRow(table)
                        .tag(table.name)
                }
            }
            .listStyle(.plain)
        }
        .background(Color.axBackground)
    }

    private func tableRow(_ table: TableInfo) -> some View {
        HStack {
            Image(systemName: "tablecells")
                .foregroundColor(viewModel.database.type.brandColor)
            Text(table.name)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            Spacer()
            if table.rowCount > 0 {
                Text("\(table.rowCount)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                Task { await viewModel.optimizeTable(table.name) }
            } label: {
                Label("Optimize Table", systemImage: "bolt.badge.a")
            }
            Button {
                Task { await viewModel.analyzeTable(table.name) }
            } label: {
                Label("Analyze Table", systemImage: "magnifyingglass")
            }
            Divider()
            Button(role: .destructive) {
                viewModel.confirmTruncateTable(table.name)
            } label: {
                Label("Truncate Table", systemImage: "xmark.bin")
            }
            Button(role: .destructive) {
                viewModel.confirmDropTable(table.name)
            } label: {
                Label("Drop Table", systemImage: "trash")
            }
        }
    }

    private var tableEmptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "tablecells.badge.ellipsis")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted.opacity(0.5))
            Text("Select a table to view details")
                .font(AXTypography.title3)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }

    private var tableDetailPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(viewModel.selectedTable?.name ?? "")
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Picker("", selection: $viewModel.tableDetailTab) {
                    ForEach(TableDetailTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Spacer()
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)

            Divider()

            // Content
            switch viewModel.tableDetailTab {
            case .structure:
                DBTableStructureView(viewModel: viewModel)
            case .data:
                DBTableDataView(viewModel: viewModel)
            case .indexes:
                DBTableIndexesView(viewModel: viewModel)
            }
        }
        .background(Color.axBackground)
    }
}
