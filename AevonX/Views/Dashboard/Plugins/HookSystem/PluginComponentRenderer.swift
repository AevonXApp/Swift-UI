//
//  PluginComponentRenderer.swift
//  AevonX
//
//  Routes a HookPluginDefinition to the correct SwiftUI component view.
//

import SwiftUI
import AevonXCore

struct PluginComponentRenderer: View {
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
            // Rich data table with columns, sorting, search, auto-refresh
            PluginDataTableComponent(plugin: plugin, serverId: serverId, context: context)

        case .form:
            PluginFormComponent(plugin: plugin, serverId: serverId, context: context)

        case .chart:
            PluginPageComponent(plugin: plugin, serverId: serverId, context: context)

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
        }
    }
}
