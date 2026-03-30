//
//  Fail2BanLogsView.swift
//  AevonX
//
//  Fail2Ban log entries — ban/unban activity.
//

import SwiftUI

extension Fail2BanSection {

    var logsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: "doc.text").font(AXTypography.caption2).foregroundColor(.axAccentBlue)
                Text(L10n.ServerSettings.banLog).font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextPrimary)
                Spacer()
                if vm.fail2BanLogs.count > 20 {
                    Text(L10n.ServerSettings.last20Entries)
                        .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                }
            }

            if vm.fail2BanLogs.isEmpty {
                Text(L10n.ServerSettings.noBanLogEntries)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AXSpacing.xs)
            } else {
                ForEach(vm.fail2BanLogs.suffix(20)) { entry in
                    logRow(entry)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func logRow(_ entry: Fail2BanLogEntry) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: entry.action == "Ban" ? "nosign" : "checkmark.circle")
                .font(AXTypography.caption2)
                .foregroundColor(entry.action == "Ban" ? .axError : .axSuccess)
                .frame(width: 16)
            Text(entry.timestamp)
                .font(AXTypography.monoXs).foregroundColor(.axTextTertiary)
                .frame(width: 130, alignment: .leading)
                .lineLimit(1)
            Text(entry.jail)
                .font(AXTypography.caption2).foregroundColor(.axAccentPurple)
                .frame(width: 60, alignment: .leading)
            Text(entry.action)
                .font(AXTypography.caption2).fontWeight(.medium)
                .foregroundColor(entry.action == "Ban" ? .axError : .axSuccess)
                .frame(width: 40)
            Text(entry.ip)
                .font(AXTypography.monoXs).foregroundColor(.axTextPrimary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.vertical, AXSpacing.xxxs)
    }
}
