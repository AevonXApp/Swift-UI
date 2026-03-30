//
//  ServerSettingsTab.swift
//  AevonX
//
//  Thin wrapper — delegates to ServerSettingsContentView.
//

import SwiftUI

struct ServerSettingsTab: View {
    let server: Server
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel

    var body: some View {
        ServerSettingsContentView(
            server: server,
            serverId: serverId,
            connectionViewModel: connectionViewModel
        )
    }
}

#Preview {
    ServerSettingsTab(
        server: Server.placeholder(name: "Preview"),
        serverId: "test",
        connectionViewModel: ServerConnectionViewModel(server: Server.placeholder(name: "Preview"), serverId: "test")
    )
    .background(Color.axBackground)
}
