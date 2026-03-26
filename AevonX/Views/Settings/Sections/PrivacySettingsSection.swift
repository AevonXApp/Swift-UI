//
//  PrivacySettingsSection.swift
//  AevonX
//
//  Privacy settings: information masking, behavior, preview
//

import SwiftUI

struct PrivacySettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Privacy",
                description: "Control what's visible on screen",
                icon: "eye.slash",
                iconColor: .axAccentPurple
            )

            maskingSection
            behaviorSection
        }
    }

    // MARK: - Sections

    private var maskingSection: some View {
        SettingsSection(title: "Information Masking", icon: "eye.slash") {
            SettingsToggleRow(
                title: "Mask Sensitive Info",
                subtitle: "Master toggle for all masking",
                isOn: $settings.maskServerInfo,
                tint: .axAccentPurple
            )

            if settings.maskServerInfo {
                SettingsToggleRow(
                    title: "Mask IP Addresses",
                    subtitle: "192.168.0.1 → 192.***.***.1",
                    isOn: $settings.maskIPAddresses
                )
                SettingsToggleRow(
                    title: "Mask Usernames",
                    subtitle: "admin → a***n",
                    isOn: $settings.maskUsernames
                )
                SettingsToggleRow(
                    title: "Mask Database Names",
                    subtitle: "prod_db → p***_**",
                    isOn: $settings.maskDatabaseNames
                )
                SettingsToggleRow(
                    title: "Mask Port Numbers",
                    subtitle: "22 → **",
                    isOn: $settings.maskPortNumbers
                )
            }
        }
    }

    private var behaviorSection: some View {
        SettingsSection(title: "Behavior", icon: "hand.raised") {
            SettingsToggleRow(
                title: "Mask in Dashboard",
                subtitle: "Also mask info inside server dashboard",
                isOn: $settings.maskInDashboard
            )
        }
    }
}
