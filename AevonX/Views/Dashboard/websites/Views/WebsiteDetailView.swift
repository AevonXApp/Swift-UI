//
//  WebsiteDetailView.swift
//  AevonX
//
//  Completely redesigned website management interface with modern control panel UI
//

import SwiftUI
import AevonXCoreBridge

struct WebsiteDetailView: View {
    @StateObject private var viewModel: WebsiteDetailViewModel
    let onBack: () -> Void
    let initialItem: ModernSidebarItem

    init(website: WebsiteInfo, serverId: String?, onBack: @escaping () -> Void, initialTab: Int = 0) {
        self._viewModel = StateObject(wrappedValue: WebsiteDetailViewModel(website: website, serverId: serverId))
        self.onBack = onBack

        // Map legacy Int tab index to ModernSidebarItem using runtime-aware items
        let runtimeItems = ModernSidebarItem.items(for: website.runtime)
        if initialTab >= 0, initialTab < runtimeItems.count {
            self.initialItem = runtimeItems[initialTab]
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
