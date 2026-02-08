//
//  DatabaseEngineManagementView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

// MARK: - Database Engine Management View

public struct DatabaseEngineManagementView: View {
    @StateObject private var viewModel: DatabaseEngineDetailViewModel
    let onBack: () -> Void

    public init(databaseType: DatabaseType, serverId: String?, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DatabaseEngineDetailViewModel(
            databaseType: databaseType,
            serverId: serverId
        ))
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Sidebar Navigation
                DBEMSidebar(viewModel: viewModel, onBack: onBack)
                    .frame(width: 240)
                    .background(Color.axSurface)

                Divider()

                // Main Content Area
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.axBackground)
            }

            // Operation progress overlay
            if viewModel.operationResult.isInProgress {
                operationOverlay
            }
        }
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

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.currentSection {
        case .overview:
            DBEMOverviewSection(viewModel: viewModel)
        case .configuration:
            DBEMConfigurationSection(viewModel: viewModel)
        case .logs:
            DBEMLogsSection(viewModel: viewModel)
        case .optimization:
            DBEMOptimizationSection(viewModel: viewModel)
        case .versions:
            DBEMVersionsSection(viewModel: viewModel)
        case .access:
            DBEMAccessSection(viewModel: viewModel)
        }
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

// MARK: - Preview

#Preview {
    DatabaseEngineManagementView(
        databaseType: .mysql,
        serverId: "test-server",
        onBack: {}
    )
    .frame(width: 1200, height: 800)
}
