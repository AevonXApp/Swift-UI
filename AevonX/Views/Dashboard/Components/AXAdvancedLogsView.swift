//
//  AXAdvancedLogsView.swift
//  AevonX
//
//  Premium generic logs viewer with table, filters, and real-time data fetching.
//  Supports multiple sources like individual websites or global Nginx service.
//

import SwiftUI
import Combine
import AevonXCore

// MARK: - Log Source

public enum AXLogSource: Equatable {
    case website(domain: String)
    case nginxService
    case apacheService
    case phpService
    // Database services
    case mysqlService
    case postgresqlService
    case redisService
    case mongodbService
    case mariadbService
    case cassandraService
    case elasticsearchService
    case cockroachdbService
    case genericService(name: String, path: String)

    var displayName: String {
        switch self {
        case .website(let domain): return "Site: \(domain)"
        case .nginxService: return "Nginx Service"
        case .apacheService: return "Apache Service"
        case .phpService: return "PHP-FPM Service"
        case .mysqlService: return "MySQL Service"
        case .postgresqlService: return "PostgreSQL Service"
        case .redisService: return "Redis Service"
        case .mongodbService: return "MongoDB Service"
        case .mariadbService: return "MariaDB Service"
        case .cassandraService: return "Cassandra Service"
        case .elasticsearchService: return "Elasticsearch Service"
        case .cockroachdbService: return "CockroachDB Service"
        case .genericService(let name, _): return "\(name) Service"
        }
    }
}

// MARK: - Log Type Tabs

enum AXLogTab: String, CaseIterable, Identifiable {
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

enum AXLogSortOption: String, CaseIterable {
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

// MARK: - AX Advanced Logs View

public struct AXAdvancedLogsView: View {
    @StateObject private var viewModel: AXLogsViewModel

    public init(
        source: AXLogSource,
        serverId: String?,
        onSuccess: ((String) -> Void)? = nil,
        onError: ((String) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: AXLogsViewModel(
            source: source,
            serverId: serverId,
            onSuccess: onSuccess,
            onError: onError
        ))
    }

    public var body: some View {
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
                AXLogDetailSheet(log: log, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showIPBlockSheet) {
            if let ip = viewModel.selectedIP {
                AXIPBlockSheet(ip: ip, onBlock: { reason in
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
                ForEach(AXLogTab.allCases) { tab in
                    AXLogTabButton(
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
                    ForEach(AXLogSortOption.allCases, id: \.self) { option in
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
                    AXLogTableRow(log: log, isEven: index % 2 == 0) {
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

                Text(viewModel.searchText.isEmpty ? "No logs available for this source" : "No logs match your search criteria")
                    .font(.system(size: 13))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - AX Log Tab Button

struct AXLogTabButton: View {
    let tab: AXLogTab
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

// MARK: - AX Log Table Row

struct AXLogTableRow: View {
    let log: AXLogEntryDisplay
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

// MARK: - AX Log Detail Sheet

struct AXLogDetailSheet: View {
    let log: AXLogEntryDisplay
    let viewModel: AXLogsViewModel
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
            AXDetailSection(title: "Request Information", icon: "arrow.right.circle.fill") {
                AXLogDetailRow(label: "Method", value: log.method ?? "N/A")
                AXLogDetailRow(label: "URL", value: log.urlOrMessage)
                AXLogDetailRow(label: "Status Code", value: log.statusCode != nil ? "\(log.statusCode!)" : "N/A")
                AXLogDetailRow(label: "Response Time", value: log.responseTime ?? "N/A")
            }

            // Client Info
            AXDetailSection(title: "Client Information", icon: "network") {
                AXLogDetailRow(label: "IP Address", value: log.ip ?? "N/A")
                AXLogDetailRow(label: "User Agent", value: log.userAgent ?? "N/A")
                AXLogDetailRow(label: "Referer", value: log.referer ?? "N/A")
            }

            // Actions
            if let ip = log.ip {
                AXDetailSection(title: "Actions", icon: "shield.fill") {
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
            AXDetailSection(title: "Error Information", icon: "exclamationmark.triangle.fill") {
                AXLogDetailRow(label: "Level", value: log.level?.uppercased() ?? "N/A")
                AXLogDetailRow(label: "Message", value: log.urlOrMessage)
                if let file = log.file {
                    AXLogDetailRow(label: "File", value: file)
                }
                if let line = log.line {
                    AXLogDetailRow(label: "Line", value: "\(line)")
                }
            }
        }
    }
}

struct AXDetailSection<Content: View>: View {
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

struct AXLogDetailRow: View {
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

// MARK: - AX IP Block Sheet

struct AXIPBlockSheet: View {
    let ip: String
    let onBlock: (String) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var reason: String = ""
    @State private var selectedDuration: AXBlockDuration = .permanent

    enum AXBlockDuration: String, CaseIterable {
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
                        ForEach(AXBlockDuration.allCases, id: \.self) { duration in
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

// MARK: - AX Log Entry Display Model

public struct AXLogEntryDisplay: Identifiable {
    public let id: UUID
    let type: AXLogTab
    public let timestamp: Date
    public let ip: String?
    public let method: String?
    public let statusCode: Int?
    public let urlOrMessage: String
    public let userAgent: String?
    public let referer: String?
    public let responseTime: String?
    public let level: String?
    public let file: String?
    public let line: Int?

    public var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    var levelIcon: String {
        switch level?.lowercased() {
        case "error", "crit", "emerg", "alert": return "xmark.circle.fill"
        case "warn", "warning": return "exclamationmark.triangle.fill"
        case "info", "notice", "debug": return "info.circle.fill"
        default: return "circle.fill"
        }
    }

    var levelColor: Color {
        switch level?.lowercased() {
        case "error", "crit", "emerg", "alert": return .axError
        case "warn", "warning": return .axWarning
        case "info", "notice", "debug": return .axAccentBlue
        default: return .axTextSecondary
        }
    }
}

// MARK: - AX Logs ViewModel

@MainActor
public final class AXLogsViewModel: ObservableObject {
    @Published var selectedTab: AXLogTab = .all
    @Published var searchText: String = ""
    @Published var sortOption: AXLogSortOption = .newestFirst
    @Published var statusFilter: Int? = nil
    @Published var isLoading: Bool = false

    @Published var accessLogs: [AXLogEntryDisplay] = []
    @Published var errorLogs: [AXLogEntryDisplay] = []

    @Published var showLogDetail: Bool = false
    @Published var selectedLog: AXLogEntryDisplay? = nil

    @Published var showIPBlockSheet: Bool = false
    @Published var selectedIP: String? = nil

    private let source: AXLogSource
    private let serverId: String?
    
    // Callbacks for UI feedback
    var onSuccess: ((String) -> Void)?
    var onError: ((String) -> Void)?

    // Services
    private let websiteLogService = WebsiteLogService.shared
    private let appManager = ApplicationManager.shared

    public init(
        source: AXLogSource,
        serverId: String?,
        onSuccess: ((String) -> Void)? = nil,
        onError: ((String) -> Void)? = nil
    ) {
        self.source = source
        self.serverId = serverId
        self.onSuccess = onSuccess
        self.onError = onError
    }

    var allLogs: [AXLogEntryDisplay] {
        accessLogs + errorLogs
    }

    var filteredLogs: [AXLogEntryDisplay] {
        var logs: [AXLogEntryDisplay]

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

    func getCount(for tab: AXLogTab) -> Int {
        switch tab {
        case .access: return accessLogs.count
        case .error: return errorLogs.count
        case .all: return allLogs.count
        }
    }

    func loadLogs() async {
        guard let serverId = serverId else { return }
        isLoading = true

        do {
            switch source {
            case .website(let domain):
                // Fetch Website Logs (Parsed from Service)
                let coreAccess = try await websiteLogService.getAccessLogs(domain: domain, serverId: serverId, limit: 200, filters: nil)
                let coreError = try await websiteLogService.getErrorLogs(domain: domain, serverId: serverId, limit: 200, filters: nil)
                
                self.accessLogs = coreAccess.map { entry in
                    AXLogEntryDisplay(
                        id: entry.id,
                        type: .access,
                        timestamp: entry.timestamp,
                        ip: entry.ip,
                        method: entry.method,
                        statusCode: entry.statusCode,
                        urlOrMessage: entry.url,
                        userAgent: entry.userAgent,
                        referer: entry.referrer,
                        responseTime: entry.responseTime != nil ? "\(Int(entry.responseTime!))ms" : nil,
                        level: nil,
                        file: nil,
                        line: nil
                    )
                }
                
                self.errorLogs = coreError.map { entry in
                    AXLogEntryDisplay(
                        id: entry.id,
                        type: .error,
                        timestamp: entry.timestamp,
                        ip: nil,
                        method: nil,
                        statusCode: nil,
                        urlOrMessage: entry.message,
                        userAgent: nil,
                        referer: nil,
                        responseTime: nil,
                        level: entry.level.rawValue,
                        file: entry.file,
                        line: entry.line
                    )
                }
                
            case .nginxService:
                // Fetch Global Nginx Logs (Raw then custom parse)
                let rawLogs = try await appManager.readLogs(type: .nginx, lines: 200, serverId: serverId)
                
                // Re-use parsing logic or manual parse for service logs
                // Since Nginx global logs use the same format, we can adapt the parsers
                self.accessLogs = parseAccessLevelLogs(rawLogs)
                self.errorLogs = parseErrorLevelLogs(rawLogs)
                
            case .phpService:
                // Fetch PHP-FPM Logs
                let rawLogs = try await appManager.readLogs(type: .phpFpm, lines: 200, serverId: serverId)
                
                // Parse PHP logs (mostly error logs for PHP-FPM)
                self.accessLogs = []
                self.errorLogs = parsePHPErrorLogs(rawLogs)
                
            case .apacheService:
                // Fetch Apache Logs
                let rawLogs = try await appManager.readLogs(type: .apache, lines: 200, serverId: serverId)
                self.accessLogs = parseAccessLevelLogs(rawLogs)
                self.errorLogs = parseErrorLevelLogs(rawLogs)

            case .mysqlService, .postgresqlService, .redisService, .mongodbService, .mariadbService, 
                 .cassandraService, .elasticsearchService, .cockroachdbService:
                // Map log source to application type
                let appType: ApplicationType
                switch source {
                case .mysqlService: appType = .mysql
                case .postgresqlService: appType = .postgresql
                case .redisService: appType = .redis
                case .mongodbService: appType = .mongodb
                case .mariadbService: appType = .mariadb
                case .cassandraService: appType = .cassandra
                case .elasticsearchService: appType = .elasticsearch
                case .cockroachdbService: appType = .cockroachdb
                default: appType = .unknown
                }
                
                if appType != .unknown {
                    let rawLogs = try await appManager.readLogs(type: appType, lines: 200, serverId: serverId)
                    // Database logs are typically error/output logs
                    self.accessLogs = []
                    self.errorLogs = parseErrorLevelLogs(rawLogs)
                }

            case .genericService(_, _):
                // Generic service logs - showing empty until custom path logic refined
                self.accessLogs = []
                self.errorLogs = []
            }
        } catch {
            print("Failed to load logs: \(error)")
        }

        isLoading = false
    }

    func blockIP(_ ip: String, reason: String) async {
        guard let serverId = serverId else { return }
        do {
            try await appManager.blockIP(ip, type: .nginx, serverId: serverId)
            onSuccess?("IP \(ip) blocked successfully")
        } catch {
            onError?("Failed to block IP: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Generic Parsers (Adapted from WebsiteLogService)
    
    private func parseAccessLevelLogs(_ raw: String) -> [AXLogEntryDisplay] {
        let lines = raw.components(separatedBy: .newlines)
        var entries: [AXLogEntryDisplay] = []
        
        // Pattern: #^(\S+) \S+ \S+ \[([\w:/]+\s[+\-]\d{4})\] "(\S+) (\S+) \S+" (\d{3}) (\d+) "([^"]*)" "([^"]*)""#
        let pattern = #"^(\S+) \S+ \S+ \[([\w:/]+\s[+\-]\d{4})\] "(\S+) (\S+) \S+" (\d{3}) (\d+) "([^"]*)" "([^"]*)""#
        let regex = try? NSRegularExpression(pattern: pattern)
        
        for line in lines {
            guard !line.isEmpty, let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else { continue }
            
            func extract(_ index: Int) -> String? {
                guard let range = Range(match.range(at: index), in: line) else { return nil }
                return String(line[range])
            }
            
            if let ip = extract(1),
               let tsStr = extract(2),
               let method = extract(3),
               let url = extract(4),
               let statusStr = extract(5),
               let status = Int(statusStr) {
                
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MMM/yyyy:HH:mm:ss Z"
                let timestamp = formatter.date(from: tsStr) ?? Date()
                
                entries.append(AXLogEntryDisplay(
                    id: UUID(),
                    type: .access,
                    timestamp: timestamp,
                    ip: ip,
                    method: method,
                    statusCode: status,
                    urlOrMessage: url,
                    userAgent: extract(8),
                    referer: extract(7),
                    responseTime: nil,
                    level: nil,
                    file: nil,
                    line: nil
                ))
            }
        }
        return entries
    }
    
    private func parseErrorLevelLogs(_ raw: String) -> [AXLogEntryDisplay] {
        let lines = raw.components(separatedBy: .newlines)
        var entries: [AXLogEntryDisplay] = []
        
        let pattern = #"^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[(\w+)\] (.+)$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        
        for line in lines {
            guard !line.isEmpty, let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else { continue }
            
            func extract(_ index: Int) -> String? {
                guard let range = Range(match.range(at: index), in: line) else { return nil }
                return String(line[range])
            }
            
            if let tsStr = extract(1), let level = extract(2), let msg = extract(3) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                let timestamp = formatter.date(from: tsStr) ?? Date()
                
                entries.append(AXLogEntryDisplay(
                    id: UUID(),
                    type: .error,
                    timestamp: timestamp,
                    ip: nil,
                    method: nil,
                    statusCode: nil,
                    urlOrMessage: msg,
                    userAgent: nil,
                    referer: nil,
                    responseTime: nil,
                    level: level,
                    file: nil,
                    line: nil
                ))
            }
        }
        return entries
    }
    
    private func parsePHPErrorLogs(_ raw: String) -> [AXLogEntryDisplay] {
        let lines = raw.components(separatedBy: .newlines)
        var entries: [AXLogEntryDisplay] = []
        
        // PHP-FPM error log format: [DD-MMM-YYYY HH:MM:SS] LEVEL: message
        let pattern = #"^\[(\d{2}-[A-Za-z]{3}-\d{4} \d{2}:\d{2}:\d{2})\] ([A-Z]+): (.+)$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        
        for line in lines {
            guard !line.isEmpty else { continue }
            
            // Try PHP-FPM format first
            if let match = regex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                func extract(_ index: Int) -> String? {
                    guard let range = Range(match.range(at: index), in: line) else { return nil }
                    return String(line[range])
                }
                
                if let tsStr = extract(1), let level = extract(2), let msg = extract(3) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
                    let timestamp = formatter.date(from: tsStr) ?? Date()
                    
                    entries.append(AXLogEntryDisplay(
                        id: UUID(),
                        type: .error,
                        timestamp: timestamp,
                        ip: nil,
                        method: nil,
                        statusCode: nil,
                        urlOrMessage: msg,
                        userAgent: nil,
                        referer: nil,
                        responseTime: nil,
                        level: level,
                        file: nil,
                        line: nil
                    ))
                }
            } else {
                // Fallback: treat as generic error line
                entries.append(AXLogEntryDisplay(
                    id: UUID(),
                    type: .error,
                    timestamp: Date(),
                    ip: nil,
                    method: nil,
                    statusCode: nil,
                    urlOrMessage: line,
                    userAgent: nil,
                    referer: nil,
                    responseTime: nil,
                    level: "ERROR",
                    file: nil,
                    line: nil
                ))
            }
        }
        return entries
    }
}
