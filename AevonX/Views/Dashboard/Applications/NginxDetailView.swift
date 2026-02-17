
import SwiftUI
import AevonXCore

@MainActor
struct NginxDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let application: ApplicationInstance
    let serverId: String
    let onBack: (() -> Void)?

    init(application: ApplicationInstance, serverId: String, onBack: (() -> Void)? = nil) {
        self.application = application
        self.serverId = serverId
        self.onBack = onBack
    }

    @State private var selectedSection: NginxSection = .overview
    @State private var nginxConfig = NginxConfigData()
    @State private var isLoading = true

    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            NginxSidebar(
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
                onSuccess: { msg in showSuccess(msg) },
                onError: { msg in showError(msg) }
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
            showError("Failed to load Nginx data: \(error.localizedDescription)")
            self.isLoading = false
        }
    }

    private func saveConfiguration(_ newConfig: String) async {
        do {
            try await ApplicationManager.shared.updateConfig(newConfig, type: .nginx, serverId: serverId)
            showSuccess("Nginx configuration updated and reloaded successfully")
            await loadNginxData()
        } catch {
            showError("Failed to save configuration: \(error.localizedDescription)")
        }
    }

    private func savePort(_ port: Int) async {
        do {
            try await ApplicationManager.shared.updatePort(port, type: .nginx, serverId: serverId)
            showSuccess("Nginx port updated to \(port)")
            await loadNginxData()
        } catch {
            showError("Failed to update port: \(error.localizedDescription)")
        }
    }

    private func blockIP(_ ip: String, reason: String? = nil, duration: String? = nil) async {
        do {
            try await ApplicationManager.shared.blockIP(ip, reason: reason, duration: duration, type: .nginx, serverId: serverId)
            showSuccess("IP \(ip) blocked successfully")
            await loadNginxData()
        } catch {
            showError("Failed to block IP: \(error.localizedDescription)")
        }
    }

    private func unblockIP(_ ip: String) async {
        do {
            try await ApplicationManager.shared.unblockIP(ip, type: .nginx, serverId: serverId)
            showSuccess("IP \(ip) unblocked successfully")
            await loadNginxData()
        } catch {
            showError("Failed to unblock IP: \(error.localizedDescription)")
        }
    }
    
    // New specific Nginx actions
    private func reloadService() async {
        do {
            try await ApplicationManager.shared.restartService(type: .nginx, serverId: serverId)
            showSuccess("Nginx service reloaded successfully")
        } catch {
            showError("Failed to reload Nginx: \(error.localizedDescription)")
        }
    }
    
    private func testConfiguration() async {
        do {
            let isValid = try await ApplicationManager.shared.validateConfig(type: .nginx, serverId: serverId)
            if isValid {
                showSuccess("Nginx configuration is valid")
            } else {
                showError("Nginx configuration validation failed")
            }
        } catch {
            showError("Validation error: \(error.localizedDescription)")
        }
    }

    private func controlService(action: String) async {
        do {
            switch action {
            case "start": try await ApplicationManager.shared.startService(type: .nginx, serverId: serverId)
            case "stop": try await ApplicationManager.shared.stopService(type: .nginx, serverId: serverId)
            case "restart": try await ApplicationManager.shared.restartService(type: .nginx, serverId: serverId)
            default: break
            }
            await MainActor.run {
                showSuccess("Nginx service \(action)ed successfully")
            }
            // Trigger refresh after control
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await loadNginxData()
            }
        } catch {
            await MainActor.run {
                showError("Failed to \(action) Nginx: \(error.localizedDescription)")
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
