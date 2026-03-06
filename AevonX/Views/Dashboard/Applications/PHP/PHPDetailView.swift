//
//  PHPDetailView.swift
//  AevonX
//

import SwiftUI
import AevonXCore

@MainActor
struct PHPDetailView: View {
    let application: ApplicationInstance
    let serverId: String
    let onBack: (() -> Void)?

    @StateObject private var viewModel: PHPDetailViewModel

    init(application: ApplicationInstance, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.serverId = serverId
        self.onBack = onBack
        self._viewModel = StateObject(wrappedValue: PHPDetailViewModel(application: application, serverId: serverId))
    }

    var body: some View {
        ServiceDetailContainer(
            application: application,
            brandColor: Color(hex: "#777BB4"),
            logoName: "php-logo",
            selectedSection: $viewModel.selectedSection,
            sections: PHPSection.allCases.map { $0 },
            isLoading: viewModel.isLoading,
            loadingMessage: "Syncing PHP Data…",
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
            PHPOverviewTab(
                application: application,
                phpConfig: $viewModel.phpConfig,
                onReload: { Task { await viewModel.reloadService() } },
                onTest: { Task { await viewModel.testConfiguration() } },
                serverId: serverId
            )
        case .extensions:
            PHPExtensionsTab(application: application, phpConfig: $viewModel.phpConfig, serverId: serverId)
        case .configuration:
            PHPConfigurationTab(application: application, phpConfig: $viewModel.phpConfig, onSave: viewModel.saveConfiguration)
        case .disabledFunctions:
            PHPDisabledFunctionsTab(application: application, phpConfig: $viewModel.phpConfig, serverId: serverId)
        case .fpmPools:
            PHPFPMPoolsTab(application: application, phpConfig: $viewModel.phpConfig, serverId: serverId)
        case .logs:
            AXAdvancedLogsView(
                source: AXLogSource.phpService,
                serverId: serverId,
                onSuccess: { msg in GlobalToastManager.shared.showSuccess(msg) },
                onError: { msg in GlobalToastManager.shared.showError(msg) }
            )
        case .versions:
            PHPVersionsTab(application: application, serverId: serverId, onRefreshAll: {
                Task { await viewModel.loadData() }
            })
        }
    }
}
