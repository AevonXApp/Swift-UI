//
//  DBEDServiceControls.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBEDServiceControls: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Start Button — triggers confirmation
            AXServiceControlButton(
                title: "Start",
                icon: "play.fill",
                color: .axSuccess,
                isEnabled: !viewModel.isRunning && !viewModel.isOperationInProgress
            ) {
                viewModel.showStartConfirmation()
            }

            // Stop Button — triggers confirmation
            AXServiceControlButton(
                title: "Stop",
                icon: "stop.fill",
                color: .axError,
                isEnabled: viewModel.isRunning && !viewModel.isOperationInProgress
            ) {
                viewModel.showStopConfirmation()
            }

            // Restart Button — triggers confirmation
            AXServiceControlButton(
                title: "Restart",
                icon: "arrow.clockwise",
                color: .axWarning,
                isEnabled: viewModel.isRunning && !viewModel.isOperationInProgress
            ) {
                viewModel.showRestartConfirmation()
            }

            Divider()
                .frame(height: 40)

            // Enable/Disable on Boot — based on actual boot status
            AXServiceControlButton(
                title: viewModel.isBootEnabled ? "Disable Boot" : "Enable Boot",
                icon: viewModel.isBootEnabled ? "poweroff" : "power",
                color: viewModel.isBootEnabled ? .axTextMuted : viewModel.databaseType.brandColor,
                isEnabled: !viewModel.isOperationInProgress
            ) {
                Task {
                    if viewModel.isBootEnabled {
                        await viewModel.disableOnBoot()
                    } else {
                        await viewModel.enableOnBoot()
                    }
                }
            }

            Spacer()

            // Refresh
            Button(action: { Task { await viewModel.loadData() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                    .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                    .frame(width: 36, height: 36)
                    .background(Color.axBackground)
                    .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isOperationInProgress)
        }
    }
}

// Helper button component
struct ServiceControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isEnabled ? color : .axTextMuted)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(isEnabled ? color.opacity(0.1) : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isEnabled ? color.opacity(0.3) : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
