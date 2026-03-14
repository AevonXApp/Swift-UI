//
//  TerminalSettingsSheet.swift
//  AevonX
//
//  Terminal appearance and behavior settings
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Terminal Settings Sheet

struct TerminalSettingsSheet: View {
    @ObservedObject var viewModel: TerminalViewModel
    @ObservedObject var preferences: TerminalPreferences
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.axAccentBlue)
                    Text("Terminal Settings")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AXSpacing.lg)
            
            Divider().background(Color.axBorder)
            
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    
                    // MARK: - Theme Section
                    settingsSection("Theme") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AXSpacing.sm) {
                            ForEach(TerminalTheme.allThemes) { theme in
                                themeCard(theme)
                            }
                        }
                    }
                    
                    // MARK: - Font Section
                    settingsSection("Font") {
                        VStack(spacing: AXSpacing.md) {
                            // Font family
                            HStack {
                                Text("Font Family")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                Picker("", selection: $preferences.fontName) {
                                    ForEach(TerminalFontFamily.allCases) { f in
                                        Text(f.rawValue).tag(f.fontName)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 160)
                            }
                            
                            // Font size
                            HStack {
                                Text("Font Size")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                HStack(spacing: AXSpacing.sm) {
                                    Button(action: { preferences.fontSize = max(10, preferences.fontSize - 1) }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 10, weight: .bold))
                                            .frame(width: 24, height: 24)
                                            .background(Color.axBackgroundTertiary)
                                            .cornerRadius(AXCornerRadius.sm)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text("\(Int(preferences.fontSize))pt")
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundColor(.axTextPrimary)
                                        .frame(width: 40)
                                    
                                    Button(action: { preferences.fontSize = min(24, preferences.fontSize + 1) }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                            .frame(width: 24, height: 24)
                                            .background(Color.axBackgroundTertiary)
                                            .cornerRadius(AXCornerRadius.sm)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    // MARK: - Cursor Section
                    settingsSection("Cursor") {
                        VStack(spacing: AXSpacing.md) {
                            HStack {
                                Text("Style")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                Picker("", selection: $preferences.cursorStyleRaw) {
                                    ForEach(TerminalCursorStyle.allCases) { style in
                                        Text(style.rawValue).tag(style.rawValue)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                            }
                            
                            HStack {
                                Text("Cursor Blink")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                Toggle("", isOn: $preferences.cursorBlink)
                                    .toggleStyle(.switch)
                                    .tint(.axAccentBlue)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    // MARK: - Behavior Section
                    settingsSection("Behavior") {
                        VStack(spacing: AXSpacing.md) {
                            HStack {
                                Text("Scrollback Lines")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                Picker("", selection: $preferences.scrollbackLines) {
                                    Text("1,000").tag(1000)
                                    Text("5,000").tag(5000)
                                    Text("10,000").tag(10000)
                                    Text("50,000").tag(50000)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }
                            
                            HStack {
                                Text("Dangerous Command Warnings")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                Toggle("", isOn: $preferences.showDangerWarnings)
                                    .toggleStyle(.switch)
                                    .tint(.axAccentBlue)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Text("Auto Reconnect")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                Toggle("", isOn: $preferences.autoReconnect)
                                    .toggleStyle(.switch)
                                    .tint(.axAccentBlue)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Text("Command Timer")
                                    .font(AXTypography.body)
                                    .foregroundColor(.axTextSecondary)
                                Spacer()
                                Toggle("", isOn: $preferences.showCommandTimer)
                                    .toggleStyle(.switch)
                                    .tint(.axAccentBlue)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    // MARK: - Preview
                    settingsSection("Preview") {
                        let theme = preferences.theme
                        VStack(alignment: .leading, spacing: 4) {
                            Text("root@server:~$ ls -la")
                                .font(.system(size: CGFloat(preferences.fontSize), design: .monospaced))
                                .foregroundColor(theme.green)
                            Text("total 48")
                                .font(.system(size: CGFloat(preferences.fontSize), design: .monospaced))
                                .foregroundColor(theme.foreground)
                            Text("drwxr-xr-x  5 root root 4096 Feb 26 /var/www")
                                .font(.system(size: CGFloat(preferences.fontSize), design: .monospaced))
                                .foregroundColor(theme.blue)
                            Text("-rw-r--r--  1 root root  512 Feb 26 config.yml")
                                .font(.system(size: CGFloat(preferences.fontSize), design: .monospaced))
                                .foregroundColor(theme.foreground)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AXSpacing.md)
                        .background(theme.background)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(AXSpacing.xl)
            }
        }
        .frame(width: 500, height: 580)
        .background(Color.axBackground)
    }
    
    // MARK: - Helpers
    
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.axTextTertiary)
                .textCase(.uppercase)
                .tracking(0.8)
            
            content()
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
        }
    }
    
    private func themeCard(_ theme: TerminalTheme) -> some View {
        Button(action: { preferences.themeId = theme.id }) {
            VStack(spacing: AXSpacing.xs) {
                // Color preview
                HStack(spacing: 3) {
                    Circle().fill(theme.red).frame(width: 8, height: 8)
                    Circle().fill(theme.green).frame(width: 8, height: 8)
                    Circle().fill(theme.blue).frame(width: 8, height: 8)
                    Circle().fill(theme.yellow).frame(width: 8, height: 8)
                    Circle().fill(theme.magenta).frame(width: 8, height: 8)
                    Circle().fill(theme.cyan).frame(width: 8, height: 8)
                }
                .padding(.vertical, AXSpacing.sm)
                .padding(.horizontal, AXSpacing.md)
                .background(theme.background)
                .cornerRadius(AXCornerRadius.sm)
                
                Text(theme.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextSecondary)
            }
            .padding(AXSpacing.sm)
            .background(preferences.themeId == theme.id ? Color.axAccentBlue.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(preferences.themeId == theme.id ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
            )
            .cornerRadius(AXCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
