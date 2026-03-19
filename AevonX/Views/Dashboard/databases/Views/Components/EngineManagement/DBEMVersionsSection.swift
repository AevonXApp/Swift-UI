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
                    Text("Versions")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()

                    Button(action: { Task { await viewModel.fetchAvailableVersions() } }) {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.clockwise")
                                .font(AXTypography.subheadline)
                            Text("Refresh")
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
                        Text("Current Version")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        HStack {
                            Text(viewModel.formattedVersion)
                                .font(AXTypography.title3)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Text(viewModel.isRunning ? "Active" : "Stopped")
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
                            Text("Available Versions")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button("Update to Latest") {
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
                                Text("No versions fetched yet.")
                                    .font(AXTypography.subheadline)
                                    .foregroundColor(.axTextMuted)

                                Button("Fetch Available Versions") {
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
                                                Text("LTS")
                                                    .font(AXTypography.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.axAccentBlue)
                                                    .padding(.horizontal, AXSpacing.xs)
                                                    .padding(.vertical, AXSpacing.xxxs)
                                                    .background(Color.axAccentBlue.opacity(0.15))
                                                    .cornerRadius(AXCornerRadius.xs)
                                            }

                                            if version.isRecommended {
                                                Text("Recommended")
                                                    .font(AXTypography.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.axAccentGreen)
                                                    .padding(.horizontal, AXSpacing.xs)
                                                    .padding(.vertical, AXSpacing.xxxs)
                                                    .background(Color.axAccentGreen.opacity(0.15))
                                                    .cornerRadius(AXCornerRadius.xs)
                                            }

                                            if version.version == viewModel.engineInfo?.version {
                                                Text("Installed")
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
                                            Text("Released \(date, style: .date)")
                                                .font(AXTypography.caption)
                                                .foregroundColor(.axTextMuted)
                                        }
                                    }

                                    Spacer()

                                    if version.version != viewModel.engineInfo?.version {
                                        Button("Install") {
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
