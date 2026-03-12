//
//  UnifiedDatabaseDetailView.swift
//  AevonX
//
//  Unified detail view for ALL database engines with FULL functionality
//  Integrates DatabaseEngineDetailViewModel functionality directly
//

import SwiftUI
import AevonXCoreBridge
import AevonXCoreBridge

struct UnifiedDatabaseDetailView: View {

    let application: ApplicationInstance
    let databaseType: AevonXCoreBridge.DatabaseType
    let serverId: String
    let onBack: (() -> Void)?

    // ViewModel integration (internal for extensions)
    @StateObject var viewModel: DatabaseEngineDetailViewModel

    @State var selectedSection: DatabaseSection = .overview
    @State var showConfigEditor = false
    @State var editedConfig: String = ""
    
    var availableSections: [DatabaseSection] {
        DatabaseSection.allCases.filter { section in
            if section == .access {
                return viewModel.supportsUserManagement
            }
            return true
        }
    }

    init(application: ApplicationInstance, databaseType: AevonXCoreBridge.DatabaseType, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.databaseType = databaseType
        self.serverId = serverId
        self.onBack = onBack
        _viewModel = StateObject(wrappedValue: DatabaseEngineDetailViewModel(databaseType: databaseType, serverId: serverId))
    }

    /// Convenience init — constructs ApplicationInstance internally so callers
    /// don't need to import AevonXCore.
    init(databaseType: AevonXCoreBridge.DatabaseType, serverId: String, onBack: (() -> Void)? = nil) {
        let appType: ApplicationType
        switch databaseType {
        case .mysql: appType = .mysql
        case .postgresql: appType = .postgresql
        case .redis: appType = .redis
        case .mongodb: appType = .mongodb
        case .mariadb: appType = .mariadb
        case .cockroachdb: appType = .cockroachdb
        case .elasticsearch: appType = .elasticsearch
        case .cassandra: appType = .cassandra
        default: appType = .unknown
        }
        self.init(
            application: ApplicationInstance(id: UUID(), name: databaseType.displayName, type: appType, status: .active, isRunning: true),
            databaseType: databaseType,
            serverId: serverId,
            onBack: onBack
        )
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Sidebar
                sidebarView
                    .frame(width: 260)

                Divider()

                // Content
                contentView
            }

            // Operation overlay
            if viewModel.operationResult.isInProgress {
                operationOverlay
            }

            if showConfigEditor {
                modalOverlay {
                    configEditorSheet
                }
            }

            if viewModel.showInstallVersion {
                modalOverlay {
                    versionPickerSheet
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .alert(item: $viewModel.activeAlert) { alertType in
            alertContent(for: alertType)
        }
        .overlay(alignment: .top) {
            resultToast
        }
    }

    // MARK: - Sidebar (using UnifiedServiceSidebar)

    private var sidebarView: some View {
        UnifiedServiceSidebar.database(
            databaseType: databaseType,
            application: application,
            selectedSection: $selectedSection,
            sections: availableSections,
            onBack: { onBack?() },
            onControl: { action in
                switch action {
                case .start: viewModel.showStartConfirmation()
                case .stop: viewModel.showStopConfirmation()
                case .restart: viewModel.showRestartConfirmation()
                }
            }
        )
    }


    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                contentForSelectedSection
            }
            .padding(AXSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }

    @ViewBuilder
    private var contentForSelectedSection: some View {
        switch selectedSection {
        case .overview:
            overviewContent
        case .configuration:
            configurationContent
        case .logs:
            logsContent
        case .versions:
            versionsContent
        case .optimization:
            optimizationContent
        case .access:
            accessContent
        }
    }

    // MARK: - Tab Content (split into extension files)
    // See: DatabaseOverviewContent.swift
    // See: DatabaseConfigContent.swift
    // See: DatabaseExtrasContent.swift

    // MARK: - Helper Views

    // cardView replaced by AXConfigCard from Dashboard/Components/Cards

    // infoRow replaced by AXInfoRow from Dashboard/Components/Cards


    func errorView(message: String) -> some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.axError)

            Text(message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Alert Content

    func alertContent(for alertType: AlertType) -> Alert {
        switch alertType {
        case .confirmStart:
            return Alert(
                title: Text("Start \(databaseType.displayName)?"),
                message: Text("The database service will be started and begin accepting connections."),
                primaryButton: .default(Text("Start")) {
                    Task { await viewModel.startService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmStop:
            return Alert(
                title: Text("Stop \(databaseType.displayName)?"),
                message: Text("All active connections will be terminated. Running queries will be interrupted."),
                primaryButton: .destructive(Text("Stop")) {
                    Task { await viewModel.stopService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmRestart:
            return Alert(
                title: Text("Restart \(databaseType.displayName)?"),
                message: Text("The service will be briefly interrupted. All active connections will be dropped."),
                primaryButton: .destructive(Text("Restart")) {
                    Task { await viewModel.restartService() }
                },
                secondaryButton: .cancel()
            )
        case .confirmInstall(let version):
            return Alert(
                title: Text("Install \(databaseType.displayName) \(version.version)?"),
                message: Text("This will download and install version \(version.version) on the server."),
                primaryButton: .default(Text("Install")) {
                    Task { await viewModel.installVersion(version) }
                },
                secondaryButton: .cancel()
            )
        case .confirmUpdate:
            return Alert(
                title: Text("Update \(databaseType.displayName)?"),
                message: Text("The database engine will be updated to the latest version."),
                primaryButton: .default(Text("Update")) {
                    Task { await viewModel.updateToLatestVersion() }
                },
                secondaryButton: .cancel()
            )
        case .confirmUninstall:
            return Alert(
                title: Text("Uninstall \(databaseType.displayName)?"),
                message: Text("This will completely remove the database engine. This action cannot be undone."),
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

    var operationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: AXSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(databaseType.brandColor)

                Text(viewModel.operationResult.message ?? "Working...")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                if let progress = viewModel.operationResult.progress {
                    VStack(spacing: AXSpacing.xs) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(databaseType.brandColor)
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
    var resultToast: some View {
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
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    viewModel.dismissAlert()
                }
            }
        }
    }

    // MARK: - Config Editor Sheet

    var configEditorSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Configuration")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Button("Cancel") {
                    showConfigEditor = false
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)

            Divider()

            // Editor
            TextEditor(text: $editedConfig)
                .font(.system(.body, design: .monospaced))
                .padding()

            Divider()

            // Footer
            HStack {
                AXActionButton(label: "Reset", icon: "arrow.uturn.backward", style: .ghost) {
                    editedConfig = viewModel.configuration?.rawContent ?? ""
                }

                Spacer()

                AXActionButton(label: "Save", icon: "checkmark", style: .primary, isLoading: viewModel.isPerformingServiceAction) {
                    Task {
                        await viewModel.saveConfiguration(content: editedConfig)
                        showConfigEditor = false
                    }
                }
            }
            .padding()
            .background(Color.axSurface)
        }
        .frame(width: 700, height: 600)
    }

    // MARK: - Version Picker Sheet

    var versionPickerSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Install Version")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                Spacer()

                Button("Cancel") {
                    viewModel.showInstallVersion = false
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)

            Divider()

            // Version List
            if viewModel.isFetchingVersions {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.availableVersions.isEmpty {
                VStack(spacing: AXSpacing.lg) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.axTextMuted)
                    Text("No versions available")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(viewModel.availableVersions) { version in
                            versionRow(version: version)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 500, height: 600)
    }

    func modalOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    showConfigEditor = false
                    viewModel.showInstallVersion = false
                }

            content()
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
        }
    }

    func versionRow(version: AevonX.DatabaseVersion) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(version.version)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)

                    if version.isRecommended {
                        Text("Recommended")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axSuccess)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.axSuccess.opacity(0.1))
                            .cornerRadius(4)
                    }

                    if version.isLTS {
                        Text("LTS")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                if let date = version.releaseDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            AXActionButton(label: "Install", icon: "arrow.down.circle", style: .primary) {
                viewModel.showInstallConfirmation(version: version)
                viewModel.showInstallVersion = false
            }
            .disabled(viewModel.isOperationInProgress)
        }
        .padding()
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }


}

// MARK: - Preview

#Preview {
    UnifiedDatabaseDetailView(
        application: ApplicationInstance(
            name: "MySQL",
            type: .mysql,
            version: "8.0.35",
            isRunning: true
        ),
        databaseType: AevonXCoreBridge.DatabaseType.mysql,
        serverId: "test"
    )
    .frame(width: 1200, height: 800)
}
