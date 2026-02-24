
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
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PHP Versions")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    
                    if let current = currentVersion {
                        Text("Currently using PHP \(current)")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                }
                
                Spacer()
                
                Button(action: { Task { await loadVersions() } }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoading || showInstaller)
            }
            
            if isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                    Text("Loading available versions...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if showInstaller {
                // Step-by-step installation UI
                AXStepInstallerView(
                    viewModel: installerVM,
                    title: installerTitle,
                    icon: "shippingbox.fill",
                    accentColor: .axAccentBlue,
                    onDismiss: {
                        showInstaller = false
                        Task {
                            await loadVersions()
                            onRefreshAll?()
                        }
                    }
                )
                .frame(maxWidth: .infinity, minHeight: 300)
                .padding(.horizontal, AXSpacing.sm)
            } else {
                // Versions List
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(availableVersions, id: \.self) { version in
                            VersionCard(
                                version: version,
                                isCurrent: version == currentVersion,
                                isInstalled: installedVersions.contains { normalizeMajorMinor($0) == normalizeMajorMinor(version) },
                                onSwitch: { Task { await switchToVersion(version) } },
                                onInstall: { Task { await installVersion(version) } },
                                onUninstall: { Task { await uninstallVersion(version) } }
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            Task { await loadVersions() }
        }
    }
    
    private func loadVersions() async {
        isLoading = true
        
        do {
            let appInfo = try await ApplicationManager.shared.getApplicationInfo(type: .phpFpm, serverId: serverId)
            currentVersion = appInfo.version
            let versions = try await ApplicationManager.shared.getAvailableVersions(type: .phpFpm, serverId: serverId)
            availableVersions = versions.sorted { compareVersions($0, $1) == .orderedDescending }
            
            // Get actually installed versions via PHP domain service
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
        
        // We'll add the "Add Repository" step dynamically based on check result
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
                    // PPA not found — add it
                    _ = try await sshService.execute(
                        "sudo add-apt-repository -y ppa:ondrej/php 2>/dev/null",
                        serverId: sid
                    )
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
                _ = try await sshService.execute(
                    "sudo apt-get autoremove -y 2>/dev/null",
                    serverId: sid
                )
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

private struct VersionCard: View {
    let version: String
    let isCurrent: Bool
    let isInstalled: Bool
    let onSwitch: () -> Void
    let onInstall: () -> Void
    let onUninstall: () -> Void
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Version Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AXSpacing.xs) {
                    Text("PHP")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axTextTertiary)
                    
                    Text(version)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                        .monospaced()
                }
                
                // Status
                if isCurrent {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.axSuccess)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.axSuccess)
                    }
                } else {
                    Text(isInstalled ? "Installed" : "Not Installed")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                }
            }
            
            Spacer()
            
            // Action Buttons
            if !isCurrent {
                HStack(spacing: AXSpacing.xs) {
                    Button(action: isInstalled ? onSwitch : onInstall) {
                        Text(isInstalled ? "Switch" : "Install")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                    
                    if isInstalled {
                        Button(action: onUninstall) {
                            Text("Uninstall")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, AXSpacing.sm)
                                .background(Color.axError)
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(isCurrent ? 0.8 : 0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(isCurrent ? Color.axAccentBlue : Color.clear, lineWidth: 2)
        )
    }
}
