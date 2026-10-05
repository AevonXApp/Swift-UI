//
//  HookDataModels.swift
//  AevonXCoreBridge
//
//  Data-related models: commands, data sources, formats, conditions.
//

import Foundation

// MARK: - Button Styles

public enum HookButtonStyle: String, Codable, Sendable {
    case primary    = "primary"
    case secondary  = "secondary"
    case danger     = "danger"
    case warning    = "warning"
    case success    = "success"
    case ghost      = "ghost"
}

// MARK: - Command

public struct HookPluginCommand: Codable, Sendable {
    public let type: HookCommandType
    public let action: String
    public let payload: [String: AnyCodable]?
    public let timeout: TimeInterval?
    public let retries: Int?

    /// Toast message shown on success (nil = no toast)
    public let onSuccess: String?

    /// Toast message shown on error (nil = no toast)
    public let onError: String?

    enum CodingKeys: String, CodingKey {
        case type, action, payload, timeout, retries
        case onSuccess = "on_success"
        case onError = "on_error"
    }

    public init(type: HookCommandType, action: String, payload: [String: AnyCodable]? = nil, timeout: TimeInterval? = nil, retries: Int? = nil, onSuccess: String? = nil, onError: String? = nil) {
        self.type = type
        self.action = action
        self.payload = payload
        self.timeout = timeout
        self.retries = retries
        self.onSuccess = onSuccess
        self.onError = onError
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = (try? container.decode(HookCommandType.self, forKey: .type)) ?? .coreCmd
        self.action = try container.decode(String.self, forKey: .action)
        self.payload = try? container.decode([String: AnyCodable].self, forKey: .payload)
        self.timeout = try? container.decode(TimeInterval.self, forKey: .timeout)
        self.retries = try? container.decode(Int.self, forKey: .retries)
        self.onSuccess = try? container.decode(String.self, forKey: .onSuccess)
        self.onError = try? container.decode(String.self, forKey: .onError)
    }
}

public enum HookCommandType: String, Codable, Sendable {
    case coreCmd      = "core_cmd"
    case pluginCmd    = "plugin_cmd"
    case asyncCmd     = "async_cmd"
    case streamingCmd = "streaming_cmd"
}

// MARK: - Data Source (for rich data views)

/// Defines how a component fetches and parses its data
public struct HookDataSource: Codable, Sendable {
    public let action: String
    public let payload: [String: AnyCodable]?
    public let format: HookDataFormat?
    public let refreshInterval: TimeInterval?
    public let rowsPath: String?
    public let type: HookCommandType?
    public let pageSize: Int?
    public let valuePath: String?
    public let transform: String?
    public let keyColumn: String?

    enum CodingKeys: String, CodingKey {
        case action, payload, format, type
        case refreshInterval = "refresh_interval"
        case rowsPath = "rows_path"
        case pageSize = "page_size"
        case valuePath = "value_path"
        case transform
        case keyColumn = "key_column"
    }

    public init(action: String, format: HookDataFormat? = .json, payload: [String: AnyCodable]? = nil, refreshInterval: TimeInterval? = nil, rowsPath: String? = nil, type: HookCommandType? = nil, pageSize: Int? = nil, valuePath: String? = nil, transform: String? = nil, keyColumn: String? = nil) {
        self.action = action
        self.format = format
        self.payload = payload
        self.refreshInterval = refreshInterval
        self.rowsPath = rowsPath
        self.type = type
        self.pageSize = pageSize
        self.valuePath = valuePath
        self.transform = transform
        self.keyColumn = keyColumn
    }
}

public enum HookDataFormat: String, Codable, Sendable {
    case json       = "json"
    case csv        = "csv"
    case tsv        = "tsv"
    case lines      = "lines"
    case keyValue   = "key_value"
    case nginx      = "nginx"
    case apache     = "apache"
    case number     = "number"
    case raw        = "raw"
}

// MARK: - Conditions

public struct HookCondition: Codable, Sendable {
    public let field: String
    public let op: HookConditionOperator
    public let value: AnyCodable

    enum CodingKeys: String, CodingKey {
        case field
        case op = "operator"
        case value
    }
}

public enum HookConditionOperator: String, Codable, Sendable {
    case equals      = "eq"
    case notEquals   = "neq"
    case contains    = "contains"
    case greaterThan = "gt"
    case lessThan    = "lt"
    case exists      = "exists"
}

// MARK: - Column Filters (for data_table filtering)

/// Defines a filterable column in a data_table — renders as a dropdown or text input above the table
public struct HookColumnFilter: Codable, Sendable {
    public let key: String
    public let label: String
    public let type: HookFilterType

    public init(key: String, label: String, type: HookFilterType = .select) {
        self.key = key
        self.label = label
        self.type = type
    }
}

public enum HookFilterType: String, Codable, Sendable {
    case select = "select"   // Dropdown from unique column values
    case text   = "text"     // Free-form text filter
}

// MARK: - Command Result

public struct HookCommandResult: Sendable {
    public let pluginId: String
    public let action: String
    public let success: Bool
    public let output: String?
    public let parsedData: [[String: String]]?
    public let error: String?
    public let exitCode: Int32?
    public let duration: TimeInterval

    public init(pluginId: String, action: String, success: Bool, output: String? = nil, parsedData: [[String: String]]? = nil, error: String? = nil, exitCode: Int32? = nil, duration: TimeInterval = 0) {
        self.pluginId = pluginId
        self.action = action
        self.success = success
        self.output = output
        self.parsedData = parsedData
        self.error = error
        self.exitCode = exitCode
        self.duration = duration
    }
}

// MARK: - Column Definition (for data_table)

public struct HookColumnDefinition: Codable, Sendable {
    public let key: String
    public let label: String?
    public let type: HookColumnType?
    public let width: CGFloat?
    public let sortable: Bool?
    public let format: String?
    public let color: String?
    public let icon: String?

    /// Display label — falls back to capitalized key
    public var displayLabel: String { label ?? key.replacingOccurrences(of: "_", with: " ").capitalized }

    enum CodingKeys: String, CodingKey {
        case key, label, type, width, sortable, format, color, icon
    }

    public init(key: String, label: String? = nil, type: HookColumnType? = .text, width: CGFloat? = nil, sortable: Bool? = nil, format: String? = nil, color: String? = nil, icon: String? = nil) {
        self.key = key
        self.label = label
        self.type = type
        self.width = width
        self.sortable = sortable
        self.format = format
        self.color = color
        self.icon = icon
    }
}

public enum HookColumnType: String, Codable, Sendable {
    case text       = "text"
    case number     = "number"
    case bytes      = "bytes"
    case percent    = "percent"
    case datetime   = "datetime"
    case status     = "status"
    case badge      = "badge"
    case url        = "url"
    case ip         = "ip"
    case boolean    = "boolean"
}

// MARK: - AnyCodable Helper

public struct AnyCodable: Codable, Sendable {
    public let value: any Sendable

    public init(_ value: any Sendable) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else {
            value = ""
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Int:    try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as Bool:   try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [AnyCodable]: try container.encode(v)
        case let v as [String: AnyCodable]: try container.encode(v)
        default: try container.encode(String(describing: value))
        }
    }

    public var stringValue: String {
        switch value {
        case let v as String: return v
        case let v as Int:    return String(v)
        case let v as Double: return String(v)
        case let v as Bool:   return String(v)
        default: return String(describing: value)
        }
    }
}
