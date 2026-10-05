//
//  HookWidgetModels.swift
//  AevonXCoreBridge
//
//  Formal widget system for hook plugins.
//  Widgets are the building blocks inside layouts — each represents a specific UI element
//  (metric card, chart, data table, action panel, etc.) with its own data source.
//
//  Before this model existed, widget types in hook.json (hero_metric, live_feed, etc.)
//  were silently ignored during JSON decoding. Now they're properly modeled and decoded.
//

import Foundation

// MARK: - Widget Type

/// All available widget types that plugins can use in their hook.json.
/// These get rendered by the HookWidgetRenderer on the UI side.
public enum HookWidgetType: String, Codable, Sendable {
    // ── Metrics ──────────────────────────────────────────────────────────
    case heroMetric    = "hero_metric"     // Large KPI with trend indicator
    case statBadge     = "stat_badge"      // Compact colored badge with a count
    case statRow       = "stat_row"        // Horizontal row of stat items
    case statGroup     = "stat_group"      // Grouped stat items with labels
    case counter       = "counter"         // Animated counter
    case sparkline     = "sparkline"       // Tiny inline chart
    case kpiCard       = "kpi_card"        // KPI card with title, value, change
    case progressRing  = "progress_ring"   // Circular progress indicator
    case statusIndicator = "status_indicator" // Colored dot with label

    // ── Charts ───────────────────────────────────────────────────────────
    case lineChart     = "line_chart"      // Line/area chart
    case barChart      = "bar_chart"       // Vertical bar chart
    case donutChart    = "donut_chart"     // Donut / pie chart
    case areaChart     = "area_chart"      // Filled area chart
    case stackedBar    = "stacked_bar"     // Stacked bar chart
    case radarChart    = "radar_chart"     // Radar / spider chart
    case heatmap       = "heatmap"         // Heat map grid

    // ── Tables / Feeds ───────────────────────────────────────────────────
    case dataTable     = "data_table"      // Full data table with columns
    case liveFeed      = "live_feed"       // Auto-scrolling live event feed
    case logStream     = "log_stream"      // Log viewer with severity colors
    case compactList   = "compact_list"    // Dense list with icons

    // ── Actions ──────────────────────────────────────────────────────────
    case actionPanel   = "action_panel"    // Action buttons with descriptions
    case buttonGroup   = "button_group"    // Simple group of buttons
    case togglePanel   = "toggle_panel"    // Toggle switches panel
    case quickActions  = "quick_actions"   // Quick action grid

    // ── Content ──────────────────────────────────────────────────────────
    case statusCard    = "status_card"     // Card with status fields
    case infoCard      = "info_card"       // Informational card
    case codeBlock     = "code_block"      // Syntax-highlighted code
    case markdownBlock = "markdown_block"  // Rendered markdown content
    case notificationFeed = "notification_feed"  // Notification list

    // ── Visualization ────────────────────────────────────────────────────
    case geoMap        = "geo_map"         // Geographic map
    case networkGraph  = "network_graph"   // Node-edge graph
    case treeMap       = "tree_map"        // Hierarchical tree map
    case timelineStrip = "timeline_strip"  // Horizontal timeline

    // ── Forward compatibility ──────────────────────────────────────────────
    case unknown       = "_unknown"        // Unrecognized type — prevents decode failures

    /// Custom decoder: falls back to .unknown for unrecognized widget types
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = HookWidgetType(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Widget Definition

/// A single widget within a hook layout — the atomic building block of plugin UIs.
/// This models the `"widgets": [...]` array in hook.json files.
public struct HookWidget: Codable, Sendable, Identifiable {
    public let id: String
    public let type: HookWidgetType
    public let title: String?
    public let icon: String?
    public let iconColor: String?
    public let span: Int?                        // Grid span (1-based, default 1)
    public let dataSource: HookDataSource?
    public let columns: [HookColumnDefinition]?  // For data_table widgets
    public let chart: HookChartConfig?           // For chart widgets
    public let actions: [HookWidgetAction]?      // For action_panel widgets
    public let fields: [HookWidgetField]?        // For status_card widgets
    public let stats: [HookWidgetStat]?          // For stat_row/stat_group widgets
    public let searchable: Bool?
    public let paginated: Bool?
    public let pageSize: Int?
    public let maxItems: Int?
    public let rowActions: [HookRowActionButton]?  // For data_table row actions
    public let command: HookPluginCommand?        // Direct command for action widgets
    public let style: HookWidgetStyle?            // Per-widget style overrides
    public let refresh: Int?                      // Auto-refresh interval in seconds

    enum CodingKeys: String, CodingKey {
        case id, type, title, icon, span, columns, chart, actions, fields, stats
        case searchable, paginated, maxItems, command, style, refresh
        case iconColor   = "icon_color"
        case dataSource  = "data_source"
        case pageSize    = "page_size"
        case rowActions  = "row_actions"
    }
}

// MARK: - Widget Sub-Models

/// A field displayed within a status_card widget
public struct HookWidgetField: Codable, Sendable {
    public let key: String
    public let label: String
    public let format: String?       // "percent", "duration", "bytes", "date", etc.
    public let color: String?
}

/// A stat item within a stat_row/stat_group widget
public struct HookWidgetStat: Codable, Sendable {
    public let key: String
    public let label: String
    public let color: String?
    public let format: String?
    public let icon: String?
}

/// An action within an action_panel widget
public struct HookWidgetAction: Codable, Sendable {
    public let id: String
    public let label: String
    public let icon: String?
    public let style: String?         // "primary", "secondary", "destructive"
    public let description: String?
    public let command: HookPluginCommand?
    public let input: HookWidgetInput?
}

/// An input definition for action_panel actions
public struct HookWidgetInput: Codable, Sendable {
    public let type: String           // "text", "select", "number"
    public let placeholder: String?
    public let label: String?
    public let options: [String]?
}

/// Per-widget style overrides
public struct HookWidgetStyle: Codable, Sendable {
    public let accentColor: String?
    public let background: String?     // "transparent", "solid", "gradient"
    public let borderColor: String?
    public let cornerRadius: String?   // "sm", "md", "lg", "xl"
    public let shadow: String?         // "none", "subtle", "medium", "strong"
    public let animation: String?      // "none", "pulse", "glow", "shimmer"

    enum CodingKeys: String, CodingKey {
        case accentColor = "accent_color"
        case background
        case borderColor = "border_color"
        case cornerRadius = "corner_radius"
        case shadow, animation
    }
}
