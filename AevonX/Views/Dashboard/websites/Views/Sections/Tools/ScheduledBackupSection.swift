//
//  ScheduledBackupSection.swift
//  AevonX
//
//  Scheduled backup management UI — cron-based automated backups
//

import SwiftUI
import AevonXCore

struct ScheduledBackupSection: View {
    @ObservedObject var viewModel: ScheduledBackupViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Scheduled Backups", icon: "clock.arrow.circlepath")

                // Existing schedules
                AXConfigCard(icon: "calendar.badge.clock", title: "Active Schedules", subtitle: "Automated backup cron jobs for this site") {
                    if viewModel.schedules.isEmpty && !viewModel.isLoading {
                        AXPlaceholder(icon: "calendar", title: "No scheduled backups configured")
                    } else {
                        VStack(spacing: AXSpacing.sm) {
                            ForEach(viewModel.schedules) { schedule in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(schedule.displayText)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.axTextPrimary)
                                        HStack(spacing: AXSpacing.xs) {
                                            Text(schedule.cronExpression)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.axTextMuted)
                                            if schedule.includesDatabase {
                                                HStack(spacing: 2) {
                                                    Image(systemName: "cylinder.fill")
                                                    Text("+ DB")
                                                }
                                                .font(.system(size: 9))
                                                .foregroundColor(.axAccentBlue)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Button(action: { Task { await viewModel.deleteSchedule(schedule) } }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                            .foregroundColor(.axError)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(AXSpacing.sm)
                                .background(Color.axBackground)
                                .cornerRadius(AXCornerRadius.sm)
                            }
                        }
                    }
                }

                // Create new schedule
                AXConfigCard(icon: "plus.circle.fill", title: "Create Schedule", subtitle: "Set up automated backups") {
                    VStack(spacing: AXSpacing.md) {
                        // Frequency picker
                        HStack {
                            Text("Frequency")
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 100, alignment: .trailing)
                            Picker("", selection: $viewModel.selectedFrequency) {
                                Text("Daily").tag("daily")
                                Text("Weekly").tag("weekly")
                                Text("Monthly").tag("monthly")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Retention
                        HStack {
                            Text("Keep for")
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 100, alignment: .trailing)
                            Picker("", selection: $viewModel.retentionDays) {
                                Text("7 days").tag(7)
                                Text("14 days").tag(14)
                                Text("30 days").tag(30)
                                Text("60 days").tag(60)
                                Text("90 days").tag(90)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // Include DB
                        Toggle(isOn: $viewModel.includeDatabase) {
                            HStack(spacing: AXSpacing.xs) {
                                Image(systemName: "cylinder.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.axAccentBlue)
                                Text("Include database dump")
                                    .font(.system(size: 12))
                            }
                        }
                        .toggleStyle(.switch)

                        HStack(spacing: AXSpacing.md) {
                            Button(action: { Task { await viewModel.createSchedule() } }) {
                                Label("Create Schedule", systemImage: "calendar.badge.plus")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            .disabled(viewModel.isLoading)

                            Button(action: { Task { await viewModel.runBackupNow() } }) {
                                Label("Backup Now", systemImage: "archivebox.fill")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .disabled(viewModel.isLoading)
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.loadSchedules() } }
    }
}
