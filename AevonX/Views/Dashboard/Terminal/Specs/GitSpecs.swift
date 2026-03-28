//
//  GitSpecs.swift
//  AevonX
//
//  Completion specs for git commands, flags, branches (dynamic).
//

import Foundation

enum GitSpecs {

    static let git = ToolSpec(
        command: "git",
        description: "Distributed version control",
        subcommands: [
            SubcommandSpec(name: "status", description: "Show working tree status", flags: [
                FlagSpec(long: "--short", short: "-s", description: "Short format"),
                FlagSpec(long: "--branch", short: "-b", description: "Show branch info"),
            ]),
            SubcommandSpec(name: "add", description: "Add file contents to index", flags: [
                FlagSpec(long: "--all", short: "-A", description: "Add all changes"),
                FlagSpec(long: "--patch", short: "-p", description: "Interactive staging"),
                FlagSpec(long: "--verbose", short: "-v", description: "Verbose"),
            ]),
            SubcommandSpec(name: "commit", description: "Record changes", flags: [
                FlagSpec(long: "--message", short: "-m", description: "Commit message", takesValue: true),
                FlagSpec(long: "--all", short: "-a", description: "Stage all modified files"),
                FlagSpec(long: "--amend", description: "Amend last commit"),
                FlagSpec(long: "--no-edit", description: "Reuse commit message"),
                FlagSpec(long: "--fixup", description: "Fixup commit", takesValue: true),
                FlagSpec(long: "--signoff", short: "-s", description: "Add Signed-off-by"),
            ]),
            SubcommandSpec(name: "push", description: "Update remote refs", flags: [
                FlagSpec(long: "--force", short: "-f", description: "Force push"),
                FlagSpec(long: "--force-with-lease", description: "Safe force push"),
                FlagSpec(long: "--set-upstream", short: "-u", description: "Set upstream"),
                FlagSpec(long: "--tags", description: "Push tags"),
                FlagSpec(long: "--delete", description: "Delete remote branch"),
            ]),
            SubcommandSpec(name: "pull", description: "Fetch and integrate", flags: [
                FlagSpec(long: "--rebase", short: "-r", description: "Rebase instead of merge"),
                FlagSpec(long: "--no-rebase", description: "Merge (default)"),
                FlagSpec(long: "--autostash", description: "Auto stash/unstash"),
            ]),
            SubcommandSpec(name: "fetch", description: "Download objects and refs", flags: [
                FlagSpec(long: "--all", description: "Fetch all remotes"),
                FlagSpec(long: "--prune", short: "-p", description: "Prune remote branches"),
                FlagSpec(long: "--tags", short: "-t", description: "Fetch all tags"),
            ]),
            SubcommandSpec(name: "merge", description: "Join branches", flags: [
                FlagSpec(long: "--no-ff", description: "Create merge commit"),
                FlagSpec(long: "--squash", description: "Squash merge"),
                FlagSpec(long: "--abort", description: "Abort merge"),
            ]),
            SubcommandSpec(name: "rebase", description: "Reapply commits", flags: [
                FlagSpec(long: "--interactive", short: "-i", description: "Interactive rebase"),
                FlagSpec(long: "--continue", description: "Continue rebase"),
                FlagSpec(long: "--abort", description: "Abort rebase"),
                FlagSpec(long: "--skip", description: "Skip current patch"),
                FlagSpec(long: "--onto", description: "New base", takesValue: true),
            ]),
            SubcommandSpec(name: "checkout", description: "Switch branches or restore files", flags: [
                FlagSpec(long: "-b", description: "Create and switch to new branch"),
                FlagSpec(long: "--track", short: "-t", description: "Track remote branch"),
            ]),
            SubcommandSpec(name: "switch", description: "Switch branches", flags: [
                FlagSpec(long: "--create", short: "-c", description: "Create new branch"),
                FlagSpec(long: "--detach", description: "Detach HEAD"),
            ]),
            SubcommandSpec(name: "branch", description: "List, create, or delete branches", flags: [
                FlagSpec(long: "--delete", short: "-d", description: "Delete branch"),
                FlagSpec(long: "-D", description: "Force delete"),
                FlagSpec(long: "--list", description: "List branches"),
                FlagSpec(long: "--all", short: "-a", description: "List all (include remote)"),
                FlagSpec(long: "--move", short: "-m", description: "Rename branch"),
            ]),
            SubcommandSpec(name: "log", description: "Show commit logs", flags: [
                FlagSpec(long: "--oneline", description: "One line per commit"),
                FlagSpec(long: "--graph", description: "Show graph"),
                FlagSpec(long: "--all", description: "All branches"),
                FlagSpec(long: "--author", description: "Filter by author", takesValue: true),
                FlagSpec(long: "--since", description: "Since date", takesValue: true),
                FlagSpec(long: "-n", description: "Limit commits", takesValue: true),
                FlagSpec(long: "--stat", description: "Show diffstat"),
                FlagSpec(long: "-p", description: "Show patch"),
            ]),
            SubcommandSpec(name: "diff", description: "Show changes", flags: [
                FlagSpec(long: "--staged", description: "Show staged changes"),
                FlagSpec(long: "--cached", description: "Show staged changes"),
                FlagSpec(long: "--name-only", description: "Show only file names"),
                FlagSpec(long: "--stat", description: "Show diffstat"),
                FlagSpec(long: "--color", description: "Colorize output"),
            ]),
            SubcommandSpec(name: "stash", description: "Stash changes", flags: []),
            SubcommandSpec(name: "stash push", description: "Stash working changes", flags: [
                FlagSpec(long: "--message", short: "-m", description: "Stash message", takesValue: true),
                FlagSpec(long: "--keep-index", description: "Keep staged changes"),
                FlagSpec(long: "--include-untracked", short: "-u", description: "Include untracked"),
            ]),
            SubcommandSpec(name: "stash pop", description: "Apply and remove top stash", flags: []),
            SubcommandSpec(name: "stash apply", description: "Apply stash", flags: []),
            SubcommandSpec(name: "stash list", description: "List stashes", flags: []),
            SubcommandSpec(name: "stash drop", description: "Remove a stash", flags: []),
            SubcommandSpec(name: "reset", description: "Reset current HEAD", flags: [
                FlagSpec(long: "--hard", description: "Discard all changes"),
                FlagSpec(long: "--soft", description: "Keep changes staged"),
                FlagSpec(long: "--mixed", description: "Keep changes unstaged"),
            ]),
            SubcommandSpec(name: "revert", description: "Revert commits", flags: [
                FlagSpec(long: "--no-commit", short: "-n", description: "Don't auto-commit"),
            ]),
            SubcommandSpec(name: "cherry-pick", description: "Apply commit from another branch", flags: [
                FlagSpec(long: "--no-commit", short: "-n", description: "Don't auto-commit"),
                FlagSpec(long: "--continue", description: "Continue after conflicts"),
                FlagSpec(long: "--abort", description: "Abort cherry-pick"),
            ]),
            SubcommandSpec(name: "tag", description: "Create, list, or delete tags", flags: [
                FlagSpec(long: "--annotate", short: "-a", description: "Annotated tag"),
                FlagSpec(long: "--message", short: "-m", description: "Tag message", takesValue: true),
                FlagSpec(long: "--delete", short: "-d", description: "Delete tag"),
                FlagSpec(long: "--list", short: "-l", description: "List tags"),
            ]),
            SubcommandSpec(name: "remote", description: "Manage remotes", flags: [
                FlagSpec(long: "--verbose", short: "-v", description: "Show URLs"),
            ]),
            SubcommandSpec(name: "clone", description: "Clone a repository", flags: [
                FlagSpec(long: "--depth", description: "Shallow clone", takesValue: true),
                FlagSpec(long: "--branch", short: "-b", description: "Branch", takesValue: true),
                FlagSpec(long: "--single-branch", description: "Clone single branch"),
            ]),
            SubcommandSpec(name: "restore", description: "Restore working tree files", flags: [
                FlagSpec(long: "--staged", description: "Unstage files"),
                FlagSpec(long: "--source", description: "Restore from commit", takesValue: true),
            ]),
            SubcommandSpec(name: "clean", description: "Remove untracked files", flags: [
                FlagSpec(long: "-f", description: "Force clean"),
                FlagSpec(long: "-d", description: "Remove directories too"),
                FlagSpec(long: "-n", description: "Dry run"),
            ]),
            SubcommandSpec(name: "blame", description: "Show who changed each line", flags: [
                FlagSpec(long: "-L", description: "Line range", takesValue: true),
            ]),
        ],
        globalFlags: [
            FlagSpec(long: "--help", short: "-h", description: "Show help"),
            FlagSpec(long: "--version", description: "Show version"),
        ]
    )

    /// Dynamic completion commands for fetching from server
    static let branchCommand = "git branch --list --format='%(refname:short)' 2>/dev/null"
    static let remoteBranchCommand = "git branch -r --format='%(refname:short)' 2>/dev/null"
    static let tagCommand = "git tag -l 2>/dev/null"
    static let remoteCommand = "git remote 2>/dev/null"
    static let modifiedFilesCommand = "git diff --name-only 2>/dev/null"
    static let stashCommand = "git stash list --format='%gd: %gs' 2>/dev/null"

    static var allSpecs: [ToolSpec] { [git] }
}
