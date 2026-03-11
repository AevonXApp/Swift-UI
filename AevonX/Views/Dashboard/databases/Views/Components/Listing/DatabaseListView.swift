//
//  DatabaseListView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DatabaseListView: View {
    @ObservedObject var viewModel: DatabaseManagementViewModel
    let onOpen: (DatabaseInfo) -> Void
    let onDelete: (DatabaseInfo) -> Void
    
    var body: some View {
        Group {
            if viewModel.databaseViewMode == .grid {
                DatabaseGridView(
                    databases: viewModel.filteredDatabases,
                    serverId: viewModel.serverId,
                    onOpen: onOpen,
                    onBackup: performBackup,
                    onDelete: onDelete
                )
            } else {
                DatabaseTableView(
                    databases: viewModel.filteredDatabases,
                    serverId: viewModel.serverId,
                    onOpen: onOpen,
                    onBackup: performBackup,
                    onDelete: onDelete
                )
            }
        }
    }
    
    private func performBackup(for database: DatabaseInfo) {
        Task {
            guard let serverId = viewModel.serverId else { return }
            do {
                let _ = try await DatabaseBackupService.shared.createBackup(
                    database: database.name,
                    type: database.type,
                    serverId: serverId
                )
                GlobalToastManager.shared.showSuccess("Backup created for '\(database.name)'")
            } catch {
                GlobalToastManager.shared.showError("Backup failed: \(error.localizedDescription)")
            }
        }
    }
}
