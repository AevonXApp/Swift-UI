//
//  DBActivityLogSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBActivityLogSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            logHeader
            Divider()
            logContent
        }
    }

    private var logHeader: some View {
        HStack {
            Text("Activity Log")
                .font(AXTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            Text("\(viewModel.activityLog.count) entries")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            Spacer()

            if !viewModel.activityLog.isEmpty {
                Button {
                    viewModel.activityLog.removeAll()
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("Clear")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axError)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.lg)
    }

    @ViewBuilder
    private var logContent: some View {
        if viewModel.activityLog.isEmpty {
            logEmptyState
        } else {
            logList
        }
    }

    private var logEmptyState: some View {
        VStack {
            Spacer()
            VStack(spacing: AXSpacing.md) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 36))
                    .foregroundColor(.axTextMuted)
                Text("No Activity Yet")
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
                Text("Actions you perform will be logged here.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var logList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.activityLog) { entry in
                    logRow(entry)
                    Divider()
                }
            }
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .padding(AXSpacing.lg)
        }
    }

    private func logRow(_ entry: ActivityLogEntry) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            // Status icon
            Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(entry.success ? .axSuccess : .axError)
                .frame(width: 20, alignment: .center)
                .padding(.top, 2)

            // Content
            VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                HStack(spacing: AXSpacing.sm) {
                    Text(entry.action)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }

                Text(entry.detail)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(2)

                if let error = entry.errorMessage {
                    Text(error)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                        .lineLimit(3)
                        .padding(.top, AXSpacing.xxxs)
                }
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
    }
}
