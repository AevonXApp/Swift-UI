//
//  DatabaseTypeDetailView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DatabaseTypeDetailView: View {
    @ObservedObject var viewModel: DatabaseManagementViewModel
    let onManageEngine: (DatabaseType) -> Void
    let onOpenDatabase: (DatabaseInfo) -> Void
    let onDeleteDatabase: (DatabaseInfo) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if let selectedType = viewModel.selectedDatabaseType {
                if let state = viewModel.installationState(for: selectedType) {
                    if state.isInstalled {
                        InstalledDatabaseView(
                            type: selectedType,
                            viewModel: viewModel,
                            onManageEngine: onManageEngine,
                            onOpenDatabase: onOpenDatabase,
                            onDeleteDatabase: onDeleteDatabase
                        )
                    } else {
                        NotInstalledView(type: selectedType, viewModel: viewModel)
                    }
                } else {
                    NotInstalledView(type: selectedType, viewModel: viewModel)
                }
            }
        }
    }
}
