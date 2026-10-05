//
//  HookLayoutModels.swift
//  AevonXCoreBridge
//
//  Layout and presentation models: page layout, cards, tabs, chart config.
//

import Foundation

// MARK: - Layout (for page-type plugins)

public struct HookPluginLayout: Codable, Sendable {
    public let type: HookLayoutType
    public let cards: [HookLayoutCard]?
    public let columns: Int?
    public let title: String?
    public let description: String?
    public let spacing: String?
    public let tabs: [HookLayoutTab]?
    public let theme: HookTheme?

    public init(type: HookLayoutType, cards: [HookLayoutCard]? = nil, columns: Int? = nil, title: String? = nil, description: String? = nil, spacing: String? = nil, tabs: [HookLayoutTab]? = nil, theme: HookTheme? = nil) {
        self.type = type
        self.cards = cards
        self.columns = columns
        self.title = title
        self.description = description
        self.spacing = spacing
        self.tabs = tabs
        self.theme = theme
    }
}

public enum HookLayoutType: String, Codable, Sendable {
    // ── Core layouts ─────────────────────────────────────────────────────
    case cardsDetails = "cards_details"
    case overview     = "overview"
    case table        = "table"
    case grid         = "grid"
    case split        = "split"
    case dashboard    = "dashboard"
    case tabs         = "tabs"

    // ── Used in existing hooks (were missing from enum) ──────────────────
    case commandCenter    = "command_center"      // Hero KPIs + live feed + controls
    case intelligenceFeed = "intelligence_feed"   // Searchable threat/event streams
    case operationsPanel  = "operations_panel"    // Status cards + action buttons + tables
    case analyticsBoard   = "analytics_board"     // Charts and trend analysis
    case forensicsView    = "forensics_view"      // Paginated findings list

    // ── New layouts for design diversity ─────────────────────────────────
    case kanban           = "kanban"              // Kanban board with drag-and-drop columns
    case timelineView     = "timeline_view"       // Vertical timeline with events
    case splitDetail      = "split_detail"        // Master-detail with resizable pane
    case heroCards        = "hero_cards"           // Large hero cards with rich content
    case mosaic           = "mosaic"              // Pinterest-style masonry layout
    case sidebarDetail    = "sidebar_detail"      // Sidebar navigation + detail pane
    case metricsWall      = "metrics_wall"        // Dense KPI wall
    case comparison       = "comparison"          // Side-by-side comparison
    case flow             = "flow"                // Process flow / pipeline view
    case report           = "report"              // Printable report layout

    // ── Forward compatibility ──────────────────────────────────────────
    case unknown          = "_unknown"             // Unrecognized type — prevents decode failures

    /// Custom decoder: falls back to .unknown for unrecognized layout types
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = HookLayoutType(rawValue: rawValue) ?? .unknown
    }
}

/// A tab within a tabbed layout
public struct HookLayoutTab: Codable, Sendable {
    public let title: String
    public let icon: String?
    public let cards: [HookLayoutCard]?
    public let columns: Int?

    public init(title: String, icon: String? = nil, cards: [HookLayoutCard]? = nil, columns: Int? = nil) {
        self.title = title
        self.icon = icon
        self.cards = cards
        self.columns = columns
    }
}

public struct HookLayoutCard: Codable, Sendable {
    public let title: String
    public let description: String?
    public let icon: String?
    public let command: HookPluginCommand?
    public let dataSource: HookDataSource?
    public let columns: [HookColumnDefinition]?
    public let style: HookButtonStyle?
    public let component: HookComponentType?
    public let fields: [HookFormField]?
    public let rowActions: [HookRowActionButton]?
    public let chartConfig: HookChartConfig?
    public let chartType: String?
    public let searchable: Bool?
    public let searchKeys: [String]?

    // ── v2.2: info_card / command_block card-level fields ────────────────
    /// Items for `component: "info_card"` cards.
    public let items: [HookInfoItem]?
    /// Command text for `component: "command_block"` cards.
    public let commandText: String?
    /// Caption for `component: "command_block"` cards (rendered above).
    public let caption: String?
    /// Footnote for `component: "command_block"` cards (rendered below).
    public let note: String?

    enum CodingKeys: String, CodingKey {
        case title, description, icon, command, style, component, columns, fields
        case dataSource = "data_source"
        case rowActions = "row_actions"
        case chartConfig = "chart_config"
        case chartType = "chart_type"
        case searchable
        case searchKeys = "search_keys"
        case items
        case commandText = "command_text"
        case caption, note
    }

    public init(title: String, description: String? = nil, icon: String? = nil, command: HookPluginCommand? = nil, dataSource: HookDataSource? = nil, columns: [HookColumnDefinition]? = nil, style: HookButtonStyle? = nil, component: HookComponentType? = nil, fields: [HookFormField]? = nil, rowActions: [HookRowActionButton]? = nil, chartConfig: HookChartConfig? = nil, chartType: String? = nil, searchable: Bool? = nil, searchKeys: [String]? = nil, items: [HookInfoItem]? = nil, commandText: String? = nil, caption: String? = nil, note: String? = nil) {
        self.title = title
        self.description = description
        self.icon = icon
        self.command = command
        self.dataSource = dataSource
        self.columns = columns
        self.style = style
        self.component = component
        self.fields = fields
        self.rowActions = rowActions
        self.chartConfig = chartConfig
        self.chartType = chartType
        self.searchable = searchable
        self.searchKeys = searchKeys
        self.items = items
        self.commandText = commandText
        self.caption = caption
        self.note = note
    }

    /// Resilient decoder — unknown component types become nil instead of crashing
    /// the entire card/layout/page decode chain.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        command = try c.decodeIfPresent(HookPluginCommand.self, forKey: .command)
        dataSource = try c.decodeIfPresent(HookDataSource.self, forKey: .dataSource)
        columns = try c.decodeIfPresent([HookColumnDefinition].self, forKey: .columns)
        style = try c.decodeIfPresent(HookButtonStyle.self, forKey: .style)
        fields = try c.decodeIfPresent([HookFormField].self, forKey: .fields)
        rowActions = try c.decodeIfPresent([HookRowActionButton].self, forKey: .rowActions)
        chartConfig = try c.decodeIfPresent(HookChartConfig.self, forKey: .chartConfig)
        chartType = try c.decodeIfPresent(String.self, forKey: .chartType)
        searchable = try c.decodeIfPresent(Bool.self, forKey: .searchable)
        searchKeys = try c.decodeIfPresent([String].self, forKey: .searchKeys)
        items = try c.decodeIfPresent([HookInfoItem].self, forKey: .items)
        commandText = try c.decodeIfPresent(String.self, forKey: .commandText)
        caption = try c.decodeIfPresent(String.self, forKey: .caption)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        // Resilient component decode — unknown values don't crash the whole page
        if let raw = try? c.decodeIfPresent(String.self, forKey: .component) {
            component = HookComponentType(rawValue: raw)
            if component == nil {
                print("[HookLayoutCard] ⚠️ Unknown component type '\(raw)' in card '\(title)' — skipping")
            }
        } else {
            component = nil
        }
    }
}

// MARK: - Chart Config

public struct HookChartConfig: Codable, Sendable {
    public let xKey: String?
    public let yKeys: [String]?
    public let labelKey: String?
    public let valueKey: String?
    public let colors: [String]?
    public let labels: [String]?
    public let fill: Bool?
    public let horizontal: Bool?
    public let maxItems: Int?

    enum CodingKeys: String, CodingKey {
        case colors, labels, fill, horizontal
        case xKey = "x_key"
        case yKeys = "y_keys"
        case labelKey = "label_key"
        case valueKey = "value_key"
        case maxItems = "max_items"
    }

    public init(xKey: String? = nil, yKeys: [String]? = nil, labelKey: String? = nil, valueKey: String? = nil, colors: [String]? = nil, labels: [String]? = nil, fill: Bool? = nil, horizontal: Bool? = nil, maxItems: Int? = nil) {
        self.xKey = xKey
        self.yKeys = yKeys
        self.labelKey = labelKey
        self.valueKey = valueKey
        self.colors = colors
        self.labels = labels
        self.fill = fill
        self.horizontal = horizontal
        self.maxItems = maxItems
    }
}

// MARK: - Wizard Step

public struct HookWizardStep: Codable, Sendable, Identifiable {
    public var id: String { title }
    public let title: String
    public let description: String?
    public let icon: String?
    public let fields: [HookFormField]?
    public let command: HookPluginCommand?
    public let validation: HookWizardValidation?

    public init(title: String, description: String? = nil, icon: String? = nil, fields: [HookFormField]? = nil, command: HookPluginCommand? = nil, validation: HookWizardValidation? = nil) {
        self.title = title
        self.description = description
        self.icon = icon
        self.fields = fields
        self.command = command
        self.validation = validation
    }
}

public struct HookWizardValidation: Codable, Sendable {
    public let required: [String]?
    public let minLength: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case required
        case minLength = "min_length"
    }

    public init(required: [String]? = nil, minLength: [String: Int]? = nil) {
        self.required = required
        self.minLength = minLength
    }
}

// MARK: - Alert Severity

public enum HookAlertSeverity: String, Codable, Sendable {
    case info    = "info"
    case warning = "warning"
    case error   = "error"
    case success = "success"
}

// MARK: - Health Check

public struct HookHealthCheck: Codable, Sendable {
    public let type: String?
    public let serviceName: String?
    public let url: String?
    public let command: String?
    public let interval: TimeInterval?
    public let successPattern: String?

    enum CodingKeys: String, CodingKey {
        case type, command, interval, url
        case serviceName = "service_name"
        case successPattern = "success_pattern"
    }

    public init(type: String? = nil, serviceName: String? = nil, url: String? = nil, command: String? = nil, interval: TimeInterval? = nil, successPattern: String? = nil) {
        self.type = type
        self.serviceName = serviceName
        self.url = url
        self.command = command
        self.interval = interval
        self.successPattern = successPattern
    }
}

// MARK: - Namespace Manifest

public struct HookNamespaceManifest: Codable, Sendable {
    public let name: String
    public let slug: String?
    public let description: String?
    public let author: String?
    public let version: String?
    public let icon: String?
    public let website: String?
    public let binary: String?
    public let commandsPath: String?
    public let healthCheck: HookHealthCheck?

    /// Argument passing style when calling the plugin binary.
    /// - "positional" (default): values appended in alphabetical key order
    /// - "named": --key value pairs
    /// - "json": payload encoded as JSON piped to stdin
    public let argStyle: String?

    /// Legacy field — parsed from JSON for backward compatibility but no longer enforced.
    /// Security is handled by Smart Auto-Trust (safe characters + installed manifest + binary sandboxing).
    public let allowedActions: [String]?

    enum CodingKeys: String, CodingKey {
        case name, slug, description, author, version, icon, website, binary
        case commandsPath  = "commands_path"
        case allowedActions = "allowed_actions"
        case healthCheck   = "health_check"
        case argStyle      = "arg_style"
    }

    public init(name: String, slug: String? = nil, description: String? = nil, author: String? = nil, version: String? = nil, icon: String? = nil, website: String? = nil, binary: String? = nil, commandsPath: String? = nil, allowedActions: [String]? = nil, healthCheck: HookHealthCheck? = nil, argStyle: String? = nil) {
        self.name = name
        self.slug = slug
        self.description = description
        self.author = author
        self.version = version
        self.icon = icon
        self.website = website
        self.binary = binary
        self.commandsPath = commandsPath
        self.allowedActions = allowedActions
        self.healthCheck = healthCheck
        self.argStyle = argStyle
    }
}

// MARK: - Loaded Namespace

public struct HookNamespace: Identifiable, Sendable {
    public let id: String
    public let manifest: HookNamespaceManifest?
    public let plugins: [HookPluginDefinition]
    public let pluginCount: Int
    /// Raw manifest JSON data for integrity verification (hash tracking).
    public let manifestRawData: Data?

    public init(id: String, manifest: HookNamespaceManifest? = nil, plugins: [HookPluginDefinition], manifestRawData: Data? = nil) {
        self.id = id
        self.manifest = manifest
        self.plugins = plugins
        self.pluginCount = plugins.count
        self.manifestRawData = manifestRawData
    }

    public var displayName: String {
        manifest?.name ?? id
    }
}
