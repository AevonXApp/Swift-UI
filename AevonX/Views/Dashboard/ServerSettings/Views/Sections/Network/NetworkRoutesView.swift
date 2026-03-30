//
//  NetworkRoutesView.swift
//  AevonX
//
//  Routing table display.
//

import SwiftUI

extension NetworkManagementSection {

    // MARK: - Route Privacy Helpers

    private func maskedRouteIP(_ ip: String) -> String {
        isMasking && settings.maskIPAddresses ? PrivacyMask.ip(ip) : ip
    }

    // MARK: - Routes

    var routesSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            sectionLabel(L10n.ServerSettings.routingTable, icon: "point.topleft.down.to.point.bottomright.curvepath")

            if vm.routes.isEmpty {
                Text(L10n.ServerSettings.noRoutesFound)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AXSpacing.sm)
            } else {
                routeHeader
                ForEach(vm.routes) { route in
                    routeRow(route)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private var routeHeader: some View {
        HStack(spacing: AXSpacing.sm) {
            Text(L10n.ServerSettings.destination).frame(minWidth: 120, alignment: .leading)
            Text(L10n.ServerSettings.gateway).frame(minWidth: 100, alignment: .leading)
            Text(L10n.ServerSettings.interfaceCol).frame(width: 60, alignment: .leading)
            Text(L10n.ServerSettings.flags).frame(minWidth: 80, alignment: .leading)
            Spacer()
        }
        .font(AXTypography.caption2).fontWeight(.semibold)
        .foregroundColor(.axTextMuted)
    }

    private func routeRow(_ route: RouteEntry) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Text(maskedRouteIP(route.destination))
                .font(AXTypography.monoXs).foregroundColor(.axTextPrimary)
                .frame(minWidth: 120, alignment: .leading)
            Text(maskedRouteIP(route.gateway))
                .font(AXTypography.monoXs).foregroundColor(.axAccentBlue)
                .frame(minWidth: 100, alignment: .leading)
            Text(route.iface)
                .font(AXTypography.monoXs).foregroundColor(.axTextSecondary)
                .frame(width: 60, alignment: .leading)
            Text(route.extra)
                .font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                .lineLimit(1)
                .frame(minWidth: 80, alignment: .leading)
            Spacer()
        }
        .padding(.vertical, AXSpacing.xxxs)
    }
}
