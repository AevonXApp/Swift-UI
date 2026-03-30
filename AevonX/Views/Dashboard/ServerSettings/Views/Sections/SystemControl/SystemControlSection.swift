//
//  SystemControlSection.swift
//  AevonX
//
//  System control — reboot, shutdown, hardware, swap, kernel, security modules.
//

import SwiftUI

struct SystemControlSection: View {
    @ObservedObject var vm: SystemControlVM
    @State private var isExpanded = true

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    if vm.isLoading {
                        AXSkeletonBlock(lines: 8)
                    } else {
                        hardwareView
                        rebootControlView
                        swapView
                        kernelParamsView
                        msgOverlay
                    }
                }
            }
        }
        .task { await vm.loadAll() }
    }

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "gearshape.2.fill", title: L10n.ServerSettings.systemControl,
            subtitle: vm.hardware.arch.isEmpty ? L10n.Status.loading : "\(vm.hardware.arch) · \(vm.virtType)",
            gradient: [.axAccentPurple, .axAccentBlue],
            isExpanded: $isExpanded,
            trailing: AnyView(
                Button(action: { Task { await vm.loadAll() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.caption).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
            )
        )
    }

    var msgOverlay: some View {
        Group {
            if let (msg, ok) = vm.saveMsg {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(msg)
                }
                .font(AXTypography.caption).fontWeight(.medium)
                .foregroundColor(ok ? .axSuccess : .axError)
                .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
                .background((ok ? Color.axSuccess : Color.axError).opacity(0.12))
                .cornerRadius(AXCornerRadius.sm)
            }
        }
    }
}
