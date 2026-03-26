//
//  ModernDatabasesTab.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//
//  Modern database management tab using the new modular architecture
//  Replaces the legacy DatabasesTab.swift with full database control
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Modern Databases Tab

/// Modern database management tab with AI-assisted installation
struct ModernDatabasesTab: View {
    @EnvironmentObject var settings: AppSettingsManager
    @StateObject private var viewModel: DatabaseManagementViewModel
    @State private var showEngineManagement = false
    @State private var engineManagementType: DatabaseType?
    @State private var databaseForDetail: DatabaseInfo?
    @State private var databaseToDelete: DatabaseInfo?
    
    init(server: Server? = nil, serverId: String? = nil, connectionViewModel: ServerConnectionViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: DatabaseManagementViewModel(
            server: server,
            serverId: serverId,
            connectionViewModel: connectionViewModel
        ))
    }
    
    public var body: some View {
        Group {
            if let db = databaseForDetail {
                // Full-page database detail view (replaces the list)
                DatabaseDetailView(
                    database: db,
                    serverId: viewModel.serverId,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            databaseForDetail = nil
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Normal databases list view
                VStack(spacing: 0) {
                    DatabaseStatsBar(viewModel: viewModel)
                    DatabaseTabSwitcher(activeTabIndex: $viewModel.activeTabIndex, availableDatabaseTypes: viewModel.availableDatabaseTypes)
                    contentArea
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $viewModel.showAddDatabase) {
            ModernAddDatabaseView(
                serverId: viewModel.serverId,
                installationStates: viewModel.installationStates,
                onCreated: {
                    Task { await viewModel.loadData(forceRefresh: true) }
                }
            )
        }
        .sheet(isPresented: $viewModel.showAddUser) {
            ModernAddUserView(accentColor: viewModel.selectedDatabaseType?.brandColor ?? .axAccentBlue) { username, password, host in
                if let type = viewModel.selectedDatabaseType {
                    Task {
                        do {
                            try await viewModel.createUser(username: username, password: password, host: host, databaseType: type)
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }

        .sheet(isPresented: $viewModel.showEngineDetail) {
            if let type = viewModel.selectedDatabaseType {
                UnifiedDatabaseDetailView(
                    databaseType: type,
                    serverId: viewModel.serverId ?? ""
                )
            }
        }
        .sheet(isPresented: $showEngineManagement) {
            if let type = engineManagementType {
                UnifiedDatabaseDetailView(
                    databaseType: type,
                    serverId: viewModel.serverId ?? "",
                    onBack: {
                        showEngineManagement = false
                        engineManagementType = nil
                    }
                )
            }
        }

        .overlay {
            if let db = databaseToDelete {
                AXDeleteConfirmation(
                    title: L10n.Database.deleteDatabase,
                    itemName: db.name,
                    warning: L10n.Database.cannotBeUndone,
                    onConfirm: {
                        let name = db.name
                        let type = db.type
                        databaseToDelete = nil
                        Task { try? await viewModel.deleteDatabase(name: name, type: type) }
                    },
                    onCancel: { databaseToDelete = nil }
                )
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading || viewModel.isWaitingForConnection {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if viewModel.activeTabIndex == 0 {
            allDatabasesListView
        } else {
            specificDatabaseTypeView
        }
    }

    private var allDatabasesListView: some View {
        VStack(spacing: 0) {
            DatabaseToolbar(viewModel: viewModel)
            
            if viewModel.allDatabases.isEmpty {
                ScrollView {
                    DatabaseEngineOverview(
                        viewModel: viewModel,
                        onManage: showEngineDetail
                    )
                }
            } else {
                DatabaseListView(
                    viewModel: viewModel,
                    onOpen: { db in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            databaseForDetail = db
                        }
                    },
                    onDelete: { db in
                        if settings.shouldConfirm(for: SettingsKey.confirmDropDBDatabase) {
                            databaseToDelete = db
                        } else {
                            Task { try? await viewModel.deleteDatabase(name: db.name, type: db.type) }
                        }
                    }
                )
            }
        }
    }

    private var specificDatabaseTypeView: some View {
        DatabaseTypeDetailView(
            viewModel: viewModel,
            onManageEngine: showEngineDetail,
            onOpenDatabase: { db in
                withAnimation(.easeInOut(duration: 0.25)) {
                    databaseForDetail = db
                }
            },
            onDeleteDatabase: { db in
                if settings.shouldConfirm(for: SettingsKey.confirmDropDBDatabase) {
                    databaseToDelete = db
                } else {
                    Task { try? await viewModel.deleteDatabase(name: db.name, type: db.type) }
                }
            }
        )
    }

    // MARK: - Navigation Helpers
    
    private func showEngineDetail(for type: DatabaseType) {
        engineManagementType = type
        showEngineManagement = true
    }

    // MARK: - Legacy Loading/Error Views
    
    private var loadingView: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(L10n.Database.loadingDatabases)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axError)
            
            Text(L10n.Database.failedToLoadDatabases)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            Text(message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
            
            Button(L10n.Button.retry) {
                Task {
                    await viewModel.loadData(forceRefresh: true)
                }
            }
            .font(AXTypography.subheadline)
            .foregroundColor(.axAccentBlue)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axAccentBlue.opacity(0.1))
            .cornerRadius(AXCornerRadius.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }
}
