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
            AXEmptyState(
                icon: "cylinder.split.1x2",
                title: "No Databases Found",
                description: "You haven't created any databases on this server yet. Get started by installing an engine or creating a database.",
                actionLabel: viewModel.installedDatabaseTypesCount > 0 ? "Create First Database" : nil,
                action: { viewModel.showAddDatabase = true }
            )
            .padding(.top, AXSpacing.xl)

            // Available Engines Section
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                HStack {
                    Text("Available Database Engines")
                        .font(AXTypography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    
                    Spacer()
                    
                    Text("\(viewModel.installedDatabaseTypesCount) Installed")
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentGreen)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xxs)
                        .background(Color.axAccentGreen.opacity(0.1))
                        .cornerRadius(AXCornerRadius.full)
                }
                .padding(.horizontal, AXSpacing.xl)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AXSpacing.lg) {
                        ForEach(DatabaseType.allCases) { type in
                            DatabaseEngineInstallCard(type: type, viewModel: viewModel, onManage: onManage)
                        }
                    }
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.bottom, AXSpacing.xl)
                }
            }
        }
    }
}
