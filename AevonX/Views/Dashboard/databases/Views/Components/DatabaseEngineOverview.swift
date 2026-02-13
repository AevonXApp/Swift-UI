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
                        description: "To create databases, you first need to install a database engine like MySQL, PostgreSQL, or Redis.",
                        actionLabel: nil,
                        action: nil
                    )

                    // Guide to Applications section
                    VStack(alignment: .leading, spacing: AXSpacing.md) {
                        HStack(spacing: AXSpacing.md) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.axAccentBlue)

                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                Text("Database engines are managed in Applications")
                                    .font(AXTypography.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axTextPrimary)

                                Text("Navigate to the Applications tab to install and manage database engines (MySQL, PostgreSQL, Redis, etc.)")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextSecondary)
                            }
                        }
                        .padding(AXSpacing.lg)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AXSpacing.xl)
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
