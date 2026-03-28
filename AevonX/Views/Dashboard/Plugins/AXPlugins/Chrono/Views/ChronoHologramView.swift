//
//  ChronoHologramView.swift
//  AevonX
//
//  Pre-deploy impact analysis — files, deps, migrations, risk.
//

import SwiftUI

struct ChronoHologramView: View {
    @ObservedObject var viewModel: ChronoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                header
                projectPicker
                if let holo = viewModel.hologram {
                    riskBanner(holo)
                    fileImpactSection(holo)
                    dependencySection(holo)
                    migrationsSection(holo)
                    buildSection(holo)
                    securitySummary(holo)
                    downtimeEstimate(holo)
                } else {
                    emptyState
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadProjects() }
    }

    // MARK: - Header

    private var header: some View {
        Text(L10n.Chrono.Hologram.title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.axTextPrimary)
    }

    // MARK: - Project Picker

    private var projectPicker: some View {
        HStack(spacing: AXSpacing.md) {
            ForEach(viewModel.projects) { project in
                Button {
                    Task { await viewModel.loadHologram(projectId: project.id) }
                } label: {
                    Text(project.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.hologramProjectId == project.id ? .white : .axTextSecondary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.xs)
                        .background(viewModel.hologramProjectId == project.id ? Color.axAccentPurple : Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Risk Banner

    private func riskBanner(_ holo: ChronoHologram) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: riskIcon(holo.riskLevel))
                .font(.system(size: 18))
                .foregroundColor(riskColor(holo.riskLevel))
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(riskLabel(holo.riskLevel))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(riskColor(holo.riskLevel))
                Text("Estimated duration: \(viewModel.formatDuration(holo.estimatedDurationSec * 1000))")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            Spacer()
        }
        .padding(AXSpacing.lg)
        .background(riskColor(holo.riskLevel).opacity(0.08))
        .cornerRadius(AXCornerRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(riskColor(holo.riskLevel).opacity(0.2), lineWidth: 1))
    }

    // MARK: - File Impact

    private func fileImpactSection(_ holo: ChronoHologram) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            sectionTitle(L10n.Chrono.Hologram.filesChanged, icon: "doc.on.doc")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AXSpacing.md), count: 4), spacing: AXSpacing.md) {
                impactCard("Total", value: "\(holo.filesChanged)", color: .axAccentBlue)
                impactCard("Modified", value: "\(holo.filesModified)", color: .axWarning)
                impactCard("Added", value: "\(holo.filesAdded)", color: .axSuccess)
                impactCard("Deleted", value: "\(holo.filesDeleted)", color: .axError)
            }
        }
    }

    private func impactCard(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: AXSpacing.xs) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.md)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Dependencies

    @ViewBuilder
    private func dependencySection(_ holo: ChronoHologram) -> some View {
        if !holo.dependencyChanges.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionTitle(L10n.Chrono.Hologram.dependencies, icon: "shippingbox")

                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    ForEach(holo.dependencyChanges, id: \.self) { dep in
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "cube.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.axAccentPurple)
                            Text(dep)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                        }
                    }
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.lg)
            }
        }
    }

    // MARK: - Migrations

    @ViewBuilder
    private func migrationsSection(_ holo: ChronoHologram) -> some View {
        if !holo.migrationsPending.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionTitle(L10n.Chrono.Hologram.migrations, icon: "cylinder.split.1x2")

                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    ForEach(holo.migrationsPending, id: \.self) { migration in
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.axWarning)
                            Text(migration)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.axTextPrimary)
                        }
                    }
                }
                .padding(AXSpacing.lg)
                .background(Color.axWarning.opacity(0.05))
                .cornerRadius(AXCornerRadius.lg)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axWarning.opacity(0.15), lineWidth: 1))
            }
        }
    }

    // MARK: - Build Steps

    @ViewBuilder
    private func buildSection(_ holo: ChronoHologram) -> some View {
        if !holo.buildSteps.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionTitle(L10n.Chrono.Hologram.buildSteps, icon: "hammer")

                VStack(alignment: .leading, spacing: AXSpacing.xs) {
                    ForEach(Array(holo.buildSteps.enumerated()), id: \.offset) { idx, step in
                        HStack(spacing: AXSpacing.sm) {
                            Text("\(idx + 1)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.axAccentBlue)
                                .frame(width: 20, height: 20)
                                .background(Color.axAccentBlue.opacity(0.12))
                                .clipShape(Circle())
                            Text(step)
                                .font(.system(size: 13))
                                .foregroundColor(.axTextPrimary)
                        }
                    }
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.lg)
            }
        }
    }

    // MARK: - Security Summary

    private func securitySummary(_ holo: ChronoHologram) -> some View {
        HStack(spacing: AXSpacing.xl) {
            securityItem(L10n.Chrono.Hologram.security, icon: "lock.shield", value: "\(holo.secretsDetected) secrets, \(holo.vulnsDetected) vulns", color: holo.secretsDetected > 0 || holo.vulnsDetected > 0 ? .axError : .axSuccess)
            Spacer()
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
    }

    private func securityItem(_ label: String, icon: String, value: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.axTextPrimary)
                Text(value)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
        }
    }

    // MARK: - Downtime

    private func downtimeEstimate(_ holo: ChronoHologram) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 14))
                .foregroundColor(holo.estimatedDowntimeSec > 0 ? .axWarning : .axSuccess)
            Text(L10n.Chrono.Hologram.downtime)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.axTextPrimary)
            Spacer()
            Text(holo.estimatedDowntimeSec > 0 ? "\(holo.estimatedDowntimeSec)s" : "Zero-downtime")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(holo.estimatedDowntimeSec > 0 ? .axWarning : .axSuccess)
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.axAccentPurple)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.axTextPrimary)
        }
    }

    private func riskIcon(_ level: String) -> String {
        switch level {
        case "low": return "shield.checkered"
        case "medium": return "exclamationmark.triangle"
        case "high": return "exclamationmark.octagon"
        default: return "questionmark.circle"
        }
    }

    private func riskColor(_ level: String) -> Color {
        switch level {
        case "low": return .axSuccess
        case "medium": return .axWarning
        case "high": return .axError
        default: return .axTextMuted
        }
    }

    private func riskLabel(_ level: String) -> String {
        switch level {
        case "low": return L10n.Chrono.Hologram.riskLow
        case "medium": return L10n.Chrono.Hologram.riskMedium
        case "high": return L10n.Chrono.Hologram.riskHigh
        default: return level.capitalized
        }
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 36))
                .foregroundColor(.axTextMuted)
            Text("Select a project to analyze")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }
}
