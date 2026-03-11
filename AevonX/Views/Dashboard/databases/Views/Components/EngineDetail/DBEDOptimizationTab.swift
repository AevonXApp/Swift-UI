//
//  DBEDOptimizationTab.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DBEDOptimizationTab: View {
    @ObservedObject var viewModel: DatabaseEngineDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AXSpacing.xl) {
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Performance Optimization")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        Text("AI-powered optimization recommendations will appear here.")
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
                        .background(Color.axAccentBlue)
                        .cornerRadius(AXCornerRadius.md)
                        .disabled(viewModel.isOperationInProgress)
                    }
                    .padding(AXSpacing.lg)
                }

                // Optimization presets
                AXGlassCard {
                    VStack(alignment: .leading, spacing: AXSpacing.lg) {
                        Text("Quick Presets")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)

                        VStack(spacing: AXSpacing.md) {
                            PresetButton(title: "Web Application", description: "Optimized for web workloads") {
                                Task { await viewModel.applyOptimizationPreset("Web Application") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetButton(title: "Data Warehouse", description: "Optimized for analytics") {
                                Task { await viewModel.applyOptimizationPreset("Data Warehouse") }
                            }
                            .disabled(viewModel.isOperationInProgress)

                            PresetButton(title: "Development", description: "Balanced for development") {
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

// Helper View
private struct PresetButton: View {
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(title)
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.axTextPrimary)
                    Text(description)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
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
