//
//  DatabaseStatsBar.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DatabaseStatsBar: View {
    @ObservedObject var viewModel: DatabaseManagementViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            // Premium Stats Cards
            AXDatabaseStatCard(
                title: "Databases",
                value: "\(viewModel.totalDatabaseCount)",
                icon: "cylinder.split.1x2",
                color: .axAccentBlue
            )
            
            AXDatabaseStatCard(
                title: "Total Size",
                value: viewModel.formattedTotalSize,
                icon: "internaldrive",
                color: .axAccentGreen
            )
            
            AXDatabaseStatCard(
                title: "Users",
                value: "\(viewModel.totalUserCount)",
                icon: "person.2",
                color: .axWarning
            )
            
            AXDatabaseStatCard(
                title: "Engines",
                value: "\(viewModel.installedDatabaseTypesCount)/9",
                icon: "server.rack",
                color: .axInfo
            )
            
            Spacer()
            
            // Connection status with glow
            AXConnectionStatus(isConnected: viewModel.isConnected)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }
}
