//
//  DBEMSidebar.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEMSidebar: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            sidebarHeader

            Divider()

            // Navigation Sections
            ScrollView {
                VStack(spacing: AXSpacing.xs) {
                    ForEach(DatabaseEngineDetailViewModel.Section.allCases) { section in
                        // Skip Access section for Redis as it doesn't support user management
                        if section != .access || viewModel.databaseType != .redis {
                            NavigationRow(
                                title: section.rawValue,
                                icon: section.icon,
                                isSelected: viewModel.currentSection == section,
                                themeColor: .axAccentBlue
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.currentSection = section
                                }
                            }
                        }
                    }
                }
                .padding(AXSpacing.md)
            }

            Spacer()

            // Service Status Footer
            serviceStatusFooter
        }
    }

    private var sidebarHeader: some View {
        VStack(spacing: AXSpacing.lg) {
            // Back Button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "chevron.left")
                        Text("Back to Databases")
                    }
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)

                Spacer()
            }

            // Engine Info
            HStack(spacing: AXSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                        .fill(Color.axAccentBlue.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: viewModel.databaseType.iconName)
                        .font(AXTypography.title)
                        .foregroundColor(.axAccentBlue)
                }

                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(viewModel.databaseType.displayName)
                        .font(AXTypography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Text(viewModel.formattedVersion)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()
            }
        }
        .padding(AXSpacing.lg)
    }

    private var serviceStatusFooter: some View {
        VStack(spacing: AXSpacing.md) {
            Divider()

            HStack(spacing: AXSpacing.sm) {
                Circle()
                    .fill(viewModel.statusColor)
                    .frame(width: 8, height: 8)

                Text(viewModel.engineInfo?.status.rawValue.capitalized ?? "Unknown")
                    .font(AXTypography.caption)
                    .foregroundColor(viewModel.statusColor)

                Spacer()
            }

            // Quick Service Controls — wired to confirmations
            HStack(spacing: AXSpacing.sm) {
                ServiceButton(
                    icon: "play.fill",
                    color: .axSuccess,
                    isEnabled: !viewModel.isRunning && !viewModel.isOperationInProgress
                ) {
                    viewModel.showStartConfirmation()
                }

                ServiceButton(
                    icon: "stop.fill",
                    color: .axError,
                    isEnabled: viewModel.isRunning && !viewModel.isOperationInProgress
                ) {
                    viewModel.showStopConfirmation()
                }

                ServiceButton(
                    icon: "arrow.clockwise",
                    color: .axWarning,
                    isEnabled: viewModel.isRunning && !viewModel.isOperationInProgress
                ) {
                    viewModel.showRestartConfirmation()
                }
            }
        }
        .padding(AXSpacing.lg)
    }
}

// MARK: - Helper Views

private struct NavigationRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.md) {
                Image(systemName: icon)
                    .font(AXTypography.title3)
                    .foregroundColor(isSelected ? themeColor : .axTextMuted)
                    .frame(width: 24)

                Text(title)
                    .font(AXTypography.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .axTextPrimary : .axTextSecondary)

                Spacer()
            }
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? themeColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isSelected ? themeColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ServiceButton: View {
    let icon: String
    let color: Color
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(AXTypography.subheadline)
                .foregroundColor(isEnabled ? color : .axTextMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(isEnabled ? color.opacity(0.1) : Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
