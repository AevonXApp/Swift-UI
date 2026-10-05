//
//  HookComponentType.swift
//  AevonXCoreBridge
//
//  All available UI component types that a hook can render.
//

import Foundation

// MARK: - Component Types

public enum HookComponentType: String, Codable, Sendable {
    case button       = "button"
    case card         = "card"
    case statsCard    = "stats_card"
    case form         = "form"
    case modal        = "modal"
    case table        = "table"
    case dataTable    = "data_table"   // Rich table with columns, sorting, data_source
    case chart        = "chart"        // Line/bar/pie chart from data_source
    case tabs         = "tabs"
    case page         = "page"
    case section      = "section"
    case grid         = "grid"
    case detailsView  = "details_view"
    case timeline     = "timeline"     // Timeline/log view
    case badge        = "badge"        // Status badge
    case logViewer    = "log_viewer"   // Streaming/static log output
    case progress     = "progress"     // Multi-step progress tracker
    case toggleList   = "toggle_list"  // List of on/off switches
    case gauge        = "gauge"        // Circular metric gauge
    case codeEditor   = "code_editor"  // Syntax-highlighted text editor
    case wizard       = "wizard"       // Multi-step setup wizard
    case alert        = "alert"        // Alert/banner with severity
    case markdown     = "markdown"     // Markdown content viewer
    case geoMap       = "geo_map"      // Geographic attack map

    // ── New component types ─────────────────────────────────────────────
    case dashboard     = "dashboard"     // Dashboard with widgets
    case kanbanBoard   = "kanban_board"  // Kanban board with draggable cards
    case splitView     = "split_view"    // Master-detail split view
    case metricsGrid   = "metrics_grid"  // Dense metrics grid
    case flowDiagram   = "flow_diagram"  // Process/pipeline flow chart

    // ── v2.2: declarative widgets for status/config screens ───────────
    /// A titled card rendering a list of {label, value, icon, color} rows.
    /// Used for static status readouts: TPM details, KEK metadata, ACME
    /// account info. Content comes from `data_source` (JSON) OR the static
    /// `fields` array in the plugin JSON.
    case infoCard     = "info_card"
    /// Code-styled, copyable command block with optional caption. Renders
    /// one command the user is expected to run themselves on the server —
    /// e.g. `axvault kek rotate --passphrase-file=...`. Supports a
    /// clipboard copy button.
    case commandBlock = "command_block"
}
