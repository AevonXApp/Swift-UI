
import SwiftUI
import AevonXCore

@MainActor
struct PHPDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let application: ApplicationInstance
    let serverId: String

    @State private var selectedSection: PHPSection = .overview
    @State private var phpConfig = PHPConfigData()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            PHPSidebar(
                application: application,
                selectedSection: $selectedSection,
                onBack: { dismiss() },
                onControl: { action in
                    Task { await controlService(action: action) }
                }
            )
            .frame(width: 260)
            .background(Color.axSurface.opacity(0.4))
            
            Divider()
            
            // Right Content Area
            VStack(spacing: 0) {
                // Top Message Banners
                VStack(spacing: 0) {
                    if let error = errorMessage {
                        PHPMessageBanner(message: error, type: .error) {
                            errorMessage = nil
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if let success = successMessage {
                        PHPMessageBanner(message: success, type: .success) {
                            successMessage = nil
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(), value: errorMessage)
                .animation(.spring(), value: successMessage)

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
                onTest: { Task { await testConfiguration() } }
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
                onSuccess: { msg in successMessage = msg },
                onError: { msg in errorMessage = msg }
            )
        case .versions:
            PHPVersionsTab(application: application, serverId: serverId)
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
            let configPath = (try? await ApplicationManager.shared.getConfigPath(type: .phpFpm, serverId: serverId)) ?? "/etc/php/php.ini"

            self.phpConfig = PHPConfigData(
                rawConfig: configContent,
                iniPath: configPath,
                installedExtensions: installedExts,
                availableExtensions: availableExts,
                disabledFunctions: disabledFuncs,
                fpmPools: pools
            )
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load PHP data: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    private func saveConfiguration(_ newConfig: String) async {
        successMessage = nil
        errorMessage = nil
        
        do {
            try await ApplicationManager.shared.updateConfig(newConfig, type: .phpFpm, serverId: serverId)
            self.successMessage = "PHP configuration updated and reloaded successfully"
            await loadPHPData()
        } catch {
            self.errorMessage = "Failed to save configuration: \(error.localizedDescription)"
        }
    }

    private func reloadService() async {
        successMessage = nil
        errorMessage = nil
        do {
            try await ApplicationManager.shared.restartService(type: .phpFpm, serverId: serverId)
            self.successMessage = "PHP-FPM service reloaded successfully"
        } catch {
            self.errorMessage = "Failed to reload PHP-FPM: \(error.localizedDescription)"
        }
    }
    
    private func testConfiguration() async {
        successMessage = nil
        errorMessage = nil
        do {
            let isValid = try await ApplicationManager.shared.validateConfig(type: .phpFpm, serverId: serverId)
            if isValid {
                self.successMessage = "PHP configuration is valid"
            } else {
                self.errorMessage = "PHP configuration validation failed"
            }
        } catch {
            self.errorMessage = "Validation error: \(error.localizedDescription)"
        }
    }

    private func controlService(action: String) async {
        successMessage = nil
        errorMessage = nil
        do {
            switch action {
            case "start": try await ApplicationManager.shared.startService(type: .phpFpm, serverId: serverId)
            case "stop": try await ApplicationManager.shared.stopService(type: .phpFpm, serverId: serverId)
            case "restart": try await ApplicationManager.shared.restartService(type: .phpFpm, serverId: serverId)
            default: break
            }
            await MainActor.run {
                self.successMessage = "PHP-FPM service \(action)ed successfully"
            }
            // Trigger refresh after control
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await loadPHPData()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to \(action) PHP-FPM: \(error.localizedDescription)"
            }
        }
    }
}
