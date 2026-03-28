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
        mainContent
            .modifier(SheetsModifier(
                viewModel: viewModel,
                showEngineManagement: $showEngineManagement,
                engineManagementType: $engineManagementType
            ))
            .overlay { deleteOverlay }
            .task { await viewModel.loadData() }
    }

    // MARK: - Extracted Body Components

    @ViewBuilder
    private var mainContent: some View {
        Group {
            if let db = databaseForDetail {
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
                VStack(spacing: 0) {
                    DatabaseStatsBar(viewModel: viewModel)
                    DatabaseTabSwitcher(activeTabIndex: $viewModel.activeTabIndex, availableDatabaseTypes: viewModel.availableDatabaseTypes)
                    contentArea
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var deleteOverlay: some View {
        if let db = databaseToDelete {
            AXDeleteConfirmation(
                title: L10n.Database.deleteDatabase,
                itemName: db.name,
                warning: L10n.Database.cannotBeUndone,
                onConfirm: {
                    let name = db.name
                    let type = db.type
                    databaseToDelete = nil
                    Task {
                        do {
                            try await viewModel.deleteDatabase(name: name, type: type)
                        } catch {
                            GlobalToastManager.shared.showError("\(L10n.Database.deleteFailed): \(error.localizedDescription)")
                        }
                    }
                },
                onCancel: { databaseToDelete = nil }
            )
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
                            Task {
                                do {
                                    try await viewModel.deleteDatabase(name: db.name, type: db.type)
                                } catch {
                                    GlobalToastManager.shared.showError("\(L10n.Database.deleteFailed): \(error.localizedDescription)")
                                }
                            }
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
                    Task {
                                do {
                                    try await viewModel.deleteDatabase(name: db.name, type: db.type)
                                } catch {
                                    GlobalToastManager.shared.showError("\(L10n.Database.deleteFailed): \(error.localizedDescription)")
                                }
                            }
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

// MARK: - Sheets Modifier

private struct SheetsModifier: ViewModifier {
    @ObservedObject var viewModel: DatabaseManagementViewModel
    @Binding var showEngineManagement: Bool
    @Binding var engineManagementType: DatabaseType?

    func body(content: Content) -> some View {
        content
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
                addUserSheet
            }
            .sheet(isPresented: $viewModel.showEngineDetail) {
                engineDetailSheet
            }
            .sheet(isPresented: $showEngineManagement) {
                engineManagementSheet
            }
    }

    @ViewBuilder
    private var addUserSheet: some View {
        ModernAddUserView(accentColor: viewModel.selectedDatabaseType?.brandColor ?? .axAccentBlue) { username, password, host in
            let type = viewModel.selectedDatabaseType
                ?? viewModel.availableDatabaseTypes.first(where: { $0 == .mysql || $0 == .mariadb || $0 == .postgresql })
                ?? viewModel.availableDatabaseTypes.first
            if let type {
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

    @ViewBuilder
    private var engineDetailSheet: some View {
        if let type = viewModel.selectedDatabaseType {
            UnifiedDatabaseDetailView(
                databaseType: type,
                serverId: viewModel.serverId ?? ""
            )
        }
    }

    @ViewBuilder
    private var engineManagementSheet: some View {
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
}
