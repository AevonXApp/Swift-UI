//
//  CronJobsListView.swift
//  AevonX
//
//  Cron jobs list, add form, and cron log display.
//

import SwiftUI

extension CronJobsSection {

    var cronJobsList: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            if vm.cronJobs.isEmpty {
                Text(L10n.ServerSettings.noCronJobs)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AXSpacing.sm)
            } else {
                ForEach(vm.cronJobs) { job in
                    HStack(spacing: AXSpacing.sm) {
                        Circle()
                            .fill(job.isDisabled ? Color.axTextMuted : Color.axSuccess)
                            .frame(width: 6, height: 6)
                        Text(isMasking && settings.maskUsernames ? PrivacyMask.username(job.user) : job.user)
                            .font(AXTypography.monoXs).fontWeight(.medium)
                            .foregroundColor(.axAccentBlue)
                            .frame(width: 50, alignment: .leading)
                        Text(job.schedule)
                            .font(AXTypography.monoXs)
                            .foregroundColor(.axTextPrimary)
                            .frame(width: 90, alignment: .leading)
                        Text(job.command)
                            .font(AXTypography.monoXs)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(1)
                        Spacer()
                        Button(action: { Task { await vm.deleteServerCronJob(job) } }) {
                            Image(systemName: "trash")
                                .font(AXTypography.caption2).foregroundColor(.axError)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, AXSpacing.xxxs)
                    .opacity(job.isDisabled ? 0.5 : 1)
                }
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    var addCronRow: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text(L10n.ServerSettings.addCronJob)
                .font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextPrimary)
            HStack(spacing: AXSpacing.xs) {
                TextField(L10n.ServerSettings.user, text: $vm.newCronUser)
                    .font(AXTypography.monoXs).textFieldStyle(.plain)
                    .frame(width: 55)
                    .padding(.horizontal, AXSpacing.xxs).padding(.vertical, AXSpacing.xxs)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.sm)

                TextField("0 * * * *", text: $vm.newCronSchedule)
                    .font(AXTypography.monoXs).textFieldStyle(.plain)
                    .frame(width: 85)
                    .padding(.horizontal, AXSpacing.xxs).padding(.vertical, AXSpacing.xxs)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.sm)

                TextField(L10n.ServerSettings.commandPlaceholder, text: $vm.newCronCommand)
                    .font(AXTypography.monoXs).textFieldStyle(.plain)
                    .padding(.horizontal, AXSpacing.xxs).padding(.vertical, AXSpacing.xxs)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.sm)

                Button(action: { Task { await vm.addServerCronJob() } }) {
                    Image(systemName: "plus.circle.fill")
                        .font(AXTypography.body).foregroundColor(.axAccentBlue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(vm.newCronCommand.isEmpty)
            }

            // Quick templates
            HStack(spacing: AXSpacing.xs) {
                Text(L10n.ServerSettings.templates).font(AXTypography.caption2).foregroundColor(.axTextMuted)
                templateButton(L10n.ServerSettings.everyHour, "0 * * * *")
                templateButton(L10n.ServerSettings.daily3AM, "0 3 * * *")
                templateButton(L10n.ServerSettings.weeklySun, "0 0 * * 0")
                templateButton(L10n.ServerSettings.monthly1st, "0 0 1 * *")
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    private func templateButton(_ label: String, _ schedule: String) -> some View {
        Button(action: { vm.newCronSchedule = schedule }) {
            Text(label)
                .font(AXTypography.caption2)
                .foregroundColor(.axAccentBlue)
                .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxxs)
                .background(Color.axAccentBlue.opacity(0.1))
                .cornerRadius(AXCornerRadius.sm)
        }.buttonStyle(PlainButtonStyle())
    }

    var cronLogsView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: "doc.text").font(AXTypography.caption2).foregroundColor(.axAccentBlue)
                Text(L10n.ServerSettings.cronLog).font(AXTypography.caption).fontWeight(.semibold).foregroundColor(.axTextPrimary)
            }

            if vm.cronLogs.isEmpty {
                Text(L10n.ServerSettings.noCronLogEntries)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                        ForEach(vm.cronLogs.suffix(15)) { entry in
                            Text(entry.line)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.axTextSecondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
            }
        }
        .padding(AXSpacing.sm)
        .background(Color.axBackgroundTertiary.opacity(0.3))
        .cornerRadius(AXCornerRadius.md)
    }

    var msgOverlay: some View {
        Group {
            if let (msg, ok) = vm.saveMsg {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(msg)
                }
                .font(AXTypography.caption).foregroundColor(ok ? .axSuccess : .axError)
            }
        }
    }
}
