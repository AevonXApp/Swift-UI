//
//  ChronoDeployHistoryView.swift
//  AevonX
//
//  Deploy history list.
//

import SwiftUI

struct ChronoDeployHistoryView: View {
    @ObservedObject var viewModel: ChronoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                Text(L10n.Chrono.Deploy.history)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)

                if viewModel.deploys.isEmpty {
                    emptyState
                } else {
                    // Lazy: a project's deploy history is unbounded.
                    LazyVStack(spacing: AXSpacing.xs) {
                        ForEach(viewModel.deploys) { deploy in
                            ChronoDeployRow(deploy: deploy)
                                .onTapGesture {
                                    Task { await viewModel.loadDeployDetail(deployId: deploy.id) }
                                }
                        }
                    }
                }
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadDeploys() }
        .sheet(item: $viewModel.selectedDeploy) { deploy in
            ChronoDeployDetailView(deploy: deploy, viewModel: viewModel)
                .frame(minWidth: 550, minHeight: 500)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 36))
                .foregroundColor(.axTextMuted)
            Text(L10n.Chrono.Deploy.empty)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }
}
