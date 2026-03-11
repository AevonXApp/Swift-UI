//
//  DBEDTabSwitcher.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEDTabSwitcher: View {
    @Binding var activeTab: Int
    
    private let tabs: [AXTabItem] = [
        AXTabItem(label: "Overview", icon: "chart.bar"),
        AXTabItem(label: "Configuration", icon: "gearshape"),
        AXTabItem(label: "Logs", icon: "doc.text"),
        AXTabItem(label: "Optimization", icon: "gauge")
    ]
    
    var body: some View {
        AXTabSwitcher(tabs: tabs, selected: $activeTab)
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axSurface)
            .overlay(
                Rectangle()
                    .fill(Color.axBorder)
                    .frame(height: 1),
                alignment: .bottom
            )
    }
}
