//
//  MySQLWorkersSection.swift
//  AevonX
//
//  Thread & connection table — pure display, data from MySQLDetailView.
//

import SwiftUI
import AevonXCoreBridge

struct MySQLWorkersSection: View {
    let workers: [BridgeWorkerInfo]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                if !workers.isEmpty { summaryStats }

                AXSectionTitle(title: "Active Threads", icon: "cpu.fill")

                if workers.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "cpu")
                            .font(.system(size: 28))
                            .foregroundColor(.axTextMuted)
                        Text("No active threads detected")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    workerTable
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private var summaryStats: some View {
        HStack(spacing: AXSpacing.md) {
            let active = workers.filter { $0.state != "Sleep" }.count
            let sleeping = workers.filter { $0.state == "Sleep" }.count
            let totalCPU = workers.reduce(0) { $0 + $1.cpuPercent }
            let totalMem = workers.reduce(0) { $0 + $1.memoryMB }

            AXStatCard(icon: "bolt.fill", label: "Active", value: "\(active)", color: .axSuccess, style: .card)
            AXStatCard(icon: "moon.fill", label: "Sleeping", value: "\(sleeping)", color: .axTextMuted, style: .card)
            AXStatCard(icon: "gauge.high", label: "Total CPU", value: String(format: "%.1f%%", totalCPU), color: .purple, style: .card)
            AXStatCard(icon: "memorychip", label: "Total Memory", value: String(format: "%.1f MB", totalMem), color: .axAccentBlue, style: .card)
        }
    }

    private var workerTable: some View {
        VStack(spacing: 1) {
            HStack(spacing: 0) {
                tableHeader("PID", width: 80)
                tableHeader("State", width: 100)
                tableHeader("CPU %", width: 80)
                tableHeader("Memory", width: 100)
                Spacer()
            }
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface.opacity(0.6))

            ForEach(workers) { worker in
                HStack(spacing: 0) {
                    tableCell("\(worker.pid)", width: 80, mono: true)
                    tableCell(worker.state.capitalized, width: 100, color: worker.state == "Sleep" ? .axTextMuted : .axSuccess)
                    tableCell(String(format: "%.1f%%", worker.cpuPercent), width: 80,
                              color: worker.cpuPercent > 50 ? .axWarning : .axTextPrimary)
                    tableCell(String(format: "%.1f MB", worker.memoryMB), width: 100)
                    Spacer()
                }
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axSurface.opacity(0.3))
            }
        }
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(Color.axBorder.opacity(0.2), lineWidth: 1)
        )
    }

    private func tableHeader(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.axTextMuted)
            .textCase(.uppercase)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)
    }

    private func tableCell(_ value: String, width: CGFloat, mono: Bool = false, color: Color = .axTextPrimary) -> some View {
        Text(value)
            .font(mono ? .system(size: 11, design: .monospaced) : .system(size: 11))
            .foregroundColor(color)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, AXSpacing.sm)
    }
}
