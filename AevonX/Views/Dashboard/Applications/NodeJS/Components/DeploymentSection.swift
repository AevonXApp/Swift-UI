//
//  DeploymentSection.swift
//  AevonX
//
//  Git-based deployment management for Node.js apps.
//  Supports clone, pull, branch switching, and full deploy pipelines.
//

import SwiftUI
import AevonXCore

struct DeploymentSection: View {
    let serverId: String
    let appPath: String?

    @State private var isGitRepo = false
    @State private var deployInfo: NodeJSDeployService.DeploymentInfo?
    @State private var packageManager: NodeJSDeployService.PackageManager = .npm
    @State private var branches: [String] = []
    @State private var isLoading = true
    @State private var isDeploying = false
    @State private var deployOutput: String = ""
    @State private var showCloneSheet = false
    @State private var showOutput = false

    // Clone form
    @State private var cloneURL = ""
    @State private var cloneBranch = "main"

    private let deployService = NodeJSDeployService()

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            if isLoading {
                AXLoadingState(message: "Checking Git status…")
            } else if !isGitRepo {
                noGitSection
            } else {
                gitInfoCard
                branchCard
                deployActionsCard
                if showOutput && !deployOutput.isEmpty {
                    outputCard
                }
            }
        }
        .task { await loadData() }
        .sheet(isPresented: $showCloneSheet) { cloneSheet }
    }

    // MARK: - No Git

    private var noGitSection: some View {
        AXPlaceholder(
            icon: "arrow.triangle.branch",
            title: "No Git Repository",
            subtitle: "This project is not a Git repository. Clone a repo to enable deployment features.",
            action: AXPlaceholderAction(label: "Clone Repository") {
                await MainActor.run { showCloneSheet = true }
            }
        )
    }

    // MARK: - Git Info

    private var gitInfoCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    HStack(spacing: AXSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "#F05032").opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#F05032"))
                        }
                        Text("Repository Status")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                    Spacer()

                    // Package manager badge
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 10))
                        Text(packageManager.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }

                if let info = deployInfo {
                    AXInfoRow(label: "Branch", value: info.branch, valueColor: .axAccentBlue)
                    if let commit = info.lastCommit {
                        AXInfoRow(label: "Last Commit", value: String(commit.prefix(8)))
                    }
                    if let msg = info.lastCommitMessage {
                        AXInfoRow(label: "Message", value: msg)
                    }
                    if let date = info.lastCommitDate {
                        AXInfoRow(label: "Date", value: date)
                    }
                    if let url = info.remoteURL {
                        AXInfoRow(label: "Remote", value: url)
                    }
                    AXInfoRow(label: "Working Tree", value: info.isDirty ? "Uncommitted Changes" : "Clean",
                              valueColor: info.isDirty ? .axWarning : .axSuccess)
                }
            }
        }
    }

    // MARK: - Branch Card

    private var branchCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.axAccentBlue.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.axAccentBlue)
                    }
                    Text("Branches")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }

                if branches.isEmpty {
                    Text("No branches detected")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AXSpacing.sm) {
                            ForEach(branches, id: \.self) { branch in
                                let isCurrent = branch == deployInfo?.branch
                                Button {
                                    Task { await switchBranch(branch) }
                                } label: {
                                    HStack(spacing: 4) {
                                        if isCurrent {
                                            Circle()
                                                .fill(Color.axSuccess)
                                                .frame(width: 6, height: 6)
                                        }
                                        Text(branch)
                                            .font(.system(size: 11, weight: isCurrent ? .bold : .medium))
                                    }
                                    .foregroundColor(isCurrent ? .axSuccess : .axTextSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                            .fill(isCurrent ? Color.axSuccess.opacity(0.1) : Color.axSurface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                                    .stroke(isCurrent ? Color.axSuccess.opacity(0.3) : Color.axBorder.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isCurrent)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Deploy Actions

    private var deployActionsCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack(spacing: AXSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#8B5CF6").opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "rocket.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#8B5CF6"))
                    }
                    Text("Deploy Actions")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AXSpacing.sm) {
                    deployActionButton(title: "Pull", icon: "arrow.down.circle", color: .axAccentBlue) {
                        await gitPull()
                    }
                    deployActionButton(title: "Install Deps", icon: "shippingbox", color: Color(hex: "#339933")) {
                        await installDeps()
                    }
                    deployActionButton(title: "Build", icon: "hammer.fill", color: .axWarning) {
                        await runBuild()
                    }
                    deployActionButton(title: "Full Deploy", icon: "rocket.fill", color: Color(hex: "#8B5CF6")) {
                        await fullDeploy()
                    }
                    deployActionButton(title: "Refresh", icon: "arrow.clockwise", color: .axTextSecondary) {
                        await loadData()
                    }
                }

                if isDeploying {
                    HStack(spacing: AXSpacing.sm) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Deploying…")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextMuted)
                    }
                }
            }
        }
    }

    private func deployActionButton(title: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AXSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(color.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDeploying)
    }

    // MARK: - Output Card

    private var outputCard: some View {
        AXCard {
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                HStack {
                    HStack(spacing: AXSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.axTextSecondary.opacity(0.12))
                                .frame(width: 28, height: 28)
                            Image(systemName: "terminal.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.axTextSecondary)
                        }
                        Text("Output")
                            .font(AXTypography.headline)
                            .foregroundColor(.axTextPrimary)
                    }
                    Spacer()
                    Button {
                        showOutput = false
                        deployOutput = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    Text(deployOutput)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "#4EC9B0"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 200)
                .padding(AXSpacing.sm)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Clone Sheet

    private var cloneSheet: some View {
        VStack(spacing: AXSpacing.lg) {
            Text("Clone Repository")
                .font(AXTypography.title3)
                .foregroundColor(.axTextPrimary)

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Repository URL")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextMuted)
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                    TextField("https://github.com/user/repo.git", text: $cloneURL)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text("Branch")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.axTextMuted)
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 11))
                        .foregroundColor(.axTextMuted)
                    TextField("main", text: $cloneBranch)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.axTextPrimary)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
            }

            HStack {
                Button("Cancel") { showCloneSheet = false }
                    .buttonStyle(.plain)
                Spacer()
                AXActionButton(label: "Clone", icon: "arrow.down.circle", style: .primary) {
                    Task { await cloneRepo() }
                }
            }
        }
        .padding(AXSpacing.xl)
        .frame(width: 420)
    }

    // MARK: - Actions

    private func loadData() async {
        guard let path = appPath else {
            isLoading = false
            return
        }
        isLoading = true
        do {
            isGitRepo = try await deployService.isGitRepo(path: path, serverId: serverId)
            if isGitRepo {
                deployInfo = try? await deployService.getDeploymentInfo(path: path, serverId: serverId)
                packageManager = (try? await deployService.detectPackageManager(path: path, serverId: serverId)) ?? .npm
                branches = (try? await deployService.listBranches(path: path, serverId: serverId)) ?? []
            }
        } catch {
            isGitRepo = false
        }
        isLoading = false
    }

    private func switchBranch(_ branch: String) async {
        guard let path = appPath else { return }
        do {
            try await deployService.gitCheckout(path: path, branch: branch, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Switched to \(branch)")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
    }

    private func gitPull() async {
        guard let path = appPath else { return }
        isDeploying = true
        do {
            try await deployService.gitPull(path: path, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Pull complete")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        isDeploying = false
    }

    private func installDeps() async {
        guard let path = appPath else { return }
        isDeploying = true
        showOutput = true
        do {
            let output = try await deployService.installDependencies(path: path, serverId: serverId, production: false)
            deployOutput = output
            GlobalToastManager.shared.showSuccess("Dependencies installed")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        isDeploying = false
    }

    private func runBuild() async {
        guard let path = appPath else { return }
        isDeploying = true
        showOutput = true
        do {
            let output = try await deployService.runScript(path: path, script: "build", serverId: serverId)
            deployOutput = output
            GlobalToastManager.shared.showSuccess("Build complete")
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        isDeploying = false
    }

    private func fullDeploy() async {
        guard let path = appPath else { return }
        isDeploying = true
        showOutput = true
        do {
            try await deployService.deploy(path: path, serverId: serverId) { message, progress in
                Task { @MainActor in
                    deployOutput += "\(message)\n"
                }
            }
            GlobalToastManager.shared.showSuccess("Deployment complete!")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        isDeploying = false
    }

    private func cloneRepo() async {
        guard let path = appPath, !cloneURL.isEmpty else { return }
        isDeploying = true
        showCloneSheet = false
        do {
            try await deployService.gitClone(repoURL: cloneURL, path: path, branch: cloneBranch, serverId: serverId)
            GlobalToastManager.shared.showSuccess("Repository cloned!")
            await loadData()
        } catch {
            GlobalToastManager.shared.showError(error.localizedDescription)
        }
        isDeploying = false
    }
}
