//
//  RemoteServerRow.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

struct RemoteServerRow: View {
    let server: ServerViewModel
    let connectionProgress: ConnectionProgress?
    let onTap: () -> Void
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    var onUpgrade: (() -> Void)? = nil

    @EnvironmentObject var settings: AppSettingsManager
    @State private var showDeleteConfirmation = false

    private var isLocked: Bool { server.accessLevel != .full }

    var body: some View {
        HStack(spacing: AXSpacing.lg) {
            // Server Icon
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(customColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: server.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(customColor)

                if isLocked {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.55))
                            .frame(width: 18, height: 18)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 14, y: 14)
                }
            }

            // Server Info
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(server.name)
                        .font(AXTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(isLocked ? .axTextMuted : .axTextPrimary)

                    if isLocked {
                        Text(L10n.Fleet.pro)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.xs)
                            .padding(.vertical, 1)
                            .background(Color.axAccentBlue.opacity(0.12))
                            .cornerRadius(AXCornerRadius.xs)
                    }
                }

                HStack(spacing: AXSpacing.sm) {
                    Text("\(maskedUsername)@\(maskedHost)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                        .help(settings.showRealOnHover && isMasking ? "\(server.username)@\(server.host)" : "")

                    if isLocked {
                        // Free Limit badge
                        HStack(spacing: AXSpacing.xxs) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                            Text(L10n.Fleet.freeLimit)
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(.axWarning)
                    } else {
                        // Status
                        HStack(spacing: AXSpacing.xs) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(statusText)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }

                        // Access Level
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: accessLevelIcon)
                                .font(.caption2)
                            Text(accessLevelText)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                    }
                }
            }

            Spacer()

            // Tags
            if settings.showServerTags && !server.tags.isEmpty {
                HStack(spacing: AXSpacing.xs) {
                    ForEach(server.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(AXTypography.caption2)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, AXSpacing.xxs)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.full)
                    }
                    if server.tags.count > 2 {
                        Text(L10n.Fleet.moreTagsCount(server.tags.count - 2))
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }

            // Created Date
            Text(formattedDate(server.createdAt))
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .frame(width: 80)

            // Connect / Upgrade Button
            if isLocked {
                Button(action: { onUpgrade?() }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text(L10n.Button.upgrade)
                            .font(AXTypography.caption2)
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    debugLog("[RemoteServerRow] Connect button tapped for: \(server.name)")
                    onConnect()
                }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text(L10n.Button.connect)
                            .font(AXTypography.caption2)
                    }
                    .foregroundColor(.axBackground)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }

            // Actions Menu
            Menu {
                Button(action: {
                    if isLocked {
                        onUpgrade?()
                    } else {
                        debugLog("[RemoteServerRow] Menu Connect tapped for: \(server.name)")
                        onConnect()
                    }
                }) {
                    Label(isLocked ? L10n.Button.upgrade : L10n.Button.connect,
                          systemImage: isLocked ? "lock.fill" : "bolt.fill")
                }

                Button(action: onEdit) {
                    Label(L10n.Fleet.editServer, systemImage: "pencil")
                }

                Button(action: {
                    // Duplicate action placeholder
                }) {
                    Label(L10n.Fleet.duplicate, systemImage: "doc.on.doc")
                }

                Divider()

                Button(role: .destructive, action: {
                    if settings.shouldConfirm(for: SettingsKey.confirmDeleteServer) {
                        showDeleteConfirmation = true
                    } else {
                        onDelete()
                    }
                }) {
                    Label(L10n.Fleet.deleteServer, systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.vertical, AXSpacing.md)
        .opacity(isLocked ? 0.55 : 1.0)
        .contentShape(Rectangle())
        .overlay {
            if showDeleteConfirmation {
                AXDeleteConfirmation(
                    title: "Delete Server?",
                    itemName: server.name,
                    warning: "This will permanently remove the server and all its data.",
                    onConfirm: {
                        showDeleteConfirmation = false
                        onDelete()
                    },
                    onCancel: { showDeleteConfirmation = false }
                )
            }
        }
    }
    
    // MARK: - Privacy Masking

    private var isMasking: Bool { settings.maskServerInfo }

    private var maskedHost: String {
        isMasking && settings.maskIPAddresses ? PrivacyMask.ip(server.host) : server.host
    }

    private var maskedUsername: String {
        isMasking && settings.maskUsernames ? PrivacyMask.username(server.username) : server.username
    }

    private var customColor: Color {
        if let hex = server.customColor {
            return Color(hex: hex)
        }
        return .axAccentBlue
    }
    
    private var statusColor: Color {
        server.isAccessible ? .axSuccess : .axTextMuted
    }
    
    private var statusText: String {
        server.isAccessible ? L10n.Fleet.statusOnline : L10n.Fleet.statusOffline
    }
    
    private var accessLevelIcon: String {
        switch server.accessLevel {
        case .full: return "lock.open"
        case .readOnly: return "eye"
        case .none: return "lock"
        }
    }
    
    private var accessLevelText: String {
        switch server.accessLevel {
        case .full: return "Full"
        case .readOnly: return "Read"
        case .none: return "None"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
