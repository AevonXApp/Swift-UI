//
//  FilesTab.swift
//  AevonX
//
//  Thin wrapper that delegates to Files/FilesView.swift
//  Kept for backward compatibility with ServerDashboardView references
//

import SwiftUI
import AevonXCore

// MARK: - Files Tab (Compatibility Wrapper)

struct FilesTab: View {
    let serverId: String
    let connectionViewModel: ServerConnectionViewModel
    
    var body: some View {
        FilesView(
            serverId: serverId,
            connectionViewModel: connectionViewModel
        )
    }
}
