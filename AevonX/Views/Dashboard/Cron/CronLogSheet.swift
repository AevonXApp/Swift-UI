//
//  CronLogSheet.swift
//  AevonX
//
//  Execution log viewer for cron jobs
//

import SwiftUI
import AevonXCoreBridge

struct CronLogSheet: View {
    @ObservedObject var vm: CronViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Execution Log")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    if let job = vm.logJob {
                        Text(job.name)
                            .font(.system(size: 12))
                            .foregroundColor(.axTextTertiary)
                    }
                }
                Spacer()
                
                if let job = vm.logJob {
                    Button(action: { Task { await vm.clearLogs(for: job) } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash").font(.system(size: 10))
                            Text("Clear").font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.axError)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.axError.opacity(0.08))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { Task { await vm.loadLogs(for: job) } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise").font(.system(size: 10))
                            Text("Refresh").font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.axAccentBlue.opacity(0.08))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            
            Divider().background(Color.axBorder)
            
            if vm.isLoadingLogs {
                Spacer()
                ProgressView().scaleEffect(0.8)
                Text("Loading logs...").font(AXTypography.caption).foregroundColor(.axTextTertiary)
                Spacer()
            } else if vm.logEntries.isEmpty {
                Spacer()
                VStack(spacing: AXSpacing.sm) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.axTextMuted)
                    Text("No execution logs yet")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextTertiary)
                    Text("Logs will appear after the task is executed")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: AXSpacing.sm) {
                        ForEach(vm.logEntries) { entry in
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                HStack {
                                    Circle()
                                        .fill(entry.isSuccess ? Color.axSuccess : Color.axError)
                                        .frame(width: 8, height: 8)
                                    Text(entry.isSuccess ? "Successful" : "Failed")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(entry.isSuccess ? .axSuccess : .axError)
                                    
                                    Spacer()
                                    
                                    if !entry.timestamp.isEmpty {
                                        Text(formatTimestamp(entry.timestamp))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.axTextTertiary)
                                    }
                                }
                                
                                // Output block
                                ScrollView(.horizontal, showsIndicators: false) {
                                    Text(entry.output)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(Color(red: 0.6, green: 0.9, blue: 0.6))
                                        .padding(AXSpacing.sm)
                                }
                                .frame(maxHeight: 150)
                                .background(Color(red: 0.06, green: 0.06, blue: 0.08))
                                .cornerRadius(AXCornerRadius.sm)
                            }
                            .padding(AXSpacing.md)
                            .background(Color.axSurface.opacity(0.4))
                            .cornerRadius(AXCornerRadius.md)
                        }
                    }
                    .padding(AXSpacing.xl)
                }
            }
        }
        .frame(width: 600, height: 500)
        .background(Color.axBackground)
    }
    
    /// Format timestamp: convert ISO8601 to readable, or pass through already-formatted strings
    private func formatTimestamp(_ raw: String) -> String {
        // Try ISO8601 first (old logs)
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: raw) {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df.string(from: date)
        }
        // Already in readable format or unknown — return as-is
        return raw
    }
}
