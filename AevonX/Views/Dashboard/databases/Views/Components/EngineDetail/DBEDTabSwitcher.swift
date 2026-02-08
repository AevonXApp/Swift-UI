//
//  DBEDTabSwitcher.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBEDTabSwitcher: View {
    @Binding var activeTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            AXDatabaseTabButton(title: "Overview", icon: "chart.bar", isSelected: activeTab == 0) {
                activeTab = 0
            }

            AXDatabaseTabButton(title: "Configuration", icon: "gearshape", isSelected: activeTab == 1) {
                activeTab = 1
            }

            AXDatabaseTabButton(title: "Logs", icon: "doc.text", isSelected: activeTab == 2) {
                activeTab = 2
            }

            AXDatabaseTabButton(title: "Optimization", icon: "gauge", isSelected: activeTab == 3) {
                activeTab = 3
            }

            Spacer()
        }
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
