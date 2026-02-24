
import SwiftUI
import AevonXCore

@MainActor
struct PHPDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let application: ApplicationInstance
    let serverId: String
    let onBack: (() -> Void)?

    init(application: ApplicationInstance, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.serverId = serverId
        self.onBack = onBack
    }

    @State private var selectedSection: PHPSection = .overview
    @State private var phpConfig = PHPConfigData()
    @State private var isLoading = true

    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            PHPSidebar(
                application: application,
                selectedSection: $selectedSection,
                onBack: { handleBack() },
                onControl: { action in
                    Task { await controlService(action: action) }
                }
            )
            .frame(width: 260)
            .background(Color.axSurface.opacity(0.4))
            
            Divider()
            
            // Right Content Area
            VStack(spacing: 0) {
                // Scrollable Content
                ScrollView {
                    VStack(spacing: AXSpacing.xl) {
                        if isLoading {
                            VStack(spacing: AXSpacing.md) {
                                ProgressView()
                                Text("Syncing PHP Data...")
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextTertiary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 400)
                        } else {
                            contentForSection
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(AXSpacing.xl)
                }
            }
            .background(Color.axBackground)
        }
        .background(Color.axBackground)
        .onAppear {
            Task { await loadPHPData() }
        }
    }

    @ViewBuilder
    private var contentForSection: some View {
        switch selectedSection {
        case .overview:
            PHPOverviewTab(
                application: application,
                phpConfig: $phpConfig,
                onReload: { Task { await reloadService() } },
                onTest: { Task { await testConfiguration() } },
                serverId: serverId
            )
        case .extensions:
            PHPExtensionsTab(application: application, phpConfig: $phpConfig, serverId: serverId)
        case .configuration:
            PHPConfigurationTab(application: application, phpConfig: $phpConfig, onSave: saveConfiguration)
        case .disabledFunctions:
            PHPDisabledFunctionsTab(application: application, phpConfig: $phpConfig, serverId: serverId)
        case .fpmPools:
            PHPFPMPoolsTab(application: application, phpConfig: $phpConfig, serverId: serverId)
        case .logs:
            AXAdvancedLogsView(
                source: AXLogSource.phpService,
                serverId: serverId,
                onSuccess: { msg in showSuccess(msg) },
                onError: { msg in showError(msg) }
            )
        case .versions:
            PHPVersionsTab(application: application, serverId: serverId, onRefreshAll: {
                Task { await loadPHPData() }
            })
        }
    }

    // MARK: - Actions

    private func loadPHPData() async {
        isLoading = true
        do {
            // Fetch configuration
            let configContent = try await ApplicationManager.shared.readConfig(type: .phpFpm, serverId: serverId)
            
            // Fetch installed extensions
            let installedExts = (try? await ApplicationManager.shared.getInstalledPHPExtensions(serverId: serverId)) ?? []
            
            // Fetch available extensions
            let availableExts = (try? await ApplicationManager.shared.getAvailablePHPExtensions(serverId: serverId)) ?? []
            
            // Fetch disabled functions
            let disabledFuncs = (try? await ApplicationManager.shared.getDisabledPHPFunctions(serverId: serverId)) ?? []
            
            // Fetch FPM pools
            let pools = (try? await ApplicationManager.shared.getPHPFPMPools(serverId: serverId)) ?? []
            
            // Get config path
            let configPath = (try? await ApplicationManager.shared.getConfigPath(type: .phpFpm, serverId: serverId)) ?? "Not detected"
            
            // Get log path dynamically from Core
            let logPaths = (try? await ApplicationManager.shared.getLogPaths(type: .phpFpm, serverId: serverId)) ?? []
            let logPath = logPaths.first ?? "Not detected"
            
            // Get PHP-FPM process status
            let fpmStatus = (try? await ApplicationManager.shared.getPHPFPMStatus(serverId: serverId)) ?? PHPFPMStatus()
            
            // Get OPcache status
            let opcacheStatus = (try? await ApplicationManager.shared.getPHPOPcacheStatus(serverId: serverId)) ?? PHPOPcacheStatus()

            self.phpConfig = PHPConfigData(
                rawConfig: configContent,
                iniPath: configPath,
                logPath: logPath,
                installedExtensions: installedExts,
                availableExtensions: availableExts,
                disabledFunctions: disabledFuncs,
                fpmPools: pools,
                fpmStatus: fpmStatus,
                opcacheStatus: opcacheStatus
            )
            self.isLoading = false
        } catch {
            showError("Failed to load PHP data: \(error.localizedDescription)")
            self.isLoading = false
        }
    }

    private func saveConfiguration(_ newConfig: String) async {
        do {
            try await ApplicationManager.shared.updateConfig(newConfig, type: .phpFpm, serverId: serverId)
            showSuccess("PHP configuration updated and reloaded successfully")
            await loadPHPData()
        } catch {
            showError("Failed to save configuration: \(error.localizedDescription)")
        }
    }

    private func reloadService() async {
        do {
            try await ApplicationManager.shared.restartService(type: .phpFpm, serverId: serverId)
            showSuccess("PHP-FPM service reloaded successfully")
        } catch {
            showError("Failed to reload PHP-FPM: \(error.localizedDescription)")
        }
    }
    
    private func testConfiguration() async {
        do {
            let isValid = try await ApplicationManager.shared.validateConfig(type: .phpFpm, serverId: serverId)
            if isValid {
                showSuccess("PHP configuration is valid")
            } else {
                showError("PHP configuration validation failed")
            }
        } catch {
            showError("Validation error: \(error.localizedDescription)")
        }
    }

    private func controlService(action: String) async {
        do {
            switch action {
            case "start": try await ApplicationManager.shared.startService(type: .phpFpm, serverId: serverId)
            case "stop": try await ApplicationManager.shared.stopService(type: .phpFpm, serverId: serverId)
            case "restart": try await ApplicationManager.shared.restartService(type: .phpFpm, serverId: serverId)
            default: break
            }
            await MainActor.run {
                showSuccess("PHP-FPM service \(action)ed successfully")
            }
            // Trigger refresh after control
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await loadPHPData()
            }
        } catch {
            await MainActor.run {
                showError("Failed to \(action) PHP-FPM: \(error.localizedDescription)")
            }
        }
    }

    private func showSuccess(_ message: String) {
        GlobalToastManager.shared.showSuccess(message)
    }

    private func showError(_ message: String) {
        GlobalToastManager.shared.showError(message)
    }

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }
}
