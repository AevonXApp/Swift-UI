//
//  ChronoApprovalsView.swift
//  AevonX
//
//  Pending approval cards with approve/deny + history.
//

import SwiftUI

struct ChronoApprovalsView: View {
    @ObservedObject var viewModel: ChronoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                header
                pendingSection
                historySection
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadApprovals() }
    }

    // MARK: - Header

    private var header: some View {
        Text(L10n.Chrono.Approvals.title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.axTextPrimary)
    }

    // MARK: - Pending

    @ViewBuilder
    private var pendingSection: some View {
        if viewModel.pendingApprovals.isEmpty {
            emptyState
        } else {
            VStack(spacing: AXSpacing.md) {
                ForEach(viewModel.pendingApprovals) { approval in
                    approvalCard(approval)
                }
            }
        }
    }

    private func approvalCard(_ approval: ChronoApproval) -> some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                cardHeader(approval)
                cardReason(approval)
                cardDetails(approval)
                cardActions(approval)
            }
            .padding(AXSpacing.lg)
        }
    }

    private func cardHeader(_ approval: ChronoApproval) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: approvalIcon(approval.type))
                .font(.system(size: 14))
                .foregroundColor(.axWarning)
                .frame(width: 28, height: 28)
                .background(Color.axWarning.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AXCornerRadius.sm))
            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(approvalLabel(approval.type))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.axTextPrimary)
                Text(approval.projectName)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
            }
            Spacer()
            Text(approval.requestedAt)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextMuted)
        }
    }

    private func cardReason(_ approval: ChronoApproval) -> some View {
        Text(approval.reason)
            .font(AXTypography.subheadline)
            .foregroundColor(.axTextSecondary)
            .padding(AXSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.axWarning.opacity(0.05))
            .cornerRadius(AXCornerRadius.md)
    }

    @ViewBuilder
    private func cardDetails(_ approval: ChronoApproval) -> some View {
        if let details = approval.details, !details.isEmpty {
            VStack(spacing: AXSpacing.xxxs) {
                ForEach(Array(details.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                            .frame(width: 100, alignment: .leading)
                        Text(details[key] ?? "")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.axTextPrimary)
                        Spacer()
                    }
                }
            }
        }
    }

    private func cardActions(_ approval: ChronoApproval) -> some View {
        HStack(spacing: AXSpacing.md) {
            Button {
                Task { await viewModel.approveOperation(id: approval.id) }
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(L10n.Chrono.Approvals.approve)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSuccess)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.denyOperation(id: approval.id) }
            } label: {
                HStack(spacing: AXSpacing.xxxs) {
                    Image(systemName: "xmark.circle.fill")
                    Text(L10n.Chrono.Approvals.deny)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.axError)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axError.opacity(0.12))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        if !viewModel.approvalHistory.isEmpty {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                Text(L10n.Chrono.Approvals.history)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.axTextPrimary)

                VStack(spacing: AXSpacing.xs) {
                    ForEach(viewModel.approvalHistory) { entry in
                        historyRow(entry)
                    }
                }
                .padding(AXSpacing.lg)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.lg)
            }
        }
    }

    private func historyRow(_ entry: ChronoApprovalHistory) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: entry.action == "approved" ? "checkmark.circle" : "xmark.circle")
                .font(.system(size: 11))
                .foregroundColor(entry.action == "approved" ? .axSuccess : .axError)
            Text(entry.projectName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.axTextPrimary)
            Text(entry.type.capitalized)
                .font(AXTypography.caption)
                .foregroundColor(.axTextSecondary)
            Spacer()
            Text(entry.action.capitalized)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(entry.action == "approved" ? .axSuccess : .axError)
            Text(entry.actionAt)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.axTextMuted)
        }
        .padding(.vertical, AXSpacing.xxxs)
    }

    // MARK: - Helpers

    private func approvalIcon(_ type: String) -> String {
        switch type {
        case "selfheal": return "heart.fill"
        case "migration": return "cylinder.split.1x2"
        case "canary": return "bird"
        case "ghost": return "eye.slash"
        case "drift": return "arrow.triangle.swap"
        default: return "checkmark.seal"
        }
    }

    private func approvalLabel(_ type: String) -> String {
        switch type {
        case "selfheal": return L10n.Chrono.Approvals.selfheal
        case "migration": return L10n.Chrono.Approvals.migration
        case "canary": return L10n.Chrono.Approvals.canary
        case "ghost": return L10n.Chrono.Approvals.ghost
        case "drift": return L10n.Chrono.Approvals.drift
        default: return type.capitalized
        }
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 36))
                .foregroundColor(.axTextMuted)
            Text(L10n.Chrono.Approvals.empty)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }
}
