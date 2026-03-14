
import SwiftUI
import AevonXCoreBridge

// MARK: - Docker Logs Tab (Table-based, like AXAdvancedLogsView)

struct DockerLogsTab: View {
    let serverId: String
    
    @State private var containers: [DockerContainer] = []
    @State private var selectedContainerIds: Set<String> = []
    @State private var logEntries: [AggregatedLogEntry] = []
    @State private var isLoading = false
    @State private var isFetching = false
    @State private var searchText = ""
    @State private var selectedLevel: LogLevelFilter = .all
    @State private var sortNewestFirst = true
    @State private var selectedEntry: AggregatedLogEntry?
    @State private var tailLines = 200
    
    enum LogLevelFilter: String, CaseIterable {
        case all = "All"
        case error = "Error"
        case warn = "Warning"
        case info = "Info"
        case debug = "Debug"
        
        var color: Color {
            switch self {
            case .all: return .axTextPrimary
            case .error: return .axError
            case .warn: return .axWarning
            case .info: return .axAccentBlue
            case .debug: return .axTextTertiary
            }
        }
    }
    
    private var filteredEntries: [AggregatedLogEntry] {
        var result = logEntries
        
        // Filter by selected containers
        if !selectedContainerIds.isEmpty {
            result = result.filter { selectedContainerIds.contains($0.containerName) }
        }
        
        // Filter by level
        if selectedLevel != .all {
            result = result.filter { entry in
                let upper = entry.message.uppercased()
                switch selectedLevel {
                case .error: return upper.contains("ERROR") || upper.contains("FATAL") || upper.contains("CRITICAL")
                case .warn: return upper.contains("WARN")
                case .info: return upper.contains("INFO")
                case .debug: return upper.contains("DEBUG")
                case .all: return true
                }
            }
        }
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { $0.message.localizedCaseInsensitiveContains(searchText) || $0.containerName.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Sort
        if sortNewestFirst {
            result = result.reversed()
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: Controls Header
            controlsHeader
            
            Divider().background(Color.axBorder.opacity(0.3))
            
            // MARK: Content
            if isLoading {
                loadingState
            } else if logEntries.isEmpty && !isFetching {
                emptyState
            } else {
                logsTable
            }
        }
        .background(Color.axBackground)
        .onAppear { loadContainers() }
        .sheet(item: $selectedEntry) { entry in
            logDetailSheet(entry)
        }
    }
    
    // MARK: - Controls Header
    
    private var controlsHeader: some View {
        VStack(spacing: AXSpacing.md) {
            // Row 1: Container pills + actions
            HStack(spacing: AXSpacing.sm) {
                // Container filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        // "All" pill
                        Button {
                            selectedContainerIds.removeAll()
                        } label: {
                            Text("All Containers")
                                .font(.system(size: 11, weight: selectedContainerIds.isEmpty ? .bold : .medium))
                                .foregroundColor(selectedContainerIds.isEmpty ? .axAccentBlue : .axTextSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(selectedContainerIds.isEmpty ? Color.axAccentBlue.opacity(0.12) : Color.axSurface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedContainerIds.isEmpty ? Color.axAccentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        ForEach(containers, id: \.id) { container in
                            let isSelected = selectedContainerIds.contains(container.names)
                            Button {
                                if isSelected {
                                    selectedContainerIds.remove(container.names)
                                } else {
                                    selectedContainerIds.insert(container.names)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(container.isRunning ? Color.axSuccess : Color.axTextMuted)
                                        .frame(width: 6, height: 6)
                                    Text(container.names)
                                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                }
                                .foregroundColor(isSelected ? .axAccentBlue : .axTextSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(isSelected ? Color.axAccentBlue.opacity(0.12) : Color.axSurface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? Color.axAccentBlue.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
                
                // Fetch button
                Button {
                    fetchLogs()
                } label: {
                    HStack(spacing: 6) {
                        if isFetching {
                            ProgressView().scaleEffect(0.5)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Text(isFetching ? "Fetching..." : "Fetch Logs")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(isFetching)
            }
            
            // Row 2: Search + Level filter + Sort + Count
            HStack(spacing: AXSpacing.sm) {
                // Search
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextTertiary)
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, 6)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .frame(width: 280)
                
                // Level filter pills
                HStack(spacing: 4) {
                    ForEach(LogLevelFilter.allCases, id: \.self) { level in
                        Button { selectedLevel = level } label: {
                            Text(level.rawValue)
                                .font(.system(size: 10, weight: selectedLevel == level ? .bold : .medium))
                                .foregroundColor(selectedLevel == level ? level.color : .axTextMuted)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedLevel == level ? level.color.opacity(0.12) : Color.clear)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Sort
                Button {
                    sortNewestFirst.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: sortNewestFirst ? "arrow.down" : "arrow.up")
                            .font(.system(size: 10))
                        Text(sortNewestFirst ? "Newest" : "Oldest")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                
                // Tail count
                Menu {
                    Button("100 lines") { tailLines = 100 }
                    Button("200 lines") { tailLines = 200 }
                    Button("500 lines") { tailLines = 500 }
                    Button("1000 lines") { tailLines = 1000 }
                } label: {
                    HStack(spacing: 4) {
                        Text("Tail: \(tailLines)")
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
                
                // Results count
                Text("\(filteredEntries.count) entries")
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
            LazyVStack(spacing: 0) {
                // Table header
                tableHeader
                
                Divider().background(Color.axBorder)
                
                // Table rows
                ForEach(Array(filteredEntries.enumerated()), id: \.offset) { index, entry in
                    DockerLogTableRow(entry: entry, isEven: index % 2 == 0) {
                        selectedEntry = entry
                    }
                    
                    if index < filteredEntries.count - 1 {
                        Divider().background(Color.axBorder.opacity(0.3))
                    }
                }
            }
        }
    }
    
    private var tableHeader: some View {
        HStack(spacing: AXSpacing.md) {
            Text("Container")
                .frame(width: 140, alignment: .leading)
            Text("Time")
                .frame(width: 160, alignment: .leading)
            Text("Level")
                .frame(width: 80, alignment: .leading)
            Text("Message")
                .frame(minWidth: 300, alignment: .leading)
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
            ProgressView().scaleEffect(1.2)
            Text("Loading containers...")
                .font(.system(size: 14))
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyState: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "text.line.first.and.arrowtriangle.forward")
                .font(.system(size: 50))
                .foregroundColor(.axTextTertiary.opacity(0.5))
            
            VStack(spacing: AXSpacing.xs) {
                Text("No Logs Yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text("Select containers above and click \"Fetch Logs\" to load aggregated logs")
                    .font(.system(size: 13))
                    .foregroundColor(.axTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Log Detail Sheet (simple/quick)
    
    private func logDetailSheet(_ entry: AggregatedLogEntry) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log Detail")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text(entry.containerName)
                        .font(.system(size: 12))
                        .foregroundColor(.axTextTertiary)
                }
                Spacer()
                Button { selectedEntry = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.xl)
            .background(Color.axSurface)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    detailRow("Container", entry.containerName)
                    detailRow("Timestamp", entry.timestamp)
                    detailRow("Level", detectLevel(entry.message))
                    
                    Text("Full Message")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.axTextPrimary)
                        .padding(.top, AXSpacing.sm)
                    
                    Text(entry.message)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                        .textSelection(.enabled)
                        .padding(AXSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .padding(AXSpacing.xl)
            }
        }
        .frame(width: 650, height: 400)
        .background(Color.axBackground)
    }
    
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.axTextSecondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.axTextPrimary)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Data Loading
    
    private func loadContainers() {
        isLoading = true
        Task {
            do {
                let c = try await DockerService.shared.getContainers(serverId: serverId, all: false)
                await MainActor.run {
                    containers = c
                    isLoading = false
                    // Auto-fetch logs for all containers
                    fetchLogs()
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func fetchLogs() {
        isFetching = true
        let ids = selectedContainerIds.isEmpty
            ? containers.map(\.id)
            : containers.filter { selectedContainerIds.contains($0.names) }.map(\.id)
        
        Task {
            do {
                let rawLogs = try await DockerService.shared.getAggregatedLogs(
                    containerIds: ids,
                    tail: tailLines,
                    serverId: serverId
                )
                await MainActor.run {
                    logEntries = rawLogs
                    isFetching = false
                }
            } catch {
                await MainActor.run { isFetching = false }
            }
        }
    }
    
    private func detectLevel(_ message: String) -> String {
        let upper = message.uppercased()
        if upper.contains("ERROR") || upper.contains("FATAL") || upper.contains("CRITICAL") { return "ERROR" }
        if upper.contains("WARN") { return "WARNING" }
        if upper.contains("INFO") { return "INFO" }
        if upper.contains("DEBUG") { return "DEBUG" }
        return "LOG"
    }
}

// MARK: - Docker Log Table Row

private struct DockerLogTableRow: View {
    let entry: AggregatedLogEntry
    let isEven: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                // Container
                HStack(spacing: 4) {
                    Circle()
                        .fill(containerColor)
                        .frame(width: 6, height: 6)
                    Text(entry.containerName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.axTextPrimary)
                        .lineLimit(1)
                }
                .frame(width: 140, alignment: .leading)
                
                // Time
                Text(entry.timestamp)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 160, alignment: .leading)
                
                // Level
                let level = detectLevel(entry.message)
                Text(level)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(levelColor(level))
                    .cornerRadius(6)
                    .frame(width: 80, alignment: .leading)
                
                // Message
                Text(entry.message)
                    .font(.system(size: 11))
                    .foregroundColor(messageColor(entry.message))
                    .lineLimit(1)
                    .frame(minWidth: 300, alignment: .leading)
                
                Spacer()
                
                // Expand icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextTertiary)
                    .opacity(isHovered ? 1 : 0)
            }
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, AXSpacing.sm)
            .background(isHovered ? Color.axAccentBlue.opacity(0.05) : (isEven ? Color.axBackground : Color.axSurface.opacity(0.3)))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
    
    private var containerColor: Color {
        let hash = abs(entry.containerName.hashValue)
        let colors: [Color] = [.axAccentBlue, .axSuccess, .purple, .orange, .cyan, .pink, .mint, .indigo]
        return colors[hash % colors.count]
    }
    
    private func detectLevel(_ message: String) -> String {
        let upper = message.uppercased()
        if upper.contains("ERROR") || upper.contains("FATAL") || upper.contains("CRITICAL") { return "ERROR" }
        if upper.contains("WARN") { return "WARNING" }
        if upper.contains("INFO") { return "INFO" }
        if upper.contains("DEBUG") { return "DEBUG" }
        return "LOG"
    }
    
    private func levelColor(_ level: String) -> Color {
        switch level {
        case "ERROR": return .axError
        case "WARNING": return .axWarning
        case "INFO": return .axAccentBlue
        case "DEBUG": return .axTextTertiary
        default: return .axTextMuted
        }
    }
    
    private func messageColor(_ message: String) -> Color {
        let upper = message.uppercased()
        if upper.contains("ERROR") || upper.contains("FATAL") || upper.contains("CRITICAL") { return .axError }
        if upper.contains("WARN") { return .axWarning }
        if upper.contains("HTTP") || upper.contains("GET ") || upper.contains("POST ") { return .axSuccess }
        return .axTextSecondary
    }
}
