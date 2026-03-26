//
//  TerminalSettingsSection.swift
//  AevonX
//
//  Terminal settings: font, display, behavior
//  Writes directly to TerminalPreferences so changes take effect immediately
//

import SwiftUI

struct TerminalSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager
    @ObservedObject private var prefs = TerminalPreferences.shared

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Terminal",
                description: "Terminal emulator preferences",
                icon: "terminal.fill",
                iconColor: .axAccentGreen
            )

            fontSection
            displaySection
            behaviorSection
        }
    }

    private var fontSection: some View {
        SettingsSection(title: "Font", icon: "textformat") {
            SettingsPickerRow(
                title: "Font Family",
                selection: $prefs.fontName,
                options: [
                    (label: "SF Mono", value: "SFMono-Regular"),
                    (label: "Menlo", value: "Menlo"),
                    (label: "Fira Code", value: "FiraCode-Regular"),
                    (label: "JetBrains Mono", value: "JetBrainsMono-Regular"),
                    (label: "Courier New", value: "Courier New")
                ]
            )
            SettingsSliderRow(
                title: "Font Size",
                value: $prefs.fontSize,
                range: 10...24,
                step: 1,
                unit: "px"
            )
        }
    }

    private var displaySection: some View {
        SettingsSection(title: "Display", icon: "rectangle.on.rectangle") {
            SettingsStepperRow(
                title: "Scrollback Lines",
                value: $prefs.scrollbackLines,
                range: 1000...100000
            )
            SettingsSegmentedRow(
                title: "Cursor Style",
                selection: $prefs.cursorStyleRaw,
                options: [
                    (label: "Block", value: "Block"),
                    (label: "Underline", value: "Underline"),
                    (label: "I-Beam", value: "I-Beam")
                ]
            )
            SettingsToggleRow(
                title: "Cursor Blink",
                subtitle: "Animate the terminal cursor",
                isOn: $prefs.cursorBlink
            )
        }
    }

    private var behaviorSection: some View {
        SettingsSection(title: "Behavior", icon: "keyboard") {
            SettingsToggleRow(
                title: "Bell Sound",
                subtitle: "Play system beep on terminal bell",
                isOn: $settings.terminalBellSound
            )
            SettingsToggleRow(
                title: "Copy on Select",
                subtitle: "Automatically copy selected text",
                isOn: $settings.terminalCopyOnSelect
            )
        }
    }
}
