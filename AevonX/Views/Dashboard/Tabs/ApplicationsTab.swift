//
//  ApplicationsTab.swift
//  AevonX
//
//  Applications/Stack management tab — powered by Go Core.
//

import SwiftUI

struct ApplicationsTab: View {
    let server: Server?
    let serverId: String?
    let connectionViewModel: ServerConnectionViewModel?

    init(server: Server? = nil, serverId: String? = nil, connectionViewModel: ServerConnectionViewModel? = nil) {
        self.server = server
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
    }

    var body: some View {
        if let vm = connectionViewModel {
            ApplicationsMainView(
                server: server,
                serverId: serverId,
                connectionViewModel: vm
            )
        } else {
            Text(L10n.Dashboard.noConnectionAvailable)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.axBackground)
        }
    }
}
