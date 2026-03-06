//
//  NginxDetailView.swift
//  AevonX
//

import SwiftUI
import AevonXCore

@MainActor
struct NginxDetailView: View {

    let application: ApplicationInstance
    let serverId: String
    let onBack: (() -> Void)?

    @StateObject private var viewModel: NginxDetailViewModel

    init(application: ApplicationInstance, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.serverId = serverId
        self.onBack = onBack
        self._viewModel = StateObject(wrappedValue: NginxDetailViewModel(application: application, serverId: serverId))
    }

    var body: some View {
        ServiceDetailContainer(
            application: application,
            brandColor: Color(hex: "#009639"),
            logoName: "nginx-logo",
            selectedSection: $viewModel.selectedSection,
            sections: NginxSection.allCases.map { $0 },
            isLoading: viewModel.isLoading,
            loadingMessage: "Syncing Nginx Data…",
            onBack: onBack,
            onControl: { action in
                Task { await viewModel.controlService(action: action) }
            }
        ) {
            contentForSection
        }
        .task {
            await viewModel.loadData()
        }
    }

    @ViewBuilder
    private var contentForSection: some View {
        switch viewModel.selectedSection {
        case .overview:
            NginxOverviewTab(
                application: application,
                nginxConfig: $viewModel.nginxConfig,
                onReload: { Task { await viewModel.reloadService() } },
                onTest: { Task { await viewModel.testConfiguration() } }
            )
        case .configuration:
            NginxConfigurationTab(application: application, nginxConfig: $viewModel.nginxConfig, onSave: viewModel.saveConfiguration)
        case .ports:
            NginxPortsTab(application: application, nginxConfig: $viewModel.nginxConfig, onSave: viewModel.savePort)
        case .security:
            NginxSecurityTab(application: application, nginxConfig: $viewModel.nginxConfig, onBlock: viewModel.blockIP, onUnblock: viewModel.unblockIP)
        case .logs:
            AXAdvancedLogsView(
                source: AXLogSource.nginxService,
                serverId: serverId,
                onSuccess: { msg in GlobalToastManager.shared.showSuccess(msg) },
                onError: { msg in GlobalToastManager.shared.showError(msg) }
            )
        case .versions:
            NginxVersionsTab(application: application, serverId: serverId)
        }
    }
}
