//
//  DBEMOptimizationSection.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DBEMOptimizationSection: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                // Page Title
                HStack {
                    Text("Optimization")
                        .font(AXTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.axTextPrimary)

                    Spacer()
                }

                // AI Analysis Card
                AXGlassCard(accentColor: viewModel.databaseType.brandColor) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Performance Analysis")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Text("AI-powered optimization recommendations will appear here based on your database usage patterns.")
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextMuted)

                        Button("Analyze Performance") {
                            Task { await viewModel.analyzePerformance() }
                        }
                        .font(AXTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.lg)
                        .padding(.vertical, AXSpacing.md)
                        .background(viewModel.databaseType.brandColor)
                        .cornerRadius(AXCornerRadius.md)
                        .disabled(viewModel.isOperationInProgress)
                    }
                    .padding(AXSpacing.lg)
                }

                // Quick Presets
                AXGlassCard(accentColor: viewModel.databaseType.brandColor) {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Quick Presets")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        VStack(spacing: AXSpacing.md) {
                            PresetRow(title: "Web Application", description: "Optimized for web workloads with high read/write ratio") {
                                Task { await viewModel.applyOptimizationPreset("Web Application") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetRow(title: "Data Warehouse", description: "Optimized for analytics and reporting workloads") {
                                Task { await viewModel.applyOptimizationPreset("Data Warehouse") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetRow(title: "Development", description: "Balanced configuration for development environments") {
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
                    .font(.system(size: 12))
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
