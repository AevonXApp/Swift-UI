//
//  QuickActionsSection.swift
//  AevonX
//
//  Quick one-click actions dashboard for a website
//

import SwiftUI
import AevonXCoreBridge

struct QuickActionsSection: View {
    @ObservedObject var viewModel: QuickActionsViewModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                AXSectionTitle(title: "Quick Actions", icon: "bolt.fill")

                // Running indicator
                if viewModel.isRunning {
                    HStack(spacing: AXSpacing.sm) {
                        ProgressView().scaleEffect(0.8)
                        Text(viewModel.runningAction)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axAccentBlue)
                    }
                    .padding(AXSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }

                // Service Actions
                AXConfigCard(icon: "server.rack", title: "Service Control", subtitle: "Restart or reload services") {
                    LazyVGrid(columns: columns, spacing: AXSpacing.md) {
                        actionTile(icon: "arrow.clockwise", title: "Restart Runtime", subtitle: viewModel.runtime.rawValue, color: .orange) {
                            Task { await viewModel.restartRuntime() }
                        }
                        actionTile(icon: "arrow.clockwise.circle", title: "Restart Nginx", subtitle: "Full restart", color: .red) {
                            Task { await viewModel.restartNginx() }
                        }
                        actionTile(icon: "arrow.triangle.2.circlepath", title: "Reload Nginx", subtitle: "Graceful", color: .axSuccess) {
                            Task { await viewModel.reloadNginx() }
                        }
                    }
                }

                // Maintenance
                AXConfigCard(icon: "wrench.fill", title: "Maintenance", subtitle: "Maintenance mode and cache management") {
                    LazyVGrid(columns: columns, spacing: AXSpacing.md) {
                        actionTile(
                            icon: viewModel.maintenanceMode ? "xmark.circle" : "wrench.and.screwdriver",
                            title: viewModel.maintenanceMode ? "Disable Maint." : "Enable Maint.",
                            subtitle: viewModel.maintenanceMode ? "Site is offline" : "Show 503 page",
                            color: viewModel.maintenanceMode ? .axSuccess : .axWarning
                        ) {
                            Task { await viewModel.toggleMaintenanceMode() }
                        }
                        actionTile(icon: "trash.circle", title: "Clear App Cache", subtitle: "Laravel/WP", color: .purple) {
                            Task { await viewModel.clearAppCache() }
                        }
                        actionTile(icon: "person.badge.key", title: "Fix Ownership", subtitle: "www-data", color: .axAccentBlue) {
                            Task { await viewModel.fixOwnership() }
                        }
                    }
                }

                // Diagnostics
                AXConfigCard(icon: "stethoscope", title: "Diagnostics", subtitle: "Test configuration and check disk usage") {
                    LazyVGrid(columns: columns, spacing: AXSpacing.md) {
                        actionTile(icon: "checkmark.seal", title: "Test Nginx", subtitle: "nginx -t", color: .cyan) {
                            Task { await viewModel.testNginx() }
                        }
                        VStack(spacing: 4) {
                            Image(systemName: "internaldrive")
                                .font(AXTypography.title2)
                                .foregroundColor(.axAccentBlue)
                            Text("Disk Usage")
                                .font(AXTypography.footnote).fontWeight(.semibold)
                                .foregroundColor(.axTextPrimary)
                            Text(viewModel.diskUsage)
                                .font(AXTypography.title2).fontWeight(.bold)
                                .foregroundColor(.axAccentBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AXSpacing.md)
                        .background(Color.axBackground)
                        .cornerRadius(AXCornerRadius.md)
                    }
                }

                // Nginx test result
                if let result = viewModel.nginxTestResult {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: viewModel.nginxTestPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.nginxTestPassed ? .axSuccess : .axError)
                        Text(result)
                            .font(AXTypography.monoSm)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(3)
                    }
                    .padding(AXSpacing.md)
                    .background((viewModel.nginxTestPassed ? Color.axSuccess : Color.axError).opacity(0.08))
                    .cornerRadius(AXCornerRadius.md)
                }
            }
            .padding(AXSpacing.xl)
        }
        .background(Color.axBackground)
        .onAppear { Task { await viewModel.refreshDiskUsage() } }
    }

    // MARK: - Action Tile

    private func actionTile(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(AXTypography.title)
                    .foregroundColor(color)
                Text(title)
                    .font(AXTypography.footnote).fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                Text(subtitle)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(AXSpacing.md)
            .background(color.opacity(0.06))
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isRunning)
    }
}
