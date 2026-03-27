import Foundation

extension L10n {

    // MARK: - File Manager Git (FileGit.strings)
    enum FileGit {
        private static let table = "FileGit"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        // Toolbar
        static let branch = s("git.toolbar.branch", "Branch")
        static let ahead = s("git.toolbar.ahead", "ahead")
        static let behind = s("git.toolbar.behind", "behind")
        static let lastCommit = s("git.toolbar.lastCommit", "Last:")
        static let noCommits = s("git.toolbar.noCommits", "No commits yet")

        // Buttons
        static let pull = s("git.btn.pull", "Pull")
        static let push = s("git.btn.push", "Push")
        static let fetch = s("git.btn.fetch", "Fetch")
        static let commit = s("git.btn.commit", "Commit")
        static let branchBtn = s("git.btn.branch", "Branch")
        static let more = s("git.btn.more", "More")

        // Commit
        enum Commit {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: FileGit.table) }

            static let title = s("git.commit.title", "Commit Changes")
            static let changedFiles = s("git.commit.changedFiles", "Changed Files")
            static let message = s("git.commit.message", "Commit Message")
            static let placeholder = s("git.commit.placeholder", "Describe your changes...")
            static let stageAll = s("git.commit.stageAll", "Stage All & Commit")
            static let noChanges = s("git.commit.noChanges", "No changes to commit")
        }

        // Branch
        enum Branch {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: FileGit.table) }

            static let title = s("git.branch.title", "Branches")
            static let local = s("git.branch.local", "Local")
            static let remote = s("git.branch.remote", "Remote")
            static let current = s("git.branch.current", "current")
            static let new = s("git.branch.new", "New Branch")
            static let newPlaceholder = s("git.branch.newPlaceholder", "feature/my-branch")
            static let merge = s("git.branch.merge", "Merge Into Current")
            static let delete = s("git.branch.delete", "Delete Branch")
            static let switchBranch = s("git.branch.switch", "Switch Branch")
        }

        // Log
        enum Log {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: FileGit.table) }

            static let title = s("git.log.title", "Commit History")
            static let empty = s("git.log.empty", "No commit history")
            static let checkout = s("git.log.checkout", "Checkout")
        }

        // Stash
        enum Stash {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: FileGit.table) }

            static let title = s("git.stash.title", "Stash")
            static let save = s("git.stash.save", "Save to Stash")
            static let list = s("git.stash.list", "Stash List")
            static let pop = s("git.stash.pop", "Pop Latest")
            static let drop = s("git.stash.drop", "Drop")
            static let empty = s("git.stash.empty", "No stash entries")
            static let messagePlaceholder = s("git.stash.messagePlaceholder", "Optional stash message...")
        }

        // Tags
        enum Tags {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: FileGit.table) }

            static let title = s("git.tags.title", "Tags")
            static let checkout = s("git.tags.checkout", "Checkout Tag")
            static let empty = s("git.tags.empty", "No tags")
        }

        // Remotes
        enum Remotes {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: FileGit.table) }

            static let title = s("git.remotes.title", "Remotes")
            static let add = s("git.remotes.add", "Add Remote")
            static let remove = s("git.remotes.remove", "Remove")
            static let name = s("git.remotes.name", "Remote Name")
            static let url = s("git.remotes.url", "Remote URL")
            static let empty = s("git.remotes.empty", "No remotes configured")
        }

        // More Menu
        enum More {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: FileGit.table) }

            static let stash = s("git.more.stash", "Stash")
            static let tags = s("git.more.tags", "Tags")
            static let remotes = s("git.more.remotes", "Remotes")
            static let history = s("git.more.history", "Commit History")
            static let dangerZone = s("git.more.dangerZone", "Danger Zone")
            static let resetHard = s("git.more.resetHard", "Reset Hard")
            static let discardAll = s("git.more.discardAll", "Discard All Changes")
            static let disconnect = s("git.more.disconnect", "Disconnect Git")
        }

        // Danger
        enum Danger {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: FileGit.table) }

            static let resetTitle = s("git.danger.resetTitle", "Reset Hard")
            static let resetMessage = s("git.danger.resetMessage", "This will discard all uncommitted changes. This cannot be undone.")
            static let discardTitle = s("git.danger.discardTitle", "Discard All Changes")
            static let discardMessage = s("git.danger.discardMessage", "All modified and untracked files will be lost.")
            static let disconnectTitle = s("git.danger.disconnectTitle", "Disconnect Git")
            static let disconnectMessage = s("git.danger.disconnectMessage", "This will remove the .git directory. Repository history will be lost.")
        }

        // Operations
        enum Op {
            private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: FileGit.table) }

            static let pulling = s("git.op.pulling", "Pulling...")
            static let pushing = s("git.op.pushing", "Pushing...")
            static let fetching = s("git.op.fetching", "Fetching...")
            static let committing = s("git.op.committing", "Committing...")
            static let switching = s("git.op.switching", "Switching branch...")
            static let merging = s("git.op.merging", "Merging...")
            static let deleting = s("git.op.deleting", "Deleting branch...")
            static let stashing = s("git.op.stashing", "Stashing...")
            static let poppingStash = s("git.op.poppingStash", "Popping stash...")
            static let droppingStash = s("git.op.droppingStash", "Dropping stash...")
            static let checkingOutTag = s("git.op.checkingOutTag", "Checking out tag...")
            static let addingRemote = s("git.op.addingRemote", "Adding remote...")
            static let removingRemote = s("git.op.removingRemote", "Removing remote...")
            static let resetting = s("git.op.resetting", "Resetting...")
            static let discarding = s("git.op.discarding", "Discarding changes...")
            static let disconnecting = s("git.op.disconnecting", "Disconnecting...")
            static let checkingOut = s("git.op.checkingOut", "Checking out commit...")
        }
    }
}
