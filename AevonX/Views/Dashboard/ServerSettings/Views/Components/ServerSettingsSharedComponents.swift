//
//  ServerSettingsSharedComponents.swift
//  AevonX
//
//  Small reusable components for server settings views.
//

import SwiftUI

// MARK: - Status Badge

struct ServerSettingsBadge: View {
    let text: String
    let color: Color
    var icon: String? = nil

    var body: some View {
        HStack(spacing: AXSpacing.xxs) {
            if let icon {
                Image(systemName: icon).font(AXTypography.caption2)
            } else {
                Circle().fill(color).frame(width: 6, height: 6)
            }
            Text(text).font(AXTypography.caption2).fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, AXSpacing.sm).padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(AXCornerRadius.sm)
    }
}

// MARK: - Quick Action Button

struct ServerSettingsQuickAction: View {
    let icon: String
    let title: String
    let color: Color
    let action: () async -> Void

    var body: some View {
        Button(action: { Task { await action() } }) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon).font(AXTypography.subheadline).fontWeight(.semibold)
                Text(title).font(AXTypography.subheadline).fontWeight(.medium)
            }
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.sm)
            .background(color.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(color.opacity(0.2), lineWidth: 1))
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Disk Partition Row

struct DiskPartitionRow: View {
    let mount: String
    let size: String
    let used: String
    let percent: Int

    var body: some View {
        VStack(spacing: AXSpacing.xxs) {
            HStack {
                Text(mount)
                    .font(AXTypography.monoSm)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Text("\(used) / \(size)")
                    .font(AXTypography.monoXs)
                    .foregroundColor(.axTextSecondary)
                Text("\(percent)%")
                    .font(AXTypography.monoXs).fontWeight(.bold)
                    .foregroundColor(percent >= 90 ? .axError : percent >= 70 ? .axWarning : .axSuccess)
            }
            DiskUsageBar(percent: percent)
        }
    }
}

