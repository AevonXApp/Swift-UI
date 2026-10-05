//
//  HookInfoModels.swift
//  AevonXCoreBridge
//
//  Models for the declarative `info_card` and `command_block` components.
//  These let plugins render status panels (key-value readouts) and
//  copyable command blocks entirely from JSON — no native code per plugin.
//

import Foundation

// MARK: - Info Card item

/// One row inside an info_card. Rendered as: [icon] Label · · · Value
/// Fields are optional; the renderer skips missing parts.
public struct HookInfoItem: Codable, Sendable, Identifiable {
    public var id: String { key ?? label ?? UUID().uuidString }

    /// Dot-path into the data_source JSON (e.g. "tpm.device"). When set,
    /// the resolved value overrides the static `value` field.
    public let key: String?
    /// Label shown on the left. Always displayed if present.
    public let label: String?
    /// Static fallback value — used when `key` is empty or fails to resolve.
    public let value: String?
    /// SF Symbol shown before the label.
    public let icon: String?
    /// AX color token name: "accent_blue", "accent_green", "warning",
    /// "error", "text_muted", "text_primary", etc. Mapped to Color.ax*.
    public let color: String?
    /// Render value in monospaced font (for paths, hashes, IDs).
    public let mono: Bool?
    /// Value rendering hint — reuses HookColumnType so "badge", "boolean",
    /// "datetime", etc. behave the same as in data_table cells.
    public let type: HookColumnType?

    public init(key: String? = nil, label: String? = nil, value: String? = nil,
                icon: String? = nil, color: String? = nil, mono: Bool? = nil,
                type: HookColumnType? = nil) {
        self.key = key
        self.label = label
        self.value = value
        self.icon = icon
        self.color = color
        self.mono = mono
        self.type = type
    }
}
