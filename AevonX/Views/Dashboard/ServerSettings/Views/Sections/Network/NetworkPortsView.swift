//
//  NetworkPortsView.swift
//  AevonX
//
//  Listening ports list with search and risky port warnings.
//

import SwiftUI

extension NetworkManagementSection {

    // MARK: - Port Privacy Helpers

    private func maskedPort(_ port: Int) -> String {
        isMasking ? PrivacyMask.port(port) : String(port)
    }

    private func maskedPortAddress(_ addr: String) -> String {
        addr
    }

    // MARK: - Listening Ports

    var listeningPortsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack {
                sectionLabel(L10n.ServerSettings.listeningPorts, icon: "lock.open.fill")
                Spacer()
                portSearchField
            }

            if !vm.riskyPorts.isEmpty {
                riskyPortsBanner
            }

            ForEach(vm.filteredPorts) { port in
                portRow(port)
            }

            if vm.filteredPorts.isEmpty {
                Text(L10n.ServerSettings.noPortsMatch)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AXSpacing.sm)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private var portSearchField: some View {
        HStack(spacing: AXSpacing.xxs) {
            Image(systemName: "magnifyingglass").font(AXTypography.caption2).foregroundColor(.axTextMuted)
            TextField(L10n.ServerSettings.filterPlaceholder, text: $vm.portSearchText)
                .font(AXTypography.caption).textFieldStyle(.plain)
        }
        .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxxs)
        .background(Color.axBackgroundTertiary)
        .cornerRadius(AXCornerRadius.sm)
        .frame(width: 140)
    }

    private var riskyPortsBanner: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            ForEach(vm.riskyPorts) { port in
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AXTypography.caption2).foregroundColor(.axWarning)
                    Text(isMasking ? maskedPort(port.port) : L10n.ServerSettings.portNum(port.port))
                        .font(AXTypography.monoXs).fontWeight(.bold).foregroundColor(.axWarning)
                    Text(port.riskMessage ?? "")
                        .font(AXTypography.caption2).foregroundColor(.axTextSecondary)
                }
            }
        }
        .padding(AXSpacing.xs)
        .background(Color.axWarning.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }

    private func portRow(_ port: NetworkListeningPort) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(maskedPort(port.port))
                .font(AXTypography.monoXs).fontWeight(.semibold)
                .foregroundColor(port.isRisky ? .axWarning : .axTextPrimary)
                .frame(width: 50, alignment: .trailing)
            Text(port.proto.uppercased())
                .font(AXTypography.caption2).fontWeight(.medium)
                .foregroundColor(.axAccentBlue)
                .frame(width: 35)
            Text(maskedPortAddress(port.address))
                .font(AXTypography.monoXs).foregroundColor(.axTextTertiary)
                .frame(minWidth: 100, alignment: .leading)
            Text(port.process)
                .font(AXTypography.caption).foregroundColor(.axTextSecondary)
                .lineLimit(1)
            Spacer()
            if port.pid != "—" {
                Text(L10n.ServerSettings.pidLabel(port.pid))
                    .font(AXTypography.caption2).foregroundColor(.axTextMuted)
            }
        }
        .padding(.vertical, AXSpacing.xxxs)
    }
}
