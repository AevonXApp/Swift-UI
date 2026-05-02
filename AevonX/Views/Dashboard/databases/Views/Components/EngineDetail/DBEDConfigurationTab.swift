//
//  DBEDConfigurationTab.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEDConfigurationTab: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Config file path
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text(L10n.Database.configurationFile)
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
                            .buttonStyle(.plain)
                            .foregroundColor(.axAccentBlue)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        Text(viewModel.configFilePath)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextMuted)
                            .font(.system(.subheadline, design: .monospaced))
                    }
                    .padding(AXSpacing.lg)
                }

                // Version Management
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text(L10n.Database.versionManagement)
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button(L10n.Database.switchVersion) {
                                viewModel.showVersionSwitcher = true
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.axAccentBlue)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        HStack {
                            Text(L10n.Database.currentVersion)
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextMuted)
                            Spacer()
                            Text(viewModel.formattedVersion)
                                .font(AXTypography.subheadline)
                                .foregroundColor(.axTextPrimary)
                        }

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
                    AXGlassCard {
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            HStack {
                                Text(L10n.Database.security)
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "lock.shield")
                                    .foregroundColor(.axAccentBlue)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                                Text(L10n.Database.redisPasswordRequirepass)
                                    .font(AXTypography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.axTextSecondary)
                                
                                HStack(spacing: AXSpacing.sm) {
                                    SecureField("Enter password", text: $viewModel.redisPassword)
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
                                
                                Text(L10n.Database.settingAPasswordEnablesTheRequirepassDirectiveARestartIsRequired)
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
