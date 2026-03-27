//
//  AXLaunchStep2Server.swift
//  AevonX
//
//  Step 2: Select server, connect SSH, auto-detect framework.
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStep2Server: View {
    @ObservedObject var viewModel: AXLaunchWizardViewModel
    @State private var showManualPicker = false

    private let frameworks = [
        "laravel", "wordpress", "nextjs", "react", "nodejs",
        "django", "fastapi", "go", "docker", "static"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.lg) {
                AXLaunchStepHeader(
                    stepIndex: 2, totalSteps: viewModel.totalWizardSteps,
                    title: L10n.AXLaunch.stepServer
                )
                serverList
                connectionStatus
                detectionResult
            }
        }
    }

    // MARK: - Server List

    private var serverList: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.AXLaunch.selectServer)
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(.axTextPrimary)

            if viewModel.availableServers.isEmpty {
                emptyServerState
            } else {
                serverGrid
            }
        }
    }

    private var emptyServerState: some View {
        Text(L10n.AXLaunch.noServers)
            .font(AXTypography.caption)
            .foregroundColor(.axTextMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.xl)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
    }

    private var serverGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: AXSpacing.sm)], spacing: AXSpacing.sm) {
            ForEach(viewModel.availableServers) { server in
                serverCard(server)
            }
        }
    }

    private func serverCard(_ server: Server) -> some View {
        let isSelected = viewModel.selectedServer?.id == server.id
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedServer = server
                viewModel.connectionStage = .idle
                viewModel.connectionError = nil
                viewModel.projectInfo = nil
                viewModel.detectionError = nil
            }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: server.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? Color.axAccentBlue.opacity(0.15) : Color.axBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))

                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(server.name)
                        .font(AXTypography.subheadline.weight(.medium))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    Text(server.host)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                }
                Spacer()
                Circle()
                    .fill(server.status.color)
                    .frame(width: 8, height: 8)
            }
            .padding(AXSpacing.md)
            .background(isSelected ? Color.axAccentBlue.opacity(0.08) : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Connection Status

    @ViewBuilder
    private var connectionStatus: some View {
        if viewModel.selectedServer != nil {
            switch viewModel.connectionStage {
            case .idle:
                connectButton
            case .connecting, .authenticating, .detecting:
                connectingState
            case .connected:
                connectedState
            case .failed:
                failedState
            }
        }
    }

    private var connectButton: some View {
        Button {
            Task { await viewModel.connectToServer() }
        } label: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "bolt.fill")
                Text(L10n.AXLaunch.connectServer)
            }
            .font(AXTypography.subheadline.weight(.medium))
            .foregroundColor(.axBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.md)
            .background(Color.axAccentBlue)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    private var connectingState: some View {
        HStack(spacing: AXSpacing.md) {
            ProgressView()
                .scaleEffect(0.8)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(connectionStageLabel)
                    .font(AXTypography.subheadline.weight(.medium))
                    .foregroundColor(.axTextPrimary)
                Text(connectionStageDetail)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
        }
        .padding(AXSpacing.md)
        .background(Color.axAccentBlue.opacity(0.08))
        .cornerRadius(AXCornerRadius.md)
    }

    private var connectionStageLabel: String {
        switch viewModel.connectionStage {
        case .connecting: return L10n.AXLaunch.stageConnecting
        case .authenticating: return L10n.AXLaunch.stageAuthenticating
        case .detecting: return L10n.AXLaunch.stageDetecting
        default: return ""
        }
    }

    private var connectionStageDetail: String {
        switch viewModel.connectionStage {
        case .connecting: return L10n.AXLaunch.stageConnectingDetail
        case .authenticating: return L10n.AXLaunch.stageAuthenticatingDetail
        case .detecting: return L10n.AXLaunch.stageDetectingDetail
        default: return ""
        }
    }

    private var connectedState: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.axSuccess)
                .font(.system(size: 18))
            Text(L10n.AXLaunch.connected)
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(.axSuccess)
            Spacer()
        }
        .padding(AXSpacing.md)
        .background(Color.axSuccess.opacity(0.08))
        .cornerRadius(AXCornerRadius.md)
    }

    private var failedState: some View {
        VStack(spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.axError)
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(L10n.AXLaunch.connectionFailed)
                        .font(AXTypography.subheadline.weight(.medium))
                        .foregroundColor(.axError)
                    if let err = viewModel.connectionError {
                        Text(err)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            Button {
                Task { await viewModel.connectToServer() }
            } label: {
                Text(L10n.AXLaunch.retry)
                    .font(AXTypography.caption.weight(.medium))
                    .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.md)
        .background(Color.axError.opacity(0.08))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Detection Result

    @ViewBuilder
    private var detectionResult: some View {
        if viewModel.connectionStage == .connected {
            if viewModel.isDetecting {
                detectingView
            } else if let info = viewModel.projectInfo {
                detectedView(info)
            } else if let error = viewModel.detectionError {
                detectionErrorView(error)
            }
        }
    }

    private var detectingView: some View {
        HStack(spacing: AXSpacing.md) {
            ProgressView().scaleEffect(0.8)
            Text(L10n.AXLaunch.stageDetecting)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
            Spacer()
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    private func detectedView(_ info: AXProjectInfo) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            AXLaunchFrameworkBadge(info: info)
            manualOverride
        }
    }

    private func detectionErrorView(_ error: String) -> some View {
        VStack(spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.axWarning)
                Text(L10n.AXLaunch.errorDetectionFailed)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                Spacer()
            }
            Text(error)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            manualOverride
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Manual Override

    private var manualOverride: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Button {
                withAnimation { showManualPicker.toggle() }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Text(L10n.AXLaunch.notCorrect)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Text(L10n.AXLaunch.selectManually)
                        .font(AXTypography.caption.weight(.medium))
                        .foregroundColor(.axAccentBlue)
                    Image(systemName: showManualPicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.axAccentBlue)
                }
            }
            .buttonStyle(.plain)

            if showManualPicker {
                frameworkGrid
            }
        }
    }

    private var frameworkGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: AXSpacing.sm)], spacing: AXSpacing.sm) {
            ForEach(frameworks, id: \.self) { fw in
                let isSelected = viewModel.manualFramework == fw
                Button {
                    viewModel.manualFramework = fw
                } label: {
                    Text(fw.capitalized)
                        .font(AXTypography.caption.weight(.medium))
                        .foregroundColor(isSelected ? .axBackground : .axTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.sm)
                        .background(isSelected ? Color.axAccentBlue : Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.md)
    }
}
