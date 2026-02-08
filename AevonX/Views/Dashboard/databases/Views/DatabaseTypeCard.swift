//
//  DatabaseTypeCard.swift
//  AevonX
//
//  Card component showing a database type with installation status
//

import SwiftUI
import AevonXCore

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
                            .font(.system(size: 20))
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
                Text("Version:")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                
                Text(installationState.installedVersion ?? "Unknown")
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
            }
            
            if let path = installationState.installPath {
                HStack {
                    Text("Path:")
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
                    label: installationState.isRunning ? "Running" : "Stopped"
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
                    .font(.system(size: 14))
                    .foregroundColor(.axWarning)
                
                Text("Not Installed")
                    .font(AXTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.axWarning)
            }
            
            Text("This database engine is not installed on your server. Install it to create and manage databases.")
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
                    .font(.system(size: 14))
                
                Text(installationState.isInstalled ? "Manage" : "Install")
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
            return "Active"
        case .inactive:
            return "Inactive"
        case .failed:
            return "Failed"
        case .unknown:
            return "Unknown"
        case .notInstalled:
            return "Not Installed"
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