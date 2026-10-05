//
//  HookActionModels.swift
//  AevonXCoreBridge
//
//  Action-related models: row actions, batch actions, confirmations, form fields.
//

import Foundation

// MARK: - Row Actions

/// Defines what happens when a table row is tapped
public struct HookRowAction: Codable, Sendable {
    public let action: String
    public let payload: [String: AnyCodable]?
    public let title: String?
    public let type: HookCommandType?

    /// Sections to display in the detail sheet — groups related fields with icons
    public let sections: [HookRowDetailSection]?

    enum CodingKeys: String, CodingKey {
        case action, payload, title, type, sections
    }

    public init(action: String, payload: [String: AnyCodable]? = nil, title: String? = nil, type: HookCommandType? = nil, sections: [HookRowDetailSection]? = nil) {
        self.action = action
        self.payload = payload
        self.title = title
        self.type = type
        self.sections = sections
    }
}

/// A section in the row detail sheet — groups related fields under a title with an optional icon
public struct HookRowDetailSection: Codable, Sendable {
    public let title: String
    public let icon: String?
    public let fields: [String]

    public init(title: String, icon: String? = nil, fields: [String]) {
        self.title = title
        self.icon = icon
        self.fields = fields
    }
}

/// Defines a batch action for multi-select in data_table
public struct HookBatchAction: Codable, Sendable {
    public let action: String
    public let label: String
    public let icon: String?
    public let style: HookButtonStyle?
    public let confirmationMessage: String?
    public let confirmation: HookConfirmation?

    enum CodingKeys: String, CodingKey {
        case action, label, icon, style, confirmation
        case confirmationMessage = "confirmation_message"
    }

    public init(action: String, label: String, icon: String? = nil, style: HookButtonStyle? = nil, confirmationMessage: String? = nil, confirmation: HookConfirmation? = nil) {
        self.action = action
        self.label = label
        self.icon = icon
        self.style = style
        self.confirmationMessage = confirmationMessage
        self.confirmation = confirmation
    }
}

/// Rich confirmation dialog with optional input fields
public struct HookConfirmation: Codable, Sendable {
    public let title: String
    public let message: String
    public let confirmLabel: String?
    public let cancelLabel: String?
    public let style: HookButtonStyle?
    public let fields: [HookFormField]?

    enum CodingKeys: String, CodingKey {
        case title, message, style, fields
        case confirmLabel = "confirm_label"
        case cancelLabel = "cancel_label"
    }

    public init(title: String, message: String, confirmLabel: String? = nil, cancelLabel: String? = nil, style: HookButtonStyle? = nil, fields: [HookFormField]? = nil) {
        self.title = title
        self.message = message
        self.confirmLabel = confirmLabel
        self.cancelLabel = cancelLabel
        self.style = style
        self.fields = fields
    }
}

// MARK: - Row Action Buttons (inline per-row actions)

public struct HookRowActionButton: Codable, Sendable {
    public let label: String
    public let icon: String?
    public let style: HookButtonStyle?
    public let command: HookPluginCommand?
    public let confirmationMessage: String?

    enum CodingKeys: String, CodingKey {
        case label, icon, style, command
        case confirmationMessage = "confirmation_message"
    }

    public init(label: String, icon: String? = nil, style: HookButtonStyle? = nil, command: HookPluginCommand? = nil, confirmationMessage: String? = nil) {
        self.label = label
        self.icon = icon
        self.style = style
        self.command = command
        self.confirmationMessage = confirmationMessage
    }
}

// MARK: - Form Field Definitions

public enum HookFormFieldType: String, Codable, Sendable {
    case text        = "text"
    case number      = "number"
    case password    = "password"
    case textarea    = "textarea"
    case select      = "select"
    case multiselect = "multiselect"  // Multiple selections from a list
    case toggle      = "toggle"
    case date        = "date"
    case slider      = "slider"
    case tags        = "tags"         // Free-form multi-value text input (comma-separated chip UI)
    case fileSelect  = "file_select"  // Browse and select a path from the remote server
}

public struct HookFormFieldOption: Codable, Sendable {
    public let value: String
    public let label: String

    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }

    public init(from decoder: Decoder) throws {
        if let stringVal = try? decoder.singleValueContainer().decode(String.self) {
            self.value = stringVal
            self.label = stringVal
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.value = try container.decode(String.self, forKey: .value)
            self.label = try container.decode(String.self, forKey: .label)
        }
    }

    enum CodingKeys: String, CodingKey {
        case value, label
    }
}

public struct HookFormField: Codable, Sendable {
    public let key: String
    public let label: String
    public let type: HookFormFieldType
    public let placeholder: String?
    public let defaultValue: AnyCodable?
    public let required: Bool?
    public let options: [HookFormFieldOption]?
    public let min: Double?
    public let max: Double?
    public let step: Double?
    public let pattern: String?
    public let helpText: String?
    public let icon: String?

    enum CodingKeys: String, CodingKey {
        case key, label, type, placeholder, required, options
        case min, max, step, pattern, icon
        case defaultValue = "default"
        case helpText = "help_text"
    }

    public init(
        key: String, label: String, type: HookFormFieldType = .text,
        placeholder: String? = nil, defaultValue: AnyCodable? = nil,
        required: Bool? = nil, options: [HookFormFieldOption]? = nil,
        min: Double? = nil, max: Double? = nil, step: Double? = nil,
        pattern: String? = nil, helpText: String? = nil, icon: String? = nil
    ) {
        self.key = key; self.label = label; self.type = type
        self.placeholder = placeholder; self.defaultValue = defaultValue
        self.required = required; self.options = options
        self.min = min; self.max = max; self.step = step
        self.pattern = pattern; self.helpText = helpText; self.icon = icon
    }
}
