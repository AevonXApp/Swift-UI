//
//  LiteSpeedWorkersSection.swift
//  AevonX
//
//  Worker processes and resource usage for LiteSpeed.
//

import SwiftUI
import AevonXCoreBridge

struct LiteSpeedWorkersSection: View {
    let workers: [BridgeWorkerInfo]

    private let lsGreen = Color(red: 0.18, green: 0.55, blue: 0.34)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Worker Processes (\(workers.count))", icon: "cpu.fill")

                if workers.isEmpty {
                    VStack(spacing: AXSpacing.md) {
                        Spacer()
                        Image(systemName: "cpu").font(AXTypography.largeTitle).foregroundColor(.axTextMuted.opacity(0.3))
                        Text(L10n.Apps.noWorkerProcessesDetected).font(AXTypography.callout).foregroundColor(.axTextMuted)
                        Spacer()
                    }.frame(maxWidth: .infinity).padding(.vertical, AXSpacing.xl)
                } else {
                    // Summary stats
                    HStack(spacing: AXSpacing.md) {
                        workerStat(label: "Total Workers", value: "\(workers.count)", icon: "person.3.fill", color: .axAccentBlue)
                        workerStat(label: "Total CPU", value: String(format: "%.1f%%", workers.reduce(0) { $0 + $1.cpuPercent }), icon: "cpu.fill", color: .cyan)
                        workerStat(label: "Total Memory", value: String(format: "%.1f MB", workers.reduce(0) { $0 + $1.memoryMB }), icon: "memorychip.fill", color: .purple)
                    }

                    // Worker table
                    VStack(spacing: 1) {
                        // Header
                        HStack(spacing: 0) {
                            Text("PID").frame(width: 80, alignment: .leading)
                            Text(L10n.Apps.state).frame(width: 100, alignment: .leading)
                            Text(L10n.Apps.cpu).frame(width: 80, alignment: .trailing)
                            Text(L10n.Apps.memory).frame(width: 100, alignment: .trailing)
                            Spacer()
                        }
                        .font(AXTypography.caption).fontWeight(.bold)
                        .foregroundColor(.axTextMuted)
                        .textCase(.uppercase)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface.opacity(0.5))

                        ForEach(workers, id: \.pid) { worker in
                            HStack(spacing: 0) {
                                Text("\(worker.pid)")
                                    .font(AXTypography.monoMd)
                                    .frame(width: 80, alignment: .leading)
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(worker.state == "master" ? lsGreen : .axAccentBlue)
                                        .frame(width: 6, height: 6)
                                    Text(worker.state.capitalized)
                                        .font(AXTypography.footnote)
                                }
                                .frame(width: 100, alignment: .leading)
                                Text(String(format: "%.1f%%", worker.cpuPercent))
                                    .font(AXTypography.monoMd)
                                    .foregroundColor(worker.cpuPercent > 50 ? .axWarning : .axTextPrimary)
                                    .frame(width: 80, alignment: .trailing)
                                Text(String(format: "%.1f MB", worker.memoryMB))
                                    .font(AXTypography.monoMd)
                                    .frame(width: 100, alignment: .trailing)
                                Spacer()
                            }
                            .foregroundColor(.axTextPrimary)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axSurface.opacity(0.15))
                        }
                    }
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder.opacity(0.1), lineWidth: 1)
                    )
                }

                Spacer()
            }
            .padding(AXSpacing.xl)
        }
    }

    private func workerStat(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon).font(AXTypography.footnote).foregroundColor(color)
                Spacer()
                Text(value).font(AXTypography.title2).fontWeight(.bold).foregroundColor(.axTextPrimary)
            }
            Text(label).font(AXTypography.caption).foregroundColor(.axTextMuted).textCase(.uppercase)
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.06))
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(color.opacity(0.15), lineWidth: 1))
    }
}
