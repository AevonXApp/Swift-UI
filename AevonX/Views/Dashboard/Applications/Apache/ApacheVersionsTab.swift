//
//  ApacheVersionsTab.swift
//  AevonX
//
//  Apache Version management — now using UnifiedVersionsView
//  Business logic preserved, uses ApplicationManager for install/switch
//

import SwiftUI
import AevonXCoreBridge

struct ApacheVersionsTab: View {
    let application: ApplicationInstance
    let serverId: String

    @State private var availableVersions: [String] = []
    @State private var installedVersions: [String] = []
    @State private var currentVersion: String?
    @State private var isLoading = true

    // Step installer
    @StateObject private var installerVM = AXStepInstallerViewModel(steps: [])
    @State private var installerTitle: String = ""
    @State private var showInstaller = false

    var body: some View {
        UnifiedVersionsView(
            title: "Apache Versions",
            serviceName: "Apache",
            currentVersion: currentVersion,
            versions: buildVersionItems(),
            isLoading: isLoading,
            serviceIcon: "server.rack",
            accentColor: Color(hex: "#D22128"),
            onRefresh: { await loadVersions() },
            onInstall: { version in Task { await applyVersion(version) } },
            onSwitch: { version in Task { await applyVersion(version) } },
            onUninstall: nil,
            installerVM: installerVM,
            installerTitle: installerTitle,
            showInstaller: showInstaller,
            onDismissInstaller: {
                showInstaller = false
                Task { await loadVersions() }
            }
        )
        .onAppear {
            Task { await loadVersions() }
        }
    }

    // MARK: - Build Version Items

    private func buildVersionItems() -> [VersionItem] {
        availableVersions.map { version in
            let isCurrent = currentVersion != nil && (version.hasPrefix(currentVersion!) || currentVersion!.hasPrefix(version))
            let isInstalled = installedVersions.contains { $0.hasPrefix(version) || version.hasPrefix($0) }

            return VersionItem(
                version: version,
                isCurrent: isCurrent,
                isInstalled: isInstalled
            )
        }
    }

    // MARK: - Data Loading

    private func loadVersions() async {
        isLoading = true

        do {
            let appInfo = try await GoApplicationService.shared.getApplicationInfo(type: .apache, serverId: serverId)
            currentVersion = appInfo.version
            let versions = try await GoApplicationService.shared.getAvailableVersions(type: .apache, serverId: serverId)
            availableVersions = versions.sorted { compareVersions($0, $1) == .orderedDescending }
            if let current = currentVersion {
                installedVersions = [current]
            }
        } catch {
            GlobalToastManager.shared.showError("Failed to load Apache versions: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Actions

    private func applyVersion(_ version: String) async {
        let isInstalled = installedVersions.contains { $0.hasPrefix(version) || version.hasPrefix($0) }
        let actionTitle = isInstalled ? "Switching to" : "Installing"

        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Stop Apache", description: "Stopping current service", icon: "stop.circle"),
            AXInstallStep(title: "\(actionTitle) Apache \(version)", description: isInstalled ? "Switching active version" : "Installing apache2=\(version)*", icon: "shippingbox"),
            AXInstallStep(title: "Start Apache", description: "Starting updated service", icon: "play.circle"),
            AXInstallStep(title: "Verify", description: "Confirming Apache version", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "\(actionTitle) Apache \(version)"
        showInstaller = true

        let sshService = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case "Stop Apache":
                _ = try await sshService.execute("sudo systemctl stop apache2 2>/dev/null", serverId: sid)
                return "Stopped"

            case let t where t.contains("Apache \(version)"):
                let result = try await sshService.execute("sudo apt-get install -y apache2=\(version)* 2>&1", serverId: sid)
                guard result.exitCode == 0 else {
                    throw NSError(domain: "ApacheInstall", code: 1, userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? "Installation failed" : result.stderr])
                }
                return "Installed"

            case "Start Apache":
                _ = try await sshService.execute("sudo systemctl start apache2 2>/dev/null", serverId: sid)
                return "Started"

            case "Verify":
                let result = try await sshService.execute("apache2 -v 2>/dev/null | head -1", serverId: sid)
                return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

            default:
                return nil
            }
        }
    }

    private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = lhs.split(separator: ".").compactMap { Int($0) }
        let right = rhs.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(left.count, right.count) {
            let l = i < left.count ? left[i] : 0
            let r = i < right.count ? right[i] : 0
            if l > r { return .orderedDescending }
            if l < r { return .orderedAscending }
        }
        return .orderedSame
    }
}
