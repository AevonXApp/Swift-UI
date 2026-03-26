//
//  DatabaseTypeCard.swift
//  AevonX
//
//  Card component showing a database type with installation status
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Database Type Card

/// Card showing database type information and installation status
public struct DatabaseTypeCard: View {
    let installationState: DatabaseInstallationState
    let onInstall: () -> Void
    let onManage: () -> Void
    
    @State private var isHovered = false
    
    public init(
        installationState: DatabaseInstallationState,
        onInstall: @escaping () -> Void,
        onManage: @escaping () -> Void
    ) {
        self.installationState = installationState
        self.onInstall = onInstall
        self.onManage = onManage
    }
    
    public var body: some View {
        AXCard(padding: 20, accentColor: installationState.type.brandColor) {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                // Header with icon and status
                HStack(spacing: AXSpacing.md) {
                    // Database icon
                    ZStack {
                        Circle()
                            .fill(installationState.type.brandColor.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: installationState.type.iconName)
                            .font(AXTypography.title2)
                            .foregroundColor(installationState.type.brandColor)
                    }
                    
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text(installationState.type.displayName)
                            .font(AXTypography.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        
                        Text(installationState.type.category.displayName)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    StatusBadge(status: installationState.serviceStatus)
                }
                
                Divider()
                    .background(Color.axBorder)
                
                // Version info or "Not installed" message
                if installationState.isInstalled {
                    installedContent
                } else {
                    notInstalledContent
                }
                
                // Action button
                actionButton
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    // MARK: - Installed Content
    
    private var installedContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack {
                Text(L10n.Engine.versionColon)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                
                Text(installationState.installedVersion ?? L10n.Status.unknown)
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
            }
            
            if let path = installationState.installPath {
                HStack {
                    Text(L10n.Engine.pathColon)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    Text(path)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
            
            HStack(spacing: AXSpacing.md) {
                DBStatusIndicator(
                    isRunning: installationState.isRunning,
                    label: installationState.isRunning ? L10n.Status.running : L10n.Status.stopped
                )
                
                Spacer()
            }
        }
    }
    
    // MARK: - Not Installed Content
    
    private var notInstalledContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "exclamationmark.triangle")
                    .font(AXTypography.body)
                    .foregroundColor(.axWarning)
                
                Text(L10n.Database.notInstalled)
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.axWarning)
            }

            Text(L10n.Database.notInstalledDescription)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: installationState.isInstalled ? onManage : onInstall) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: installationState.isInstalled ? "gearshape" : "arrow.down.circle")
                    .font(AXTypography.body)
                
                Text(installationState.isInstalled ? L10n.Database.manage : L10n.Button.install)
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(installationState.isInstalled ? installationState.type.brandColor : .axBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.sm)
            .background(installationState.isInstalled ? installationState.type.brandColor.opacity(0.1) : installationState.type.brandColor)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: ServiceStatus
    
    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(AXTypography.caption2)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
        .background(statusColor.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return .axSuccess
        case .inactive:
            return .axTextMuted
        case .failed:
            return .axError
        case .unknown:
            return .axWarning
        case .notInstalled:
            return .axTextMuted
        }
    }
    
    private var statusText: String {
        switch status {
        case .active:
            return L10n.Status.active
        case .inactive:
            return L10n.Status.inactive
        case .failed:
            return L10n.Status.failed
        case .unknown:
            return L10n.Status.unknown
        case .notInstalled:
            return L10n.Database.notInstalled
        }
    }
}

// MARK: - DB Status Indicator

private struct DBStatusIndicator: View {
    let isRunning: Bool
    let label: String
    
    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Circle()
                .fill(isRunning ? Color.axSuccess : Color.axTextMuted)
                .frame(width: 6, height: 6)
            
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(isRunning ? .axSuccess : .axTextMuted)
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: AXSpacing.lg) {
        // Installed example
        DatabaseTypeCard(
            installationState: DatabaseInstallationState(
                type: .mysql,
                isInstalled: true,
                installedVersion: "8.0.32",
                installPath: "/usr/bin/mysql",
                serviceStatus: .active,
                isRunning: true
            ),
            onInstall: {},
            onManage: {}
        )
        .frame(width: 300)
        
        // Not installed example
        DatabaseTypeCard(
            installationState: DatabaseInstallationState(
                type: .redis,
                isInstalled: false,
                serviceStatus: .notInstalled,
                isRunning: false
            ),
            onInstall: {},
            onManage: {}
        )
        .frame(width: 300)
    }
    .padding()
    .background(Color.axBackground)
}