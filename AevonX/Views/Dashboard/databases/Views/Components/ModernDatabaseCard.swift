//
//  ModernDatabaseCard.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct ModernDatabaseCard: View {
    let database: DatabaseInfo
    var onOpen: (() -> Void)?
    var onBackup: (() -> Void)?
    var onDelete: (() -> Void)?
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                // Header
                HStack(spacing: AXSpacing.md) {
                    // Database icon with gradient background
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(
                                LinearGradient(
                                    colors: [database.type.brandColor.opacity(0.25), database.type.brandColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: database.type.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(database.type.brandColor)
                    }

                    VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                        Text(database.name)
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)

                        if let version = database.version {
                            Text("\(database.type.displayName) \(version)")
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        } else {
                            Text(database.type.displayName)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextTertiary)
                        }
                    }

                    Spacer()

                    // Action buttons (Permanently visible for easier access)
                    HStack(spacing: AXSpacing.xs) {
                        Button { onOpen?() } label: {
                            Image(systemName: "arrow.right.circle")
                                .font(.system(size: 13))
                                .foregroundColor(database.type.brandColor)
                                .frame(width: 26, height: 26)
                                .background(database.type.brandColor.opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .help("Open Details")

                        Button { onBackup?() } label: {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 13))
                                .foregroundColor(.axAccentGreen)
                                .frame(width: 26, height: 26)
                                .background(Color.axAccentGreen.opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .help("Create Backup")

                        Button { onDelete?() } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.axError)
                                .frame(width: 26, height: 26)
                                .background(Color.axError.opacity(0.1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .help("Delete Database")
                    }
                    
                    // Status badge with glow
                    AXStatusBadge(
                        status: database.status == .online ? .online : .offline,
                        showLabel: false,
                        size: 8
                    )
                }
                
                // Divider with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.axBorder.opacity(0.3), Color.axBorder, Color.axBorder.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                
                // Stats Row
                HStack(spacing: AXSpacing.lg) {
                    // Size
                    VStack(alignment: .leading, spacing: 2) {
                        Text(database.formattedSize)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        Text("Size")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                    
                    // Tables
                    if database.tables > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(database.tables)")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)
                            Text("Tables")
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                        }
                    }
                    
                    // Connections
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(database.connections)")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.axTextPrimary)
                        Text("Conns")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                    
                    Spacer()
                }
            }
            .padding(AXSpacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: isHovered 
                            ? [database.type.brandColor.opacity(0.4), database.type.brandColor.opacity(0.2)]
                            : [Color.axGlassBorder, Color.axBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: isHovered ? database.type.brandColor.opacity(0.15) : .clear, radius: 12, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onOpen?()
        }
    }
}
