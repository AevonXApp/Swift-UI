//
//  ApacheDetailView.swift
//  AevonX
//
//  Main container view for Apache management
//

import SwiftUI
import AevonXCore

@MainActor
struct ApacheDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let application: ApplicationInstance
    let serverId: String

    @State private var selectedSection: ApacheSection = .overview
    @State private var apacheConfig = ApacheConfigData()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            ApacheSidebar(
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
                        ApacheMessageBanner(message: error, type: .error) {
                            errorMessage = nil
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if let success = successMessage {
                        ApacheMessageBanner(message: success, type: .success) {
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
                                Text("Syncing Apache Data...")
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
            Task { await loadApacheData() }
        }
    }

    @ViewBuilder
    private var contentForSection: some View {
        switch selectedSection {
        case .overview:
            ApacheOverviewTab(
                application: application,
                apacheConfig: $apacheConfig,
                onReload: { Task { await reloadService() } },
                onTest: { Task { await testConfiguration() } }
            )
        case .modules:
            ApacheModulesTab(application: application, apacheConfig: $apacheConfig, serverId: serverId)
        case .configuration:
            ApacheConfigurationTab(application: application, apacheConfig: $apacheConfig, onSave: saveConfiguration)
        case .virtualHosts:
            ApacheVirtualHostsTab(application: application, apacheConfig: $apacheConfig, serverId: serverId)
        case .logs:
            AXAdvancedLogsView(
                source: AXLogSource.apacheService,
                serverId: serverId,
                onSuccess: { msg in successMessage = msg },
                onError: { msg in errorMessage = msg }
            )
        case .versions:
            ApacheVersionsTab(application: application, serverId: serverId)
        }
    }

    // MARK: - Actions

    private func loadApacheData() async {
        isLoading = true
        do {
            // Fetch configuration
            let configContent = try await ApplicationManager.shared.readConfig(type: .apache, serverId: serverId)
            
            // Fetch installed modules
            let installedModules = (try? await ApplicationManager.shared.getInstalledApacheModules(serverId: serverId)) ?? []
            
            // Fetch available modules (optional, can be lazy loaded or fetched here)
            let availableModules = (try? await ApplicationManager.shared.getAvailableApacheModules(serverId: serverId)) ?? []
            
            // Combine modules
            let allModules = installedModules + availableModules
            
            // Fetch Virtual Hosts
            let vhosts = (try? await ApplicationManager.shared.getApacheVirtualHosts(serverId: serverId)) ?? []
            
            // Get config path
            let configPath = (try? await ApplicationManager.shared.getConfigPath(type: .apache, serverId: serverId)) ?? "/etc/apache2/apache2.conf"
            
            // Get Document Root
            let documentRoot = (try? await ApplicationManager.shared.getDocumentRoot(serverId: serverId)) ?? "/var/www/html"

            self.apacheConfig = ApacheConfigData(
                rawConfig: configContent,
                configPath: configPath,
                documentRoot: documentRoot,
                modules: allModules,
                virtualHosts: vhosts
            )
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load Apache data: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    private func saveConfiguration(_ newConfig: String) {
        Task {
            successMessage = nil
            errorMessage = nil
            
            do {
                try await ApplicationManager.shared.updateConfig(newConfig, type: .apache, serverId: serverId)
                self.successMessage = "Apache configuration updated and reloaded successfully"
                await loadApacheData()
            } catch {
                self.errorMessage = "Failed to save configuration: \(error.localizedDescription)"
            }
        }
    }

    private func reloadService() async {
        successMessage = nil
        errorMessage = nil
        do {
            try await ApplicationManager.shared.restartService(type: .apache, serverId: serverId)
            self.successMessage = "Apache service reloaded successfully"
        } catch {
            self.errorMessage = "Failed to reload Apache: \(error.localizedDescription)"
        }
    }
    
    private func testConfiguration() async {
        successMessage = nil
        errorMessage = nil
        do {
            let isValid = try await ApplicationManager.shared.validateConfig(type: .apache, serverId: serverId)
            if isValid {
                self.successMessage = "Apache configuration is valid"
            } else {
                self.errorMessage = "Apache configuration validation failed"
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
            case "start": try await ApplicationManager.shared.startService(type: .apache, serverId: serverId)
            case "stop": try await ApplicationManager.shared.stopService(type: .apache, serverId: serverId)
            case "restart": try await ApplicationManager.shared.restartService(type: .apache, serverId: serverId)
            default: break
            }
            await MainActor.run {
                self.successMessage = "Apache service \(action)ed successfully"
            }
            // Trigger refresh after control
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await loadApacheData()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to \(action) Apache: \(error.localizedDescription)"
            }
        }
    }
}
