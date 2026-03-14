//
//  RemoteServerRow.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore

struct RemoteServerRow: View {
    let server: ServerViewModel
    let connectionProgress: ConnectionProgress?
    let onTap: () -> Void
    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

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
            }

            // Server Info
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text(server.name)
                    .font(AXTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.axTextPrimary)

                HStack(spacing: AXSpacing.sm) {
                    Text("\(server.username)@\(server.host)")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)

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

            Spacer()

            // Tags
            if !server.tags.isEmpty {
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
                        Text("+\(server.tags.count - 2)")
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

            // Connect Button
            Button(action: {
                print("[RemoteServerRow] Connect button tapped for: \(server.name)")
                onConnect()
            }) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("Connect")
                        .font(AXTypography.caption2)
                }
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)

            // Actions Menu
            Menu {
                Button(action: {
                    print("[RemoteServerRow] Menu Connect tapped for: \(server.name)")
                    onConnect()
                }) {
                    Label("Connect", systemImage: "bolt.fill")
                }

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
                    .font(.system(size: 18))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .padding(.horizontal, AXSpacing.xxl)
        .padding(.vertical, AXSpacing.md)
        .contentShape(Rectangle())
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
        server.isAccessible ? "Online" : "Offline"
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
