//
//  UnifiedVersionsView.swift
//  AevonX
//
//  Unified version management view — consistent UI for ALL applications.
//  Business logic is injected via closures, design is standardized.
//

import SwiftUI
import AevonXCore

// MARK: - Version Item Model

struct VersionItem: Identifiable {
    let id = UUID()
    let version: String
    let isCurrent: Bool
    let isInstalled: Bool
    var badge: String? = nil  // e.g. "LTS", "Recommended", "Latest"
    var badgeColor: Color = .axAccentBlue
}

// MARK: - Unified Versions View

struct UnifiedVersionsView: View {
    let title: String
    let serviceName: String
    let currentVersion: String?
    let versions: [VersionItem]
    let isLoading: Bool
    let serviceIcon: String
    let accentColor: Color

    // Actions
    let onRefresh: () async -> Void
    let onInstall: (String) -> Void
    let onSwitch: (String) -> Void
    let onUninstall: ((String) -> Void)?

    // Step installer
    @ObservedObject var installerVM: AXStepInstallerViewModel
    var installerTitle: String = ""
    var showInstaller: Bool = false
    var onDismissInstaller: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection
                .padding(.bottom, AXSpacing.lg)

            if isLoading {
                loadingState
            } else if showInstaller {
                AXStepInstallerView(
                    viewModel: installerVM,
                    title: installerTitle,
                    icon: "shippingbox.fill",
                    accentColor: accentColor,
                    onDismiss: {
                        onDismissInstaller?()
                    }
                )
                .frame(maxWidth: .infinity, minHeight: 300)
                .padding(.horizontal, AXSpacing.sm)
            } else if versions.isEmpty {
                emptyState
            } else {
                versionsListSection
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.axTextPrimary)

                if let current = currentVersion {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.axSuccess)
                            .frame(width: 6, height: 6)

                        Text("Currently using \(serviceName) \(current)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }

            Spacer()

            Button {
                Task { await onRefresh() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Refresh")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .fill(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading || showInstaller)
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: AXSpacing.md) {
            // Skeleton version cards
            ForEach(0..<4, id: \.self) { _ in
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.axSurface)
                            .frame(width: 100, height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.axSurface.opacity(0.5))
                            .frame(width: 70, height: 10)
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(Color.axSurface)
                        .frame(width: 70, height: 30)
                }
                .padding(AXSpacing.md)
                .background(Color.axSurface.opacity(0.3))
                .cornerRadius(AXCornerRadius.md)
            }
        }
        .redacted(reason: .placeholder)
    }

    // MARK: - Empty

    private var emptyState: some View {
        AXPlaceholder(
            icon: "number.square",
            title: "No Versions Available",
            subtitle: "Could not find any versions for \(serviceName)"
        )
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.xxl)
    }

    // MARK: - Versions List

    private var versionsListSection: some View {
        ScrollView {
            VStack(spacing: AXSpacing.sm) {
                ForEach(versions) { item in
                    UnifiedVersionCard(
                        version: item,
                        serviceName: serviceName,
                        accentColor: accentColor,
                        onInstall: { onInstall(item.version) },
                        onSwitch: { onSwitch(item.version) },
                        onUninstall: onUninstall != nil ? { onUninstall?(item.version) } : nil
                    )
                }
            }
        }
    }
}

// MARK: - Unified Version Card

private struct UnifiedVersionCard: View {
    let version: VersionItem
    let serviceName: String
    let accentColor: Color
    let onInstall: () -> Void
    let onSwitch: () -> Void
    let onUninstall: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Left: Version Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AXSpacing.sm) {
                    Text(serviceName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axTextTertiary)

                    Text(version.version)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.axTextPrimary)

                    // Badge (LTS, Recommended, etc.)
                    if let badge = version.badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(version.badgeColor)
                            )
                    }
                }

                // Status
                HStack(spacing: 4) {
                    if version.isCurrent {
                        Circle()
                            .fill(Color.axSuccess)
                            .frame(width: 6, height: 6)
                            .shadow(color: .axSuccess.opacity(0.5), radius: 3)

                        Text("Active")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.axSuccess)
                    } else if version.isInstalled {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 5, height: 5)

                        Text("Installed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(accentColor)
                    } else {
                        Text("Not Installed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.axTextMuted)
                    }
                }
            }

            Spacer()

            // Right: Action Buttons
            if !version.isCurrent {
                HStack(spacing: AXSpacing.xs) {
                    if version.isInstalled {
                        // Switch Button
                        Button(action: onSwitch) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.swap")
                                    .font(.system(size: 10))
                                Text("Switch")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [accentColor, accentColor.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)

                        // Uninstall Button (if supported)
                        if let onUninstall = onUninstall {
                            Button(action: onUninstall) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                    Text("Uninstall")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.axError)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        // Install Button
                        Button(action: onInstall) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 11))
                                Text("Install")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [accentColor, accentColor.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(version.isCurrent ? Color.axSurface : Color.axSurface.opacity(0.4))

                // Active version left accent
                if version.isCurrent {
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color.axSuccess, Color.axSuccess.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 3)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
                }

                // Border
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(
                        version.isCurrent ? Color.axSuccess.opacity(0.3) :
                            (isHovered ? accentColor.opacity(0.3) : Color.axBorder.opacity(0.15)),
                        lineWidth: version.isCurrent ? 1.5 : 1
                    )
            }
        )
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.03), radius: isHovered ? 8 : 2, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.003 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
