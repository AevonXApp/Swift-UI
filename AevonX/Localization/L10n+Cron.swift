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
        static let deleteTask = s("cron.deleteTask", "Delete Task")
        static let schedule = s("cron.schedule", "Schedule")
        static let command = s("cron.command", "Command")
        static let everyMinute = s("cron.everyMinute", "Every Minute")
        static let everyHour = s("cron.everyHour", "Every Hour")
        static let everyDay = s("cron.everyDay", "Every Day")
        static let custom = s("cron.custom", "Custom")
    }
}
