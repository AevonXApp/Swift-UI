//
//  ChronoTimelineView.swift
//  AevonX
//
//  ChronoLog audit trail — filterable timeline of all events.
//

import SwiftUI

struct ChronoTimelineView: View {
    @ObservedObject var viewModel: ChronoViewModel
    @State private var filterProject: String?
    @State private var filterEvent: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                header
                filterBar
                timelineContent
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadTimeline() }
    }

    // MARK: - Header

    private var header: some View {
        Text(L10n.Chrono.timelineTitle)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.axTextPrimary)
    }

    // MARK: - Filter

    private var filterBar: some View {
        HStack(spacing: AXSpacing.md) {
            filterPill(label: "All", isActive: filterEvent == nil) { filterEvent = nil }
            filterPill(label: "Deploy", isActive: filterEvent == "deploy") { filterEvent = "deploy" }
            filterPill(label: "Rollback", isActive: filterEvent == "rollback") { filterEvent = "rollback" }
            filterPill(label: "Health", isActive: filterEvent == "health") { filterEvent = "health" }
            filterPill(label: "Security", isActive: filterEvent == "security") { filterEvent = "security" }
            Spacer()
        }
    }

    private func filterPill(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isActive ? .white : .axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xs)
                .background(isActive ? Color.axAccentPurple : Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var timelineContent: some View {
        if filteredEntries.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 0) {
                ForEach(filteredEntries) { entry in
                    timelineRow(entry)
                }
            }
        }
    }

    private var filteredEntries: [ChronoTimelineEntry] {
        viewModel.timeline.filter { entry in
            if let fe = filterEvent, entry.event != fe { return false }
            if let fp = filterProject, entry.projectId != fp { return false }
            return true
        }
    }

    // MARK: - Row

    private func timelineRow(_ entry: ChronoTimelineEntry) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            timelineDot(entry)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                HStack(spacing: AXSpacing.xs) {
                    Text(entry.projectName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                    Text(entry.event.capitalized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(eventColor(entry.event))
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(eventColor(entry.event).opacity(0.1))
                        .clipShape(Capsule())
                }
                Text(entry.message)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(2)
                HStack(spacing: AXSpacing.sm) {
                    Text(entry.timestamp)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    if let hash = entry.commitHash {
                        Text(hash.prefix(7))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axAccentPurple)
                    }
                }
            }
            Spacer()
            statusBadge(entry.status)
        }
        .padding(.vertical, AXSpacing.md)
        .padding(.horizontal, AXSpacing.lg)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.md)
        .padding(.bottom, AXSpacing.xs)
    }

    private func timelineDot(_ entry: ChronoTimelineEntry) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(eventColor(entry.event))
                .frame(width: 10, height: 10)
            Rectangle()
                .fill(Color.axBorder)
                .frame(width: 1)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 10)
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.capitalized)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(statusColor(status))
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxxs)
            .background(statusColor(status).opacity(0.1))
            .clipShape(Capsule())
    }

    private func eventColor(_ event: String) -> Color {
        switch event {
        case "deploy": return .axAccentBlue
        case "rollback": return .axWarning
        case "health": return .axSuccess
        case "security": return .axError
        case "watcher": return .axAccentPurple
        default: return .axTextMuted
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "success": return .axSuccess
        case "failed": return .axError
        case "warning": return .axWarning
        default: return .axTextMuted
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36))
                .foregroundColor(.axTextMuted)
            Text(L10n.Chrono.timelineEmpty)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }
}
