//
//  KeyboardSettingsSection.swift
//  AevonX
//
//  Keyboard shortcuts settings (display only for now)
//

import SwiftUI

struct KeyboardSettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Keyboard Shortcuts",
                description: "Customize keyboard shortcuts",
                icon: "keyboard"
            )

            navigationSection
            serverSection
            editorSection
        }
    }

    private var navigationSection: some View {
        SettingsSection(title: "Navigation", icon: "arrow.left.arrow.right") {
            shortcutRow("Remote Fleet", shortcut: "Cmd+1")
            shortcutRow("Profile", shortcut: "Cmd+3")
            shortcutRow("Settings", shortcut: "Cmd+,")
        }
    }

    private var serverSection: some View {
        SettingsSection(title: "Server", icon: "server.rack") {
            shortcutRow("New Connection", shortcut: "Cmd+N")
            shortcutRow("Disconnect", shortcut: "Cmd+Shift+D")
            shortcutRow("Open Terminal", shortcut: "Cmd+T")
        }
    }

    private var editorSection: some View {
        SettingsSection(title: "Editor", icon: "doc.text") {
            shortcutRow("Save File", shortcut: "Cmd+S")
            shortcutRow("Find", shortcut: "Cmd+F")
        }
    }

    private func shortcutRow(_ title: String, shortcut: String) -> some View {
        HStack {
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)

            Spacer()

            Text(shortcut)
                .font(AXTypography.monoSm)
                .foregroundColor(.axTextSecondary)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xxs)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)
        }
    }
}
