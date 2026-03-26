//
//  ChronoProjectCard.swift
//  AevonX
//
//  Project row card with status, branch, last deploy, actions.
//

import SwiftUI

struct ChronoProjectCard: View {
    let project: ChronoProject
    @ObservedObject var viewModel: ChronoViewModel

    var body: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                headerRow
                infoRow
                footerRow
            }
            .padding(AXSpacing.lg)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 14))
                .foregroundColor(.axAccentBlue)
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(project.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text(project.path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.axTextMuted)
                    .lineLimit(1)
            }
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        HStack(spacing: AXSpacing.xxxs) {
            Circle()
                .fill(healthColor)
                .frame(width: 6, height: 6)
            Text(project.healthStatus.capitalized)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(healthColor)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxxs)
        .background(healthColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var healthColor: Color {
        switch project.healthStatus {
        case "healthy": return .axSuccess
        case "unhealthy": return .axError
        default: return .axTextMuted
        }
    }

    // MARK: - Info

    private var infoRow: some View {
        HStack(spacing: AXSpacing.xl) {
            infoItem(icon: "arrow.triangle.branch", label: project.branch, color: .axAccentPurple)
            infoItem(icon: "tag", label: project.framework, color: .axAccentBlue)
            if project.pendingCommits > 0 {
                infoItem(icon: "arrow.down.circle", label: "\(project.pendingCommits) pending", color: .axWarning)
            }
            if let lastDeploy = project.lastDeploy {
                infoItem(icon: "clock", label: lastDeploy, color: .axTextMuted)
            }
            Spacer()
        }
    }

    private func infoItem(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: AXSpacing.xxxs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
                .lineLimit(1)
        }
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: AXSpacing.md) {
            Button {
                Task { await viewModel.triggerDeploy(projectId: project.id) }
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "play.fill")
                    Text(L10n.Chrono.Deploy.trigger)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.axAccentGreen)
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.openProjectDetail(project) }
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "info.circle")
                    Text(L10n.Chrono.ProjectDetail.info)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.loadHologram(projectId: project.id) }
                viewModel.selectedTab = .hologram
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "cube.transparent")
                    Text(L10n.Chrono.tabHologram)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.axAccentPurple)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                Task { await viewModel.removeProject(id: project.id) }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.axError.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }
}
