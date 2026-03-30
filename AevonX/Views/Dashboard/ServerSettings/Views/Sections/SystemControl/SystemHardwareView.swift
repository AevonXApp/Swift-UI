//
//  SystemHardwareView.swift
//  AevonX
//
//  Hardware info, virtualization, and security module display.
//

import SwiftUI

extension SystemControlSection {

    var hardwareView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.hardwareSystem, icon: "cpu")

            HStack(spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    infoRow(L10n.ServerSettings.cpu, vm.hardware.cpuModel)
                    infoRow(L10n.ServerSettings.coresLabel, vm.hardware.cpuCores)
                    infoRow(L10n.ServerSettings.architecture, vm.hardware.arch)
                }
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    infoRow(L10n.ServerSettings.totalRAM, vm.hardware.totalRAM)
                    infoRow(L10n.ServerSettings.totalDisk, vm.hardware.totalDisk)
                    infoRow(L10n.ServerSettings.virtualization, vm.virtType)
                }
            }

            Divider().background(Color.axBorder.opacity(0.3))

            // Security module
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "shield.fill")
                    .font(AXTypography.caption2)
                    .foregroundColor(vm.secModuleType == "none" ? .axTextMuted : .axAccentBlue)
                Text(L10n.ServerSettings.securityModule)
                    .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                Text(vm.secModuleType == "none" ? L10n.ServerSettings.none : "\(vm.secModuleType.uppercased()) — \(vm.secModuleStatus)")
                    .font(AXTypography.monoXs).fontWeight(.medium)
                    .foregroundColor(vm.secModuleType == "none" ? .axTextMuted : .axAccentBlue)
                Spacer()
                if vm.rebootRequired {
                    HStack(spacing: AXSpacing.xxxs) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.axWarning)
                        Text(L10n.ServerSettings.rebootRequired)
                            .fontWeight(.medium).foregroundColor(.axWarning)
                    }
                    .font(AXTypography.caption2)
                }
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

    func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(AXTypography.caption2).foregroundColor(.axTextMuted)
                .frame(width: 80, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(AXTypography.monoXs).foregroundColor(.axTextSecondary)
                .lineLimit(1)
        }
    }
}
