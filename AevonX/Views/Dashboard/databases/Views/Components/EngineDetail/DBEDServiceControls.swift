//
//  DBEDServiceControls.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEDServiceControls: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Start
            AXActionButton(
                label: L10n.Button.start,
                icon: "play.fill",
                style: .success,
                size: .regular
            ) {
                viewModel.showStartConfirmation()
            }
            .disabled(viewModel.isRunning || viewModel.isOperationInProgress)

            // Stop
            AXActionButton(
                label: L10n.Button.stop,
                icon: "stop.fill",
                style: .destructive,
                size: .regular
            ) {
                viewModel.showStopConfirmation()
            }
            .disabled(!viewModel.isRunning || viewModel.isOperationInProgress)

            // Restart
            AXActionButton(
                label: L10n.Button.restart,
                icon: "arrow.clockwise",
                style: .warning,
                size: .regular
            ) {
                viewModel.showRestartConfirmation()
            }
            .disabled(!viewModel.isRunning || viewModel.isOperationInProgress)

            Divider()
                .frame(height: 40)

            // Enable/Disable on Boot
            AXActionButton(
                label: viewModel.isBootEnabled ? "Disable Boot" : "Enable Boot",
                icon: viewModel.isBootEnabled ? "poweroff" : "power",
                style: viewModel.isBootEnabled ? .ghost : .primary,
                size: .regular
            ) {
                Task {
                    if viewModel.isBootEnabled {
                        await viewModel.disableOnBoot()
                    } else {
                        await viewModel.enableOnBoot()
                    }
                }
            }
            .disabled(viewModel.isOperationInProgress)

            Spacer()

            // Refresh
            AXRefreshButton(isLoading: viewModel.isLoading) {
                Task { await viewModel.loadData() }
            }
            .disabled(viewModel.isOperationInProgress)
        }
    }
}
