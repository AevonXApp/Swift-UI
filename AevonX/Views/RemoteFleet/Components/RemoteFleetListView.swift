//
//  RemoteFleetListView.swift
//  AevonX
//

import SwiftUI
import AevonXCore

struct RemoteFleetListView: View {
    let servers: [ServerViewModel]
    @Binding var selectedServer: Server?
    @Binding var showServerDashboard: Bool
    @ObservedObject var viewModel: ServerListViewModel
    let onConnect: (ServerViewModel) -> Void
    let onEdit: (ServerViewModel) -> Void
    let onDelete: (ServerViewModel) -> Void

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
                    },
                    onEdit: {
                        onEdit(server)
                    },
                    onDelete: {
                        onDelete(server)
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
