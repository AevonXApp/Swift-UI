//
//  FileManagerSettingsSection.swift
//  AevonX
//
//  File manager settings: display, safety
//

import SwiftUI

struct FileManagerSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "File Manager",
                description: "SFTP browser preferences",
                icon: "folder.fill",
                iconColor: .axWarning
            )

            displaySection
        }
    }

    private var displaySection: some View {
        SettingsSection(title: "Display", icon: "eye") {
            SettingsToggleRow(
                title: "Show Hidden Files",
                subtitle: "Show files starting with a dot",
                isOn: $settings.showHiddenFiles
            )
            SettingsToggleRow(
                title: "Show File Extensions",
                subtitle: "Display file type extensions",
                isOn: $settings.showFileExtensions
            )
            SettingsPickerRow(
                title: "Sort Order",
                selection: $settings.fileSortOrder,
                options: [
                    (label: "Name", value: "name"),
                    (label: "Date Modified", value: "date"),
                    (label: "Size", value: "size"),
                    (label: "Type", value: "type")
                ]
            )
        }
    }
}
