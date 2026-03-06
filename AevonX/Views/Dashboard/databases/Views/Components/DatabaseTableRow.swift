//
//  DatabaseTableRow.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DatabaseTableRow: View {
    let database: DatabaseInfo
    var onOpen: (() -> Void)?
    var onBackup: (() -> Void)?
    var onDelete: (() -> Void)?
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Identifier (Icon + Name)
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(database.type.brandColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: database.type.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(database.type.brandColor)
                }
                
                Text(database.name)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Engine
            Text(database.type.displayName)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .frame(width: 120, alignment: .leading)
            
            // Version
            Text(database.version ?? "-")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextTertiary)
                .frame(width: 100, alignment: .leading)
            
            // Size
            Text(AXFormatter.formatSizeMB(database.size))
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .frame(width: 100, alignment: .leading)
            
            // Tables
            Text("\(database.tables)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .frame(width: 80, alignment: .trailing)
            
            // Status
            HStack {
                AXStatusBadge(
                    status: database.status == .online ? .online : .offline,
                    showLabel: false,
                    size: 6
                )
            }
            .frame(width: 80, alignment: .center)
            
            // Inline Actions (Permanently visible for easier access)
            HStack(spacing: AXSpacing.sm) {
                Button { onOpen?() } label: {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
                .help("Open Details")

                Button { onBackup?() } label: {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.axAccentGreen)
                }
                .buttonStyle(.plain)
                .help("Create Backup")

                Button { onDelete?() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.axError)
                }
                .buttonStyle(.plain)
                .help("Delete Database")
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isHovered ? Color.axSurfaceHover : Color.clear)
        )
        .onTapGesture {
            onOpen?()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
