//
//  FirewallRulesView.swift
//  AevonX
//
//  Firewall rules table with delete action.
//

import SwiftUI

extension FirewallSection {

    private var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

    var rulesTable: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                Text(L10n.ServerSettings.rulesCount(vm.firewallRules.count))
                    .font(AXTypography.caption).fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                Spacer()
            }

            if vm.firewallRules.isEmpty {
                Text(L10n.ServerSettings.noRulesConfigured)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AXSpacing.sm)
            } else {
                rulesHeader
                ForEach(vm.firewallRules) { rule in
                    ruleRow(rule)
                }
            }

            // Save message
            if let (msg, ok) = vm.saveMsg {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(msg)
                }
                .font(AXTypography.caption).fontWeight(.medium)
                .foregroundColor(ok ? .axSuccess : .axError)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private var rulesHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Text("#").frame(width: 25, alignment: .trailing)
            Text(L10n.ServerSettings.action).frame(width: 55, alignment: .leading)
            Text(L10n.ServerSettings.proto).frame(width: 40, alignment: .leading)
            Text(L10n.Field.port).frame(width: 55, alignment: .leading)
            Text(L10n.ServerSettings.source).frame(minWidth: 80, alignment: .leading)
            Spacer()
            Text("").frame(width: 24)
        }
        .font(AXTypography.caption2).fontWeight(.semibold)
        .foregroundColor(.axTextMuted)
    }

    private func ruleRow(_ rule: ServerFirewallRule) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text("\(rule.id)")
                .font(AXTypography.monoXs).foregroundColor(.axTextTertiary)
                .frame(width: 25, alignment: .trailing)
            Text(rule.action)
                .font(AXTypography.monoXs).fontWeight(.medium)
                .foregroundColor(rule.action.uppercased().contains("ALLOW") || rule.action.uppercased().contains("ACCEPT") ? .axSuccess : .axError)
                .frame(width: 55, alignment: .leading)
            Text(rule.proto)
                .font(AXTypography.monoXs).foregroundColor(.axAccentBlue)
                .frame(width: 40, alignment: .leading)
            Text(rule.port)
                .font(AXTypography.monoXs).foregroundColor(.axTextPrimary)
                .frame(width: 55, alignment: .leading)
            Text(isMasking && settings.maskIPAddresses ? PrivacyMask.ip(rule.source) : rule.source)
                .font(AXTypography.caption2).foregroundColor(.axTextSecondary)
                .lineLimit(1)
                .frame(minWidth: 80, alignment: .leading)
            Spacer()
            Button(action: { Task { await vm.deleteFirewallRule(rule) } }) {
                Image(systemName: "trash")
                    .font(AXTypography.caption2).foregroundColor(.axError)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, AXSpacing.xxxs)
    }
}
