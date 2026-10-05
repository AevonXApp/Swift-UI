//
//  GitService.swift
//  AevonXCore
//
//  SSH-based Git management service for per-website source control
//

import Foundation

public actor GitService {
    public static let shared = GitService()
    private init() {}
    
    /// Helper: prefix every git command with safe.directory to avoid "dubious ownership" errors
    /// Verify that Git feature is allowed by the Ed25519-signed permit.
    private func requireGitFeature() async throws {
        let allowed = await FeatureGateManager.shared.isFeatureEnabled(FeatureKey.git.rawValue)
        guard allowed else {
            throw NSError(domain: "GitService", code: 403, userInfo: [
                NSLocalizedDescriptionKey: "Git integration requires a Pro subscription"
            ])
        }
    }

    /// Helper: prefix every git command with safe.directory to avoid "dubious ownership" errors
    private func gitCmd(_ cmd: String, documentRoot: String) -> String {
        return "cd '\(documentRoot)' && git config --global --add safe.directory '\(documentRoot)' 2>/dev/null; cd '\(documentRoot)' && \(cmd)"
    }
    
    // MARK: - Detection
    
    /// Check if a directory contains a git repo
    public func detectGit(documentRoot: String, serverId: String) async throws -> Bool {
        let result = try await SSHBridge.shared.execute(
            "test -d '\(documentRoot)/.git' && echo 'GIT_YES' || echo 'GIT_NO'",
            serverId: serverId
        )
        return result.stdout.contains("GIT_YES")
    }
    
    /// Get full repository info
    public func getRepoInfo(documentRoot: String, serverId: String) async throws -> GitRepoInfo {
        let result = try await SSHBridge.shared.execute(
            """
            cd '\(documentRoot)' 2>/dev/null || exit 1
            if [ ! -d .git ]; then echo 'NO_GIT'; exit 0; fi
            git config --global --add safe.directory '\(documentRoot)' 2>/dev/null
            echo "BRANCH:$(git branch --show-current 2>/dev/null)"
            echo "REMOTE:$(git remote get-url origin 2>/dev/null || echo 'none')"
            echo "TRACKED:$(git ls-files 2>/dev/null | wc -l | tr -d ' ')"
            echo "MODIFIED:$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')"
            echo "UNTRACKED:$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')"
            echo "AHEAD:$(git rev-list --count @{u}..HEAD 2>/dev/null || echo '0')"
            echo "BEHIND:$(git rev-list --count HEAD..@{u} 2>/dev/null || echo '0')"
            echo "LAST_MSG:$(git log -1 --pretty=format:'%s' 2>/dev/null || echo '')"
            echo "LAST_DATE:$(git log -1 --pretty=format:'%ar' 2>/dev/null || echo '')"
            """,
            serverId: serverId
        )
        
        let stdout = result.stdout
        if stdout.contains("NO_GIT") {
            return GitRepoInfo(hasGit: false)
        }
        
        func extract(_ key: String) -> String {
            guard let line = stdout.components(separatedBy: "\n").first(where: { $0.hasPrefix(key) }) else { return "" }
            return String(line.dropFirst(key.count)).trimmingCharacters(in: .whitespaces)
        }
        
        let remoteURL = extract("REMOTE:")
        
        return GitRepoInfo(
            hasGit: true,
            currentBranch: extract("BRANCH:"),
            remoteURL: remoteURL == "none" ? "" : remoteURL,
            provider: GitProvider.detect(from: remoteURL),
            trackedFiles: Int(extract("TRACKED:")) ?? 0,
            modifiedFiles: Int(extract("MODIFIED:")) ?? 0,
            untrackedFiles: Int(extract("UNTRACKED:")) ?? 0,
            aheadCount: Int(extract("AHEAD:")) ?? 0,
            behindCount: Int(extract("BEHIND:")) ?? 0,
            lastCommitMessage: extract("LAST_MSG:"),
            lastCommitDate: extract("LAST_DATE:")
        )
    }
    
    // MARK: - Clone
    
    /// Clone a repository into the document root
    public func cloneRepo(config: GitCloneConfig, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let url = config.authenticatedURL
        let branchArg = config.branch.isEmpty ? "" : " -b '\(config.branch)'"
        
        let result = try await SSHBridge.shared.execute(
            """
            cd '\(documentRoot)' || exit 1
            git config --global --add safe.directory '\(documentRoot)' 2>/dev/null
            # Remove existing content to clone into
            find . -maxdepth 1 ! -name '.' ! -name '..' -exec rm -rf {} + 2>/dev/null
            git clone\(branchArg) '\(url)' . 2>&1
            """,
            serverId: serverId
        )
        
        if result.exitCode != 0 {
            let err = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "GitService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Clone failed: \(err)"
            ])
        }
        
        return result.stdout
    }
    
    /// Initialize a new git repo
    public func initRepo(documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git init 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    /// Remove .git directory (disconnect from git)
    public func disconnectGit(documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            "rm -rf '\(documentRoot)/.git' 2>&1",
            serverId: serverId
        )
        return result.stdout
    }
    
    // MARK: - Pull / Push / Fetch
    
    /// Auto-detect the first configured remote name (falls back to "origin")
    private func detectRemote(documentRoot: String, serverId: String) async -> String {
        let result = try? await SSHBridge.shared.execute(
            gitCmd("git remote 2>/dev/null | head -1", documentRoot: documentRoot),
            serverId: serverId
        )
        let name = result?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "origin" : name
    }
    
    public func pull(documentRoot: String, branch: String = "", serverId: String) async throws -> String {
        try await requireGitFeature()
        let remote = await detectRemote(documentRoot: documentRoot, serverId: serverId)
        let branchArg = branch.isEmpty ? "" : " '\(remote)' '\(branch)'"
        let result = try await SSHBridge.shared.execute(
            gitCmd("git pull\(branchArg) 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        if result.exitCode != 0 && !result.stdout.contains("Already up to date") {
            throw NSError(domain: "GitService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr
            ])
        }
        return result.stdout
    }
    
    public func push(documentRoot: String, branch: String = "", serverId: String) async throws -> String {
        try await requireGitFeature()
        let remote = await detectRemote(documentRoot: documentRoot, serverId: serverId)
        let branchArg = branch.isEmpty ? "" : " '\(remote)' '\(branch)'"
        let result = try await SSHBridge.shared.execute(
            gitCmd("git push\(branchArg) 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        if result.exitCode != 0 {
            throw NSError(domain: "GitService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr
            ])
        }
        return result.stdout
    }
    
    public func fetch(documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git fetch --all 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    // MARK: - Branches
    
    public func listBranches(documentRoot: String, serverId: String) async throws -> [GitBranch] {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git branch -a --no-color 2>/dev/null", documentRoot: documentRoot),
            serverId: serverId
        )
        
        var branches: [GitBranch] = []
        for line in result.stdout.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if trimmed.contains("->") { continue }
            
            let isCurrent = trimmed.hasPrefix("*")
            let name = trimmed
                .replacingOccurrences(of: "* ", with: "")
                .replacingOccurrences(of: "remotes/", with: "")
                .trimmingCharacters(in: .whitespaces)
            let isRemote = line.contains("remotes/")
            
            branches.append(GitBranch(name: name, isRemote: isRemote, isCurrent: isCurrent))
        }
        
        return branches
    }
    
    public func switchBranch(to branch: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git checkout '\(branch)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        if result.exitCode != 0 {
            throw NSError(domain: "GitService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr
            ])
        }
        return result.stdout
    }
    
    public func createBranch(name: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git checkout -b '\(name)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        if result.exitCode != 0 {
            throw NSError(domain: "GitService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr
            ])
        }
        return result.stdout
    }
    
    public func deleteBranch(name: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git branch -d '\(name)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    public func mergeBranch(name: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git merge '\(name)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        if result.exitCode != 0 {
            throw NSError(domain: "GitService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr
            ])
        }
        return result.stdout
    }
    
    // MARK: - Commit History
    
    public func getLog(documentRoot: String, count: Int = 50, serverId: String) async throws -> [GitCommit] {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git log --pretty=format:'%H||%h||%s||%an||%ai||%ar' -\(count) 2>/dev/null || echo ''", documentRoot: documentRoot),
            serverId: serverId
        )
        
        // Empty repo — no commits yet
        if result.exitCode != 0 || result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        
        var commits: [GitCommit] = []
        for line in result.stdout.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: "||")
            guard parts.count >= 6 else { continue }
            commits.append(GitCommit(
                id: parts[0],
                shortHash: parts[1],
                message: parts[2],
                author: parts[3],
                date: parts[4],
                relativeDate: parts[5]
            ))
        }
        return commits
    }
    
    public func getCommitDetail(hash: String, documentRoot: String, serverId: String) async throws -> [GitFileChange] {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git show '\(hash)' --name-status --pretty=format:'' 2>/dev/null", documentRoot: documentRoot),
            serverId: serverId
        )
        
        var changes: [GitFileChange] = []
        for line in result.stdout.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, trimmed.count > 2 else { continue }
            
            let statusChar = String(trimmed.prefix(1))
            let path = String(trimmed.dropFirst(1)).trimmingCharacters(in: .whitespaces)
            
            let status: GitFileStatus
            switch statusChar {
            case "M": status = .modified
            case "A": status = .added
            case "D": status = .deleted
            case "R": status = .renamed
            case "C": status = .copied
            default: status = .modified
            }
            
            changes.append(GitFileChange(path: path, status: status))
        }
        return changes
    }
    
    /// Checkout a specific commit (detached HEAD)
    public func checkoutCommit(hash: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git checkout '\(hash)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    // MARK: - Status / Diff
    
    public func getStatus(documentRoot: String, serverId: String) async throws -> [GitFileChange] {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git status --porcelain 2>/dev/null", documentRoot: documentRoot),
            serverId: serverId
        )
        
        var changes: [GitFileChange] = []
        for line in result.stdout.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .init(charactersIn: " "))
            guard trimmed.count > 2 else { continue }
            
            let statusStr = String(trimmed.prefix(2)).trimmingCharacters(in: .whitespaces)
            let path = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            
            let status: GitFileStatus
            switch statusStr {
            case "M", "MM": status = .modified
            case "A", "AM": status = .added
            case "D": status = .deleted
            case "R": status = .renamed
            case "??": status = .untracked
            default: status = .modified
            }
            
            changes.append(GitFileChange(path: path, status: status))
        }
        return changes
    }
    
    public func getDiff(documentRoot: String, serverId: String) async throws -> String {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git diff --stat 2>/dev/null", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    public func getFileDiff(path: String, documentRoot: String, serverId: String) async throws -> String {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git diff '\(path)' 2>/dev/null", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    // MARK: - Stash
    
    public func stashSave(message: String = "", documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let msgArg = message.isEmpty ? "" : " push -m '\(message)'"
        let result = try await SSHBridge.shared.execute(
            gitCmd("git stash\(msgArg) 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    public func stashList(documentRoot: String, serverId: String) async throws -> [GitStashEntry] {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git stash list 2>/dev/null", documentRoot: documentRoot),
            serverId: serverId
        )
        
        var entries: [GitStashEntry] = []
        for line in result.stdout.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let parts = trimmed.components(separatedBy: ": ")
            let index = parts.first ?? ""
            let branch = parts.count > 1 ? parts[1].replacingOccurrences(of: "On ", with: "") : ""
            let message = parts.count > 2 ? parts[2...].joined(separator: ": ") : trimmed
            
            entries.append(GitStashEntry(index: index, message: message, branch: branch))
        }
        return entries
    }
    
    public func stashPop(documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git stash pop 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    public func stashDrop(index: String = "", documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let ref = index.isEmpty ? "" : " '\(index)'"
        let result = try await SSHBridge.shared.execute(
            gitCmd("git stash drop\(ref) 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    // MARK: - Tags
    
    public func listTags(documentRoot: String, serverId: String) async throws -> [GitTag] {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git tag -l -n1 2>/dev/null", documentRoot: documentRoot),
            serverId: serverId
        )
        
        var tags: [GitTag] = []
        for line in result.stdout.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let parts = trimmed.components(separatedBy: CharacterSet.whitespaces).filter { !$0.isEmpty }
            let name = parts.first ?? ""
            let message = parts.count > 1 ? parts[1...].joined(separator: " ") : ""
            tags.append(GitTag(name: name, message: message))
        }
        return tags
    }
    
    public func checkoutTag(name: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git checkout 'tags/\(name)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    // MARK: - Remotes
    
    public func listRemotes(documentRoot: String, serverId: String) async throws -> [GitRemote] {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git remote -v 2>/dev/null", documentRoot: documentRoot),
            serverId: serverId
        )
        
        var remotes: [GitRemote] = []
        for line in result.stdout.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let parts = trimmed.components(separatedBy: CharacterSet.whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 3 else { continue }
            
            let type = parts[2].replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            remotes.append(GitRemote(name: parts[0], url: parts[1], type: type))
        }
        return remotes
    }
    
    public func addRemote(name: String, url: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git remote add '\(name)' '\(url)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    public func removeRemote(name: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git remote remove '\(name)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    // MARK: - Reset
    
    /// Hard reset to a reference (⚠️ destructive)
    public func resetHard(ref: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git reset --hard '\(ref)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    /// Discard all local changes
    public func discardAll(documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git checkout -- . 2>&1 && git clean -fd 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    // MARK: - Credentials
    
    /// Store git credentials for private repos
    public func setCredentials(username: String, token: String, documentRoot: String, serverId: String) async throws {
        try await requireGitFeature()
        let _ = try await SSHBridge.shared.execute(
            """
            cd '\(documentRoot)'
            git config --global --add safe.directory '\(documentRoot)' 2>/dev/null
            git config credential.helper store
            echo 'https://\(username):\(token)@github.com' > ~/.git-credentials 2>/dev/null
            chmod 600 ~/.git-credentials 2>/dev/null
            """,
            serverId: serverId
        )
    }
    
    // MARK: - Commit Flow (Smart Push)
    
    /// Check if there are uncommitted changes
    public func hasChanges(documentRoot: String, serverId: String) async throws -> Bool {
        let result = try await SSHBridge.shared.execute(
            gitCmd("git status --porcelain 2>/dev/null", documentRoot: documentRoot),
            serverId: serverId
        )
        return !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Stage all changes (git add .)
    public func stageAll(documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        let result = try await SSHBridge.shared.execute(
            gitCmd("git add -A 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        return result.stdout
    }
    
    /// Commit staged changes with a message
    public func commitAll(message: String, documentRoot: String, serverId: String) async throws -> String {
        try await requireGitFeature()
        // Escape single quotes in the message
        let escapedMsg = message.replacingOccurrences(of: "'", with: "'\\''")
        let result = try await SSHBridge.shared.execute(
            gitCmd("git commit -m '\\(escapedMsg)' 2>&1", documentRoot: documentRoot),
            serverId: serverId
        )
        if result.exitCode != 0 && !result.stdout.contains("nothing to commit") {
            throw NSError(domain: "GitService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr
            ])
        }
        return result.stdout
    }
    
    /// Get diff summary for AI commit message generation
    public func getDiffSummary(documentRoot: String, serverId: String) async throws -> String {
        // Get file list + stat + actual diff for rich context
        let result = try await SSHBridge.shared.execute(
            gitCmd("""
            echo '=== FILES CHANGED ==='; \
            git status --short 2>/dev/null; \
            echo ''; \
            echo '=== DIFF STAT ==='; \
            git diff --cached --stat 2>/dev/null; \
            echo ''; \
            echo '=== DIFF ==='; \
            git diff --cached 2>/dev/null | head -300
            """, documentRoot: documentRoot),
            serverId: serverId
        )
        
        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if output.isEmpty || !output.contains("=== DIFF ===") {
            // Try unstaged diff
            let unstaged = try await SSHBridge.shared.execute(
                gitCmd("""
                echo '=== FILES CHANGED ==='; \
                git status --short 2>/dev/null; \
                echo ''; \
                echo '=== DIFF STAT ==='; \
                git diff --stat 2>/dev/null; \
                echo ''; \
                echo '=== DIFF ==='; \
                git diff 2>/dev/null | head -300
                """, documentRoot: documentRoot),
                serverId: serverId
            )
            return unstaged.stdout
        }
        return output
    }
}
