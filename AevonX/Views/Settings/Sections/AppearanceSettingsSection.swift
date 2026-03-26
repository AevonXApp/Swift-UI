//
//  AppearanceSettingsSection.swift
//  AevonX
//
//  Appearance settings: theme selection
//

import SwiftUI

struct AppearanceSettingsSection: View {
    @EnvironmentObject var settings: AppSettingsManager
    @ObservedObject private var themeEngine = ThemeEngine.shared

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            SettingsSectionHeader(
                title: "Appearance",
                description: "Theme & visual style",
                icon: "paintbrush.fill",
                iconColor: .axAccentBlue
            )

            themeSection
        }
    }

    // MARK: - Sections

    private var themeSection: some View {
        SettingsSection(title: "Theme", icon: "paintbrush") {
            themeGrid
        }
    }

    private var themeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AXSpacing.md) {
            ForEach(AXTheme.allBuiltIn) { theme in
                ThemePreviewCard(
                    theme: theme,
                    isSelected: settings.theme == theme.id,
                    onSelect: {
                        settings.theme = theme.id
                        themeEngine.setTheme(theme)
                    }
                )
            }
        }
    }
}

// MARK: - Theme Preview Card

struct ThemePreviewCard: View {
    let theme: AXTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: AXSpacing.sm) {
                // Mini preview
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .fill(Color(hex: theme.background))
                    .frame(height: 60)
                    .overlay {
                        VStack(spacing: AXSpacing.xxs) {
                            HStack(spacing: AXSpacing.xxs) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: theme.surface))
                                    .frame(width: 30, height: 20)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: theme.surface))
                                    .frame(height: 20)
                            }
                            HStack(spacing: AXSpacing.xxs) {
                                Circle()
                                    .fill(Color(hex: theme.accentPrimary))
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(Color(hex: theme.accentSecondary))
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(Color(hex: theme.success))
                                    .frame(width: 8, height: 8)
                                Spacer()
                            }
                        }
                        .padding(AXSpacing.sm)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .stroke(
                                isSelected ? Color(hex: theme.accentPrimary) : Color(hex: theme.border),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                Text(theme.name)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextPrimary)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.axAccentBlue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
