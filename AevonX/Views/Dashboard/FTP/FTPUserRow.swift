//
//  FTPUserRow.swift
//  AevonX
//
//  Individual FTP user row – single line with aligned columns
//

import SwiftUI
import AevonXCoreBridge

struct FTPUserRow: View {
    let user: FTPUser
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onCopyPassword: () -> Void
    
    @EnvironmentObject var settings: AppSettingsManager
    @State private var isHovered = false
    @State private var showPassword = false
    @State private var showCopied = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Column 1: User (icon + username + path)
            HStack(spacing: AXSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: "person.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(settings.maskServerInfo && settings.maskInDashboard && settings.maskUsernames ? PrivacyMask.username(user.username) : user.username)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(user.status == .active ? .axTextPrimary : .axTextMuted)
                            .lineLimit(1)
                        
                        if user.status == .inactive {
                            Text("DISABLED")
                                .font(.system(size: 7, weight: .heavy))
                                .foregroundColor(.axTextMuted)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.axTextMuted.opacity(0.1))
                                .cornerRadius(3)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 8))
                        Text(user.documentRoot)
                            .font(.system(size: 9, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(.axTextTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Column 2: Quota
            Text(user.quotaDisplay)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.axAccentBlue.opacity(0.08))
                .cornerRadius(4)
                .frame(width: 80, alignment: .center)
            
            // Column 3: Status
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
            .frame(width: 80, alignment: .center)
            
            // Column 4: Password
            Button(action: { showPassword.toggle() }) {
                Text(showPassword ? user.password : "••••••")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
            }
            .buttonStyle(.plain)
            .help("Click to toggle visibility")
            .frame(width: 80, alignment: .center)
            
            // Column 5: Actions
            HStack(spacing: 4) {
                actionBtn(
                    icon: showCopied ? "checkmark.circle.fill" : "doc.on.doc",
                    color: showCopied ? .axSuccess : .axAccentBlue,
                    tip: "Copy Password"
                ) {
                    onCopyPassword()
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showCopied = false }
                }
                actionBtn(icon: "pencil", color: .axAccentBlue, tip: "Edit", action: onEdit)
                actionBtn(
                    icon: user.status == .active ? "pause.fill" : "play.fill",
                    color: .axWarning,
                    tip: user.status == .active ? "Disable" : "Enable",
                    action: onToggle
                )
                actionBtn(icon: "trash", color: .axError, tip: "Delete", action: onDelete)
            }
            .frame(width: 130, alignment: .trailing)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isHovered ? Color.axSurface.opacity(0.6) : Color.clear)
        )
        .onHover { isHovered = $0 }
    }
    
    private var statusColor: Color {
        user.status == .active ? .axAccentGreen : .axTextMuted
    }
    
    private func actionBtn(icon: String, color: Color, tip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.08))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(tip)
    }
}
