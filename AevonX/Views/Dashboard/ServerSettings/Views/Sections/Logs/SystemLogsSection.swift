//
//  SystemLogsSection.swift
//  AevonX
//
//  System logs viewer — multi-source, filters, search.
//

import SwiftUI

struct SystemLogsSection: View {
    @ObservedObject var vm: SystemLogsVM
    @State private var isExpanded = true

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    if vm.isLoading {
                        AXSkeletonBlock(lines: 6)
                    } else {
                        logFilters
                        logViewer
                        logSizesView
                    }
                }
            }
        }
        .task { await vm.loadLogsSnapshot(); await vm.queryLogs() }
    }

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "doc.text.magnifyingglass", title: L10n.ServerSettings.systemLogs,
            subtitle: L10n.ServerSettings.logFilesCount(vm.logSizes.count),
            gradient: [.axAccentGreen, .axAccentBlue],
            isExpanded: $isExpanded,
            trailing: AnyView(
                Button(action: { Task { await vm.queryLogs() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(AXTypography.caption).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
            )
        )
    }
}
