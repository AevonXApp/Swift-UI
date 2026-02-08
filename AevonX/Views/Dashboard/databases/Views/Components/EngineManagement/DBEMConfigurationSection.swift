//
//  DBEMConfigurationSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBEMConfigurationSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text("Configuration")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()
                }

                // Config File Path
                AXGlassCard(accentColor: viewModel.databaseType.brandColor) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text("Configuration File")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button("Edit") {
                                Task {
                                    await viewModel.loadConfiguration()
                                    viewModel.configEditContent = viewModel.configuration?.rawContent ?? ""
                                    viewModel.showConfigEditor = true
                                }
                            }
                            .font(AXTypography.subheadline)
                            .foregroundColor(viewModel.databaseType.brandColor)
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
                AXGlassCard(accentColor: viewModel.databaseType.brandColor) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        HStack {
                            Text("Version Management")
                                .font(AXTypography.headline)
                                .foregroundColor(.axTextPrimary)

                            Spacer()

                            Button("Switch Version") {
                                viewModel.showVersionSwitcher = true
                            }
                            .font(AXTypography.subheadline)
                            .foregroundColor(viewModel.databaseType.brandColor)
                            .disabled(viewModel.isOperationInProgress)
                        }

                        Divider()

                        DBEMInfoRow(label: "Current Version", value: viewModel.formattedVersion)

                        Button("Install New Version") {
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
                    AXGlassCard(accentColor: viewModel.databaseType.brandColor) {
                        VStack(alignment: .leading, spacing: AXSpacing.lg) {
                            HStack {
                                Text("Security")
                                    .font(AXTypography.headline)
                                    .foregroundColor(.axTextPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "lock.shield")
                                    .foregroundColor(viewModel.databaseType.brandColor)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                                Text("Redis Password (requirepass)")
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
                                        Text("Save")
                                            .font(AXTypography.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.axBackground)
                                            .padding(.horizontal, AXSpacing.lg)
                                            .padding(.vertical, AXSpacing.md)
                                            .background(viewModel.databaseType.brandColor)
                                            .cornerRadius(AXCornerRadius.md)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(viewModel.isPerformingServiceAction || viewModel.redisPassword.isEmpty)
                                }
                                
                                Text("Setting a password enables the 'requirepass' directive. A restart is required.")
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
