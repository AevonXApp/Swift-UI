//
//  DBActivityLogSection.swift
//  AevonX
//
//  Premium activity log with timeline design,
//  filter by type, and operation-specific icons.
//

import SwiftUI
import AevonXCoreBridge

struct DBActivityLogSection: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel

    @State private var filterType: String = "all"
    @State private var appear = false
    @State private var searchText = ""

    private var filteredLog: [DBActivityLogEntry] {
        var log = viewModel.activityLog
        if filterType != "all" {
            log = log.filter { $0.action.lowercased().contains(filterType.lowercased()) }
        }
        if !searchText.isEmpty {
            log = log.filter {
                $0.action.localizedCaseInsensitiveContains(searchText) ||
                $0.detail.localizedCaseInsensitiveContains(searchText)
            }
        }
        return log
    }

    var body: some View {
        VStack(spacing: 0) {
            logToolbar
            Divider().background(Color.axBorder)
            logContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5)) { appear = true }
        }
    }

    // MARK: - Toolbar

    private var logToolbar: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(AXTypography.headline)
                    .foregroundColor(.axAccentBlue)
                Text(L10n.Database.activityLog)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)

                if !viewModel.activityLog.isEmpty {
                    Text(L10n.Database.entriesCount(viewModel.activityLog.count))
                        .font(AXTypography.caption2)
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.axAccentBlue.opacity(0.1))
                        .cornerRadius(AXCornerRadius.full)
                }
            }

            Spacer()

            // Filter
            Picker(L10n.Database.all, selection: $filterType) {
                Text(L10n.Database.all).tag("all")
                Text(L10n.Button.create).tag("create")
                Text(L10n.Database.filterInsert).tag("insert")
                Text(L10n.Database.filterUpdate).tag("update")
                Text(L10n.Button.delete).tag("delete")
                Text(L10n.Database.filterAlter).tag("alter")
                Text(L10n.Database.filterQuery).tag("select")
                Text(L10n.Database.filterBackup).tag("backup")
            }
            .labelsHidden()
            .frame(width: 100)

            // Export Log
            if !viewModel.activityLog.isEmpty {
                Button {
                    let text = viewModel.activityLog.map { entry in
                        "[\(entry.timestamp.formatted())] \(entry.action): \(entry.detail)\(entry.errorMessage.map { " ERROR: \($0)" } ?? "")"
                    }.joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    GlobalToastManager.shared.showSuccess(L10n.Database.logEntriesCopied(viewModel.activityLog.count))
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "doc.on.doc")
                            .font(AXTypography.caption2)
                        Text(L10n.Database.export)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }

            // Clear
            if !viewModel.activityLog.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.activityLog.removeAll()
                    }
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "trash")
                            .font(AXTypography.caption2)
                        Text(L10n.Button.clear)
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axError)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axError.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
    }

    // MARK: - Content

    @ViewBuilder
    private var logContent: some View {
        if viewModel.activityLog.isEmpty {
            logEmptyState
        } else if filteredLog.isEmpty {
            VStack(spacing: AXSpacing.md) {
                Spacer()
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(AXTypography.largeTitle)
                    .foregroundColor(.axTextMuted.opacity(0.4))
                Text(L10n.Database.noMatchingEntries)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
                Button {
                    filterType = "all"
                } label: {
                    Text(L10n.Database.clearFilter)
                        .font(AXTypography.caption)
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            logTimeline
        }
    }

    private var logEmptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Spacer()
            Image(systemName: "clock")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axTextMuted.opacity(0.4))
            Text(L10n.Database.noActivityYet)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            Text(L10n.Database.actionsLoggedHere)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Timeline

    private var logTimeline: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(filteredLog.enumerated()), id: \.element.id) { index, entry in
                    timelineRow(entry, isLast: index == filteredLog.count - 1)
                }
            }
            .padding(AXSpacing.lg)
        }
    }

    private func timelineRow(_ entry: DBActivityLogEntry, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            // Timeline line + icon
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(entry.success ? Color.axSuccess.opacity(0.15) : Color.axError.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: iconForAction(entry.action))
                        .font(AXTypography.caption2)
                        .foregroundColor(entry.success ? .axSuccess : .axError)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.axBorder)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)

            // Content card
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                HStack {
                    Text(entry.action)
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)

                    // Log entry actions — AXActionMenu
                    AXActionMenu(sections: [
                        AXMenuSection(items: {
                            var items: [AXMenuItem] = [
                                AXMenuItem(L10n.Database.copyEntry, icon: "doc.on.doc", color: .axAccentBlue) {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString("\(entry.action): \(entry.detail)", forType: .string)
                                    GlobalToastManager.shared.showSuccess(L10n.Database.logEntryCopied)
                                },
                            ]
                            if let err = entry.errorMessage {
                                items.append(AXMenuItem(L10n.Database.copyError, icon: "exclamationmark.triangle", color: .axError) {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(err, forType: .string)
                                    GlobalToastManager.shared.showSuccess(L10n.Database.errorMessageCopied)
                                })
                            }
                            return items
                        }()),
                    ], triggerIcon: "ellipsis", triggerSize: 20)
                }

                Text(entry.detail)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(2)

                if let error = entry.errorMessage {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(AXTypography.caption2)
                        Text(error)
                            .font(AXTypography.caption)
                    }
                    .foregroundColor(.axError)
                    .lineLimit(2)
                    .padding(AXSpacing.sm)
                    .background(Color.axError.opacity(0.05))
                    .cornerRadius(AXCornerRadius.sm)
                }
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
        .padding(.bottom, isLast ? 0 : AXSpacing.sm)
    }

    // MARK: - Helpers

    private func iconForAction(_ action: String) -> String {
        let lower = action.lowercased()
        if lower.contains("create") || lower.contains("add") { return "plus" }
        if lower.contains("insert") { return "arrow.right.doc.on.clipboard" }
        if lower.contains("update") || lower.contains("edit") { return "pencil" }
        if lower.contains("delete") || lower.contains("drop") || lower.contains("truncate") { return "trash" }
        if lower.contains("backup") || lower.contains("export") { return "arrow.down.doc" }
        if lower.contains("import") { return "square.and.arrow.down" }
        if lower.contains("query") || lower.contains("select") { return "magnifyingglass" }
        if lower.contains("load") { return "arrow.clockwise" }
        return "bolt.horizontal"
    }
}
