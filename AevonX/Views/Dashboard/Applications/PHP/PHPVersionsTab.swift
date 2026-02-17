
import SwiftUI
import AevonXCore

struct PHPVersionsTab: View {
    let application: ApplicationInstance
    let serverId: String
    
    @State private var availableVersions: [String] = []
    @State private var installedVersions: [String] = []
    @State private var currentVersion: String?
    @State private var isLoading = true
    @State private var isInstalling: String?
    @State private var installProgress: Double = 0.0
    @State private var installMessage: String = ""
    
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
                .disabled(isLoading)
            }
            
            if isLoading {
                VStack(spacing: AXSpacing.md) {
                    ProgressView()
                    Text("Loading available versions...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if let installing = isInstalling {
                // Installation Progress
                VStack(spacing: AXSpacing.lg) {
                    VStack(spacing: AXSpacing.sm) {
                        Text("Installing PHP \(installing)...")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                        
                        Text(installMessage)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                    
                    ProgressView(value: installProgress)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 400)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding(AXSpacing.xl)
                .background(Color.axSurface.opacity(0.3))
                .cornerRadius(AXCornerRadius.lg)
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
                                onInstall: { Task { await installVersion(version) } }
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
            
            // Get actually installed versions
            if let adapter = await ApplicationManager.shared.adapter(for: .phpFpm) as? ApplicationPHPAdapter {
                installedVersions = try await adapter.getInstalledVersions(serverId: serverId)
            }
        } catch {
            GlobalToastManager.shared.showError("Failed to load PHP versions: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func switchToVersion(_ version: String) async {
        isInstalling = version
        
        do {
            try await ApplicationManager.shared.switchVersion(version, type: .phpFpm, serverId: serverId) { message, progress in
                Task { @MainActor in
                    installMessage = message
                    installProgress = progress
                }
            }
            
            currentVersion = version
            GlobalToastManager.shared.showSuccess("Switched to PHP \(version) successfully.")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        
        isInstalling = nil
        await loadVersions()
    }
    
    private func installVersion(_ version: String) async {
        isInstalling = version
        installProgress = 0.0
        installMessage = "Starting installation..."
        
        do {
            try await ApplicationManager.shared.installVersion(version, type: .phpFpm, serverId: serverId) { message, progress in
                Task { @MainActor in
                    installMessage = message
                    installProgress = progress
                }
            }
            GlobalToastManager.shared.showSuccess("Installed PHP \(version) successfully.")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        
        isInstalling = nil
        await loadVersions()
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
            
            // Action Button
            if !isCurrent {
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
