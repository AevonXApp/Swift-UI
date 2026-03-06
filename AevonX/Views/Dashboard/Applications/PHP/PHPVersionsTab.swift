//
//  PHPVersionsTab.swift
//  AevonX
//
//  PHP Version management — now using UnifiedVersionsView
//  Business logic for PHP switch/install/uninstall preserved
//

import SwiftUI
import AevonXCore

struct PHPVersionsTab: View {
    let application: ApplicationInstance
    let serverId: String
    var onRefreshAll: (() -> Void)?

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
            title: "PHP Versions",
            serviceName: "PHP",
            currentVersion: currentVersion,
            versions: buildVersionItems(),
            isLoading: isLoading,
            serviceIcon: "p.circle.fill",
            accentColor: Color(hex: "#777BB4"),
            onRefresh: { await loadVersions() },
            onInstall: { version in Task { await installVersion(version) } },
            onSwitch: { version in Task { await switchToVersion(version) } },
            onUninstall: { version in Task { await uninstallVersion(version) } },
            installerVM: installerVM,
            installerTitle: installerTitle,
            showInstaller: showInstaller,
            onDismissInstaller: {
                showInstaller = false
                Task {
                    await loadVersions()
                    onRefreshAll?()
                }
            }
        )
        .onAppear {
            Task { await loadVersions() }
        }
    }

    // MARK: - Build Version Items

    private func buildVersionItems() -> [VersionItem] {
        availableVersions.map { version in
            let isCurrent = version == currentVersion
            let isInstalled = installedVersions.contains { normalizeMajorMinor($0) == normalizeMajorMinor(version) }
            let badge: String? = version.hasPrefix("8.4") ? "Active" : (version.hasPrefix("8.1") ? "LTS" : nil)
            let badgeColor: Color = version.hasPrefix("8.4") ? .axSuccess : .axAccentBlue

            return VersionItem(
                version: version,
                isCurrent: isCurrent,
                isInstalled: isInstalled,
                badge: isCurrent ? nil : badge,
                badgeColor: badgeColor
            )
        }
    }

    // MARK: - Data Loading

    private func loadVersions() async {
        isLoading = true

        do {
            let appInfo = try await ApplicationManager.shared.getApplicationInfo(type: .phpFpm, serverId: serverId)
            currentVersion = appInfo.version
            let versions = try await ApplicationManager.shared.getAvailableVersions(type: .phpFpm, serverId: serverId)
            availableVersions = versions.sorted { compareVersions($0, $1) == .orderedDescending }
            installedVersions = try await PHPVersionService().getInstalledVersions(serverId: serverId)
        } catch {
            GlobalToastManager.shared.showError("Failed to load PHP versions: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Step-by-Step Actions

    private func switchToVersion(_ version: String) async {
        let majorMinor = normalizeMajorMinor(version)

        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Stop Current PHP-FPM", description: "Stopping the active PHP-FPM service", icon: "stop.circle"),
            AXInstallStep(title: "Switch PHP Binary", description: "Updating alternatives to PHP \(majorMinor)", icon: "arrow.triangle.swap"),
            AXInstallStep(title: "Start PHP \(majorMinor)-FPM", description: "Starting the new PHP-FPM service", icon: "play.circle"),
            AXInstallStep(title: "Verify Switch", description: "Confirming PHP \(majorMinor) is now active", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Switching to PHP \(version)"
        showInstaller = true

        let sshService = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case "Stop Current PHP-FPM":
                if let cur = currentVersion {
                    let curMM = normalizeMajorMinor(cur)
                    _ = try await sshService.execute("sudo systemctl stop php\(curMM)-fpm 2>/dev/null", serverId: sid)
                }
                return "Stopped"
            case "Switch PHP Binary":
                let cmd = """
                sudo update-alternatives --set php /usr/bin/php\(majorMinor) 2>/dev/null || \
                sudo alternatives --set php /usr/bin/php\(majorMinor) 2>/dev/null
                """
                _ = try await sshService.execute(cmd, serverId: sid)
                return "Updated"
            case let t where t.starts(with: "Start PHP"):
                _ = try await sshService.execute("sudo systemctl start php\(majorMinor)-fpm 2>/dev/null", serverId: sid)
                return "Started"
            case "Verify Switch":
                let result = try await sshService.execute("php -v 2>/dev/null | head -1", serverId: sid)
                let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                guard output.contains(majorMinor) else {
                    throw NSError(domain: "PHPSwitch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected PHP \(majorMinor) but got: \(output)"])
                }
                return output
            default:
                return nil
            }
        }
    }

    private func installVersion(_ version: String) async {
        let majorMinor = normalizeMajorMinor(version)

        var steps: [AXInstallStep] = [
            AXInstallStep(title: "Check Repository", description: "Verifying ondrej/php PPA is available", icon: "magnifyingglass"),
        ]

        steps.append(contentsOf: [
            AXInstallStep(title: "Update Package Lists", description: "Refreshing available packages", icon: "arrow.clockwise"),
            AXInstallStep(title: "Install PHP \(majorMinor)", description: "Installing php\(majorMinor), php\(majorMinor)-fpm, php\(majorMinor)-cli", icon: "shippingbox"),
            AXInstallStep(title: "Enable FPM Service", description: "Enabling and starting php\(majorMinor)-fpm", icon: "power"),
            AXInstallStep(title: "Verify Installation", description: "Confirming PHP \(majorMinor) is installed correctly", icon: "checkmark.shield"),
        ])

        installerVM.steps = steps
        installerTitle = "Installing PHP \(version)"
        showInstaller = true

        let sshService = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case "Check Repository":
                let result = try await sshService.execute(
                    "grep -r 'ondrej/php' /etc/apt/sources.list.d/ 2>/dev/null | head -1",
                    serverId: sid
                )
                if result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    _ = try await sshService.execute("sudo add-apt-repository -y ppa:ondrej/php 2>/dev/null", serverId: sid)
                    return "Added ondrej/php PPA"
                }
                return "PPA already configured"

            case "Update Package Lists":
                let result = try await sshService.execute("sudo apt-get update -y 2>/dev/null", serverId: sid)
                guard result.exitCode == 0 else {
                    throw NSError(domain: "PHPInstall", code: 1, userInfo: [NSLocalizedDescriptionKey: "apt-get update failed"])
                }
                return "Packages updated"

            case let t where t.starts(with: "Install PHP"):
                let result = try await sshService.execute(
                    "sudo apt-get install -y php\(majorMinor) php\(majorMinor)-fpm php\(majorMinor)-cli 2>&1",
                    serverId: sid
                )
                guard result.exitCode == 0 else {
                    throw NSError(domain: "PHPInstall", code: 2, userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? "Installation failed" : result.stderr])
                }
                return "Installed successfully"

            case "Enable FPM Service":
                _ = try await sshService.execute(
                    "sudo systemctl enable php\(majorMinor)-fpm 2>/dev/null && sudo systemctl start php\(majorMinor)-fpm 2>/dev/null",
                    serverId: sid
                )
                return "Service enabled and started"

            case "Verify Installation":
                let result = try await sshService.execute("php\(majorMinor) -v 2>/dev/null | head -1", serverId: sid)
                let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                if output.isEmpty {
                    throw NSError(domain: "PHPInstall", code: 3, userInfo: [NSLocalizedDescriptionKey: "php\(majorMinor) binary not found after install"])
                }
                return output

            default:
                return nil
            }
        }
    }

    private func uninstallVersion(_ version: String) async {
        let majorMinor = normalizeMajorMinor(version)

        let steps: [AXInstallStep] = [
            AXInstallStep(title: "Stop PHP-FPM", description: "Stopping php\(majorMinor)-fpm service", icon: "stop.circle"),
            AXInstallStep(title: "Remove PHP \(majorMinor)", description: "Uninstalling all php\(majorMinor) packages", icon: "trash"),
            AXInstallStep(title: "Clean Up", description: "Removing leftover configuration files", icon: "broom"),
            AXInstallStep(title: "Verify Removal", description: "Confirming PHP \(majorMinor) was removed", icon: "checkmark.shield"),
        ]

        installerVM.steps = steps
        installerTitle = "Uninstalling PHP \(version)"
        showInstaller = true

        let sshService = SSHService.shared

        await installerVM.run(serverId: serverId) { step, sid in
            switch step.title {
            case "Stop PHP-FPM":
                _ = try await sshService.execute(
                    "sudo systemctl stop php\(majorMinor)-fpm 2>/dev/null && sudo systemctl disable php\(majorMinor)-fpm 2>/dev/null",
                    serverId: sid
                )
                return "Service stopped"

            case let t where t.starts(with: "Remove PHP"):
                let result = try await sshService.execute(
                    "dpkg -l 'php\(majorMinor)*' 2>/dev/null | grep -q '^ii' || exit 0; sudo apt-get remove -y php\(majorMinor)* 2>&1",
                    serverId: sid
                )
                guard result.exitCode == 0 else {
                    throw NSError(domain: "PHPUninstall", code: 1, userInfo: [NSLocalizedDescriptionKey: result.stderr])
                }
                return "Packages removed"

            case "Clean Up":
                _ = try await sshService.execute("sudo apt-get autoremove -y 2>/dev/null", serverId: sid)
                return "Cleaned up"

            case "Verify Removal":
                let result = try await sshService.execute("dpkg -l 'php\(majorMinor)*' 2>/dev/null | grep '^ii' | wc -l", serverId: sid)
                let count = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                if count != "0" {
                    return "\(count) residual packages (may need manual cleanup)"
                }
                return "Fully removed"

            default:
                return nil
            }
        }
    }

    private func normalizeMajorMinor(_ version: String) -> String {
        let parts = version.split(separator: ".")
        if parts.count >= 2 {
            return "\(parts[0]).\(parts[1])"
        }
        return version
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
