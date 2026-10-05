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
    private var cancellables = Set<AnyCancellable>()
    private var statsTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        server: Server? = nil,
        serverId: String? = nil,
        connectionViewModel: ServerConnectionViewModel? = nil
    ) {
        self.server = server
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel

        // Reactive: auto-load when connection state changes
        connectionViewModel?.$isConnected
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                guard let self else { return }
                self.isConnected = connected
                if connected && self.allDatabases.isEmpty && !self.isLoading {
                    Task { await self.loadData() }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed State

    /// True while SSH connection is still being established
    var isWaitingForConnection: Bool {
        guard let cv = connectionViewModel else { return false }
        return !cv.isConnected && (cv.isConnecting || cv.isReconnecting)
    }

    // MARK: - Data Loading

    /// Loads all database data from the server via Core layer
    public func loadData(forceRefresh: Bool = false) async {
        guard let serverId = serverId else { return }
        guard !isLoading else { return } // prevent concurrent loads
        guard connectionViewModel?.isConnected == true else { return }

        // Check cache first
        let cacheKey = SSHResultCache.key(serverId, "databases:all")
        if !forceRefresh,
           let cached: [DatabaseInfo] = await SSHResultCache.shared.get(cacheKey),
           !cached.isEmpty {
            allDatabases = cached
            filterDatabases()
            return
        }

        isLoading = true
        isConnected = true
        errorMessage = nil

        // Step 1: Load installation states (which database engines are installed)
        await loadInstallationStates(serverId: serverId)

        // Step 2: Load all databases from all installed engines
        await loadAllDatabases(serverId: serverId)

        // Step 3: Load database users
        await loadDatabaseUsers(serverId: serverId)

        // Cache the results
        await SSHResultCache.shared.set(cacheKey, value: allDatabases, ttl: SSHResultCache.databaseListTTL)

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
        
        // For installed engines, also check service status (concurrently)
        let installedTypes = uiStates.filter(\.isInstalled).map(\.type)
        let statuses = await withTaskGroup(of: (DatabaseType, BridgeServiceStatus).self) { group in
            for type in installedTypes {
                group.addTask { (type, await DatabaseEngineService.shared.getServiceStatus(type: type, serverId: serverId)) }
            }
            var collected: [DatabaseType: BridgeServiceStatus] = [:]
            for await (type, status) in group { collected[type] = status }
            return collected
        }
        for i in uiStates.indices {
            guard let status = statuses[uiStates[i].type] else { continue }
            uiStates[i].serviceStatus = ServiceStatus(rawValue: status.rawValue) ?? .unknown
            uiStates[i].isRunning = status == .active
        }

        installationStates = uiStates
        CoreLogger.shared.info("Detected engines: \(uiStates.filter { $0.isInstalled }.map { "\($0.type.displayName) v\($0.installedVersion ?? "?")" })", module: "DatabaseManagement")
    }

    /// Loads all databases from the server via Core layer.
    ///
    /// Engines are listed concurrently. MySQL, MariaDB and PostgreSQL list
    /// names only (instant even with thousands of tables); sizes and table
    /// counts are filled in by `loadDatabaseStatsInBackground`.
    private func loadAllDatabases(serverId: String) async {
        let engines = installationStates.filter(\.isInstalled)

        let allDBs = await withTaskGroup(of: (Int, [DatabaseInfo]).self) { group in
            for (order, state) in engines.enumerated() {
                group.addTask { (order, await Self.listDatabases(for: state, serverId: serverId)) }
            }
            var collected: [(Int, [DatabaseInfo])] = []
            for await result in group { collected.append(result) }
            return collected.sorted { $0.0 < $1.0 }.flatMap(\.1)
        }

        CoreLogger.shared.info("Total databases loaded: \(allDBs.count)", module: "DatabaseManagement")
        allDatabases = allDBs
        filterDatabases()
        loadDatabaseStatsInBackground(serverId: serverId)
    }

    /// Main-actor isolated like the rest of the app; engines still list in
    /// parallel because each call suspends while its SSH command runs.
    private static func listDatabases(for state: DatabaseInstallationState, serverId: String) async -> [DatabaseInfo] {
        let makeInfo = { (name: String, size: Double, tables: Int) in
            DatabaseInfo(
                name: name,
                type: state.type,
                version: state.installedVersion,
                status: .online,
                size: size,
                tables: tables,
                connections: 0,
                host: "localhost",
                port: state.type.defaultPort,
                isReachable: true
            )
        }

        do {
            if ExplorerBridge.shared.supports(engine: state.type.rawValue) {
                let names = try await DatabaseManagementService.shared.listDatabaseNames(type: state.type.rawValue, serverId: serverId)
                return names.map { makeInfo($0, 0, 0) }
            }
            let coreDatabases = try await DatabaseManagementService.shared.listDatabases(type: state.type.rawValue, serverId: serverId)
            return coreDatabases.map { makeInfo($0.name, $0.size, $0.tables) }
        } catch {
            CoreLogger.shared.error("Failed to list \(state.type.displayName): \(error.localizedDescription)", module: "DatabaseManagement")
            return []
        }
    }

    /// Fills database sizes and table counts after the names are on screen.
    private func loadDatabaseStatsInBackground(serverId: String) {
        let engines = installationStates
            .filter { $0.isInstalled && ExplorerBridge.shared.supports(engine: $0.type.rawValue) }
            .map(\.type)
        guard !engines.isEmpty else { return }

        statsTask?.cancel()
        statsTask = Task { [weak self] in
            for type in engines {
                guard let stats = try? await DatabaseManagementService.shared.loadDatabaseStats(type: type.rawValue, serverId: serverId) else { continue }
                guard let self, !Task.isCancelled else { return }
                let byName = Dictionary(stats.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
                self.allDatabases = self.allDatabases.map { db in
                    guard db.type == type, let stat = byName[db.name] else { return db }
                    var updated = db
                    updated.size = Double(stat.sizeBytes) / (1024.0 * 1024.0)
                    if stat.tables >= 0 { updated.tables = stat.tables }
                    return updated
                }
                self.filterDatabases()
            }
            guard let self, !Task.isCancelled else { return }
            let cacheKey = SSHResultCache.key(serverId, "databases:all")
            await SSHResultCache.shared.set(cacheKey, value: self.allDatabases, ttl: SSHResultCache.databaseListTTL)
        }
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
            CoreLogger.shared.warning("Could not load database users: \(error.localizedDescription)", module: "DatabaseManagement")
        }
    }


    // Filtering, operations, user management, statistics
    // → DatabaseManagementViewModel+Operations.swift
}
