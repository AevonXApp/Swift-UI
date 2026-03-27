//
//  FileManagerVM+Git.swift
//  AevonX
//
//  Extension: Git integration — detection, status, pull/push/fetch,
//  commit, branch, stash, tags, remotes, reset.
//

import SwiftUI
import AevonXCoreBridge

// MARK: - Git Detection & Status

extension FileManagerViewModel {

    /// Called after navigating to a new directory. Detects .git and loads info.
    func detectGit() async {
        let path = currentPath
        guard !path.isEmpty else {
            isGitRepo = false
            return
        }

        do {
            isGitRepo = try await GitService.shared.detectGit(documentRoot: path, serverId: serverId)
        } catch {
            isGitRepo = false
        }

        if isGitRepo {
            await loadGitInfo()
        } else {
            gitInfo = GitRepoInfo()
            gitFileChanges = []
        }
    }

    /// Load repo info + file status (lightweight, called after every nav + operation).
    func loadGitInfo() async {
        let path = currentPath
        guard isGitRepo else { return }

        do {
            gitInfo = try await GitService.shared.getRepoInfo(documentRoot: path, serverId: serverId)
            gitFileChanges = try await GitService.shared.getStatus(documentRoot: path, serverId: serverId)
        } catch {
            gitInfo = GitRepoInfo()
            gitFileChanges = []
        }
    }

    /// Load full git data (branches, tags, remotes, stashes) for sheets.
    func loadGitFull() async {
        let path = currentPath
        gitBranches = (try? await GitService.shared.listBranches(documentRoot: path, serverId: serverId)) ?? []
        gitTags = (try? await GitService.shared.listTags(documentRoot: path, serverId: serverId)) ?? []
        gitRemotes = (try? await GitService.shared.listRemotes(documentRoot: path, serverId: serverId)) ?? []
        gitStashes = (try? await GitService.shared.stashList(documentRoot: path, serverId: serverId)) ?? []
    }

    /// Load commit log.
    func loadGitLog() async {
        let path = currentPath
        gitCommits = (try? await GitService.shared.getLog(documentRoot: path, serverId: serverId)) ?? []
    }

    /// Git status for a specific file path (relative to repo root).
    func gitStatusForFile(_ fileName: String) -> GitFileStatus? {
        gitFileChanges.first(where: { $0.path.hasSuffix(fileName) })?.status
    }
}

// MARK: - Git Operations

extension FileManagerViewModel {

    func gitPull() async {
        await runGitOp(L10n.FileGit.Op.pulling) {
            _ = try await GitService.shared.pull(documentRoot: self.currentPath, serverId: self.serverId)
        }
        await loadFiles()
    }

    func gitPush() async {
        await runGitOp(L10n.FileGit.Op.pushing) {
            _ = try await GitService.shared.push(documentRoot: self.currentPath, serverId: self.serverId)
        }
    }

    func gitFetch() async {
        await runGitOp(L10n.FileGit.Op.fetching) {
            _ = try await GitService.shared.fetch(documentRoot: self.currentPath, serverId: self.serverId)
        }
    }

    func gitCommitAll() async {
        let msg = gitCommitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !msg.isEmpty else { return }

        await runGitOp(L10n.FileGit.Op.committing) {
            _ = try await GitService.shared.stageAll(documentRoot: self.currentPath, serverId: self.serverId)
            _ = try await GitService.shared.commitAll(message: msg, documentRoot: self.currentPath, serverId: self.serverId)
        }
        gitCommitMessage = ""
        showGitCommitSheet = false
    }

    func gitSwitchBranch(_ branch: String) async {
        await runGitOp(L10n.FileGit.Op.switching) {
            _ = try await GitService.shared.switchBranch(to: branch, documentRoot: self.currentPath, serverId: self.serverId)
        }
        await loadFiles()
    }

    func gitCreateBranch() async {
        let name = gitNewBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        await runGitOp(L10n.FileGit.Op.switching) {
            _ = try await GitService.shared.createBranch(name: name, documentRoot: self.currentPath, serverId: self.serverId)
        }
        gitNewBranchName = ""
    }

    func gitDeleteBranch(_ name: String) async {
        await runGitOp(L10n.FileGit.Op.deleting) {
            _ = try await GitService.shared.deleteBranch(name: name, documentRoot: self.currentPath, serverId: self.serverId)
        }
    }

    func gitMergeBranch(_ name: String) async {
        await runGitOp(L10n.FileGit.Op.merging) {
            _ = try await GitService.shared.mergeBranch(name: name, documentRoot: self.currentPath, serverId: self.serverId)
        }
        await loadFiles()
    }

    // MARK: - Stash

    func gitStashSave() async {
        await runGitOp(L10n.FileGit.Op.stashing) {
            _ = try await GitService.shared.stashSave(message: self.gitStashMessage, documentRoot: self.currentPath, serverId: self.serverId)
        }
        gitStashMessage = ""
        await loadFiles()
    }

    func gitStashPop() async {
        await runGitOp(L10n.FileGit.Op.poppingStash) {
            _ = try await GitService.shared.stashPop(documentRoot: self.currentPath, serverId: self.serverId)
        }
        await loadFiles()
    }

    func gitStashDrop(_ index: String) async {
        await runGitOp(L10n.FileGit.Op.droppingStash) {
            _ = try await GitService.shared.stashDrop(index: index, documentRoot: self.currentPath, serverId: self.serverId)
        }
    }

    // MARK: - Tags

    func gitCheckoutTag(_ name: String) async {
        await runGitOp(L10n.FileGit.Op.checkingOutTag) {
            _ = try await GitService.shared.checkoutTag(name: name, documentRoot: self.currentPath, serverId: self.serverId)
        }
        await loadFiles()
    }

    // MARK: - Checkout Commit

    func gitCheckoutCommit(_ hash: String) async {
        await runGitOp(L10n.FileGit.Op.checkingOut) {
            _ = try await GitService.shared.checkoutCommit(hash: hash, documentRoot: self.currentPath, serverId: self.serverId)
        }
        await loadGitLog()
        await loadFiles()
    }

    // MARK: - Remotes

    func gitAddRemote() async {
        let name = gitNewRemoteName.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = gitNewRemoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !url.isEmpty else { return }

        await runGitOp(L10n.FileGit.Op.addingRemote) {
            _ = try await GitService.shared.addRemote(name: name, url: url, documentRoot: self.currentPath, serverId: self.serverId)
        }
        gitNewRemoteName = ""
        gitNewRemoteURL = ""
    }

    func gitRemoveRemote(_ name: String) async {
        await runGitOp(L10n.FileGit.Op.removingRemote) {
            _ = try await GitService.shared.removeRemote(name: name, documentRoot: self.currentPath, serverId: self.serverId)
        }
    }

    // MARK: - Danger Zone

    func gitResetHard() async {
        await runGitOp(L10n.FileGit.Op.resetting) {
            _ = try await GitService.shared.resetHard(ref: "HEAD", documentRoot: self.currentPath, serverId: self.serverId)
        }
        await loadFiles()
    }

    func gitDiscardAll() async {
        await runGitOp(L10n.FileGit.Op.discarding) {
            _ = try await GitService.shared.discardAll(documentRoot: self.currentPath, serverId: self.serverId)
        }
        await loadFiles()
    }

    func gitDisconnect() async {
        await runGitOp(L10n.FileGit.Op.disconnecting) {
            _ = try await GitService.shared.disconnectGit(documentRoot: self.currentPath, serverId: self.serverId)
        }
        isGitRepo = false
        gitInfo = GitRepoInfo()
        gitFileChanges = []
        await loadFiles()
    }

    func executeGitDangerAction() async {
        guard let action = gitDangerAction else { return }
        switch action {
        case .resetHard: await gitResetHard()
        case .discardAll: await gitDiscardAll()
        case .disconnect: await gitDisconnect()
        }
        gitDangerAction = nil
    }

    // MARK: - Helper

    private func runGitOp(_ message: String, _ operation: @escaping () async throws -> Void) async {
        gitOperationRunning = true
        gitOperationMessage = message
        do {
            try await operation()
            gitOperationMessage = nil
        } catch {
            gitOperationMessage = error.localizedDescription
            try? await Task.sleep(for: .seconds(2))
            gitOperationMessage = nil
        }
        gitOperationRunning = false
        await loadGitInfo()
    }
}
