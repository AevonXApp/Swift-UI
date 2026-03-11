//
//  DatabaseConfigContent.swift
//  AevonX
//
//  Configuration + Redis Security tabs extracted from UnifiedDatabaseDetailView
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

extension UnifiedDatabaseDetailView {

    // MARK: - Configuration Tab

    var configurationContent: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xl) {
            Text("Configuration")
                .font(AXTypography.title)
                .fontWeight(.bold)
                .foregroundColor(.axTextPrimary)

            // Config File Path
            AXConfigCard(icon: "doc.text.fill", title: "Configuration File") {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    HStack {
                        Text(viewModel.configFilePath)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.axTextMuted)

                        Spacer()

                        AXActionButton(label: "Edit", icon: "pencil", style: .ghost, size: .small) {
                            Task {
                                await viewModel.loadConfiguration()
                                editedConfig = viewModel.configuration?.rawContent ?? ""
                                showConfigEditor = true
                            }
                        }
                        .disabled(viewModel.isOperationInProgress)
                    }
                }
            }

            // Version Management
            AXConfigCard(icon: "shippingbox.fill", title: "Version Management") {
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    AXInfoRow(label: "Current Version", value: viewModel.formattedVersion)

                    AXActionButton(label: "Install New Version", icon: "arrow.down.circle", style: .ghost, fullWidth: true) {
                        Task {
                            selectedSection = .versions
                            await viewModel.fetchAvailableVersions()
                        }
                    }
                    .disabled(viewModel.isOperationInProgress)
                }
            }

            // Redis Security Section
            if databaseType == .redis {
                redisSecurityCard
            }
        }
    }

    var redisSecurityCard: some View {
        AXConfigCard(icon: "lock.shield.fill", title: "Security", iconColor: .axSuccess) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(databaseType.brandColor)

                    Text("Redis Password (requirepass)")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)

                    Spacer()
                }

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

                    AXActionButton(label: "Save", icon: "checkmark", style: .success) {
                        Task {
                            await viewModel.updateRedisPassword(newPassword: viewModel.redisPassword)
                        }
                    }
                    .disabled(viewModel.isPerformingServiceAction || viewModel.redisPassword.isEmpty)
                }

                Text("Setting a password enables the 'requirepass' directive. A restart is required.")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }
        }
    }
}
