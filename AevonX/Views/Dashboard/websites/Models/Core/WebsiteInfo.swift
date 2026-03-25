//
//  WebsiteInfo.swift
//  AevonX
//
//  Comprehensive website information model
//  Represents a website instance with full metadata and status
//

import Foundation

// MARK: - Website Info

/// Represents a complete website instance with all metadata
public struct WebsiteInfo: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var domain: String
    public var status: WebsiteStatus
    public var sslEnabled: Bool
    public var sslInfo: SSLInfo?

    // Runtime configuration
    public var phpVersion: String?
    public var runtime: RuntimeType

    // Deployment information
    public var lastDeployed: Date?
    public var deploymentStatus: DeploymentStatus
    public var gitBranch: String?
    public var gitCommit: String?
    public var gitRepository: String?

    // Resource usage
    public var diskUsage: Double // MB
    public var bandwidth: Double // GB per month
    public var monthlyVisitors: Int?
    public var dailyRequests: Int?

    // Server configuration
    public var host: String
    public var port: Int?
    public var documentRoot: String?
    public var configPath: String?
    public var webServerEngine: String? // "nginx" or "apache"

    // Health & Performance
    public var isReachable: Bool
    public var responseTime: Double? // milliseconds
    public var uptime: Double? // percentage
    public var healthIssues: [WebsiteHealthIssue]

    // Timestamps
    public var createdAt: Date?
    public var lastCheckedAt: Date?

    // Additional configuration
    public var environment: EnvironmentType
    public var customHeaders: [String: String]?
    public var redirects: [RedirectRule]?
    public var aliases: [String]
    public var activeConnections: Int
    public var connectionList: [DetailedConnection]

    public init(
        id: UUID = UUID(),
        name: String,
        domain: String,
        status: WebsiteStatus = .offline,
        sslEnabled: Bool = false,
        sslInfo: SSLInfo? = nil,
        phpVersion: String? = nil,
        runtime: RuntimeType = .php,
        lastDeployed: Date? = nil,
        deploymentStatus: DeploymentStatus = .none,
        gitBranch: String? = nil,
        gitCommit: String? = nil,
        gitRepository: String? = nil,
        diskUsage: Double = 0,
        bandwidth: Double = 0,
        monthlyVisitors: Int? = nil,
        dailyRequests: Int? = nil,
        host: String = "localhost",
        port: Int? = nil,
        documentRoot: String? = nil,
        configPath: String? = nil,
        webServerEngine: String? = nil,
        isReachable: Bool = false,
        responseTime: Double? = nil,
        uptime: Double? = nil,
        healthIssues: [WebsiteHealthIssue] = [],
        createdAt: Date? = nil,
        lastCheckedAt: Date? = nil,
        environment: EnvironmentType = .production,
        customHeaders: [String: String]? = nil,
        redirects: [RedirectRule]? = nil,
        aliases: [String] = [],
        activeConnections: Int = 0,
        connectionList: [DetailedConnection] = []
    ) {
        self.id = id
        self.name = name
        self.domain = domain
        self.status = status
        self.sslEnabled = sslEnabled
        self.sslInfo = sslInfo
        self.phpVersion = phpVersion
        self.runtime = runtime
        self.lastDeployed = lastDeployed
        self.deploymentStatus = deploymentStatus
        self.gitBranch = gitBranch
        self.gitCommit = gitCommit
        self.gitRepository = gitRepository
        self.diskUsage = diskUsage
        self.bandwidth = bandwidth
        self.monthlyVisitors = monthlyVisitors
        self.dailyRequests = dailyRequests
        self.host = host
        self.port = port ?? 80
        self.documentRoot = documentRoot
        self.configPath = configPath
        self.webServerEngine = webServerEngine
        self.isReachable = isReachable
        self.responseTime = responseTime
        self.uptime = uptime
        self.healthIssues = healthIssues
        self.createdAt = createdAt
        self.lastCheckedAt = lastCheckedAt
        self.environment = environment
        self.customHeaders = customHeaders
        self.redirects = redirects
        self.aliases = aliases
        self.activeConnections = activeConnections
        self.connectionList = connectionList
    }

    /// Formatted disk usage string
    public var formattedDiskUsage: String {
        if diskUsage >= 1024 * 1024 {
            return String(format: "%.2f TB", diskUsage / (1024 * 1024))
        } else if diskUsage >= 1024 {
            return String(format: "%.2f GB", diskUsage / 1024)
        } else {
            return String(format: "%.1f MB", diskUsage)
        }
    }

    /// Formatted bandwidth string
    public var formattedBandwidth: String {
        if bandwidth >= 1024 {
            return String(format: "%.2f TB", bandwidth / 1024)
        } else {
            return String(format: "%.1f GB", bandwidth)
        }
    }

    /// Whether the website is in a healthy state
    public var isHealthy: Bool {
        status == .online && isReachable && healthIssues.isEmpty
    }

    /// Overall health score (0-100)
    public var healthScore: Int {
        var score = 100

        if status != .online { score -= 30 }
        if !isReachable { score -= 40 }
        if !sslEnabled { score -= 10 }
        score -= healthIssues.count * 5

        return max(0, score)
    }

    /// Full URL with scheme
    public var fullURL: String {
        let scheme = sslEnabled ? "https" : "http"
        return "\(scheme)://\(domain)"
    }
}

// MARK: - Detailed Connection

public struct DetailedConnection: Identifiable, Codable, Hashable {
    public let id: UUID
    public let ip: String
    public let count: Int
    public var location: String?
    
    public init(id: UUID = UUID(), ip: String, count: Int, location: String? = nil) {
        self.id = id
        self.ip = ip
        self.count = count
        self.location = location
    }
}

// MARK: - Website Status

public enum WebsiteStatus: String, Codable, CaseIterable {
    case online = "online"
    case offline = "offline"
    case maintenance = "maintenance"
    case error = "error"
    case deploying = "deploying"
    case unknown = "unknown"

    public var isActive: Bool {
        self == .online
    }
}

// MARK: - Deployment Status

public enum DeploymentStatus: String, Codable, CaseIterable {
    case none = "none"
    case pending = "pending"
    case inProgress = "in_progress"
    case success = "success"
    case failed = "failed"
    case rolledBack = "rolled_back"
}

// MARK: - Runtime Type

public enum RuntimeType: String, Codable, CaseIterable {
    case php = "PHP"
    case nodejs = "Node.js"
    case python = "Python"
    case ruby = "Ruby"
    case `static` = "Static"
    case docker = "Docker"

    public var icon: String {
        switch self {
        case .php: return "chevron.left.forwardslash.chevron.right"
        case .nodejs: return "terminal"
        case .python: return "snake"
        case .ruby: return "diamond"
        case .`static`: return "doc.text"
        case .docker: return "shippingbox"
        }
    }
}

// MARK: - Environment Type

public enum EnvironmentType: String, Codable, CaseIterable {
    case production = "Production"
    case staging = "Staging"
    case development = "Development"
    case testing = "Testing"
}

// MARK: - Redirect Rule

public struct RedirectRule: Identifiable, Codable, Hashable {
    public let id: UUID
    public var source: String
    public var destination: String
    public var statusCode: Int // 301, 302, etc.
    public var isRegex: Bool

    public init(
        id: UUID = UUID(),
        source: String,
        destination: String,
        statusCode: Int = 301,
        isRegex: Bool = false
    ) {
        self.id = id
        self.source = source
        self.destination = destination
        self.statusCode = statusCode
        self.isRegex = isRegex
    }
}
