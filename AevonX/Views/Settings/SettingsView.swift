//
//  SettingsView.swift
//  AevonX
//
//  Global Settings view with sidebar navigation and 14 sections
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Settings Tab

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case security
    case privacy
    case appearance
    case serverList
    case dashboard
    case terminal
    case fileManager
    case database
    case network
    case notifications
    case confirmations
    case keyboard
    case dataStorage
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return L10n.Settings.tabGeneral
        case .security: return L10n.Settings.tabSecurity
        case .privacy: return L10n.Settings.tabPrivacy
        case .appearance: return L10n.Settings.tabAppearance
        case .serverList: return L10n.Settings.tabServerList
        case .dashboard: return L10n.Settings.tabDashboard
        case .terminal: return L10n.Settings.tabTerminal
        case .fileManager: return L10n.Settings.tabFileManager
        case .database: return L10n.Settings.tabDatabase
        case .network: return L10n.Settings.tabNetwork
        case .notifications: return L10n.Settings.tabNotifications
        case .confirmations: return L10n.Settings.tabConfirmations
        case .keyboard: return L10n.Settings.tabKeyboard
        case .dataStorage: return L10n.Settings.tabDataStorage
        case .about: return L10n.Settings.tabAbout
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .security: return "lock.shield"
        case .privacy: return "eye.slash"
        case .appearance: return "paintbrush"
        case .serverList: return "server.rack"
        case .dashboard: return "gauge.with.dots.needle.67percent"
        case .terminal: return "terminal"
        case .fileManager: return "folder"
        case .database: return "cylinder.split.1x2"
        case .network: return "network"
        case .notifications: return "bell"
        case .confirmations: return "exclamationmark.triangle"
        case .keyboard: return "keyboard"
        case .dataStorage: return "externaldrive"
        case .about: return "info.circle"
        }
    }

    var isBottomSection: Bool {
        self == .dataStorage || self == .about
    }

    static var mainTabs: [SettingsTab] {
        allCases.filter { !$0.isBottomSection }
    }

    static var bottomTabs: [SettingsTab] {
        allCases.filter { $0.isBottomSection }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettingsManager
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            settingsHeader

            Divider()
                .background(Color.axBorder)

            HStack(spacing: 0) {
                settingsSidebar

                Divider()
                    .background(Color.axBorder)

                settingsContent
            }
        }
        .background(Color.axBackground)
        .frame(minWidth: 900, minHeight: 650)
    }

    // MARK: - Header

    private var settingsHeader: some View {
        HStack {
            Text(L10n.Settings.title)
                .font(AXTypography.largeTitle)
                .foregroundColor(.axTextPrimary)

            Spacer()
        }
        .padding(AXSpacing.xl)
    }

    // MARK: - Sidebar

    private var settingsSidebar: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    ForEach(SettingsTab.mainTabs) { tab in
                        AXSidebarTabRow(
                            icon: tab.icon,
                            title: tab.title,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                }
                .padding(.top, AXSpacing.lg)
                .padding(.bottom, AXSpacing.sm)
            }

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Divider()
                    .background(Color.axBorder)

                ForEach(SettingsTab.bottomTabs) { tab in
                    AXSidebarTabRow(
                        icon: tab.icon,
                        title: tab.title,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }
            .padding(.bottom, AXSpacing.lg)
        }
        .frame(width: 220)
        .background(Color.axBackgroundSecondary)
    }

    // MARK: - Content

    private var settingsContent: some View {
        ScrollView {
            settingsContentSwitch
                .padding(AXSpacing.xl)
                .frame(maxWidth: 700, alignment: .leading)
                .frame(maxWidth: .infinity)
        }
        .background(Color.axBackground)
    }

    @ViewBuilder
    private var settingsContentSwitch: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsSection()
        case .security:
            SecuritySettingsSection()
        case .privacy:
            PrivacySettingsSection()
        case .appearance:
            AppearanceSettingsSection()
        case .serverList:
            ServerListSettingsSection()
        case .dashboard:
            DashboardSettingsSection()
        case .terminal:
            TerminalSettingsSection()
        case .fileManager:
            FileManagerSettingsSection()
        case .database:
            DatabaseSettingsSection()
        case .network:
            NetworkSettingsSection()
        case .notifications:
            NotificationSettingsSection()
        case .confirmations:
            ConfirmationSettingsSection()
        case .keyboard:
            KeyboardSettingsSection()
        case .dataStorage:
            DataStorageSettingsSection()
        case .about:
            AboutSettingsSection()
        }
    }
}

// MARK: - Helper Views (kept for backward compatibility)

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

#Preview {
    SettingsView()
        .environmentObject(AppSettingsManager.shared)
        .background(Color.axBackground)
}
