//
//  ResourceDiskList.swift
//  AevonX
//
//  Enhanced disk partition list with usage bars and inode info.
//

import SwiftUI

struct ResourceDiskList: View {
    @ObservedObject var vm: ResourceMonitorVM

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.ServerSettings.diskUsage)
                .font(AXTypography.caption).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)

            ForEach(vm.diskPartitions) { part in
                diskRow(part)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func diskRow(_ part: DiskPartitionInfo) -> some View {
        VStack(spacing: AXSpacing.xxs) {
            HStack {
                Text(part.mount).font(AXTypography.monoXs).foregroundColor(.axTextPrimary)
                Text(part.filesystem).font(AXTypography.caption2).foregroundColor(.axTextTertiary)
                Spacer()
                Text("\(part.used) / \(part.size)").font(AXTypography.monoXs).foregroundColor(.axTextSecondary)
                Text("\(part.usagePercent)%")
                    .font(AXTypography.monoXs).fontWeight(.bold)
                    .foregroundColor(ResourceColor.disk(part.usagePercent))
            }
            diskBar(percent: part.usagePercent)
            if let inode = part.inodeUsedPercent {
                HStack {
                    Text(L10n.ServerSettings.inodePercent(inode))
                        .font(AXTypography.caption2)
                        .foregroundColor(ResourceColor.disk(inode))
                    Spacer()
                }
            }
        }
    }

    private func diskBar(percent: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(Color.axBorder.opacity(0.3))
                RoundedRectangle(cornerRadius: AXCornerRadius.xs)
                    .fill(ResourceColor.disk(percent))
                    .frame(width: max(geo.size.width * CGFloat(percent) / 100, 0))
            }
        }
        .frame(height: 4)
    }
}
