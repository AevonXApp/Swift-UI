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

    init(website: WebsiteInfo, serverId: String?, onBack: @escaping () -> Void, initialTab: Int = 0) {
        self._viewModel = StateObject(wrappedValue: WebsiteDetailViewModel(website: website, serverId: serverId))
        self.onBack = onBack
    }

    var body: some View {
        ModernWebsitePanel(viewModel: viewModel, onBack: onBack)
            .background(Color.axBackground)
            .task {
                await viewModel.loadAllSections()
            }
    }
}
