//
//  NetworkConnectionsView.swift
//  AevonX
//
//  Active connections list — established TCP/UDP connections.
//

import SwiftUI

extension NetworkManagementSection {

    // MARK: - Connection Privacy Helpers

    private func maskedConnIP(_ ip: String) -> String {
        ip
    }

    private func maskedConnPort(_ port: String) -> String {
        guard isMasking, let portInt = Int(port) else { return port }
        return PrivacyMask.port(portInt)
    }

    // MARK: - Active Connections

    var activeConnectionsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.activeConnections, icon: "arrow.left.arrow.right")

            if vm.activeConnections.isEmpty {
                Text(L10n.ServerSettings.noActiveConnections)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AXSpacing.sm)
            } else {
                connectionHeader
                ForEach(vm.activeConnections.prefix(50)) { conn in
                    connectionRow(conn)
                }
                if vm.activeConnections.count > 50 {
                    Text(L10n.ServerSettings.moreConnections(vm.activeConnections.count - 50))
                        .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private var connectionHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Text(L10n.ServerSettings.proto).frame(width: 35, alignment: .leading)
            Text(L10n.ServerSettings.local).frame(width: 50, alignment: .trailing)
            Text(L10n.ServerSettings.remoteAddress).frame(minWidth: 140, alignment: .leading)
            Text(L10n.Field.port).frame(width: 50, alignment: .trailing)
            Text(L10n.ServerSettings.process).frame(minWidth: 80, alignment: .leading)
            Spacer()
        }
        .font(AXTypography.caption2).fontWeight(.semibold)
        .foregroundColor(.axTextMuted)
    }

    private func connectionRow(_ conn: ActiveConnection) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(conn.proto.uppercased())
                .font(AXTypography.monoXs).foregroundColor(.axAccentBlue)
                .frame(width: 35, alignment: .leading)
            Text(maskedConnPort(conn.localPort))
                .font(AXTypography.monoXs).foregroundColor(.axTextPrimary)
                .frame(width: 50, alignment: .trailing)
            Text(maskedConnIP(conn.remoteAddr))
                .font(AXTypography.monoXs).foregroundColor(.axTextSecondary)
                .lineLimit(1)
                .frame(minWidth: 140, alignment: .leading)
            Text(maskedConnPort(conn.remotePort))
                .font(AXTypography.monoXs).foregroundColor(.axTextTertiary)
                .frame(width: 50, alignment: .trailing)
            Text(conn.process)
                .font(AXTypography.caption).foregroundColor(.axTextSecondary)
                .lineLimit(1)
                .frame(minWidth: 80, alignment: .leading)
            Spacer()
        }
        .padding(.vertical, AXSpacing.xxxs)
    }
}
