//
//  SettingsView.swift
//  AevonX
//
//  Global Settings view
//

import SwiftUI
import AevonXCore


struct SettingsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(AXTypography.largeTitle)
                    .foregroundColor(.axTextPrimary)
                
                Spacer()
            }
            .padding(AXSpacing.xl)
            
            Divider()
                .background(Color.axBorder)
            
            // Settings Tabs
            HStack(spacing: 0) {
                // Sidebar
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    AXSidebarTabRow(
                        icon: "gearshape",
                        title: "General",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    AXSidebarTabRow(
                        icon: "paintbrush",
                        title: "Appearance",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    AXSidebarTabRow(
                        icon: "bell",
                        title: "Notifications",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    
                    AXSidebarTabRow(
                        icon: "network",
                        title: "Network",
                        isSelected: selectedTab == 3,
                        action: { selectedTab = 3 }
                    )
                    
                    AXSidebarTabRow(
                        icon: "lock.shield",
                        title: "Security",
                        isSelected: selectedTab == 4,
                        action: { selectedTab = 4 }
                    )
                    
                    Spacer()
                    
                    // About Section
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Divider()
                            .background(Color.axBorder)
                        
                        AXSidebarTabRow(
                            icon: "info.circle",
                            title: "About",
                            isSelected: selectedTab == 5,
                            action: { selectedTab = 5 }
                        )
                    }
                }
                .frame(width: 200)
                .padding(.top, AXSpacing.lg)
                .background(Color.axBackgroundSecondary)
                
                Divider()
                    .background(Color.axBorder)
                
                // Content
                ScrollView {
                    VStack(spacing: AXSpacing.xl) {
                        switch selectedTab {
                        case 0:
                            GeneralSettings()
                        case 1:
                            AppearanceSettings()
                        case 2:
                            NotificationSettings()
                        case 3:
                            NetworkSettings()
                        case 4:
                            SecuritySettings()
                        case 5:
                            AboutSettings()
                        default:
                            GeneralSettings()
                        }
                    }
                    .padding(AXSpacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.axBackground)
            }
        }
        .background(Color.axBackground)
        .frame(minWidth: 800, minHeight: 600)
    }
}



// MARK: - Settings Sections

struct GeneralSettings: View {
    @State private var launchAtLogin = true
    @State private var checkUpdates = true
    @State private var autoSave = true
    @State private var defaultTerminal = "Terminal"
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSection(title: "Startup", icon: "power") {
                ToggleRow(title: "Launch at Login", isOn: $launchAtLogin)
                ToggleRow(title: "Check for Updates", isOn: $checkUpdates)
            }
            
            SettingsSection(title: "Behavior", icon: "gearshape") {
                ToggleRow(title: "Auto-save Connections", isOn: $autoSave)
                
                HStack {
                    Text("Default Terminal")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                    
                    Spacer()
                    
                    Picker("", selection: $defaultTerminal) {
                        Text("Terminal").tag("Terminal")
                        Text("iTerm").tag("iTerm")
                        Text("Warp").tag("Warp")
                        Text("Kitty").tag("Kitty")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150)
                }
            }
            
            SettingsSection(title: "Data", icon: "externaldrive") {
                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text("Export Configuration")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        
                        Text("Export all settings and server configurations")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("Export...")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text("Reset to Defaults")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        
                        Text("Clear all settings and restore defaults")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("Reset...")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axError)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct AppearanceSettings: View {
    @State private var selectedTheme = 0
    @State private var sidebarStyle = 0
    @State private var fontSize = 14.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSection(title: "Theme", icon: "paintbrush") {
                Picker("Appearance", selection: $selectedTheme) {
                    Text("Dark").tag(0)
                    Text("Light").tag(1)
                    Text("Auto").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Picker("Sidebar Style", selection: $sidebarStyle) {
                    Text("Compact").tag(0)
                    Text("Expanded").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            SettingsSection(title: "Typography", icon: "textformat") {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Text("Font Size")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
                        Text("\(Int(fontSize))px")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    Slider(value: $fontSize, in: 12...18, step: 1)
                }
            }
            
            SettingsSection(title: "Accent Color", icon: "paintpalette") {
                HStack(spacing: AXSpacing.md) {
                    ColorPickerButton(color: .axAccentBlue, isSelected: true)
                    ColorPickerButton(color: .axAccentGreen, isSelected: false)
                    ColorPickerButton(color: .axWarning, isSelected: false)
                    ColorPickerButton(color: .axError, isSelected: false)
                }
            }
        }
    }
}

struct ColorPickerButton: View {
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        Button(action: {}) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.axTextPrimary : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationSettings: View {
    @State private var serverAlerts = true
    @State private var deploymentNotifications = true
    @State private var updateAlerts = true
    @State private var dailyDigest = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSection(title: "Notifications", icon: "bell") {
                ToggleRow(title: "Server Status Alerts", isOn: $serverAlerts)
                ToggleRow(title: "Deployment Notifications", isOn: $deploymentNotifications)
                ToggleRow(title: "App Update Alerts", isOn: $updateAlerts)
                ToggleRow(title: "Daily Digest Email", isOn: $dailyDigest)
            }
        }
    }
}

struct NetworkSettings: View {
    @State private var connectionTimeout = 30.0
    @State private var maxRetries = 3
    @State private var useProxy = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSection(title: "Connection", icon: "network") {
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Text("Connection Timeout")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
                        Text("\(Int(connectionTimeout))s")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    Slider(value: $connectionTimeout, in: 5...120, step: 5)
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    HStack {
                        Text("Max Retries")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        
                        Spacer()
                        
                        Text("\(maxRetries)")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    Slider(value: .init(
                        get: { Double(maxRetries) },
                        set: { maxRetries = Int($0) }
                    ), in: 0...10, step: 1)
                }
            }
            
            SettingsSection(title: "Proxy", icon: "globe") {
                ToggleRow(title: "Use Proxy", isOn: $useProxy)
            }
        }
    }
}

struct SecuritySettings: View {
    @State private var biometricAuth = true
    @State private var lockOnSleep = true
    @State private var clearClipboard = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSection(title: "Authentication", icon: "lock") {
                ToggleRow(title: "Biometric Authentication", isOn: $biometricAuth)
                ToggleRow(title: "Lock on Sleep", isOn: $lockOnSleep)
            }
            
            SettingsSection(title: "Privacy", icon: "hand.raised") {
                ToggleRow(title: "Clear Clipboard on Exit", isOn: $clearClipboard)
                
                HStack {
                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                        Text("Clear All Data")
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                        
                        Text("Remove all stored credentials and history")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextTertiary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("Clear...")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axError)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct AboutSettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            HStack(spacing: AXSpacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                        .fill(Color.axAccentBlue.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.axAccentBlue)
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    Text("AevonX")
                        .font(AXTypography.title)
                        .foregroundColor(.axTextPrimary)
                    
                    Text("Version 1.0.0 (Build 2024.1)")
                        .font(AXTypography.callout)
                        .foregroundColor(.axTextSecondary)
                    
                    Text("© 2024 AevonX Inc. All rights reserved.")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
            }
            
            SettingsSection(title: "Links", icon: "link") {
                LinkRow(title: "Website",       url: AppURLs.website.absoluteString)
                LinkRow(title: "Documentation",  url: AppURLs.docs.absoluteString)
                LinkRow(title: "GitHub", url: "https://github.com/aevonxapp")
                LinkRow(title: "Twitter", url: "https://twitter.com/aevonxapp")
            }
            
            SettingsSection(title: "Legal", icon: "doc.text") {
                ButtonRow(title: "Privacy Policy")
                ButtonRow(title: "Terms of Service")
                ButtonRow(title: "License Agreement")
            }
        }
    }
}

// MARK: - Helper Views

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.lg) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.axAccentBlue)
                
                Text(title)
                    .font(AXTypography.headline)
                    .foregroundColor(.axTextPrimary)
            }
            
            AXCard {
                VStack(spacing: AXSpacing.md) {
                    content
                }
            }
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .axAccentBlue))
                .frame(width: 40)
        }
    }
}

struct LinkRow: View {
    let title: String
    let url: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            
            Spacer()
            
            Link(destination: URL(string: url)!) {
                HStack(spacing: AXSpacing.xs) {
                    Text(url.replacingOccurrences(of: "https://", with: ""))
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                        .foregroundColor(.axAccentBlue)
                }
            }
        }
    }
}

struct ButtonRow: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    SettingsView()
        .background(Color.axBackground)
}
