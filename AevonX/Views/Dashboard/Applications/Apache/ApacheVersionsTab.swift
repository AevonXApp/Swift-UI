
import SwiftUI
import AevonXCore

struct ApacheVersionsTab: View {
    let application: ApplicationInstance
    let serverId: String
    
    @State private var availableVersions: [String] = []
    @State private var installedVersions: [String] = []
    @State private var currentVersion: String?
    @State private var isLoading = true
    @State private var isInstalling: String?
    @State private var installProgress: Double = 0.0
    @State private var installMessage: String = ""
    @State private var showNotSupportedAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apache Versions")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    
                    if let current = currentVersion {
                        Text("Currently using Apache \(current)")
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
            } else {
                // Info Banner
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axAccentBlue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version Management Coming Soon")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.axTextPrimary)
                        
                        Text("Switching Apache versions directly is not yet supported. You can install specific versions manually via SSH.")
                            .font(.system(size: 12))
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    Spacer()
                }
                .padding(AXSpacing.lg)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1)
                )

                // Versions List
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(availableVersions, id: \.self) { version in
                            VersionCard(
                                version: version,
                                isCurrent: version == currentVersion,
                                isInstalled: installedVersions.contains(where: { $0.hasPrefix(version) || version.hasPrefix($0) }),
                                onAction: { showNotSupportedAlert = true }
                            )
                        }
                    }
                }
            }
        }
        .alert("Coming Soon", isPresented: $showNotSupportedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Apache version switching inside AevonX will be available in a future update.")
        }
        .onAppear {
            Task { await loadVersions() }
        }
    }
    
    private func loadVersions() async {
        isLoading = true
        
        do {
            let appInfo = try await ApplicationManager.shared.getApplicationInfo(type: .apache, serverId: serverId)
            currentVersion = appInfo.version
            availableVersions = try await ApplicationManager.shared.getAvailableVersions(type: .apache, serverId: serverId)
            
            // For Apache, check installed version specifically if needed, but currentVersion usually suffices for single install
            // Just mark current as installed for now
            if let current = currentVersion {
                installedVersions = [current]
            }
        } catch {
            print("Error loading versions: \(error)")
        }
        
        isLoading = false
    }
}

private struct VersionCard: View {
    let version: String
    let isCurrent: Bool
    let isInstalled: Bool
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Version Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AXSpacing.xs) {
                    Text("Apache")
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
                    Text(isInstalled ? "Installed" : "Available")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                }
            }
            
            Spacer()
            
            // Action Button
            if !isCurrent {
                Button(action: onAction) {
                    Text(isInstalled ? "Switch" : "Install")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axTextMuted) // Muted because disabled/coming soon
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
