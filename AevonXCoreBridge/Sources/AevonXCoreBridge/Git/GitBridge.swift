//
//  GitBridge.swift
//  AevonXCoreBridge
//
//  Swift wrapper for Go Core Git source control operations.
//  Full coverage: detect, clone, pull/push, branches, commits,
//  status, stash, tags, remotes, reset, credentials, commit flow.
//

import Foundation
import AevonXCoreLib

public final class GitBridge: @unchecked Sendable {

    public static let shared = GitBridge()
    private init() {}

    // MARK: - Detection

    public func detectCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitDetectCmd(c.str(documentRoot))) }
    }

    public func getRepoInfoCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitGetRepoInfoCmd(c.str(documentRoot))) }
    }

    // MARK: - Init / Clone / Disconnect

    public func initRepoCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitInitRepoCmd(c.str(documentRoot))) }
    }

    public func cloneRepoCmd(repoURL: String, branch: String = "main", documentRoot: String, token: String = "", username: String = "", isPrivate: Bool = false) -> String {
        withCArgs { c in extract(GitCloneRepoCmd(c.str(repoURL), c.str(branch), c.str(documentRoot), c.str(token), c.str(username), isPrivate ? 1 : 0)) }
    }

    public func disconnectCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitDisconnectCmd(c.str(documentRoot))) }
    }

    // MARK: - Pull / Push / Fetch

    public func detectRemoteCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitDetectRemoteCmd(c.str(documentRoot))) }
    }

    public func pullCmd(documentRoot: String, remote: String = "", branch: String = "") -> String {
        withCArgs { c in extract(GitPullCmd(c.str(documentRoot), c.str(remote), c.str(branch))) }
    }

    public func pushCmd(documentRoot: String, remote: String = "", branch: String = "") -> String {
        withCArgs { c in extract(GitPushCmd(c.str(documentRoot), c.str(remote), c.str(branch))) }
    }

    public func fetchCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitFetchCmd(c.str(documentRoot))) }
    }

    // MARK: - Branches

    public func listBranchesCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitListBranchesCmd(c.str(documentRoot))) }
    }

    public func switchBranchCmd(branch: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitSwitchBranchCmd(c.str(branch), c.str(documentRoot))) }
    }

    public func createBranchCmd(name: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitCreateBranchCmd(c.str(name), c.str(documentRoot))) }
    }

    public func deleteBranchCmd(name: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitDeleteBranchCmd(c.str(name), c.str(documentRoot))) }
    }

    public func mergeBranchCmd(name: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitMergeBranchCmd(c.str(name), c.str(documentRoot))) }
    }

    // MARK: - Commits

    public func getLogCmd(documentRoot: String, count: Int = 50) -> String {
        withCArgs { c in extract(GitGetLogCmd(c.str(documentRoot), Int32(count))) }
    }

    public func getCommitDetailCmd(hash: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitGetCommitDetailCmd(c.str(hash), c.str(documentRoot))) }
    }

    public func checkoutCommitCmd(hash: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitCheckoutCommitCmd(c.str(hash), c.str(documentRoot))) }
    }

    // MARK: - Status / Diff

    public func getStatusCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitGetStatusCmd(c.str(documentRoot))) }
    }

    public func getDiffCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitGetDiffCmd(c.str(documentRoot))) }
    }

    public func getFileDiffCmd(path: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitGetFileDiffCmd(c.str(path), c.str(documentRoot))) }
    }

    // MARK: - Stash

    public func stashSaveCmd(message: String = "", documentRoot: String) -> String {
        withCArgs { c in extract(GitStashSaveCmd(c.str(message), c.str(documentRoot))) }
    }

    public func stashListCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitStashListCmd(c.str(documentRoot))) }
    }

    public func stashPopCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitStashPopCmd(c.str(documentRoot))) }
    }

    public func stashDropCmd(index: String = "", documentRoot: String) -> String {
        withCArgs { c in extract(GitStashDropCmd(c.str(index), c.str(documentRoot))) }
    }

    // MARK: - Tags

    public func listTagsCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitListTagsCmd(c.str(documentRoot))) }
    }

    public func checkoutTagCmd(name: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitCheckoutTagCmd(c.str(name), c.str(documentRoot))) }
    }

    // MARK: - Remotes

    public func listRemotesCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitListRemotesCmd(c.str(documentRoot))) }
    }

    public func addRemoteCmd(name: String, url: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitAddRemoteCmd(c.str(name), c.str(url), c.str(documentRoot))) }
    }

    public func removeRemoteCmd(name: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitRemoveRemoteCmd(c.str(name), c.str(documentRoot))) }
    }

    // MARK: - Reset

    public func resetHardCmd(ref: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitResetHardCmd(c.str(ref), c.str(documentRoot))) }
    }

    public func discardAllCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitDiscardAllCmd(c.str(documentRoot))) }
    }

    // MARK: - Credentials

    public func setCredentialsCmd(username: String, token: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitSetCredentialsCmd(c.str(username), c.str(token), c.str(documentRoot))) }
    }

    // MARK: - Commit Flow

    public func hasChangesCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitHasChangesCmd(c.str(documentRoot))) }
    }

    public func stageAllCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitStageAllCmd(c.str(documentRoot))) }
    }

    public func commitAllCmd(message: String, documentRoot: String) -> String {
        withCArgs { c in extract(GitCommitAllCmd(c.str(message), c.str(documentRoot))) }
    }

    public func getDiffSummaryCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitGetDiffSummaryCmd(c.str(documentRoot))) }
    }

    public func getDiffSummaryUnstagedCmd(documentRoot: String) -> String {
        withCArgs { c in extract(GitGetDiffSummaryUnstagedCmd(c.str(documentRoot))) }
    }

    // MARK: - Helpers

    private func extract(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = resp["success"] as? Bool, success,
              let innerData = resp["data"] as? [String: Any],
              let value = innerData["command"] as? String else { return "" }
        return value
    }
}
