//
//  FirewallControlsView.swift
//  AevonX
//
//  Firewall status toggle, add rule, block IP controls.
//

import SwiftUI

extension FirewallSection {

    private var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

    var statusRow: some View {
        HStack {
            HStack(spacing: AXSpacing.xxs) {
                Circle()
                    .fill(vm.firewallEnabled ? Color.axSuccess : Color.axError)
                    .frame(width: 8, height: 8)
                Text(vm.firewallEnabled ? L10n.Status.active : L10n.Status.inactive)
                    .font(AXTypography.caption).fontWeight(.semibold)
                    .foregroundColor(vm.firewallEnabled ? .axSuccess : .axError)
            }
            Spacer()
            Button(action: { Task { await vm.toggleFirewall() } }) {
                Text(vm.firewallEnabled ? L10n.Status.disabled : L10n.Status.enabled)
                    .font(AXTypography.caption2).fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
                    .background(vm.firewallEnabled ? Color.axError : Color.axSuccess)
                    .cornerRadius(AXCornerRadius.sm)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    var addRuleRow: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.ServerSettings.addRule).font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextPrimary)
            HStack(spacing: AXSpacing.xs) {
                TextField(L10n.Field.port, text: $vm.newRulePort)
                    .font(AXTypography.monoXs).textFieldStyle(.plain)
                    .frame(width: 60)
                    .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxs)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.sm)

                Picker("", selection: $vm.newRuleProto) {
                    Text(L10n.ServerSettings.tcp).tag("tcp")
                    Text(L10n.ServerSettings.udp).tag("udp")
                }
                .pickerStyle(.segmented).frame(width: 100)

                Picker("", selection: $vm.newRuleAction) {
                    Text(L10n.ServerSettings.allow).tag("allow")
                    Text(L10n.ServerSettings.deny).tag("deny")
                }
                .pickerStyle(.segmented).frame(width: 100)

                Button(action: { Task { await vm.addFirewallRule() } }) {
                    Image(systemName: "plus.circle.fill")
                        .font(AXTypography.body).foregroundColor(.axAccentBlue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(vm.newRulePort.isEmpty)

                Spacer()

                // Quick rules
                quickRuleButton(L10n.ServerSettings.ssh, port: "22")
                quickRuleButton(L10n.ServerSettings.http, port: "80")
                quickRuleButton(L10n.ServerSettings.https, port: "443")
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func quickRuleButton(_ label: String, port: String) -> some View {
        Button(action: {
            vm.newRulePort = port
            vm.newRuleProto = "tcp"
            vm.newRuleAction = "allow"
            Task { await vm.addFirewallRule() }
        }) {
            Text(label)
                .font(AXTypography.caption2).fontWeight(.medium)
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxxs)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
        }.buttonStyle(PlainButtonStyle())
    }

    var blockIPRow: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: "nosign").font(AXTypography.caption2).foregroundColor(.axError)
            TextField(L10n.ServerSettings.blockIPPlaceholder, text: $vm.blockIPText)
                .font(AXTypography.monoXs).textFieldStyle(.plain)
                .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxs)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)
            Button(action: { Task { await vm.blockIP() } }) {
                Text(L10n.ServerSettings.block)
                    .font(AXTypography.caption2).fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
                    .background(Color.axError)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(vm.blockIPText.isEmpty)
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }
}
