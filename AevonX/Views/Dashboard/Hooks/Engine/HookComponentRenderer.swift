//
//  HookComponentRenderer.swift
//  AevonX
//
//  Routes a HookPluginDefinition to the correct SwiftUI component view.
//  Supports component versioning via `component_version` in the plugin JSON.
//  Defaults to "v1" if unspecified — safe fallback for all existing plugins.
//

import SwiftUI
import AevonXCore

// MARK: - Component Renderer (versioned entry point)

struct HookComponentRenderer: View {
    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    /// Resolved component version — falling back to "v1" if not declared in JSON
    private var componentVersion: String {
        plugin.componentVersion ?? "v1"
    }

    var body: some View {
        Group {
            switch componentVersion {
            case "v1":
                HookComponentRendererV1(plugin: plugin, serverId: serverId, context: context)
            // Future versions slot in here without breaking existing plugins:
            // case "v2":
            //     HookComponentRendererV2(plugin: plugin, serverId: serverId, context: context)
            default:
                // Unknown version → graceful fallback to v1
                HookComponentRendererV1(plugin: plugin, serverId: serverId, context: context)
            }
        }
    }
}

// MARK: - V1 Router

/// Routes a plugin to the correct v1 SwiftUI component.
/// All existing plugins use this renderer unless they declare `"component_version": "v2"` or higher.
private struct HookComponentRendererV1: View {
    let plugin: HookPluginDefinition
    let serverId: String
    let context: [String: String]

    var body: some View {
        switch plugin.component {
        case .button:
            PluginButtonComponent(plugin: plugin, serverId: serverId, context: context)

        case .card:
            PluginCardComponent(plugin: plugin, serverId: serverId, context: context)

        case .statsCard:
            PluginStatsCardComponent(plugin: plugin, serverId: serverId, context: context)

        case .modal:
            PluginModalComponent(plugin: plugin, serverId: serverId, context: context)

        case .page:
            PluginPageComponent(plugin: plugin, serverId: serverId, context: context)

        case .section:
            PluginSectionComponent(plugin: plugin, serverId: serverId, context: context)

        case .table:
            PluginTableComponent(plugin: plugin, serverId: serverId, context: context)

        case .dataTable:
            PluginDataTableComponent(plugin: plugin, serverId: serverId, context: context)

        case .form:
            PluginFormComponent(plugin: plugin, serverId: serverId, context: context)

        case .chart:
            PluginChartComponent(plugin: plugin, serverId: serverId, context: context)

        case .timeline:
            PluginTableComponent(plugin: plugin, serverId: serverId, context: context)

        case .badge:
            PluginStatsCardComponent(plugin: plugin, serverId: serverId, context: context)

        case .tabs, .grid, .detailsView:
            PluginPageComponent(plugin: plugin, serverId: serverId, context: context)

        case .logViewer:
            PluginLogViewerComponent(plugin: plugin, serverId: serverId, context: context)

        case .progress:
            PluginProgressComponent(plugin: plugin, serverId: serverId, context: context)

        case .toggleList:
            PluginToggleListComponent(plugin: plugin, serverId: serverId, context: context)

        case .gauge:
            PluginGaugeComponent(plugin: plugin, serverId: serverId, context: context)

        case .codeEditor:
            PluginCodeEditorComponent(plugin: plugin, serverId: serverId, context: context)

        case .wizard:
            PluginWizardComponent(plugin: plugin, serverId: serverId, context: context)

        case .alert:
            PluginAlertComponent(plugin: plugin, serverId: serverId, context: context)

        case .markdown:
            PluginMarkdownComponent(plugin: plugin, serverId: serverId, context: context)

        case .geoMap:
            PluginGeoMapComponent(plugin: plugin, serverId: serverId, context: context)

        // ── New component types (page-level layouts) ─────────────────────
        case .dashboard, .kanbanBoard, .splitView, .metricsGrid, .flowDiagram:
            PluginPageComponent(plugin: plugin, serverId: serverId, context: context)

        case nil, .none:
            PluginPageComponent(plugin: plugin, serverId: serverId, context: context)
        }
    }
}

// MARK: - Backward Compatibility

typealias PluginComponentRenderer = HookComponentRenderer
