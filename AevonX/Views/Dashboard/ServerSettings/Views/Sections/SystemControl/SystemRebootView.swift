//
//  SystemRebootView.swift
//  AevonX
//
//  Reboot/shutdown controls with double confirmation.
//

import SwiftUI

extension SystemControlSection {

    var rebootControlView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.powerControl, icon: "power")

            HStack(spacing: AXSpacing.sm) {
                // Reboot button
                Button(action: { vm.showRebootConfirm = true }) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "arrow.clockwise")
                        Text(L10n.ServerSettings.reboot)
                    }
                    .font(AXTypography.caption).fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.xs)
                    .background(Color.axWarning)
                    .cornerRadius(AXCornerRadius.sm)
                }.buttonStyle(PlainButtonStyle())

                // Shutdown button
                Button(action: { vm.showShutdownConfirm = true }) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "power")
                        Text(L10n.ServerSettings.shutdown)
                    }
                    .font(AXTypography.caption).fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.xs)
                    .background(Color.axError)
                    .cornerRadius(AXCornerRadius.sm)
                }.buttonStyle(PlainButtonStyle())

                Spacer()

                // Schedule reboot
                HStack(spacing: AXSpacing.xxs) {
                    TextField("+5", text: $vm.scheduleTime)
                        .font(AXTypography.monoXs).textFieldStyle(.plain)
                        .frame(width: 40)
                        .padding(.horizontal, AXSpacing.xxs).padding(.vertical, AXSpacing.xxxs)
                        .background(Color.axBackgroundTertiary)
                        .cornerRadius(AXCornerRadius.sm)
                    Text(L10n.ServerSettings.min)
                        .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                    Button(action: { Task { await vm.scheduleReboot() } }) {
                        Text(L10n.ServerSettings.schedule)
                            .font(AXTypography.caption2).fontWeight(.medium)
                            .foregroundColor(.axAccentBlue)
                    }.buttonStyle(PlainButtonStyle())
                }
            }

            // Scheduled reboot info
            if !vm.scheduledReboot.isEmpty {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(AXTypography.caption2).foregroundColor(.axWarning)
                    Text(L10n.ServerSettings.scheduled(vm.scheduledReboot))
                        .font(AXTypography.caption2).foregroundColor(.axWarning)
                    Button(action: { Task { await vm.cancelReboot() } }) {
                        Text(L10n.Button.cancel)
                            .font(AXTypography.caption2).fontWeight(.medium)
                            .foregroundColor(.axError)
                    }.buttonStyle(PlainButtonStyle())
                }
            }

            // Confirmation overlays
            if vm.showRebootConfirm {
                confirmBanner(
                    text: L10n.ServerSettings.confirmReboot,
                    color: .axWarning,
                    onConfirm: { vm.showRebootConfirm = false; Task { await vm.reboot() } },
                    onCancel: { vm.showRebootConfirm = false }
                )
            }
            if vm.showShutdownConfirm {
                confirmBanner(
                    text: L10n.ServerSettings.confirmShutdown,
                    color: .axError,
                    onConfirm: { vm.showShutdownConfirm = false; Task { await vm.shutdown() } },
                    onCancel: { vm.showShutdownConfirm = false }
                )
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func confirmBanner(text: String, color: Color, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(color)
            Text(text).font(AXTypography.caption).foregroundColor(.axTextPrimary)
            Spacer()
            Button(L10n.Button.cancel, action: onCancel)
                .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                .buttonStyle(PlainButtonStyle())
            Button(L10n.Button.confirm, action: onConfirm)
                .font(AXTypography.caption2).fontWeight(.bold).foregroundColor(color)
                .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.xs)
        .background(color.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }
}
