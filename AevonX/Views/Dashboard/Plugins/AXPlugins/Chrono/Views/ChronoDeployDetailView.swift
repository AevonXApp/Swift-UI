//
//  ChronoDeployDetailView.swift
//  AevonX
//
//  Single deploy detail with pipeline steps.
//

import SwiftUI

struct ChronoDeployDetailView: View {
    let deploy: ChronoDeploy
    @ObservedObject var viewModel: ChronoViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    metadataSection
                    pipelineSection
                    actionButtons
                }
                .padding(AXSpacing.xl)
            }
        }
        .background(Color.axBackground)
        .sheet(isPresented: $viewModel.showLiveLog) {
            ChronoLiveLogView(deployId: deploy.id, viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 450)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text("Deploy \(deploy.id)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                Text("\(deploy.projectName) · \(deploy.commit.prefix(7))")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            Spacer()
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

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(spacing: AXSpacing.sm) {
            metaRow("Status", value: deploy.status.capitalized, color: statusColor)
            metaRow(L10n.Chrono.Deploy.duration, value: viewModel.formatDuration(deploy.durationMS))
            metaRow("Trigger", value: deploy.trigger.capitalized)
            metaRow(L10n.Chrono.Deploy.filesChanged, value: "\(deploy.filesChanged)")
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
    }

    private func metaRow(_ label: String, value: String, color: Color = .axTextPrimary) -> some View {
        HStack {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(color)
            Spacer()
        }
    }

    private var statusColor: Color {
        switch deploy.status {
        case "success": return .axSuccess
        case "failed": return .axError
        case "rolled_back": return .axWarning
        default: return .axAccentBlue
        }
    }

    // MARK: - Pipeline Steps

    private var pipelineSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            Text(L10n.Chrono.Deploy.pipelineSteps)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.axTextPrimary)

            VStack(spacing: AXSpacing.xs) {
                ForEach(deploy.steps) { step in
                    ChronoStepBadge(step: step, formatDuration: viewModel.formatDuration)
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.lg)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: AXSpacing.md) {
            Button {
                Task { await viewModel.watchLiveLog(deployId: deploy.id) }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "doc.text")
                    Text(L10n.Chrono.Deploy.viewLog)
                }
                .font(AXTypography.caption.weight(.medium))
                .foregroundColor(.axAccentBlue)
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.rollback(projectId: deploy.projectId, snapshotId: deploy.id) }
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "arrow.uturn.backward")
                    Text(L10n.Chrono.rollbackTitle)
                }
                .font(AXTypography.caption.weight(.medium))
                .foregroundColor(.axWarning)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
}
