//
//  RemoteServerCard.swift
//  AevonX
//

import SwiftUI
import AevonXCore

struct RemoteServerCard: View {
    let server: ServerViewModel
    let connectionProgress: ConnectionProgress?
    let onTap: () -> Void
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var showContextMenu = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                // Header Row
                HStack(spacing: AXSpacing.md) {
                    // Server Icon with enhanced glow
                    ZStack {
                        // Animated glow for online servers
                        if server.isAccessible {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.axSuccess.opacity(0.3), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)
                        }

                        // Icon background with gradient
                        RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [customColor.opacity(0.25), customColor.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                                    .stroke(customColor.opacity(0.3), lineWidth: 1)
                            )

                        Image(systemName: server.iconName)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(customColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(AXTypography.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)

                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "network")
                                .font(.system(size: 10))
                                .foregroundColor(.axTextTertiary)
                            Text(server.host)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Status Badge with enhanced design
                    VStack(spacing: 4) {
                        Circle()
                            .fill(server.isAccessible ? Color.axSuccess : Color.axTextMuted)
                            .frame(width: 8, height: 8)
                            .shadow(color: server.isAccessible ? Color.axSuccess.opacity(0.5) : .clear, radius: 4)

                        Text(server.isAccessible ? "Online" : "Offline")
                            .font(AXTypography.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(server.isAccessible ? .axSuccess : .axTextMuted)
                    }
                }

                // Divider
                Divider()
                    .background(Color.axBorder.opacity(0.5))

                // Server Details Grid
                VStack(spacing: AXSpacing.sm) {
                    HStack(spacing: AXSpacing.md) {
                        // OS Info
                        DetailChip(
                            icon: osIcon,
                            text: server.osType ?? "Linux",
                            color: .axTextSecondary
                        )

                        // User
                        DetailChip(
                            icon: "person.fill",
                            text: server.username,
                            color: .axTextSecondary
                        )

                        Spacer()
                    }

                    // Location and Port
                    HStack(spacing: AXSpacing.md) {
                        if let location = server.location {
                            DetailChip(
                                icon: "mappin.circle.fill",
                                text: location,
                                color: .axAccentBlue
                            )
                        }

                        DetailChip(
                            icon: "point.3.connected.trianglepath.dotted",
                            text: ":\(server.port)",
                            color: .axTextMuted
                        )

                        Spacer()
                    }
                }

                // Tags Row
                if !server.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AXSpacing.xs) {
                            ForEach(server.tags.prefix(3), id: \.self) { tag in
                                TagChip(text: tag, color: customColor)
                            }

                            if server.tags.count > 3 {
                                Text("+\(server.tags.count - 3)")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axTextMuted)
                                    .padding(.horizontal, AXSpacing.sm)
                            }
                        }
                    }
                }
            }
            .padding(AXSpacing.lg)
            
            // Action Footer with enhanced styling
            VStack(spacing: 0) {
                Divider()
                    .background(Color.axBorder.opacity(0.5))

                HStack(spacing: AXSpacing.sm) {
                    // Connect Button (Primary) - Full width with hover effect
                    Button(action: {
                        print("[RemoteServerCard] Connect button tapped for: \(server.name)")
                        onConnect()
                    }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                            Text("Connect Now")
                                .font(AXTypography.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.axAccentBlue, Color.axAccentBlue.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: isHovered ? Color.axAccentBlue.opacity(0.4) : .clear, radius: 8, y: 4)
                        )
                    }
                    .buttonStyle(.plain)

                    // Context Menu Button - Compact
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit Server", systemImage: "pencil")
                        }

                        Button(action: {
                            // Duplicate action placeholder
                        }) {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive, action: onDelete) {
                            Label("Delete Server", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.axTextSecondary)
                            .frame(width: 42, height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .fill(Color.axSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                            .stroke(Color.axBorder, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.md)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .fill(Color.axSurface)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .strokeBorder(
                    LinearGradient(
                        colors: isHovered
                            ? [customColor.opacity(0.6), customColor.opacity(0.3)]
                            : [Color.axBorder.opacity(0.5), Color.axBorder.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isHovered ? 2 : 1
                )
        )
        .shadow(
            color: isHovered ? customColor.opacity(0.25) : Color.black.opacity(0.03),
            radius: isHovered ? 16 : 4,
            y: isHovered ? 8 : 2
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Server", systemImage: "pencil")
            }

            Button(action: {
                // Duplicate placeholder
            }) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var customColor: Color {
        if let hex = server.customColor {
            return Color(hex: hex)
        }
        return .axAccentBlue
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
