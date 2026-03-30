//
//  ResourceMonitorSection.swift
//  AevonX
//
//  Main resource monitor section — composes gauge cards + process list + disk.
//

import SwiftUI

struct ResourceMonitorSection: View {
    @ObservedObject var vm: ResourceMonitorVM
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
                        topGaugeRow
                        bottomGaugeRow
                        ResourceProcessList(vm: vm)
                        ResourceDiskList(vm: vm)
                    }
                }
            }
        }
        .task { await vm.loadResourceSnapshot() }
        .onDisappear { vm.stopAutoRefresh() }
    }

    // MARK: - Header

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "bolt.fill", title: L10n.ServerSettings.resourceMonitor,
            subtitle: L10n.ServerSettings.realTimeMetrics, gradient: [.axAccentBlue, .axAccentPurple],
            isExpanded: $isExpanded,
            trailing: AnyView(HStack { refreshPicker; refreshButton })
        )
    }

    private var refreshPicker: some View {
        Picker("", selection: $vm.autoRefreshInterval) {
            Text(L10n.ServerSettings.off).tag(0)
            Text("5s").tag(5)
            Text("10s").tag(10)
            Text("30s").tag(30)
            Text("60s").tag(60)
        }
        .pickerStyle(.menu)
        .frame(width: 70)
        .onChange(of: vm.autoRefreshInterval) { _, newVal in
            if newVal > 0 { vm.startAutoRefresh() } else { vm.stopAutoRefresh() }
        }
    }

    private var refreshButton: some View {
        Button(action: { Task { await vm.loadResourceSnapshot() } }) {
            Image(systemName: vm.isAutoRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise")
                .font(AXTypography.caption)
                .foregroundColor(vm.isAutoRefreshing ? .axSuccess : .axAccentBlue)
        }.buttonStyle(PlainButtonStyle())
    }

    // MARK: - Gauge Rows

    private var topGaugeRow: some View {
        HStack(spacing: AXSpacing.sm) {
            ResourceGaugeCard(title: L10n.ServerSettings.cpu, value: String(format: "%.1f%%", vm.cpuPercent),
                              subtitle: L10n.ServerSettings.cores(vm.cpuCores), percent: vm.cpuPercent / 100,
                              color: ResourceColor.cpu(vm.cpuPercent)) {
                MiniChart(values: vm.cpuHistory, maxValue: 100, color: ResourceColor.cpu(vm.cpuPercent))
            }
            ResourceGaugeCard(title: L10n.ServerSettings.ram, value: vm.ramUsed.humanReadable,
                              subtitle: "\(vm.ramTotal.humanReadable) \(L10n.ServerSettings.total)",
                              percent: vm.ramPercent / 100,
                              color: ResourceColor.ram(vm.ramPercent)) {
                MiniChart(values: vm.ramHistory, maxValue: 100, color: ResourceColor.ram(vm.ramPercent))
            }
            ResourceGaugeCard(title: L10n.ServerSettings.swap, value: vm.swapUsed.humanReadable,
                              subtitle: vm.swapTotal > 0 ? "\(vm.swapTotal.humanReadable) \(L10n.ServerSettings.total)" : L10n.Status.disabled,
                              percent: vm.swapPercent / 100,
                              color: ResourceColor.swap(vm.swapPercent))
            ResourceGaugeCard(title: L10n.ServerSettings.load, value: String(format: "%.2f", vm.loadAvg1),
                              subtitle: String(format: "%.2f / %.2f", vm.loadAvg5, vm.loadAvg15),
                              percent: min(vm.loadNormalized, 2.0) / 2.0,
                              color: ResourceColor.load(vm.loadNormalized))
        }
    }

    private var bottomGaugeRow: some View {
        HStack(spacing: AXSpacing.sm) {
            ResourceGaugeCard(title: L10n.ServerSettings.ioWait, value: String(format: "%.1f%%", vm.ioWait),
                              subtitle: L10n.ServerSettings.diskLatency, percent: min(vm.ioWait, 100) / 100,
                              color: ResourceColor.ioWait(vm.ioWait))
            ResourceGaugeCard(title: L10n.ServerSettings.processes, value: "\(vm.processCount)",
                              subtitle: L10n.Status.running, percent: 0, color: .axAccentBlue)
            ResourceGaugeCard(title: L10n.ServerSettings.networkLabel, value: "↓\(vm.networkRxRate.humanReadableRate)",
                              subtitle: "↑\(vm.networkTxRate.humanReadableRate)", percent: 0, color: .axAccentGreen)
            if let temp = vm.cpuTemp {
                ResourceGaugeCard(title: L10n.ServerSettings.temp, value: String(format: "%.0f°C", temp),
                                  subtitle: temp < 60 ? L10n.ServerSettings.normal : temp < 80 ? L10n.ServerSettings.warm : L10n.ServerSettings.hot,
                                  percent: min(temp, 100) / 100, color: ResourceColor.temp(temp))
            } else {
                ResourceGaugeCard(title: L10n.ServerSettings.diskIO, value: "R:\(vm.diskReadSectors)",
                                  subtitle: "W:\(vm.diskWriteSectors) \(L10n.ServerSettings.sectors)", percent: 0, color: .axTextSecondary)
            }
        }
    }
}
