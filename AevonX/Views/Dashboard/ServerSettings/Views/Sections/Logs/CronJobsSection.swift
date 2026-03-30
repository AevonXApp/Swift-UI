//
//  CronJobsSection.swift
//  AevonX
//
//  Cron jobs management — list, add, delete, logs.
//

import SwiftUI

struct CronJobsSection: View {
    @ObservedObject var vm: SystemLogsVM
    @EnvironmentObject var settings: AppSettingsManager

    @State private var isExpanded = true

    var isMasking: Bool { settings.maskServerInfo && settings.maskInDashboard }

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    if vm.isLoadingCron {
                        AXSkeletonBlock(lines: 5)
                    } else {
                        cronJobsList
                        addCronRow
                        cronLogsView
                        msgOverlay
                    }
                }
            }
        }
        .task { await vm.loadCron() }
    }

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "clock.badge.checkmark", title: L10n.ServerSettings.cronJobs,
            subtitle: L10n.ServerSettings.cronJobsCount(vm.cronJobs.count),
            gradient: [.orange, .axWarning],
            isExpanded: $isExpanded,
            trailing: AnyView(
                Button(action: { Task { await vm.loadCron() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.caption).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
            )
        )
    }
}
