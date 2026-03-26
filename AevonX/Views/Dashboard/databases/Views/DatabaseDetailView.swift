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
        case .importSQL:
            DBBackupSection(viewModel: viewModel)
        }
    }

    private func alertForItem(_ item: DatabaseDetailAlert) -> Alert {
        switch item {
        case .confirmDropTable(let name):
            return Alert(
                title: Text(L10n.Database.dropTable),
                message: Text(L10n.Database.confirmDropTable(name)),
                primaryButton: .destructive(Text(L10n.Database.dropTable)) {
                    Task { await viewModel.dropTable(name) }
                },
                secondaryButton: .cancel()
            )
        case .confirmTruncateTable(let name):
            return Alert(
                title: Text(L10n.Database.truncateTable),
                message: Text(L10n.Database.confirmTruncateTable(name)),
                primaryButton: .destructive(Text(L10n.Database.truncate)) {
                    Task { await viewModel.truncateTable(name) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteDatabase:
            // This case might be less relevant here as deletion is usually handled in the main list,
            // but if supported from detail view:
            return Alert(
                title: Text(L10n.Database.deleteDatabase),
                message: Text(L10n.Database.confirmDeleteDatabase(viewModel.database.name)),
                primaryButton: .destructive(Text(L10n.Button.delete)) {
                    // Logic to delete DB and pop back (requires callback or VM handling)
                    // Currently viewModel doesn't have deleteDatabase method exposed but let's keep placeholder.
                },
                secondaryButton: .cancel()
            )
        case .confirmDropColumn(let name):
            return Alert(
                title: Text(L10n.Database.dropColumn),
                message: Text(L10n.Database.confirmDropColumn(name)),
                primaryButton: .destructive(Text(L10n.Database.dropColumn)) {
                    Task { await viewModel.dropColumn(name) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteRow(let index):
            return Alert(
                title: Text(L10n.Database.deleteRowTitle),
                message: Text(L10n.Database.confirmDeleteRow),
                primaryButton: .destructive(Text(L10n.Button.delete)) {
                    Task { await viewModel.deleteRow(at: index) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteSelectedRows:
            return Alert(
                title: Text(L10n.Database.deleteSelectedRows),
                message: Text(L10n.Database.confirmDeleteSelectedRows(viewModel.selectedRows.count)),
                primaryButton: .destructive(Text(L10n.Button.delete)) {
                    Task { await viewModel.deleteSelectedRows() }
                },
                secondaryButton: .cancel()
            )
        case .confirmDeleteBackup(let id):
            return Alert(
                title: Text(L10n.Database.deleteBackup),
                message: Text(L10n.Database.confirmDeleteBackup),
                primaryButton: .destructive(Text(L10n.Button.delete)) {
                    Task { await viewModel.deleteBackup(id) }
                },
                secondaryButton: .cancel()
            )
        case .confirmDropIndex(let name):
            return Alert(
                title: Text(L10n.Database.dropIndex),
                message: Text(L10n.Database.confirmDropIndex(name)),
                primaryButton: .destructive(Text(L10n.Database.dropIndex)) {
                    Task { await viewModel.dropIndex(name) }
                },
                secondaryButton: .cancel()
            )
        case .confirmRestoreBackup(let id):
            return Alert(
                title: Text(L10n.Database.restoreBackup),
                message: Text(L10n.Database.confirmRestoreBackup),
                primaryButton: .destructive(Text(L10n.Database.restore)) {
                    Task { await viewModel.restoreBackup(id) }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
