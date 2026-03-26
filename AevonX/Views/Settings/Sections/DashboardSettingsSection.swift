//
//  DashboardSettingsSection.swift
//  AevonX
//
//  Dashboard settings: connection, overview tab, tab management
//

import SwiftUI

struct DashboardSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Dashboard",
                description: "Server dashboard layout & tabs",
                icon: "gauge.with.dots.needle.67percent"
            )

            connectionSection
            overviewSection
            defaultTabSection
        }
    }

    private var connectionSection: some View {
        SettingsSection(title: "Connection", icon: "link") {
            SettingsToggleRow(
                title: "Auto-connect on Open",
                subtitle: "Automatically connect SSH when opening a server",
                isOn: $settings.autoConnectOnOpen
            )
            SettingsIntSliderRow(
                title: "Stats Refresh Interval",
                subtitle: "How often to poll system stats",
                value: $settings.statsRefreshInterval,
                range: 1...30,
                unit: "s"
            )
            SettingsToggleRow(
                title: "Enable Auto-reconnect",
                subtitle: "Automatically reconnect on connection drop",
                isOn: $settings.enableReconnection
            )
            if settings.enableReconnection {
                SettingsStepperRow(
                    title: "Max Reconnect Attempts",
                    value: $settings.maxReconnectAttempts,
                    range: 1...10
                )
            }
        }
    }

    private var overviewSection: some View {
        SettingsSection(title: "Overview Tab", icon: "chart.bar") {
            SettingsToggleRow(
                title: "Show Quick Vitals",
                subtitle: "CPU, RAM, and disk usage cards on overview",
                isOn: $settings.showQuickVitals
            )
            SettingsToggleRow(
                title: "Show Quick Actions",
                subtitle: "Shortcut buttons for common tasks",
                isOn: $settings.showQuickActions
            )
            SettingsToggleRow(
                title: "Show Inventory",
                subtitle: "Service counts (sites, databases, docker, etc.)",
                isOn: $settings.showInventory
            )
            SettingsToggleRow(
                title: "Show Fresh Server Banner",
                subtitle: "Show setup prompt for new servers",
                isOn: $settings.showFreshServerBanner
            )
        }
    }

    private var defaultTabSection: some View {
        SettingsSection(title: "Default Tab", icon: "square.grid.2x2") {
            SettingsPickerRow(
                title: "Default Tab",
                subtitle: "Which tab opens first in dashboard",
                selection: $settings.defaultDashboardTab,
                options: [
                    (label: "Overview", value: "overview"),
                    (label: "Websites", value: "websites"),
                    (label: "Databases", value: "databases"),
                    (label: "Terminal", value: "terminal"),
                    (label: "Files", value: "files"),
                    (label: "Docker", value: "docker")
                ]
            )
        }
    }
}
