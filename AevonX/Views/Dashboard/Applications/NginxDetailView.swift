
import SwiftUI
import AevonXCore

@MainActor
struct NginxDetailView: View {
    let application: ApplicationInstance
    let serverId: String

    @State private var selectedTab = 0
    @State private var nginxConfig = NginxConfigData()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header Content
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: AXSpacing.xs) {
                        Text(application.name)
                            .font(AXTypography.title)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)
                        
                        HStack(spacing: AXSpacing.md) {
                            StatusBadge(isRunning: application.isRunning)
                            
                            Text(application.version ?? "Unknown Version")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    ControlButtons(application: application, serverId: serverId) { action in
                        Task { await controlService(action: action) }
                    }
                }
                
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
            .padding(AXSpacing.xl)
            .background(Color.axSurface.opacity(0.4))
            
            // Tabs
            AXTabs(tabs: ["Overview", "Configuration", "Ports", "Security", "Logs", "Versions"], selectedTab: $selectedTab)
                .padding(.horizontal, AXSpacing.xl)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    if isLoading {
                        ProgressView("Loading Nginx data...")
                            .padding(AXSpacing.xxl)
                    } else {
                        switch selectedTab {
                        case 0: NginxOverviewTab(
                            application: application,
                            nginxConfig: $nginxConfig,
                            onReload: { Task { await reloadService() } },
                            onTest: { Task { await testConfiguration() } }
                        )
                        case 1: NginxConfigurationTab(application: application, nginxConfig: $nginxConfig, onSave: saveConfiguration)
                        case 2: NginxPortsTab(application: application, nginxConfig: $nginxConfig, onSave: savePort)
                        case 3: NginxSecurityTab(application: application, nginxConfig: $nginxConfig, onBlock: blockIP, onUnblock: unblockIP)
                        case 4: AXAdvancedLogsView(
                            source: AXLogSource.nginxService,
                            serverId: serverId,
                            onSuccess: { msg in successMessage = msg },
                            onError: { msg in errorMessage = msg }
                        )
                        case 5: NginxVersionsTab(application: application, serverId: serverId, onInstall: installVersion, onSwitch: switchVersion)
                        default: EmptyView()
                        }
                    }
                }
                .padding(AXSpacing.xl)
                .animation(.spring(), value: selectedTab)
            }
        }
        .background(Color.axBackground)
        .onAppear {
            Task { await loadNginxData() }
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

    private func installVersion(_ version: String) async {
        successMessage = nil
        errorMessage = nil
        do {
            try await ApplicationManager.shared.installVersion(version, type: .nginx, serverId: serverId)
            self.successMessage = "Nginx version \(version) installation started"
        } catch {
            self.errorMessage = "Failed to start installation: \(error.localizedDescription)"
        }
    }

    private func switchVersion(_ version: String) async {
        successMessage = nil
        errorMessage = nil
        do {
            try await ApplicationManager.shared.switchVersion(version, type: .nginx, serverId: serverId)
            self.successMessage = "Switched to Nginx version \(version)"
        } catch {
            self.errorMessage = "Failed to switch version: \(error.localizedDescription)"
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

// MARK: - Helper Views

private struct StatusBadge: View {
    let isRunning: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isRunning ? Color.axSuccess : Color.axError)
                .frame(width: 8, height: 8)
            
            Text(isRunning ? "RUNNING" : "STOPPED")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isRunning ? .axSuccess : .axError)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isRunning ? Color.axSuccess.opacity(0.1) : Color.axError.opacity(0.1))
        .cornerRadius(4)
    }
}

private struct ControlButtons: View {
    let application: ApplicationInstance
    let serverId: String
    let onAction: (String) -> Void
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Button(action: { onAction("start") }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
            }
            .buttonStyle(.borderedProminent)
            .tint(.axSuccess)
            .disabled(application.isRunning)
            
            Button(action: { onAction("stop") }) {
                Image(systemName: "stop.fill")
                    .foregroundColor(.white)
            }
            .buttonStyle(.borderedProminent)
            .tint(.axError)
            .disabled(!application.isRunning)
            
            Button(action: { onAction("restart") }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
    }
}
