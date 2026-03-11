//
//  DatabaseTabSwitcher.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DatabaseTabSwitcher: View {
    @Binding var activeTabIndex: Int
    let availableDatabaseTypes: [DatabaseType]
    
    private var tabs: [AXTabItem] {
        var items = [AXTabItem(label: "All", icon: "square.grid.2x2")]
        items += availableDatabaseTypes.map {
            AXTabItem(label: $0.displayName, icon: $0.iconName)
        }
        return items
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            AXTabSwitcher(tabs: tabs, selected: $activeTabIndex)
                .padding(.horizontal, AXSpacing.xl)
        }
        .padding(.bottom, AXSpacing.lg)
    }
}
