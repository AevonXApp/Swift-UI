
import SwiftUI
import AevonXCore

struct DockerDetailView: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    
    // Internal state for Docker tabs
    @State private var selectedTab: DockerTab = .overview
    @State private var isDockerInstalled: Bool? = nil
    @State private var isCheckingInstallation = true
    
    enum DockerTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case containers = "Containers"
        case images = "Images"
        case volumes = "Volumes"
        case networks = "Networks"
        case compose = "Compose"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .containers: return "shippingbox.fill"
            case .images: return "photo.stack.fill"
            case .volumes: return "internaldrive.fill"
            case .networks: return "network"
            case .compose: return "square.stack.3d.up.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            // Docker Header / Internal Sidebar could go here if we wanted a nested layout
            // For now, let's use a horizontal tab picker or just a simple view switcher
            
            // Header with Title and Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Docker Management")
                        .font(AXTypography.title2)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(server.name)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                
                Spacer()
                
                // Docker Status Badge
                HStack(spacing: 6) {
                    if isCheckingInstallation {
                        ProgressView().controlSize(.small)
                    } else {
                        Circle()
                            .fill(isDockerInstalled == true ? Color.axSuccess : Color.axError)
                            .frame(width: 8, height: 8)
                        Text(isDockerInstalled == true ? "Engine Running" : "Not Installed")
                            .font(AXTypography.subheadline)
                            .foregroundColor(isDockerInstalled == true ? .axSuccess : .axError)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((isDockerInstalled == true ? Color.axSuccess : Color.axError).opacity(0.1))
                .cornerRadius(16)
            }
            
            // Internal Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AXSpacing.md) {
                    ForEach(DockerTab.allCases) { tab in
                        Button(action: { selectedTab = tab }) {
                            HStack(spacing: 8) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 14))
                                Text(tab.rawValue)
                                    .font(AXTypography.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == tab ? Color.axAccentBlue.opacity(0.15) : Color.axSurface)
                            )
                            .foregroundColor(selectedTab == tab ? .axAccentBlue : .axTextSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedTab == tab ? Color.axAccentBlue.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
            
            // Content
            Group {
                if isCheckingInstallation {
                    VStack {
                        Spacer()
                        ProgressView("Checking Docker installation...")
                        Spacer()
                    }
                } else if isDockerInstalled == false {
                    DockerInstallationView(serverId: serverId) {
                        checkInstallation()
                    }
                } else {
                    ScrollView {
                        switch selectedTab {
                        case .overview:
                            DockerOverviewTab(server: server, serverId: serverId, connectionViewModel: connectionViewModel) 
                        case .containers:
                            DockerContainersTab(server: server, serverId: serverId, connectionViewModel: connectionViewModel)
                        case .images:
                            DockerImagesTab(server: server, serverId: serverId, connectionViewModel: connectionViewModel)
                        case .volumes:
                            DockerVolumesTab(server: server, serverId: serverId, connectionViewModel: connectionViewModel)
                        case .networks:
                            DockerNetworksTab(serverId: serverId)
                        case .compose:
                            DockerComposeTab(serverId: serverId)
                        }
                    }
                }
            }
        }
        .onAppear {
            checkInstallation()
        }
    }
    
    private func checkInstallation() {
        isCheckingInstallation = true
        Task {
            do {
                let installed = try await DockerManager.shared.isInstalled(serverId: serverId)
                await MainActor.run {
                    self.isDockerInstalled = installed
                    self.isCheckingInstallation = false
                }
            } catch {
                await MainActor.run {
                    self.isDockerInstalled = false
                    self.isCheckingInstallation = false
                }
            }
        }
    }
}
