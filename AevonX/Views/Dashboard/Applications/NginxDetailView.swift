
import SwiftUI
import AevonXCore

@MainActor
struct NginxDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let application: ApplicationInstance
    let serverId: String

    @State private var selectedSection: NginxSection = .overview
    @State private var nginxConfig = NginxConfigData()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            NginxSidebar(
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
                // Top Message Banners (Global to detail view)
                VStack(spacing: 0) {
                    if let error = errorMessage {
                        NginxMessageBanner(message: error, type: .error) {
                            errorMessage = nil
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if let success = successMessage {
                        NginxMessageBanner(message: success, type: .success) {
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
                                Text("Syncing Nginx Data...")
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
            Task { await loadNginxData() }
        }
    }

    @ViewBuilder
    private var contentForSection: some View {
        switch selectedSection {
        case .overview:
            NginxOverviewTab(
                application: application,
                nginxConfig: $nginxConfig,
                onReload: { Task { await reloadService() } },
                onTest: { Task { await testConfiguration() } }
            )
        case .configuration:
            NginxConfigurationTab(application: application, nginxConfig: $nginxConfig, onSave: saveConfiguration)
        case .ports:
            NginxPortsTab(application: application, nginxConfig: $nginxConfig, onSave: savePort)
        case .security:
            NginxSecurityTab(application: application, nginxConfig: $nginxConfig, onBlock: blockIP, onUnblock: unblockIP)
        case .logs:
            AXAdvancedLogsView(
                source: AXLogSource.nginxService,
                serverId: serverId,
                onSuccess: { msg in successMessage = msg },
                onError: { msg in errorMessage = msg }
            )
        case .versions:
            NginxVersionsTab(application: application, serverId: serverId)
        }
    }

    // MARK: - Actions

    private func loadNginxData() async {
        isLoading = true
        do {
            // Fetch configuration
            let configContent = try await ApplicationManager.shared.readConfig(type: .nginx, serverId: serverId)
            
            // Fetch paths
            let paths = try? await ApplicationManager.shared.getImportantPaths(type: .nginx, serverId: serverId)
            
            // Fetch listening ports
            let ports = (try? await ApplicationManager.shared.getListeningPorts(type: .nginx, serverId: serverId)) ?? []
            
            // Fetch blocked IPs
            let blocked = (try? await ApplicationManager.shared.getBlockedIPs(type: .nginx, serverId: serverId)) ?? []

            self.nginxConfig = NginxConfigData(
                rawConfig: configContent,
                configPath: paths?.configPath ?? "/etc/nginx/nginx.conf",
                logPath: paths?.logPath ?? "/var/log/nginx/access.log",
                dataPath: paths?.dataPath ?? "/var/www/html",
                listeningPorts: ports,
                blockedIPs: blocked
            )
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load Nginx data: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    private func saveConfiguration(_ newConfig: String) async {
        successMessage = nil
        errorMessage = nil
        
        do {
            try await ApplicationManager.shared.updateConfig(newConfig, type: .nginx, serverId: serverId)
            self.successMessage = "Nginx configuration updated and reloaded successfully"
            await loadNginxData()
        } catch {
            self.errorMessage = "Failed to save configuration: \(error.localizedDescription)"
        }
    }

    private func savePort(_ port: Int) async {
        successMessage = nil
        errorMessage = nil
        do {
            try await ApplicationManager.shared.updatePort(port, type: .nginx, serverId: serverId)
            self.successMessage = "Nginx port updated to \(port)"
            await loadNginxData()
        } catch {
            self.errorMessage = "Failed to update port: \(error.localizedDescription)"
        }
    }

    private func blockIP(_ ip: String, reason: String? = nil, duration: String? = nil) async {
        successMessage = nil
        errorMessage = nil
        do {
            try await ApplicationManager.shared.blockIP(ip, reason: reason, duration: duration, type: .nginx, serverId: serverId)
            self.successMessage = "IP \(ip) blocked successfully"
            await loadNginxData()
        } catch {
            self.errorMessage = "Failed to block IP: \(error.localizedDescription)"
        }
    }

    private func unblockIP(_ ip: String) async {
        successMessage = nil
        errorMessage = nil
        do {
            try await ApplicationManager.shared.unblockIP(ip, type: .nginx, serverId: serverId)
            self.successMessage = "IP \(ip) unblocked successfully"
            await loadNginxData()
        } catch {
            self.errorMessage = "Failed to unblock IP: \(error.localizedDescription)"
        }
    }
    
    // New specific Nginx actions
    private func reloadService() async {
        successMessage = nil
        errorMessage = nil
        do {
            try await ApplicationManager.shared.restartService(type: .nginx, serverId: serverId)
            self.successMessage = "Nginx service reloaded successfully"
        } catch {
            self.errorMessage = "Failed to reload Nginx: \(error.localizedDescription)"
        }
    }
    
    private func testConfiguration() async {
        successMessage = nil
        errorMessage = nil
        do {
            let isValid = try await ApplicationManager.shared.validateConfig(type: .nginx, serverId: serverId)
            if isValid {
                self.successMessage = "Nginx configuration is valid"
            } else {
                self.errorMessage = "Nginx configuration validation failed"
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
            case "start": try await ApplicationManager.shared.startService(type: .nginx, serverId: serverId)
            case "stop": try await ApplicationManager.shared.stopService(type: .nginx, serverId: serverId)
            case "restart": try await ApplicationManager.shared.restartService(type: .nginx, serverId: serverId)
            default: break
            }
            await MainActor.run {
                self.successMessage = "Nginx service \(action)ed successfully"
            }
            // Trigger refresh after control
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await loadNginxData()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to \(action) Nginx: \(error.localizedDescription)"
            }
        }
    }
}
