//
//  UpdatePackageRow.swift
//  AevonX
//
//  Single package row in the updates list.
//

import SwiftUI

struct UpdatePackageRow: View {
    @ObservedObject var vm: ServerSettingsViewModel
    let pkg: PackageUpdate

    private var isUpdating: Bool { vm.updatingPackages.contains(pkg.name) }

    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: pkg.typeIcon)
                .font(AXTypography.caption2)
                .foregroundColor(pkg.typeColor)
                .frame(width: 14)

            Text(pkg.name)
                .font(AXTypography.monoXs).fontWeight(.medium)
                .foregroundColor(.axTextPrimary)
                .lineLimit(1)

            if !pkg.currentVersion.isEmpty {
                Text(pkg.currentVersion)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                Text("→")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
            }

            Text(pkg.availableVersion)
                .font(AXTypography.caption2)
                .foregroundColor(.axAccentBlue)

            if pkg.isSecurity {
                Text(L10n.ServerSettings.sec)
                    .font(AXTypography.caption2).fontWeight(.bold)
                    .foregroundColor(.axError)
                    .padding(.horizontal, AXSpacing.xxs)
                    .background(Color.axError.opacity(0.1))
                    .cornerRadius(AXCornerRadius.xs)
            }

            Spacer()

            if isUpdating {
                ProgressView().scaleEffect(0.5)
            } else {
                Button(action: { Task { await vm.updatePackage(pkg.name) } }) {
                    Text(L10n.ServerSettings.update)
                        .font(AXTypography.caption2).fontWeight(.medium)
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.sm).padding(.vertical, 2)
                        .background(Color.axAccentBlue.opacity(0.08))
                        .cornerRadius(AXCornerRadius.sm)
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
        .background(Color.axBackgroundTertiary.opacity(0.5))
        .cornerRadius(AXCornerRadius.sm)
    }
}
