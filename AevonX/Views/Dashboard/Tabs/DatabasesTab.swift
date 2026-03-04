//
//  DatabasesTab.swift
//  AevonX
//
//  Database management tab with SSH data binding
//  Uses CommandTemplates for all database queries
//

import SwiftUI
import AevonXCore
import Combine

struct DatabasesTab: View {
    @StateObject private var viewModel: DatabasesTabViewModel
    @State private var searchText = ""
    @State private var selectedDatabase: DatabaseInfo?
    @State private var showAddDatabase = false
    @State private var showAddUser = false
    @State private var activeTab = 0 // 0 = Databases, 1 = Users
    
    init(server: Server? = nil, serverId: String? = nil, viewModel: ServerConnectionViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: DatabasesTabViewModel(server: server, serverId: serverId, connectionViewModel: viewModel))
    }
    
    var filteredDatabases: [DatabaseInfo] {
        if searchText.isEmpty { return viewModel.databases }
        return viewModel.databases.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Stats Bar
            HStack(spacing: AXSpacing.lg) {
                DatabaseStatCard(
                    title: "Databases",
                    value: "\(viewModel.databases.count)",
                    icon: "cylinder.split.1x2",
                    color: .axAccentBlue
                )
                
                DatabaseStatCard(
                    title: "Total Size",
                    value: formatTotalSize(),
                    icon: "internaldrive",
                    color: .axAccentGreen
                )
                
                DatabaseStatCard(
                    title: "Users",
                    value: "\(viewModel.users.count)",
                    icon: "person.2",
                    color: .axWarning
                )
                
                Spacer()
                
                // Connection status indicator
                if let connectionViewModel = viewModel.connectionViewModel {
                    ConnectionStatusIndicator(viewModel: connectionViewModel)
                } else {
                    DatabasesConnectionStatusIndicator(viewModel: viewModel)
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)
            
            // MARK: - Tab Switcher
            HStack(spacing: 0) {
                DatabaseTabButton(title: "Databases", icon: "cylinder.split.1x2", isSelected: activeTab == 0) {
                    activeTab = 0
                }
                
                DatabaseTabButton(title: "Users", icon: "person.2", isSelected: activeTab == 1) {
                    activeTab = 1
                }
                
                Spacer()
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)
            
            // MARK: - Content
            if activeTab == 0 {
                databasesContent
            } else {
                usersContent
            }

        }
        .sheet(isPresented: $showAddDatabase) {
            AddDatabaseView()
        }
        .sheet(isPresented: $showAddUser) {
            AddUserView()
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Databases Content
    
    private var databasesContent: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.axTextMuted)
                    
                    TextField("Search databases...", text: $searchText)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .cornerRadius(AXCornerRadius.md)
                .frame(width: 280)
                
                Spacer()
                
                HStack(spacing: AXSpacing.sm) {
                    Button(action: { showAddDatabase = true }) {
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
                    .disabled(!viewModel.isConnected)
                    
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
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)
            
            // Content Area
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if viewModel.databases.isEmpty {
                emptyView
            } else {
                // Database Cards Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: AXSpacing.lg),
                        GridItem(.flexible(), spacing: AXSpacing.lg)
                    ], spacing: AXSpacing.lg) {
                        ForEach(filteredDatabases) { database in
                            DatabaseInfoCard(database: database)
                                .onTapGesture {
                                    selectedDatabase = database
                                }
                        }
                    }
                    .padding(.horizontal, AXSpacing.xl)
                }
            }
        }
    }
    
    // MARK: - Users Content
    
    private var usersContent: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Spacer()
                
                Button(action: { showAddUser = true }) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "plus")
                        Text("Add User")
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
                .disabled(!viewModel.isConnected)
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.bottom, AXSpacing.lg)
            
            // Users Table
            if viewModel.users.isEmpty {
                emptyUsersView
            } else {
                UsersTableView(users: viewModel.users)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        AXLoadingState(message: "Loading databases...")
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
    
    // MARK: - Empty Views
    
    private var emptyView: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "cylinder.split.1x2")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)
            
            if viewModel.isConnected {
                Text("No Databases Found")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                
                Text("No MySQL, PostgreSQL, or Redis databases were detected on this server.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Not Connected")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                
                Text("Connect to the server to view databases.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }
    
    private var emptyUsersView: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)
            
            Text("No Users Found")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            Text("Connect to the server to view database users.")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AXSpacing.xl)
    }
    
    // MARK: - Helpers
    
    private func formatTotalSize() -> String {
        let total = viewModel.databases.reduce(0) { $0 + $1.size }
        if total >= 1024 {
            return String(format: "%.1f GB", total / 1024)
        }
        return String(format: "%.0f MB", total)
    }
}

// MARK: - Databases Connection Status Indicator

struct DatabasesConnectionStatusIndicator: View {
    @ObservedObject var viewModel: DatabasesTabViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(AXTypography.caption)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
        .background(statusColor.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private var statusColor: Color {
        if viewModel.isConnected {
            return .axSuccess
        } else if viewModel.isLoading {
            return .axWarning
        } else if viewModel.errorMessage != nil {
            return .axError
        } else {
            return .axTextMuted
        }
    }
    
    private var statusText: String {
        if viewModel.isConnected {
            return "Connected"
        } else if viewModel.isLoading {
            return "Loading..."
        } else if viewModel.errorMessage != nil {
            return "Error"
        } else {
            return "Disconnected"
        }
    }
}

// MARK: - Databases Tab ViewModel

@MainActor
class DatabasesTabViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var databases: [DatabaseInfo] = []
    @Published var users: [DatabaseUserInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isConnected: Bool = false
    
    // MARK: - Private Properties
    
    private let server: Server?
    private let serverId: String?
    private let sshService = SSHService.shared
    weak var connectionViewModel: ServerConnectionViewModel?
    
    // MARK: - Initialization
    
    init(server: Server? = nil, serverId: String? = nil, connectionViewModel: ServerConnectionViewModel? = nil) {
        self.server = server
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
    }
    
    // MARK: - Data Loading
    
    func loadData() async {
        guard let serverId = serverId else {
            errorMessage = "Server not configured"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        if let connectionViewModel = connectionViewModel {
            isConnected = connectionViewModel.isConnected
            print("[DatabasesTab] Using parent connectionViewModel - isConnected: \(isConnected)")
        } else {
            // No connection view model available
            print("[DatabasesTab] No connectionViewModel available")
            isConnected = false
            errorMessage = "Not connected to server"
            isLoading = false
            return
        }
        
        if !isConnected {
            print("[DatabasesTab] Not connected, skipping data load")
            isLoading = false
            return
        }
        
        // Load databases using CommandTemplates only
        await loadDatabases(serverId: serverId)
        
        // Load users
        await loadUsers(serverId: serverId)
        
        isLoading = false
    }
    
    private func loadDatabases(serverId: String) async {
        var loadedDatabases: [DatabaseInfo] = []
        
        // Use CommandTemplates.Databases commands only - no raw commands
        
        // Try MySQL
        do {
            let mysqlResult = try await executeCommand(.databases(.listMySQL), serverId: serverId)
            let mysqlDBs = parseMySQLDatabases(mysqlResult.stdout)
            loadedDatabases.append(contentsOf: mysqlDBs)
        } catch {
            CoreLogger.shared.debug("MySQL not available: \(error.localizedDescription)", module: "DatabasesTab")
        }
        
        // Try PostgreSQL
        do {
            let pgResult = try await executeCommand(.databases(.listPostgreSQL), serverId: serverId)
            let pgDBs = parsePostgreSQLDatabases(pgResult.stdout)
            loadedDatabases.append(contentsOf: pgDBs)
        } catch {
            CoreLogger.shared.debug("PostgreSQL not available: \(error.localizedDescription)", module: "DatabasesTab")
        }
        
        // Try Redis
        do {
            let redisResult = try await executeCommand(.databases(.listRedis), serverId: serverId)
            if let redisDB = parseRedisInfo(redisResult.stdout) {
                loadedDatabases.append(redisDB)
            }
        } catch {
            CoreLogger.shared.debug("Redis not available: \(error.localizedDescription)", module: "DatabasesTab")
        }
        
        databases = loadedDatabases
    }
    
    private func loadUsers(serverId: String) async {
        var loadedUsers: [DatabaseUserInfo] = []
        
        // Use CommandTemplates only
        do {
            let usersResult = try await executeCommand(.databases(.listMySQLUsers), serverId: serverId)
            loadedUsers = parseMySQLUsers(usersResult.stdout)
        } catch {
            CoreLogger.shared.debug("Could not load MySQL users: \(error.localizedDescription)", module: "DatabasesTab")
        }
        
        users = loadedUsers
    }
    
    // MARK: - Private Helpers
    
    private func executeCommand(_ command: CommandTemplate, serverId: String) async throws -> SSHCommandResult {
        let commandString = command.build()
        return try await sshService.execute(commandString, serverId: serverId)
    }
    
    // MARK: - Parsing
    
    private func parseMySQLDatabases(_ output: String) -> [DatabaseInfo] {
        var databases: [DatabaseInfo] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  trimmed != "Database",
                  !trimmed.hasPrefix("+"),
                  !trimmed.hasPrefix("|") else { continue }
            
            // Skip system databases
            let systemDBs = ["information_schema", "mysql", "performance_schema", "sys"]
            guard !systemDBs.contains(trimmed) else { continue }
            
            databases.append(DatabaseInfo(
                name: trimmed,
                type: .mysql,
                status: .online
            ))
        }
        
        return databases
    }
    
    private func parsePostgreSQLDatabases(_ output: String) -> [DatabaseInfo] {
        var databases: [DatabaseInfo] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("Name"),
                  !trimmed.hasPrefix("-"),
                  !trimmed.hasPrefix("(") else { continue }
            
            let components = trimmed.components(separatedBy: "|")
            guard let name = components.first?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty,
                  name != "postgres",
                  name != "template0",
                  name != "template1" else { continue }
            
            databases.append(DatabaseInfo(
                name: name,
                type: .postgresql,
                status: .online
            ))
        }
        
        return databases
    }
    
    private func parseRedisInfo(_ output: String) -> DatabaseInfo? {
        guard output.contains("redis_version") else { return nil }
        
        var version: String?
        var usedMemory: Double = 0
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("redis_version:") {
                version = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
            }
            if line.hasPrefix("used_memory:") {
                if let bytesStr = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces),
                   let bytes = Double(bytesStr) {
                    usedMemory = bytes / (1024 * 1024)
                }
            }
        }
        
        return DatabaseInfo(
            name: "Redis Server",
            type: .redis,
            version: version,
            status: .online,
            size: usedMemory
        )
    }
    
    private func parseMySQLUsers(_ output: String) -> [DatabaseUserInfo] {
        var users: [DatabaseUserInfo] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  trimmed != "User",
                  !trimmed.hasPrefix("+"),
                  !trimmed.hasPrefix("|") else { continue }
            
            let components = trimmed.components(separatedBy: "|")
            guard components.count >= 2 else { continue }
            
            let username = components[0].trimmingCharacters(in: .whitespaces)
            let host = components[1].trimmingCharacters(in: .whitespaces)
            
            guard !username.isEmpty, username != "User" else { continue }
            
            users.append(DatabaseUserInfo(
                username: username,
                host: host,
                privileges: []
            ))
        }
        
        return users
    }
}

// MARK: - Legacy Database User Info (Deprecated)
/// This struct is kept for backward compatibility with the old DatabasesTab
/// Use the new `DatabaseUserInfo` from databases/Models/DatabaseInfo.swift instead
private struct LegacyDatabaseUserInfo: Identifiable {
    let id = UUID()
    var username: String
    var host: String
    var privileges: [String]
    var lastActive: Date?
}

// MARK: - Database Tab Button

struct DatabaseTabButton: View {
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

// MARK: - Users Table View

struct UsersTableView: View {
    let users: [DatabaseUserInfo]
    
    var body: some View {
        AXCard(padding: 0) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: AXSpacing.md) {
                    Text("User")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 150, alignment: .leading)
                    
                    Text("Host")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 120, alignment: .leading)
                    
                    Text("Privileges")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 200, alignment: .leading)
                    
                    Text("Last Active")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 100, alignment: .leading)
                    
                    Spacer()
                    
                    Text("Actions")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 80, alignment: .center)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.md)
                .background(Color.axBackgroundTertiary)
                
                Divider()
                    .background(Color.axBorder)
                
                // Rows
                ForEach(users) { user in
                    DatabaseUserRow(user: user)
                    
                    if user.id != users.last?.id {
                        Divider()
                            .background(Color.axBorder)
                            .padding(.leading, AXSpacing.lg)
                    }
                }
            }
        }
        .padding(.horizontal, AXSpacing.xl)
    }
}

// MARK: - Database User Row

struct DatabaseUserRow: View {
    let user: DatabaseUserInfo
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "person.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.axAccentBlue) // Keeping blue for users as they might be multi-engine in the future
                
                Text(user.username)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
            }
            .frame(width: 150, alignment: .leading)
            
            Text(user.host)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .frame(width: 120, alignment: .leading)
                .monospaced()
            
            // Privileges
            HStack(spacing: AXSpacing.xs) {
                ForEach(user.privileges.prefix(2), id: \.self) { privilege in
                    Text(String(describing: privilege))
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axBackgroundTertiary)
                        .cornerRadius(AXCornerRadius.sm)
                }
                
                if user.privileges.count > 2 {
                    Text("+\(user.privileges.count - 2)")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            }
            .frame(width: 200, alignment: .leading)
            
            if let lastActive = user.lastActive {
                Text(timeAgo(lastActive))
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                    .frame(width: 100, alignment: .leading)
            } else {
                Text("Never")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
                    .frame(width: 100, alignment: .leading)
            }
            
            Spacer()
            
            HStack(spacing: AXSpacing.sm) {
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.axError)
                        .frame(width: 28, height: 28)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(Color.axSurface)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Database Stat Card

struct DatabaseStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                Text(value)
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                
                Text(title)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .cornerRadius(AXCornerRadius.md)
    }
}

// MARK: - Database Info Card

struct DatabaseInfoCard: View {
    let database: DatabaseInfo
    
    var body: some View {
        AXCard {
            VStack(spacing: AXSpacing.lg) {
                // Header
                HStack {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: databaseIcon)
                            .font(.system(size: 20))
                            .foregroundColor(databaseColor)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(database.name)
                                .font(AXTypography.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)
                            
                            if let version = database.version {
                                Text("\(database.type.rawValue) \(version)")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                            } else {
                                Text(database.type.rawValue)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    DatabaseStatusIndicator(status: database.status, showLabel: false, size: 8)
                }
                
                Divider()
                    .background(Color.axBorder)
                
                // Stats
                HStack(spacing: AXSpacing.xl) {
                    DatabaseStat(
                        icon: "internaldrive",
                        value: formatSize(database.size),
                        label: "Size"
                    )
                    
                    if database.tables > 0 {
                        DatabaseStat(
                            icon: "tablecells",
                            value: "\(database.tables)",
                            label: "Tables"
                        )
                    }
                    
                    DatabaseStat(
                        icon: "link",
                        value: "\(database.connections)",
                        label: "Conns"
                    )
                }
                
                // Actions
                HStack(spacing: AXSpacing.sm) {
                    Button(action: {}) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "terminal")
                                .font(.system(size: 10))
                            Text("Console")
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(database.type.brandColor)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(database.type.brandColor.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {}) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 10))
                            Text("Backup")
                        }
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentGreen)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axAccentGreen.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Menu {
                        Button("Optimize") {}
                        Button("Repair") {}
                        Divider()
                        Button("Export") {}
                        Button("Duplicate") {}
                        Divider()
                        Button("Delete", role: .destructive) {}
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }
        }
    }
    
    private var databaseIcon: String {
        switch database.type {
        case .mysql, .postgresql, .sqlite, .mariadb, .cockroachdb:
            return "cylinder.split.1x2"
        case .redis:
            return "bolt.fill"
        case .mongodb:
            return "leaf.fill"
        case .cassandra:
            return "circle.hexagongrid.fill"
        case .elasticsearch:
            return "magnifyingglass"
        case .unknown:
            return "cylinder"
        }
    }
    
    private var databaseColor: Color {
        database.type.brandColor
    }
    
    private func formatSize(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        } else {
            return String(format: "%.0f MB", mb)
        }
    }
}

struct DatabaseStat: View {
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

// MARK: - Database Status Indicator

struct DatabaseStatusIndicator: View {
    let status: DatabaseStatus
    var showLabel: Bool = true
    var size: CGFloat = 8
    
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Circle()
                .fill(statusColor)
                .frame(width: size, height: size)
                .shadow(color: statusColor.opacity(0.5), radius: size/2, x: 0, y: 0)
            
            if showLabel {
                Text(status.rawValue)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(Color(hex: "#A1A1AA"))
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .online: return Color(hex: "#22C55E")
        case .offline: return Color(hex: "#52525B")
        case .starting: return Color(hex: "#F59E0B")
        case .stopping: return Color(hex: "#F59E0B")
        case .error: return Color(hex: "#EF4444")
        case .maintenance: return Color(hex: "#F59E0B")
        case .unknown: return Color(hex: "#52525B")
        case .notInstalled: return Color(hex: "#52525B")
        }
    }
}

// MARK: - Add Database View

struct AddDatabaseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedType = "MySQL"
    
    let types = ["MySQL", "PostgreSQL", "Redis", "MongoDB"]
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            HStack {
                Text("Create Database")
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
                    Text("Database Name")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    TextField("my_database", text: $name)
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
                    Text("Database Type")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    Picker("", selection: $selectedType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
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
                
                Button(action: { dismiss() }) {
                    Text("Create Database")
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 400, height: 350)
        .background(Color.axBackground)
    }
}

// MARK: - Add User View

struct AddUserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var host = "localhost"
    @State private var password = ""
    
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
                
                Button(action: { dismiss() }) {
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
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 400, height: 450)
        .background(Color.axBackground)
    }
}

#Preview {
    DatabasesTab()
        .padding()
        .background(Color.axBackground)
}
