//
//  RemoteFleetView.swift
//X
//
//   Aevon Remote Fleet UI - Connected to Core for real data
//

import SwiftUI
import AevonXCore

// MARK: - Edit Server View (Simple Version using Standard SwiftUI)
struct EditServerView: View {
    @Environment(\.dismiss) private var dismiss
    let server: ServerViewModel
    let onSave: (AddServerRequest) -> Void
    
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = ""
    @State private var username: String = ""
    @State private var authType: AuthenticationType = .password
    @State private var password: String = ""
    @State private var privateKey: String = ""
    @State private var keyPassphrase: String = ""
    @State private var tagsText: String = ""
    @State private var selectedIcon: ServerIcon = .serverRack
    @State private var selectedColor: ServerColor = .blue
    
    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.axTextMuted)
                    }
                    
                    Text("Edit Server")
                        .font(AXTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, AXSpacing.xl)
                .padding(.top, AXSpacing.xl)
                
                Divider()
                    .background(Color.axBorder)
                    .padding(.horizontal, AXSpacing.xl)
                
                // Server Identity Section
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Server Identity")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.lg)
                    
                    VStack(spacing: AXSpacing.md) {
                        // Name
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Server Name")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            TextField("Server Name", text: $name)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .padding(AXSpacing.md)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                        }
                        
                        // Icon Picker
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Icon")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AXSpacing.sm) {
                                    ForEach(ServerIcon.allCases) { icon in
                                        Button {
                                            selectedIcon = icon
                                        } label: {
                                            Image(systemName: icon.rawValue)
                                                .font(.system(size: 18))
                                                .foregroundColor(selectedIcon == icon ? .white : .axTextSecondary)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                        .fill(selectedIcon == icon ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Color")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            HStack(spacing: AXSpacing.sm) {
                                ForEach(ServerColor.allCases) { color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: color.rawValue))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                            )
                                            .overlay {
                                                if selectedColor == color {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Tags (optional)")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            TextField("production, web, database", text: $tagsText)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .padding(AXSpacing.md)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                        }
                    }
                    .padding(AXSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, AXSpacing.lg)
                }
                
                // Connection Details Section
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Connection Details")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.lg)
                    
                    VStack(spacing: AXSpacing.md) {
                        // Host
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("Host")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextMuted)
                            TextField("server.example.com", text: $host)
                                .font(AXTypography.body)
                                .foregroundColor(.axTextPrimary)
                                .padding(AXSpacing.md)
                                .background(Color.axSurface)
                                .cornerRadius(AXCornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                        .stroke(Color.axBorder, lineWidth: 1)
                                )
                        }
                        
                        HStack(spacing: AXSpacing.md) {
                            // Port
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                Text("Port")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                TextField("22", text: $port)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                    .padding(AXSpacing.md)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                                    .frame(maxWidth: 100)
                            }
                            
                            // Username
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                Text("Username")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                TextField("root", text: $username)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                    .padding(AXSpacing.md)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(AXSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, AXSpacing.lg)
                }
                
                // Authentication Section
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text("Authentication")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.lg)
                    
                    VStack(spacing: AXSpacing.md) {
                        // Auth Type Picker
                        HStack(spacing: AXSpacing.sm) {
                            ForEach([AuthenticationType.password, .privateKey], id: \.self) { type in
                                Button {
                                    authType = type
                                } label: {
                                    HStack(spacing: AXSpacing.xs) {
                                        Image(systemName: type == .password ? "lock.fill" : "key.fill")
                                            .font(.system(size: 12))
                                        Text(type == .password ? "Password" : "Private Key")
                                            .font(AXTypography.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(authType == type ? .white : .axTextSecondary)
                                    .padding(.horizontal, AXSpacing.md)
                                    .padding(.vertical, AXSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .fill(authType == type ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Auth Fields
                        if authType == .password {
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                Text("Password")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                SecureField("Enter SSH password", text: $password)
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextPrimary)
                                    .padding(AXSpacing.md)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                            }
                        } else {
                            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                                Text("Private Key")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                                TextEditor(text: $privateKey)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .frame(minHeight: 100)
                                    .padding(AXSpacing.md)
                                    .background(Color.axSurface)
                                    .cornerRadius(AXCornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                                
                                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                    Text("Key Passphrase (optional)")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextMuted)
                                    SecureField("Optional passphrase", text: $keyPassphrase)
                                        .font(AXTypography.body)
                                        .foregroundColor(.axTextPrimary)
                                        .padding(AXSpacing.md)
                                        .background(Color.axSurface)
                                        .cornerRadius(AXCornerRadius.md)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .stroke(Color.axBorder, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .padding(AXSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                            .fill(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, AXSpacing.lg)
                }
                
                // Action Buttons
                HStack(spacing: AXSpacing.md) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(AXTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.axTextPrimary)
                            .padding(.horizontal, AXSpacing.xl)
                            .padding(.vertical, AXSpacing.md)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        let request = AddServerRequest(
                            name: name,
                            host: host,
                            port: Int(port) ?? 22,
                            username: username,
                            authType: authType,
                            password: password.isEmpty ? nil : password,
                            privateKey: privateKey.isEmpty ? nil : privateKey,
                            keyPassphrase: keyPassphrase.isEmpty ? nil : keyPassphrase,
                            tags: tagsText.isEmpty ? [] : tagsText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                            notes: nil,
                            iconName: selectedIcon.rawValue,
                            customColor: selectedColor.rawValue
                        )
                        onSave(request)
                        dismiss()
                    } label: {
                        Text("Save Changes")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .padding(.horizontal, AXSpacing.xl)
                            .padding(.vertical, AXSpacing.md)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                    .disabled(name.isEmpty || host.isEmpty || username.isEmpty)
                }
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.lg)
                
                Spacer(minLength: AXSpacing.xl)
            }
            .background(Color.axBackground)
        }
        .background(Color.axBackground)
        .preferredColorScheme(.dark)
        .onAppear {
            name = server.name
            host = server.host
            port = String(server.port)
            username = server.username
            tagsText = server.tags.joined(separator: ", ")
            selectedIcon = ServerIcon(rawValue: server.iconName) ?? .serverRack
            if let hex = server.customColor {
                selectedColor = ServerColor(rawValue: hex) ?? .blue
            }
        }
    }
}

#Preview {
    RemoteFleetView(
        viewModel: ServerListViewModel(),
        selectedServer: .constant(nil),
        showAddServer: .constant(false),
        showServerDashboard: .constant(false)
    )
    .frame(width: 1200, height: 800)
    .background(Color.axBackground)
}


struct RemoteFleetView: View {
    @ObservedObject var viewModel: ServerListViewModel
    @Binding var selectedServer: Server?
    @Binding var showAddServer: Bool
    @Binding var showServerDashboard: Bool
    
    @State private var searchText = ""
    @State private var selectedFilter: ServerEnvironment? = nil
    @State private var viewMode: ServerViewMode = .grid
    @State private var sortOption: ServerSortOption = .nameAsc
    @State private var serverToEdit: ServerViewModel?
    @State private var showEditServer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AXSpacing.xl) {
                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text("Remote Fleet")
                            .font(AXTypography.largeTitle)
                            .foregroundColor(.axTextPrimary)
                        
                        if !viewModel.isLoading {
                            Text("\(viewModel.decryptedServers.filter { isServerOnline($0) }.count) of \(viewModel.decryptedServers.count) servers online")
                                .font(AXTypography.callout)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Add Server Button - Fully Functional
                    Button(action: {
                        showAddServer = true
                    }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "plus")
                            Text("Add Server")
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .background(viewModel.canAddServer ? Color.axAccentBlue : Color.axTextMuted)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!viewModel.canAddServer)
                }
                
                // Search, Filter, Sort, and View Mode Bar
                HStack(spacing: AXSpacing.md) {
                    // Search
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.axTextMuted)
                        
                        TextField("Search servers...", text: $searchText)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.md)
                    .background(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .cornerRadius(AXCornerRadius.md)
                    .frame(width: 240)
                    
                    // Type Filters
                    HStack(spacing: AXSpacing.sm) {
                        FilterPill(
                            title: "All",
                            isSelected: selectedFilter == nil,
                            action: { selectedFilter = nil }
                        )
                        
                        FilterPill(
                            title: "Production",
                            isSelected: selectedFilter == .production,
                            action: { selectedFilter = .production }
                        )
                        
                        FilterPill(
                            title: "Staging",
                            isSelected: selectedFilter == .staging,
                            action: { selectedFilter = .staging }
                        )
                        
                        FilterPill(
                            title: "Development",
                            isSelected: selectedFilter == .development,
                            action: { selectedFilter = .development }
                        )
                    }
                    
                    Spacer()
                    
                    // Sort Menu
                    Menu {
                        ForEach([ServerSortOption.nameAsc, .nameDesc, .dateAdded, .status], id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                HStack {
                                    Image(systemName: option.icon)
                                    Text(option.label)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort")
                        }
                        .font(AXTypography.subheadline)
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
                    
                    // View Mode Toggle
                    HStack(spacing: AXSpacing.xs) {
                        Button(action: { viewMode = .grid }) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 14))
                                .foregroundColor(viewMode == .grid ? .axBackground : .axTextSecondary)
                                .frame(width: 32, height: 32)
                                .background(viewMode == .grid ? Color.axAccentBlue : Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { viewMode = .list }) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 14))
                                .foregroundColor(viewMode == .list ? .axBackground : .axTextSecondary)
                                .frame(width: 32, height: 32)
                                .background(viewMode == .list ? Color.axAccentBlue : Color.axSurface)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .cornerRadius(AXCornerRadius.md)
                    
                    // Refresh Button
                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 36, height: 36)
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
            .padding(AXSpacing.xxl)
            .background(Color.axBackground)
            
            Divider()
                .background(Color.axBorder)
            
            // Server Content
            if viewModel.isLoading && viewModel.decryptedServers.isEmpty {
                LoadingServersView()
            } else if viewModel.decryptedServers.isEmpty {
                RemoteFleetEmptyStateView(showAddServer: $showAddServer)
            } else {
                ScrollView {
                    if viewMode == .grid {
                        RemoteFleetGridView(
                            servers: filteredServers,
                            selectedServer: $selectedServer,
                            showServerDashboard: $showServerDashboard,
                            viewModel: viewModel,
                            onConnect: { server in
                                print("[RemoteFleet] Connect requested for server: \(server.name)")
                                
                                // Create full Server model with the SAME ID used for connection
                                let serverUUID = UUID(uuidString: server.id) ?? UUID()
                                let fullServer = Server(
                                    id: serverUUID,
                                    name: server.name,
                                    host: server.host,
                                    port: server.port,
                                    username: server.username,
                                    status: server.isAccessible ? .online : .offline,
                                    type: .remote,
                                    tags: server.tags,
                                    lastConnected: nil,
                                    os: server.osType,
                                    location: server.location,
                                    cpuUsage: nil,
                                    memoryUsage: nil,
                                    diskUsage: nil,
                                    uptime: nil
                                )
                                
                                // Store the server and open dashboard immediately
                                // Connection will happen in ServerDashboardView
                                selectedServer = fullServer
                                showServerDashboard = true
                                
                                print("[RemoteFleet] Opening dashboard for: \(server.name)")
                            },
                            onEdit: { server in
                                serverToEdit = server
                                showEditServer = true
                            },
                            onDelete: { server in
                                Task {
                                    await viewModel.deleteServer(id: server.id)
                                }
                            }
                        )
                    } else {
                        RemoteFleetListView(
                            servers: filteredServers,
                            selectedServer: $selectedServer,
                            showServerDashboard: $showServerDashboard,
                            viewModel: viewModel,
                            onConnect: { server in
                                print("[RemoteFleet] Connect requested for server (List): \(server.name)")
                                
                                // Create full Server model with the SAME ID used for connection
                                let serverUUID = UUID(uuidString: server.id) ?? UUID()
                                let fullServer = Server(
                                    id: serverUUID,
                                    name: server.name,
                                    host: server.host,
                                    port: server.port,
                                    username: server.username,
                                    status: server.isAccessible ? .online : .offline,
                                    type: .remote,
                                    tags: server.tags,
                                    lastConnected: nil,
                                    os: server.osType,
                                    location: server.location,
                                    cpuUsage: nil,
                                    memoryUsage: nil,
                                    diskUsage: nil,
                                    uptime: nil
                                )
                                
                                // Store the server and open dashboard immediately
                                // Connection will happen in ServerDashboardView
                                selectedServer = fullServer
                                showServerDashboard = true
                                
                                print("[RemoteFleet] Opening dashboard for: \(server.name) (List)")
                            }
                        )
                    }
                }
                .background(Color.axBackground)
            }
        }
        .background(Color.axBackground)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .task {
            // Initialize in background with proper actor isolation
            await viewModel.initialize()
        }
        .sheet(isPresented: $showEditServer) {
            if let server = serverToEdit {
                EditServerView(server: server) { updatedRequest in
                    Task {
                        // For now, just show a placeholder - full implementation would update the server
                        await viewModel.deleteServer(id: server.id)
                        await viewModel.addServer(updatedRequest)
                    }
                }
            }
        }
        // Decryption error dialog
        .sheet(isPresented: $viewModel.showDecryptionError) {
            DecryptionErrorView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        // Note: Connection popup removed - connection now happens in ServerDashboardView
    }
    
    private var filteredServers: [ServerViewModel] {
        let filtered = viewModel.decryptedServers.filter { server in
            let matchesSearch = searchText.isEmpty ||
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.host.localizedCaseInsensitiveContains(searchText) ||
                server.username.localizedCaseInsensitiveContains(searchText)
            
            // Environment filter matches if server tags contain the filter value
            let matchesFilter = selectedFilter == nil || 
                server.tags.contains(where: { $0.localizedCaseInsensitiveContains(selectedFilter?.rawValue ?? "") })
            
            return matchesSearch && matchesFilter
        }
        
        return filtered.sorted { s1, s2 in
            switch sortOption {
            case .nameAsc:
                return s1.name < s2.name
            case .nameDesc:
                return s1.name > s2.name
            case .dateAdded:
                return s1.createdAt > s2.createdAt
            case .status:
                return s1.isAccessible != s2.isAccessible
            }
        }
    }
    
    private func isServerOnline(_ server: ServerViewModel) -> Bool {
        return server.isAccessible
    }
}

// MARK: - Loading View
struct LoadingServersView: View {
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading servers...")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }
}

// MARK: - Empty State View
struct RemoteFleetEmptyStateView: View {
    @Binding var showAddServer: Bool
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)
            
            Text("No Servers Yet")
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)
            
            Text("Add your first server to get started")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
            
            Button(action: {
                showAddServer = true
            }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Server")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.md)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }
}

// MARK: - Grid View
struct RemoteFleetGridView: View {
    let servers: [ServerViewModel]
    @Binding var selectedServer: Server?
    @Binding var showServerDashboard: Bool
    @ObservedObject var viewModel: ServerListViewModel
    let onConnect: (ServerViewModel) -> Void
    let onEdit: (ServerViewModel) -> Void
    let onDelete: (ServerViewModel) -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AXSpacing.md),
            GridItem(.flexible(), spacing: AXSpacing.md),
            GridItem(.flexible(), spacing: AXSpacing.md)
        ], spacing: AXSpacing.md) {
            ForEach(servers) { server in
                RemoteServerCard(
                    server: server,
                    connectionProgress: viewModel.connectionProgress[server.id],
                    onTap: {
                        print("[RemoteFleetGridView] Card tapped for: \(server.name)")
                        onConnect(server)
                    },
                    onConnect: {
                        print("[RemoteFleetGridView] Connect tapped for: \(server.name)")
                        onConnect(server)
                    },
                    onEdit: { onEdit(server) },
                    onDelete: { onDelete(server) }
                )
            }
        }
        .padding(AXSpacing.lg)
    }
    
    private func navigateToServer(_ server: ServerViewModel) async {
        print("[RemoteFleet] navigateToServer called for: \(server.name)")
        
        // Create full Server model from decrypted info
        let fullServer = Server(
            name: server.name,
            host: server.host,
            port: server.port,
            username: server.username,
            status: server.isAccessible ? .online : .offline,
            type: .remote,
            tags: server.tags,
            lastConnected: nil,
            os: server.osType,
            location: server.location,
            cpuUsage: nil,
            memoryUsage: nil,
            diskUsage: nil,
            uptime: nil
        )
        
        print("[RemoteFleet] Created Server model: id=\(fullServer.id), name=\(fullServer.name)")
        
        await MainActor.run {
            print("[RemoteFleet] Setting selectedServer and showServerDashboard=true")
            selectedServer = fullServer
            showServerDashboard = true
            print("[RemoteFleet] showServerDashboard is now: \(showServerDashboard)")
        }
    }
}

// MARK: - List View
struct RemoteFleetListView: View {
    let servers: [ServerViewModel]
    @Binding var selectedServer: Server?
    @Binding var showServerDashboard: Bool
    @ObservedObject var viewModel: ServerListViewModel
    let onConnect: (ServerViewModel) -> Void
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(servers.enumerated()), id: \.element.id) { index, server in
                RemoteServerRow(
                    server: server,
                    connectionProgress: viewModel.connectionProgress[server.id],
                    onTap: {
                        print("[RemoteFleetListView] Row tapped for: \(server.name)")
                        onConnect(server)
                    },
                    onConnect: {
                        print("[RemoteFleetListView] Connect tapped for: \(server.name)")
                        onConnect(server)
                    }
                )
                
                if index < servers.count - 1 {
                    Divider()
                        .background(Color.axBorder.opacity(0.5))
                        .padding(.horizontal, AXSpacing.xxl)
                }
            }
        }
        .padding(.vertical, AXSpacing.lg)
    }
    
    private func navigateToServer(_ server: ServerViewModel) async {
        let fullServer = Server(
            name: server.name,
            host: server.host,
            port: server.port,
            username: server.username,
            status: server.isAccessible ? .online : .offline,
            type: .remote,
            tags: server.tags,
            lastConnected: nil,
            os: server.osType,
            location: server.location,
            cpuUsage: nil,
            memoryUsage: nil,
            diskUsage: nil,
            uptime: nil
        )
        
        await MainActor.run {
            selectedServer = fullServer
            showServerDashboard = true
        }
    }
}

// MARK: - Server Card (Grid View)
struct RemoteServerCard: View {
    let server: ServerViewModel
    let connectionProgress: ConnectionProgress?
    let onTap: () -> Void
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var showContextMenu = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                // Header Row
                HStack(spacing: AXSpacing.md) {
                    // Server Icon with Status Glow
                    ZStack {
                        // Status glow ring
                        if server.isAccessible {
                            Circle()
                                .stroke(Color.axSuccess.opacity(0.4), lineWidth: 2)
                                .frame(width: 52, height: 52)
                                .blur(radius: 2)
                        }
                        
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [customColor.opacity(0.2), customColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: server.iconName)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(customColor)
                    }
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text(server.name)
                            .font(AXTypography.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)
                        
                        Text(server.host)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    AXStatusBadge(
                        status: server.isAccessible ? .online : .offline,
                        showLabel: true,
                        size: 6
                    )
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
                
                // Server Details Row
                HStack(spacing: AXSpacing.lg) {
                    // OS Info
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: osIcon)
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                        Text(server.osType ?? "Linux")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    // User
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                        Text(server.username)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    // Location (if available)
                    if let location = server.location {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                                .foregroundColor(.axTextMuted)
                            Text(location)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
                
                // Tags Row
                if !server.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AXSpacing.xs) {
                            ForEach(server.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axAccentBlue)
                                    .padding(.horizontal, AXSpacing.sm)
                                    .padding(.vertical, AXSpacing.xxs)
                                    .background(Color.axAccentBlue.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.full)
                            }
                            
                            if server.tags.count > 3 {
                                Text("+\(server.tags.count - 3)")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axTextMuted)
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.lg)
            
            // Action Footer
            HStack(spacing: AXSpacing.sm) {
                // Connect Button (Primary)
                Button(action: {
                    print("[RemoteServerCard] Connect button tapped for: \(server.name)")
                    onConnect()
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                        Text("Connect")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(
                        LinearGradient(
                            colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
                
                // Context Menu Button
                Menu {
                    Button(action: onEdit) {
                        Label("Edit Server", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        // Duplicate action
                    }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 36, height: 32)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.bottom, AXSpacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(Color.axGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: isHovered 
                            ? [customColor.opacity(0.5), Color.axAccentGreen.opacity(0.3)]
                            : [Color.axGlassBorder, Color.axBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .shadow(color: isHovered ? customColor.opacity(0.15) : .clear, radius: 20, y: 8)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private var customColor: Color {
        if let hex = server.customColor {
            return Color(hex: hex)
        }
        return .axAccentBlue
    }
    
    private var osIcon: String {
        let os = server.osType?.lowercased() ?? ""
        if os.contains("ubuntu") || os.contains("debian") || os.contains("linux") {
            return "terminal"
        } else if os.contains("windows") {
            return "desktopcomputer"
        } else if os.contains("mac") || os.contains("darwin") {
            return "apple.terminal"
        }
        return "server.rack"
    }
    
    private var statusColor: Color {
        server.isAccessible ? .axSuccess : .axTextMuted
    }
    
    private var statusText: String {
        server.isAccessible ? "Online" : "Offline"
    }
}

// MARK: - Server Row (List View)
struct RemoteServerRow: View {
    let server: ServerViewModel
    let connectionProgress: ConnectionProgress?
    let onTap: () -> Void
    let onConnect: () -> Void
    
    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            // Server Icon
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(customColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: server.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(customColor)
            }
            
            // Server Info
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(server.name)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
                
                HStack(spacing: AXSpacing.sm) {
                    Text("\(server.username)@\(server.host)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                    
                    // Status
                    HStack(spacing: AXSpacing.xs) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(statusText)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    // Access Level
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: accessLevelIcon)
                            .font(.caption2)
                        Text(accessLevelText)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Created Date
            Text(formattedDate(server.createdAt))
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            
            // Connect Button
            Button(action: {
                print("[RemoteServerRow] Connect button tapped for: \(server.name)")
                onConnect()
            }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("Connect")
                        .font(AXTypography.caption2)
                }
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
            
            // Actions Menu
            Menu {
                Button(action: {
                    print("[RemoteServerRow] Menu Connect tapped for: \(server.name)")
                    onConnect()
                }) {
                    Label("Connect", systemImage: "bolt.fill")
                }
                
                if server.accessLevel == .full {
                    Divider()
                    
                    Button(role: .destructive, action: {}) {
                        Label("Delete Server", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.vertical, AXSpacing.md)
        .contentShape(Rectangle())
    }
    
    private var customColor: Color {
        if let hex = server.customColor {
            return Color(hex: hex)
        }
        return .axAccentBlue
    }
    
    private var statusColor: Color {
        server.isAccessible ? .axSuccess : .axTextMuted
    }
    
    private var statusText: String {
        server.isAccessible ? "Online" : "Offline"
    }
    
    private var accessLevelIcon: String {
        switch server.accessLevel {
        case .full: return "lock.open"
        case .readOnly: return "eye"
        case .none: return "lock"
        }
    }
    
    private var accessLevelText: String {
        switch server.accessLevel {
        case .full: return "Full"
        case .readOnly: return "Read"
        case .none: return "None"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
