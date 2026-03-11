//
//  DatabaseStatsBar.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DatabaseStatsBar: View {
    @ObservedObject var viewModel: DatabaseManagementViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            AXStatCard(
                icon: "cylinder.split.1x2",
                label: "Databases",
                value: "\(viewModel.totalDatabaseCount)",
                color: .axAccentBlue,
                layout: .horizontal,
                style: .glass
            )
            
            AXStatCard(
                icon: "internaldrive",
                label: "Total Size",
                value: viewModel.formattedTotalSize,
                color: .axAccentGreen,
                layout: .horizontal,
                style: .glass
            )
            
            AXStatCard(
                icon: "person.2",
                label: "Users",
                value: "\(viewModel.totalUserCount)",
                color: .axWarning,
                layout: .horizontal,
                style: .glass
            )
            
            AXStatCard(
                icon: "server.rack",
                label: "Engines",
                value: "\(viewModel.installedDatabaseTypesCount)/9",
                color: .axInfo,
                layout: .horizontal,
                style: .glass
            )
            
            Spacer()
            
            AXConnectionStatusBadge(isConnected: viewModel.isConnected)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }
}
