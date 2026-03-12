//
//  ApacheDetailView.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

@MainActor
struct ApacheDetailView: View {
    let application: ApplicationInstance
    let serverId: String
    let onBack: (() -> Void)?

    @StateObject private var viewModel: ApacheDetailViewModel

    init(application: ApplicationInstance, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.serverId = serverId
        self.onBack = onBack
        self._viewModel = StateObject(wrappedValue: ApacheDetailViewModel(application: application, serverId: serverId))
    }

    var body: some View {
        ServiceDetailContainer(
            application: application,
            brandColor: Color(hex: "#D22128"),
            logoName: "apache-logo",
            selectedSection: $viewModel.selectedSection,
            sections: ApacheSection.allCases.map { $0 },
            isLoading: viewModel.isLoading,
            loadingMessage: "Syncing Apache Data…",
            onBack: onBack,
            onControl: { action in
                Task { await viewModel.controlService(action: action) }
            }
        ) {
            contentForSection
        }
        .onAppear {
            Task { await viewModel.loadData() }
        }
    }

    @ViewBuilder
    private var contentForSection: some View {
        switch viewModel.selectedSection {
        case .overview:
            ApacheOverviewTab(
                application: application,
                apacheConfig: $viewModel.apacheConfig,
                onReload: { Task { await viewModel.reloadService() } },
                onTest: { Task { await viewModel.testConfiguration() } }
            )
        case .modules:
            ApacheModulesTab(application: application, apacheConfig: $viewModel.apacheConfig, serverId: serverId)
        case .configuration:
            ApacheConfigurationTab(application: application, apacheConfig: $viewModel.apacheConfig, onSave: viewModel.saveConfiguration)
        case .virtualHosts:
            ApacheVirtualHostsTab(application: application, apacheConfig: $viewModel.apacheConfig, serverId: serverId)
        case .logs:
            AXAdvancedLogsView(
                source: AXLogSource.apacheService,
                serverId: serverId,
                onSuccess: { msg in GlobalToastManager.shared.showSuccess(msg) },
                onError: { msg in GlobalToastManager.shared.showError(msg) }
            )
        case .versions:
            ApacheVersionsTab(application: application, serverId: serverId)
        }
    }
}
