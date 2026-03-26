//
//  NotificationSettingsSection.swift
//  AevonX
//
//  Notification settings: server, security, system, behavior
//

import SwiftUI

struct NotificationSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Notifications",
                description: "Alerts & notification preferences",
                icon: "bell.fill",
                iconColor: .axWarning
            )

            alertsSection
            behaviorSection
        }
    }

    private var alertsSection: some View {
        SettingsSection(title: "Alerts", icon: "bell") {
            SettingsToggleRow(
                title: "Server Status Changes",
                subtitle: "Notify when servers go online/offline",
                isOn: $settings.serverStatusAlerts
            )
            SettingsToggleRow(
                title: "Connection Alerts",
                subtitle: "Notify on connection lost/restored",
                isOn: $settings.connectionAlerts
            )
            SettingsToggleRow(
                title: "Security Alerts",
                subtitle: "Failed login attempts, brute force detection",
                isOn: $settings.securityAlerts
            )
            SettingsToggleRow(
                title: "App Update Alerts",
                subtitle: "Notify when updates are available",
                isOn: $settings.updateAlerts
            )
        }
    }

    private var behaviorSection: some View {
        SettingsSection(title: "Behavior", icon: "speaker.wave.2") {
            SettingsToggleRow(
                title: "Notification Sound",
                subtitle: "Play a sound with each notification",
                isOn: $settings.soundEnabled
            )
        }
    }
}
