//
//  LogViewerView.swift
//  AevonX
//
//  Log content viewer and log file sizes.
//

import SwiftUI

extension SystemLogsSection {

    var logViewer: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            if vm.isLoadingLogs {
                AXSkeletonBlock(lines: 8)
            } else {
                ScrollView {
                    Text(vm.logContent.isEmpty ? L10n.ServerSettings.noLogEntries : vm.logContent)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(vm.logContent.isEmpty ? .axTextMuted : .axTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 300)
                .padding(AXSpacing.xs)
                .background(Color.axBackgroundTertiary.opacity(0.5))
                .cornerRadius(AXCornerRadius.sm)
            }
        }
    }

    var logSizesView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: "internaldrive").font(AXTypography.caption2).foregroundColor(.axAccentBlue)
                Text(L10n.ServerSettings.logFileSizes).font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextPrimary)
                Spacer()
                Button(action: { Task { await vm.clearLog("all") } }) {
                    Text(L10n.ServerSettings.rotateAll)
                        .font(AXTypography.caption2).foregroundColor(.axWarning)
                }.buttonStyle(PlainButtonStyle())
            }

            ForEach(vm.logSizes) { logFile in
                HStack {
                    Text(logFile.filename)
                        .font(AXTypography.monoXs).foregroundColor(.axTextSecondary)
                    Spacer()
                    Text(logFile.size)
                        .font(AXTypography.monoXs).fontWeight(.medium)
                        .foregroundColor(.axAccentBlue)
                    Button(action: { Task { await vm.clearLog(logFile.path) } }) {
                        Image(systemName: "trash")
                            .font(AXTypography.caption2).foregroundColor(.axError.opacity(0.7))
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, AXSpacing.xxxs)
            }

            // Message
            if let (msg, ok) = vm.saveMsg {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(msg)
                }
                .font(AXTypography.caption).foregroundColor(ok ? .axSuccess : .axError)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }
}
