//
//  GitViewModel.swift
//  AevonX
//
//  ViewModel for per-website Git source control
//

import SwiftUI

import AevonXCoreBridge
import Combine

@MainActor
final class GitViewModel: ObservableObject {
    let serverId: String
    let documentRoot: String
    
    // MARK: - Published State
    
    @Published var repoInfo = GitRepoInfo()
    @Published var branches: [GitBranch] = []
    @Published var commits: [GitCommit] = []
    @Published var fileChanges: [GitFileChange] = []
    @Published var stashes: [GitStashEntry] = []
    @Published var tags: [GitTag] = []
    @Published var remotes: [GitRemote] = []
    
    @Published var isLoading = false
    @Published var isOperationRunning = false
    @Published var operationOutput = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Clone config
    @Published var cloneConfig = GitCloneConfig()
    @Published var isCloning = false
    @Published var cloneProgress: Double = 0
    @Published var cloneStepMessage = ""
    
    // UI State
    @Published var selectedSection: GitSection = .quickActions
    @Published var showCreateBranchSheet = false
    @Published var showMergeSheet = false
    @Published var showStashSheet = false
    @Published var showAddRemoteSheet = false
    @Published var showResetConfirm = false
    @Published var newBranchName = ""
    @Published var stashMessage = ""
    @Published var newRemoteName = ""
    @Published var newRemoteURL = ""
    @Published var resetRef = ""
    
    // Commit + Push sheet
    @Published var showCommitSheet = false
    @Published var commitMessage = ""
    @Published var isGeneratingCommitMessage = false
    @Published var isProPlan = false
    
    // Expanded commit detail
    @Published var expandedCommitId: String?
    @Published var commitDetail: [GitFileChange] = []
    
    init(serverId: String, documentRoot: String) {
        self.serverId = serverId
        self.documentRoot = documentRoot
    }
    
    // MARK: - Load All
    
    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            repoInfo = try await GitService.shared.getRepoInfo(documentRoot: documentRoot, serverId: serverId)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        
        guard repoInfo.hasGit else { return }
        
        // Fetch each independently — one failing shouldn't block the rest
        branches = (try? await GitService.shared.listBranches(documentRoot: documentRoot, serverId: serverId)) ?? []
        commits = (try? await GitService.shared.getLog(documentRoot: documentRoot, serverId: serverId)) ?? []
        fileChanges = (try? await GitService.shared.getStatus(documentRoot: documentRoot, serverId: serverId)) ?? []
        tags = (try? await GitService.shared.listTags(documentRoot: documentRoot, serverId: serverId)) ?? []
        remotes = (try? await GitService.shared.listRemotes(documentRoot: documentRoot, serverId: serverId)) ?? []
    }
    
    // MARK: - Clone
    
    func cloneRepository() async {
        guard !cloneConfig.repoURL.isEmpty else {
            errorMessage = "Repository URL is required"
            return
        }
        
        isCloning = true
        cloneProgress = 0
        errorMessage = nil
        
        do {
            // Step 1: Validate
            cloneStepMessage = "Validating repository URL..."
            cloneProgress = 0.1
            try await Task.sleep(nanoseconds: 300_000_000)
            
            // Step 2: Credentials
            if cloneConfig.isPrivate {
                cloneStepMessage = "Configuring credentials..."
                cloneProgress = 0.25
                try await GitService.shared.setCredentials(
                    username: cloneConfig.username,
                    token: cloneConfig.token,
                    documentRoot: documentRoot,
                    serverId: serverId
                )
            }
            
            // Step 3: Clone
            cloneStepMessage = "Cloning repository..."
            cloneProgress = 0.4
            let output = try await GitService.shared.cloneRepo(
                config: cloneConfig,
                documentRoot: documentRoot,
                serverId: serverId
            )
            operationOutput = output
            
            // Step 4: Verify
            cloneStepMessage = "Verifying clone..."
            cloneProgress = 0.85
            
            // Step 5: Done
            cloneStepMessage = "Repository cloned successfully!"
            cloneProgress = 1.0
            try await Task.sleep(nanoseconds: 500_000_000)
            
            successMessage = "Repository cloned successfully"
            
            // Reload all data
            await loadAll()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isCloning = false
    }
    
    // MARK: - Init
    
    func initRepository() async {
        await runOperation("Initializing repository") {
            let _ = try await GitService.shared.initRepo(documentRoot: self.documentRoot, serverId: self.serverId)
            await self.loadAll()
        }
    }
    
    // MARK: - Pull / Push / Fetch
    
    func pull() async {
        await runOperation("Pulling from remote") {
            let output = try await GitService.shared.pull(
                documentRoot: self.documentRoot,
                branch: self.repoInfo.currentBranch,
                serverId: self.serverId
            )
            self.operationOutput = output
            await self.loadAll()
        }
    }
    
    func push() async {
        // Smart push: check for changes first
        do {
            let hasChanges = try await GitService.shared.hasChanges(
                documentRoot: documentRoot,
                serverId: serverId
            )
            
            if hasChanges {
                // Check subscription
                let plan = await AevonXCoreBridge.SubscriptionManager.shared.currentPlan()
                isProPlan = (plan != "free")
                
                if isProPlan {
                    // Generate AI commit message
                    isGeneratingCommitMessage = true
                    do {
                        let diff = try await GitService.shared.getDiffSummary(
                            documentRoot: documentRoot,
                            serverId: serverId
                        )
                        let aiMessage = try await AIGitAPIService.shared.generateCommitMessage(diff: diff)
                        commitMessage = aiMessage
                    } catch {
                        // AI failed — provide fallback
                        commitMessage = "chore: update files"
                    }
                    isGeneratingCommitMessage = false
                } else {
                    commitMessage = ""
                }
                
                // Show commit sheet for user to review/edit
                showCommitSheet = true
                return
            }
            
            // No changes — push directly
            await directPush()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Push directly without committing (no local changes)
    func directPush() async {
        await runOperation("Pushing to remote") {
            let output = try await GitService.shared.push(
                documentRoot: self.documentRoot,
                branch: self.repoInfo.currentBranch,
                serverId: self.serverId
            )
            self.operationOutput = output
            await self.loadAll()
        }
    }
    
    /// Commit staged changes and push (called from commit sheet)
    func confirmPush() async {
        showCommitSheet = false
        
        let msg = commitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !msg.isEmpty else {
            errorMessage = "Commit message cannot be empty"
            return
        }
        
        await runOperation("Committing & Pushing") {
            // Stage all changes before commit
            let _ = try await GitService.shared.stageAll(
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            // Commit
            let _ = try await GitService.shared.commitAll(
                message: msg,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            
            // Push
            let output = try await GitService.shared.push(
                documentRoot: self.documentRoot,
                branch: self.repoInfo.currentBranch,
                serverId: self.serverId
            )
            self.operationOutput = output
            self.commitMessage = ""
            await self.loadAll()
        }
    }
    
    func fetch() async {
        await runOperation("Fetching from remote") {
            let _ = try await GitService.shared.fetch(documentRoot: self.documentRoot, serverId: self.serverId)
            await self.loadAll()
        }
    }
    
    // MARK: - Branches
    
    func switchBranch(_ branch: GitBranch) async {
        await runOperation("Switching to \(branch.displayName)") {
            let _ = try await GitService.shared.switchBranch(
                to: branch.name,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            await self.loadAll()
        }
    }
    
    func createBranch() async {
        guard !newBranchName.isEmpty else { return }
        await runOperation("Creating branch \(newBranchName)") {
            let _ = try await GitService.shared.createBranch(
                name: self.newBranchName,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            self.newBranchName = ""
            self.showCreateBranchSheet = false
            await self.loadAll()
        }
    }
    
    func deleteBranch(_ branch: GitBranch) async {
        await runOperation("Deleting branch \(branch.name)") {
            let _ = try await GitService.shared.deleteBranch(
                name: branch.name,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            await self.loadAll()
        }
    }
    
    func mergeBranch(_ branch: GitBranch) async {
        await runOperation("Merging \(branch.name)") {
            let _ = try await GitService.shared.mergeBranch(
                name: branch.name,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            await self.loadAll()
        }
    }
    
    // MARK: - Commit Operations
    
    func checkoutCommit(_ commit: GitCommit) async {
        await runOperation("Checking out \(commit.shortHash)") {
            let _ = try await GitService.shared.checkoutCommit(
                hash: commit.id,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            await self.loadAll()
        }
    }
    
    func loadCommitDetail(_ commit: GitCommit) async {
        if expandedCommitId == commit.id {
            expandedCommitId = nil
            commitDetail = []
            return
        }
        do {
            commitDetail = try await GitService.shared.getCommitDetail(
                hash: commit.id,
                documentRoot: documentRoot,
                serverId: serverId
            )
            expandedCommitId = commit.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Stash
    
    func stashSave() async {
        await runOperation("Stashing changes") {
            let _ = try await GitService.shared.stashSave(
                message: self.stashMessage,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            self.stashMessage = ""
            self.showStashSheet = false
            self.stashes = try await GitService.shared.stashList(documentRoot: self.documentRoot, serverId: self.serverId)
            await self.loadAll()
        }
    }
    
    func stashPop() async {
        await runOperation("Applying stash") {
            let _ = try await GitService.shared.stashPop(documentRoot: self.documentRoot, serverId: self.serverId)
            self.stashes = try await GitService.shared.stashList(documentRoot: self.documentRoot, serverId: self.serverId)
            await self.loadAll()
        }
    }
    
    func stashDrop(_ entry: GitStashEntry) async {
        await runOperation("Dropping stash") {
            let _ = try await GitService.shared.stashDrop(index: entry.index, documentRoot: self.documentRoot, serverId: self.serverId)
            self.stashes = try await GitService.shared.stashList(documentRoot: self.documentRoot, serverId: self.serverId)
        }
    }
    
    func loadStashes() async {
        do {
            stashes = try await GitService.shared.stashList(documentRoot: documentRoot, serverId: serverId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Tags
    
    func checkoutTag(_ tag: GitTag) async {
        await runOperation("Checking out tag \(tag.name)") {
            let _ = try await GitService.shared.checkoutTag(
                name: tag.name,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            await self.loadAll()
        }
    }
    
    // MARK: - Remotes
    
    func addRemote() async {
        guard !newRemoteName.isEmpty, !newRemoteURL.isEmpty else { return }
        await runOperation("Adding remote \(newRemoteName)") {
            let _ = try await GitService.shared.addRemote(
                name: self.newRemoteName,
                url: self.newRemoteURL,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            self.newRemoteName = ""
            self.newRemoteURL = ""
            self.showAddRemoteSheet = false
            self.remotes = try await GitService.shared.listRemotes(documentRoot: self.documentRoot, serverId: self.serverId)
        }
    }
    
    func removeRemote(_ remote: GitRemote) async {
        await runOperation("Removing remote \(remote.name)") {
            let _ = try await GitService.shared.removeRemote(
                name: remote.name,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            self.remotes = try await GitService.shared.listRemotes(documentRoot: self.documentRoot, serverId: self.serverId)
        }
    }
    
    // MARK: - Reset
    
    func resetHard() async {
        guard !resetRef.isEmpty else { return }
        await runOperation("Hard reset to \(resetRef)") {
            let _ = try await GitService.shared.resetHard(
                ref: self.resetRef,
                documentRoot: self.documentRoot,
                serverId: self.serverId
            )
            self.resetRef = ""
            self.showResetConfirm = false
            await self.loadAll()
        }
    }
    
    func discardAll() async {
        await runOperation("Discarding all changes") {
            let _ = try await GitService.shared.discardAll(documentRoot: self.documentRoot, serverId: self.serverId)
            await self.loadAll()
        }
    }
    
    // MARK: - Disconnect
    
    func disconnectGit() async {
        await runOperation("Disconnecting Git") {
            let _ = try await GitService.shared.disconnectGit(documentRoot: self.documentRoot, serverId: self.serverId)
            self.repoInfo = GitRepoInfo(hasGit: false)
            self.branches = []
            self.commits = []
            self.fileChanges = []
            self.stashes = []
            self.tags = []
            self.remotes = []
        }
    }
    
    // MARK: - Helpers
    
    private func runOperation(_ name: String, action: @escaping () async throws -> Void) async {
        isOperationRunning = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await action()
            successMessage = "\(name) completed"
        } catch {
            errorMessage = "\(name) failed: \(error.localizedDescription)"
        }
        
        isOperationRunning = false
        
        // Auto-dismiss success message
        if successMessage != nil {
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                successMessage = nil
            }
        }
    }
}

// MARK: - Git Section

enum GitSection: String, CaseIterable, Identifiable {
    case quickActions = "Quick Actions"
    case branches = "Branches"
    case commits = "Commit History"
    case fileChanges = "File Changes"
    case advanced = "Advanced"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .quickActions: return "bolt.fill"
        case .branches: return "arrow.triangle.branch"
        case .commits: return "clock.arrow.circlepath"
        case .fileChanges: return "doc.text.magnifyingglass"
        case .advanced: return "wrench.and.screwdriver.fill"
        }
    }
}
