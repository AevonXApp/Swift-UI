//
//  WebsiteDetailView.swift
//  AevonX
//
//  Completely redesigned website management interface with modern control panel UI
//

import SwiftUI
import AevonXCore

struct WebsiteDetailView: View {
    @StateObject private var viewModel: WebsiteDetailViewModel
    let onBack: () -> Void
    let initialItem: ModernSidebarItem

    init(website: WebsiteInfo, serverId: String?, onBack: @escaping () -> Void, initialTab: Int = 0) {
        self._viewModel = StateObject(wrappedValue: WebsiteDetailViewModel(website: website, serverId: serverId))
        self.onBack = onBack

        // Map legacy Int tab index to ModernSidebarItem
        let allItems = Array(ModernSidebarItem.allCases)
        if initialTab >= 0, initialTab < allItems.count {
            self.initialItem = allItems[initialTab]
        } else {
            self.initialItem = .overview
        }
    }

    var body: some View {
        ModernWebsitePanel(viewModel: viewModel, onBack: onBack, initialItem: initialItem)
            .background(Color.axBackground)
            .task {
                await viewModel.loadAllSections()
            }
            .onDisappear {
                viewModel.stopMonitoring()
            }
    }
}
