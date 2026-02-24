
import SwiftUI
import AevonXCore

struct DockerLogsView: View {
    let container: DockerContainer
    let serverId: String
    @Binding var isPresented: Bool
    
    @State private var logs: String = ""
    @State private var isStreaming: Bool = false
    @State private var autoScroll: Bool = true
    @State private var task: Task<Void, Never>?
    
    // Smart features
    @State private var searchText: String = ""
    @State private var selectedLevel: LogLevel = .all
    @State private var tailCount: Int = 200
    @State private var wordWrap: Bool = true
    @State private var showSearch: Bool = false
    
    enum LogLevel: String, CaseIterable {
        case all = "All"
        case error = "ERROR"
        case warn = "WARN"
        case info = "INFO"
        case debug = "DEBUG"
        
        var color: Color {
            switch self {
            case .all: return .axTextPrimary
            case .error: return .red
            case .warn: return .orange
            case .info: return .blue
            case .debug: return .gray
            }
        }
    }
    
    private var filteredLines: [String] {
        let allLines = logs.components(separatedBy: .newlines)
        var result = allLines
        
        // Filter by level
        if selectedLevel != .all {
            result = result.filter { line in
                line.localizedCaseInsensitiveContains(selectedLevel.rawValue)
            }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { line in
                line.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    private var matchCount: Int {
        guard !searchText.isEmpty else { return 0 }
        return filteredLines.count
    }
    
    private var lineCount: Int {
        logs.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.axAccentBlue)
                        Text("Logs: \(container.names)")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                    HStack(spacing: 8) {
                        Text(container.shortId)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                            .monospaced()
                        
                        Text("\(lineCount) lines")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(8)
                        
                        if isStreaming {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.axSuccess)
                                    .frame(width: 5, height: 5)
                                Text("Live")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.axSuccess)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Toolbar buttons
                HStack(spacing: 6) {
                    toolbarButton(icon: "magnifyingglass", active: showSearch) {
                        showSearch.toggle()
                    }
                    toolbarButton(icon: "text.word.spacing", active: wordWrap) {
                        wordWrap.toggle()
                    }
                    toolbarButton(icon: "arrow.down.to.line", active: autoScroll) {
                        autoScroll.toggle()
                    }
                    toolbarButton(icon: "trash", active: false) {
                        logs = ""
                    }
                }
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            
            // Search + Filter bar
            if showSearch {
                searchFilterBar
            }
            
            Divider()
            
            // Logs Content
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView([.vertical, wordWrap ? [] : .horizontal]) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(filteredLines.enumerated()), id: \.offset) { index, line in
                                logLine(line, index: index)
                            }
                        }
                        .padding(AXSpacing.sm)
                        .id("LogsBottom")
                    }
                    .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                    .onChange(of: logs) { _, _ in
                        if autoScroll {
                            proxy.scrollTo("LogsBottom", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Footer
            HStack {
                // Tail count
                HStack(spacing: 4) {
                    Text("Tail:")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                    Picker("", selection: $tailCount) {
                        Text("100").tag(100)
                        Text("200").tag(200)
                        Text("500").tag(500)
                        Text("1000").tag(1000)
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.mini)
                    .frame(width: 200)
                    .onChange(of: tailCount) { _, _ in
                        restartStream()
                    }
                }
                
                Spacer()
                
                if !searchText.isEmpty {
                    Text("\(matchCount) matches")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.axAccentBlue)
                }
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface)
        }
        .frame(width: 900, height: 650)
        .background(Color.axBackground)
        .onAppear { startStreaming() }
        .onDisappear { stopStreaming() }
    }
    
    // MARK: - Search & Filter Bar
    
    private var searchFilterBar: some View {
        HStack(spacing: AXSpacing.sm) {
            // Search
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color.axSurface)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.axBorder, lineWidth: 1))
            
            // Level filter pills
            HStack(spacing: 4) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    Button(action: { selectedLevel = level }) {
                        Text(level.rawValue)
                            .font(.system(size: 9, weight: selectedLevel == level ? .bold : .medium))
                            .foregroundColor(selectedLevel == level ? level.color : .axTextMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedLevel == level ? level.color.opacity(0.12) : Color.clear)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axSurface.opacity(0.7))
    }
    
    // MARK: - Log Line
    
    private func logLine(_ line: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Line number
            Text("\(index + 1)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.axTextMuted.opacity(0.4))
                .frame(width: 30, alignment: .trailing)
            
            // Content
            if !searchText.isEmpty, let range = line.range(of: searchText, options: .caseInsensitive) {
                // Highlight search term
                (Text(line[line.startIndex..<range.lowerBound])
                    .foregroundColor(lineColor(for: line)) +
                 Text(line[range])
                    .foregroundColor(.black)
                    .bold() +
                 Text(line[range.upperBound..<line.endIndex])
                    .foregroundColor(lineColor(for: line)))
                    .font(.system(size: 11, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(line)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(lineColor(for: line))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 1)
        .background(index % 2 == 0 ? Color.white.opacity(0.02) : Color.clear)
    }
    
    private func lineColor(for line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error") || lower.contains("fatal") || lower.contains("panic") { return .red }
        if lower.contains("warn") { return .orange }
        if lower.contains("debug") { return Color(white: 0.5) }
        return Color(white: 0.85)
    }
    
    // MARK: - Toolbar Button
    
    private func toolbarButton(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(active ? .axAccentBlue : .axTextSecondary)
                .padding(5)
                .background(active ? Color.axAccentBlue.opacity(0.12) : Color.axSurface)
                .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Streaming
    
    private func startStreaming() {
        isStreaming = true
        logs = ""
        
        task = Task {
            do {
                try await DockerManager.shared.getContainerLogs(
                    id: container.id,
                    tail: tailCount,
                    follow: true,
                    serverId: serverId
                ) { chunk in
                    Task { @MainActor in
                        logs += chunk
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        logs += "\n[Error] Stream disconnected: \(error.localizedDescription)"
                    }
                }
            }
            isStreaming = false
        }
    }
    
    private func stopStreaming() {
        task?.cancel()
        task = nil
        isStreaming = false
    }
    
    private func restartStream() {
        stopStreaming()
        startStreaming()
    }
}
