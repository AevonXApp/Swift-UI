//
//  DatabaseManagementViewModel.swift
//  AevonX
//
//  Main ViewModel for database management
//  Handles all database operations and state management
//
//  ARCHITECTURE: UI Layer ViewModel
//  - Uses specialized core services from Core layer for all database operations
//  - NEVER executes SSH commands directly
//  - Responsible only for UI state management and data presentation
//

import Foundation
import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - Database Management ViewModel

/// Main ViewModel for the database management system
/// Coordinates between UI and Core layer
///
/// All server operations go through specialized core services in the Core layer.
@MainActor
public final class DatabaseManagementViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All databases across all types (from Core layer)
    @Published public var allDatabases: [DatabaseInfo] = []

    /// Databases filtered by selected type and search text
    @Published public var filteredDatabases: [DatabaseInfo] = []

    /// Database users
    @Published public var databaseUsers: [DatabaseUserInfo] = []

    /// Installation states for all database types (from Core layer engines)
    @Published public var installationStates: [DatabaseInstallationState] = []

    /// Currently selected database type filter (nil = show all)
    @Published public var selectedDatabaseType: DatabaseType? = nil {
        didSet {
            filterDatabases()
        }
    }

    /// Active tab index (0 = All, 1+ = specific types)
    @Published public var activeTabIndex: Int = 0 {
        didSet {
            updateSelectedTypeFromTab()
        }
    }

    /// Loading state
    @Published public var isLoading = false

    /// Error message for user display
    @Published public var errorMessage: String?

    /// Connection state
    @Published public var isConnected = false

    /// Search text for filtering databases
    @Published public var searchText = "" {
        didSet {
            filterDatabases()
        }
    }

    /// Selected database for detail view
    @Published public var selectedDatabase: DatabaseInfo?

    /// Show add database sheet
    @Published public var showAddDatabase = false

    /// Show add user sheet
    @Published public var showAddUser = false

    /// Show engine detail view
    @Published public var showEngineDetail = false

    public enum DatabaseViewMode: String, CaseIterable, Identifiable {
        case grid, list
        public var id: String { self.rawValue }
    }
    
    /// View mode for database list
    @Published public var databaseViewMode: DatabaseViewMode = .grid

    // MARK: - Services

    // NOTE: We use specialized core services for all database operations
    // This ensures proper architecture separation (UI -> Core -> SSH)

    // MARK: - Server Properties

    let server: Server?
    let serverId: String?
    private weak var connectionViewModel: ServerConnectionViewModel?

    // MARK: - Initialization

    init(
        server: Server? = nil,
        serverId: String? = nil,
        connectionViewModel: ServerConnectionViewModel? = nil
    ) {
        self.server = server
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel

    }

    // MARK: - Data Loading

    /// Loads all database data from the server via Core layer
    public func loadData() async {
        guard let serverId = serverId else {
            errorMessage = "Server not configured"
            return
        }

        isLoading = true
        errorMessage = nil

        // Check connection status
        if let connectionViewModel = connectionViewModel {
            isConnected = connectionViewModel.isConnected
        } else {
            isConnected = false
            isLoading = false
            errorMessage = "Not connected to server"
            return
        }

        guard isConnected else {
            isLoading = false
            errorMessage = "Not connected to server. Please connect first."
            return
        }

        // Step 1: Load installation states (which database engines are installed)
        // Uses DatabaseEngineService from Core layer
        await loadInstallationStates(serverId: serverId)

        // Step 2: Load all databases from all installed engines
        // Uses DatabaseManagementService from Core layer
        await loadAllDatabases(serverId: serverId)

        // Step 3: Load database users
        // Uses DatabaseUserService from Core layer
        await loadDatabaseUsers(serverId: serverId)

        isLoading = false
    }

    /// Loads installation states for all database types via Core layer
    private func loadInstallationStates(serverId: String) async {
        // Call Core layer to detect installed databases
        let coreStates = await DatabaseEngineService.shared.detectInstalledDatabases(serverId: serverId)

        // coreStates are in fixed order: mysql, mariadb, postgresql, redis, mongodb, cassandra, cockroachdb, elasticsearch, sqlite
        // Map them to our UI DatabaseType enum
        let engineOrder: [DatabaseType] = [.mysql, .mariadb, .postgresql, .redis, .mongodb, .cassandra, .cockroachdb, .elasticsearch]
        
        var uiStates: [DatabaseInstallationState] = []
        for (index, dbType) in engineOrder.enumerated() {
            guard index < coreStates.count else { break }
            let coreState = coreStates[index]
            uiStates.append(DatabaseInstallationState(
                id: UUID(),
                type: dbType,
                isInstalled: coreState.isInstalled,
                installedVersion: coreState.version,
                installPath: coreState.installPath,
                serviceStatus: .unknown,
                isRunning: false,
                lastCheckedAt: Date()
            ))
        }
        
        // Deduplicate: When MariaDB is installed, MariaDB provides a `mysql` compatibility
        // binary that makes MySQL appear installed too. Suppress MySQL in this case to avoid
        // listing every database twice.
        let mysqlIdx = uiStates.firstIndex(where: { $0.type == .mysql && $0.isInstalled })
        let mariaIdx = uiStates.firstIndex(where: { $0.type == .mariadb && $0.isInstalled })
        if let mi = mysqlIdx, let _ = mariaIdx {
            uiStates[mi].isInstalled = false
        }
        
        // For installed engines, also check service status
        for i in 0..<uiStates.count where uiStates[i].isInstalled {
            let status = await DatabaseEngineService.shared.getServiceStatus(type: uiStates[i].type, serverId: serverId)
            uiStates[i].serviceStatus = ServiceStatus(rawValue: status.rawValue) ?? .unknown
            uiStates[i].isRunning = status == .active
        }

        installationStates = uiStates
        print("[DatabaseManagementVM] Detected engines: \(uiStates.filter { $0.isInstalled }.map { "\($0.type.displayName) v\($0.installedVersion ?? "?")" })")
    }

    /// Loads all databases from the server via Core layer
    private func loadAllDatabases(serverId: String) async {
        var allDBs: [DatabaseInfo] = []

        // Get databases for each installed engine type
        for state in installationStates where state.isInstalled {
            print("[DatabaseManagementVM] Listing databases for \(state.type.displayName) (rawValue=\(state.type.rawValue))")
            do {
                let coreDatabases = try await DatabaseManagementService.shared.listDatabases(
                    type: state.type.rawValue,
                    serverId: serverId
                )
                print("[DatabaseManagementVM] \(state.type.displayName): found \(coreDatabases.count) databases: \(coreDatabases.map { $0.name })")

                // Convert Core models to UI models
                let uiDatabases = coreDatabases.map { coreDB in
                    DatabaseInfo(
                        name: coreDB.name,
                        type: state.type,
                        version: state.installedVersion,
                        status: .online,
                        size: coreDB.size,
                        tables: coreDB.tables,
                        connections: 0,
                        host: "localhost",
                        port: state.type.defaultPort
                    )
                }

                allDBs.append(contentsOf: uiDatabases)

            } catch {
                print("[DatabaseManagementVM] ERROR listing \(state.type.displayName): \(error.localizedDescription)")
            }
        }

        print("[DatabaseManagementVM] Total databases loaded: \(allDBs.count)")
        allDatabases = allDBs
        filterDatabases()
    }

    /// Loads database users via Core layer
    func loadDatabaseUsers(serverId: String) async {
        // Only load if MySQL/MariaDB is installed
        guard installationStates.contains(where: { ($0.type == .mysql || $0.type == .mariadb) && $0.isInstalled }) else {
            return
        }

        do {
            let coreUsers = try await DatabaseUserService.shared.listUsers(type: .mysql, serverId: serverId)

            // Convert Core models to UI models
            let uiUsers = coreUsers.map { coreUser in
                DatabaseUserInfo(
                    id: UUID(uuidString: coreUser.id) ?? UUID(),
                    username: coreUser.username,
                    host: coreUser.host
                )
            }

            databaseUsers = uiUsers
        } catch {
            print("[DatabaseManagementVM] Could not load database users: \(error.localizedDescription)")
        }
    }


    // Filtering, operations, user management, statistics
    // → DatabaseManagementViewModel+Operations.swift
}
