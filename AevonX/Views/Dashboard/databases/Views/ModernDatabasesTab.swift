//
//  ModernDatabasesTab.swift
//  AevonX
//
//  Modern database management tab using the new modular architecture
//  Replaces the legacy DatabasesTab.swift with full database control
//

import SwiftUI
import AevonXCore

// MARK: - Modern Databases Tab

/// Modern database management tab with AI-assisted installation
public struct ModernDatabasesTab: View {
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
                    statsBar
                    tabSwitcher
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
            ModernAddUserView { username, password, host in
                Task {
                    try? await viewModel.createUser(
                        username: username,
                        password: password,
                        host: host,
                        databaseType: .mysql // Default to MySQL for now
                    )
                }
            }
        }
        .sheet(isPresented: $viewModel.showInstallation) {
            if let type = viewModel.databaseTypeForInstallation {
                AIInstallationView(
                    databaseType: type,
                    serverId: viewModel.serverId ?? ""
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
    
    // MARK: - Stats Bar
    
    private var statsBar: some View {
        HStack(spacing: AXSpacing.lg) {
            // Premium Stats Cards
            PremiumStatCard(
                title: "Databases",
                value: "\(viewModel.totalDatabaseCount)",
                icon: "cylinder.split.1x2",
                color: .axAccentBlue
            )
            
            PremiumStatCard(
                title: "Total Size",
                value: viewModel.formattedTotalSize,
                icon: "internaldrive",
                color: .axAccentGreen
            )
            
            PremiumStatCard(
                title: "Users",
                value: "\(viewModel.totalUserCount)",
                icon: "person.2",
                color: .axWarning
            )
            
            PremiumStatCard(
                title: "Engines",
                value: "\(viewModel.installedDatabaseTypesCount)/9",
                icon: "server.rack",
                color: .axInfo
            )
            
            Spacer()
            
            // Connection status with glow
            PremiumConnectionStatus(isConnected: viewModel.isConnected)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }
    
    // MARK: - Tab Switcher
    
    private var tabSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.sm) {
                // All tab
                DBTabButton(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: viewModel.activeTabIndex == 0
                ) {
                    viewModel.activeTabIndex = 0
                }
                
                // Individual database type tabs
                ForEach(Array(viewModel.availableDatabaseTypes.enumerated()), id: \.element) { index, type in
                    DBTabButton(
                        title: type.displayName,
                        icon: type.iconName,
                        isSelected: viewModel.activeTabIndex == index + 1
                    ) {
                        viewModel.activeTabIndex = index + 1
                    }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
        }
        .padding(.bottom, AXSpacing.lg)
    }
    
    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if viewModel.activeTabIndex == 0 {
            // "All" tab shows ALL actual databases from ALL installed engines
            allDatabasesListView
        } else {
            // Type-specific tab shows filtered databases OR installation option
            specificDatabaseTypeView
        }
    }

    // MARK: - All Databases List View (Shows ACTUAL databases, not engine types)

    private var allDatabasesListView: some View {
        VStack(spacing: 0) {
            // Toolbar with search and actions
            allDatabasesToolbar

            // Content: Database list OR empty state with engine overview
            if viewModel.allDatabases.isEmpty {
                // No databases exist yet - show engine overview for installation
                noDatabasesView
            } else {
                // Show actual database list
                actualDatabasesGridView
            }
        }
    }

    // MARK: - All Databases Toolbar

    private var allDatabasesToolbar: some View {
        HStack(spacing: AXSpacing.md) {
            SearchField(text: $viewModel.searchText, placeholder: "Search...")
                .frame(width: 220)

            // View Mode Toggle
            HStack(spacing: 0) {
                ForEach(DatabaseManagementViewModel.DatabaseViewMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.databaseViewMode = mode
                        }
                    } label: {
                        Image(systemName: mode == .grid ? "square.grid.2x2.fill" : "list.bullet")
                            .font(.system(size: 12))
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

            // Show "New Database" only if at least one engine is installed
            if viewModel.installedDatabaseTypesCount > 0 {
                AXPrimaryButton(title: "New Database", icon: "plus", action: { viewModel.showAddDatabase = true })
                    .frame(width: 160)
            }

            Button(action: { Task { await viewModel.loadData() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                    .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                    .frame(width: 36, height: 36)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }

    // MARK: - Actual Databases Content

    private var actualDatabasesListView: some View {
        Group {
            if viewModel.databaseViewMode == .grid {
                actualDatabasesGridView
            } else {
                databaseTableView
            }
        }
    }

    private var actualDatabasesGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AXSpacing.lg),
                GridItem(.flexible(), spacing: AXSpacing.lg),
                GridItem(.flexible(), spacing: AXSpacing.lg)
            ], spacing: AXSpacing.lg) {
                ForEach(viewModel.filteredDatabases) { database in
                    databaseCardWithActions(database)
                        .contextMenu {
                            databaseContextMenu(database)
                        }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.lg)
        }
    }

    private var databaseTableView: some View {
        ScrollView {
            VStack(spacing: 1) {
                // Table Header
                HStack(spacing: AXSpacing.md) {
                    Text("Name").frame(width: 200, alignment: .leading)
                    Text("Engine").frame(width: 100, alignment: .leading)
                    Text("Version").frame(width: 80, alignment: .leading)
                    Text("Size").frame(width: 80, alignment: .leading)
                    Text("Tables").frame(width: 60, alignment: .trailing)
                    Text("Status").frame(width: 80, alignment: .center)
                    Spacer()
                }
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)

                // Table Rows
                ForEach(viewModel.filteredDatabases) { database in
                    DatabaseTableRow(
                        database: database,
                        onOpen: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                databaseForDetail = database
                            }
                        },
                        onBackup: {
                            Task {
                                guard let serverId = viewModel.serverId else { return }
                                do {
                                    let _ = try await CoreDatabaseService.shared.createBackup(
                                        database: database.name,
                                        type: database.type,
                                        serverId: serverId
                                    )
                                    GlobalToastManager.shared.showSuccess("Backup created for '\(database.name)'")
                                } catch {
                                    GlobalToastManager.shared.showError("Backup failed: \(error.localizedDescription)")
                                }
                            }
                        },
                        onDelete: {
                            databaseToDelete = database
                        }
                    )
                    .contextMenu {
                        databaseContextMenu(database)
                    }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.lg)
        }
    }

    private func databaseCardWithActions(_ database: DatabaseInfo) -> some View {
        ModernDatabaseCard(
            database: database,
            onOpen: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    databaseForDetail = database
                }
            },
            onBackup: {
                Task {
                    guard let serverId = viewModel.serverId else { return }
                    do {
                        let _ = try await CoreDatabaseService.shared.createBackup(
                            database: database.name,
                            type: database.type,
                            serverId: serverId
                        )
                        GlobalToastManager.shared.showSuccess("Backup created for '\(database.name)'")
                    } catch {
                        GlobalToastManager.shared.showError("Backup failed: \(error.localizedDescription)")
                    }
                }
            },
            onDelete: {
                databaseToDelete = database
            }
        )
    }

    private func databaseContextMenu(_ database: DatabaseInfo) -> some View {
        Group {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    databaseForDetail = database
                }
            } label: {
                Label("Open Detail", systemImage: "arrow.right.circle")
            }

            Button {
                Task {
                    guard let serverId = viewModel.serverId else { return }
                    do {
                        let _ = try await CoreDatabaseService.shared.createBackup(
                            database: database.name,
                            type: database.type,
                            serverId: serverId
                        )
                        GlobalToastManager.shared.showSuccess("Backup created for '\(database.name)'")
                    } catch {
                        GlobalToastManager.shared.showError("Backup failed: \(error.localizedDescription)")
                    }
                }
            } label: {
                Label("Create Backup", systemImage: "arrow.down.doc")
            }

            Divider()

            Button(role: .destructive) {
                databaseToDelete = database
            } label: {
                Label("Delete Database", systemImage: "trash")
            }
        }
    }

    // MARK: - No Databases View (Engine Overview)

    private var noDatabasesView: some View {
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
                            engineInstallCard(for: type)
                        }
                    }
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.bottom, AXSpacing.xl)
                }
            }
        }
    }

    private func engineInstallCard(for type: DatabaseType) -> some View {
        let isInstalled = viewModel.isEngineInstalled(type)
        
        return AXGlassCard(padding: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(type.brandColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: type.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(type.brandColor)
                    }
                    
                    Spacer()
                    
                    if isInstalled {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.axSuccess)
                            .font(.system(size: 14))
                    }
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(type.displayName)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(type.category.displayName)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                
                Spacer()
                
                if isInstalled {
                    Button {
                        showEngineDetail(for: type)
                    } label: {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12))
                            Text("Manage")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        viewModel.openInstallation(for: type)
                    } label: {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 12))
                            Text("Install")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 140, height: 160)
        }
    }
    
    // MARK: - Specific Database Type View
    
    private var specificDatabaseTypeView: some View {
        VStack(spacing: 0) {
            if let selectedType = viewModel.selectedDatabaseType {
                if let state = viewModel.installationState(for: selectedType) {
                    if state.isInstalled {
                        // Show database management for installed type
                        installedDatabaseView(type: selectedType)
                    } else {
                        // Show installation card
                        notInstalledView(type: selectedType)
                    }
                } else {
                    // State not found (likely not installed), show installation card
                    notInstalledView(type: selectedType)
                }
            }
        }
    }
    
    // MARK: - Installed Database View
    
    private func installedDatabaseView(type: DatabaseType) -> some View {
        VStack(spacing: 0) {
            // Toolbar with service controls
            HStack(spacing: AXSpacing.md) {
                // Search
                SearchField(text: $viewModel.searchText, placeholder: "Search databases...")
                    .frame(width: 280)
                
                Spacer()
                
                // Service controls
                HStack(spacing: AXSpacing.sm) {
                    // Manage Engine Button
                    Button {
                        showEngineDetail(for: type)
                    } label: {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 12))
                            Text("Manage Engine")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .frame(height: 24)
                    
                    DBServiceControlButton(
                        icon: "play.fill",
                        color: .axSuccess,
                        action: {
                            Task { try? await viewModel.startService(type: type) }
                        }
                    )
                    
                    DBServiceControlButton(
                        icon: "stop.fill",
                        color: .axError,
                        action: {
                            Task { try? await viewModel.stopService(type: type) }
                        }
                    )
                    
                    DBServiceControlButton(
                        icon: "arrow.clockwise",
                        color: .axWarning,
                        action: {
                            Task { try? await viewModel.restartService(type: type) }
                        }
                    )
                    
                    Divider()
                        .frame(height: 24)
                    
                    Button(action: { viewModel.showAddDatabase = true }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "plus")
                            Text("New Database")
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { Task { await viewModel.loadData() } }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                            Text("Refresh")
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
                emptyDatabasesView(type: type)
            } else {
                databaseListView
            }
        }
    }
    
    // MARK: - Not Installed View
    
    private func notInstalledView(type: DatabaseType) -> some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()
            
            Image(systemName: type.iconName)
                .font(.system(size: 64))
                .foregroundColor(type.brandColor.opacity(0.5))
            
            VStack(spacing: AXSpacing.md) {
                Text("\(type.displayName) Not Installed")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                
                Text("This database engine is not installed on your server. Use our AI-assisted installation to set it up with optimal configuration for your system.")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            Button(action: {
                viewModel.openInstallation(for: type)
            }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "sparkles")
                    Text("AI-Assisted Installation")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(
                    LinearGradient(
                        colors: [type.brandColor, type.brandColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Database List View
    
    private var databaseListView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AXSpacing.lg),
                GridItem(.flexible(), spacing: AXSpacing.lg)
            ], spacing: AXSpacing.lg) {
                ForEach(viewModel.filteredDatabases) { database in
                    databaseCardWithActions(database)
                        .contextMenu {
                            databaseContextMenu(database)
                        }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
        }
    }
    
    // MARK: - Toolbar View (Legacy - kept for compatibility)

    private var toolbarView: some View {
        allDatabasesToolbar
    }
    
    // MARK: - Loading View
    
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
    
    // MARK: - Error View
    
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
    
    // MARK: - Empty Databases View
    
    private func emptyDatabasesView(type: DatabaseType) -> some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "cylinder.split.1x2")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)
            
            Text("No Databases Found")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            Text("No \(type.displayName) databases were detected on this server.")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
            
            Button("Create First Database") {
                viewModel.showAddDatabase = true
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

// MARK: - Supporting Views

// Premium Stat Card with glassmorphism
private struct PremiumStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: isHovered ? [color.opacity(0.4), color.opacity(0.2)] : [Color.axGlassBorder, Color.axBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: isHovered ? color.opacity(0.1) : .clear, radius: 8, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Premium Connection Status - static indicator (no animation to save CPU)
private struct PremiumConnectionStatus: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                // Outer glow - static, no animation
                if isConnected {
                    Circle()
                        .fill(Color.axSuccess.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .blur(radius: 4)
                }
                
                Circle()
                    .fill(isConnected ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 8, height: 8)
            }
            
            Text(isConnected ? "Connected" : "Disconnected")
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(isConnected ? .axSuccess : .axTextMuted)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill((isConnected ? Color.axSuccess : Color.axTextMuted).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke((isConnected ? Color.axSuccess : Color.axTextMuted).opacity(0.3), lineWidth: 1)
        )
    }
}

// Legacy StatCard kept for backwards compatibility
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        PremiumStatCard(title: title, value: value, icon: icon, color: color)
    }
}

private struct ConnectionStatusView: View {
    let isConnected: Bool
    
    var body: some View {
        PremiumConnectionStatus(isConnected: isConnected)
    }
}

private struct DBTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? Color.axSurfaceHover : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axBorder : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// SearchField moved to bottom and merged

private struct DBServiceControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ModernDatabaseCard: View {
    let database: DatabaseInfo
    var onOpen: (() -> Void)?
    var onBackup: (() -> Void)?
    var onDelete: (() -> Void)?
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                // Header
                HStack(spacing: AXSpacing.md) {
                    // Database icon with gradient background
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(
                                LinearGradient(
                                    colors: [database.type.brandColor.opacity(0.25), database.type.brandColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: database.type.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(database.type.brandColor)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                        Text(database.name)
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)

                        if let version = database.version {
                            Text("\(database.type.displayName) \(version)")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        } else {
                            Text(database.type.displayName)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        }
                    }

                    Spacer()

                    // Action buttons (visible on hover)
                    if isHovered {
                        HStack(spacing: AXSpacing.xs) {
                            Button { onOpen?() } label: {
                                Image(systemName: "arrow.right.circle")
                                    .font(.system(size: 13))
                                    .foregroundColor(.axAccentBlue)
                                    .frame(width: 26, height: 26)
                                    .background(Color.axAccentBlue.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(.plain)
                            .help("Open Details")

                            Button { onBackup?() } label: {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 13))
                                    .foregroundColor(.axAccentGreen)
                                    .frame(width: 26, height: 26)
                                    .background(Color.axAccentGreen.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(.plain)
                            .help("Create Backup")

                            Button { onDelete?() } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.axError)
                                    .frame(width: 26, height: 26)
                                    .background(Color.axError.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(.plain)
                            .help("Delete Database")
                        }
                        .transition(.opacity)
                    } else {
                        // Status badge with glow
                        AXStatusBadge(
                            status: database.status == .online ? .online : .offline,
                            showLabel: false,
                            size: 8
                        )
                    }
                }
                
                // Divider with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.axBorder.opacity(0.3), Color.axBorder, Color.axBorder.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                
                // Stats Row
                HStack(spacing: AXSpacing.lg) {
                    // Size
                    VStack(alignment: .leading, spacing: 2) {
                        Text(database.formattedSize)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        Text("Size")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                    
                    // Tables
                    if database.tables > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(database.tables)")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)
                            Text("Tables")
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                        }
                    }
                    
                    // Connections
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(database.connections)")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        Text("Conns")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                    
                    Spacer()
                }
            }
            .padding(AXSpacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: isHovered 
                            ? [database.type.brandColor.opacity(0.4), database.type.brandColor.opacity(0.2)]
                            : [Color.axGlassBorder, Color.axBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: isHovered ? database.type.brandColor.opacity(0.1) : .clear, radius: 12, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onOpen?()
        }
    }
}

private struct StatusDot: View {
    let isActive: Bool
    
    var body: some View {
        Circle()
            .fill(isActive ? Color.axSuccess : Color.axTextMuted)
            .frame(width: 8, height: 8)
    }
}

private struct DBStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.axTextMuted)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                
                Text(label)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
        }
    }
}

// MARK: - Modern Add Database View

private struct ModernAddDatabaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddDatabaseViewModel
    let onCreated: () -> Void

    init(serverId: String?, installationStates: [DatabaseInstallationState], onCreated: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddDatabaseViewModel(
            serverId: serverId,
            installationStates: installationStates
        ))
        self.onCreated = onCreated
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.xl) {
                        engineSelectorSection
                        databaseNameSection
                        encodingSection
                        Divider()
                        userCreationSection
                    }
                    .padding(AXSpacing.xl)
                }
                Divider()
                footerSection
            }
            errorOverlay
        }
        .frame(width: 520, height: 550)
        .background(Color.axBackground)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Create Database")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Engine Selector

    @ViewBuilder
    private var engineSelectorSection: some View {
        if !viewModel.installedEngines.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Database Engine")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)

                HStack(spacing: AXSpacing.sm) {
                    ForEach(viewModel.installedEngines) { engine in
                        engineCard(engine)
                    }
                }
            }
        } else {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.axWarning)
                Text("No database engines installed on this server.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
            }
        }
    }

    private func engineCard(_ engine: DatabaseInstallationState) -> some View {
        let isSelected = viewModel.selectedType == engine.type
        return Button {
            viewModel.selectEngine(engine.type)
        } label: {
            VStack(spacing: AXSpacing.xs) {
                Image(systemName: engine.type.iconName)
                    .font(.system(size: 20))
                Text(engine.type.displayName)
                    .font(AXTypography.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Database Name

    private var databaseNameSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Database Name")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)

            TextField("my_database", text: $viewModel.databaseName)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(viewModel.nameError != nil ? Color.axError : Color.axBorder, lineWidth: 1)
                )
                .onChange(of: viewModel.databaseName) { _ in
                    viewModel.validateDatabaseName()
                }

            if let error = viewModel.nameError {
                inlineError(error)
            }
        }
    }

    // MARK: - Encoding + Collation

    private var encodingSection: some View {
        HStack(spacing: AXSpacing.lg) {
            pickerField(title: "Encoding", selection: $viewModel.selectedCharset, options: viewModel.availableCharsets)
                .onChange(of: viewModel.selectedCharset) { _ in
                    let collations = viewModel.availableCollations
                    if !collations.contains(viewModel.selectedCollation) {
                        viewModel.selectedCollation = collations.first ?? "default"
                    }
                }

            pickerField(title: "Collation", selection: $viewModel.selectedCollation, options: viewModel.availableCollations)
        }
    }

    private func pickerField(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(title)
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)

            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.xs)
            .padding(.horizontal, AXSpacing.sm)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - User Creation

    @ViewBuilder
    private var userCreationSection: some View {
        if let type = viewModel.selectedType, type.supportsUserManagement {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                Toggle(isOn: $viewModel.shouldCreateUser) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14))
                            .foregroundColor(.axAccentBlue)
                        Text("Create database user")
                            .font(AXTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.axTextPrimary)
                    }
                }
                .toggleStyle(.switch)
                .tint(.axAccentBlue)

                if viewModel.shouldCreateUser {
                    userFieldsCard
                }
            }
        }
    }

    private var userFieldsCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            usernameField
            passwordField
            hostAndOptionsRow
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Username")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)

            TextField("db_user", text: $viewModel.username)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(viewModel.usernameError != nil ? Color.axError : Color.axBorder, lineWidth: 1)
                )
                .onChange(of: viewModel.username) { _ in
                    viewModel.validateUsername()
                }

            if let error = viewModel.usernameError {
                inlineError(error)
            }
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Password")
                .font(AXTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.axTextSecondary)

            HStack(spacing: AXSpacing.sm) {
                Group {
                    if viewModel.showPassword {
                        TextField("Password", text: $viewModel.password)
                    } else {
                        SecureField("Password", text: $viewModel.password)
                    }
                }
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .onChange(of: viewModel.password) { _ in
                    viewModel.validatePassword()
                }

                Button {
                    viewModel.showPassword.toggle()
                } label: {
                    Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 13))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.generatePassword()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(viewModel.passwordError != nil ? Color.axError : Color.axBorder, lineWidth: 1)
            )

            if let error = viewModel.passwordError {
                inlineError(error)
            }
        }
    }

    private var hostAndOptionsRow: some View {
        HStack(spacing: AXSpacing.lg) {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Host Access")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)

                Picker("", selection: $viewModel.host) {
                    ForEach(viewModel.hostOptions, id: \.self) { option in
                        Text(option == "%" ? "Any Host (%)" : option).tag(option)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.vertical, AXSpacing.xs)
                .padding(.horizontal, AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Options")
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)

                Toggle(isOn: $viewModel.forceSSL) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 12))
                        Text("Force SSL")
                            .font(AXTypography.subheadline)
                    }
                    .foregroundColor(.axTextPrimary)
                }
                .toggleStyle(.switch)
                .tint(.axAccentBlue)
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerSection: some View {
        HStack(spacing: AXSpacing.md) {
            if viewModel.didSucceed {
                successFooter
            } else {
                defaultFooter
            }
        }
        .padding(AXSpacing.xl)
    }

    private var successFooter: some View {
        Group {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.axSuccess)
                Text("Database created successfully!")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axSuccess)
            }
            Spacer()
            Button(action: {
                onCreated()
                dismiss()
            }) {
                Text("Done")
                    .font(AXTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.md)
                    .background(Color.axSuccess)
                    .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
        }
    }

    private var defaultFooter: some View {
        Group {
            Spacer()
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSubmitting)

            Button(action: {
                Task { await viewModel.submitForm() }
            }) {
                HStack(spacing: AXSpacing.sm) {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.axBackground)
                    }
                    Text(viewModel.isSubmitting ? "Creating..." : "Create Database")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(viewModel.isFormValid && !viewModel.isSubmitting ? Color.axAccentBlue : Color.axTextMuted.opacity(0.5))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
        }
    }

    // MARK: - Error Overlay

    @ViewBuilder
    private var errorOverlay: some View {
        if viewModel.operationResult.isFailure {
            VStack {
                Spacer()
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                    Text(viewModel.operationResult.message ?? "Operation failed")
                        .font(AXTypography.subheadline)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        viewModel.operationResult = .idle
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundColor(.axError)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundColor(.axError)
                .padding(AXSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axError.opacity(0.1))
                )
                .padding(AXSpacing.lg)
            }
        }
    }

    // MARK: - Helpers

    private func inlineError(_ message: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 11))
            Text(message)
                .font(AXTypography.caption2)
        }
        .foregroundColor(.axError)
    }
}

// MARK: - Modern Add User View

private struct ModernAddUserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var host = "localhost"
    @State private var password = ""
    
    let onCreate: (String, String, String) -> Void
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            HStack {
                Text("Add Database User")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .background(Color.axBorder)
            
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Username")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    TextField("user_name", text: $username)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Host")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    TextField("localhost or %", text: $host)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Password")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    SecureField("", text: $password)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                }
            }
            
            Spacer()
            
            HStack(spacing: AXSpacing.md) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    onCreate(username, password, host)
                    dismiss()
                }) {
                    Text("Create User")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(username.isEmpty || password.isEmpty)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 400, height: 450)
        .background(Color.axBackground)
    }
}

// MARK: - Search Field Component

private struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(isFocused ? .axAccentBlue : .axTextMuted)
            
            TextField(placeholder, text: $text)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(isFocused ? Color.axAccentBlue.opacity(0.5) : Color.axBorder, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Database Table Row

private struct DatabaseTableRow: View {
    let database: DatabaseInfo
    var onOpen: (() -> Void)?
    var onBackup: (() -> Void)?
    var onDelete: (() -> Void)?
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Identifier (Icon + Name)
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(database.type.brandColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: database.type.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(database.type.brandColor)
                }
                
                Text(database.name)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
            .frame(width: 200, alignment: .leading)
            
            // Engine
            Text(database.type.displayName)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .frame(width: 100, alignment: .leading)
            
            // Version
            Text(database.version ?? "-")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextTertiary)
                .frame(width: 80, alignment: .leading)
            
            // Size
            Text(database.formattedSize)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .frame(width: 80, alignment: .leading)
            
            // Tables
            Text("\(database.tables)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 60, alignment: .trailing)
            
            // Status
            HStack {
                AXStatusBadge(
                    status: database.status == .online ? .online : .offline,
                    showLabel: false,
                    size: 6
                )
            }
            .frame(width: 80, alignment: .center)
            
            Spacer()
            
            // Inline Actions (visible on hover)
            HStack(spacing: AXSpacing.sm) {
                Button { onOpen?() } label: {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
                .help("Open Details")

                Button { onBackup?() } label: {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.axAccentGreen)
                }
                .buttonStyle(.plain)
                .help("Create Backup")

                Button { onDelete?() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.axError)
                }
                .buttonStyle(.plain)
                .help("Delete Database")
            }
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isHovered ? Color.axSurfaceHover : Color.clear)
        )
        .onTapGesture {
            onOpen?()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Navigation Extension

extension ModernDatabasesTab {
    /// Shows the detailed engine management view for a specific database type
    private func showEngineDetail(for type: DatabaseType) {
        // Use the new full-page management view
        engineManagementType = type
        showEngineManagement = true
    }
}