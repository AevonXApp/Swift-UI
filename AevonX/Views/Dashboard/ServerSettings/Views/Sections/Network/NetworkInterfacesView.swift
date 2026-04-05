//
//  NetworkInterfacesView.swift
//  AevonX
//
//  Network interfaces table — name, IP, MAC, status.
//

import SwiftUI

extension NetworkManagementSection {

    // MARK: - Privacy Masking

    private func maskedIP(_ ip: String) -> String {
        ip
    }

    // MARK: - Interfaces Section

    var interfacesSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.interfaces, icon: "antenna.radiowaves.left.and.right")

            ForEach(vm.interfaces) { iface in
                HStack(spacing: AXSpacing.sm) {
                    Circle()
                        .fill(iface.statusColor)
                        .frame(width: 6, height: 6)
                    Text(iface.name)
                        .font(AXTypography.monoXs).fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                        .frame(width: 60, alignment: .leading)
                    Text(maskedIP(iface.ipAddress))
                        .font(AXTypography.monoXs)
                        .foregroundColor(.axAccentBlue)
                        .frame(minWidth: 120, alignment: .leading)
                    Text(iface.macAddress)
                        .font(AXTypography.monoXs)
                        .foregroundColor(.axTextTertiary)
                        .frame(minWidth: 130, alignment: .leading)
                    Spacer()
                    Text(iface.status)
                        .font(AXTypography.caption2).fontWeight(.medium)
                        .foregroundColor(iface.statusColor)
                }
                .padding(.vertical, AXSpacing.xxxs)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }
}
