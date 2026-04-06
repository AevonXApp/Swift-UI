//
//  GeneralSettingsSection.swift
//  AevonX
//
//  General settings: startup, behavior, language, data
//

import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct GeneralSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager

    @State private var showResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "General",
                description: "App behavior & startup",
                icon: "gearshape"
            )

            startupSection
            dataSection
        }
        .onChange(of: settings.launchAtLogin) { _, newValue in
            setLaunchAtLogin(newValue)
        }
        .onChange(of: settings.checkForUpdates) { _, newValue in
            if newValue {
                AppUpdateService.shared.startPeriodicCheck()
            }
        }
    }

    // MARK: - Sections

    private var startupSection: some View {
        SettingsSection(title: "Startup", icon: "power") {
            SettingsToggleRow(
                title: "Launch at Login",
                subtitle: "Start AevonX when you log in",
                isOn: $settings.launchAtLogin
            )
            SettingsToggleRow(
                title: "Check for Updates",
                subtitle: "Automatically check for new versions",
                isOn: $settings.checkForUpdates
            )
        }
    }

    // MARK: - Login Item

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            debugLog("[GeneralSettings] Failed to \(enabled ? "register" : "unregister") login item: \(error)")
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "Data", icon: "externaldrive") {
            SettingsButtonRow(
                title: "Export Configuration",
                subtitle: "Export all settings and server configurations",
                buttonLabel: "Export...",
                action: { exportSettings() }
            )
            SettingsButtonRow(
                title: "Import Configuration",
                subtitle: "Import settings from a file",
                buttonLabel: "Import...",
                action: { importSettings() }
            )
            SettingsButtonRow(
                title: "Reset to Defaults",
                subtitle: "Clear all settings and restore defaults",
                buttonLabel: "Reset...",
                isDestructive: true,
                action: { showResetConfirmation = true }
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
}
