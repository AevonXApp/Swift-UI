//
//  CerberusHoneypotView.swift
//  AevonX
//
//  Honeypot tab — trap hit analytics + detailed log viewer.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusHoneypotView: View {
    @ObservedObject var viewModel: CerberusViewModel

    var body: some View {
        VStack(spacing: 0) {
            honeypotHeader
            Divider().background(Color.axDivider)
            logTableSection
        }
        .task { await viewModel.loadHoneypot() }
    }
}

// MARK: - Header

private extension CerberusHoneypotView {

    var honeypotHeader: some View {
        HStack(spacing: AXSpacing.xl) {
            honeypotHeroIcon
            honeypotHeroText
            Spacer()
            honeypotStatsGroup
            refreshButton
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
        .background(
            Color.axSurface.overlay(
                LinearGradient(
                    colors: [Color.axWarning.opacity(0.03), Color.clear],
                    startPoint: .leading, endPoint: .trailing
                )
            )
        )
    }

    var honeypotHeroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axWarning.opacity(0.2), Color.axWarning.opacity(0.04)],
                        center: .center, startRadius: 0, endRadius: 24
                    )
                )
                .frame(width: 44, height: 44)
            Circle()
                .stroke(Color.axWarning.opacity(0.25), lineWidth: 1)
                .frame(width: 44, height: 44)
            Image(systemName: "ant.fill")
                .font(AXTypography.headline)
                .foregroundStyle(Color.axWarning)
        }
    }

    var honeypotHeroText: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(L10n.Cerberus.Honeypot.title)
                .font(AXTypography.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(L10n.Cerberus.Honeypot.subtitle)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    var honeypotStatsGroup: some View {
        HStack(spacing: AXSpacing.xl) {
            honeypotMiniStat(
                value: "\(viewModel.honeypotHits.count)",
                label: L10n.Cerberus.Honeypot.totalHits,
                color: .axWarning
            )
            Divider().frame(height: 28)
            honeypotMiniStat(
                value: "\(uniqueIPs)",
                label: L10n.Cerberus.Honeypot.uniqueIPs,
                color: .axError
            )
            Divider().frame(height: 28)
            honeypotMiniStat(
                value: "\(uniquePaths)",
                label: L10n.Cerberus.Honeypot.trapPaths,
                color: .axAccentPurple
            )
        }
    }

    func honeypotMiniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    var refreshButton: some View {
        Button {
            Task { await viewModel.loadHoneypot() }
        } label: {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "arrow.clockwise")
                Text(L10n.Button.refresh)
            }
            .font(AXTypography.caption)
            .fontWeight(.medium)
            .foregroundStyle(Color.axAccentBlue)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axAccentBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log Table

private extension CerberusHoneypotView {

    var logTableSection: some View {
        AXLogTable(
            title: L10n.Cerberus.Honeypot.honeypotHits,
            icon: "ant",
            columns: logColumns,
            rows: buildRows(),
            isLoading: viewModel.honeypotLoading,
            accentColor: .axWarning,
            rowActions: [
                AXLogRowAction(
                    id: "block",
                    label: L10n.Cerberus.Honeypot.blockIP,
                    icon: "hand.raised.fill",
                    color: .axError,
                    handler: { row in
                        if let ip = row.cells["ip"] {
                            Task { await viewModel.blockIP(ip) }
                        }
                    }
                )
            ],
            onRefresh: {
                await viewModel.loadHoneypot()
            }
        )
    }

    var logColumns: [AXLogColumn] {
        [
            AXLogColumn(id: "ip", title: L10n.Cerberus.Honeypot.colIP, width: 140),
            AXLogColumn(id: "path", title: L10n.Cerberus.Honeypot.colTrapPath, width: 180),
            AXLogColumn(id: "method", title: L10n.Cerberus.Honeypot.colMethod, width: 60),
            AXLogColumn(id: "ua", title: L10n.Cerberus.Honeypot.colUserAgent, width: nil),
            AXLogColumn(id: "time", title: L10n.Cerberus.Honeypot.colTimestamp, width: 160),
        ]
    }

    func buildRows() -> [AXLogRow] {
        viewModel.honeypotHits.enumerated().map { idx, hit in
            AXLogRow(
                id: idx,
                level: "warn",
                cells: [
                    "ip": hit.ip,
                    "path": hit.path,
                    "method": hit.method,
                    "ua": hit.userAgent,
                    "time": formatTime(hit.time),
                ],
                raw: "\(hit.method) \(hit.path) from \(hit.ip) — \(hit.userAgent)",
                details: buildDetails(hit)
            )
        }
    }

    func buildDetails(_ hit: HoneypotHit) -> [AXLogRowDetail] {
        var details: [AXLogRowDetail] = [
            AXLogRowDetail(label: L10n.Cerberus.Honeypot.detailIP, value: hit.ip),
            AXLogRowDetail(label: L10n.Cerberus.Honeypot.detailPath, value: hit.path),
            AXLogRowDetail(label: L10n.Cerberus.Honeypot.detailMethod, value: hit.method),
            AXLogRowDetail(label: L10n.Cerberus.Honeypot.detailTime, value: hit.time),
            AXLogRowDetail(label: L10n.Cerberus.Honeypot.detailUA, value: hit.userAgent),
        ]
        for (key, value) in hit.headers.sorted(by: { $0.key < $1.key }) {
            details.append(AXLogRowDetail(label: "\(L10n.Cerberus.Honeypot.headerPrefix): \(key)", value: value))
        }
        if !hit.body.isEmpty {
            details.append(AXLogRowDetail(label: L10n.Cerberus.Honeypot.detailBody, value: hit.body))
        }
        return details
    }
}

// MARK: - Helpers

private extension CerberusHoneypotView {

    var uniqueIPs: Int {
        Set(viewModel.honeypotHits.map(\.ip)).count
    }

    var uniquePaths: Int {
        Set(viewModel.honeypotHits.map(\.path)).count
    }

    private static let isoFmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoFmtBasic = ISO8601DateFormatter()
    private static let displayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm:ss"
        return f
    }()

    func formatTime(_ iso: String) -> String {
        guard let date = Self.isoFmt.date(from: iso) ?? Self.isoFmtBasic.date(from: iso) else { return iso }
        return Self.displayFmt.string(from: date)
    }
}
