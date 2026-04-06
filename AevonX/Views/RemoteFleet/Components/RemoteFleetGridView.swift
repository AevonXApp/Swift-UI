//
//  RemoteFleetGridView.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

struct RemoteFleetGridView: View {
    let servers: [ServerViewModel]
    @Binding var selectedServer: Server?
    @Binding var showServerDashboard: Bool
    @Binding var showPaywall: Bool
    @ObservedObject var viewModel: ServerListViewModel
    @EnvironmentObject var settings: AppSettingsManager
    let onConnect: (ServerViewModel) -> Void
    let onEdit: (ServerViewModel) -> Void
    let onDelete: (ServerViewModel) -> Void

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AXSpacing.lg), count: settings.gridColumnCount)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: AXSpacing.lg) {
            ForEach(servers) { server in
                RemoteServerCard(
                    server: server,
                    connectionProgress: viewModel.connectionProgress[server.id],
                    onTap: {
                        debugLog("[RemoteFleetGridView] Card tapped for: \(server.name)")
                        onConnect(server)
                    },
                    onConnect: {
                        debugLog("[RemoteFleetGridView] Connect tapped for: \(server.name)")
                        onConnect(server)
                    },
                    onEdit: { onEdit(server) },
                    onDelete: { onDelete(server) },
                    onUpgrade: { showPaywall = true }
                )
            }
        }
        .padding(AXSpacing.xxl)
    }
    
    private func navigateToServer(_ server: ServerViewModel) async {
        debugLog("[RemoteFleet] navigateToServer called for: \(server.name)")
        
        // Create full Server model from decrypted info
        let fullServer = Server(
            coreID: server.id,
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
        
        debugLog("[RemoteFleet] Created Server model: id=\(fullServer.id), name=\(fullServer.name)")
        
        await MainActor.run {
            debugLog("[RemoteFleet] Setting selectedServer and showServerDashboard=true")
            selectedServer = fullServer
            showServerDashboard = true
            debugLog("[RemoteFleet] showServerDashboard is now: \(showServerDashboard)")
        }
    }
}
