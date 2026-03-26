//
//  DatabaseEngineOverview.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DatabaseEngineOverview: View {
    @ObservedObject var viewModel: DatabaseManagementViewModel
    let onManage: (DatabaseType) -> Void
    
    var body: some View {
        VStack(spacing: AXSpacing.xxxl) {
            // Hero Empty State
            if viewModel.installedDatabaseTypesCount == 0 {
                // No engines installed - guide user to Applications section
                VStack(spacing: AXSpacing.xl) {
                    AXEmptyState(
                        icon: "cylinder.split.1x2",
                        title: L10n.Database.noEnginesInstalled,
                        description: L10n.Database.noEnginesDescription,
                        actionLabel: nil,
                        action: nil
                    )
                }
                .padding(.top, AXSpacing.xl)
            } else {
                // Has engines but no databases
                AXEmptyState(
                    icon: "cylinder.split.1x2",
                    title: L10n.Database.noDatabasesFound,
                    description: L10n.Database.noDatabasesDescription,
                    actionLabel: L10n.Database.createFirstDatabase,
                    action: { viewModel.showAddDatabase = true }
                )
                .padding(.top, AXSpacing.xl)
            }
        }
    }
}
