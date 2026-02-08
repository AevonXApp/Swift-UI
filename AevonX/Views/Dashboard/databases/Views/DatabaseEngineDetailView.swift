//
//  DatabaseEngineDetailView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

// MARK: - Database Engine Detail View

public struct DatabaseEngineDetailView: View {
    @StateObject private var viewModel: DatabaseEngineDetailViewModel
    @Environment(\.dismiss) private var dismiss

    public init(databaseType: DatabaseType, serverId: String?) {
        _viewModel = StateObject(wrappedValue: DatabaseEngineDetailViewModel(
            databaseType: databaseType,
            serverId: serverId
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            DBEDHeader(viewModel: viewModel, onDismiss: { dismiss() })

            // Tab Switcher
            DBEDTabSwitcher(activeTab: $viewModel.activeTab)

            // Content
            ZStack {
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Operation progress overlay
                if viewModel.operationResult.isInProgress {
                    operationOverlay
                }
            }
        }
        .background(Color.axBackground)
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
        // Confirmation and result alerts
        .alert(item: $viewModel.activeAlert) { alertType in
            alertContent(for: alertType)
        }
        // Version picker sheet
        .sheet(isPresented: $viewModel.showInstallVersion) {
            VersionPickerSheet(viewModel: viewModel)
        }
        // Configuration editor sheet
        .sheet(isPresented: $viewModel.showConfigEditor) {
            ConfigEditorSheet(viewModel: viewModel)
        }
        // Result toast overlay
        .overlay(alignment: .top) {
            resultToast
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if !viewModel.isInstalled {
            notInstalledView
        } else {
            switch viewModel.activeTab {
            case 0:
                DBEDOverviewTab(viewModel: viewModel)
            case 1:
                DBEDConfigurationTab(viewModel: viewModel)
            case 2:
                DBEDLogsTab(viewModel: viewModel)
            case 3:
                DBEDOptimizationTab(viewModel: viewModel)
            default:
                DBEDOverviewTab(viewModel: viewModel)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(viewModel.databaseType.brandColor)
            Text("Loading engine data...")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.axError)
            Text("Error Loading Data")
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Text(message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task { await viewModel.loadData() }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.sm)
            .background(viewModel.databaseType.brandColor.opacity(0.1))
            .foregroundColor(viewModel.databaseType.brandColor)
            .cornerRadius(AXCornerRadius.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Not Installed View

    private var notInstalledView: some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()

            Image(systemName: viewModel.databaseType.iconName)
                .font(.system(size: 64))
                .foregroundColor(viewModel.databaseType.brandColor.opacity(0.5))

            Text("\(viewModel.databaseType.displayName) is not installed")
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)

            Text("Install the engine to start specific version management and configuration.")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)

            Button("Install Now") {
                viewModel.showInstallVersion = true
            }
            .font(AXTypography.headline)
            .foregroundColor(.axBackground)
            .padding(.horizontal, AXSpacing.xxl)
            .padding(.vertical, AXSpacing.md)
            .background(viewModel.databaseType.brandColor)
            .cornerRadius(AXCornerRadius.md)
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Alert Content

    private func alertContent(for alertType: AlertType) -> Alert {
        switch alertType {
        case .confirmStart:
            return Alert(
                title: Text("Start \(viewModel.databaseType.displayName)?"),
                message: Text("The database service will be started and begin accepting connections."),
                primaryButton: .default(Text("Start")) {
                    Task { await viewModel.startService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmStop:
            return Alert(
                title: Text("Stop \(viewModel.databaseType.displayName)?"),
                message: Text("All active connections will be terminated. Running queries will be interrupted."),
                primaryButton: .destructive(Text("Stop")) {
                    Task { await viewModel.stopService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmRestart:
            return Alert(
                title: Text("Restart \(viewModel.databaseType.displayName)?"),
                message: Text("The service will be briefly interrupted. All active connections will be dropped and re-established."),
                primaryButton: .destructive(Text("Restart")) {
                    Task { await viewModel.restartService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmInstall(let version):
            return Alert(
                title: Text("Install \(viewModel.databaseType.displayName) \(version.version)?"),
                message: Text("This will download and install version \(version.version) on the server."),
                primaryButton: .default(Text("Install")) {
                    if let selected = viewModel.selectedVersion {
                        Task { await viewModel.installVersion(selected) }
                    }
                },
                secondaryButton: .cancel()
            )
        case .confirmUpdate:
            return Alert(
                title: Text("Update \(viewModel.databaseType.displayName)?"),
                message: Text("The database engine will be updated to the latest available version. A service restart will be required."),
                primaryButton: .default(Text("Update")) {
                    Task { await viewModel.updateToLatestVersion() }
                },
                secondaryButton: .cancel()
            )
        case .confirmUninstall:
            return Alert(
                title: Text("Uninstall \(viewModel.databaseType.displayName)?"),
                message: Text("This will completely remove the database engine from the server. All databases and data may be lost. This action cannot be undone."),
                primaryButton: .destructive(Text("Uninstall")) {
                    Task { await viewModel.uninstallEngine() }
                },
                secondaryButton: .cancel()
            )
        case .operationSuccess(let msg):
            return Alert(
                title: Text("Success"),
                message: Text(msg),
                dismissButton: .default(Text("OK")) {
                    viewModel.dismissAlert()
                }
            )
        case .operationFailure(let msg):
            return Alert(
                title: Text("Error"),
                message: Text(msg),
                dismissButton: .default(Text("OK")) {
                    viewModel.dismissAlert()
                }
            )
        }
    }

    // MARK: - Operation Overlay

    private var operationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: AXSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(viewModel.databaseType.brandColor)

                Text(viewModel.operationResult.message ?? "Working...")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                if let progress = viewModel.operationResult.progress {
                    VStack(spacing: AXSpacing.xs) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(viewModel.databaseType.brandColor)
                            .frame(width: 240)

                        Text("\(Int(progress * 100))%")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }
            .padding(AXSpacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                    .fill(Color.axSurface)
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
        }
    }

    // MARK: - Result Toast

    @ViewBuilder
    private var resultToast: some View {
        if viewModel.operationResult.isSuccess || viewModel.operationResult.isFailure {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: viewModel.operationResult.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 16))
                Text(viewModel.operationResult.message ?? "")
                    .font(AXTypography.subheadline)
                    .lineLimit(1)
            }
            .foregroundColor(viewModel.operationResult.isSuccess ? .axSuccess : .axError)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axSurface)
                    .shadow(color: .black.opacity(0.2), radius: 8)
            )
            .padding(.top, AXSpacing.md)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: viewModel.operationResult.isSuccess)
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    viewModel.dismissAlert()
                }
            }
        }
    }
}
