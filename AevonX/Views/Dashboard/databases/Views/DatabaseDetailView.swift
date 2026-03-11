//
//  DatabaseDetailView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

public struct DatabaseDetailView: View {
    @StateObject private var viewModel: DatabaseDetailViewModel
    var onBack: () -> Void

    public init(database: DatabaseInfo, serverId: String?, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DatabaseDetailViewModel(database: database, serverId: serverId))
        self.onBack = onBack
    }

    public var body: some View {
        HStack(spacing: 0) {
            DBDetailSidebar(viewModel: viewModel, onBack: onBack)
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
        // Sheets for Modals defined in Subviews or Global to the Detail View
        // While subviews handle their own sheets for Create Table and Import,
        // Add/Edit Row are typically presented over the whole detail view or specifically in Tables section.
        // To be safe and ensure they work regardless of where triggered, we place them here if they are global or if
        // subviews don't have them attached.
        // In our extraction:
        // - DBCreateTableView is attached in DBTablesSection
        // - DBAddColumnView is attached in DBTableStructureView
        // - DBImportSQLView is attached in DBBackupSection
        // - But DBAddRowView & DBEditRowView were in DBTableDataView but NOT attached as a modifier there.
        // So we attach them here or in DBTableDataView.
        // Since DBTableDataView is inside a switch, attaching here ensures they persist but might re-trigger if recreated.
        // Attaching to DBTablesSection might be better but let's do it here as it was in original.
        .sheet(isPresented: $viewModel.showAddRow) {
            DBAddRowView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showEditRow) {
            DBEditRowView(viewModel: viewModel)
        }
    }

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
                message: Text("Are you sure you want to truncate '\(name)'? This will remove all rows but keep the table structure."),
                primaryButton: .destructive(Text("Truncate")) {
                    Task { await viewModel.truncateTable(name) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteDatabase:
            // This case might be less relevant here as deletion is usually handled in the main list,
            // but if supported from detail view:
            return Alert(
                title: Text("Delete Database"),
                message: Text("Are you sure you want to delete database '\(viewModel.database.name)'? This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    // Logic to delete DB and pop back (requires callback or VM handling)
                    // Currently viewModel doesn't have deleteDatabase method exposed but let's keep placeholder.
                },
                secondaryButton: .cancel()
            )
        case .confirmDropColumn(let name):
            return Alert(
                title: Text("Drop Column"),
                message: Text("Are you sure you want to drop column '\(name)'? Data in this column will be lost."),
                primaryButton: .destructive(Text("Drop Column")) {
                    Task { await viewModel.dropColumn(name) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteRow(let index):
            return Alert(
                title: Text("Delete Row"),
                message: Text("Are you sure you want to delete this row?"),
                primaryButton: .destructive(Text("Delete")) {
                    Task { await viewModel.deleteRow(at: index) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteSelectedRows:
            return Alert(
                title: Text("Delete Selected Rows"),
                message: Text("Are you sure you want to delete \(viewModel.selectedRows.count) selected rows?"),
                primaryButton: .destructive(Text("Delete")) {
                    Task { await viewModel.deleteSelectedRows() }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteBackup(let id):
            return Alert(
                title: Text("Delete Backup"),
                message: Text("Are you sure you want to delete this backup file?"),
                primaryButton: .destructive(Text("Delete")) {
                    Task { await viewModel.deleteBackup(id) }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
