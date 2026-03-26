//
//  RemoteFleetView.swift
//
//  Aevon Remote Fleet UI - Refactored for maximum modularity
//

import SwiftUI
import UniformTypeIdentifiers
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
    @AppStorage(SettingsKey.defaultViewMode) private var viewMode: ServerViewMode = .grid
    @AppStorage(SettingsKey.defaultSortOption) private var sortOption: ServerSortOption = .nameAsc
    @AppStorage("settings.serverList.lastFilter") private var lastFilter: String = ""
    @State private var serverToEdit: ServerViewModel?
    @State private var showEditServer = false
    @State private var showPaywall = false
    @State private var showLaunchWizard = false
    @State private var launchTargetServer: Server?
    @State private var launchLocalPath: String?
    @State private var isDraggingFolder = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header & Filter Section
            VStack(spacing: AXSpacing.lg) {
                RemoteFleetHeader(viewModel: viewModel, showAddServer: $showAddServer, showPaywall: $showPaywall, onLaunch: {
                    showLaunchWizard = true
                })
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
                if !viewModel.isAuthenticated && !viewModel.isLoading {
                    // Not logged in — show sign-in prompt
                    VStack(spacing: AXSpacing.xl) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.axTextMuted)

                        Text("Sign In Required")
                            .font(AXTypography.title2)
                            .foregroundColor(.axTextPrimary)

                        Text("Sign in or create an account to manage your servers")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.isLoading && viewModel.decryptedServers.isEmpty {
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

            // Restore last filter if setting enabled
            if AppSettingsManager.shared.rememberLastFilter, !lastFilter.isEmpty {
                selectedFilter = ServerStatusFilter(rawValue: lastFilter)
            }

            // Reset sort to default if rememberLastSort is disabled
            if !AppSettingsManager.shared.rememberLastSort {
                sortOption = .nameAsc
            }
        }
        .onChange(of: selectedFilter) { _, newValue in
            if AppSettingsManager.shared.rememberLastFilter {
                lastFilter = newValue?.rawValue ?? ""
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .overlay {
            if showPaywall {
                FeaturePaywallView(
                    featureTitle: "Unlock Server Management",
                    featureDescription: "You've reached the server limit for your plan. Upgrade to Pro for unlimited servers and more.",
                    isPresented: $showPaywall
                )
            }
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
        .sheet(isPresented: $showLaunchWizard) {
            if let server = launchTargetServer {
                AXLaunchWizardView(server: server, localPath: launchLocalPath)
                    .frame(minWidth: 600, minHeight: 560)
            } else if let first = filteredServers.first {
                AXLaunchWizardView(
                    server: serverViewModelToServer(first),
                    localPath: launchLocalPath
                )
                .frame(minWidth: 600, minHeight: 560)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDraggingFolder) { providers in
            handleFolderDrop(providers)
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
                    onEdit: { server in authenticatedEdit(server) },
                    onDelete: { server in authenticatedDelete(server) }
                )
            } else {
                RemoteFleetListView(
                    servers: filteredServers,
                    selectedServer: $selectedServer,
                    showServerDashboard: $showServerDashboard,
                    viewModel: viewModel,
                    onConnect: navigateToServer,
                    onEdit: { server in authenticatedEdit(server) },
                    onDelete: { server in authenticatedDelete(server) }
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

    // MARK: - Auth-Gated Actions

    private func authenticatedEdit(_ server: ServerViewModel) {
        Task {
            if AppSettingsManager.shared.requireAuthOnEdit {
                do {
                    try await BiometricAuthManager.shared.authenticateIfNeeded(reason: "Authenticate to edit server")
                } catch { return }
            }
            serverToEdit = server
            showEditServer = true
        }
    }

    private func authenticatedDelete(_ server: ServerViewModel) {
        Task {
            if AppSettingsManager.shared.requireAuthOnDelete {
                do {
                    try await BiometricAuthManager.shared.authenticateIfNeeded(reason: "Authenticate to delete server")
                } catch { return }
            }
            await viewModel.deleteServer(id: server.id)
        }
    }

    private func serverViewModelToServer(_ server: ServerViewModel) -> Server {
        Server(
            id: UUID(uuidString: server.id) ?? UUID(),
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
            iconName: server.iconName,
            customColor: server.customColor ?? "#007AFF"
        )
    }

    private func handleFolderDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.hasDirectoryPath else { return }
            DispatchQueue.main.async {
                launchLocalPath = url.path
                showLaunchWizard = true
            }
        }
        return true
    }

    private func openLaunchForServer(_ server: ServerViewModel) {
        launchTargetServer = serverViewModelToServer(server)
        launchLocalPath = nil
        showLaunchWizard = true
    }

    private func navigateToServer(_ server: ServerViewModel) {
        selectedServer = serverViewModelToServer(server)
        showServerDashboard = true
    }
}
