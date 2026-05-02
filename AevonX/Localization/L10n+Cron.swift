import Foundation

extension L10n {

    // MARK: - Cron (Cron.strings)
    enum Cron {
        private static let table = "Cron"
        private static func s(_ k: StaticString, _ v: String.LocalizationValue) -> String { String(localized: k, defaultValue: v, table: table) }

        static let title = s("cron.title", "Cron Manager")
        static let addTask = s("cron.addTask", "Add Task")
        static let executionLog = s("cron.executionLog", "Execution Log")
        static let loadingLogs = s("cron.loadingLogs", "Loading logs...")
        static let noLogs = s("cron.noLogs", "No execution logs yet")
        static let disabled = s("cron.disabled", "DISABLED")
        static let useTemplate = s("cron.useTemplate", "Use")
        static let editTask = s("cron.editTask", "Edit Task")
        static let configureAScheduledTaskForYourServer = s("cron.configureAScheduledTaskForYourServer", "Configure a scheduled task for your server")
        static let reset = s("cron.reset", "Reset")
        static let avoidDangerousCommandsShutdownInitMkfsRmRf = s("cron.avoidDangerousCommandsShutdownInitMkfsRmRf", "Avoid dangerous commands: shutdown, init 0, mkfs, rm -rf /")
        static let logsWillAppearAfterTheTaskIsExecuted = s("cron.logsWillAppearAfterTheTaskIsExecuted", "Logs will appear after the task is executed")
        static let task = s("cron.task", "Task")
        static let status = s("cron.status", "Status")
        static let lastExecuted = s("cron.lastExecuted", "Last Executed")
        static let actions = s("cron.actions", "Actions")
        static let noCronJobs = s("cron.noCronJobs", "No Cron Jobs")
        static let createTask = s("cron.createTask", "Create Task")
        static let browseScripts = s("cron.browseScripts", "Browse Scripts")
        static let executionResult = s("cron.executionResult", "Execution Result")
    }
}
