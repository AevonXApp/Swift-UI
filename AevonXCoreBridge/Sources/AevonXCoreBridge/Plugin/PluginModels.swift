//
//  PluginModels.swift
//  AevonXCoreBridge
//
//  Models for plugin system
//

import Foundation

// MARK: - Plugin Category

/// A category for organizing plugins in the marketplace
public struct PluginCategory: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let slug: String
    public let icon: String?
    public let pluginsCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug, icon
        case pluginsCount = "plugins_count"
    }
    
    public init(id: String, name: String, slug: String, icon: String? = nil, pluginsCount: Int? = nil) {
        self.id = id
        self.name = name
        self.slug = slug
        self.icon = icon
        self.pluginsCount = pluginsCount
    }
}

/// Response for categories listing
public struct PluginCategoriesResponse: Codable {
    public let categories: [PluginCategory]
}

// MARK: - Plugin

/// Represents a plugin from the marketplace
public struct Plugin: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let slug: String
    public let description: String
    public let shortDescription: String?
    public let imageUrl: String?
    public let status: String
    public let isOfficial: Bool
    public let downloadsCount: Int
    public let rating: String? // Decimal handled as String from Laravel
    public let activeVersion: PluginVersion?
    public let pricing: PluginPricing?
    public let isPurchased: Bool
    public let user: PluginDeveloper?
    public let versions: [PluginVersion]?
    public let category: PluginCategory?
    public let pluginCategoryId: String?
    public let documentationUrl: String?
    public let supportUrl: String?
    public let license: String?
    public let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, status, rating, pricing, versions, category, license, tags
        case shortDescription = "short_description"
        case imageUrl = "image_url"
        case isOfficial = "is_official"
        case downloadsCount = "downloads_count"
        case activeVersion = "active_version"
        case isPurchased = "is_purchased"
        case user
        case pluginCategoryId = "plugin_category_id"
        case documentationUrl = "documentation_url"
        case supportUrl = "support_url"
    }

    public init(id: String, name: String, slug: String, description: String, shortDescription: String? = nil, imageUrl: String? = nil, status: String, isOfficial: Bool, downloadsCount: Int, rating: String? = nil, activeVersion: PluginVersion? = nil, pricing: PluginPricing? = nil, isPurchased: Bool = false, user: PluginDeveloper? = nil, versions: [PluginVersion]? = nil, category: PluginCategory? = nil, pluginCategoryId: String? = nil, documentationUrl: String? = nil, supportUrl: String? = nil, license: String? = nil, tags: [String]? = nil) {
        self.id = id
        self.name = name
        self.slug = slug
        self.description = description
        self.shortDescription = shortDescription
        self.imageUrl = imageUrl
        self.status = status
        self.isOfficial = isOfficial
        self.downloadsCount = downloadsCount
        self.rating = rating
        self.activeVersion = activeVersion
        self.pricing = pricing
        self.isPurchased = isPurchased
        self.user = user
        self.versions = versions
        self.category = category
        self.pluginCategoryId = pluginCategoryId
        self.documentationUrl = documentationUrl
        self.supportUrl = supportUrl
        self.license = license
        self.tags = tags
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        description = try container.decode(String.self, forKey: .description)
        shortDescription = try container.decodeIfPresent(String.self, forKey: .shortDescription)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        status = try container.decode(String.self, forKey: .status)
        isOfficial = try container.decodeIfPresent(Bool.self, forKey: .isOfficial) ?? false
        downloadsCount = try container.decodeIfPresent(Int.self, forKey: .downloadsCount) ?? 0
        rating = try container.decodeIfPresent(String.self, forKey: .rating)
        activeVersion = try container.decodeIfPresent(PluginVersion.self, forKey: .activeVersion)
        pricing = try container.decodeIfPresent(PluginPricing.self, forKey: .pricing)
        isPurchased = try container.decodeIfPresent(Bool.self, forKey: .isPurchased) ?? false
        user = try container.decodeIfPresent(PluginDeveloper.self, forKey: .user)
        versions = try container.decodeIfPresent([PluginVersion].self, forKey: .versions)
        category = try container.decodeIfPresent(PluginCategory.self, forKey: .category)
        pluginCategoryId = try container.decodeIfPresent(String.self, forKey: .pluginCategoryId)
        documentationUrl = try container.decodeIfPresent(String.self, forKey: .documentationUrl)
        supportUrl = try container.decodeIfPresent(String.self, forKey: .supportUrl)
        license = try container.decodeIfPresent(String.self, forKey: .license)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Plugin, rhs: Plugin) -> Bool {
        lhs.id == rhs.id
    }
}

/// Developer info for a plugin
public struct PluginDeveloper: Codable, Sendable, Hashable {
    public let id: Int
    public let name: String
    public let email: String?
    public let username: String?
    public let avatarUrl: String?
    public let isVerifiedDeveloper: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, email, username
        case avatarUrl = "avatar_url"
        case isVerifiedDeveloper = "is_verified_developer"
    }

    public init(id: Int, name: String, email: String? = nil, username: String? = nil, avatarUrl: String? = nil, isVerifiedDeveloper: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.username = username
        self.avatarUrl = avatarUrl
        self.isVerifiedDeveloper = isVerifiedDeveloper
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        isVerifiedDeveloper = try container.decodeIfPresent(Bool.self, forKey: .isVerifiedDeveloper) ?? false
    }
}

// MARK: - Pricing

/// Pricing type for a plugin
public enum PluginPricingType: String, Codable {
    case free
    case paid
    case subscribers
    
    public var displayLabel: String {
        switch self {
        case .free: return "Free"
        case .paid: return "Paid"
        case .subscribers: return "Pro"
        }
    }
}

/// Pricing information for a plugin
public struct PluginPricing: Codable, Sendable, Hashable {
    public let pricingType: String
    public let price: String?
    public let duration: String?
    public let serverLimit: Int?
    
    enum CodingKeys: String, CodingKey {
        case price, duration
        case pricingType = "pricing_type"
        case serverLimit = "server_limit"
    }
    
    /// Parsed pricing type enum
    public var type: PluginPricingType {
        PluginPricingType(rawValue: pricingType) ?? .free
    }
    
    public var isFree: Bool { type == .free }
    public var isPaid: Bool { type == .paid }
    public var isSubscribers: Bool { type == .subscribers }
    
    /// Formatted display label for the pricing badge
    public var displayLabel: String {
        switch type {
        case .free:
            return "Free"
        case .paid:
            if let p = price, let d = Double(p), d > 0 {
                return String(format: "$%.2f", d)
            }
            return "Paid"
        case .subscribers:
            return "Pro"
        }
    }
    
    /// Server limit display text
    public var serverLimitLabel: String {
        if isPaid, let limit = serverLimit {
            return "\(limit) server\(limit == 1 ? "" : "s")"
        }
        return "Unlimited"
    }
}

/// Version information for a plugin
public struct PluginVersion: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let versionNumber: String
    public let changelog: String?
    public let repositoryUrl: String?
    public let isActive: Bool
    public let files: [PluginFile]?
    
    enum CodingKeys: String, CodingKey {
        case id, changelog
        case versionNumber = "version_number"
        case repositoryUrl = "repository_url"
        case isActive = "is_active"
        case files
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: PluginVersion, rhs: PluginVersion) -> Bool {
        lhs.id == rhs.id
    }
}

/// File associated with a plugin version
/// Note: google_drive_url and google_drive_file_id are stripped by the API
public struct PluginFile: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let fileType: String // 'build' or 'script'
    public let fileName: String
    public let fileSize: Int?
    public let mimeType: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fileName = "file_name"
        case fileType = "file_type"
        case fileSize = "file_size"
        case mimeType = "mime_type"
    }
}

// MARK: - Download

/// One-time download link info from the API
public struct PluginDownloadInfo: Codable {
    public let pluginId: String
    public let version: String
    public let downloadToken: String
    public let downloadUrl: String
    public let expiresAt: String
    public let fileName: String
    public let fileSize: Int?
    
    enum CodingKeys: String, CodingKey {
        case version
        case fileName = "file_name"
        case pluginId = "plugin_id"
        case downloadToken = "download_token"
        case downloadUrl = "download_url"
        case expiresAt = "expires_at"
        case fileSize = "file_size"
    }
}

// MARK: - Pagination & API Responses

/// Paginated response for plugins
public struct PaginatedPlugins: Codable, Sendable {
    public let data: [Plugin]
    public let currentPage: Int
    public let lastPage: Int
    public let total: Int
    
    enum CodingKeys: String, CodingKey {
        case data, total
        case currentPage = "current_page"
        case lastPage = "last_page"
    }
}

/// Root response from plugin index
public struct PluginIndexResponse: Codable {
    public let plugins: PaginatedPlugins
}

/// Root response for plugin detail
public struct PluginDetailResponse: Codable {
    public let plugin: Plugin
}

/// Local status of a plugin (installed, installing, etc)
public enum PluginInstallStatus: String, Codable {
    case available = "available"
    case downloading = "downloading"
    case installing = "installing"
    case installed = "installed"
    case failed = "failed"
}

// MARK: - Install Source

/// Tracks how a plugin was installed on a server
public enum InstallSource: String, Codable, Sendable {
    /// Installed from the AevonX marketplace (official flow)
    case marketplace
    /// Installed by the server owner via Upload Build (dev flow)
    case devBuild = "dev_build"
    /// Source could not be determined (old install)
    case unknown
}

// MARK: - License Verification

/// Result of a runtime license verification check.
public struct LicenseVerificationResult: Sendable {
    public let valid: Bool
    public let pricingType: String
    public let reason: String?
    public let expiresAt: String?
    public let verificationToken: String?
    public let ttl: Int?
    // Signed license token for secure download (from Fortress verification)
    public let licenseToken: String?
    public let tokenSignature: String?
    public let nonce: String?

    public init(valid: Bool, pricingType: String, reason: String? = nil, expiresAt: String? = nil, verificationToken: String? = nil, ttl: Int? = nil, licenseToken: String? = nil, tokenSignature: String? = nil, nonce: String? = nil) {
        self.valid = valid
        self.pricingType = pricingType
        self.reason = reason
        self.expiresAt = expiresAt
        self.verificationToken = verificationToken
        self.ttl = ttl
        self.licenseToken = licenseToken
        self.tokenSignature = tokenSignature
        self.nonce = nonce
    }

    /// Whether the backend authorized this request (cryptographic proof via license_token).
    /// SECURITY: Do NOT use `valid` boolean as a gate — it can be patched.
    /// The license_token is the ONLY proof. No token = no authorization.
    public var isAuthorized: Bool {
        guard let token = licenseToken, !token.isEmpty else { return false }
        return true
    }

    /// User-friendly message describing why the license is invalid.
    public var userMessage: String? {
        guard !isAuthorized else { return nil }
        switch reason {
        case "subscription_required":
            return "An active Pro subscription is required for this plugin."
        case "purchase_required":
            return "A valid license is required for this plugin."
        case "missing_server":
            return "Server identification required."
        case "plugin_not_found":
            return "Plugin not found."
        default:
            return "Unable to verify plugin license."
        }
    }
}

// MARK: - Configuration Models

/// Root configuration object for config.avx
public struct PluginConfig: Codable, Equatable {
    public var project: String
    public var description: String?
    public var version: String
    public var configInfo: ConfigInfo?
    public var configSchema: [ConfigSection]
    
    enum CodingKeys: String, CodingKey {
        case project, version, description
        case configSchema = "config_schema"
        case configInfo = "config_info"
    }
    
    public init(project: String = "", description: String? = nil, version: String = "", configInfo: ConfigInfo? = nil, configSchema: [ConfigSection] = []) {
        self.project = project
        self.description = description
        self.version = version
        self.configInfo = configInfo
        self.configSchema = configSchema
    }
}

/// Metadata information for the plugin configuration UI
public struct ConfigInfo: Codable, Equatable {
    public let color: String?
    public let accentColor: String?
    public let websiteUrl: String?
    public let docsUrl: String?
    public let githubUrl: String?
    public let xUrl: String?
    public let discordUrl: String?
    public let copyright: String?
    public let feedbackUrl: String?

    enum CodingKeys: String, CodingKey {
        case color, copyright
        case accentColor = "accent_color"
        case websiteUrl = "website_url"
        case docsUrl = "docs_url"
        case githubUrl = "github_url"
        case xUrl = "x_url"
        case discordUrl = "discord_url"
        case feedbackUrl = "feedback_url"
    }

    public init(color: String? = nil, accentColor: String? = nil, websiteUrl: String? = nil, docsUrl: String? = nil, githubUrl: String? = nil, xUrl: String? = nil, discordUrl: String? = nil, copyright: String? = nil, feedbackUrl: String? = nil) {
        self.color = color
        self.accentColor = accentColor
        self.websiteUrl = websiteUrl
        self.docsUrl = docsUrl
        self.githubUrl = githubUrl
        self.xUrl = xUrl
        self.discordUrl = discordUrl
        self.copyright = copyright
        self.feedbackUrl = feedbackUrl
    }
}

/// A section of configuration fields
public struct ConfigSection: Codable, Identifiable, Equatable {
    public var id: String { section }
    public let section: String
    public let description: String?
    public var fields: [ConfigField]
}

/// A single configuration field
public struct ConfigField: Codable, Identifiable, Equatable {
    public var id: String { key }
    public let key: String
    public let title: String?     // Preferred key in JSON
    public let label: String?     // Alias for title (used by some plugin configs)
    public let description: String?
    public let type: ConfigFieldType
    public let options: [String]?
    public var value: ConfigValue
    public let action: String?           // CLI command for action type
    public let actionStyle: String?      // primary, danger, warning, success
    public let confirmMessage: String?   // confirmation before executing

    /// Returns the display title — prefers "title", falls back to "label"
    public var displayTitle: String { title ?? label ?? key }

    enum CodingKeys: String, CodingKey {
        case key, title, label, description, type, options, value, action
        case actionStyle = "action_style"
        case confirmMessage = "confirm_message"
    }

    public init(key: String, title: String? = nil, label: String? = nil, description: String? = nil, type: ConfigFieldType, options: [String]? = nil, value: ConfigValue, action: String? = nil, actionStyle: String? = nil, confirmMessage: String? = nil) {
        self.key = key
        self.title = title
        self.label = label
        self.description = description
        self.type = type
        self.options = options
        self.value = value
        self.action = action
        self.actionStyle = actionStyle
        self.confirmMessage = confirmMessage
    }
}

/// Supported field types
public enum ConfigFieldType: String, Codable, Equatable {
    case boolean
    case text
    case number
    case options
    case array
    case password
    /// "select" is an alias for "options" — accepted from plugin config files
    case select
    /// "action" renders a button that executes a CLI command on the server
    case action

    /// Returns true if this type renders as a dropdown/picker
    public var isPickerType: Bool { self == .options || self == .select }
}

/// dynamic value wrapper for mixed types in JSON
public enum ConfigValue: Codable, Equatable {
    case bool(Bool)
    case string(String)
    case int(Int)
    case double(Double)
    case array([ConfigValue])
    case object([String: ConfigValue])
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else if let arrayVal = try? container.decode([ConfigValue].self) {
            self = .array(arrayVal)
        } else if let objectVal = try? container.decode([String: ConfigValue].self) {
            self = .object(objectVal)
        } else {
            throw DecodingError.typeMismatch(ConfigValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Value cannot be decoded"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
    
    // Helpers for UI binding
    public var asBool: Bool {
        if case .bool(let v) = self { return v }
        return false
    }
    
    public var asString: String {
        switch self {
        case .string(let v): return v
        case .int(let v): return String(v)
        case .double(let v): return String(v)
        case .bool(let v): return String(v)
        case .array(let v): 
            if let data = try? JSONEncoder().encode(v), let str = String(data: data, encoding: .utf8) {
                return str
            }
            return "[Array]"
        case .object(let v):
            if let data = try? JSONEncoder().encode(v), let str = String(data: data, encoding: .utf8) {
                return str
            }
            return "{Object}"
        case .null: return "null"
        }
    }
}
