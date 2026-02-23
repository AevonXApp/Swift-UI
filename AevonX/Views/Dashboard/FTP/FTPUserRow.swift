//
//  FTPUserRow.swift
//  AevonX
//
//  Individual FTP user row with status, path, and actions
//

import SwiftUI
import AevonXCore

struct FTPUserRow: View {
    let user: FTPUser
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onCopyPassword: () -> Void
    
    @State private var isHovered = false
    @State private var showPassword = false
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // User icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(user.status == .active ? 0.15 : 0.05))
                    .frame(width: 36, height: 36)
                Image(systemName: "person.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(user.status == .active ? statusColor : .axTextMuted)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AXSpacing.xs) {
                    Text(user.username)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(user.status == .active ? .axTextPrimary : .axTextMuted)
                        .lineLimit(1)
                    
                    if user.status == .inactive {
                        Text("DISABLED")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.axTextMuted)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.axTextMuted.opacity(0.1))
                            .cornerRadius(3)
                    }
                }
                
                HStack(spacing: AXSpacing.sm) {
                    // Document root
                    HStack(spacing: 3) {
                        Image(systemName: "folder")
                            .font(.system(size: 9))
                        Text(user.documentRoot)
                            .font(.system(size: 10, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(.axTextTertiary)
                    
                    // Quota badge
                    Text(user.quotaDisplay)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.axAccentBlue.opacity(0.08))
                        .cornerRadius(3)
                }
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 3) {
                Circle()
                    .fill(user.status == .active ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 6, height: 6)
                Text(user.status.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(user.status == .active ? .axSuccess : .axTextMuted)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background((user.status == .active ? Color.axSuccess : Color.axTextMuted).opacity(0.08))
            .cornerRadius(4)
            
            // Password (masked/visible)
            Button(action: { showPassword.toggle() }) {
                Text(showPassword ? user.password : user.maskedPassword)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .frame(width: 90, alignment: .trailing)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Click to toggle password visibility")
            
            // Actions
            HStack(spacing: AXSpacing.xs) {
                // Copy password
                actionButton(icon: "doc.on.doc", color: .axAccentBlue, tooltip: "Copy Password") {
                    onCopyPassword()
                }
                
                // Edit
                actionButton(icon: "pencil", color: .axAccentBlue, tooltip: "Edit") {
                    onEdit()
                }
                
                // Toggle
                actionButton(
                    icon: user.status == .active ? "pause.fill" : "play.fill",
                    color: .axWarning,
                    tooltip: user.status == .active ? "Disable" : "Enable"
                ) {
                    onToggle()
                }
                
                // Delete
                actionButton(icon: "trash", color: .axError, tooltip: "Delete") {
                    onDelete()
                }
            }
            .opacity(isHovered ? 1 : 0.4)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isHovered ? Color.axSurface.opacity(0.5) : Color.clear)
        )
        .onHover { isHovered = $0 }
    }
    
    private var statusColor: Color {
        user.status == .active ? .axAccentGreen : .axTextMuted
    }
    
    private func actionButton(icon: String, color: Color, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.08))
                .cornerRadius(5)
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
    }
}
