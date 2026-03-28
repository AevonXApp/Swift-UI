//
//  DBEMOptimizationSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEMOptimizationSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text(L10n.Engine.optimization)
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()
                }

                // AI Analysis Card
                AXGlassCard(accentColor: .axAccentBlue) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text(L10n.Engine.performanceAnalysis)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Text(L10n.Engine.aiOptimizationHint)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextMuted)

                        Button(L10n.Engine.analyzePerformance) {
                            Task { await viewModel.analyzePerformance() }
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                        .disabled(viewModel.isOperationInProgress)
                    }
                    .padding(AXSpacing.lg)
                }

                // Quick Presets
                AXGlassCard(accentColor: .axAccentBlue) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text(L10n.Engine.quickPresets)
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        VStack(spacing: AXSpacing.md) {
                            PresetRow(title: L10n.Engine.presetWebApp, description: L10n.Engine.presetWebAppDesc) {
                                Task { await viewModel.applyOptimizationPreset("Web Application") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetRow(title: L10n.Engine.presetDataWarehouse, description: L10n.Engine.presetDataWarehouseDesc) {
                                Task { await viewModel.applyOptimizationPreset("Data Warehouse") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetRow(title: L10n.Engine.presetDevelopment, description: L10n.Engine.presetDevelopmentDesc) {
                                Task { await viewModel.applyOptimizationPreset("Development") }
                            }
                            .disabled(viewModel.isOperationInProgress)
                        }
                    }
                    .padding(AXSpacing.lg)
                }
            }
            .padding(AXSpacing.xl)
        }
    }
}

// MARK: - Supporting Views

struct PresetRow: View {
    let title: String
    let description: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(title)
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)

                    Text(description)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextMuted)
            }
            .padding(AXSpacing.md)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
