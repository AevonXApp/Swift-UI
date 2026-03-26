//
//  InstalledDatabaseView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct InstalledDatabaseView: View {
    let type: DatabaseType
    @ObservedObject var viewModel: DatabaseManagementViewModel
    let onManageEngine: (DatabaseType) -> Void
    let onOpenDatabase: (DatabaseInfo) -> Void
    let onDeleteDatabase: (DatabaseInfo) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with service controls
            HStack(spacing: AXSpacing.md) {
                // Search
                AXSearchBar(text: $viewModel.searchText, placeholder: L10n.Database.searchDatabases)
                    .frame(width: 280)
                
                // View Mode Toggle
                HStack(spacing: 0) {
                    ForEach(DatabaseManagementViewModel.DatabaseViewMode.allCases) { mode in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.databaseViewMode = mode
                            }
                        } label: {
                            Image(systemName: mode == .grid ? "square.grid.2x2.fill" : "list.bullet")
                                .font(AXTypography.subheadline)
                                .foregroundColor(viewModel.databaseViewMode == mode ? .axTextPrimary : .axTextMuted)
                                .frame(width: 32, height: 32)
                                .background(viewModel.databaseViewMode == mode ? Color.axSurfaceHover : Color.clear)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.axSurface.opacity(0.5))
                .cornerRadius(AXCornerRadius.md)
                .padding(.leading, AXSpacing.sm)
                
                Spacer()
                
                // Actions
                HStack(spacing: AXSpacing.sm) {
                    // ℹ️ NOTE: Engine management (Start/Stop/Configuration) has moved to Applications section
                    // This section now focuses only on database-level operations (Create/Delete/Manage)

                    Divider()
                        .frame(height: 24)
                    
                    Button(action: { viewModel.showAddDatabase = true }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "plus")
                            Text(L10n.Database.newDatabase)
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(type.brandColor)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { Task { await viewModel.loadData() } }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                            Text(L10n.Button.refresh)
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)
            
            // Database list
            if viewModel.filteredDatabases.isEmpty {
                 VStack {
                     Spacer()
                     AXEmptyState(
                        icon: "cylinder",
                        title: L10n.Database.noDatabases,
                        description: L10n.Database.noDatabasesFor(type.displayName),
                        actionLabel: L10n.Database.createDatabase,
                        action: { viewModel.showAddDatabase = true }
                     )
                     Spacer()
                 }
            } else {
                DatabaseListView(
                    viewModel: viewModel,
                    onOpen: onOpenDatabase,
                    onDelete: onDeleteDatabase
                )
            }
        }
    }
}
