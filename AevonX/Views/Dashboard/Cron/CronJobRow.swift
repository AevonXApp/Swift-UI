//
//  CronJobRow.swift
//  AevonX
//
//  Individual cron job row with status, schedule, and actions
//

import SwiftUI
import AevonXCore

struct CronJobRow: View {
    let job: CronJob
    let isExecuting: Bool
    let onExecute: () -> Void
    let onEdit: () -> Void
    let onLog: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            // Task type icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(typeColor.opacity(job.isEnabled ? 0.15 : 0.05))
                    .frame(width: 36, height: 36)
                Image(systemName: job.taskType.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(job.isEnabled ? typeColor : .axTextMuted)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AXSpacing.xs) {
                    Text(job.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(job.isEnabled ? .axTextPrimary : .axTextMuted)
                        .lineLimit(1)
                    
                    if !job.isEnabled {
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
                    // Schedule badge
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(job.schedule.humanReadable)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.axTextTertiary)
                    
                    // Task type
                    Text(job.taskType.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(typeColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(typeColor.opacity(0.08))
                        .cornerRadius(3)
                }
            }
            
            Spacer()
            
            // Status
            if let status = job.lastStatus {
                HStack(spacing: 3) {
                    Circle().fill(status == .success ? Color.axSuccess : Color.axError).frame(width: 6, height: 6)
                    Text(status.rawValue).font(.system(size: 10, weight: .medium)).foregroundColor(status == .success ? .axSuccess : .axError)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background((status == .success ? Color.axSuccess : Color.axError).opacity(0.08))
                .cornerRadius(4)
            }
            
            // Last executed
            if let last = job.lastExecuted {
                Text(last)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .frame(width: 90, alignment: .trailing)
            }
            
            // Actions
            HStack(spacing: AXSpacing.xs) {
                // Execute
                actionButton(icon: isExecuting ? "hourglass" : "play.fill", color: .axAccentGreen, tooltip: "Execute Now") {
                    onExecute()
                }
                .disabled(isExecuting)
                
                // Edit
                actionButton(icon: "pencil", color: .axAccentBlue, tooltip: "Edit") {
                    onEdit()
                }
                
                // Logs
                actionButton(icon: "doc.text", color: .purple, tooltip: "View Logs") {
                    onLog()
                }
                
                // Toggle
                actionButton(icon: job.isEnabled ? "pause.fill" : "play.fill", color: .axWarning, tooltip: job.isEnabled ? "Disable" : "Enable") {
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
    
    private var typeColor: Color {
        switch job.taskType {
        case .backupWebsite, .backupDatabase, .backupDirectory: return .axAccentBlue
        case .sslRenewal, .systemUpdate: return .axSuccess
        case .diskCleanup: return .axError
        case .freeRAM, .cutLog: return .orange
        case .syncTime: return .cyan
        case .accessURL: return .teal
        case .dbOptimization: return .indigo
        case .shellScript: return .axTextSecondary
        }
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
