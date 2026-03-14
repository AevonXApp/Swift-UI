//
//  RemoteServerCard.swift
//  AevonX
//
//  Compact server card — single-row design with inline actions
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore

struct RemoteServerCard: View {
    let server: ServerViewModel
    let connectionProgress: ConnectionProgress?
    let onTap: () -> Void
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 0) {
            // ─── Left: Status indicator bar ─────────────────
            RoundedRectangle(cornerRadius: 2)
                .fill(server.isAccessible ? Color.axSuccess : Color.axTextMuted.opacity(0.4))
                .frame(width: 3, height: 36)
                .shadow(color: server.isAccessible ? .axSuccess.opacity(0.4) : .clear, radius: 4)
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
                    HStack(spacing: 3) {
                        Circle()
                            .fill(server.isAccessible ? Color.axSuccess : Color.axTextMuted)
                            .frame(width: 5, height: 5)
                        
                        Text(server.isAccessible ? "Online" : "Offline")
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
                
                HStack(spacing: AXSpacing.md) {
                    // IP
                    Label(server.host, systemImage: "network")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                        .lineLimit(1)
                    
                    // Port + User inline
                    HStack(spacing: AXSpacing.xs) {
                        Text(server.username + "@:" + "\(server.port)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.axTextMuted.opacity(0.7))
                    }
                    
                    // OS chip
                    if let os = server.osType {
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
            if !server.tags.isEmpty {
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
                        Text("+\(server.tags.count - 2)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.axTextMuted)
                    }
                }
                .padding(.trailing, AXSpacing.md)
            }
            
            // ─── Actions ────────────────────────────────────
            HStack(spacing: AXSpacing.sm) {
                // Connect button — compact
                Button(action: {
                    print("[RemoteServerCard] Connect → \(server.name)")
                    onConnect()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Connect")
                            .font(.system(size: 11, weight: .semibold))
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
                
                // Menu button — small
                Menu {
                    Button(action: onEdit) {
                        Label("Edit Server", systemImage: "pencil")
                    }
                    Button(action: {}) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    Divider()
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Server", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(isHovered ? Color.axSurface : Color.clear)
                                .overlay(
                                    Circle().stroke(Color.axBorder.opacity(isHovered ? 0.5 : 0), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
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
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { onTap() }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Server", systemImage: "pencil")
            }
            Button(action: {}) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
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
