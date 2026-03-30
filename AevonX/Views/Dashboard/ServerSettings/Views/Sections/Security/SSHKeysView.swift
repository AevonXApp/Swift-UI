//
//  SSHKeysView.swift
//  AevonX
//
//  Host key fingerprints + authorized keys management.
//

import SwiftUI

extension SSHSecurityDetailSection {

    private var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

    var hostKeysSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.hostKeyFingerprints, icon: "key.viewfinder")

            if vm.hostKeyFingerprints.isEmpty {
                emptyText(L10n.ServerSettings.noHostKeys)
            } else {
                ForEach(vm.hostKeyFingerprints) { key in
                    HStack(spacing: AXSpacing.sm) {
                        Text(key.keyType)
                            .font(AXTypography.monoXs).fontWeight(.semibold)
                            .foregroundColor(.axAccentBlue)
                            .frame(width: 70, alignment: .leading)
                        Text(key.hash)
                            .font(AXTypography.monoXs)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(key.bits) bits")
                            .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                    }
                    .padding(.vertical, AXSpacing.xxxs)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    var authorizedKeysSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                sectionLabel(L10n.ServerSettings.authorizedKeysCount(vm.authorizedKeys.count), icon: "key.horizontal.fill")
                Spacer()
            }

            ForEach(vm.authorizedKeys) { key in
                HStack(spacing: AXSpacing.sm) {
                    Text(key.keyType)
                        .font(AXTypography.monoXs).fontWeight(.medium)
                        .foregroundColor(.axAccentBlue)
                        .frame(width: 60, alignment: .leading)
                    Text(key.comment.isEmpty ? key.fingerprint : (isMasking && settings.maskUsernames ? PrivacyMask.username(key.comment) : key.comment))
                        .font(AXTypography.caption).foregroundColor(.axTextSecondary)
                        .lineLimit(1)
                    Spacer()
                    Button(action: { Task { await vm.deleteSSHKey(key.id) } }) {
                        Image(systemName: "trash")
                            .font(AXTypography.caption2).foregroundColor(.axError)
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, AXSpacing.xxxs)
            }

            // Add key field
            HStack(spacing: AXSpacing.xs) {
                TextField(L10n.ServerSettings.pastePublicKey, text: $vm.newPubKey)
                    .font(AXTypography.caption).textFieldStyle(.plain)
                    .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxs)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.sm)

                Button(action: { Task { await vm.addSSHKey() } }) {
                    Image(systemName: "plus.circle.fill")
                        .font(AXTypography.body).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
                .disabled(vm.newPubKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.xxs) {
            Image(systemName: icon).font(AXTypography.caption2).foregroundColor(.axAccentBlue)
            Text(title).font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextPrimary)
        }
    }

    func emptyText(_ text: String) -> some View {
        Text(text)
            .font(AXTypography.caption).foregroundColor(.axTextMuted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, AXSpacing.xs)
    }
}
