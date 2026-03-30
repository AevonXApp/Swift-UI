//
//  ServiceManagementSection.swift
//  AevonX
//
//  Services management — categorized list with search, filter, enable/disable, logs.
//

import SwiftUI

struct ServiceManagementSection: View {
    @ObservedObject var vm: ServerSettingsViewModel
    @State private var isExpanded = true

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    if vm.isLoadingServices {
                        AXSkeletonBlock(lines: 7)
                    } else {
                        searchAndFilter
                        serviceCategories
                    }
                }
            }
        }
        .sheet(item: logsBinding) { name in
            ServiceLogsSheet(vm: vm, serviceName: name)
        }
    }

    private var logsBinding: Binding<String?> {
        Binding(
            get: { vm.selectedServiceForLogs },
            set: { vm.selectedServiceForLogs = $0 }
        )
    }

    // MARK: - Header

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "square.stack.3d.up.fill", title: L10n.ServerSettings.services,
            subtitle: L10n.ServerSettings.servicesCount(vm.allServices.count), gradient: [.teal, .mint],
            isExpanded: $isExpanded,
            trailing: AnyView(
                Button(action: { Task { await vm.loadServices() } }) {
                    Image(systemName: "arrow.clockwise").font(AXTypography.caption).foregroundColor(.axAccentBlue)
                }.buttonStyle(PlainButtonStyle())
            )
        )
    }

    // MARK: - Search & Filter

    private var searchAndFilter: some View {
        HStack(spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: "magnifyingglass").font(AXTypography.caption).foregroundColor(.axTextMuted)
                TextField(L10n.ServerSettings.searchServicesPlaceholder, text: $vm.serviceSearchText)
                    .font(AXTypography.caption).textFieldStyle(.plain)
            }
            .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
            .background(Color.axBackgroundTertiary)
            .cornerRadius(AXCornerRadius.sm)

            Picker("", selection: $vm.serviceFilter) {
                ForEach(ServiceFilter.allCases, id: \.self) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 100)
        }
    }

    // MARK: - Categorized List

    private var serviceCategories: some View {
        let categories = vm.categorizedServices
        return VStack(alignment: .leading, spacing: AXSpacing.md) {
            if categories.isEmpty {
                Text(L10n.ServerSettings.noServicesMatch)
                    .font(AXTypography.caption).foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AXSpacing.lg)
            } else {
                ForEach(categories, id: \.category) { group in
                    ServiceCategoryGroup(vm: vm, category: group.category, services: group.services)
                }
            }
        }
    }
}
