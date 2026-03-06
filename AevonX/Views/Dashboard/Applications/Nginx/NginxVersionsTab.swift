//
//  NginxVersionsTab.swift
//  AevonX
//
//  Nginx Version management — now using UnifiedVersionsView
//  Business logic preserved, uses ApplicationManager for install/switch
//

import SwiftUI
import AevonXCore

@MainActor
public struct NginxVersionsTab: View {
    let application: ApplicationInstance
    let serverId: String

    @State private var availableVersions: [String] = []
    @State private var currentVersion: String?
    @State private var isLoading = false

    // Step installer
    @StateObject private var installerVM = AXStepInstallerViewModel(steps: [])
    @State private var installerTitle: String = ""
    @State private var showInstaller = false

    public init(application: ApplicationInstance, serverId: String) {
        self.application = application
        self.serverId = serverId
    }

    public var body: some View {
        UnifiedVersionsView(
            title: "Nginx Versions",
            serviceName: "Nginx",
            currentVersion: currentVersion ?? application.version,
            versions: buildVersionItems(),
            isLoading: isLoading,
            serviceIcon: "server.rack",
            accentColor: Color(hex: "#009639"),
            onRefresh: { await loadVersions() },
            onInstall: { version in Task { await installVersion(version) } },
            onSwitch: { version in Task { await switchToVersion(version) } },
            onUninstall: nil,
            installerVM: installerVM,
            installerTitle: installerTitle,
            showInstaller: showInstaller,
            onDismissInstaller: {
                showInstaller = false
                Task { await loadVersions() }
            }
        )
        .task {
            await loadVersions()
        }
    }

    // MARK: - Build Version Items

    private func buildVersionItems() -> [VersionItem] {
        availableVersions.map { version in
            let isCurrent = version == (currentVersion ?? application.version)
            let badge: String? = {
                // Mark latest & LTS
                if version == availableVersions.first { return "Latest" }
                return nil
            }()

            return VersionItem(
                version: version,
                isCurrent: isCurrent,
                isInstalled: isCurrent,
                badge: isCurrent ? nil : badge,
                badgeColor: .axAccentBlue
            )
        }
    }

    // MARK: - Data Loading

    private func loadVersions() async {
        isLoading = true
        do {
            let appInfo = try await ApplicationManager.shared.getApplicationInfo(type: .nginx, serverId: serverId)
            let versions = try await ApplicationManager.shared.getAvailableVersions(type: .nginx, serverId: serverId)
            self.currentVersion = appInfo.version
            self.availableVersions = versions
        } catch {
            self.availableVersions = []
            GlobalToastManager.shared.showError("Failed to load versions: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Actions

    private func installVersion(_ version: String) async {
        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Download Nginx \(version)", description: "Fetching packages", icon: "arrow.down.circle"),
            AXInstallStep(title: "Install Nginx \(version)", description: "Installing nginx=\(version)*", icon: "shippingbox"),
            AXInstallStep(title: "Verify Installation", description: "Confirming version", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Installing Nginx \(version)"
        showInstaller = true

        let sshService = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case let t where t.starts(with: "Download"):
                let result = try await sshService.execute("sudo apt-get update -y 2>/dev/null", serverId: sid)
                guard result.exitCode == 0 else {
                    throw NSError(domain: "NginxInstall", code: 1, userInfo: [NSLocalizedDescriptionKey: "apt-get update failed"])
                }
                return "Package lists updated"

            case let t where t.starts(with: "Install"):
                let result = try await sshService.execute("sudo apt-get install -y nginx=\(version)* 2>&1", serverId: sid)
                guard result.exitCode == 0 else {
                    throw NSError(domain: "NginxInstall", code: 2, userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? "Installation failed" : result.stderr])
                }
                return "Installed"

            case "Verify Installation":
                let result = try await sshService.execute("nginx -v 2>&1", serverId: sid)
                return result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)

            default:
                return nil
            }
        }
    }

    private func switchToVersion(_ version: String) async {
        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Stop Nginx", description: "Stopping current service", icon: "stop.circle"),
            AXInstallStep(title: "Switch to \(version)", description: "Updating package version", icon: "arrow.triangle.swap"),
            AXInstallStep(title: "Start Nginx", description: "Starting updated service", icon: "play.circle"),
            AXInstallStep(title: "Verify Switch", description: "Confirming new version", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Switching to Nginx \(version)"
        showInstaller = true

        let sshService = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case "Stop Nginx":
                _ = try await sshService.execute("sudo systemctl stop nginx 2>/dev/null", serverId: sid)
                return "Stopped"

            case let t where t.starts(with: "Switch"):
                let result = try await sshService.execute("sudo apt-get install -y nginx=\(version)* 2>&1", serverId: sid)
                guard result.exitCode == 0 else {
                    throw NSError(domain: "NginxSwitch", code: 1, userInfo: [NSLocalizedDescriptionKey: result.stderr])
                }
                return "Installed \(version)"

            case "Start Nginx":
                _ = try await sshService.execute("sudo systemctl start nginx 2>/dev/null", serverId: sid)
                return "Started"

            case "Verify Switch":
                let result = try await sshService.execute("nginx -v 2>&1", serverId: sid)
                return result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)

            default:
                return nil
            }
        }
    }
}
