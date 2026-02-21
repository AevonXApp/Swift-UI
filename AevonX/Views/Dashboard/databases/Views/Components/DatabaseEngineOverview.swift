//
//  DatabaseEngineOverview.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

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
                        title: "No Database Engines Installed",
                        description: "Go to the Applications tab to install database engines like MySQL, PostgreSQL, or Redis. Installed engines will appear here automatically.",
                        actionLabel: nil,
                        action: nil
                    )
                }
                .padding(.top, AXSpacing.xl)
            } else {
                // Has engines but no databases
                AXEmptyState(
                    icon: "cylinder.split.1x2",
                    title: "No Databases Found",
                    description: "You have database engines installed but haven't created any databases yet. Create your first database to get started.",
                    actionLabel: "Create First Database",
                    action: { viewModel.showAddDatabase = true }
                )
                .padding(.top, AXSpacing.xl)
            }
        }
    }
}
