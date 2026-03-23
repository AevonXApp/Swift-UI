//
//  CerberusHoneypotView.swift
//  AevonX
//
//  Honeypot tab — trap hit log viewer using AXLogTable.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusHoneypotView: View {
    @ObservedObject var viewModel: CerberusViewModel

    var body: some View {
        AXLogTable(
            title: "Honeypot Hits",
            icon: "ant",
            columns: logColumns,
            rows: buildRows(),
            isLoading: viewModel.isLoading,
            accentColor: .axWarning,
            rowActions: [
                AXLogRowAction(
                    id: "block",
                    label: "Block IP",
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
        .task { await viewModel.loadHoneypot() }
    }

    // MARK: - Columns

    private var logColumns: [AXLogColumn] {
        [
            AXLogColumn(id: "ip", title: "IP Address", width: 140),
            AXLogColumn(id: "path", title: "Path", width: 180),
            AXLogColumn(id: "method", title: "Method", width: 60),
            AXLogColumn(id: "ua", title: "User Agent", width: nil),
            AXLogColumn(id: "time", title: "Time", width: 160),
        ]
    }

    // MARK: - Build Rows

    private func buildRows() -> [AXLogRow] {
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

    private func buildDetails(_ hit: HoneypotHit) -> [AXLogRowDetail] {
        var details: [AXLogRowDetail] = [
            AXLogRowDetail(label: "IP", value: hit.ip),
            AXLogRowDetail(label: "Path", value: hit.path),
            AXLogRowDetail(label: "Method", value: hit.method),
            AXLogRowDetail(label: "Time", value: hit.time),
            AXLogRowDetail(label: "User-Agent", value: hit.userAgent),
        ]
        for (key, value) in hit.headers.sorted(by: { $0.key < $1.key }) {
            details.append(AXLogRowDetail(label: "H: \(key)", value: value))
        }
        if !hit.body.isEmpty {
            details.append(AXLogRowDetail(label: "Body", value: hit.body))
        }
        return details
    }

    // MARK: - Helpers

    private func formatTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else {
            return iso
        }
        let display = DateFormatter()
        display.dateFormat = "MMM d, HH:mm:ss"
        return display.string(from: date)
    }
}
