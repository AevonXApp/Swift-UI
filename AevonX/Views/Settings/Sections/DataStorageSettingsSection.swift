//
//  DataStorageSettingsSection.swift
//  AevonX
//
//  Data & storage settings: cache, backup, reset
//

import SwiftUI
import UniformTypeIdentifiers

struct DataStorageSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager
    @State private var showResetConfirmation = false
    @State private var showFactoryResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Data & Storage",
                description: "Manage app data & storage",
                icon: "externaldrive",
                iconColor: .axTextSecondary
            )

            backupSection
            resetSection
        }
    }

    private var backupSection: some View {
        SettingsSection(title: "Backup", icon: "arrow.down.doc") {
            SettingsButtonRow(
                title: "Export All Settings",
                subtitle: "Save settings to a JSON file",
                icon: "square.and.arrow.up",
                buttonLabel: "Export...",
                action: { exportSettings() }
            )
            SettingsButtonRow(
                title: "Import Settings",
                subtitle: "Load settings from a file",
                icon: "square.and.arrow.down",
                buttonLabel: "Import...",
                action: { importSettings() }
            )
        }
    }

    // MARK: - Actions

    private func exportSettings() {
        let data = settings.exportSettings()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "aevonx-settings.json"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? jsonData.write(to: url)
            }
        }
    }

    private func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                guard let data = try? Data(contentsOf: url),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                settings.importSettings(json)
            }
        }
    }

    private var resetSection: some View {
        SettingsSection(title: "Reset", icon: "arrow.counterclockwise") {
            SettingsButtonRow(
                title: "Reset All Settings",
                subtitle: "Restore all settings to their defaults",
                icon: "arrow.counterclockwise",
                buttonLabel: "Reset...",
                isDestructive: true,
                action: { showResetConfirmation = true }
            )
            SettingsButtonRow(
                title: "Factory Reset",
                subtitle: "Remove all data, servers, and settings",
                icon: "trash",
                buttonLabel: "Factory Reset...",
                isDestructive: true,
                action: { showFactoryResetConfirmation = true }
            )
        }
        .overlay {
            if showResetConfirmation {
                AXDeleteConfirmation(
                    title: "Reset All Settings?",
                    itemName: "All Settings",
                    icon: "arrow.counterclockwise",
                    warning: "This will restore all settings to their defaults. Server data will not be affected.",
                    onConfirm: {
                        settings.resetToDefaults()
                        showResetConfirmation = false
                    },
                    onCancel: { showResetConfirmation = false }
                )
            }
            if showFactoryResetConfirmation {
                AXDeleteConfirmation(
                    title: "Factory Reset?",
                    itemName: "RESET",
                    icon: "trash",
                    warning: "This will permanently delete ALL data including servers, credentials, settings, and encryption keys. This CANNOT be undone.",
                    requireTypeConfirm: true,
                    onConfirm: {
                        showFactoryResetConfirmation = false
                    },
                    onCancel: { showFactoryResetConfirmation = false }
                )
            }
        }
    }
}
