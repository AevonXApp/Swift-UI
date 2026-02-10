//
//  AdvancedLogsView.swift
//  AevonX
//
//  Premium logs viewer with table, filters, tabs, and IP blocking
//

import SwiftUI
import Combine
import AevonXCore

// MARK: - Log Type Tabs

enum LogTab: String, CaseIterable, Identifiable {
    case access = "Access Logs"
    case error = "Error Logs"
    case all = "All Logs"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .access: return "arrow.right.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .all: return "doc.text.fill"
        }
    }

    var color: Color {
        switch self {
        case .access: return .axAccentBlue
        case .error: return .axError
        case .all: return .axTextSecondary
        }
    }
}

// MARK: - Sort Options

enum LogSortOption: String, CaseIterable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case ipAddress = "IP Address"
    case statusCode = "Status Code"

    var icon: String {
        switch self {
        case .newestFirst: return "arrow.down"
        case .oldestFirst: return "arrow.up"
        case .ipAddress: return "network"
        case .statusCode: return "number"
        }
    }
}

// MARK: - Advanced Logs View

struct AdvancedLogsView: View {
    @StateObject private var viewModel: LogsViewModel

    init(websiteDomain: String, serverId: String?) {
        _viewModel = StateObject(wrappedValue: LogsViewModel(websiteDomain: websiteDomain, serverId: serverId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tabs & Controls Header
            controlsHeader

            Divider()
                .background(Color.axBorder.opacity(0.3))

            // Table Content
            if viewModel.isLoading {
                loadingState
            } else if viewModel.filteredLogs.isEmpty {
                emptyState
            } else {
                logsTable
            }
        }
        .background(Color.axBackground)
        .sheet(isPresented: $viewModel.showLogDetail) {
            if let log = viewModel.selectedLog {
                LogDetailSheet(log: log, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showIPBlockSheet) {
            if let ip = viewModel.selectedIP {
                IPBlockSheet(ip: ip, onBlock: { reason in
                    Task { await viewModel.blockIP(ip, reason: reason) }
                })
            }
        }
        .task {
            await viewModel.loadLogs()
        }
    }

    // MARK: - Controls Header

    private var controlsHeader: some View {
        VStack(spacing: AXSpacing.md) {
            // Tabs
            HStack(spacing: AXSpacing.sm) {
                ForEach(LogTab.allCases) { tab in
                    LogTabButton(
                        tab: tab,
                        isSelected: viewModel.selectedTab == tab,
                        count: viewModel.getCount(for: tab)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedTab = tab
                        }
                    }
                }

                Spacer()

                // Refresh Button
                Button(action: { Task { await viewModel.loadLogs() } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        if !viewModel.isLoading {
                            Text("Refresh")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading)
            }

            // Filters Row
            HStack(spacing: AXSpacing.sm) {
                // Search
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextTertiary)

                    TextField("Search IP, URL, or message...", text: $viewModel.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 12))
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 6)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .frame(width: 280)

                // Status Filter (for access logs)
                if viewModel.selectedTab == .access {
                    Menu {
                        Button("All Status") { viewModel.statusFilter = nil }
                        Divider()
                        Button("2xx Success") { viewModel.statusFilter = 200 }
                        Button("3xx Redirect") { viewModel.statusFilter = 300 }
                        Button("4xx Client Error") { viewModel.statusFilter = 400 }
                        Button("5xx Server Error") { viewModel.statusFilter = 500 }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 11))
                            Text(viewModel.statusFilterLabel)
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(.axTextSecondary)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 6)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                }

                // Sort Menu
                Menu {
                    ForEach(LogSortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.rawValue)
                                if viewModel.sortOption == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.sortOption.icon)
                            .font(.system(size: 11))
                        Text(viewModel.sortOption.rawValue)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                }

                Spacer()

                // Results Count
                Text("\(viewModel.filteredLogs.count) entries")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextTertiary)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.5))
    }

    // MARK: - Logs Table

    private var logsTable: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Table Header
                tableHeader

                Divider()
                    .background(Color.axBorder)

                // Table Rows
                ForEach(Array(viewModel.filteredLogs.enumerated()), id: \.element.id) { index, log in
                    LogTableRow(log: log, isEven: index % 2 == 0) {
                        viewModel.selectedLog = log
                        viewModel.showLogDetail = true
                    }

                    if index < viewModel.filteredLogs.count - 1 {
                        Divider()
                            .background(Color.axBorder.opacity(0.3))
                    }
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: AXSpacing.md) {
            Text("Time")
                .frame(width: 140, alignment: .leading)

            if viewModel.selectedTab != .error {
                Text("IP Address")
                    .frame(width: 130, alignment: .leading)

                Text("Method")
                    .frame(width: 70, alignment: .leading)
            }

            Text(viewModel.selectedTab == .error ? "Level" : "Status")
                .frame(width: 80, alignment: .leading)

            Text(viewModel.selectedTab == .error ? "Message" : "URL")
                .frame(minWidth: 200, alignment: .leading)

            Spacer()
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.axTextSecondary)
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading logs...")
                .font(.system(size: 14))
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.axTextTertiary.opacity(0.5))

            VStack(spacing: AXSpacing.xs) {
                Text("No Logs Found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                Text(viewModel.searchText.isEmpty ? "No logs available for this website" : "No logs match your search criteria")
                    .font(.system(size: 13))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Log Tab Button

struct LogTabButton: View {
    let tab: LogTab
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))

                Text(tab.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? .white : tab.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? tab.color : tab.color.opacity(0.15))
                        .cornerRadius(10)
                }
            }
            .foregroundColor(isSelected ? tab.color : .axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(isSelected ? tab.color.opacity(0.1) : (isHovered ? Color.axBackground.opacity(0.5) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(isSelected ? tab.color.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Log Table Row

struct LogTableRow: View {
    let log: LogEntryDisplay
    let isEven: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Time
                Text(log.timeFormatted)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .frame(width: 140, alignment: .leading)

                if log.type == .access {
                    // IP Address
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                            .font(.system(size: 9))
                            .foregroundColor(.axAccentBlue)
                        Text(log.ip ?? "N/A")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                    }
                    .frame(width: 130, alignment: .leading)

                    // Method
                    Text(log.method ?? "")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(methodColor(log.method))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(methodColor(log.method).opacity(0.1))
                        .cornerRadius(4)
                        .frame(width: 70, alignment: .leading)

                    // Status Code
                    Text(log.statusCode != nil ? "\(log.statusCode!)" : "")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor(log.statusCode))
                        .cornerRadius(6)
                        .frame(width: 80, alignment: .leading)
                } else {
                    // Error Level
                    HStack(spacing: 4) {
                        Image(systemName: log.levelIcon)
                            .font(.system(size: 10))
                        Text(log.level?.uppercased() ?? "")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(log.levelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(log.levelColor.opacity(0.1))
                    .cornerRadius(6)
                    .frame(width: 80, alignment: .leading)
                }

                // URL or Message
                Text(log.urlOrMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextSecondary)
                    .lineLimit(1)
                    .frame(minWidth: 200, alignment: .leading)

                Spacer()

                // Expand Icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextTertiary)
                    .opacity(isHovered ? 1 : 0)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(isHovered ? Color.axAccentBlue.opacity(0.05) : (isEven ? Color.axBackground : Color.axSurface.opacity(0.3)))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func methodColor(_ method: String?) -> Color {
        guard let method = method else { return .axTextMuted }
        switch method {
        case "GET": return .axAccentBlue
        case "POST": return .axSuccess
        case "PUT": return .axWarning
        case "DELETE": return .axError
        default: return .axTextSecondary
        }
    }

    private func statusColor(_ code: Int?) -> Color {
        guard let code = code else { return .axTextMuted }
        switch code {
        case 200..<300: return .axSuccess
        case 300..<400: return .axAccentBlue
        case 400..<500: return .axWarning
        case 500..<600: return .axError
        default: return .axTextMuted
        }
    }
}

// MARK: - Log Detail Sheet

struct LogDetailSheet: View {
    let log: LogEntryDisplay
    let viewModel: LogsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)

                    Text(log.timeFormatted)
                        .font(.system(size: 12))
                        .foregroundColor(.axTextTertiary)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            .background(Color.axSurface)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    if log.type == .access {
                        accessLogDetails
                    } else {
                        errorLogDetails
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .frame(width: 700, height: 600)
        .background(Color.axBackground)
    }

    private var accessLogDetails: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Request Info
            DetailSection(title: "Request Information", icon: "arrow.right.circle.fill") {
                LogDetailRow(label: "Method", value: log.method ?? "N/A")
                LogDetailRow(label: "URL", value: log.urlOrMessage)
                LogDetailRow(label: "Status Code", value: log.statusCode != nil ? "\(log.statusCode!)" : "N/A")
                LogDetailRow(label: "Response Time", value: log.responseTime ?? "N/A")
            }

            // Client Info
            DetailSection(title: "Client Information", icon: "network") {
                LogDetailRow(label: "IP Address", value: log.ip ?? "N/A")
                LogDetailRow(label: "User Agent", value: log.userAgent ?? "N/A")
                LogDetailRow(label: "Referer", value: log.referer ?? "N/A")
            }

            // Actions
            if let ip = log.ip {
                DetailSection(title: "Actions", icon: "shield.fill") {
                    Button(action: {
                        viewModel.selectedIP = ip
                        viewModel.showIPBlockSheet = true
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("Block IP Address: \(ip)")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axError)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var errorLogDetails: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            // Error Info
            DetailSection(title: "Error Information", icon: "exclamationmark.triangle.fill") {
                LogDetailRow(label: "Level", value: log.level?.uppercased() ?? "N/A")
                LogDetailRow(label: "Message", value: log.urlOrMessage)
                if let file = log.file {
                    LogDetailRow(label: "File", value: file)
                }
                if let line = log.line {
                    LogDetailRow(label: "Line", value: "\(line)")
                }
            }
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content

    init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axAccentBlue)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.axTextPrimary)
            }

            VStack(spacing: AXSpacing.xs) {
                content()
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
        }
    }
}

struct LogDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextSecondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.axTextPrimary)
                .textSelection(.enabled)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - IP Block Sheet

struct IPBlockSheet: View {
    let ip: String
    let onBlock: (String) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var reason: String = ""
    @State private var selectedDuration: BlockDuration = .permanent

    enum BlockDuration: String, CaseIterable {
        case oneHour = "1 Hour"
        case oneDay = "1 Day"
        case oneWeek = "1 Week"
        case permanent = "Permanent"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Block IP Address")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)

                    Text(ip)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.axError)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            .background(Color.axSurface)

            Divider()

            // Form
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Duration")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)

                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(BlockDuration.allCases, id: \.self) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Reason (Optional)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)

                    TextEditor(text: $reason)
                        .font(.system(size: 12))
                        .frame(height: 100)
                        .padding(AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.sm)
                }

                HStack(spacing: AXSpacing.md) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.axTextSecondary)
                            .padding(.horizontal, AXSpacing.lg)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        onBlock(reason)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("Block IP")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axError)
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(AXSpacing.xl)
        }
        .frame(width: 500, height: 400)
        .background(Color.axBackground)
    }
}

// MARK: - Log Entry Display Model

struct LogEntryDisplay: Identifiable {
    let id: UUID
    let type: LogTab
    let timestamp: Date
    let ip: String?
    let method: String?
    let statusCode: Int?
    let urlOrMessage: String
    let userAgent: String?
    let referer: String?
    let responseTime: String?
    let level: String?
    let file: String?
    let line: Int?

    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    var levelIcon: String {
        switch level?.lowercased() {
        case "error", "crit": return "xmark.circle.fill"
        case "warn", "warning": return "exclamationmark.triangle.fill"
        case "info", "notice": return "info.circle.fill"
        default: return "circle.fill"
        }
    }

    var levelColor: Color {
        switch level?.lowercased() {
        case "error", "crit": return .axError
        case "warn", "warning": return .axWarning
        case "info", "notice": return .axAccentBlue
        default: return .axTextSecondary
        }
    }
}

// MARK: - Logs ViewModel

@MainActor
class LogsViewModel: ObservableObject {
    @Published var selectedTab: LogTab = .all
    @Published var searchText: String = ""
    @Published var sortOption: LogSortOption = .newestFirst
    @Published var statusFilter: Int? = nil
    @Published var isLoading: Bool = false

    @Published var accessLogs: [LogEntryDisplay] = []
    @Published var errorLogs: [LogEntryDisplay] = []

    @Published var showLogDetail: Bool = false
    @Published var selectedLog: LogEntryDisplay? = nil

    @Published var showIPBlockSheet: Bool = false
    @Published var selectedIP: String? = nil

    private let websiteDomain: String
    private let serverId: String?

    init(websiteDomain: String, serverId: String?) {
        self.websiteDomain = websiteDomain
        self.serverId = serverId
    }

    var allLogs: [LogEntryDisplay] {
        accessLogs + errorLogs
    }

    var filteredLogs: [LogEntryDisplay] {
        var logs: [LogEntryDisplay]

        // Filter by tab
        switch selectedTab {
        case .access:
            logs = accessLogs
        case .error:
            logs = errorLogs
        case .all:
            logs = allLogs
        }

        // Filter by search
        if !searchText.isEmpty {
            logs = logs.filter { log in
                log.urlOrMessage.localizedCaseInsensitiveContains(searchText) ||
                (log.ip?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by status
        if let statusFilter = statusFilter {
            logs = logs.filter { log in
                guard let code = log.statusCode else { return false }
                return code >= statusFilter && code < statusFilter + 100
            }
        }

        // Sort
        switch sortOption {
        case .newestFirst:
            logs.sort { $0.timestamp > $1.timestamp }
        case .oldestFirst:
            logs.sort { $0.timestamp < $1.timestamp }
        case .ipAddress:
            logs.sort { ($0.ip ?? "") < ($1.ip ?? "") }
        case .statusCode:
            logs.sort { ($0.statusCode ?? 0) < ($1.statusCode ?? 0) }
        }

        return logs
    }

    var statusFilterLabel: String {
        guard let filter = statusFilter else { return "All Status" }
        switch filter {
        case 200: return "2xx Success"
        case 300: return "3xx Redirect"
        case 400: return "4xx Error"
        case 500: return "5xx Error"
        default: return "Filter"
        }
    }

    func getCount(for tab: LogTab) -> Int {
        switch tab {
        case .access: return accessLogs.count
        case .error: return errorLogs.count
        case .all: return allLogs.count
        }
    }

    func loadLogs() async {
        isLoading = true

        // Simulate loading - Replace with actual API calls
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Mock data
        accessLogs = generateMockAccessLogs()
        errorLogs = generateMockErrorLogs()

        isLoading = false
    }

    func blockIP(_ ip: String, reason: String) async {
        // Implement IP blocking logic via SSH
        print("Blocking IP: \(ip), Reason: \(reason)")
    }

    // Mock data generation
    private func generateMockAccessLogs() -> [LogEntryDisplay] {
        let methods = ["GET", "POST", "PUT", "DELETE"]
        let statuses = [200, 201, 301, 302, 400, 401, 404, 500, 502]
        let urls = ["/", "/api/users", "/login", "/dashboard", "/products/123"]

        return (0..<50).map { i in
            LogEntryDisplay(
                id: UUID(),
                type: .access,
                timestamp: Date().addingTimeInterval(-Double(i * 300)),
                ip: "192.168.1.\(Int.random(in: 1...255))",
                method: methods.randomElement(),
                statusCode: statuses.randomElement(),
                urlOrMessage: urls.randomElement()!,
                userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
                referer: "https://example.com",
                responseTime: "\(Int.random(in: 10...500))ms",
                level: nil,
                file: nil,
                line: nil
            )
        }
    }

    private func generateMockErrorLogs() -> [LogEntryDisplay] {
        let levels = ["error", "warn", "crit", "notice"]
        let messages = [
            "Database connection failed",
            "File not found: config.php",
            "Memory limit exceeded",
            "Undefined variable: user"
        ]

        return (0..<20).map { i in
            LogEntryDisplay(
                id: UUID(),
                type: .error,
                timestamp: Date().addingTimeInterval(-Double(i * 600)),
                ip: nil,
                method: nil,
                statusCode: nil,
                urlOrMessage: messages.randomElement()!,
                userAgent: nil,
                referer: nil,
                responseTime: nil,
                level: levels.randomElement(),
                file: "/var/www/html/index.php",
                line: Int.random(in: 1...1000)
            )
        }
    }
}
