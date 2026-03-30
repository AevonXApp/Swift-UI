//
//  SystemSwapKernelView.swift
//  AevonX
//
//  Swap management and kernel parameters.
//

import SwiftUI

extension SystemControlSection {

    // MARK: - Swap

    var swapView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.swap, icon: "memorychip")

            if vm.swapEntries.isEmpty {
                HStack {
                    Text(L10n.ServerSettings.noSwapConfigured)
                        .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    Spacer()
                }
            } else {
                ForEach(vm.swapEntries) { entry in
                    HStack(spacing: AXSpacing.sm) {
                        Text(entry.name)
                            .font(AXTypography.monoXs).foregroundColor(.axTextPrimary)
                        Text(entry.type)
                            .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                        Text(L10n.ServerSettings.sizeValue(entry.size))
                            .font(AXTypography.monoXs).foregroundColor(.axAccentBlue)
                        Text(L10n.ServerSettings.usedValue(entry.used))
                            .font(AXTypography.monoXs).foregroundColor(.axTextSecondary)
                        Spacer()
                    }
                }
            }

            HStack(spacing: AXSpacing.xs) {
                TextField(L10n.ServerSettings.sizeMB, text: $vm.newSwapSizeMB)
                    .font(AXTypography.monoXs).textFieldStyle(.plain)
                    .frame(width: 70)
                    .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxs)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.sm)
                Text(L10n.ServerSettings.mb)
                    .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                Button(action: { Task { await vm.resizeSwap() } }) {
                    Text(L10n.ServerSettings.resizeSwap)
                        .font(AXTypography.caption2).fontWeight(.medium)
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(vm.newSwapSizeMB.isEmpty)
                Spacer()
                Button(action: {
                    vm.newSwapSizeMB = "0"
                    Task { await vm.resizeSwap() }
                }) {
                    Text(L10n.ServerSettings.disableSwap)
                        .font(AXTypography.caption2).foregroundColor(.axError)
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Kernel Parameters

    var kernelParamsView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.kernelParameters, icon: "terminal")

            if vm.kernelParams.isEmpty {
                Text(L10n.ServerSettings.noKernelParams)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
            } else {
                ForEach(vm.kernelParams) { param in
                    kernelParamRow(param)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func kernelParamRow(_ param: KernelParam) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(param.key)
                .font(AXTypography.monoXs).foregroundColor(.axTextPrimary)
                .frame(minWidth: 200, alignment: .leading)
            Text(param.value)
                .font(AXTypography.monoXs).fontWeight(.medium)
                .foregroundColor(.axAccentBlue)
            Spacer()
        }
        .padding(.vertical, AXSpacing.xxxs)
    }
}
