//
//  ConfirmationSettingsSection.swift
//  AevonX
//
//  Delete confirmation settings: per-category toggles
//

import SwiftUI

struct ConfirmationSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager
    @State private var showDisableAllWarning = false

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Delete Confirmations",
                description: "Control which actions require confirmation",
                icon: "exclamationmark.triangle.fill",
                iconColor: .axError
            )

            masterSection
            serverSection
            databaseSection
            filesSection
            dockerSection
            otherSection
        }
    }

    // MARK: - Sections

    private var masterSection: some View {
        SettingsSection(title: "Master Control", icon: "power") {
            SettingsToggleRow(
                title: "Disable ALL Confirmations",
                subtitle: "Skip all delete/destructive confirmations",
                isOn: Binding(
                    get: { settings.disableAllConfirmations },
                    set: { newValue in
                        if newValue {
                            showDisableAllWarning = true
                        } else {
                            settings.disableAllConfirmations = false
                        }
                    }
                ),
                tint: .axError
            )
        }
        .overlay {
            if showDisableAllWarning {
                AXConfirmationDialog(
                    title: "Disable All Confirmations?",
                    message: "This will skip ALL delete and destructive confirmations. Actions will execute immediately without warning.",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .axError,
                    actionTitle: "Disable All",
                    actionColor: .axError,
                    note: "You can re-enable confirmations at any time.",
                    onConfirm: {
                        settings.disableAllConfirmations = true
                        showDisableAllWarning = false
                    },
                    onCancel: {
                        showDisableAllWarning = false
                    }
                )
            }
        }
    }

    private var serverSection: some View {
        SettingsSection(title: "Server", icon: "server.rack") {
            SettingsToggleRow(
                title: "Confirm Server Delete",
                subtitle: "Show confirmation before removing a server",
                isOn: $settings.confirmDeleteServer
            )
            SettingsToggleRow(
                title: "Confirm Server Disconnect",
                subtitle: "Ask before disconnecting from a server",
                isOn: $settings.confirmDisconnectServer
            )
        }
    }

    private var databaseSection: some View {
        SettingsSection(title: "Database", icon: "cylinder") {
            SettingsToggleRow(
                title: "Confirm Drop Table",
                subtitle: "Ask before dropping database tables",
                isOn: $settings.confirmDropDBTable
            )
            SettingsToggleRow(
                title: "Confirm Drop Database",
                subtitle: "Ask before dropping entire databases",
                isOn: $settings.confirmDropDBDatabase
            )
            SettingsToggleRow(
                title: "Confirm Delete Rows",
                subtitle: "Ask before deleting database rows",
                isOn: $settings.confirmDeleteDBRow
            )
            SettingsToggleRow(
                title: "Confirm Truncate Table",
                subtitle: "Ask before truncating table data",
                isOn: $settings.confirmTruncateTable
            )
        }
    }

    private var filesSection: some View {
        SettingsSection(title: "Files", icon: "folder") {
            SettingsToggleRow(
                title: "Confirm File Delete",
                subtitle: "Ask before deleting files via SFTP",
                isOn: $settings.confirmDeleteFile2
            )
            SettingsToggleRow(
                title: "Confirm Folder Delete",
                subtitle: "Ask before deleting folders via SFTP",
                isOn: $settings.confirmDeleteFolder
            )
        }
    }

    private var dockerSection: some View {
        SettingsSection(title: "Docker", icon: "shippingbox") {
            SettingsToggleRow(
                title: "Confirm Container Remove",
                subtitle: "Ask before removing Docker containers",
                isOn: $settings.confirmDeleteDockerContainer
            )
            SettingsToggleRow(
                title: "Confirm Image Remove",
                subtitle: "Ask before removing Docker images",
                isOn: $settings.confirmDeleteDockerImage
            )
            SettingsToggleRow(
                title: "Confirm System Prune",
                subtitle: "Ask before pruning Docker system resources",
                isOn: $settings.confirmDockerPrune
            )
        }
    }

    private var otherSection: some View {
        SettingsSection(title: "Other", icon: "ellipsis.circle") {
            SettingsToggleRow(
                title: "Confirm Website Delete",
                subtitle: "Ask before deleting websites",
                isOn: $settings.confirmDeleteWebsite
            )
            SettingsToggleRow(
                title: "Confirm Cron Job Delete",
                subtitle: "Ask before deleting cron jobs",
                isOn: $settings.confirmDeleteCronJob
            )
            SettingsToggleRow(
                title: "Confirm FTP User Delete",
                subtitle: "Ask before deleting FTP users",
                isOn: $settings.confirmDeleteFTPUser
            )
            SettingsToggleRow(
                title: "Confirm Plugin Uninstall",
                subtitle: "Ask before uninstalling plugins",
                isOn: $settings.confirmUninstallPlugin
            )
            SettingsToggleRow(
                title: "Confirm SSH Key Remove",
                subtitle: "Ask before removing SSH keys",
                isOn: $settings.confirmDeleteSSHKey
            )
        }
    }
}
