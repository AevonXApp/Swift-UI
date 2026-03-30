//
//  SSHSecuritySection.swift
//  AevonX
//
//  SSH security configuration card.
//

import SwiftUI

struct SSHSecuritySection: View {
    @ObservedObject var vm: ServerSettingsViewModel

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                SettingsGradientHeader(icon: "lock.shield.fill", title: L10n.ServerSettings.sshSecurity, subtitle: L10n.ServerSettings.sshdConfigMgmt, gradient: [.axError, .axError.opacity(0.7)])
                Divider().background(Color.axBorder)

                if vm.isLoadingSSH {
                    AXSkeletonBlock(lines: 5)
                } else {
                    VStack(spacing: AXSpacing.sm) {
                        SettingsInfoRow(icon: "number", title: L10n.ServerSettings.sshPort, value: vm.sshPort)
                        ServerSettingsToggleRow(icon: "person.crop.circle.badge.exclamationmark", title: L10n.ServerSettings.permitRootLogin, isOn: $vm.permitRootLogin, tint: .axError)
                        ServerSettingsToggleRow(icon: "key.horizontal", title: L10n.ServerSettings.passwordAuth, isOn: $vm.passwordAuthEnabled, tint: .axWarning)
                        SettingsInfoRow(icon: "person.2.badge.key", title: L10n.ServerSettings.maxAuthTries, value: vm.maxAuthTries)
                        SettingsInfoRow(icon: "key.fill", title: L10n.ServerSettings.authorizedKeys, value: "\(vm.authorizedKeysCount)")

                        if let msg = vm.sshMsg { SettingsInlineMsg(text: msg.0, isSuccess: msg.1) }

                        saveButton
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: { Task { await vm.saveSSHConfig() } }) {
            HStack(spacing: AXSpacing.xs) {
                if vm.isSavingSSH { ProgressView().scaleEffect(0.6) }
                else { Image(systemName: "checkmark.shield.fill").font(AXTypography.caption) }
                Text(L10n.ServerSettings.saveReloadSSH).font(AXTypography.caption).fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.sm)
            .background(LinearGradient(colors: [.axAccentBlue, .axAccentBlue.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(vm.isSavingSSH)
    }
}
