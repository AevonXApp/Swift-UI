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
import AevonXCore

// MARK: - Modern Databases Tab

/// Modern database management tab with AI-assisted installation
struct ModernDatabasesTab: View {
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
                    Task { await viewModel.loadData() }
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
        .sheet(isPresented: $viewModel.showInstallation) {
            if let type = viewModel.databaseTypeForInstallation, let serverId = viewModel.serverId {
                AIInstallationView(
                    databaseType: type,
                    serverId: serverId,
                    onSuccess: {
                        Task {
                            await viewModel.loadData()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showEngineDetail) {
            if let type = viewModel.selectedDatabaseType {
                DatabaseEngineDetailView(
                    databaseType: type,
                    serverId: viewModel.serverId
                )
            }
        }
        .sheet(isPresented: $showEngineManagement) {
            if let type = engineManagementType {
                DatabaseEngineManagementView(
                    databaseType: type,
                    serverId: viewModel.serverId,
                    onBack: {
                        showEngineManagement = false
                        engineManagementType = nil
                    }
                )
                .frame(minWidth: 900, minHeight: 600)
            }
        }
        .sheet(isPresented: $viewModel.showErrorResolution) {
            if let context = viewModel.errorResolutionContext {
                ErrorResolutionView(
                    databaseType: context.databaseType,
                    serverId: context.serverId,
                    erroredStep: context.step,
                    errorLog: context.log
                )
            }
        }
        .alert(
            "Delete Database",
            isPresented: Binding<Bool>(
                get: { databaseToDelete != nil },
                set: { if !$0 { databaseToDelete = nil } }
            ),
            presenting: databaseToDelete
        ) { db in
            Button("Cancel", role: .cancel) { databaseToDelete = nil }
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deleteDatabase(name: db.name, type: db.type)
                }
            }
        } message: { db in
            Text("Are you sure you want to delete '\(db.name)'? This action cannot be undone.")
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading {
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
                DatabaseEngineOverview(
                    viewModel: viewModel,
                    onManage: showEngineDetail
                )
            } else {
                DatabaseListView(
                    viewModel: viewModel,
                    onOpen: { db in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            databaseForDetail = db
                        }
                    },
                    onDelete: { db in
                        databaseToDelete = db
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
                databaseToDelete = db
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
            
            Text("Loading databases...")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.axError)
            
            Text("Failed to Load Databases")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            Text(message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.loadData()
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
