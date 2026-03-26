//
//  DatabaseSettingsSection.swift
//  AevonX
//
//  Database settings: query, display
//

import SwiftUI

struct DatabaseSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Database",
                description: "Database management preferences",
                icon: "cylinder.split.1x2",
                iconColor: .axInfo
            )

            querySection
        }
    }

    private var querySection: some View {
        SettingsSection(title: "Query", icon: "text.magnifyingglass") {
            SettingsIntSliderRow(
                title: "Query Timeout",
                subtitle: "Maximum time for a query to execute",
                value: $settings.dbQueryTimeout,
                range: 5...120,
                step: 5,
                unit: "s"
            )
            SettingsPickerRow(
                title: "Max Rows Display",
                selection: $settings.dbMaxRowsDisplay,
                options: [
                    (label: "50", value: 50),
                    (label: "100", value: 100),
                    (label: "250", value: 250),
                    (label: "500", value: 500),
                    (label: "1000", value: 1000)
                ]
            )
        }
    }
}
