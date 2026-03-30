//
//  UpdateManagementSection.swift
//  AevonX
//
//  Package updates — manual check, security badges, package list, actions.
//

import SwiftUI

struct UpdateManagementSection: View {
    @ObservedObject var vm: ServerSettingsViewModel
    @State private var isExpanded = true
    @State private var hasChecked = false

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                if isExpanded {
                    Divider().background(Color.axBorder)

                    if !hasChecked && !vm.isCheckingUpdates {
                        checkPrompt
                    } else if vm.isCheckingUpdates {
                        checkingView
                    } else {
                        resultsView
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        CollapsibleSectionHeader(
            icon: "arrow.down.circle.fill", title: L10n.ServerSettings.systemUpdates,
            subtitle: L10n.ServerSettings.packageUpdates, gradient: [.axWarning, .orange.opacity(0.7)],
            isExpanded: $isExpanded
        )
    }

    // MARK: - Check Prompt (before first check)

    private var checkPrompt: some View {
        VStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(AXTypography.title3)
                    .foregroundColor(.axTextMuted)
                VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                    Text(L10n.ServerSettings.checkForUpdates)
                        .font(AXTypography.subheadline).fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)
                    Text(L10n.ServerSettings.checkForUpdatesDesc)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                Spacer()
                Button(action: { runCheck() }) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "magnifyingglass")
                        Text(L10n.ServerSettings.checkNow)
                    }
                    .font(AXTypography.caption).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg).padding(.vertical, AXSpacing.xs)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, AXSpacing.xs)
    }

    // MARK: - Checking View (spinner)

    private var checkingView: some View {
        HStack(spacing: AXSpacing.sm) {
            ProgressView().scaleEffect(0.8)
            Text(L10n.ServerSettings.checkingUpdates)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, AXSpacing.lg)
    }

    // MARK: - Results View

    private var resultsView: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            summaryBadges

            if !vm.availablePackages.isEmpty {
                packageList
            }

            actionButtons

            if let msg = vm.updateMessage {
                SettingsInlineMsg(text: msg.0, isSuccess: msg.1)
            }
        }
    }

    // MARK: - Summary Badges

    private var summaryBadges: some View {
        HStack(spacing: AXSpacing.sm) {
            if vm.securityUpdatesCount > 0 {
                ServerSettingsBadge(text: L10n.ServerSettings.securityCount(vm.securityUpdatesCount), color: .axError, icon: "shield.fill")
            }
            ServerSettingsBadge(
                text: vm.updatesAvailable > 0 ? L10n.ServerSettings.totalCount(vm.updatesAvailable) : L10n.ServerSettings.upToDate,
                color: vm.updatesAvailable > 0 ? .axWarning : .axSuccess,
                icon: vm.updatesAvailable > 0 ? "exclamationmark.circle" : "checkmark.circle"
            )
            Spacer()
            Button(action: { runCheck() }) {
                Image(systemName: "arrow.clockwise")
                    .font(AXTypography.caption).foregroundColor(.axAccentBlue)
            }.buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Package List

    private var packageList: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            ForEach(vm.availablePackages.prefix(20)) { pkg in
                UpdatePackageRow(vm: vm, pkg: pkg)
            }
            if vm.availablePackages.count > 20 {
                Text(L10n.ServerSettings.morePackages(vm.availablePackages.count - 20))
                    .font(AXTypography.caption2).foregroundColor(.axTextMuted)
                    .padding(.top, AXSpacing.xxs)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: AXSpacing.sm) {
            if vm.securityUpdatesCount > 0 {
                Button(action: { Task { await vm.updateSecurityOnly() } }) {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "shield.fill")
                        Text(L10n.ServerSettings.securityOnly(vm.securityUpdatesCount))
                    }
                    .font(AXTypography.caption).fontWeight(.medium)
                    .foregroundColor(.axError)
                    .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.xs)
                    .background(Color.axError.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }.buttonStyle(PlainButtonStyle())
            }
            if vm.updatesAvailable > 0 {
                Button(action: { Task { await vm.upgradeSystem() } }) {
                    HStack(spacing: AXSpacing.xxs) {
                        if vm.isUpgrading { ProgressView().scaleEffect(0.5) }
                        else { Image(systemName: "arrow.down.circle") }
                        Text(L10n.ServerSettings.updateAll(vm.updatesAvailable))
                    }
                    .font(AXTypography.caption).fontWeight(.medium)
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.md).padding(.vertical, AXSpacing.xs)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(vm.isUpgrading)
            }
        }
    }

    // MARK: - Actions

    private func runCheck() {
        hasChecked = true
        Task { await vm.checkUpdatesWithList() }
    }
}
