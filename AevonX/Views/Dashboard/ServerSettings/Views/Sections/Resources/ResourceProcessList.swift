//
//  ResourceProcessList.swift
//  AevonX
//
//  Top processes table with sort toggle and kill button.
//

import SwiftUI

struct ResourceProcessList: View {
    @ObservedObject var vm: ResourceMonitorVM
    @State private var showKillConfirm: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            header
            headerColumns
            ForEach(vm.displayedProcesses.prefix(15)) { proc in
                processRow(proc)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private var header: some View {
        HStack {
            Text(L10n.ServerSettings.topProcesses)
                .font(AXTypography.caption).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)
            Spacer()
            Picker("", selection: $vm.sortMode) {
                ForEach(ProcessSortMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
        }
    }

    private var headerColumns: some View {
        HStack(spacing: AXSpacing.xs) {
            Text(L10n.ServerSettings.pid).frame(width: 50, alignment: .leading)
            Text(L10n.ServerSettings.user).frame(width: 60, alignment: .leading)
            Text(L10n.ServerSettings.cpuPercent).frame(width: 45, alignment: .trailing)
            Text(L10n.ServerSettings.memPercent).frame(width: 45, alignment: .trailing)
            Text(L10n.ServerSettings.command).frame(maxWidth: .infinity, alignment: .leading)
            Text("").frame(width: 24)
        }
        .font(AXTypography.caption2).foregroundColor(.axTextMuted)
    }

    private func processRow(_ proc: ServerProcessInfo) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Text("\(proc.pid)").frame(width: 50, alignment: .leading)
            Text(proc.user).frame(width: 60, alignment: .leading).lineLimit(1)
            Text(String(format: "%.1f", proc.cpuPercent)).frame(width: 45, alignment: .trailing)
                .foregroundColor(ResourceColor.cpu(proc.cpuPercent))
            Text(String(format: "%.1f", proc.memPercent)).frame(width: 45, alignment: .trailing)
                .foregroundColor(ResourceColor.ram(proc.memPercent))
            Text(proc.command).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
            killButton(proc.pid)
        }
        .font(AXTypography.monoXs)
        .foregroundColor(.axTextSecondary)
        .padding(.vertical, 1)
    }

    private func killButton(_ pid: Int) -> some View {
        Group {
            if showKillConfirm == pid {
                Button(action: {
                    showKillConfirm = nil
                    Task { await vm.killProcess(pid) }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AXTypography.caption2).foregroundColor(.axError)
                }.buttonStyle(PlainButtonStyle())
            } else {
                Button(action: { showKillConfirm = pid }) {
                    Image(systemName: "xmark.circle")
                        .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .frame(width: 24)
    }
}
