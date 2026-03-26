//
//  ServerListSettingsSection.swift
//  AevonX
//
//  Server list settings: view mode, display options, behavior
//

import SwiftUI

struct ServerListSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Server List",
                description: "Fleet view layout & behavior",
                icon: "server.rack"
            )

            viewSection
            displaySection
            behaviorSection
        }
    }

    private var viewSection: some View {
        SettingsSection(title: "View", icon: "rectangle.grid.1x2") {
            SettingsSegmentedRow(
                title: "Default View Mode",
                selection: $settings.defaultViewMode,
                options: [
                    (label: "Grid", value: "grid"),
                    (label: "List", value: "list")
                ]
            )
            SettingsStepperRow(
                title: "Grid Columns",
                subtitle: "Number of columns in grid view",
                value: $settings.gridColumnCount,
                range: 1...4
            )
        }
    }

    private var displaySection: some View {
        SettingsSection(title: "Display", icon: "eye") {
            SettingsToggleRow(
                title: "Show Server Tags",
                subtitle: "Display tags beneath each server card",
                isOn: $settings.showServerTags
            )
            SettingsToggleRow(
                title: "Show OS Badge",
                subtitle: "Display the detected OS icon on cards",
                isOn: $settings.showServerOS
            )
            SettingsToggleRow(
                title: "Show Port Info",
                subtitle: "Show SSH port number on server cards",
                isOn: $settings.showPortInfo
            )
        }
    }

    private var behaviorSection: some View {
        SettingsSection(title: "Behavior", icon: "arrow.triangle.2.circlepath") {
            SettingsToggleRow(
                title: "Remember Last Filter",
                subtitle: "Restore your last active filter on next launch",
                isOn: $settings.rememberLastFilter
            )
            SettingsToggleRow(
                title: "Remember Last Sort",
                subtitle: "Restore your last sort order on next launch",
                isOn: $settings.rememberLastSort
            )
            SettingsPickerRow(
                title: "Default Sort",
                selection: $settings.defaultSortOption,
                options: [
                    (label: "Name (A-Z)", value: "name_asc"),
                    (label: "Name (Z-A)", value: "name_desc"),
                    (label: "Recently Added", value: "date_desc"),
                    (label: "Status", value: "status")
                ]
            )
            SettingsToggleRow(
                title: "Auto-refresh Status",
                subtitle: "Periodically check server online/offline state",
                isOn: $settings.autoRefreshStatus
            )
            if settings.autoRefreshStatus {
                SettingsIntSliderRow(
                    title: "Refresh Interval",
                    value: $settings.statusCheckInterval,
                    range: 15...300,
                    step: 15,
                    unit: "s"
                )
            }
        }
    }
}
