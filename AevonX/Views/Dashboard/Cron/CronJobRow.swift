//
//  CronJobRow.swift
//  AevonX
//
//  Website-style BlueprintNode card for individual cron jobs
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
        HStack(spacing: 14) {
            // Icon container — matches website bg-cyan-500/15 border border-cyan-500/25
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(typeColor.opacity(job.isEnabled ? 0.12 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(typeColor.opacity(job.isEnabled ? 0.25 : 0.08), lineWidth: 1)
                    )
                Image(systemName: job.taskType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(job.isEnabled ? typeColor : .white.opacity(0.2))
            }
            .frame(width: 42, height: 42)
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .rotationEffect(.degrees(isHovered ? -3 : 0))
            .animation(.spring(response: 0.35), value: isHovered)
            
            // Info block
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(job.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(job.isEnabled ? .white.opacity(0.85) : .white.opacity(0.35))
                        .lineLimit(1)
                    
                    if !job.isEnabled {
                        Text("DISABLED")
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundColor(.white.opacity(0.25))
                            .tracking(1)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                            .cornerRadius(4)
                    }
                }
                
                // Metadata tags — matches website text-[10px] px-2.5 py-1 rounded-lg pills
                HStack(spacing: 6) {
                    // Schedule pill
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 8))
                        Text(job.schedule.humanReadable)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(typeColor.opacity(0.6))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(typeColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(typeColor.opacity(0.1), lineWidth: 1)
                    )
                    .cornerRadius(6)
                    
                    // Task type pill
                    Text(job.taskType.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.04), lineWidth: 1)
                        )
                        .cornerRadius(6)
                }
            }
            
            Spacer()
            
            // Status indicator
            if let status = job.lastStatus {
                HStack(spacing: 4) {
                    Circle()
                        .fill(status == .success ? Color.green.opacity(0.7) : Color.red.opacity(0.7))
                        .frame(width: 6, height: 6)
                    Text(status.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(status == .success ? .green.opacity(0.7) : .red.opacity(0.7))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((status == .success ? Color.green : Color.red).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke((status == .success ? Color.green : Color.red).opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(6)
            }
            
            // Action buttons — reveal on hover
            HStack(spacing: 4) {
                actionButton(icon: isExecuting ? "hourglass" : "play.fill", color: .green, tooltip: "Execute Now") { onExecute() }
                    .disabled(isExecuting)
                actionButton(icon: "pencil", color: .axAccentBlue, tooltip: "Edit") { onEdit() }
                actionButton(icon: "doc.text", color: .purple, tooltip: "Logs") { onLog() }
                actionButton(icon: job.isEnabled ? "pause.fill" : "play.fill", color: .orange, tooltip: job.isEnabled ? "Disable" : "Enable") { onToggle() }
                actionButton(icon: "trash", color: .red, tooltip: "Delete") { onDelete() }
            }
            .opacity(isHovered ? 1 : 0.25)
            .animation(.easeOut(duration: 0.2), value: isHovered)
        }
        .padding(14)
        .background(
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isHovered ? 0.025 : 0.012))
                // Border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isHovered ? typeColor.opacity(0.2) : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
                // Top glow bar on hover
                if isHovered {
                    VStack {
                        LinearGradient(
                            colors: [.clear, typeColor.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        )
        .offset(y: isHovered ? -1 : 0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { isHovered = $0 }
    }
    
    // MARK: - Helpers
    
    private var typeColor: Color {
        switch job.taskType {
        case .backupWebsite, .backupDatabase, .backupDirectory: return Color(red: 0.13, green: 0.83, blue: 0.93) // cyan-400
        case .sslRenewal: return .green
        case .systemUpdate: return Color(red: 0.13, green: 0.83, blue: 0.93)
        case .diskCleanup: return .red
        case .freeRAM, .cutLog: return .orange
        case .syncTime: return .cyan
        case .accessURL: return .teal
        case .dbOptimization: return .indigo
        case .shellScript: return Color(red: 0.13, green: 0.83, blue: 0.93) // default cyan
        }
    }
    
    private func actionButton(icon: String, color: Color, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color.opacity(0.7))
                .frame(width: 26, height: 26)
                .background(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(7)
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
    }
}
