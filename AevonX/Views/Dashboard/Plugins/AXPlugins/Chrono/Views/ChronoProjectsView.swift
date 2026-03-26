//
//  ChronoProjectsView.swift
//  AevonX
//
//  AXChrono tracked projects list with add/remove/deploy.
//

import SwiftUI

struct ChronoProjectsView: View {
    @ObservedObject var viewModel: ChronoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xl) {
                header
                projectsList
            }
            .padding(AXSpacing.xl)
        }
        .task { await viewModel.loadProjects() }
        .sheet(isPresented: $viewModel.showAddProject) {
            ChronoAddProjectSheet(viewModel: viewModel)
                .frame(minWidth: 500, minHeight: 500)
        }
        .sheet(isPresented: $viewModel.showProjectDetail) {
            ChronoProjectDetailView(viewModel: viewModel)
        }
    }

    private var header: some View {
        HStack {
            Text(L10n.Chrono.Projects.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)
            Spacer()
            AXPrimaryButton(title: L10n.Chrono.Projects.add, icon: "plus.circle.fill", action: {
                viewModel.showAddProject = true
            })
        }
    }

    @ViewBuilder
    private var projectsList: some View {
        if viewModel.projects.isEmpty {
            emptyState
        } else {
            VStack(spacing: AXSpacing.md) {
                ForEach(viewModel.projects) { project in
                    ChronoProjectCard(project: project, viewModel: viewModel)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 36))
                .foregroundColor(.axTextMuted)
            Text(L10n.Chrono.Projects.empty)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AXSpacing.xxxxl)
    }
}

// MARK: - Add Project Sheet

private struct ChronoAddProjectSheet: View {
    @ObservedObject var viewModel: ChronoViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var path = ""
    @State private var repoURL = ""
    @State private var branch = "main"
    @State private var autoDeploy = true
    @State private var healthURL = ""
    @State private var gitUsername = ""
    @State private var gitToken = ""

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            ScrollView {
                VStack(alignment: .leading, spacing: AXSpacing.lg) {
                    formField(L10n.Chrono.Projects.path, text: $path, placeholder: "/var/www/myapp")
                    formField(L10n.Chrono.Projects.repoURL, text: $repoURL, placeholder: "https://github.com/user/myapp")
                    formField(L10n.Chrono.Projects.branch, text: $branch, placeholder: "main")

                    Toggle(isOn: $autoDeploy) {
                        Text(L10n.Chrono.Projects.autoDeploy)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextPrimary)
                    }
                    .toggleStyle(.checkbox)

                    formField(L10n.Chrono.Projects.healthURL, text: $healthURL, placeholder: "https://myapp.com/health")

                    gitAuthSection
                }
                .padding(AXSpacing.xl)
            }
            sheetFooter
        }
        .background(Color.axBackground)
    }

    private var sheetHeader: some View {
        HStack {
            Text(L10n.Chrono.Projects.add)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.axTextPrimary)
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

    private var gitAuthSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            Text(L10n.Chrono.Projects.gitAuth)
                .font(AXTypography.subheadline.weight(.medium))
                .foregroundColor(.axTextPrimary)
            formField(L10n.Chrono.Projects.gitUsername, text: $gitUsername, placeholder: "user")
            SecureField(L10n.Chrono.Projects.gitToken, text: $gitToken)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
        }
    }

    private var sheetFooter: some View {
        HStack {
            AXPrimaryButton(title: L10n.Button.cancel, icon: nil, action: { dismiss() }, style: .secondary)
            Spacer()
            AXPrimaryButton(title: L10n.Chrono.Projects.add, icon: "plus.circle.fill", action: {
                Task {
                    await viewModel.addProject(path: path, repoURL: repoURL, branch: branch, autoDeploy: autoDeploy, healthURL: healthURL)
                    dismiss()
                }
            }, isDisabled: path.isEmpty || branch.isEmpty)
        }
        .padding(AXSpacing.xl)
    }

    private func formField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
            Text(label)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .padding(AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder, lineWidth: 1))
        }
    }
}
