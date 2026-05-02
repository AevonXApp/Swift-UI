//
//  CronAddTaskSheet.swift
//  AevonX
//
//  Add/Edit cron task sheet with visual schedule builder
//

import SwiftUI
import AevonXCoreBridge

struct CronAddTaskSheet: View {
    @ObservedObject var vm: CronViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var taskType: CronTaskType = .shellScript
    @State private var schedulePreset: SchedulePreset = .daily
    @State private var customMinute = "0"
    @State private var customHour = "2"
    @State private var customDayOfMonth = "*"
    @State private var customMonth = "*"
    @State private var customDayOfWeek = "*"
    @State private var executeUser = "root"
    @State private var scriptContent = ""
    @State private var customParam = ""
    @State private var isEditing = false
    @State private var editingJobId: UUID?
    
    enum SchedulePreset: String, CaseIterable {
        case everyMinute = "Every Minute"
        case every5Min = "Every 5 Minutes"
        case every15Min = "Every 15 Minutes"
        case every30Min = "Every 30 Minutes"
        case hourly = "Hourly"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case custom = "Custom"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEditing ? L10n.Cron.editTask : L10n.Cron.addTask)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text(L10n.Cron.configureAScheduledTaskForYourServer)
                        .font(.system(size: 12))
                        .foregroundColor(.axTextTertiary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.xl)
            
            Divider().background(Color.axBorder)
            
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    // Task Type
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        formLabel("Task Type")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: AXSpacing.sm)], spacing: AXSpacing.sm) {
                            ForEach(CronTaskType.allCases) { type in
                                Button(action: {
                                    taskType = type
                                    if !isEditing { scriptContent = type.defaultScript(param: customParam) }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 11, weight: .medium))
                                        Text(type.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(taskType == type ? .white : .axTextSecondary)
                                    .padding(.horizontal, AXSpacing.sm)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background(taskType == type ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                    .cornerRadius(AXCornerRadius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                            .stroke(taskType == type ? Color.clear : Color.axBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Task Name
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        formLabel("Task Name")
                        TextField("e.g. Daily Database Backup", text: $name)
                            .font(.system(size: 13))
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(AXSpacing.sm)
                            .background(Color.axBackgroundTertiary)
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    
                    // Schedule
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        formLabel("Execute Cycle")
                        
                        HStack(spacing: AXSpacing.sm) {
                            ForEach(SchedulePreset.allCases, id: \.self) { preset in
                                Button(action: { schedulePreset = preset }) {
                                    Text(preset.rawValue)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(schedulePreset == preset ? .white : .axTextSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(schedulePreset == preset ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                        .cornerRadius(AXCornerRadius.sm)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        if schedulePreset == .custom {
                            HStack(spacing: AXSpacing.sm) {
                                cronField("Min", $customMinute)
                                cronField("Hour", $customHour)
                                cronField("Day", $customDayOfMonth)
                                cronField("Month", $customMonth)
                                cronField("Weekday", $customDayOfWeek)
                            }
                        }
                        
                        // Preview
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(buildSchedule.humanReadable)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.axAccentBlue)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.axAccentBlue.opacity(0.08))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                    
                    // Execute User
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        formLabel("Execute User")
                        Picker("", selection: $executeUser) {
                            Text("root").tag("root")
                            Text("www-data").tag("www-data")
                            Text("nobody").tag("nobody")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Optional param for certain types
                    if taskType == .backupWebsite || taskType == .backupDirectory || taskType == .accessURL {
                        VStack(alignment: .leading, spacing: AXSpacing.sm) {
                            formLabel(taskType == .accessURL ? "URL" : "Path")
                            TextField(taskType == .accessURL ? "https://example.com" : "/var/www/html", text: $customParam)
                                .font(.system(size: 13, design: .monospaced))
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(AXSpacing.sm)
                                .background(Color.axBackgroundTertiary)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                                .cornerRadius(AXCornerRadius.sm)
                                .onChange(of: customParam) { _, newVal in
                                    scriptContent = taskType.defaultScript(param: newVal)
                                }
                        }
                    }
                    
                    // Script Content
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        HStack {
                            formLabel("Script Content")
                            Spacer()
                            Button(action: { scriptContent = taskType.defaultScript(param: customParam) }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.counterclockwise").font(.system(size: 9))
                                    Text(L10n.Cron.reset).font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(.axAccentBlue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        TextEditor(text: $scriptContent)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(AXSpacing.sm)
                            .frame(minHeight: 160)
                            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                            .cornerRadius(AXCornerRadius.sm)
                        
                        // Security warning
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 10))
                            Text(L10n.Cron.avoidDangerousCommandsShutdownInitMkfsRmRf)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.axWarning)
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.axWarning.opacity(0.08))
                        .cornerRadius(AXCornerRadius.sm)
                    }
                }
                .padding(AXSpacing.xl)
            }
            
            Divider().background(Color.axBorder)
            
            // Footer buttons
            HStack {
                Button(L10n.Button.cancel) { dismiss() }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.sm)
                
                Spacer()
                
                Button(action: saveTask) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text(isEditing ? L10n.Button.saveChanges : L10n.Cron.addTask)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(name.isEmpty || scriptContent.isEmpty)
            }
            .padding(AXSpacing.xl)
        }
        .frame(width: 700, height: 680)
        .background(Color.axBackground)
        .onAppear(perform: loadEditingJob)
    }
    
    private var buildSchedule: CronSchedule {
        switch schedulePreset {
        case .everyMinute: return .everyMinute
        case .every5Min: return .every5Minutes
        case .every15Min: return .every15Minutes
        case .every30Min: return .every30Minutes
        case .hourly: return .hourly
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .custom: return CronSchedule(minute: customMinute, hour: customHour, dayOfMonth: customDayOfMonth, month: customMonth, dayOfWeek: customDayOfWeek)
        }
    }
    
    private func saveTask() {
        var job = CronJob()
        if let existingId = editingJobId { job.id = existingId }
        job.name = name
        job.taskType = taskType
        job.schedule = buildSchedule
        job.command = scriptContent
        job.executeUser = executeUser
        
        Task {
            if isEditing, let old = vm.editingJob {
                await vm.deleteJob(old)
            }
            await vm.addJob(job)
            dismiss()
        }
    }
    
    private func loadEditingJob() {
        guard let job = vm.editingJob else {
            scriptContent = taskType.defaultScript()
            return
        }
        isEditing = true
        editingJobId = job.id
        name = job.name
        taskType = job.taskType
        scriptContent = job.command
        executeUser = job.executeUser
        schedulePreset = .custom
        customMinute = job.schedule.minute
        customHour = job.schedule.hour
        customDayOfMonth = job.schedule.dayOfMonth
        customMonth = job.schedule.month
        customDayOfWeek = job.schedule.dayOfWeek
    }
    
    private func formLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.axTextSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
    
    private func cronField(_ label: String, _ value: Binding<String>) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 9, weight: .medium)).foregroundColor(.axTextTertiary)
            TextField("*", text: value)
                .font(.system(size: 12, design: .monospaced))
                .multilineTextAlignment(.center)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 4).padding(.vertical, 4)
                .background(Color.axBackgroundTertiary)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.axBorder, lineWidth: 1))
                .cornerRadius(4)
                .frame(width: 60)
        }
    }
}
