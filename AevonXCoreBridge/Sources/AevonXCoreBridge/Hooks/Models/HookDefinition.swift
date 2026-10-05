//
//  HookDefinition.swift
//  AevonXCoreBridge
//
//  The main definition struct for a hook plugin.
//  One .json file = one HookPluginDefinition.
//

import Foundation

// MARK: - Single Plugin File (one .json = one plugin)

/// A single plugin definition — one .json file in /etc/aevonx/{namespace}/
public struct HookPluginDefinition: Codable, Identifiable, Sendable {
    // Core identity
    public var id: String
    public let name: String
    public let description: String?
    public let version: String?
    public let componentVersion: String?  // "v1", "v2", etc. Defaults to "v1" if omitted.
    public let enabled: Bool?

    // Hook & component
    public let hook: HookPoint?
    public let component: HookComponentType?
    public let label: String?
    public let icon: String?
    public let style: HookButtonStyle?

    // Action
    public let command: HookPluginCommand?

    // Layout (for page-type plugins)
    public let layout: HookPluginLayout?

    // Data source (for rich data views like data_table and chart)
    public let dataSource: HookDataSource?
    public let columns: [HookColumnDefinition]?

    // Conditional visibility
    public let conditions: [HookCondition]?

    // Permission requirements
    public let permissions: [String]?

    // Confirmation before action
    public let confirmationMessage: String?

    // Chart rendering
    public let chartType: String?
    public let chartConfig: HookChartConfig?

    // Dependencies on other plugins
    public let dependencies: [String]?

    // Form fields (for form-type plugins)
    public let fields: [HookFormField]?

    // Row tap action (for data_table drill-down)
    public let onRowTap: HookRowAction?

    // Batch actions for multi-select in data_table
    public let batchActions: [HookBatchAction]?

    // Inline row action buttons (e.g. "Block IP", "Unblock")
    public let rowActions: [HookRowActionButton]?

    // Search configuration
    public let searchable: Bool?
    public let searchKeys: [String]?

    // Column filters (for data_table — dropdown/text filters per column)
    public let filters: [HookColumnFilter]?

    // Multi-command support (e.g. button-group with step1, step2, step3)
    public let commands: [HookPluginCommand]?

    // Wizard steps
    public let steps: [HookWizardStep]?

    // Alert severity
    public let severity: HookAlertSeverity?
    public let dismissible: Bool?

    // Dynamic content source (markdown URL, etc.)
    public let contentSource: String?

    // Embedded tabs — sub-plugins rendered as tabs within a page component
    public let tabs: [HookPluginDefinition]?

    // Widgets — formal widget definitions for rich layout rendering
    public let widgets: [HookWidget]?

    // Secondary data tables rendered below the main table
    public let secondaryTables: [HookSecondaryTable]?

    // Override the title/icon shown on the data table header
    public let titleOverride: String?
    public let iconOverride: String?

    // Sidebar items (for sidebar_detail layout)
    public var sidebar: [HookSidebarItem]?

    // ── v2.2: info_card / command_block declarative fields ───────────
    /// Static rows rendered by `component: "info_card"`. Each item shows
    /// an [icon] label · · · value pair. When `data_source` is also set,
    /// items with a non-nil `key` resolve their value from the JSON.
    public let items: [HookInfoItem]?
    /// Preformatted command displayed by `component: "command_block"`.
    /// Never executed — the user copies and runs it themselves on the server.
    public let commandText: String?
    /// Optional caption line rendered above the command_block.
    public let caption: String?
    /// Optional footnote line rendered below the command_block.
    public let note: String?

    // Namespace (injected by PluginLoader from folder name, not in JSON)
    public var namespace: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, version, enabled
        case componentVersion = "component_version"
        case hook, component, label, icon, style
        case command, layout
        case dataSource = "data_source"
        case columns, conditions, permissions, dependencies
        case confirmationMessage = "confirmation_message"
        case onRowTap = "on_row_tap"
        case batchActions = "batch_actions"
        case rowActions = "row_actions"
        case searchable
        case searchKeys = "search_keys"
        case filters
        case chartType = "chart_type"
        case chartConfig = "chart_config"
        case commands, steps, severity, dismissible
        case contentSource = "content_source"
        case tabs, namespace, widgets
        case fields
        case secondaryTables = "secondary_tables"
        case titleOverride = "title_override"
        case iconOverride = "icon_override"
        case sidebar
        case items
        case commandText = "command_text"
        case caption, note
    }

    public var isEnabled: Bool { enabled ?? true }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedName = try c.decode(String.self, forKey: .name)
        self.id = (try? c.decode(String.self, forKey: .id)) ?? decodedName.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = decodedName
        self.description = try? c.decode(String.self, forKey: .description)
        self.version = try? c.decode(String.self, forKey: .version)
        self.componentVersion = try? c.decode(String.self, forKey: .componentVersion)
        self.enabled = try? c.decode(Bool.self, forKey: .enabled)
        self.hook = try? c.decode(HookPoint.self, forKey: .hook)
        self.component = try? c.decode(HookComponentType.self, forKey: .component)
        self.label = try? c.decode(String.self, forKey: .label)
        self.icon = try? c.decode(String.self, forKey: .icon)
        self.style = try? c.decode(HookButtonStyle.self, forKey: .style)
        self.command = try? c.decode(HookPluginCommand.self, forKey: .command)
        self.layout = try? c.decode(HookPluginLayout.self, forKey: .layout)
        self.dataSource = try? c.decode(HookDataSource.self, forKey: .dataSource)
        self.columns = try? c.decode([HookColumnDefinition].self, forKey: .columns)
        self.conditions = try? c.decode([HookCondition].self, forKey: .conditions)
        self.permissions = try? c.decode([String].self, forKey: .permissions)
        self.confirmationMessage = try? c.decode(String.self, forKey: .confirmationMessage)
        self.onRowTap = try? c.decode(HookRowAction.self, forKey: .onRowTap)
        self.batchActions = try? c.decode([HookBatchAction].self, forKey: .batchActions)
        self.rowActions = try? c.decode([HookRowActionButton].self, forKey: .rowActions)
        self.searchable = try? c.decode(Bool.self, forKey: .searchable)
        self.searchKeys = try? c.decode([String].self, forKey: .searchKeys)
        self.filters = try? c.decode([HookColumnFilter].self, forKey: .filters)
        self.chartType = try? c.decode(String.self, forKey: .chartType)
        self.chartConfig = try? c.decode(HookChartConfig.self, forKey: .chartConfig)
        self.dependencies = try? c.decode([String].self, forKey: .dependencies)
        self.commands = try? c.decode([HookPluginCommand].self, forKey: .commands)
        self.steps = try? c.decode([HookWizardStep].self, forKey: .steps)
        self.severity = try? c.decode(HookAlertSeverity.self, forKey: .severity)
        self.dismissible = try? c.decode(Bool.self, forKey: .dismissible)
        self.contentSource = try? c.decode(String.self, forKey: .contentSource)
        self.tabs = try? c.decode([HookPluginDefinition].self, forKey: .tabs)
        self.widgets = try? c.decode([HookWidget].self, forKey: .widgets)
        self.fields = try? c.decode([HookFormField].self, forKey: .fields)
        self.secondaryTables = try? c.decode([HookSecondaryTable].self, forKey: .secondaryTables)
        self.titleOverride = try? c.decode(String.self, forKey: .titleOverride)
        self.iconOverride = try? c.decode(String.self, forKey: .iconOverride)
        self.sidebar = try? c.decode([HookSidebarItem].self, forKey: .sidebar)
        self.items = try? c.decode([HookInfoItem].self, forKey: .items)
        self.commandText = try? c.decode(String.self, forKey: .commandText)
        self.caption = try? c.decode(String.self, forKey: .caption)
        self.note = try? c.decode(String.self, forKey: .note)
        self.namespace = try? c.decode(String.self, forKey: .namespace)
    }

    public init(
        id: String? = nil,
        name: String,
        description: String? = nil,
        version: String? = nil,
        componentVersion: String? = nil,
        enabled: Bool? = true,
        hook: HookPoint? = nil,
        component: HookComponentType? = nil,
        label: String? = nil,
        icon: String? = nil,
        style: HookButtonStyle? = nil,
        command: HookPluginCommand? = nil,
        layout: HookPluginLayout? = nil,
        dataSource: HookDataSource? = nil,
        columns: [HookColumnDefinition]? = nil,
        conditions: [HookCondition]? = nil,
        permissions: [String]? = nil,
        confirmationMessage: String? = nil,
        chartType: String? = nil,
        chartConfig: HookChartConfig? = nil,
        dependencies: [String]? = nil,
        namespace: String? = nil,
        fields: [HookFormField]? = nil,
        onRowTap: HookRowAction? = nil,
        batchActions: [HookBatchAction]? = nil,
        rowActions: [HookRowActionButton]? = nil,
        searchable: Bool? = nil,
        searchKeys: [String]? = nil,
        filters: [HookColumnFilter]? = nil,
        commands: [HookPluginCommand]? = nil,
        steps: [HookWizardStep]? = nil,
        severity: HookAlertSeverity? = nil,
        dismissible: Bool? = nil,
        contentSource: String? = nil,
        tabs: [HookPluginDefinition]? = nil,
        widgets: [HookWidget]? = nil,
        secondaryTables: [HookSecondaryTable]? = nil,
        titleOverride: String? = nil,
        iconOverride: String? = nil,
        sidebar: [HookSidebarItem]? = nil,
        items: [HookInfoItem]? = nil,
        commandText: String? = nil,
        caption: String? = nil,
        note: String? = nil
    ) {
        self.id = id ?? name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = name
        self.description = description
        self.version = version
        self.componentVersion = componentVersion
        self.enabled = enabled
        self.hook = hook
        self.component = component
        self.label = label
        self.icon = icon
        self.style = style
        self.command = command
        self.layout = layout
        self.dataSource = dataSource
        self.columns = columns
        self.conditions = conditions
        self.permissions = permissions
        self.confirmationMessage = confirmationMessage
        self.chartType = chartType
        self.chartConfig = chartConfig
        self.dependencies = dependencies
        self.namespace = namespace
        self.fields = fields
        self.onRowTap = onRowTap
        self.batchActions = batchActions
        self.rowActions = rowActions
        self.searchable = searchable
        self.searchKeys = searchKeys
        self.filters = filters
        self.commands = commands
        self.steps = steps
        self.severity = severity
        self.dismissible = dismissible
        self.contentSource = contentSource
        self.tabs = tabs
        self.widgets = widgets
        self.secondaryTables = secondaryTables
        self.titleOverride = titleOverride
        self.iconOverride = iconOverride
        self.sidebar = sidebar
        self.items = items
        self.commandText = commandText
        self.caption = caption
        self.note = note
    }

    /// Returns a copy of this definition with the given tabs injected.
    /// Used by HookLoader for folder-based plugins where tabs are auto-collected from separate files.
    public func withTabs(_ newTabs: [HookPluginDefinition]) -> HookPluginDefinition {
        HookPluginDefinition(
            id: id, name: name, description: description, version: version,
            componentVersion: componentVersion, enabled: enabled, hook: hook, component: component,
            label: label, icon: icon, style: style, command: command, layout: layout,
            dataSource: dataSource, columns: columns, conditions: conditions, permissions: permissions,
            confirmationMessage: confirmationMessage, chartType: chartType, chartConfig: chartConfig,
            dependencies: dependencies, namespace: namespace, fields: fields, onRowTap: onRowTap,
            batchActions: batchActions, rowActions: rowActions, searchable: searchable,
            searchKeys: searchKeys, filters: filters, commands: commands, steps: steps,
            severity: severity, dismissible: dismissible, contentSource: contentSource,
            tabs: newTabs, widgets: widgets,
            secondaryTables: secondaryTables, titleOverride: titleOverride, iconOverride: iconOverride,
            sidebar: sidebar,
            items: items, commandText: commandText, caption: caption, note: note
        )
    }
}

// MARK: - Secondary Table Definition

/// A secondary data table shown below the main plugin data table.
/// Used for supplementary data views (e.g. "Risk by Category" below "Active Threats").
public struct HookSecondaryTable: Codable, Sendable {
    public let id: String?
    public let title: String?
    public let icon: String?
    public let dataSource: HookDataSource?
    public let columns: [HookColumnDefinition]?

    enum CodingKeys: String, CodingKey {
        case id, title, icon
        case dataSource = "data_source"
        case columns
    }
}

// MARK: - Sidebar Item Definition

/// A sidebar navigation item for sidebar_detail layout.
/// The "file" field references a sidebar-*.json file resolved at load time.
public struct HookSidebarItem: Codable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let icon: String?
    public let file: String?  // e.g. "sidebar-dashboard.json"

    /// Badge data source (optional — shows a count badge next to the label)
    public let badgeSource: HookDataSource?

    /// Resolved content — populated by HookLoader from the referenced file
    public var content: HookPluginDefinition?

    enum CodingKeys: String, CodingKey {
        case id, label, icon, file
        case badgeSource = "badge_source"
        case content
    }
}
