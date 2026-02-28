//
//  FTPTab.swift
//  AevonX
//
//  Main FTP Management tab with sub-tabs for Users and Logs
//

import SwiftUI
import AevonXCore

enum FTPUserFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case inactive = "Inactive"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "person.2"
        case .active: return "checkmark.circle.fill"
        case .inactive: return "pause.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .axAccentBlue
        case .active: return .axSuccess
        case .inactive: return .axTextMuted
        }
    }
}

struct FTPTab: View {
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    @StateObject private var vm: FTPViewModel
    
    @State private var selectedSubTab = 0
    @State private var showDeleteAlert = false
    @State private var userToDelete: FTPUser?
    @State private var userFilter: FTPUserFilter = .all
    
    init(serverId: String, connectionViewModel: ServerConnectionViewModel) {
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
        _vm = StateObject(wrappedValue: FTPViewModel(serverId: serverId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            
            Divider().background(Color.axBorder)
            
            // Content
            ScrollView {
                VStack(spacing: AXSpacing.lg) {
                    if vm.isLoading {
                        loadingState
                    } else if !vm.serverInfo.isInstalled {
                        installPrompt
                    } else {
                        // FTP server info bar
                        serverInfoBar
                        
                        // Sub-tab content
                        if selectedSubTab == 0 {
                            usersContent
                        } else {
                            logsContent
                        }
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .sheet(isPresented: $vm.showAddSheet) {
            FTPAddUserSheet(vm: vm)
        }
        .sheet(isPresented: $vm.showSettingsSheet) {
            FTPSettingsSheet(vm: vm)
        }
        .alert("Delete FTP User?", isPresented: $showDeleteAlert, presenting: userToDelete) { user in
            Button("Cancel", role: .cancel) { userToDelete = nil }
            Button("Delete", role: .destructive) { Task { await vm.deleteUser(user) } }
        } message: { user in
            Text("Delete \"\(user.username)\"? This will remove the FTP account from the server.")
        }
        .overlay(alignment: .bottom) { toastOverlay }
        .task {
            await vm.loadAll()
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        VStack(spacing: 0) {
            // Row 1: Title
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "externaldrive.connected.to.line.below")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.axAccentBlue)
                    Text("FTP Manager")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.xl)
            .padding(.bottom, AXSpacing.md)
            
            // Row 2: Sub-tabs + search + actions
            if vm.serverInfo.isInstalled {
                HStack(spacing: AXSpacing.lg) {
                    // Sub-tabs
                    HStack(spacing: 0) {
                        subTab("FTP Users", icon: "person.2", index: 0, count: vm.users.count)
                        subTab("FTP Logs", icon: "doc.text.magnifyingglass", index: 1, count: vm.logEntries.count)
                    }
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.md)
                    
                    Spacer()
                    
                    // Stats (users tab) or filter (logs tab)
                    if selectedSubTab == 0 {
                        HStack(spacing: AXSpacing.sm) {
                            statBadge(vm.activeUsersCount, label: "Active", color: .axSuccess)
                            statBadge(vm.inactiveUsersCount, label: "Inactive", color: .axTextMuted)
                        }
                    }
                    
                    // Search
                    AXSearchBar(
                        text: selectedSubTab == 0 ? $vm.searchText : $vm.logSearchText,
                        placeholder: selectedSubTab == 0 ? "Search users..." : "Search logs..."
                    )
                    .frame(width: 200)
                    
                    // Settings
                    Button(action: { vm.showSettingsSheet = true }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 11))
                            Text("Settings")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 7)
                        .background(Color.axBackgroundTertiary)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Add User (only on users tab)
                    if selectedSubTab == 0 {
                        Button(action: { vm.editingUser = nil; vm.showAddSheet = true }) {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Add FTP")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, 7)
                            .background(LinearGradient(colors: [.axAccentBlue, .axAccentBlue.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Refresh logs (only on logs tab)
                    if selectedSubTab == 1 {
                        Button(action: { Task { await vm.loadLogs() } }) {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Refresh")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, 7)
                            .background(Color.axAccentBlue.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1))
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, AXSpacing.xl)
                .padding(.bottom, AXSpacing.md)
            }
        }
    }
    
    // MARK: - Server Info Bar
    
    private var serverInfoBar: some View {
        HStack(spacing: AXSpacing.lg) {
            // FTP Address
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.axAccentBlue)
                Text("FTP address:")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextSecondary)
                Text(vm.serverInfo.ftpAddress)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                
                Button(action: {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(vm.serverInfo.ftpAddress, forType: .string)
                    #endif
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Copy FTP Address")
            }
            
            Spacer()
            
            // Version info
            HStack(spacing: AXSpacing.xs) {
                Text("PureFTPd")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.axAccentGreen)
                Text(vm.serverInfo.version)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextTertiary)
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, 4)
            .background(Color.axAccentGreen.opacity(0.08))
            .cornerRadius(AXCornerRadius.sm)
            
            // Service status
            HStack(spacing: AXSpacing.xs) {
                Circle()
                    .fill(vm.serverInfo.isRunning ? Color.axSuccess : Color.axError)
                    .frame(width: 6, height: 6)
                Text(vm.serverInfo.isRunning ? "Running" : "Stopped")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(vm.serverInfo.isRunning ? .axSuccess : .axError)
            }
            
            // Service control
            Button(action: {
                Task {
                    if vm.serverInfo.isRunning {
                        await vm.restartService()
                    } else {
                        await vm.startService()
                    }
                }
            }) {
                Image(systemName: vm.serverInfo.isRunning ? "arrow.clockwise" : "play.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axAccentBlue)
                    .frame(width: 24, height: 24)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(5)
            }
            .buttonStyle(PlainButtonStyle())
            .help(vm.serverInfo.isRunning ? "Restart Service" : "Start Service")
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axAccentBlue.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axAccentBlue.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Users Content
    
    private var usersContent: some View {
        VStack(spacing: AXSpacing.md) {
            // Filter chips
            HStack(spacing: 6) {
                ForEach(FTPUserFilter.allCases) { filter in
                    let count = countForFilter(filter)
                    let isActive = userFilter == filter
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { userFilter = filter }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 9, weight: .bold))
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                            Text("\(count)")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule().fill(isActive ? Color.white.opacity(0.2) : filter.color.opacity(0.1))
                                )
                        }
                        .foregroundColor(isActive ? .white : .axTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(isActive ? filter.color : Color.axSurface)
                        )
                        .overlay(
                            Capsule().stroke(isActive ? Color.clear : Color.axBorder.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            
            if filteredFTPUsers.isEmpty {
                emptyUsersState
            } else {
                // Table header
                HStack(spacing: 0) {
                    Text("User")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Quota")
                        .frame(width: 80, alignment: .center)
                    Text("Status")
                        .frame(width: 80, alignment: .center)
                    Text("Password")
                        .frame(width: 80, alignment: .center)
                    Text("Actions")
                        .frame(width: 130, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.axTextTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, AXSpacing.md)
                
                ForEach(filteredFTPUsers) { user in
                    FTPUserRow(
                        user: user,
                        onEdit: { vm.editingUser = user; vm.showAddSheet = true },
                        onToggle: { Task { await vm.toggleUser(user) } },
                        onDelete: { userToDelete = user; showDeleteAlert = true },
                        onCopyPassword: {
                            #if os(macOS)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(user.password, forType: .string)
                            #endif
                        }
                    )
                }
            }
        }
    }
    
    private var filteredFTPUsers: [FTPUser] {
        switch userFilter {
        case .all: return vm.filteredUsers
        case .active: return vm.filteredUsers.filter { $0.status == .active }
        case .inactive: return vm.filteredUsers.filter { $0.status == .inactive }
        }
    }
    
    private func countForFilter(_ filter: FTPUserFilter) -> Int {
        switch filter {
        case .all: return vm.filteredUsers.count
        case .active: return vm.filteredUsers.filter { $0.status == .active }.count
        case .inactive: return vm.filteredUsers.filter { $0.status == .inactive }.count
        }
    }
    
    // MARK: - Logs Content (Inline Table)
    
    private var logsContent: some View {
        VStack(spacing: AXSpacing.md) {
            // Log type filter pills
            HStack(spacing: AXSpacing.xs) {
                logFilterPill(label: "All", type: nil, count: vm.logEntries.count)
                logFilterPill(label: "Login", type: .login, count: vm.logTypeCounts[.login] ?? 0)
                logFilterPill(label: "Logout", type: .logout, count: vm.logTypeCounts[.logout] ?? 0)
                logFilterPill(label: "Upload", type: .upload, count: vm.logTypeCounts[.upload] ?? 0)
                logFilterPill(label: "Download", type: .download, count: vm.logTypeCounts[.download] ?? 0)
                logFilterPill(label: "Error", type: .error, count: vm.logTypeCounts[.error] ?? 0)
                logFilterPill(label: "Info", type: .info, count: vm.logTypeCounts[.info] ?? 0)
                Spacer()
            }
            
            if vm.isLoadingLogs {
                AXLoadingState(message: "Loading FTP logs...")
            } else if vm.filteredLogs.isEmpty {
                VStack(spacing: AXSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Color.axAccentBlue.opacity(0.08))
                            .frame(width: 80, height: 80)
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.axAccentBlue.opacity(0.5))
                    }
                    Text(vm.logEntries.isEmpty ? "No FTP Logs" : "No Matching Logs")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    Text(vm.logEntries.isEmpty
                         ? "FTP activity logs will appear here.\nLogs are loaded from the server automatically."
                         : "No logs match the current filter.")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                // Log table header
                HStack(spacing: 0) {
                    Text("Type")
                        .frame(width: 80, alignment: .leading)
                    Text("Timestamp")
                        .frame(width: 160, alignment: .leading)
                    Text("Message")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.axTextTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs)
                
                // Log rows
                ForEach(vm.filteredLogs) { entry in
                    logRow(entry)
                }
            }
        }
        .task {
            if vm.logEntries.isEmpty {
                await vm.loadLogs()
            }
        }
    }
    
    // MARK: - Log Row
    
    private func logRow(_ entry: FTPLogEntry) -> some View {
        HStack(spacing: 0) {
            // Type badge
            HStack(spacing: 4) {
                Image(systemName: logIconName(entry.type))
                    .font(.system(size: 9, weight: .bold))
                Text(entry.type.rawValue)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(logColor(entry.type))
            .frame(width: 80, alignment: .leading)
            
            // Timestamp
            Text(entry.timestamp)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextTertiary)
                .frame(width: 160, alignment: .leading)
            
            // Message
            Text(entry.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(logColor(entry.type).opacity(0.02))
        )
    }
    
    // MARK: - Empty Users State
    
    private var emptyUsersState: some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.axAccentBlue.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(.axAccentBlue.opacity(0.5))
            }
            
            Text("No FTP Users")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.axTextPrimary)
            
            Text("Create FTP accounts to allow file transfer access.\nUsers can connect using any FTP client.")
                .font(AXTypography.body)
                .foregroundColor(.axTextTertiary)
                .multilineTextAlignment(.center)
            
            Button(action: { vm.editingUser = nil; vm.showAddSheet = true }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                    Text("Add FTP User").font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Install Prompt
    
    private var installPrompt: some View {
        VStack(spacing: AXSpacing.xl) {
            ZStack {
                Circle()
                    .fill(Color.axWarning.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 42))
                    .foregroundColor(.axWarning.opacity(0.6))
            }
            
            Text("PureFTPd Not Installed")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.axTextPrimary)
            
            Text("PureFTPd is required for FTP user management.\nInstall it now to enable FTP access on this server.")
                .font(AXTypography.body)
                .foregroundColor(.axTextTertiary)
                .multilineTextAlignment(.center)
            
            Button(action: { Task { await vm.installFTP() } }) {
                HStack(spacing: AXSpacing.sm) {
                    if vm.isInstalling {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(vm.isInstalling ? "Installing PureFTPd..." : "Install PureFTPd")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.xxl)
                .padding(.vertical, AXSpacing.md)
                .background(
                    LinearGradient(
                        colors: [.axAccentBlue, .axAccentBlue.opacity(0.8)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .cornerRadius(AXCornerRadius.lg)
                .shadow(color: .axAccentBlue.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(vm.isInstalling)
            
            VStack(spacing: AXSpacing.sm) {
                infoRow(icon: "checkmark.shield", text: "Secure virtual user system — no system accounts needed")
                infoRow(icon: "bolt.fill", text: "High performance FTP server")
                infoRow(icon: "lock.fill", text: "TLS/SSL support available")
            }
            .padding(.top, AXSpacing.md)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        AXLoadingState(message: "Checking FTP installation...")
    }
    
    // MARK: - Helpers
    
    private func subTab(_ title: String, icon: String, index: Int, count: Int) -> some View {
        Button(action: { withAnimation(.spring(response: 0.3)) { selectedSubTab = index } }) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon).font(.system(size: 11))
                Text(title).font(.system(size: 12, weight: .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(selectedSubTab == index ? .white : .axTextTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(selectedSubTab == index ? Color.white.opacity(0.2) : Color.axBorder.opacity(0.5))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(selectedSubTab == index ? .white : .axTextSecondary)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, 8)
            .background(selectedSubTab == index ? Color.axAccentBlue : Color.clear)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statBadge(_ count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(count)").font(.system(size: 11, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 10)).foregroundColor(.axTextTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.06))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private func logFilterPill(label: String, type: FTPLogType?, count: Int) -> some View {
        let isSelected = vm.selectedLogType == type
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                vm.selectedLogType = isSelected ? nil : type
            }
        }) {
            HStack(spacing: 4) {
                if let t = type {
                    Image(systemName: logIconName(t))
                        .font(.system(size: 9))
                }
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isSelected ? .white : .axTextTertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.axBorder.opacity(0.5))
                        .cornerRadius(6)
                }
            }
            .foregroundColor(isSelected ? .white : .axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, 5)
            .background(isSelected ? (type != nil ? logColor(type!) : Color.axAccentBlue) : Color.axBackgroundTertiary)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.axAccentBlue)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.axTextSecondary)
        }
    }
    
    private func logIconName(_ type: FTPLogType) -> String {
        switch type {
        case .login: return "arrow.right.circle"
        case .logout: return "arrow.left.circle"
        case .upload: return "arrow.up.circle"
        case .download: return "arrow.down.circle"
        case .error: return "exclamationmark.circle"
        case .info: return "info.circle"
        }
    }
    
    private func logColor(_ type: FTPLogType) -> Color {
        switch type {
        case .login: return .axAccentGreen
        case .logout: return .axAccentBlue
        case .upload: return .axWarning
        case .download: return .cyan
        case .error: return .axError
        case .info: return .axTextMuted
        }
    }
    
    @ViewBuilder
    private var toastOverlay: some View {
        if let msg = vm.toastMessage {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: msg.1 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                Text(msg.0)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.md)
            .background(Capsule().fill(msg.1 ? Color.axSuccess : Color.axError).shadow(color: .black.opacity(0.3), radius: 10, y: 4))
            .padding(.bottom, AXSpacing.xl)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4), value: vm.toastMessage != nil)
        }
    }
}
