
import SwiftUI
import AevonXCore

struct DockerVolumesTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    
    @State private var volumes: [DockerVolume] = []
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var errorMessage: String?
    @State private var actionInProgress: String?
    @State private var showCreateSheet: Bool = false
    
    // Filtered volumes
    var filteredVolumes: [DockerVolume] {
        if searchText.isEmpty {
            return volumes
        }
        return volumes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.driver.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.md) {
            // Toolbar
            HStack {
                // Search
                AXSearchBar(text: $searchText, placeholder: "Search volumes...")
                    .frame(maxWidth: 300)
                
                Spacer()
                
                // Create Volume Button
                Button(action: { showCreateSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Create Volume")
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
                AXCard {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.axError)
                        Text(error)
                            .foregroundColor(.axError)
                        Spacer()
                        Button(action: { errorMessage = nil }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
            }
            
            // Volumes List
            if isLoading && volumes.isEmpty {
                AXLoadingState(message: "Loading volumes...")
            } else if filteredVolumes.isEmpty {
                AXPlaceholder(
                    icon: "internaldrive",
                    title: "No volumes found"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AXSpacing.sm) {
                        ForEach(filteredVolumes) { volume in
                            VolumeRow(
                                volume: volume,
                                isActionInProgress: actionInProgress == volume.name,
                                onRemove: {
                                    handleRemoveVolume(name: volume.name)
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
            CreateVolumeSheet(isOpen: $showCreateSheet) { name, driver in
                handleCreateVolume(name: name, driver: driver)
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                volumes = try await DockerManager.shared.getVolumes(serverId: serverId)
            } catch {
                errorMessage = "Failed to fetch volumes: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func handleRemoveVolume(name: String) {
        guard actionInProgress == nil else { return }
        actionInProgress = name
        
        Task {
            do {
                try await DockerManager.shared.removeVolume(name: name, force: false, serverId: serverId)
                
                // Refresh
                try await Task.sleep(nanoseconds: 500_000_000)
                refreshData() // Removed await
                
            } catch {
                errorMessage = "Failed to remove volume: \(error.localizedDescription)"
            }
            actionInProgress = nil
        }
    }
    
    private func handleCreateVolume(name: String, driver: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await DockerManager.shared.createVolume(name: name, driver: driver, serverId: serverId)
                refreshData() // Removed await
            } catch {
                errorMessage = "Failed to create volume: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - Subviews

private struct VolumeRow: View {
    let volume: DockerVolume
    let isActionInProgress: Bool
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        AXCard {
            HStack(spacing: AXSpacing.md) {
                // Icon
                Image(systemName: "internaldrive")
                    .font(.system(size: 18))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(volume.name)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    HStack(spacing: AXSpacing.sm) {
                        Text(volume.driver)
                            .font(AXTypography.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.axSurface)
                            .foregroundColor(.axTextSecondary)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.axBorder, lineWidth: 0.5))
                        
                        Text(volume.mountpoint)
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
                    .help("Remove Volume")
                }
            }
        }
    }
}

private struct CreateVolumeSheet: View {
    @Binding var isOpen: Bool
    let onCreate: (String, String) -> Void
    
    @State private var volumeName: String = ""
    @State private var driver: String = "local"
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Text("Create Volume")
                .font(AXTypography.title3)
                .foregroundColor(.axTextPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Volume Name")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                TextField("my-volume", text: $volumeName)
                    .textFieldStyle(AXTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Driver")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                
                TextField("local", text: $driver)
                    .textFieldStyle(AXTextFieldStyle())
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
                    if !volumeName.isEmpty {
                        onCreate(volumeName, driver)
                        isOpen = false
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(!volumeName.isEmpty ? Color.axAccentBlue : Color.axSurface)
                .foregroundColor(.white)
                .cornerRadius(AXCornerRadius.sm)
                .disabled(volumeName.isEmpty)
                .opacity(volumeName.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 400)
        .background(Color.axBackground)
    }
}
