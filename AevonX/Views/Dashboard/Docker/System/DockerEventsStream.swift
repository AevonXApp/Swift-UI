
import SwiftUI
import AevonXCoreBridge

struct DockerEventsStream: View {
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var events: [(time: String, type: String, action: String, actor: String)] = []
    @State private var isStreaming = false
    @State private var filterType: String = "all"
    @State private var task: Task<Void, Never>?
    
    private let eventTypes = ["all", "container", "image", "volume", "network"]
    
    private var filteredEvents: [(time: String, type: String, action: String, actor: String)] {
        if filterType == "all" { return events }
        return events.filter { $0.type == filterType }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("Docker Events")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    if isStreaming {
                        HStack(spacing: 3) {
                            Circle().fill(Color.axSuccess).frame(width: 5, height: 5)
                            Text("Live").font(.system(size: 9, weight: .bold)).foregroundColor(.axSuccess)
                        }
                    }
                }
                
                Spacer()
                
                // Type filter
                HStack(spacing: 4) {
                    ForEach(eventTypes, id: \.self) { type in
                        Button(action: { filterType = type }) {
                            Text(type.capitalized)
                                .font(.system(size: 9, weight: filterType == type ? .bold : .medium))
                                .foregroundColor(filterType == type ? eventColor(type) : .axTextMuted)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(filterType == type ? eventColor(type).opacity(0.1) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Button(action: { events.removeAll() }) {
                    Image(systemName: "trash").foregroundColor(.axTextSecondary).font(.system(size: 11))
                }
                .buttonStyle(.plain)
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            // Events list
            if filteredEvents.isEmpty {
                VStack(spacing: AXSpacing.md) {
                    Image(systemName: "bolt.circle")
                        .font(.system(size: 36))
                        .foregroundColor(.axTextMuted)
                    Text(isStreaming ? "Waiting for events..." : "Not connected")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredEvents.indices, id: \.self) { i in
                            let event = filteredEvents[i]
                            HStack(spacing: AXSpacing.sm) {
                                // Time
                                Text(event.time)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.axTextMuted)
                                    .frame(width: 65, alignment: .leading)
                                
                                // Type badge
                                Text(event.type)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(eventColor(event.type))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(eventColor(event.type).opacity(0.1))
                                    .cornerRadius(3)
                                    .frame(width: 70)
                                
                                // Action
                                Text(event.action)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(actionColor(event.action))
                                    .frame(width: 80, alignment: .leading)
                                
                                // Actor
                                Text(event.actor)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.axTextPrimary)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, AXSpacing.sm)
                            .background(i % 2 == 0 ? Color.axSurface.opacity(0.3) : Color.clear)
                        }
                    }
                    .padding(AXSpacing.sm)
                }
            }
            
            // Status bar
            HStack {
                Text("\(filteredEvents.count) events")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(Color.axSurface)
        }
        .frame(width: 700, height: 450)
        .background(Color.axBackground)
        .onAppear { startStream() }
        .onDisappear { stopStream() }
    }
    
    // MARK: - Helpers
    
    private func eventColor(_ type: String) -> Color {
        switch type {
        case "container": return .axAccentBlue
        case "image": return .purple
        case "volume": return .orange
        case "network": return .green
        default: return .axTextPrimary
        }
    }
    
    private func actionColor(_ action: String) -> Color {
        switch action {
        case "start", "create": return .green
        case "stop", "kill", "die": return .red
        case "restart": return .orange
        case "pull", "push": return .axAccentBlue
        default: return .axTextSecondary
        }
    }
    
    // MARK: - Stream
    
    private func startStream() {
        isStreaming = true
        task = Task {
            do {
                // Single fetch — no continuous polling to avoid blocking SSH
                let since = Int(Date().timeIntervalSince1970) - 60
                let until = Int(Date().timeIntervalSince1970)
                
                let result = try await DockerService.shared.getRecentEvents(
                    since: since,
                    until: until,
                    serverId: serverId
                )
                
                for event in result {
                    let timeStr = String(event.timestamp.suffix(8))
                    let newEvent = (time: timeStr, type: event.type, action: event.action, actor: event.actor)
                    
                    await MainActor.run {
                        if !events.contains(where: { $0.time == newEvent.time && $0.action == newEvent.action && $0.actor == newEvent.actor }) {
                            events.insert(newEvent, at: 0)
                            if events.count > 500 { events.removeLast() }
                        }
                    }
                }
                
                // Then poll slowly — every 30 seconds
                while !Task.isCancelled {
                    try await Task.sleep(nanoseconds: 30_000_000_000)
                    
                    let newSince = Int(Date().timeIntervalSince1970) - 30
                    let newUntil = Int(Date().timeIntervalSince1970)
                    
                    let newResult = try await DockerService.shared.getRecentEvents(
                        since: newSince,
                        until: newUntil,
                        serverId: serverId
                    )
                    
                    for event in newResult {
                        let timeStr = String(event.timestamp.suffix(8))
                        let newEvent = (time: timeStr, type: event.type, action: event.action, actor: event.actor)
                        
                        await MainActor.run {
                            if !events.contains(where: { $0.time == newEvent.time && $0.action == newEvent.action && $0.actor == newEvent.actor }) {
                                events.insert(newEvent, at: 0)
                                if events.count > 500 { events.removeLast() }
                            }
                        }
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { isStreaming = false }
                }
            }
        }
    }
    
    private func stopStream() {
        task?.cancel()
        task = nil
        isStreaming = false
    }
}
