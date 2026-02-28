//
//  UnifiedBackupSection.swift
//  AevonX
//
//  Unified backup section — merges Backup & Restore + Scheduled Backup
//

import SwiftUI
import AevonXCore

struct UnifiedBackupSection: View {
    @ObservedObject var backupVM: BackupViewModel
    @ObservedObject var scheduledVM: ScheduledBackupViewModel
    @State private var selectedTab: BackupTab = .manual

    enum BackupTab: String, CaseIterable, Identifiable {
        case manual = "Manual Backup"
        case scheduled = "Scheduled"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Backup & Restore", icon: "archivebox.fill")

                Picker("", selection: $selectedTab) {
                    ForEach(BackupTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .manual:
                    BackupSection(viewModel: backupVM)
                case .scheduled:
                    ScheduledBackupSection(viewModel: scheduledVM)
                }
            }
        }
        .background(Color.axBackground)
    }
}
