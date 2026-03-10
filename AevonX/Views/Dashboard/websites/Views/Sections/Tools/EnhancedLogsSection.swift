//
//  EnhancedLogsSection.swift
//  AevonX
//
//  Log viewer with parsed table, AI analysis sheet, block IP, clear confirmation.
//  Models/parsers in EnhancedLogModels.swift, AI sheet in AIAnalysisSheet.swift.
//

import SwiftUI
import AevonXCoreBridge

struct EnhancedLogsSection: View {
    @ObservedObject var viewModel: EnhancedLogsViewModel
    @State private var levelFilter: LogLevelFilter = .all
    @State private var searchText = ""
    @State private var expandedRow: Int? = nil
    @State private var showAnalysisSheet = false
    @State private var showClearConfirmation = false
    @State private var ipToBlock: String? = nil

    enum LogLevelFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case errors = "Errors"
        case warnings = "Warnings"
        case info = "Info"
        var id: String { rawValue }

        var color: Color {
            switch self {
            case .all: return .axTextSecondary
            case .errors: return .red
            case .warnings: return .orange
            case .info: return .green
            }
        }

        func matches(_ line: String) -> Bool {
            let lower = line.lowercased()
            switch self {
            case .all: return true
            case .errors: return lower.contains("[error]") || lower.contains("[crit]") || lower.contains("[emerg]") || lower.contains("fatal") || lower.contains(" 500 ") || lower.contains(" 502 ") || lower.contains(" 503 ")
            case .warnings: return lower.contains("[warn") || lower.contains("[notice]") || lower.contains(" 404 ") || lower.contains(" 403 ") || lower.contains(" 401 ")
            case .info: return lower.contains(" 200 ") || lower.contains(" 301 ") || lower.contains(" 302 ") || lower.contains(" 304 ") || lower.contains("[info]")
            }
        }
    }

    private var filteredLines: [IndexedLogLine] {
        var lines = viewModel.logLines.enumerated().map { IndexedLogLine(index: $0.offset, content: $0.element) }
        if levelFilter != .all {
            lines = lines.filter { levelFilter.matches($0.content) }
        }
        if !searchText.isEmpty {
            lines = lines.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
        return lines
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.lg)
                .background(Color.axSurface.opacity(0.3))

            Divider().background(Color.axBorder.opacity(0.3))

            filterBar
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.md)
                .background(Color.axSurface.opacity(0.15))

            Divider().background(Color.axBorder.opacity(0.3))

            logTable

            Divider().background(Color.axBorder.opacity(0.3))

            statusBar
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, 6)
                .background(Color.axSurface.opacity(0.15))
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.discoverLogs() } }
        .sheet(isPresented: $showAnalysisSheet) {
            AIAnalysisSheet(viewModel: viewModel)
                .frame(minWidth: 620, minHeight: 520)
        }
        .alert("Clear Log", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task { await viewModel.clearLog() }
            }
        } message: {
            Text("Are you sure you want to clear this log file? This action cannot be undone.")
        }
        .alert("Block IP", isPresented: Binding(
            get: { ipToBlock != nil },
            set: { if !$0 { ipToBlock = nil } }
        )) {
            Button("Cancel", role: .cancel) { ipToBlock = nil }
            Button("Block", role: .destructive) {
                if let ip = ipToBlock {
                    Task { await viewModel.blockIP(ip) }
                    ipToBlock = nil
                }
            }
        } message: {
            Text("Block IP address \(ipToBlock ?? "") from accessing the server? This will add a UFW deny rule.")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: AXSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Logs")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Text("Log viewer, search & filtering")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()

            if !viewModel.logFiles.isEmpty {
                Picker("Log File", selection: Binding(
                    get: { viewModel.selectedLog ?? viewModel.logFiles.first! },
                    set: { viewModel.selectedLog = $0; Task { await viewModel.loadLogLines() } }
                )) {
                    ForEach(viewModel.logFiles) { log in
                        HStack {
                            Image(systemName: log.type == "error" ? "exclamationmark.triangle" : "doc.text")
                            Text("\(log.filename) (\(log.size))")
                        }.tag(log)
                    }
                }
                .frame(maxWidth: 260)
            }

            Button(action: { Task { await viewModel.loadLogLines() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(action: {
                showAnalysisSheet = true
                Task { await viewModel.runSmartAnalysis() }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "brain")
                    Text("AI Analysis")
                }
                .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button(action: { showClearConfirmation = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.small)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: AXSpacing.md) {
            HStack(spacing: 4) {
                ForEach(LogLevelFilter.allCases) { level in
                    filterPill(level)
                }
            }

            Divider().frame(height: 20)

            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextMuted)
                TextField("Filter logs...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.axSurface)
            .cornerRadius(6)
            .frame(maxWidth: 280)

            Spacer()

            Picker("Lines", selection: $viewModel.lineCount) {
                Text("50").tag(50)
                Text("100").tag(100)
                Text("200").tag(200)
                Text("500").tag(500)
            }
            .frame(width: 100)
        }
    }

    private func filterPill(_ level: LogLevelFilter) -> some View {
        let count: Int = {
            if level == .all { return viewModel.logLines.count }
            return viewModel.logLines.filter { level.matches($0) }.count
        }()

        return Button(action: { withAnimation(.easeInOut(duration: 0.15)) { levelFilter = level } }) {
            HStack(spacing: 3) {
                Text(level.rawValue)
                    .font(.system(size: 10, weight: levelFilter == level ? .bold : .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(level.color.opacity(levelFilter == level ? 0.3 : 0.1))
                        .cornerRadius(3)
                }
            }
            .foregroundColor(levelFilter == level ? level.color : .axTextMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(levelFilter == level ? level.color.opacity(0.1) : Color.axSurface.opacity(0.5))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(levelFilter == level ? level.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Log Table

    private var logTable: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 35, alignment: .center)
                Text("LEVEL")
                    .frame(width: 55, alignment: .center)
                    .overlay(alignment: .leading) { Color.axBorder.opacity(0.15).frame(width: 1) }
                Text("TIME")
                    .frame(width: 120, alignment: .leading)
                    .padding(.leading, 8)
                    .overlay(alignment: .leading) { Color.axBorder.opacity(0.15).frame(width: 1) }
                Text("STATUS")
                    .frame(width: 50, alignment: .center)
                    .overlay(alignment: .leading) { Color.axBorder.opacity(0.15).frame(width: 1) }
                Text("METHOD")
                    .frame(width: 55, alignment: .center)
                    .overlay(alignment: .leading) { Color.axBorder.opacity(0.15).frame(width: 1) }
                Text("URL / MESSAGE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                    .overlay(alignment: .leading) { Color.axBorder.opacity(0.15).frame(width: 1) }
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.axTextMuted)
            .textCase(.uppercase)
            .padding(.vertical, 6)
            .background(Color.axSurface.opacity(0.4))

            Divider().background(Color.axBorder.opacity(0.3))

            // Table body
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isLoading {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("Loading logs...").font(.system(size: 12)).foregroundColor(.axTextMuted)
                        }
                        .padding(AXSpacing.xl).frame(maxWidth: .infinity)
                    } else if filteredLines.isEmpty {
                        VStack(spacing: AXSpacing.md) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 28)).foregroundColor(.axTextMuted.opacity(0.4))
                            Text(viewModel.logLines.isEmpty ? "No log entries found" : "No entries match filter")
                                .font(.system(size: 13)).foregroundColor(.axTextMuted)
                        }
                        .padding(AXSpacing.xl).frame(maxWidth: .infinity)
                    } else {
                        ForEach(filteredLines) { line in
                            tableRow(line)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Table Row

    private func tableRow(_ line: IndexedLogLine) -> some View {
        let parsed = EnhancedLogParser.parse(line.content)
        let isEven = line.index % 2 == 0
        let isExpanded = expandedRow == line.index

        return VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    expandedRow = expandedRow == line.index ? nil : line.index
                }
            }) {
                HStack(alignment: .center, spacing: 0) {
                    Text("\(line.index + 1)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextMuted.opacity(0.5))
                        .frame(width: 35, alignment: .center)

                    levelBadge(parsed.level)
                        .frame(width: 55, alignment: .center)
                        .overlay(alignment: .leading) { Color.axBorder.opacity(0.06).frame(width: 1) }

                    Text(parsed.timestamp)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 120, alignment: .leading)
                        .padding(.leading, 8)
                        .overlay(alignment: .leading) { Color.axBorder.opacity(0.06).frame(width: 1) }

                    statusBadge(parsed.statusCode)
                        .frame(width: 50, alignment: .center)
                        .overlay(alignment: .leading) { Color.axBorder.opacity(0.06).frame(width: 1) }

                    Text(parsed.method.isEmpty ? "—" : parsed.method)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(EnhancedLogParser.methodColor(parsed.method))
                        .frame(width: 55, alignment: .center)
                        .overlay(alignment: .leading) { Color.axBorder.opacity(0.06).frame(width: 1) }

                    Text(parsed.url.isEmpty ? parsed.message : parsed.url)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                        .overlay(alignment: .leading) { Color.axBorder.opacity(0.06).frame(width: 1) }

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.axTextMuted.opacity(0.4))
                        .frame(width: 18)
                }
                .padding(.vertical, 4)
                .background(isExpanded ? Color.axAccentBlue.opacity(0.05) :
                           isEven ? Color.clear : Color.axSurface.opacity(0.06))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                rowDetails(parsed)
            }

            Divider().background(Color.axBorder.opacity(0.06))
        }
    }

    // MARK: - Row Details

    private func rowDetails(_ parsed: ParsedLogLine) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xl) {
                detailField("IP Address", parsed.ip)
                detailField("Status", parsed.statusCode)
                detailField("Method", parsed.method)
                detailField("Size", parsed.size)

                Spacer()

                if !parsed.ip.isEmpty {
                    Button(action: { ipToBlock = parsed.ip }) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised.fill")
                            Text("Block IP")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !parsed.url.isEmpty { detailField("URL", parsed.url) }
            if !parsed.userAgent.isEmpty { detailField("User Agent", parsed.userAgent) }

            VStack(alignment: .leading, spacing: 2) {
                Text("RAW")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.axTextMuted)
                Text(parsed.raw)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
                    .textSelection(.enabled)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.md)
        .padding(.leading, 35)
        .background(Color.axAccentBlue.opacity(0.03))
        .overlay(alignment: .leading) {
            Color.axAccentBlue.opacity(0.3).frame(width: 2)
        }
    }

    private func detailField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.axTextMuted)
                .textCase(.uppercase)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .textSelection(.enabled)
        }
    }

    // MARK: - Badges

    private func levelBadge(_ level: String) -> some View {
        Text(level.uppercased())
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(EnhancedLogParser.levelColor(level))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(EnhancedLogParser.levelColor(level).opacity(0.12))
            .cornerRadius(3)
    }

    private func statusBadge(_ code: String) -> some View {
        Text(code.isEmpty ? "—" : code)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(code.isEmpty ? .axTextMuted : EnhancedLogParser.statusColor(code))
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: AXSpacing.md) {
            Text("\(filteredLines.count) of \(viewModel.logLines.count) entries")
                .font(.system(size: 10)).foregroundColor(.axTextMuted)

            if levelFilter != .all {
                HStack(spacing: 2) {
                    Circle().fill(levelFilter.color).frame(width: 5, height: 5)
                    Text(levelFilter.rawValue).font(.system(size: 10, weight: .medium)).foregroundColor(levelFilter.color)
                }
            }

            if !searchText.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "magnifyingglass").font(.system(size: 8))
                    Text("\"\(searchText)\"").font(.system(size: 10))
                }.foregroundColor(.axAccentBlue)
            }

            Spacer()

            if let log = viewModel.selectedLog {
                Text(log.filename).font(.system(size: 10, design: .monospaced)).foregroundColor(.axTextMuted)
            }
        }
    }
}
