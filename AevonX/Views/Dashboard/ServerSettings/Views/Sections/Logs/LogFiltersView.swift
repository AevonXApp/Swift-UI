//
//  LogFiltersView.swift
//  AevonX
//
//  Log query filters — source, priority, service, search, line count.
//

import SwiftUI

extension SystemLogsSection {

    var logFilters: some View {
        VStack(spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.sm) {
                // Source picker
                Picker(L10n.ServerSettings.sourcePicker, selection: $vm.selectedSource) {
                    ForEach(vm.logSources, id: \.self) { source in
                        Text(source).tag(source)
                    }
                }
                .pickerStyle(.menu).frame(width: 120)

                // Priority picker
                Picker(L10n.ServerSettings.priorityPicker, selection: $vm.selectedPriority) {
                    ForEach(LogPriority.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.menu).frame(width: 90)

                // Lines picker
                Picker(L10n.ServerSettings.lines, selection: $vm.logLines) {
                    Text("25").tag(Int32(25))
                    Text("50").tag(Int32(50))
                    Text("100").tag(Int32(100))
                    Text("200").tag(Int32(200))
                    Text("500").tag(Int32(500))
                }
                .pickerStyle(.menu).frame(width: 70)

                Spacer()
            }

            HStack(spacing: AXSpacing.sm) {
                // Service filter
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "square.stack.3d.up").font(AXTypography.caption2).foregroundColor(.axTextMuted)
                    TextField(L10n.ServerSettings.servicePlaceholder, text: $vm.logServiceFilter)
                        .font(AXTypography.caption).textFieldStyle(.plain)
                }
                .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxs)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)
                .frame(width: 140)

                // Search
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "magnifyingglass").font(AXTypography.caption2).foregroundColor(.axTextMuted)
                    TextField(L10n.ServerSettings.searchPlaceholder, text: $vm.logSearchText)
                        .font(AXTypography.caption).textFieldStyle(.plain)
                }
                .padding(.horizontal, AXSpacing.xs).padding(.vertical, AXSpacing.xxs)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)

                Button(action: { Task { await vm.queryLogs() } }) {
                    Text(L10n.ServerSettings.query)
                        .font(AXTypography.caption2).fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.sm)
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}
