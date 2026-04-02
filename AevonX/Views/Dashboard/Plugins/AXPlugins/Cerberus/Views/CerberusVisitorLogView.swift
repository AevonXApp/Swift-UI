//
//  CerberusVisitorLogView.swift
//  AevonX
//
//  Visitor Log tab — real-time access log viewer with filtering,
//  search, and request detail inspection.
//

import SwiftUI
import AevonXCoreBridge

struct CerberusVisitorLogView: View {
    @ObservedObject var viewModel: CerberusViewModel
    @State private var searchQuery = ""
    @State private var selectedFilter: VisitorFilter = .all
    @State private var selectedEntry: WAFAccessLogEntry?
    @State private var selectedDomain: String?
    @State private var currentPage = 0
    private let pageSize = 50

    var body: some View {
        VStack(spacing: 0) {
            visitorLogHeader
            Divider().background(Color.axDivider)
            filterBar
            Divider().background(Color.axDivider)
            logContent
        }
        .task { await viewModel.loadAccessLog() }
        .sheet(item: $selectedEntry) { entry in
            visitorDetailSheet(entry)
        }
    }
}

// MARK: - Filter

private enum VisitorFilter: String, CaseIterable {
    case all, success, errors, blocked, bots

    var label: String {
        switch self {
        case .all:     return L10n.Cerberus.VisitorLog.filterAll
        case .success: return L10n.Cerberus.VisitorLog.filterSuccess
        case .errors:  return L10n.Cerberus.VisitorLog.filterErrors
        case .blocked: return L10n.Cerberus.VisitorLog.filterBlocked
        case .bots:    return L10n.Cerberus.VisitorLog.filterBots
        }
    }
}

// MARK: - Header

private extension CerberusVisitorLogView {

    var visitorLogHeader: some View {
        HStack(spacing: AXSpacing.xl) {
            headerIcon
            headerTitle
            Spacer()
            headerStats
            refreshButton
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
        .background(
            Color.axSurface.overlay(
                LinearGradient(
                    colors: [Color.axAccentBlue.opacity(0.03), Color.clear],
                    startPoint: .leading, endPoint: .trailing
                )
            )
        )
    }

    var headerIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.axAccentBlue.opacity(0.2), Color.axAccentBlue.opacity(0.04)],
                        center: .center, startRadius: 0, endRadius: 24
                    )
                )
                .frame(width: 44, height: 44)
            Circle()
                .stroke(Color.axAccentBlue.opacity(0.25), lineWidth: 1)
                .frame(width: 44, height: 44)
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(AXTypography.headline)
                .foregroundStyle(Color.axAccentBlue)
        }
    }

    var headerTitle: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(L10n.Cerberus.VisitorLog.title)
                .font(AXTypography.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.axTextPrimary)
            Text(L10n.Cerberus.VisitorLog.subtitle)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextTertiary)
        }
    }

    var headerStats: some View {
        HStack(spacing: AXSpacing.xl) {
            miniStat(
                value: "\(viewModel.accessLog.count)",
                label: L10n.Cerberus.VisitorLog.totalRequests,
                color: .axAccentBlue
            )
            Divider().frame(height: 28)
            miniStat(
                value: "\(botCount)",
                label: L10n.Cerberus.VisitorLog.botRequests,
                color: .axWarning
            )
            Divider().frame(height: 28)
            miniStat(
                value: avgLatencyText,
                label: L10n.Cerberus.VisitorLog.avgLatency,
                color: .axAccentGreen
            )
            Divider().frame(height: 28)
            miniStat(
                value: errorRateText,
                label: L10n.Cerberus.VisitorLog.errorRate,
                color: .axError
            )
        }
    }

    func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xxxs) {
            Text(value)
                .font(AXTypography.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
        }
    }

    var refreshButton: some View {
        Button {
            Task { await viewModel.loadAccessLog() }
        } label: {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "arrow.clockwise")
                Text(L10n.Button.refresh)
            }
            .font(AXTypography.caption)
            .fontWeight(.medium)
            .foregroundStyle(Color.axAccentBlue)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(Color.axAccentBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Bar

private extension CerberusVisitorLogView {

    var filterBar: some View {
        HStack(spacing: AXSpacing.md) {
            ForEach(VisitorFilter.allCases, id: \.self) { filter in
                filterChip(filter)
            }
            Divider().frame(height: 20)
            domainPicker
            Spacer()
            AXTextField(
                placeholder: L10n.Cerberus.VisitorLog.searchPlaceholder,
                text: $searchQuery,
                icon: "magnifyingglass"
            )
            .frame(maxWidth: 300)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
        .onChange(of: searchQuery) { _ in currentPage = 0 }
        .onChange(of: selectedFilter) { _ in currentPage = 0 }
        .onChange(of: selectedDomain) { _ in currentPage = 0 }
    }

    var domainPicker: some View {
        Menu {
            Button {
                selectedDomain = nil
            } label: {
                HStack {
                    Text(L10n.Cerberus.VisitorLog.allDomains)
                    if selectedDomain == nil { Image(systemName: "checkmark") }
                }
            }
            Divider()
            ForEach(uniqueDomains, id: \.self) { domain in
                Button {
                    selectedDomain = domain
                } label: {
                    HStack {
                        Text(domain)
                        if selectedDomain == domain { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: AXSpacing.xxxs) {
                Image(systemName: "globe")
                    .font(.system(size: 10))
                Text(selectedDomain ?? L10n.Cerberus.VisitorLog.allDomains)
                    .font(AXTypography.caption)
                    .fontWeight(selectedDomain != nil ? .semibold : .regular)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .foregroundStyle(selectedDomain != nil ? Color.axAccentBlue : Color.axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(selectedDomain != nil ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        }
    }

    func filterChip(_ filter: VisitorFilter) -> some View {
        let isSelected = selectedFilter == filter
        let count = countFor(filter)
        return Button {
            selectedFilter = filter
        } label: {
            HStack(spacing: AXSpacing.xxxs) {
                Text(filter.label)
                    .font(AXTypography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                if count > 0 {
                    Text("\(count)")
                        .font(AXTypography.caption2)
                        .foregroundStyle(isSelected ? .white : Color.axTextMuted)
                        .padding(.horizontal, AXSpacing.xs)
                        .padding(.vertical, AXSpacing.xxxs)
                        .background(isSelected ? Color.axAccentBlue : Color.axSurfaceHover)
                        .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.full))
                }
            }
            .foregroundStyle(isSelected ? Color.axAccentBlue : Color.axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(isSelected ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log Content

private extension CerberusVisitorLogView {

    var logContent: some View {
        Group {
            if viewModel.visitorLogLoading && viewModel.accessLog.isEmpty {
                loadingState
            } else if filteredEntries.isEmpty {
                emptyState
            } else {
                logTable
            }
        }
        .animation(.easeInOut(duration: 0.15), value: selectedFilter)
        .animation(.easeInOut(duration: 0.15), value: currentPage)
    }

    var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.axTextMuted)
            Text(L10n.Cerberus.VisitorLog.noEntries)
                .font(AXTypography.headline)
                .foregroundStyle(Color.axTextSecondary)
            Text(L10n.Cerberus.VisitorLog.noEntriesDesc)
                .font(AXTypography.caption)
                .foregroundStyle(Color.axTextMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var logTable: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    logTableHeader
                    ForEach(paginatedEntries) { entry in
                        logRow(entry)
                        Divider().background(Color.axDivider.opacity(0.5))
                    }
                }
            }
            if totalPages > 1 {
                Divider().background(Color.axDivider)
                paginationBar
            }
        }
    }

    var paginationBar: some View {
        HStack(spacing: AXSpacing.md) {
            Text(L10n.Cerberus.VisitorLog.showingEntries(
                currentPage * pageSize + 1,
                min((currentPage + 1) * pageSize, filteredEntries.count),
                filteredEntries.count
            ))
            .font(AXTypography.caption)
            .foregroundStyle(Color.axTextMuted)

            Spacer()

            HStack(spacing: AXSpacing.xs) {
                pageButton(icon: "chevron.left.2", action: { currentPage = 0 }, disabled: currentPage == 0)
                pageButton(icon: "chevron.left", action: { currentPage -= 1 }, disabled: currentPage == 0)

                Text(L10n.Cerberus.VisitorLog.pageOf(currentPage + 1, totalPages))
                    .font(AXTypography.monoSm)
                    .foregroundStyle(Color.axTextSecondary)

                pageButton(icon: "chevron.right", action: { currentPage += 1 }, disabled: currentPage >= totalPages - 1)
                pageButton(icon: "chevron.right.2", action: { currentPage = totalPages - 1 }, disabled: currentPage >= totalPages - 1)
            }
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    func pageButton(icon: String, action: @escaping () -> Void, disabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(disabled ? Color.axTextMuted.opacity(0.4) : Color.axAccentBlue)
                .frame(width: 26, height: 26)
                .background(disabled ? Color.clear : Color.axAccentBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    var logTableHeader: some View {
        HStack(spacing: 0) {
            headerCell(L10n.Cerberus.VisitorLog.colTime, width: 100)
            headerCell(L10n.Cerberus.VisitorLog.colIP, width: 130)
            headerCell(L10n.Cerberus.VisitorLog.colCountry, width: 70)
            headerCell(L10n.Cerberus.VisitorLog.colMethod, width: 60)
            headerCell(L10n.Cerberus.VisitorLog.colPath, width: nil)
            headerCell(L10n.Cerberus.VisitorLog.colStatus, width: 60)
            headerCell(L10n.Cerberus.VisitorLog.colLatency, width: 70)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axSurface)
        .overlay(Divider().background(Color.axDivider), alignment: .bottom)
    }

    func headerCell(_ title: String, width: CGFloat?) -> some View {
        Text(title)
            .font(AXTypography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.axTextMuted)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .padding(.horizontal, AXSpacing.xs)
    }

    func logRow(_ entry: WAFAccessLogEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            HStack(spacing: 0) {
                Text(formatTime(entry.timestamp))
                    .frame(width: 100, alignment: .leading)
                Text(entry.ip)
                    .frame(width: 130, alignment: .leading)
                countryCell(entry)
                    .frame(width: 70, alignment: .leading)
                methodBadge(entry.method)
                    .frame(width: 60, alignment: .leading)
                pathCell(entry)
                    .frame(maxWidth: .infinity, alignment: .leading)
                statusBadge(entry.statusCode)
                    .frame(width: 60, alignment: .leading)
                Text(String(format: "%.0fms", entry.latencyMs))
                    .frame(width: 70, alignment: .trailing)
            }
            .font(AXTypography.monoSm)
            .foregroundStyle(Color.axTextPrimary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func countryCell(_ entry: WAFAccessLogEntry) -> some View {
        HStack(spacing: AXSpacing.xxxs) {
            if !entry.countryCode.isEmpty {
                Text(flagEmoji(for: entry.countryCode))
                    .font(.system(size: 12))
                Text(entry.countryCode)
            } else {
                Text("—")
                    .foregroundStyle(Color.axTextMuted)
            }
        }
    }

    func methodBadge(_ method: String) -> some View {
        let color: Color = switch method {
        case "GET": .axAccentGreen
        case "POST": .axAccentBlue
        case "PUT", "PATCH": .axWarning
        case "DELETE": .axError
        default: .axTextMuted
        }
        return Text(method)
            .font(AXTypography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color)
    }

    func pathCell(_ entry: WAFAccessLogEntry) -> some View {
        HStack(spacing: AXSpacing.xxxs) {
            Text(entry.path)
                .lineLimit(1)
                .truncationMode(.middle)
            if entry.isBot {
                Image(systemName: "ant.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.axWarning)
            }
        }
    }

    func statusBadge(_ code: Int) -> some View {
        let color: Color = switch code {
        case 200..<300: .axAccentGreen
        case 300..<400: .axAccentBlue
        case 403: .axError
        case 400..<500: .axWarning
        case 500...: .axError
        default: .axTextMuted
        }
        return Text("\(code)")
            .font(AXTypography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, AXSpacing.xs)
            .padding(.vertical, AXSpacing.xxxs)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.xs))
    }
}

// MARK: - Detail Sheet

private extension CerberusVisitorLogView {

    func visitorDetailSheet(_ entry: WAFAccessLogEntry) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack {
                Text("\(entry.method) \(entry.path)")
                    .font(AXTypography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.axTextPrimary)
                    .lineLimit(1)
                Spacer()
                statusBadge(entry.statusCode)
            }

            Divider()

            detailGrid(entry)

            Spacer()
        }
        .padding(AXSpacing.xxl)
        .frame(width: 500, height: 400)
        .background(Color.axBackground)
    }

    func detailGrid(_ entry: WAFAccessLogEntry) -> some View {
        let rows: [(String, String)] = [
            ("IP", entry.ip),
            ("Country", entry.countryCode.isEmpty ? "—" : "\(flagEmoji(for: entry.countryCode)) \(entry.country) (\(entry.countryCode))"),
            ("Host", entry.host),
            ("Method", entry.method),
            ("Path", entry.path),
            ("Status", "\(entry.statusCode)"),
            ("Latency", String(format: "%.1fms", entry.latencyMs)),
            ("Bytes In", "\(entry.bytesIn)"),
            ("Bytes Out", "\(entry.bytesOut)"),
            ("User-Agent", entry.userAgent),
            ("Bot", entry.isBot ? "Yes" : "No"),
            ("Timestamp", entry.timestamp),
        ]

        return LazyVGrid(columns: [
            GridItem(.fixed(90), alignment: .topLeading),
            GridItem(.flexible(), alignment: .topLeading)
        ], spacing: AXSpacing.sm) {
            ForEach(rows, id: \.0) { label, value in
                Text(label)
                    .font(AXTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.axTextMuted)
                Text(value)
                    .font(AXTypography.caption)
                    .foregroundStyle(Color.axTextPrimary)
                    .textSelection(.enabled)
            }
        }
    }
}

// MARK: - Helpers

private extension CerberusVisitorLogView {

    var filteredEntries: [WAFAccessLogEntry] {
        var entries = viewModel.accessLog

        if let domain = selectedDomain {
            entries = entries.filter { $0.host == domain }
        }

        switch selectedFilter {
        case .all: break
        case .success: entries = entries.filter { (200..<300).contains($0.statusCode) }
        case .errors:  entries = entries.filter { $0.statusCode >= 400 }
        case .blocked: entries = entries.filter { $0.statusCode == 403 }
        case .bots:    entries = entries.filter { $0.isBot }
        }

        if !searchQuery.isEmpty {
            entries = entries.filter {
                $0.ip.localizedCaseInsensitiveContains(searchQuery)
                || $0.path.localizedCaseInsensitiveContains(searchQuery)
                || $0.userAgent.localizedCaseInsensitiveContains(searchQuery)
                || $0.host.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        return entries
    }

    var paginatedEntries: [WAFAccessLogEntry] {
        let start = currentPage * pageSize
        let end = min(start + pageSize, filteredEntries.count)
        guard start < end else { return [] }
        return Array(filteredEntries[start..<end])
    }

    var totalPages: Int {
        max(1, (filteredEntries.count + pageSize - 1) / pageSize)
    }

    var uniqueDomains: [String] {
        Array(Set(viewModel.accessLog.map(\.host)))
            .filter { !$0.isEmpty }
            .sorted()
    }

    var botCount: Int {
        viewModel.accessLog.filter(\.isBot).count
    }

    var avgLatencyText: String {
        guard !viewModel.accessLog.isEmpty else { return "—" }
        let avg = viewModel.accessLog.map(\.latencyMs).reduce(0, +) / Double(viewModel.accessLog.count)
        return String(format: "%.0fms", avg)
    }

    var errorRateText: String {
        guard !viewModel.accessLog.isEmpty else { return "—" }
        let errors = viewModel.accessLog.filter { $0.statusCode >= 400 }.count
        let rate = Double(errors) / Double(viewModel.accessLog.count) * 100
        return String(format: "%.1f%%", rate)
    }

    func countFor(_ filter: VisitorFilter) -> Int {
        switch filter {
        case .all:     return viewModel.accessLog.count
        case .success: return viewModel.accessLog.filter { (200..<300).contains($0.statusCode) }.count
        case .errors:  return viewModel.accessLog.filter { $0.statusCode >= 400 }.count
        case .blocked: return viewModel.accessLog.filter { $0.statusCode == 403 }.count
        case .bots:    return viewModel.accessLog.filter(\.isBot).count
        }
    }

    func formatTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else {
            return iso
        }
        let display = DateFormatter()
        display.dateFormat = "HH:mm:ss"
        return display.string(from: date)
    }

    func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let s = Unicode.Scalar(base + scalar.value) { flag.append(String(s)) }
        }
        return flag.isEmpty ? "🏳️" : flag
    }
}
