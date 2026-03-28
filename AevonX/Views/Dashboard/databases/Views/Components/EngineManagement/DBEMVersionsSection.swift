//
//  DBEMVersionsSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEMVersionsSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text(L10n.Engine.versions)
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Button(action: { Task { await viewModel.fetchAvailableVersions() } }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .font(AXTypography.subheadline)
                            Text(L10n.Button.refresh)
                                .font(AXTypography.subheadline)
                        }
                        .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isOperationInProgress)
                }

                // Current Version
                AXGlassCard(accentColor: .axAccentBlue) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text(L10n.Engine.currentVersion)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        HStack {
                            Text(viewModel.formattedVersion)
                                .font(AXTypography.title3)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Text(viewModel.isRunning ? L10n.Status.active : L10n.Status.stopped)
                                .font(AXTypography.caption)
                                .foregroundColor(viewModel.isRunning ? .axSuccess : .axWarning)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, AXSpacing.xxs)
                                .background((viewModel.isRunning ? Color.axSuccess : Color.axWarning).opacity(0.1))
                                .cornerRadius(AXCornerRadius.full)
                        }
                    }
                    .padding(AXSpacing.lg)
                }

                // Available Versions
                AXGlassCard(accentColor: .axAccentBlue) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text(L10n.Engine.availableVersions)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button(L10n.Engine.updateToLatest) {
                                viewModel.showUpdateConfirmation()
                            }
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .padding(.horizontal, AXSpacing.md)
                            .padding(.vertical, AXSpacing.sm)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        if viewModel.isFetchingVersions {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(AXSpacing.xl)
                                Spacer()
                            }
                        } else if viewModel.availableVersions.isEmpty {
                            VStack(spacing: AXSpacing.md) {
                                Text(L10n.Engine.noVersionsFetched)
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextMuted)

                                Button(L10n.Engine.fetchAvailableVersions) {
                                    Task { await viewModel.fetchAvailableVersions() }
                                }
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axAccentBlue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AXSpacing.lg)
                        } else {
                            ForEach(viewModel.availableVersions) { version in
                                HStack(spacing: AXSpacing.md) {
                                    VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                                        HStack(spacing: AXSpacing.sm) {
                                            Text(version.version)
                                                .font(AXTypography.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.axTextPrimary)

                                            if version.isLTS {
                                                Text(L10n.Engine.lts)
                                                    .font(AXTypography.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.axAccentBlue)
                                                    .padding(.horizontal, AXSpacing.xs)
                                                    .padding(.vertical, AXSpacing.xxxs)
                                                    .background(Color.axAccentBlue.opacity(0.15))
                                                    .cornerRadius(AXCornerRadius.xs)
                                            }

                                            if version.isRecommended {
                                                Text(L10n.Engine.recommended)
                                                    .font(AXTypography.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.axAccentGreen)
                                                    .padding(.horizontal, AXSpacing.xs)
                                                    .padding(.vertical, AXSpacing.xxxs)
                                                    .background(Color.axAccentGreen.opacity(0.15))
                                                    .cornerRadius(AXCornerRadius.xs)
                                            }

                                            if version.version == viewModel.engineInfo?.version {
                                                Text(L10n.Engine.installed)
                                                    .font(AXTypography.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.axTextMuted)
                                                    .padding(.horizontal, AXSpacing.xs)
                                                    .padding(.vertical, AXSpacing.xxxs)
                                                    .background(Color.axTextMuted.opacity(0.15))
                                                    .cornerRadius(AXCornerRadius.xs)
                                            }
                                        }

                                        if let date = version.releaseDate {
                                            Text(L10n.Engine.releasedDate(date))
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextMuted)
                                        }
                                    }

                                    Spacer()

                                    if version.version != viewModel.engineInfo?.version {
                                        Button(L10n.Button.install) {
                                            viewModel.showInstallConfirmation(version: version)
                                        }
                                        .font(AXTypography.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.axAccentBlue)
                                        .padding(.horizontal, AXSpacing.md)
                                        .padding(.vertical, AXSpacing.xs)
                                        .background(Color.axAccentBlue.opacity(0.1))
                                        .cornerRadius(AXCornerRadius.md)
                                        .buttonStyle(.plain)
                                        .disabled(viewModel.isOperationInProgress)
                                    }
                                }
                                .padding(.vertical, AXSpacing.sm)

                                if version.id != viewModel.availableVersions.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            }
            .padding(AXSpacing.xl)
        }
        .onAppear {
            if viewModel.availableVersions.isEmpty {
                Task { await viewModel.fetchAvailableVersions() }
            }
        }
    }
}
