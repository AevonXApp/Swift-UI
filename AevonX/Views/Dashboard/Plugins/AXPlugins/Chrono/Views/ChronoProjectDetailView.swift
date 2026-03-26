//
//  ChronoProjectDetailView.swift
//  AevonX
//
//  Detailed view for a single AXChrono project — config, health, deploys, snapshots.
//

import SwiftUI

struct ChronoProjectDetailView: View {
    @ObservedObject var viewModel: ChronoViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let project = viewModel.detailProject {
            VStack(spacing: 0) {
                sheetHeader(project)
                Divider().background(Color.axBorder)
                ScrollView {
                    VStack(alignment: .leading, spacing: AXSpacing.xl) {
                        projectInfoSection(project)
                        healthSection(project)
                        deploysSection
                        snapshotsSection(project)
                    }
                    .padding(AXSpacing.xl)
                }
            }
            .background(Color.axBackground)
            .frame(minWidth: 620, minHeight: 560)
        }
    }

    // MARK: - Header

    private func sheetHeader(_ project: ChronoProject) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 16))
                .foregroundColor(.axAccentBlue)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(project.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                Text(project.path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .lineLimit(1)
            }
            Spacer()
            detailHealthBadge(project)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.xl)
    }

    private func detailHealthBadge(_ project: ChronoProject) -> some View {
        HStack(spacing: AXSpacing.xxxs) {
            Circle()
                .fill(healthColor(project.healthStatus))
                .frame(width: 6, height: 6)
            Text(project.healthStatus.capitalized)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(healthColor(project.healthStatus))
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxxs)
        .background(healthColor(project.healthStatus).opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Project Info

    private func projectInfoSection(_ project: ChronoProject) -> some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionLabel(L10n.Chrono.ProjectDetail.info, icon: "info.circle")
                infoGrid(project)
            }
            .padding(AXSpacing.lg)
        }
    }

    private func infoGrid(_ project: ChronoProject) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: AXSpacing.md) {
            infoCell(L10n.Chrono.Projects.branch, value: project.branch, icon: "arrow.triangle.branch", color: .axAccentPurple)
            infoCell(L10n.Chrono.Projects.repoURL, value: project.repoURL, icon: "link", color: .axAccentBlue)
            infoCell("Framework", value: project.framework, icon: "tag", color: .axAccentBlue)
            infoCell(L10n.Chrono.Projects.watchMode, value: project.watchMode.capitalized, icon: "eye", color: .axTextSecondary)
            infoCell(L10n.Chrono.Projects.autoDeploy, value: project.autoDeploy ? "Enabled" : "Disabled", icon: "bolt.fill", color: project.autoDeploy ? .axSuccess : .axTextMuted)
            infoCell(L10n.Chrono.Projects.lastDeploy, value: project.lastDeploy ?? "Never", icon: "clock", color: .axTextMuted)
        }
    }

    private func infoCell(_ label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(label)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Health

    private func healthSection(_ project: ChronoProject) -> some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionLabel(L10n.Chrono.ProjectDetail.health, icon: "heart.text.square")

                if let probe = viewModel.healthProbes.first(where: { $0.projectId == project.id }) {
                    healthProbeRow(probe)
                } else {
                    Text(L10n.Chrono.ProjectDetail.noHealth)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.lg)
                }
            }
            .padding(AXSpacing.lg)
        }
    }

    private func healthProbeRow(_ probe: ChronoHealthProbe) -> some View {
        HStack(spacing: AXSpacing.lg) {
            probeStatusIcon(probe.status)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(probe.url)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
                Text(L10n.Chrono.ProjectDetail.lastChecked(probe.lastCheck))
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AXSpacing.xxxs) {
                Text("\(probe.responseTimeMS)ms")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(probe.responseTimeMS < 500 ? .axSuccess : .axWarning)
                Text(String(format: "%.1f%% uptime", probe.uptimePercent))
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextSecondary)
            }

            if probe.consecutiveFailures > 0 {
                Text("\(probe.consecutiveFailures)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, AXSpacing.xxxs)
                    .background(Capsule().fill(Color.axError))
            }
        }
    }

    private func probeStatusIcon(_ status: String) -> some View {
        ZStack {
            Circle()
                .fill(probeColor(status).opacity(0.15))
                .frame(width: 32, height: 32)
            Image(systemName: probeIcon(status))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(probeColor(status))
        }
    }

    // MARK: - Deploys

    private var deploysSection: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionLabel(L10n.Chrono.Deploy.history, icon: "arrow.triangle.2.circlepath")

                if viewModel.detailDeploys.isEmpty {
                    Text(L10n.Chrono.Deploy.empty)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.lg)
                } else {
                    ForEach(viewModel.detailDeploys.prefix(10)) { deploy in
                        ChronoDeployRow(deploy: deploy)
                    }
                }
            }
            .padding(AXSpacing.lg)
        }
    }

    // MARK: - Snapshots

    private func snapshotsSection(_ project: ChronoProject) -> some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                sectionLabel(L10n.Chrono.ProjectDetail.snapshots, icon: "camera.fill")

                if viewModel.snapshots.isEmpty {
                    Text(L10n.Chrono.ProjectDetail.noSnapshots)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AXSpacing.lg)
                } else {
                    ForEach(viewModel.snapshots) { snap in
                        snapshotRow(snap, projectId: project.id)
                    }
                }
            }
            .padding(AXSpacing.lg)
        }
    }

    private func snapshotRow(_ snap: ChronoSnapshot, projectId: String) -> some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: "camera.fill")
                .font(.system(size: 11))
                .foregroundColor(.axAccentPurple)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(snap.commitHash.prefix(8) + "")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextPrimary)
                HStack(spacing: AXSpacing.sm) {
                    Text(snap.createdAt)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                    Text(viewModel.formatBytes(snap.sizeBytes))
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                    Text("\(snap.fileCount) files")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
            }

            Spacer()

            Button {
                Task { await viewModel.restoreSnapshot(projectId: projectId, snapshotId: snap.id) }
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "arrow.uturn.backward")
                    Text(L10n.Chrono.rollbackTitle)
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.axWarning)
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.deleteSnapshot(id: snap.id, projectId: projectId) }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(.axError.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AXSpacing.xxs)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.axAccentPurple)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.axTextPrimary)
        }
    }

    private func healthColor(_ status: String) -> Color {
        switch status {
        case "healthy": return .axSuccess
        case "unhealthy": return .axError
        default: return .axTextMuted
        }
    }

    private func probeColor(_ status: String) -> Color {
        switch status {
        case "up": return .axSuccess
        case "degraded": return .axWarning
        case "down": return .axError
        default: return .axTextMuted
        }
    }

    private func probeIcon(_ status: String) -> String {
        switch status {
        case "up": return "checkmark.circle.fill"
        case "degraded": return "exclamationmark.triangle.fill"
        case "down": return "xmark.circle.fill"
        default: return "questionmark.circle"
        }
    }
}
