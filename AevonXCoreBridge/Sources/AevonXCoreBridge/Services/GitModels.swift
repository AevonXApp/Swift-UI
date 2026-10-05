//
//  GitModels.swift
//  AevonXCore
//
//  Data models for Git source control management
//

import Foundation

// MARK: - Git Repository Info

public struct GitRepoInfo: Equatable {
    public var hasGit: Bool
    public var currentBranch: String
    public var remoteURL: String
    public var provider: GitProvider
    public var trackedFiles: Int
    public var modifiedFiles: Int
    public var untrackedFiles: Int
    public var aheadCount: Int
    public var behindCount: Int
    public var lastCommitMessage: String
    public var lastCommitDate: String
    
    public init(
        hasGit: Bool = false,
        currentBranch: String = "",
        remoteURL: String = "",
        provider: GitProvider = .unknown,
        trackedFiles: Int = 0,
        modifiedFiles: Int = 0,
        untrackedFiles: Int = 0,
        aheadCount: Int = 0,
        behindCount: Int = 0,
        lastCommitMessage: String = "",
        lastCommitDate: String = ""
    ) {
        self.hasGit = hasGit
        self.currentBranch = currentBranch
        self.remoteURL = remoteURL
        self.provider = provider
        self.trackedFiles = trackedFiles
        self.modifiedFiles = modifiedFiles
        self.untrackedFiles = untrackedFiles
        self.aheadCount = aheadCount
        self.behindCount = behindCount
        self.lastCommitMessage = lastCommitMessage
        self.lastCommitDate = lastCommitDate
    }
}

// MARK: - Git Provider

public enum GitProvider: String, CaseIterable {
    case github = "GitHub"
    case gitlab = "GitLab"
    case bitbucket = "Bitbucket"
    case custom = "Custom"
    case unknown = "Unknown"
    
    public var icon: String {
        switch self {
        case .github: return "arrow.triangle.branch"
        case .gitlab: return "arrow.triangle.branch"
        case .bitbucket: return "arrow.triangle.branch"
        case .custom: return "server.rack"
        case .unknown: return "questionmark.circle"
        }
    }
    
    public static func detect(from url: String) -> GitProvider {
        let lower = url.lowercased()
        if lower.contains("github.com") { return .github }
        if lower.contains("gitlab.com") || lower.contains("gitlab") { return .gitlab }
        if lower.contains("bitbucket.org") || lower.contains("bitbucket") { return .bitbucket }
        if !url.isEmpty { return .custom }
        return .unknown
    }
}

// MARK: - Git Commit

public struct GitCommit: Identifiable, Equatable {
    public let id: String  // full hash
    public let shortHash: String
    public let message: String
    public let author: String
    public let date: String
    public let relativeDate: String
    public var filesChanged: [GitFileChange]
    
    public init(
        id: String,
        shortHash: String,
        message: String,
        author: String,
        date: String,
        relativeDate: String = "",
        filesChanged: [GitFileChange] = []
    ) {
        self.id = id
        self.shortHash = shortHash
        self.message = message
        self.author = author
        self.date = date
        self.relativeDate = relativeDate
        self.filesChanged = filesChanged
    }
}

// MARK: - Git Branch

public struct GitBranch: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let isRemote: Bool
    public let isCurrent: Bool
    
    public init(name: String, isRemote: Bool = false, isCurrent: Bool = false) {
        self.name = name
        self.isRemote = isRemote
        self.isCurrent = isCurrent
    }
    
    /// Clean display name (strips remote prefix)
    public var displayName: String {
        if isRemote, let slashIdx = name.range(of: "/", options: .backwards) {
            return String(name[slashIdx.upperBound...])
        }
        return name
    }
}

// MARK: - Git File Change

public struct GitFileChange: Identifiable, Equatable {
    public var id: String { path }
    public let path: String
    public let status: GitFileStatus
    
    public init(path: String, status: GitFileStatus) {
        self.path = path
        self.status = status
    }
}

public enum GitFileStatus: String {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case untracked = "?"
    case copied = "C"
    
    public var displayName: String {
        switch self {
        case .modified: return "Modified"
        case .added: return "Added"
        case .deleted: return "Deleted"
        case .renamed: return "Renamed"
        case .untracked: return "Untracked"
        case .copied: return "Copied"
        }
    }
    
    public var icon: String {
        switch self {
        case .modified: return "pencil.circle.fill"
        case .added: return "plus.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .renamed: return "arrow.right.circle.fill"
        case .untracked: return "questionmark.circle.fill"
        case .copied: return "doc.on.doc.fill"
        }
    }
}

// MARK: - Git Stash Entry

public struct GitStashEntry: Identifiable, Equatable {
    public var id: String { index }
    public let index: String  // "stash@{0}"
    public let message: String
    public let branch: String
    
    public init(index: String, message: String, branch: String = "") {
        self.index = index
        self.message = message
        self.branch = branch
    }
}

// MARK: - Git Remote

public struct GitRemote: Identifiable, Equatable {
    public var id: String { name + type }
    public let name: String
    public let url: String
    public let type: String  // "fetch" or "push"
    
    public init(name: String, url: String, type: String) {
        self.name = name
        self.url = url
        self.type = type
    }
}

// MARK: - Git Tag

public struct GitTag: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let message: String
    
    public init(name: String, message: String = "") {
        self.name = name
        self.message = message
    }
}

// MARK: - Clone Configuration

public struct GitCloneConfig {
    public var repoURL: String
    public var branch: String
    public var isPrivate: Bool
    public var token: String
    public var username: String
    
    public init(
        repoURL: String = "",
        branch: String = "main",
        isPrivate: Bool = false,
        token: String = "",
        username: String = ""
    ) {
        self.repoURL = repoURL
        self.branch = branch
        self.isPrivate = isPrivate
        self.token = token
        self.username = username
    }
    
    /// Build the authenticated URL for private repos
    public var authenticatedURL: String {
        guard isPrivate, !token.isEmpty else { return repoURL }
        
        // Convert https://github.com/user/repo.git → https://TOKEN@github.com/user/repo.git
        if repoURL.hasPrefix("https://") {
            let stripped = repoURL.replacingOccurrences(of: "https://", with: "")
            if !username.isEmpty {
                return "https://\(username):\(token)@\(stripped)"
            }
            return "https://\(token)@\(stripped)"
        }
        return repoURL
    }
    
    public var provider: GitProvider {
        GitProvider.detect(from: repoURL)
    }
}
