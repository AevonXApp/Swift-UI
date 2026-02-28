//
//  CronTab.swift
//  AevonX
//
//  Main Cron Management tab with sub-tabs for Jobs and Script Library
//

import SwiftUI
import AevonXCore

struct CronTab: View {
    let serverId: String
    @ObservedObject var connectionViewModel: ServerConnectionViewModel
    @StateObject private var vm: CronViewModel
    
    @State private var selectedSubTab = 0
    @State private var showDeleteAlert = false
    @State private var jobToDelete: CronJob?
    
    init(serverId: String, connectionViewModel: ServerConnectionViewModel) {
        self.serverId = serverId
        self.connectionViewModel = connectionViewModel
        _vm = StateObject(wrappedValue: CronViewModel(serverId: serverId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            
            Divider().background(Color.axBorder)
            
            // Content
            ScrollView {
                VStack(spacing: AXSpacing.lg) {
                    if selectedSubTab == 0 {
                        cronJobsContent
                    } else {
                        CronScriptLibrary(vm: vm)
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .sheet(isPresented: $vm.showAddSheet) {
            CronAddTaskSheet(vm: vm)
        }
        .sheet(isPresented: $vm.showLogSheet) {
            CronLogSheet(vm: vm)
        }
        .sheet(isPresented: $vm.showExecuteResult) {
            executeResultSheet
        }
        .alert("Delete Task?", isPresented: $showDeleteAlert, presenting: jobToDelete) { job in
            Button("Cancel", role: .cancel) { jobToDelete = nil }
            Button("Delete", role: .destructive) { Task { await vm.deleteJob(job) } }
        } message: { job in
            Text("Delete \"\(job.name)\"? This will remove the cron job from the server.")
        }
        .overlay(alignment: .bottom) { toastOverlay }
        .task {
            await vm.loadJobs()
            vm.loadScriptLibrary()
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        VStack(spacing: 0) {
            // Row 1: Title only
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.axAccentBlue)
                    Text("Cron Manager")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.xl)
            .padding(.bottom, AXSpacing.md)
            
            // Row 2: Tabs + stats + search + add task
            HStack(spacing: AXSpacing.lg) {
                HStack(spacing: 0) {
                    subTab("Cron Jobs", icon: "clock.badge.checkmark", index: 0, count: vm.jobs.count)
                    subTab("Script Library", icon: "book.closed", index: 1, count: vm.scriptTemplates.count)
                }
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.md)
                
                Spacer()
                
                HStack(spacing: AXSpacing.sm) {
                    statBadge(vm.activeJobsCount, label: "Active", color: .axSuccess)
                    statBadge(vm.disabledJobsCount, label: "Disabled", color: .axTextMuted)
                }
                
                AXSearchBar(text: $vm.searchText, placeholder: "Search tasks...")
                    .frame(width: 200)
                
                Button(action: { vm.editingJob = nil; vm.showAddSheet = true }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add Task")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, 7)
                    .background(LinearGradient(colors: [.axAccentBlue, .axAccentBlue.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.bottom, AXSpacing.md)
        }
    }
    
    // MARK: - Cron Jobs Content
    
    private var cronJobsContent: some View {
        VStack(spacing: AXSpacing.md) {
            if vm.isLoading {
                AXLoadingState(message: "Loading cron jobs from server...")
            } else if vm.filteredJobs.isEmpty {
                emptyState
            } else {
                // Table header
                HStack(spacing: AXSpacing.md) {
                    Text("Task")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Status")
                        .frame(width: 80)
                    Text("Last Executed")
                        .frame(width: 90, alignment: .trailing)
                    Text("Actions")
                        .frame(width: 160, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.axTextTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, AXSpacing.md)
                
                ForEach(vm.filteredJobs) { job in
                    CronJobRow(
                        job: job,
                        isExecuting: vm.executingJobId == job.id,
                        onExecute: { Task { await vm.executeNow(job) } },
                        onEdit: { vm.editingJob = job; vm.showAddSheet = true },
                        onLog: { Task { await vm.loadLogs(for: job) } },
                        onToggle: { Task { await vm.toggleJob(job) } },
                        onDelete: { jobToDelete = job; showDeleteAlert = true }
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AXSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.axAccentBlue.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 32))
                    .foregroundColor(.axAccentBlue.opacity(0.5))
            }
            
            Text("No Cron Jobs")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.axTextPrimary)
            
            Text("Schedule automated tasks for your server.\nBackups, monitoring, maintenance — all automated.")
                .font(AXTypography.body)
                .foregroundColor(.axTextTertiary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: AXSpacing.md) {
                Button(action: { vm.editingJob = nil; vm.showAddSheet = true }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        Text("Create Task").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { selectedSubTab = 1 }) {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "book.closed").font(.system(size: 12))
                        Text("Browse Scripts").font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Execute Result Sheet

    private var executeResultSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Execution Result")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.axTextPrimary)
                Spacer()
                Button(action: { vm.showExecuteResult = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.lg)
            
            Divider()
            
            ScrollView {
                Text(vm.executeOutput ?? "No output")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(red: 0.6, green: 0.9, blue: 0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AXSpacing.lg)
            }
            .background(Color(red: 0.06, green: 0.06, blue: 0.08))
        }
        .frame(width: 550, height: 400)
        .background(Color.axBackground)
    }
    
    // MARK: - Helpers
    
    private func subTab(_ title: String, icon: String, index: Int, count: Int) -> some View {
        Button(action: { withAnimation(.spring(response: 0.3)) { selectedSubTab = index } }) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon).font(.system(size: 11))
                Text(title).font(.system(size: 12, weight: .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(selectedSubTab == index ? .white : .axTextTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(selectedSubTab == index ? Color.white.opacity(0.2) : Color.axBorder.opacity(0.5))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(selectedSubTab == index ? .white : .axTextSecondary)
            .padding(.horizontal, AXSpacing.lg)
            .padding(.vertical, 8)
            .background(selectedSubTab == index ? Color.axAccentBlue : Color.clear)
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statBadge(_ count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(count)").font(.system(size: 11, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 10)).foregroundColor(.axTextTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.06))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    @ViewBuilder
    private var toastOverlay: some View {
        if let msg = vm.toastMessage {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: msg.1 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 14))
                Text(msg.0)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.md)
            .background(Capsule().fill(msg.1 ? Color.axSuccess : Color.axError).shadow(color: .black.opacity(0.3), radius: 10, y: 4))
            .padding(.bottom, AXSpacing.xl)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4), value: vm.toastMessage != nil)
        }
    }
}
