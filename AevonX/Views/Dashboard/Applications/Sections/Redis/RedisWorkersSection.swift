//
//  RedisWorkersSection.swift
//  AevonX
//
//  Connected clients — pure display, data from RedisDetailView.
//

import SwiftUI
import AevonXCoreBridge

struct RedisWorkersSection: View {
    let workers: [BridgeWorkerInfo]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                if !workers.isEmpty { summaryStats }
                AXSectionTitle(title: "Connected Clients", icon: "person.2.fill")
                if workers.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "person.2").font(.system(size: 28)).foregroundColor(.axTextMuted)
                        Text(L10n.Apps.noConnectedClientsDetected).font(AXTypography.caption).foregroundColor(.axTextMuted)
                    }.frame(maxWidth: .infinity).padding(.top, 40)
                } else { workerTable }
            }.padding(AXSpacing.xl)
        }
    }

    private var summaryStats: some View {
        HStack(spacing: AXSpacing.md) {
            let active = workers.filter { $0.state != "idle" }.count
            let idle = workers.filter { $0.state == "idle" }.count
            AXStatCard(icon: "bolt.fill", label: "Active", value: "\(active)", color: .axSuccess, style: .card)
            AXStatCard(icon: "moon.fill", label: "Idle", value: "\(idle)", color: .axTextMuted, style: .card)
            AXStatCard(icon: "person.2.fill", label: "Total", value: "\(workers.count)", color: .axAccentBlue, style: .card)
        }
    }

    private var workerTable: some View {
        VStack(spacing: 1) {
            HStack(spacing: 0) { tableHeader("ID", width: 80); tableHeader("State", width: 100); tableHeader("Age", width: 80)
                tableHeader("DB", width: 60); Spacer() }.padding(.vertical, AXSpacing.xs).background(Color.axSurface.opacity(0.6))
            ForEach(workers) { worker in
                HStack(spacing: 0) {
                    tableCell("\(worker.pid)", width: 80, mono: true)
                    tableCell(worker.state.capitalized, width: 100, color: worker.state == "idle" ? .axTextMuted : .axSuccess)
                    tableCell(String(format: "%.0fs", worker.cpuPercent), width: 80)
                    tableCell(String(format: "%.0f", worker.memoryMB), width: 60); Spacer()
                }.padding(.vertical, AXSpacing.xs).background(Color.axSurface.opacity(0.3))
            }
        }.cornerRadius(AXCornerRadius.md).overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
    }

    private func tableHeader(_ title: String, width: CGFloat) -> some View {
        Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.axTextMuted).textCase(.uppercase)
            .frame(width: width, alignment: .leading).padding(.horizontal, AXSpacing.sm)
    }
    private func tableCell(_ value: String, width: CGFloat, mono: Bool = false, color: Color = .axTextPrimary) -> some View {
        Text(value).font(mono ? .system(size: 11, design: .monospaced) : .system(size: 11)).foregroundColor(color)
            .frame(width: width, alignment: .leading).padding(.horizontal, AXSpacing.sm)
    }
}
