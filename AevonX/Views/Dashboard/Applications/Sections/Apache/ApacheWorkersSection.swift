//
//  ApacheWorkersSection.swift
//  AevonX
//
//  Apache worker process table — pure display, data from detail view.
//

import SwiftUI
import AevonXCoreBridge

struct ApacheWorkersSection: View {
    let workers: [BridgeWorkerInfo]

    private let apacheRed = Color(red: 0.82, green: 0.13, blue: 0.16)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                if !workers.isEmpty { summaryStats }

                AXSectionTitle(title: "Worker Processes", icon: "cpu.fill")

                if workers.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Image(systemName: "cpu").font(.system(size: 28)).foregroundColor(.axTextMuted)
                        Text("No worker processes detected").font(AXTypography.caption).foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 40)
                } else {
                    workerTable
                }
            }
            .padding(AXSpacing.xl)
        }
    }

    private var summaryStats: some View {
        HStack(spacing: AXSpacing.md) {
            let master = workers.filter { $0.state == "master" }.count
            let workerProcesses = workers.filter { $0.state == "worker" }
            let totalCPU = workerProcesses.reduce(0) { $0 + $1.cpuPercent }
            let totalMem = workerProcesses.reduce(0) { $0 + $1.memoryMB }

            AXStatCard(icon: "person.fill", label: "Master", value: "\(master)", color: .orange, style: .card)
            AXStatCard(icon: "cpu", label: "Workers", value: "\(workerProcesses.count)", color: apacheRed, style: .card)
            AXStatCard(icon: "gauge.high", label: "Total CPU", value: String(format: "%.1f%%", totalCPU), color: .purple, style: .card)
            AXStatCard(icon: "memorychip", label: "Total Memory", value: String(format: "%.1f MB", totalMem), color: .axAccentBlue, style: .card)
        }
    }

    private var workerTable: some View {
        VStack(spacing: 1) {
            HStack(spacing: 0) {
                tableHeader("PID", width: 80)
                tableHeader("Type", width: 80)
                tableHeader("CPU %", width: 80)
                tableHeader("Memory", width: 100)
                Spacer()
            }
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface.opacity(0.6))

            ForEach(workers) { worker in
                HStack(spacing: 0) {
                    tableCell("\(worker.pid)", width: 80, mono: true)
                    tableCell(worker.state.capitalized, width: 80, color: worker.state == "master" ? .orange : apacheRed)
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
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
    }

    private func tableHeader(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.axTextMuted).textCase(.uppercase)
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
