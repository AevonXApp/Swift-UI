//
//  RemoteFleetGridView.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore

struct RemoteFleetGridView: View {
    let servers: [AevonXCore.ServerViewModel]
    @Binding var selectedServer: Server?
    @Binding var showServerDashboard: Bool
    @ObservedObject var viewModel: ServerListViewModel
    let onConnect: (AevonXCore.ServerViewModel) -> Void
    let onEdit: (AevonXCore.ServerViewModel) -> Void
    let onDelete: (AevonXCore.ServerViewModel) -> Void

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AXSpacing.lg),
            GridItem(.flexible(), spacing: AXSpacing.lg),
            GridItem(.flexible(), spacing: AXSpacing.lg)
        ], spacing: AXSpacing.lg) {
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
        .padding(AXSpacing.xxl)
    }
    
    private func navigateToServer(_ server: AevonXCore.ServerViewModel) async {
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
