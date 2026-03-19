//
//  GitTab.swift
//  AevonX
//
//  Premium Git source control panel for per-website management
//

import SwiftUI
import AevonXCoreBridge

struct GitTab: View {
    @ObservedObject var vm: GitViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AXSpacing.lg) {
                if vm.isLoading {
                    loadingView
                } else if !vm.repoInfo.hasGit {
                    gitSetupWizard
                } else {
                    gitControlPanel
                }
            }
            .padding(AXSpacing.xl)
        }
        .overlay(alignment: .bottom) { toastOverlay }
        .sheet(isPresented: $vm.showCommitSheet) { commitSheet }
        .task { await vm.loadAll() }
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView().scaleEffect(0.8)
            Text("Detecting Git repository...")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
    
    // MARK: - Commit Sheet
    
    private var commitSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "arrow.up.doc.fill")
                    .font(AXTypography.body)
                    .foregroundColor(.axAccentBlue)
                Text("Commit & Push")
                    .font(AXTypography.headline).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Spacer()
                if vm.isProPlan {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(AXTypography.caption2)
                        Text("AI")
                            .font(AXTypography.caption2).fontWeight(.bold)
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.axAccentBlue.opacity(0.15))
                    .cornerRadius(AXCornerRadius.sm)
                }
            }
            .padding(AXSpacing.md)
            .background(Color.axBackgroundSecondary)
            
            Divider().background(Color.axBorder)
            
            // Body
            VStack(alignment: .leading, spacing: AXSpacing.sm) {
                Text(vm.isProPlan ? "AI-generated commit message (editable):" : "Enter commit message:")
                    .font(AXTypography.footnote)
                    .foregroundColor(.axTextSecondary)
                
                if vm.isGeneratingCommitMessage {
                    HStack(spacing: AXSpacing.sm) {
                        ProgressView().scaleEffect(0.6)
                        Text("Generating commit message...")
                            .font(AXTypography.footnote)
                            .foregroundColor(.axTextMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AXSpacing.md)
                } else {
                    TextEditor(text: $vm.commitMessage)
                        .font(AXTypography.monoMd)
                        .scrollContentBackground(.hidden)
                        .padding(AXSpacing.sm)
                        .background(Color.axBackgroundTertiary)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.axBorder, lineWidth: 1))
                        .cornerRadius(AXCornerRadius.sm)
                        .frame(minHeight: 60, maxHeight: 100)
                }
                
                if !vm.isProPlan {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(AXTypography.caption2)
                        Text("Upgrade to Pro for AI-generated commit messages")
                            .font(AXTypography.caption2)
                    }
                    .foregroundColor(.axTextMuted)
                }
            }
            .padding(AXSpacing.md)
            
            Divider().background(Color.axBorder)
            
            // Actions
            HStack(spacing: AXSpacing.sm) {
                Button("Cancel") {
                    vm.showCommitSheet = false
                    vm.commitMessage = ""
                }
                .font(AXTypography.footnote).fontWeight(.medium)
                .foregroundColor(.axTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.axBackgroundTertiary)
                .cornerRadius(AXCornerRadius.sm)
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    Task { await vm.confirmPush() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(AXTypography.footnote)
                        Text("Commit & Push")
                            .font(AXTypography.footnote).fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.axAccentBlue)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .disabled(vm.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(AXSpacing.md)
        }
        .background(Color.axBackground)
        .frame(width: 420)
    }
    
    // ──────────────────────────────────────────────────────
    // MARK: - Setup Wizard (No Git)
    // ──────────────────────────────────────────────────────
    
    private var gitSetupWizard: some View {
        VStack(spacing: AXSpacing.xl) {
            // Hero
            VStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.05)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                    Image(systemName: "arrow.triangle.branch")
                        .font(AXTypography.largeTitle).fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                Text("Connect Git Repository")
                    .font(AXTypography.title2).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                
                Text("Clone an existing repository or initialize a new one.\nSupports GitHub, GitLab, Bitbucket, and any Git server.")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextTertiary)
                    .multilineTextAlignment(.center)
            }
            
            // Clone Form
            if vm.isCloning {
                cloneProgressView
            } else {
                cloneFormView
            }
            
            // — OR — divider
            HStack {
                Rectangle().fill(Color.axBorder.opacity(0.3)).frame(height: 1)
                Text("OR")
                    .font(AXTypography.caption).fontWeight(.bold)
                    .foregroundColor(.axTextMuted)
                    .padding(.horizontal, 12)
                Rectangle().fill(Color.axBorder.opacity(0.3)).frame(height: 1)
            }
            
            // Init Empty Repo
            Button(action: { Task { await vm.initRepository() } }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(AXTypography.body)
                    Text("Initialize Empty Repository")
                        .font(AXTypography.callout).fontWeight(.semibold)
                }
                .foregroundColor(.axAccentBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.axAccentBlue.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axAccentBlue.opacity(0.2), lineWidth: 1))
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: Clone Form
    
    private var cloneFormView: some View {
        VStack(spacing: AXSpacing.md) {
            // Repo URL
            VStack(alignment: .leading, spacing: 4) {
                Text("Repository URL")
                    .font(AXTypography.footnote).fontWeight(.semibold)
                    .foregroundColor(.axTextSecondary)
                
                HStack(spacing: AXSpacing.sm) {
                    providerIcon
                    
                    TextField("https://github.com/user/repo.git", text: $vm.cloneConfig.repoURL)
                        .font(AXTypography.monoMd)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, 8)
                .background(Color.axBackgroundTertiary)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                .cornerRadius(AXCornerRadius.sm)
            }
            
            // Branch
            HStack(spacing: AXSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Branch")
                        .font(AXTypography.footnote).fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)
                    TextField("main", text: $vm.cloneConfig.branch)
                        .font(AXTypography.monoMd)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 8)
                        .background(Color.axBackgroundTertiary)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                        .cornerRadius(AXCornerRadius.sm)
                }
                
                // Private toggle
                VStack(alignment: .leading, spacing: 4) {
                    Text("Private Repo")
                        .font(AXTypography.footnote).fontWeight(.semibold)
                        .foregroundColor(.axTextSecondary)
                    Toggle("", isOn: $vm.cloneConfig.isPrivate)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                        .labelsHidden()
                        .padding(.vertical, 4)
                }
                .frame(width: 80)
            }
            
            // Auth fields (if private)
            if vm.cloneConfig.isPrivate {
                VStack(spacing: AXSpacing.sm) {
                    HStack(spacing: AXSpacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username")
                                .font(AXTypography.footnote).fontWeight(.semibold)
                                .foregroundColor(.axTextSecondary)
                            TextField("username", text: $vm.cloneConfig.username)
                                .font(AXTypography.subheadline)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, 8)
                                .background(Color.axBackgroundTertiary)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Access Token")
                                .font(AXTypography.footnote).fontWeight(.semibold)
                                .foregroundColor(.axTextSecondary)
                            SecureField("ghp_xxxx...", text: $vm.cloneConfig.token)
                                .font(AXTypography.subheadline)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, 8)
                                .background(Color.axBackgroundTertiary)
                                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Clone Button
            Button(action: { Task { await vm.cloneRepository() } }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(AXTypography.headline)
                    Text("Clone Repository")
                        .font(AXTypography.callout).fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(colors: [.orange, .orange.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(AXCornerRadius.md)
                .shadow(color: .orange.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(vm.cloneConfig.repoURL.isEmpty)
            .opacity(vm.cloneConfig.repoURL.isEmpty ? 0.5 : 1)
        }
    }
    
    // Provider icon auto-detect
    private var providerIcon: some View {
        let provider = vm.cloneConfig.provider
        return Image(systemName: provider == .unknown ? "link" : provider.icon)
            .font(AXTypography.headline)
            .foregroundColor(provider == .github ? .white : provider == .gitlab ? .orange : .axAccentBlue)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(provider == .github ? Color.black : provider == .gitlab ? Color.orange.opacity(0.15) : Color.axAccentBlue.opacity(0.1))
            )
    }
    
    // MARK: Clone Progress
    
    private var cloneProgressView: some View {
        VStack(spacing: AXSpacing.lg) {
            // Progress bar
            VStack(spacing: AXSpacing.sm) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.axBackgroundTertiary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * vm.cloneProgress)
                            .animation(.spring(response: 0.5), value: vm.cloneProgress)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    HStack(spacing: 4) {
                        ProgressView().scaleEffect(0.5)
                        Text(vm.cloneStepMessage)
                            .font(AXTypography.footnote)
                            .foregroundColor(.axTextTertiary)
                    }
                    Spacer()
                    Text("\(Int(vm.cloneProgress * 100))%")
                        .font(AXTypography.monoSm).fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    // ──────────────────────────────────────────────────────
    // MARK: - Git Control Panel (Has Git)
    // ──────────────────────────────────────────────────────
    
    private var gitControlPanel: some View {
        VStack(spacing: AXSpacing.lg) {
            // Repo info header
            repoInfoHeader
            
            // Section tabs
            sectionTabs
            
            // Section content
            switch vm.selectedSection {
            case .quickActions:
                quickActionsSection
            case .branches:
                branchesSection
            case .commits:
                commitsSection
            case .fileChanges:
                fileChangesSection
            case .advanced:
                advancedSection
            }
        }
    }
    
    // MARK: Repo Info Header
    
    private var repoInfoHeader: some View {
        HStack(spacing: AXSpacing.lg) {
            // Provider & branch
            HStack(spacing: AXSpacing.sm) {
                providerBadge
                
                VStack(alignment: .leading, spacing: 2) {
                    if !vm.repoInfo.remoteURL.isEmpty {
                        Text(repoDisplayName)
                            .font(AXTypography.callout).fontWeight(.bold)
                            .foregroundColor(.axTextPrimary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(AXTypography.caption2).fontWeight(.bold)
                        Text(vm.repoInfo.currentBranch)
                            .font(AXTypography.monoSm).fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Stats chips
            HStack(spacing: 6) {
                statChip(icon: "doc.fill", value: "\(vm.repoInfo.trackedFiles)", label: "Files", color: .axAccentBlue)
                if vm.repoInfo.modifiedFiles > 0 {
                    statChip(icon: "pencil.circle.fill", value: "\(vm.repoInfo.modifiedFiles)", label: "Modified", color: .axWarning)
                }
                if vm.repoInfo.aheadCount > 0 {
                    statChip(icon: "arrow.up", value: "\(vm.repoInfo.aheadCount)", label: "Ahead", color: .axSuccess)
                }
                if vm.repoInfo.behindCount > 0 {
                    statChip(icon: "arrow.down", value: "\(vm.repoInfo.behindCount)", label: "Behind", color: .axError)
                }
            }
            
            // Refresh
            Button(action: { Task { await vm.loadAll() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(AXTypography.footnote).fontWeight(.bold)
                    .foregroundColor(.axAccentBlue)
                    .frame(width: 28, height: 28)
                    .background(Color.axAccentBlue.opacity(0.08))
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
            .help("Refresh")
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .fill(Color.axSurface)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.lg).stroke(Color.axBorder.opacity(0.3), lineWidth: 1))
        )
    }
    
    private var providerBadge: some View {
        let p = vm.repoInfo.provider
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(p == .github ? Color.white.opacity(0.1) : Color.orange.opacity(0.12))
                .frame(width: 36, height: 36)
            Image(systemName: p.icon)
                .font(AXTypography.title3)
                .foregroundColor(p == .github ? .white : .orange)
        }
    }
    
    private var repoDisplayName: String {
        let url = vm.repoInfo.remoteURL
        // Extract "user/repo" from URL
        let cleaned = url
            .replacingOccurrences(of: "https://github.com/", with: "")
            .replacingOccurrences(of: "https://gitlab.com/", with: "")
            .replacingOccurrences(of: ".git", with: "")
        return cleaned
    }
    
    // MARK: Section Tabs
    
    private var sectionTabs: some View {
        HStack(spacing: 4) {
            ForEach(GitSection.allCases) { section in
                let isActive = vm.selectedSection == section
                Button(action: {
                    withAnimation(.spring(response: 0.3)) { vm.selectedSection = section }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: section.icon)
                            .font(AXTypography.caption).fontWeight(.bold)
                        Text(section.rawValue)
                            .font(AXTypography.footnote).fontWeight(.semibold)
                    }
                    .foregroundColor(isActive ? .white : .axTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(isActive ? Color.orange : Color.axSurface)
                    )
                    .overlay(
                        Capsule().stroke(isActive ? Color.clear : Color.axBorder.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
    
    // ──────────────────────────────────────────────────────
    // MARK: - Quick Actions
    // ──────────────────────────────────────────────────────
    
    private var quickActionsSection: some View {
        VStack(spacing: AXSpacing.md) {
            // Action buttons
            HStack(spacing: AXSpacing.sm) {
                gitActionButton(icon: "arrow.down.circle.fill", label: "Pull", color: .axSuccess, loading: vm.isOperationRunning) {
                    Task { await vm.pull() }
                }
                gitActionButton(icon: "arrow.up.circle.fill", label: "Push", color: .axAccentBlue, loading: false) {
                    Task { await vm.push() }
                }
                gitActionButton(icon: "arrow.triangle.2.circlepath", label: "Fetch", color: .purple, loading: false) {
                    Task { await vm.fetch() }
                }
                gitActionButton(icon: "tray.and.arrow.down.fill", label: "Stash", color: .orange, loading: false) {
                    vm.showStashSheet = true
                }
                gitActionButton(icon: "arrow.counterclockwise", label: "Discard All", color: .axError, loading: false) {
                    Task { await vm.discardAll() }
                }
            }
            
            // Last commit
            if !vm.repoInfo.lastCommitMessage.isEmpty {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "clock")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Text("Last commit:")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextMuted)
                    Text(vm.repoInfo.lastCommitMessage)
                        .font(AXTypography.footnote).fontWeight(.medium)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text(vm.repoInfo.lastCommitDate)
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextTertiary)
                }
                .padding(AXSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(Color.axSurface.opacity(0.5))
                )
            }
            
            // Output console
            if !vm.operationOutput.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Output")
                        .font(AXTypography.caption).fontWeight(.bold)
                        .foregroundColor(.axTextMuted)
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        Text(vm.operationOutput)
                            .font(AXTypography.monoXs)
                            .foregroundColor(.axTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 120)
                }
                .padding(AXSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .fill(Color.black.opacity(0.3))
                )
            }
        }
    }
    
    // ──────────────────────────────────────────────────────
    // MARK: - Branches
    // ──────────────────────────────────────────────────────
    
    private var branchesSection: some View {
        VStack(spacing: AXSpacing.md) {
            // Header
            HStack {
                Text("Branches")
                    .font(AXTypography.callout).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                
                Text("\(vm.branches.filter { !$0.isRemote }.count) local")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.sm)
                
                Spacer()
                
                Button(action: { vm.showCreateBranchSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(AXTypography.caption).fontWeight(.bold)
                        Text("New Branch")
                            .font(AXTypography.footnote).fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            
            // Create branch inline
            if vm.showCreateBranchSheet {
                HStack(spacing: AXSpacing.sm) {
                    TextField("new-branch-name", text: $vm.newBranchName)
                        .font(AXTypography.monoMd)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, 7)
                        .background(Color.axBackgroundTertiary)
                        .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                        .cornerRadius(AXCornerRadius.sm)
                    
                    Button("Create") { Task { await vm.createBranch() } }
                        .font(AXTypography.footnote).fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.orange)
                        .cornerRadius(AXCornerRadius.sm)
                        .buttonStyle(.plain)
                    
                    Button(action: { vm.showCreateBranchSheet = false; vm.newBranchName = "" }) {
                        Image(systemName: "xmark")
                            .font(AXTypography.caption2).fontWeight(.bold)
                            .foregroundColor(.axTextMuted)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Local branches
            ForEach(vm.branches.filter { !$0.isRemote }) { branch in
                branchRow(branch)
            }
            
            // Remote branches (collapsible)
            let remoteBranches = vm.branches.filter { $0.isRemote }
            if !remoteBranches.isEmpty {
                DisclosureGroup {
                    ForEach(remoteBranches) { branch in
                        branchRow(branch)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "cloud")
                            .font(AXTypography.caption)
                        Text("Remote Branches (\(remoteBranches.count))")
                            .font(AXTypography.footnote).fontWeight(.medium)
                    }
                    .foregroundColor(.axTextSecondary)
                }
            }
        }
    }
    
    private func branchRow(_ branch: GitBranch) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: branch.isCurrent ? "checkmark.circle.fill" : "circle")
                .font(AXTypography.subheadline)
                .foregroundColor(branch.isCurrent ? .axSuccess : .axTextMuted)
            
            Text(branch.displayName)
                .font(AXTypography.monoMd).fontWeight(branch.isCurrent ? .bold : .medium)
                .foregroundColor(branch.isCurrent ? .axTextPrimary : .axTextSecondary)
            
            if branch.isCurrent {
                Text("CURRENT")
                    .font(AXTypography.caption2).fontWeight(.heavy)
                    .foregroundColor(.axSuccess)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.axSuccess.opacity(0.1))
                    .cornerRadius(AXCornerRadius.xs)
            }
            
            if branch.isRemote {
                Image(systemName: "cloud.fill")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
            
            Spacer()
            
            if !branch.isCurrent {
                HStack(spacing: 4) {
                    Button(action: { Task { await vm.switchBranch(branch) } }) {
                        Text("Switch")
                            .font(AXTypography.caption).fontWeight(.semibold)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.axAccentBlue.opacity(0.08))
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                    
                    if !branch.isRemote {
                        Button(action: { Task { await vm.mergeBranch(branch) } }) {
                            Image(systemName: "arrow.triangle.merge")
                                .font(AXTypography.caption2).fontWeight(.bold)
                                .foregroundColor(.purple)
                                .frame(width: 22, height: 22)
                                .background(Color.purple.opacity(0.08))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .help("Merge into current branch")
                        
                        Button(action: { Task { await vm.deleteBranch(branch) } }) {
                            Image(systemName: "trash")
                                .font(AXTypography.caption2).fontWeight(.bold)
                                .foregroundColor(.axError)
                                .frame(width: 22, height: 22)
                                .background(Color.axError.opacity(0.08))
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        .help("Delete branch")
                    }
                }
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                .fill(branch.isCurrent ? Color.axSuccess.opacity(0.04) : Color.clear)
        )
    }
    
    // ──────────────────────────────────────────────────────
    // MARK: - Commit History
    // ──────────────────────────────────────────────────────
    
    private var commitsSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.commits.prefix(30).enumerated()), id: \.element.id) { index, commit in
                VStack(spacing: 0) {
                    commitRow(commit, index: index)
                    
                    // Expanded detail
                    if vm.expandedCommitId == commit.id && !vm.commitDetail.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(vm.commitDetail) { file in
                                HStack(spacing: 6) {
                                    Image(systemName: file.status.icon)
                                        .font(AXTypography.caption2)
                                        .foregroundColor(fileStatusColor(file.status))
                                    Text(file.path)
                                        .font(AXTypography.monoXs)
                                        .foregroundColor(.axTextSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.leading, 36)
                        .padding(.vertical, AXSpacing.sm)
                        .padding(.horizontal, AXSpacing.md)
                        .background(Color.axBackgroundTertiary.opacity(0.5))
                        .transition(.opacity)
                    }
                }
            }
        }
    }
    
    private func commitRow(_ commit: GitCommit, index: Int) -> some View {
        HStack(spacing: AXSpacing.sm) {
            // Timeline dot
            VStack(spacing: 0) {
                if index > 0 {
                    Rectangle().fill(Color.axBorder.opacity(0.3)).frame(width: 1).frame(height: 8)
                }
                Circle()
                    .fill(index == 0 ? Color.orange : Color.axTextMuted.opacity(0.4))
                    .frame(width: 8, height: 8)
                Rectangle().fill(Color.axBorder.opacity(0.3)).frame(width: 1).frame(maxHeight: .infinity)
            }
            .frame(width: 8)
            
            // Hash
            Text(commit.shortHash)
                .font(AXTypography.monoXs).fontWeight(.bold)
                .foregroundColor(.orange)
                .frame(width: 55, alignment: .leading)
            
            // Message
            Text(commit.message)
                .font(AXTypography.footnote).fontWeight(.medium)
                .foregroundColor(.axTextPrimary)
                .lineLimit(1)
            
            Spacer()
            
            // Author
            Text(commit.author)
                .font(AXTypography.caption)
                .foregroundColor(.axTextTertiary)
            
            // Date
            Text(commit.relativeDate)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .frame(width: 70, alignment: .trailing)
            
            // Actions
            HStack(spacing: 3) {
                Button(action: { Task { await vm.loadCommitDetail(commit) } }) {
                    Image(systemName: vm.expandedCommitId == commit.id ? "chevron.up" : "chevron.down")
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 20, height: 20)
                        .background(Color.axBackgroundTertiary)
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .help("Show files")
                
                Button(action: { Task { await vm.checkoutCommit(commit) } }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(.axWarning)
                        .frame(width: 20, height: 20)
                        .background(Color.axWarning.opacity(0.08))
                        .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
                .help("Checkout this commit")
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, 6)
    }
    
    // ──────────────────────────────────────────────────────
    // MARK: - File Changes
    // ──────────────────────────────────────────────────────
    
    private var fileChangesSection: some View {
        VStack(spacing: AXSpacing.md) {
            if vm.fileChanges.isEmpty {
                VStack(spacing: AXSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AXTypography.largeTitle)
                        .foregroundColor(.axSuccess)
                    Text("Working tree clean")
                        .font(AXTypography.callout).fontWeight(.medium)
                        .foregroundColor(.axTextSecondary)
                    Text("No modified, added, or untracked files")
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // File change stats
                HStack(spacing: AXSpacing.sm) {
                    let modified = vm.fileChanges.filter { $0.status == .modified }.count
                    let added = vm.fileChanges.filter { $0.status == .added || $0.status == .untracked }.count
                    let deleted = vm.fileChanges.filter { $0.status == .deleted }.count
                    
                    if modified > 0 { changeStatBadge(count: modified, label: "Modified", color: .axWarning) }
                    if added > 0 { changeStatBadge(count: added, label: "Added", color: .axSuccess) }
                    if deleted > 0 { changeStatBadge(count: deleted, label: "Deleted", color: .axError) }
                    Spacer()
                }
                
                // File list
                ForEach(vm.fileChanges) { file in
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: file.status.icon)
                            .font(AXTypography.footnote)
                            .foregroundColor(fileStatusColor(file.status))
                        
                        Text(file.path)
                            .font(AXTypography.monoSm)
                            .foregroundColor(.axTextSecondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(file.status.displayName)
                            .font(AXTypography.caption2).fontWeight(.semibold)
                            .foregroundColor(fileStatusColor(file.status))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(fileStatusColor(file.status).opacity(0.08))
                            .cornerRadius(AXCornerRadius.xs)
                    }
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // ──────────────────────────────────────────────────────
    // MARK: - Advanced
    // ──────────────────────────────────────────────────────
    
    private var advancedSection: some View {
        VStack(spacing: AXSpacing.lg) {
            // Stash
            advancedCard(title: "Stash", icon: "tray.and.arrow.down.fill", color: .orange) {
                VStack(spacing: AXSpacing.sm) {
                    HStack(spacing: AXSpacing.sm) {
                        TextField("Stash message (optional)", text: $vm.stashMessage)
                            .font(AXTypography.footnote)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, 6)
                            .background(Color.axBackgroundTertiary)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.axBorder, lineWidth: 1))
                            .cornerRadius(AXCornerRadius.sm)
                        
                        Button("Save") { Task { await vm.stashSave() } }
                            .font(AXTypography.caption).fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(AXCornerRadius.sm)
                            .buttonStyle(.plain)
                        
                        Button("Pop") { Task { await vm.stashPop() } }
                            .font(AXTypography.caption).fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.08))
                            .cornerRadius(AXCornerRadius.sm)
                            .buttonStyle(.plain)
                    }
                    
                    if !vm.stashes.isEmpty {
                        ForEach(vm.stashes) { stash in
                            HStack {
                                Text(stash.index)
                                    .font(AXTypography.monoXxs).fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text(stash.message)
                                    .font(AXTypography.caption)
                                    .foregroundColor(.axTextSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Button(action: { Task { await vm.stashDrop(stash) } }) {
                                    Image(systemName: "trash")
                                        .font(AXTypography.caption2)
                                        .foregroundColor(.axError)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            
            // Tags
            advancedCard(title: "Tags", icon: "tag.fill", color: .cyan) {
                if vm.tags.isEmpty {
                    Text("No tags found")
                        .font(AXTypography.footnote)
                        .foregroundColor(.axTextTertiary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 6) {
                        ForEach(vm.tags) { tag in
                            Button(action: { Task { await vm.checkoutTag(tag) } }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "tag")
                                        .font(AXTypography.caption2)
                                    Text(tag.name)
                                        .font(AXTypography.monoXs).fontWeight(.medium)
                                }
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.cyan.opacity(0.08))
                                .cornerRadius(AXCornerRadius.sm)
                            }
                            .buttonStyle(.plain)
                            .help(tag.message.isEmpty ? "Checkout tag" : tag.message)
                        }
                    }
                }
            }
            
            // Remotes
            advancedCard(title: "Remotes", icon: "network", color: .purple) {
                VStack(spacing: AXSpacing.sm) {
                    ForEach(vm.remotes) { remote in
                        HStack(spacing: AXSpacing.sm) {
                            Text(remote.name)
                                .font(AXTypography.monoSm).fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text(remote.url)
                                .font(AXTypography.monoXs)
                                .foregroundColor(.axTextTertiary)
                                .lineLimit(1)
                            Text("(\(remote.type))")
                                .font(AXTypography.caption2)
                                .foregroundColor(.axTextMuted)
                            Spacer()
                            Button(action: { Task { await vm.removeRemote(remote) } }) {
                                Image(systemName: "trash")
                                    .font(AXTypography.caption2)
                                    .foregroundColor(.axError)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Add remote inline
                    if vm.showAddRemoteSheet {
                        HStack(spacing: AXSpacing.sm) {
                            TextField("name", text: $vm.newRemoteName)
                                .font(AXTypography.monoSm)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 5)
                                .background(Color.axBackgroundTertiary)
                                .cornerRadius(AXCornerRadius.sm)
                                .frame(width: 80)
                            TextField("https://...", text: $vm.newRemoteURL)
                                .font(AXTypography.monoSm)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 5)
                                .background(Color.axBackgroundTertiary)
                                .cornerRadius(AXCornerRadius.sm)
                            Button("Add") { Task { await vm.addRemote() } }
                                .font(AXTypography.caption).fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.purple)
                                .cornerRadius(AXCornerRadius.sm)
                                .buttonStyle(.plain)
                        }
                    } else {
                        Button(action: { vm.showAddRemoteSheet = true }) {
                            HStack(spacing: 3) {
                                Image(systemName: "plus").font(AXTypography.caption2).fontWeight(.bold)
                                Text("Add Remote").font(AXTypography.caption).fontWeight(.semibold)
                            }
                            .foregroundColor(.purple)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Danger Zone
            advancedCard(title: "Danger Zone", icon: "exclamationmark.triangle.fill", color: .axError) {
                VStack(spacing: AXSpacing.md) {
                    // Hard Reset
                    VStack(spacing: AXSpacing.sm) {
                        HStack(spacing: AXSpacing.sm) {
                            TextField("commit hash or HEAD~N", text: $vm.resetRef)
                                .font(AXTypography.monoSm)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, AXSpacing.sm)
                                .padding(.vertical, 6)
                                .background(Color.axBackgroundTertiary)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.axError.opacity(0.2), lineWidth: 1))
                                .cornerRadius(AXCornerRadius.sm)
                            
                            Button("Hard Reset") { Task { await vm.resetHard() } }
                                .font(AXTypography.caption).fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.axError)
                                .cornerRadius(AXCornerRadius.sm)
                                .buttonStyle(.plain)
                                .disabled(vm.resetRef.isEmpty)
                        }
                        
                        Text("⚠️ Hard reset is destructive and cannot be undone. All uncommitted changes will be lost.")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axError.opacity(0.7))
                    }
                    
                    Divider().background(Color.axBorder.opacity(0.2))
                    
                    // Disconnect Git
                    VStack(spacing: AXSpacing.sm) {
                        Button(action: { Task { await vm.disconnectGit() } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(AXTypography.subheadline)
                                Text("Disconnect Git Repository")
                                    .font(AXTypography.footnote).fontWeight(.bold)
                            }
                            .foregroundColor(.axError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.axError.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axError.opacity(0.2), lineWidth: 1))
                            .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(.plain)
                        
                        Text("Removes the .git directory. Your website files remain untouched.")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axError.opacity(0.7))
                    }
                }
            }
        }
    }
    
    // ──────────────────────────────────────────────────────
    // MARK: - Helpers
    // ──────────────────────────────────────────────────────
    
    private func gitActionButton(icon: String, label: String, color: Color, loading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if loading && vm.isOperationRunning {
                    ProgressView().scaleEffect(0.6)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: icon)
                        .font(AXTypography.title3)
                }
                Text(label)
                    .font(AXTypography.caption2).fontWeight(.semibold)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(color.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(color.opacity(0.15), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .disabled(vm.isOperationRunning)
    }
    
    private func statChip(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(AXTypography.caption2)
            Text(value)
                .font(AXTypography.caption).fontWeight(.bold)
            Text(label)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextTertiary)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.06))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private func changeStatBadge(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text("\(count)")
                .font(AXTypography.caption).fontWeight(.bold)
            Text(label)
                .font(AXTypography.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }
    
    private func advancedCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(AXTypography.footnote).fontWeight(.bold)
                    .foregroundColor(color)
                Text(title)
                    .font(AXTypography.subheadline).fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
            }
            
            content()
        }
        .padding(AXSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axSurface)
                .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.md).stroke(Color.axBorder.opacity(0.2), lineWidth: 1))
        )
    }
    
    private func fileStatusColor(_ status: GitFileStatus) -> Color {
        switch status {
        case .modified: return .axWarning
        case .added, .copied: return .axSuccess
        case .deleted: return .axError
        case .renamed: return .purple
        case .untracked: return .axTextMuted
        }
    }
    
    // MARK: Toast
    
    @ViewBuilder
    private var toastOverlay: some View {
        if let msg = vm.successMessage {
            toastView(msg, isSuccess: true)
        } else if let err = vm.errorMessage {
            toastView(err, isSuccess: false)
        }
    }
    
    private func toastView(_ message: String, isSuccess: Bool) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(AXTypography.body)
            Text(message)
                .font(AXTypography.subheadline).fontWeight(.medium)
                .lineLimit(2)
        }
        .foregroundColor(.white)
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.md)
        .background(
            Capsule().fill(isSuccess ? Color.axSuccess : Color.axError)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        )
        .padding(.bottom, AXSpacing.xl)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
