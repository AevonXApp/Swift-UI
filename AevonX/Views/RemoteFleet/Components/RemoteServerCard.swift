//
//  RemoteServerCard.swift
//  AevonX
//
//  Compact server card — single-row design with inline actions
//

import SwiftUI
import AevonXCoreBridge

struct RemoteServerCard: View {
    let server: ServerViewModel
    let connectionProgress: ConnectionProgress?
    let onTap: () -> Void
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    var onLaunch: (() -> Void)? = nil
    var onUpgrade: (() -> Void)? = nil

    @EnvironmentObject var settings: AppSettingsManager
    @State private var isHovered = false
    @State private var showDeleteConfirmation = false

    private var isLocked: Bool { server.accessLevel != .full }
    
    var body: some View {
        HStack(spacing: 0) {
            // ─── Left: Status indicator bar ─────────────────
            RoundedRectangle(cornerRadius: 2)
                .fill(isLocked ? Color.axTextMuted.opacity(0.3) : (server.isAccessible ? Color.axSuccess : Color.axTextMuted.opacity(0.4)))
                .frame(width: 3, height: 36)
                .shadow(color: (!isLocked && server.isAccessible) ? .axSuccess.opacity(0.4) : .clear, radius: 4)
                .padding(.trailing, AXSpacing.md)
            
            // ─── Icon ───────────────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [customColor.opacity(0.2), customColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(customColor.opacity(0.2), lineWidth: 1)
                    )

                Image(systemName: server.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(customColor)

                // Lock badge for non-accessible servers
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
            .padding(.trailing, AXSpacing.md)
            
            // ─── Server info ────────────────────────────────
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AXSpacing.sm) {
                    Text(server.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                    
                    // Status badge
                    if isLocked {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                            Text(L10n.Fleet.freeLimit)
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(.axWarning)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.axWarning.opacity(0.12))
                        )
                    } else {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(server.isAccessible ? Color.axSuccess : Color.axTextMuted)
                                .frame(width: 5, height: 5)

                            Text(server.isAccessible ? L10n.Fleet.statusOnline : L10n.Fleet.statusOffline)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(server.isAccessible ? .axSuccess : .axTextMuted)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(server.isAccessible ? Color.axSuccess.opacity(0.1) : Color.axSurface)
                        )
                    }
                }
                
                HStack(spacing: AXSpacing.md) {
                    // IP
                    Label(maskedHost, systemImage: "network")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                        .help(settings.showRealOnHover && isMasking ? server.host : "")

                    // Port + User inline
                    if settings.showPortInfo {
                        HStack(spacing: AXSpacing.xs) {
                            Text(maskedUsername + "@:" + maskedPort)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.axTextMuted.opacity(0.7))
                        }
                    }

                    // OS chip
                    if settings.showServerOS, let os = server.osType {
                        HStack(spacing: 3) {
                            Image(systemName: osIcon)
                                .font(.system(size: 8))
                            Text(os)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.axTextMuted)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.axSurface.opacity(0.6))
                        .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            // ─── Tags (compact) ─────────────────────────────
            if settings.showServerTags && !server.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(server.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(customColor.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(customColor.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    if server.tags.count > 2 {
                        Text(L10n.Fleet.moreTagsCount(server.tags.count - 2))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.axTextMuted)
                    }
                }
                .padding(.trailing, AXSpacing.md)
            }
            
            // ─── Actions ────────────────────────────────────
            HStack(spacing: AXSpacing.sm) {
                if isLocked {
                    // Locked: Upgrade button
                    Button(action: { onUpgrade?() }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text(L10n.Button.upgrade)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.axAccentBlue.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                } else {
                    // Connect button — compact
                    Button(action: {
                        debugLog("[RemoteServerCard] Connect → \(server.name)")
                        onConnect()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text(L10n.Button.connect)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: isHovered ? .axAccentBlue.opacity(0.35) : .clear, radius: 6, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                }

                // Action menu — AX design system
                AXActionMenu.serverActions(
                    onEdit: onEdit,
                    onDuplicate: {},
                    onCopyIP: { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(server.host, forType: .string) },
                    onDelete: onDelete
                )
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(isHovered ? Color.axSurface : Color.axSurface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(
                    isHovered ? customColor.opacity(0.25) : Color.axBorder.opacity(0.3),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isHovered ? customColor.opacity(0.08) : Color.black.opacity(0.02),
            radius: isHovered ? 8 : 2,
            y: isHovered ? 3 : 1
        )
        .opacity(isLocked ? 0.55 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture {
            if isLocked {
                onUpgrade?()
            } else {
                onTap()
            }
        }
        .contextMenu {
            Button(action: onEdit) {
                Label(L10n.Fleet.editServer, systemImage: "pencil")
            }
            Button(action: { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(server.host, forType: .string) }) {
                Label(L10n.Fleet.copyIP, systemImage: "doc.on.clipboard")
            }
            if let onLaunch {
                Button(action: onLaunch) {
                    Label(L10n.AXLaunch.contextMenuLaunch, systemImage: "paperplane")
                }
            }
            Divider()
            Button(role: .destructive, action: {
                if settings.shouldConfirm(for: SettingsKey.confirmDeleteServer) {
                    showDeleteConfirmation = true
                } else {
                    onDelete()
                }
            }) {
                Label(L10n.Button.delete, systemImage: "trash")
            }
        }
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
    
    // MARK: - Helpers
    
    private var customColor: Color {
        if let hex = server.customColor {
            return Color(hex: hex)
        }
        return .axAccentBlue
    }
    
    // MARK: - Privacy Masking

    private var isMasking: Bool { settings.maskServerInfo }

    private var maskedHost: String {
        isMasking && settings.maskIPAddresses ? PrivacyMask.ip(server.host) : server.host
    }

    private var maskedUsername: String {
        isMasking && settings.maskUsernames ? PrivacyMask.username(server.username) : server.username
    }

    private var maskedPort: String {
        isMasking && settings.maskPortNumbers ? PrivacyMask.port(server.port) : "\(server.port)"
    }

    private var osIcon: String {
        let os = server.osType?.lowercased() ?? ""
        if os.contains("ubuntu") || os.contains("debian") || os.contains("linux") {
            return "terminal"
        } else if os.contains("windows") {
            return "desktopcomputer"
        } else if os.contains("mac") || os.contains("darwin") {
            return "apple.terminal"
        }
        return "server.rack"
    }
}
