//
//  RemoteFleetView.swift
//
//  Aevon Remote Fleet UI - Refactored for maximum modularity
//

import SwiftUI
import AevonXCoreBridge

enum ServerViewMode: String, CaseIterable {
    case grid
    case list
}

enum ServerStatusFilter: String, CaseIterable {
    case online = "Online"
    case offline = "Offline"
}

enum ServerSortOption: String, CaseIterable {
    case nameAsc = "name_asc"
    case nameDesc = "name_desc"
    case dateAdded = "date_added"
    case status = "status"
    
    var label: String {
        switch self {
        case .nameAsc: return "Name (A-Z)"
        case .nameDesc: return "Name (Z-A)"
        case .dateAdded: return "Date Added"
        case .status: return "Status"
        }
    }
    
    var icon: String {
        switch self {
        case .nameAsc: return "textformat.abc"
        case .nameDesc: return "textformat.abc.rtl"
        case .dateAdded: return "calendar"
        case .status: return "bolt.circle"
        }
    }
}

struct RemoteFleetView: View {
    @ObservedObject var viewModel: ServerListViewModel
    @Binding var selectedServer: Server?
    @Binding var showAddServer: Bool
    @Binding var showServerDashboard: Bool
    
    @State private var searchText = ""
    @State private var selectedFilter: ServerStatusFilter? = nil
    @State private var viewMode: ServerViewMode = .grid
    @State private var sortOption: ServerSortOption = .nameAsc
    @State private var serverToEdit: ServerViewModel?
    @State private var showEditServer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header & Filter Section
            VStack(spacing: AXSpacing.lg) {
                RemoteFleetHeader(viewModel: viewModel, showAddServer: $showAddServer)
                RemoteFleetFilterBar(
                    searchText: $searchText,
                    selectedFilter: $selectedFilter,
                    sortOption: $sortOption,
                    viewMode: $viewMode,
                    viewModel: viewModel,
                    filteredCount: filteredServers.count
                )
            }
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.vertical, AXSpacing.lg)
            .background(Color.axBackground)
            
            Divider().background(Color.axBorder)
            
            // Server Content Area
            Group {
                if viewModel.isLoading && viewModel.decryptedServers.isEmpty {
                    LoadingServersView()
                } else if viewModel.decryptedServers.isEmpty {
                    RemoteFleetEmptyStateView(showAddServer: $showAddServer)
                } else if filteredServers.isEmpty {
                    RemoteFleetNoResultsView(searchText: $searchText, selectedFilter: $selectedFilter)
                } else {
                    serverListView
                }
            }
            .background(Color.axBackground)
        }
        .task {
            // Add a small delay to ensure UI is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            await viewModel.initialize()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .sheet(item: $serverToEdit) { server in
            EditServerView(server: server) { updatedRequest in
                Task {
                    await viewModel.deleteServer(id: server.id)
                    await viewModel.addServer(updatedRequest)
                    serverToEdit = nil
                }
            }
            .frame(minWidth: 600, minHeight: 700)
        }
        .sheet(isPresented: $viewModel.showEncryptionKeyInput) {
            DecryptionErrorView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Subviews
    
    private var serverListView: some View {
        ScrollView {
            if viewMode == .grid {
                RemoteFleetGridView(
                    servers: filteredServers,
                    selectedServer: $selectedServer,
                    showServerDashboard: $showServerDashboard,
                    viewModel: viewModel,
                    onConnect: navigateToServer,
                    onEdit: { server in serverToEdit = server; showEditServer = true },
                    onDelete: { server in Task { await viewModel.deleteServer(id: server.id) } }
                )
            } else {
                RemoteFleetListView(
                    servers: filteredServers,
                    selectedServer: $selectedServer,
                    showServerDashboard: $showServerDashboard,
                    viewModel: viewModel,
                    onConnect: navigateToServer,
                    onEdit: { server in serverToEdit = server; showEditServer = true },
                    onDelete: { server in Task { await viewModel.deleteServer(id: server.id) } }
                )
            }
        }
    }
    
    // MARK: - Filtering Logic
    
    private var filteredServers: [ServerViewModel] {
        let filtered = viewModel.decryptedServers.filter { server in
            let matchesSearch = searchText.isEmpty ||
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.host.localizedCaseInsensitiveContains(searchText) ||
                server.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })

            var matchesFilter = true
            if let filter = selectedFilter {
                matchesFilter = (filter == .online) ? server.isAccessible : !server.isAccessible
            }
            return matchesSearch && matchesFilter
        }

        return filtered.sorted { s1, s2 in
            switch sortOption {
            case .nameAsc: return s1.name < s2.name
            case .nameDesc: return s1.name > s2.name
            case .dateAdded: return s1.createdAt > s2.createdAt
            case .status: return s1.isAccessible != s2.isAccessible ? s1.isAccessible : s1.name < s2.name
            }
        }
    }

    private func navigateToServer(_ server: ServerViewModel) {
        let fullServer = Server(
            id: UUID(uuidString: server.id) ?? UUID(),
            name: server.name,
            host: server.host,
            port: server.port,
            username: server.username,
            status: server.isAccessible ? .online : .offline,
            type: .remote,
            tags: server.tags,
            lastConnected: nil, // Add this
            os: server.osType,
            location: server.location,
            iconName: server.iconName, // Provide default
            customColor: server.customColor ?? "#007AFF" // Provide default
        )
        selectedServer = fullServer
        showServerDashboard = true
    }
}
