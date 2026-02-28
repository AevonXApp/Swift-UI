
import SwiftUI
import AevonXCore

struct DockerNetworksTab: View {
    let serverId: String
    
    @State private var networks: [DockerNetwork] = []
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var errorMessage: String?
    @State private var actionInProgress: String?
    @State private var showCreateSheet: Bool = false
    @State private var selectedNetworkForInspector: DockerNetwork?
    
    // Filtered networks
    var filteredNetworks: [DockerNetwork] {
        if searchText.isEmpty {
            return networks
        }
        return networks.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.driver.localizedCaseInsensitiveContains(searchText) ||
            $0.scope.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.md) {
            // Toolbar
            HStack {
                // Search
                AXSearchBar(text: $searchText, placeholder: "Search networks...")
                    .frame(maxWidth: 300)
                
                Spacer()
                
                // Create Network Button
                Button(action: { showCreateSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Create Network")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                
                // Refresh Button
                AXRefreshIconButton(isLoading: isLoading) {
                    refreshData()
                }
            }
            .padding(.bottom, AXSpacing.sm)
            
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.axError)
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                    Spacer()
                    Button(action: { errorMessage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.sm)
                .background(Color.axError.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
                .padding(.horizontal, AXSpacing.md)
            }
            
            // Networks List
            if isLoading && networks.isEmpty {
                AXLoadingState(message: "Loading networks...")
            } else if filteredNetworks.isEmpty {
                AXPlaceholder(
                    icon: "network",
                    title: "No networks found"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AXSpacing.sm) {
                        ForEach(filteredNetworks) { network in
                            NetworkRow(
                                network: network,
                                isActionInProgress: actionInProgress == network.networkId,
                                onRemove: {
                                    handleRemoveNetwork(id: network.networkId)
                                },
                                onInspect: {
                                    selectedNetworkForInspector = network
                                }
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            refreshData()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateNetworkSheet(isOpen: $showCreateSheet) { name, driver in
                handleCreateNetwork(name: name, driver: driver)
            }
        }
        .sheet(item: $selectedNetworkForInspector) { network in
            DockerNetworkInspector(network: network, serverId: serverId)
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                networks = try await DockerManager.shared.getNetworks(serverId: serverId)
            } catch {
                errorMessage = "Failed to fetch networks: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func handleRemoveNetwork(id: String) {
        guard actionInProgress == nil else { return }
        actionInProgress = id
        
        Task {
            do {
                try await DockerManager.shared.removeNetwork(id: id, serverId: serverId)
                
                // Refresh
                try await Task.sleep(nanoseconds: 500_000_000)
                refreshData()
                
            } catch {
                errorMessage = "Failed to remove network: \(error.localizedDescription)"
            }
            actionInProgress = nil
        }
    }
    
    private func handleCreateNetwork(name: String, driver: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await DockerManager.shared.createNetwork(name: name, driver: driver, serverId: serverId)
                refreshData()
            } catch {
                errorMessage = "Failed to create network: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - Subviews

private struct NetworkRow: View {
    let network: DockerNetwork
    let isActionInProgress: Bool
    let onRemove: () -> Void
    let onInspect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                // Icon
                Image(systemName: "network")
                    .font(.system(size: 18))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(network.name)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    HStack(spacing: 8) {
                        AXBadge(text: network.driver, color: .axAccentBlue, style: .soft)
                        AXBadge(text: network.scope, color: .axTextSecondary, style: .soft)
                        
                        if network.ipv6 {
                            AXBadge(text: "IPv6", color: .axSuccess, style: .soft)
                        }
                        if network.internalNetwork {
                            AXBadge(text: "Internal", color: .axWarning, style: .soft)
                        }
                        
                        Text(network.networkId.prefix(12))
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                            .monospaced()
                    }
                }
                
                Spacer()
                
                // Actions
                if isActionInProgress {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 32)
                } else {
                    HStack(spacing: 6) {
                        Button(action: onInspect) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.axAccentBlue)
                                .frame(width: 32, height: 32)
                                .background(Color.axSurface.opacity(0.5))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .help("Inspect Network")
                        
                        Button(action: onRemove) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(isHovered ? .axError : .axTextSecondary)
                                .frame(width: 32, height: 32)
                                .background(Color.axSurface.opacity(0.5))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .onHover { hover in isHovered = hover }
                        .help("Remove Network")
                        .disabled(isSystemNetwork(network.name))
                        .opacity(isSystemNetwork(network.name) ? 0.3 : 1.0)
                    }
                }
            }
        }
    }
    
    private func isSystemNetwork(_ name: String) -> Bool {
        return ["bridge", "host", "none"].contains(name)
    }
}



private struct CreateNetworkSheet: View {
    @Binding var isOpen: Bool
    let onCreate: (String, String) -> Void
    
    @State private var networkName: String = ""
    @State private var driver: String = "bridge"
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Text("Create Network")
                .font(AXTypography.title3)
                .foregroundColor(.axTextPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Network Name")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                TextField("my-network", text: $networkName)
                    .textFieldStyle(AXTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Driver")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                Picker("Driver", selection: $driver) {
                    Text("Bridge").tag("bridge")
                    Text("Host").tag("host")
                    Text("Overlay").tag("overlay")
                    Text("Macvlan").tag("macvlan")
                    Text("Null").tag("null")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            HStack(spacing: AXSpacing.md) {
                Button("Cancel") {
                    isOpen = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.axSurface)
                .foregroundColor(.axTextPrimary)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                
                Button("Create") {
                    if !networkName.isEmpty {
                        onCreate(networkName, driver)
                        isOpen = false
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(!networkName.isEmpty ? Color.axAccentBlue : Color.axSurface)
                .foregroundColor(.white)
                .cornerRadius(AXCornerRadius.sm)
                .disabled(networkName.isEmpty)
                .opacity(networkName.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 400)
        .background(Color.axBackground)
    }
}
