
import SwiftUI
import AevonXCoreBridge

struct DockerSchedulerView: View {
    let serverId: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var scheduledActions: [ScheduledAction] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // New schedule form
    @State private var showAddForm = false
    @State private var containers: [DockerContainer] = []
    @State private var selectedContainer = ""
    @State private var selectedAction = "restart"
    @State private var cronSchedule = "0 3 * * *"
    @State private var isAdding = false
    
    private let actions = ["restart", "stop", "start"]
    private let presetSchedules = [
        ("Every day at 3 AM", "0 3 * * *"),
        ("Every 6 hours", "0 */6 * * *"),
        ("Every Sunday", "0 3 * * 0"),
        ("Every Monday 8 AM", "0 8 * * 1"),
        ("Every hour", "0 * * * *"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label(L10n.Docker.containerScheduler, systemImage: "clock.badge.checkmark")
                    .font(AXTypography.title2)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                
                Button { showAddForm.toggle() } label: {
                    Label("New Schedule", systemImage: "plus")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.axAccentBlue)
                .foregroundColor(.white)
                .cornerRadius(AXCornerRadius.sm)
                
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
            
            ScrollView {
                VStack(spacing: AXSpacing.md) {
                    // Add Form
                    if showAddForm {
                        AXCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("New Scheduled Action", systemImage: "calendar.badge.plus")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                // Container picker
                                Picker("Container", selection: $selectedContainer) {
                                    ForEach(containers) { c in
                                        Text(c.names).tag(c.names)
                                    }
                                }
                                .labelsHidden()
                                
                                // Action picker
                                Picker("Action", selection: $selectedAction) {
                                    ForEach(actions, id: \.self) { a in
                                        Text(a.capitalized).tag(a)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                // Schedule presets
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Schedule")
                                        .font(AXTypography.caption)
                                        .foregroundColor(.axTextSecondary)
                                    
                                    ForEach(presetSchedules, id: \.0) { preset in
                                        Button {
                                            cronSchedule = preset.1
                                        } label: {
                                            HStack {
                                                Image(systemName: cronSchedule == preset.1 ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(cronSchedule == preset.1 ? .axAccentBlue : .axTextMuted)
                                                Text(preset.0)
                                                    .font(AXTypography.caption)
                                                    .foregroundColor(.axTextPrimary)
                                                Spacer()
                                                Text(preset.1)
                                                    .font(AXTypography.caption2)
                                                    .foregroundColor(.axTextMuted)
                                                    .monospaced()
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .padding(6)
                                        .background(cronSchedule == preset.1 ? Color.axAccentBlue.opacity(0.1) : Color.clear)
                                        .cornerRadius(4)
                                    }
                                    
                                    TextField("Custom cron: * * * * *", text: $cronSchedule)
                                        .textFieldStyle(.roundedBorder)
                                        .font(AXTypography.caption)
                                        .monospaced()
                                }
                                
                                HStack {
                                    Spacer()
                                    Button(L10n.Button.cancel) { showAddForm = false }
                                        .buttonStyle(.plain)
                                        .foregroundColor(.axTextSecondary)
                                    
                                    Button {
                                        addSchedule()
                                    } label: {
                                        if isAdding {
                                            ProgressView().scaleEffect(0.6)
                                        } else {
                                            Text("Add Schedule")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedContainer.isEmpty ? Color.axSurface : Color.axAccentBlue)
                                    .foregroundColor(selectedContainer.isEmpty ? .axTextMuted : .white)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .disabled(selectedContainer.isEmpty || isAdding)
                                }
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error).font(AXTypography.caption).foregroundColor(.axError).padding()
                    }
                    
                    // Active Schedules
                    if isLoading {
                        ProgressView("Loading schedules...")
                            .padding(30)
                    } else if scheduledActions.isEmpty {
                        VStack(spacing: AXSpacing.sm) {
                            Image(systemName: "clock.badge.questionmark")
                                .font(.system(size: 32))
                                .foregroundColor(.axTextMuted)
                            Text("No scheduled actions")
                                .font(AXTypography.body)
                                .foregroundColor(.axTextSecondary)
                        }
                        .padding(30)
                    } else {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            Text("Active Schedules")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)
                            
                            ForEach(scheduledActions) { action in
                                AXCard {
                                    HStack {
                                        Image(systemName: actionIcon(action.action))
                                            .foregroundColor(actionColor(action.action))
                                            .font(.system(size: 16))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(action.description)
                                                .font(AXTypography.body)
                                                .foregroundColor(.axTextPrimary)
                                            Text(action.schedule)
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextMuted)
                                                .monospaced()
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            removeSchedule(action)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 12))
                                                .foregroundColor(.axError)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 550, minHeight: 450)
        .background(Color.axBackground)
        .onAppear { loadData() }
    }
    
    private func actionIcon(_ action: String) -> String {
        switch action {
        case "restart": return "arrow.clockwise"
        case "stop": return "stop.fill"
        case "start": return "play.fill"
        default: return "gearshape"
        }
    }
    
    private func actionColor(_ action: String) -> Color {
        switch action {
        case "restart": return .axWarning
        case "stop": return .axError
        case "start": return .axSuccess
        default: return .axTextSecondary
        }
    }
    
    private func loadData() {
        Task {
            do {
                let c = try await DockerService.shared.getContainers(serverId: serverId, all: true)
                let s = try await DockerService.shared.listScheduledActions(serverId: serverId)
                await MainActor.run {
                    containers = c
                    if let first = c.first { selectedContainer = first.names }
                    scheduledActions = s
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false; errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func addSchedule() {
        isAdding = true
        Task {
            do {
                try await DockerService.shared.scheduleContainerAction(
                    containerName: selectedContainer, action: selectedAction,
                    schedule: cronSchedule, serverId: serverId
                )
                await MainActor.run {
                    isAdding = false; showAddForm = false
                    loadData()
                }
            } catch {
                await MainActor.run { isAdding = false; errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func removeSchedule(_ action: ScheduledAction) {
        Task {
            try? await DockerService.shared.removeScheduledAction(
                containerName: action.containerName, action: action.action, serverId: serverId
            )
            await MainActor.run { scheduledActions.removeAll { $0.id == action.id } }
        }
    }
}
