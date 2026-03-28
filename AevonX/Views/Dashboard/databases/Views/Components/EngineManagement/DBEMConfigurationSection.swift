//
//  DBEMConfigurationSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEMConfigurationSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text(L10n.Engine.configuration)
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()
                }

                // Config File Path
                AXGlassCard(accentColor: .axAccentBlue) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text(L10n.Engine.configurationFile)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button(L10n.Button.edit) {
                                Task {
                                    await viewModel.loadConfiguration()
                                    viewModel.configEditContent = viewModel.configuration?.rawContent ?? ""
                                    viewModel.showConfigEditor = true
                                }
                            }
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        Text(viewModel.configFilePath)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.axTextMuted)
                    }
                    .padding(AXSpacing.lg)
                }

                // Version Management
                AXGlassCard(accentColor: .axAccentBlue) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text(L10n.Engine.versionManagement)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button(L10n.Database.switchVersion) {
                                viewModel.showVersionSwitcher = true
                            }
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        DBEMInfoRow(label: L10n.Engine.currentVersion, value: viewModel.formattedVersion)

                        Button(L10n.Database.installVersion) {
                            viewModel.showInstallVersion = true
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .disabled(viewModel.isOperationInProgress)
                    }
                    .padding(AXSpacing.lg)
                }

                // Redis Security Section
                if viewModel.databaseType == .redis {
                    AXGlassCard(accentColor: .axAccentBlue) {
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            HStack {
                                Text(L10n.Engine.security)
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "lock.shield")
                                    .foregroundColor(.axAccentBlue)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                                Text(L10n.Engine.redisRequirepass)
                                    .font(AXTypography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axTextSecondary)
                                
                                HStack(spacing: AXSpacing.sm) {
                                    SecureField(L10n.Engine.enterPassword, text: $viewModel.redisPassword)
                                        .textFieldStyle(.plain)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(AXSpacing.md)
                                        .background(Color.axBackground)
                                        .cornerRadius(AXCornerRadius.md)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                                .stroke(Color.axBorder, lineWidth: 1)
                                        )
                                    
                                    Button {
                                        Task {
                                            await viewModel.updateRedisPassword(newPassword: viewModel.redisPassword)
                                        }
                                    } label: {
                                        Text(L10n.Button.save)
                                            .font(AXTypography.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.axBackground)
                                            .padding(.horizontal, AXSpacing.lg)
                                            .padding(.vertical, AXSpacing.md)
                                            .background(Color.axAccentBlue)
                                            .cornerRadius(AXCornerRadius.md)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(viewModel.isPerformingServiceAction || viewModel.redisPassword.isEmpty)
                                }
                                
                                Text(L10n.Engine.requirepassHint)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextMuted)
                            }
                        }
                        .padding(AXSpacing.lg)
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
    }
}
