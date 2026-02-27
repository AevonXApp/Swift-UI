//
//  EnhancedLogsSection.swift
//  AevonX
//
//  Log viewer with table, AI analysis sheet, block IP, clear confirmation
//

import SwiftUI
import AevonXCore

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
            // thead
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

            // tbody
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
        let parsed = parseLine(line.content)
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
                        .foregroundColor(parsed.method == "GET" ? .axAccentBlue :
                                        parsed.method == "POST" ? .green :
                                        parsed.method == "DELETE" ? .red : .axTextMuted)
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

                // Block IP button
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

            if !parsed.url.isEmpty {
                detailField("URL", parsed.url)
            }

            if !parsed.userAgent.isEmpty {
                detailField("User Agent", parsed.userAgent)
            }

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
        let color: Color = {
            switch level {
            case "error", "fatal", "crit": return .red
            case "warn", "notice": return .orange
            case "info": return .green
            default: return .axTextMuted
            }
        }()
        return Text(level.uppercased())
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(3)
    }

    private func statusBadge(_ code: String) -> some View {
        let color: Color = {
            guard let num = Int(code) else { return .axTextMuted }
            switch num {
            case 200..<300: return .green
            case 300..<400: return .blue
            case 400..<500: return .orange
            case 500..<600: return .red
            default: return .axTextMuted
            }
        }()
        return Text(code.isEmpty ? "—" : code)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(code.isEmpty ? .axTextMuted : color)
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

    // MARK: - Parser

    private func parseLine(_ raw: String) -> ParsedLogLine {
        var timestamp = ""
        var level = "info"
        var ip = ""
        var method = ""
        var url = ""
        var statusCode = ""
        var size = ""
        var userAgent = ""

        let parts = raw.split(separator: " ", maxSplits: 1)
        if let first = parts.first {
            let candidate = String(first)
            if candidate.contains(".") || candidate.contains(":") { ip = candidate }
        }

        if let bracketMatch = raw.range(of: "\\[([^\\]]+)\\]", options: .regularExpression) {
            let rawTS = String(raw[bracketMatch]).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            timestamp = formatTimestamp(rawTS)
        }

        if let reqMatch = raw.range(of: "\"(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS) ([^ ]+) HTTP[^\"]*\"", options: .regularExpression) {
            let reqStr = String(raw[reqMatch]).replacingOccurrences(of: "\"", with: "")
            let reqParts = reqStr.split(separator: " ")
            if reqParts.count >= 2 { method = String(reqParts[0]); url = String(reqParts[1]) }
        }

        let statusPattern = try? NSRegularExpression(pattern: "\" (\\d{3}) (\\d+)", options: [])
        if let match = statusPattern?.firstMatch(in: raw, options: [], range: NSRange(raw.startIndex..., in: raw)) {
            if let r1 = Range(match.range(at: 1), in: raw) { statusCode = String(raw[r1]) }
            if let r2 = Range(match.range(at: 2), in: raw) {
                if let bytes = Int(raw[r2]) { size = formatBytes(bytes) }
            }
        }

        let uaPattern = try? NSRegularExpression(pattern: "\"([^\"]{15,})\"\\s*$", options: [])
        if let match = uaPattern?.firstMatch(in: raw, options: [], range: NSRange(raw.startIndex..., in: raw)),
           let r = Range(match.range(at: 1), in: raw) { userAgent = String(raw[r]) }

        if let code = Int(statusCode) {
            switch code {
            case 500...599: level = "error"
            case 400...499: level = "warn"
            case 200...399: level = "info"
            default: break
            }
        }

        let lower = raw.lowercased()
        if lower.contains("[error]") || lower.contains("[crit]") || lower.contains("[emerg]") { level = "error" }
        else if lower.contains("[warn") || lower.contains("[notice]") { level = "warn" }

        return ParsedLogLine(
            timestamp: timestamp.isEmpty ? "—" : timestamp,
            level: level, ip: ip, method: method, url: url,
            statusCode: statusCode, size: size, userAgent: userAgent,
            message: raw, raw: raw
        )
    }

    private func formatTimestamp(_ raw: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MMM/yyyy:HH:mm:ss Z"
        if let date = formatter.date(from: raw) {
            let out = DateFormatter(); out.dateFormat = "yyyy-MM-dd HH:mm"
            return out.string(from: date)
        }
        formatter.dateFormat = "dd/MMM/yyyy:HH:mm:ss"
        if let date = formatter.date(from: raw) {
            let out = DateFormatter(); out.dateFormat = "yyyy-MM-dd HH:mm"
            return out.string(from: date)
        }
        if raw.count > 16 { return String(raw.prefix(16)) }
        return raw
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1048576 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / 1048576)
    }
}

// MARK: - AI Analysis Sheet

struct AIAnalysisSheet: View {
    @ObservedObject var viewModel: EnhancedLogsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            // Sheet header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                        .font(.system(size: 18))
                        .foregroundColor(.axAccentBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Log Analysis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.axTextPrimary)
                        Text(viewModel.domain)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextMuted)
                    }
                }

                Spacer()

                if let analysis = viewModel.aiAnalysis {
                    Button(action: copyReport) {
                        HStack(spacing: 4) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy Report")
                        }
                        .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(copied ? .green : .axAccentBlue)
                }

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface.opacity(0.4))

            Divider().background(Color.axBorder.opacity(0.3))

            // Content
            if viewModel.isAnalyzing {
                Spacer()
                VStack(spacing: AXSpacing.lg) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analyzing log patterns...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.axTextSecondary)
                    Text("\(viewModel.logLines.count) log entries")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                }
                Spacer()
            } else if let analysis = viewModel.aiAnalysis {
                ScrollView {
                    VStack(spacing: AXSpacing.lg) {
                        // Health score card
                        healthCard(analysis)

                        // Stats grid
                        statsGrid(analysis)

                        // HTTP Status Distribution
                        if !analysis.statusDistribution.isEmpty {
                            statusSection(analysis.statusDistribution)
                        }

                        // Insights
                        if !analysis.insights.isEmpty {
                            insightsSection(analysis.insights)
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            } else {
                Spacer()
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 32))
                        .foregroundColor(.axTextMuted.opacity(0.4))
                    Text("No analysis data")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextMuted)
                    Button("Run Analysis") {
                        Task { await viewModel.runSmartAnalysis() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
        }
        .background(Color.axBackground)
    }

    // MARK: - Health Card

    private func healthCard(_ analysis: LogAIAnalysis) -> some View {
        HStack(spacing: AXSpacing.lg) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.axBorder.opacity(0.2), lineWidth: 6)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: Double(analysis.healthScore) / 100)
                    .stroke(
                        analysis.healthScore >= 80 ? Color.green :
                        analysis.healthScore >= 50 ? Color.orange : Color.red,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(analysis.healthScore)")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                    Text("%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axTextMuted)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Health Score")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Text("Based on \(analysis.totalRequests) requests — \(analysis.errorCount) errors, \(analysis.warningCount) warnings")
                    .font(.system(size: 11))
                    .foregroundColor(.axTextTertiary)
            }

            Spacer()
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Stats Grid

    private func statsGrid(_ analysis: LogAIAnalysis) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
        ], spacing: AXSpacing.md) {
            statCard(icon: "doc.text.fill", value: "\(analysis.totalRequests)", label: "Requests", color: .axAccentBlue)
            statCard(icon: "person.2.fill", value: "\(analysis.uniqueIPs)", label: "Unique IPs", color: .purple)
            statCard(icon: "xmark.circle.fill", value: "\(analysis.errorCount)", label: "Errors", color: .red)
            statCard(icon: "exclamationmark.triangle.fill", value: "\(analysis.warningCount)", label: "Warnings", color: .orange)
            statCard(icon: "ant.fill", value: "\(analysis.botCount)", label: "Bots", color: .axTextMuted)
            statCard(icon: "checkmark.shield.fill", value: "\(analysis.healthScore)%", label: "Health", color: analysis.healthScore >= 80 ? .green : .orange)
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.axTextPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.md)
        .background(color.opacity(0.05))
        .cornerRadius(AXCornerRadius.sm)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(color.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Status Distribution

    private func statusSection(_ stats: [LogStatusStat]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("HTTP Status Distribution")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.axTextPrimary)

            HStack(spacing: AXSpacing.sm) {
                ForEach(stats) { stat in
                    VStack(spacing: 4) {
                        Text("\(stat.count)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(stat.color)
                        Text(stat.code)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                        Text(statusLabel(stat.code))
                            .font(.system(size: 9))
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.sm)
                    .background(stat.color.opacity(0.06))
                    .cornerRadius(AXCornerRadius.sm)
                }
            }
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.2))
        .cornerRadius(AXCornerRadius.md)
    }

    private func statusLabel(_ code: String) -> String {
        switch code {
        case "200": return "OK"
        case "301": return "Redirect"
        case "302": return "Found"
        case "304": return "Not Modified"
        case "400": return "Bad Request"
        case "401": return "Unauthorized"
        case "403": return "Forbidden"
        case "404": return "Not Found"
        case "500": return "Server Error"
        case "502": return "Bad Gateway"
        case "503": return "Unavailable"
        default: return ""
        }
    }

    // MARK: - Insights

    private func insightsSection(_ insights: [LogInsight]) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text("Insights")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.axTextPrimary)

            ForEach(insights) { insight in
                HStack(spacing: AXSpacing.md) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 16))
                        .foregroundColor(insight.level.color)
                        .frame(width: 30, height: 30)
                        .background(insight.level.color.opacity(0.1))
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.axTextPrimary)
                        Text(insight.detail)
                            .font(.system(size: 11))
                            .foregroundColor(.axTextTertiary)
                    }

                    Spacer()
                }
                .padding(AXSpacing.sm)
                .background(insight.level.color.opacity(0.03))
                .cornerRadius(AXCornerRadius.sm)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(insight.level.color.opacity(0.1), lineWidth: 1))
            }
        }
    }

    private func copyReport() {
        let report = viewModel.generateReport()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
    }
}

// MARK: - Models

struct IndexedLogLine: Identifiable {
    var id: Int { index }
    let index: Int
    let content: String
}

struct ParsedLogLine {
    let timestamp: String
    let level: String
    let ip: String
    let method: String
    let url: String
    let statusCode: String
    let size: String
    let userAgent: String
    let message: String
    let raw: String
}
