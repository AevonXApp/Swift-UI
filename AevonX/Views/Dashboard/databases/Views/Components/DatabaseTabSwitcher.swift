//
//  DatabaseTabSwitcher.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DatabaseTabSwitcher: View {
    @Binding var activeTabIndex: Int
    let availableDatabaseTypes: [DatabaseType]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.sm) {
                // All tab
                AXDatabaseTabButton(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: activeTabIndex == 0
                ) {
                    activeTabIndex = 0
                }
                
                // Individual database type tabs
                ForEach(Array(availableDatabaseTypes.enumerated()), id: \.element) { index, type in
                    AXDatabaseTabButton(
                        title: type.displayName,
                        icon: type.iconName,
                        isSelected: activeTabIndex == index + 1
                    ) {
                        activeTabIndex = index + 1
                    }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
        }
        .padding(.bottom, AXSpacing.lg)
    }
}
