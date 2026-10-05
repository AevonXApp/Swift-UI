//
//  HookPoint.swift
//  AevonXCoreBridge
//
//  All available anchor points where plugins can inject UI.
//  Expanded from 14 to 40+ hook points for full app coverage.
//

import Foundation

// MARK: - Hook Points

public enum HookPoint: String, Codable, CaseIterable, Sendable {
    // --- Website hooks ---
    case websitesCardActions       = "remote_fleets.websites.card.actions"
    case websitesDetailsHeader     = "remote_fleets.websites.details.header"
    case websitesDetailsActions    = "remote_fleets.websites.details.actions"
    case websitesDetailsTabs       = "remote_fleets.websites.details.tabs"
    case websitesDetailsSidebar    = "remote_fleets.websites.details.sidebar"
    case websitesDetailsFooter     = "remote_fleets.websites.details.footer"
    case websitesListToolbar       = "remote_fleets.websites.list.toolbar"
    case websitesSslActions        = "remote_fleets.websites.ssl.actions"
    case websitesNginxActions      = "remote_fleets.websites.nginx.actions"

    // --- Sidebar & global ---
    case sidebarTabs               = "remote_fleets.sidebar.tabs"
    case globalHeaderActions       = "remote_fleets.global.header.actions"
    case globalToolbar             = "remote_fleets.global.toolbar"
    case globalStatusBar           = "remote_fleets.global.status_bar"
    case footerActions             = "remote_fleets.footer.actions"

    // --- Server overview ---
    case overviewWidgets           = "remote_fleets.overview.widgets"
    case overviewHeader            = "remote_fleets.overview.header"
    case overviewStats             = "remote_fleets.overview.stats"
    case overviewCharts            = "remote_fleets.overview.charts"
    case overviewAlerts            = "remote_fleets.overview.alerts"

    // --- Databases ---
    case databasesCardActions      = "remote_fleets.databases.card.actions"
    case databasesDetailsActions   = "remote_fleets.databases.details.actions"
    case databasesDetailsTabs      = "remote_fleets.databases.details.tabs"
    case databasesListToolbar      = "remote_fleets.databases.list.toolbar"

    // --- Servers ---
    case serversCardActions        = "remote_fleets.servers.card.actions"

    // --- Services ---
    case servicesCardActions       = "remote_fleets.services.card.actions"

    // --- Terminal ---
    case terminalActions           = "remote_fleets.terminal.actions"

    // --- Firewall / Security ---
    case firewallActions           = "remote_fleets.firewall.actions"
    case securityFirewallRules     = "remote_fleets.security.firewall.rules"
    case securitySslActions        = "remote_fleets.security.ssl.actions"
    case securityAuditWidgets      = "remote_fleets.security.audit.widgets"

    // --- DNS ---
    case dnsActions                = "remote_fleets.dns.actions"

    // --- Email ---
    case emailActions              = "remote_fleets.email.actions"

    // --- Files & FTP ---
    case filesToolbar              = "remote_fleets.files.toolbar"
    case filesContextMenu          = "remote_fleets.files.context_menu"
    case ftpCardActions            = "remote_fleets.ftp.card.actions"

    // --- Docker ---
    case dockerContainerActions    = "remote_fleets.docker.container.actions"
    case dockerToolbar             = "remote_fleets.docker.toolbar"
    case dockerStatsWidgets        = "remote_fleets.docker.stats.widgets"

    // --- Cron ---
    case cronToolbar               = "remote_fleets.cron.toolbar"
    case cronJobActions            = "remote_fleets.cron.job.actions"

    // --- Monitoring ---
    case monitoringWidgets         = "remote_fleets.monitoring.widgets"

    // --- Settings ---
    case settingsSections          = "remote_fleets.settings.sections"

    // --- Applications ---
    case applicationsCardActions   = "remote_fleets.applications.card.actions"
    case applicationsDetailsTabs   = "remote_fleets.applications.details.tabs"
    case applicationsToolbar       = "remote_fleets.applications.toolbar"

    // --- Backups ---
    case backupsActions            = "remote_fleets.backups.actions"
    case backupsSchedule           = "remote_fleets.backups.schedule"
    case backupsToolbar            = "remote_fleets.backups.toolbar"

    // --- User Management ---
    case usersCardActions          = "remote_fleets.users.card.actions"
    case usersDetailsTabs          = "remote_fleets.users.details.tabs"

    // --- Notifications ---
    case notificationActions       = "remote_fleets.notifications.actions"

    // --- Plugin Ecosystem ---
    case pluginsMarketplace        = "remote_fleets.plugins.marketplace"
    case pluginsSettings           = "remote_fleets.plugins.settings"

    // --- Dashboard Extended ---
    case dashboardBottom           = "remote_fleets.dashboard.bottom"
    case dashboardSidePanel        = "remote_fleets.dashboard.side_panel"
    case dashboardQuickActions     = "remote_fleets.dashboard.quick_actions"
}
