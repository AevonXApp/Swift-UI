
import SwiftUI
import AevonXCoreBridge

struct DockerAggregatedLogsView: View {
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var containers: [DockerContainer] = []
    @State private var selectedContainerIds: Set<String> = []
    @State private var logEntries: [AggregatedLogEntry] = []
    @State private var isLoading = false
    @State private var filterText = ""
    @State private var tailCount = 50
    
    var filteredEntries: [AggregatedLogEntry] {
        if filterText.isEmpty { return logEntries }
        return logEntries.filter {
            $0.message.localizedCaseInsensitiveContains(filterText) ||
            $0.containerName.localizedCaseInsensitiveContains(filterText)
        }
    }
    
    // Assign color per container
    private let containerColors: [Color] = [.axAccentBlue, .axSuccess, .purple, .orange, .cyan, .pink, .mint, .indigo]
    
    private func colorForContainer(_ name: String) -> Color {
        let names = Array(Set(logEntries.map { $0.containerName })).sorted()
        let idx = names.firstIndex(of: name) ?? 0
        return containerColors[idx % containerColors.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Aggregated Logs", systemImage: "text.line.first.and.arrowtriangle.forward")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.axSurface)
            
            Divider()
            
            HStack(spacing: 0) {
                // Container selector sidebar
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Docker.containers)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.bottom, 4)
                    
                    ForEach(containers.filter { $0.isRunning }) { container in
                        Button {
                            if selectedContainerIds.contains(container.id) {
                                selectedContainerIds.remove(container.id)
                            } else {
                                selectedContainerIds.insert(container.id)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedContainerIds.contains(container.id) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selectedContainerIds.contains(container.id) ? .axAccentBlue : .axTextMuted)
                                Text(container.names)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextPrimary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    Button {
                        fetchLogs()
                    } label: {
                        Label("Fetch Logs", systemImage: "arrow.clockwise")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                    .background(selectedContainerIds.isEmpty ? Color.axSurface : Color.axAccentBlue)
                    .foregroundColor(selectedContainerIds.isEmpty ? .axTextMuted : .white)
                    .cornerRadius(AXCornerRadius.sm)
                    .disabled(selectedContainerIds.isEmpty)
                }
                .frame(width: 180)
                .padding()
                .background(Color.axSurface.opacity(0.5))
                
                Divider()
                
                // Logs view
                VStack(spacing: 0) {
                    // Filter bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.axTextMuted)
                        TextField("Filter logs...", text: $filterText)
                            .textFieldStyle(.plain)
                            .font(AXTypography.caption)
                        
                        Text("\(filteredEntries.count) entries")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface)
                    
                    Divider()
                    
                    if isLoading {
                        Spacer()
                        ProgressView("Fetching logs...")
                        Spacer()
                    } else if logEntries.isEmpty {
                        Spacer()
                        VStack(spacing: AXSpacing.sm) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 32))
                                .foregroundColor(.axTextMuted)
                            Text(L10n.Docker.selectContainersAndFetchLogs)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 1) {
                                ForEach(filteredEntries) { entry in
                                    HStack(alignment: .top, spacing: 6) {
                                        Circle()
                                            .fill(colorForContainer(entry.containerName))
                                            .frame(width: 8, height: 8)
                                            .padding(.top, 4)
                                        
                                        Text(entry.containerName)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(colorForContainer(entry.containerName))
                                            .frame(width: 120, alignment: .leading)
                                        
                                        Text(entry.message)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.axTextPrimary)
                                            .lineLimit(3)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.axBackground)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color.axBackground)
        .onAppear { loadContainers() }
    }
    
    private func loadContainers() {
        Task {
            let c = try? await DockerService.shared.getContainers(serverId: serverId, all: false)
            await MainActor.run { containers = c ?? [] }
        }
    }
    
    private func fetchLogs() {
        isLoading = true
        Task {
            do {
                let entries = try await DockerService.shared.getAggregatedLogs(
                    containerIds: Array(selectedContainerIds),
                    tail: tailCount,
                    serverId: serverId
                )
                await MainActor.run {
                    logEntries = entries
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}
