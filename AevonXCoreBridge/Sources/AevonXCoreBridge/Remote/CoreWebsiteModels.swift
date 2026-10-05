//
//  CoreWebsiteModels.swift
//  AevonXCoreBridge
//
//  Core layer models for website management
//  These are used by CoreWebsiteService and converted to UI models in the UI layer
//

import Foundation

// MARK: - Core Website Info

/// Core layer model representing a website instance
public struct CoreWebsiteInfo: Codable, Sendable {
    public let id: UUID
    public var name: String
    public var domain: String
    public var status: CoreWebsiteStatus
    public var sslEnabled: Bool
    public var sslInfo: CoreSSLInfo?
    public var phpVersion: String?
    public var runtime: CoreRuntimeType
    public var lastDeployed: Date?
    public var deploymentStatus: CoreDeploymentStatus
    public var gitBranch: String?
    public var gitCommit: String?
    public var gitRepository: String?
    public var diskUsage: Double // MB
    public var bandwidth: Double // GB
    public var monthlyVisitors: Int?
    public var dailyRequests: Int?
    public var host: String
    public var port: Int?
    public var documentRoot: String?
    public var configPath: String?
    public var isReachable: Bool
    public var responseTime: Double? // milliseconds
    public var uptime: Double? // percentage
    public var healthIssues: [CoreWebsiteHealthIssue]
    public var createdAt: Date?
    public var lastCheckedAt: Date?
    public var environment: CoreEnvironmentType
    public var customHeaders: [String: String]?
    public var redirects: [CoreRedirectRule]?
    public var aliases: [String]
    public var activeConnections: Int
    public var connectionList: [CoreDetailedConnection]

    public init(
        id: UUID = UUID(),
        name: String,
        domain: String,
        status: CoreWebsiteStatus = .offline,
        sslEnabled: Bool = false,
        sslInfo: CoreSSLInfo? = nil,
        phpVersion: String? = nil,
        runtime: CoreRuntimeType = .php,
        lastDeployed: Date? = nil,
        deploymentStatus: CoreDeploymentStatus = .none,
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
        isReachable: Bool = false,
        responseTime: Double? = nil,
        uptime: Double? = nil,
        healthIssues: [CoreWebsiteHealthIssue] = [],
        createdAt: Date? = nil,
        lastCheckedAt: Date? = nil,
        environment: CoreEnvironmentType = .production,
        customHeaders: [String: String]? = nil,
        redirects: [CoreRedirectRule]? = nil,
        aliases: [String] = [],
        activeConnections: Int = 0,
        connectionList: [CoreDetailedConnection] = []
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
        self.port = port
        self.documentRoot = documentRoot
        self.configPath = configPath
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
}

// MARK: - Core Website Status

public enum CoreWebsiteStatus: String, Codable, Sendable {
    case online = "online"
    case offline = "offline"
    case maintenance = "maintenance"
    case error = "error"
    case deploying = "deploying"
    case unknown = "unknown"
}

// MARK: - Core Deployment Status

public enum CoreDeploymentStatus: String, Codable, Sendable {
    case none = "none"
    case pending = "pending"
    case inProgress = "in_progress"
    case success = "success"
    case failed = "failed"
    case rolledBack = "rolled_back"
}

// MARK: - Core Runtime Type

public enum CoreRuntimeType: String, Codable, Sendable {
    case php = "PHP"
    case nodejs = "Node.js"
    case python = "Python"
    case ruby = "Ruby"
    case `static` = "Static"
    case docker = "Docker"
}

// MARK: - Core Environment Type

public enum CoreEnvironmentType: String, Codable, Sendable {
    case production = "Production"
    case staging = "Staging"
    case development = "Development"
    case testing = "Testing"
}

// MARK: - Core SSL Info

public struct CoreSSLInfo: Codable, Sendable {
    public var provider: CoreSSLProvider
    public var status: CoreSSLStatus
    public var issuer: String?
    public var validFrom: Date?
    public var validUntil: Date?
    public var autoRenew: Bool
    public var domains: [String]
    public var certificateType: CoreCertificateType

    public init(
        provider: CoreSSLProvider = .letsEncrypt,
        status: CoreSSLStatus = .pending,
        issuer: String? = nil,
        validFrom: Date? = nil,
        validUntil: Date? = nil,
        autoRenew: Bool = true,
        domains: [String] = [],
        certificateType: CoreCertificateType = .single
    ) {
        self.provider = provider
        self.status = status
        self.issuer = issuer
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.autoRenew = autoRenew
        self.domains = domains
        self.certificateType = certificateType
    }
}

// MARK: - Core SSL Provider

public enum CoreSSLProvider: String, Codable, Sendable {
    case letsEncrypt = "Let's Encrypt"
    case customCertificate = "Custom Certificate"
    case cloudflare = "Cloudflare"
    case other = "Other"
}

// MARK: - Core SSL Status

public enum CoreSSLStatus: String, Codable, Sendable {
    case active = "active"
    case pending = "pending"
    case expired = "expired"
    case invalid = "invalid"
    case revoked = "revoked"
    case unknown = "unknown"
}

// MARK: - Core Certificate Type

public enum CoreCertificateType: String, Codable, Sendable {
    case single = "Single Domain"
    case wildcard = "Wildcard"
    case multiDomain = "Multi-Domain"
}

// MARK: - Core Website Health Issue

public struct CoreWebsiteHealthIssue: Codable, Sendable {
    public let id: UUID
    public var severity: CoreHealthSeverity
    public var title: String
    public var description: String
    public var recommendation: String?
    public var detectedAt: Date
    public var resolvedAt: Date?
    public var isResolved: Bool

    public init(
        id: UUID = UUID(),
        severity: CoreHealthSeverity,
        title: String,
        description: String,
        recommendation: String? = nil,
        detectedAt: Date = Date(),
        resolvedAt: Date? = nil,
        isResolved: Bool = false
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.description = description
        self.recommendation = recommendation
        self.detectedAt = detectedAt
        self.resolvedAt = resolvedAt
        self.isResolved = isResolved
    }
}

// MARK: - Core Health Severity

public enum CoreHealthSeverity: String, Codable, Sendable {
    case critical = "Critical"
    case warning = "Warning"
    case info = "Info"
}

// MARK: - Core Redirect Rule

public struct CoreRedirectRule: Codable, Sendable {
    public let id: UUID
    public var source: String
    public var destination: String
    public var statusCode: Int
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

// MARK: - Core Detailed Connection

public struct CoreDetailedConnection: Codable, Sendable {
    public let ip: String
    public let count: Int
    public var location: String? // Reserved for future GeoIP
    
    public init(ip: String, count: Int, location: String? = nil) {
        self.ip = ip
        self.count = count
        self.location = location
    }
}

// MARK: - Core Website Health

public struct CoreWebsiteHealth: Codable, Sendable {
    public var isReachable: Bool
    public var responseTime: Double?
    public var statusCode: Int?
    public var sslValid: Bool
    public var issues: [CoreWebsiteHealthIssue]

    public init(
        isReachable: Bool,
        responseTime: Double? = nil,
        statusCode: Int? = nil,
        sslValid: Bool,
        issues: [CoreWebsiteHealthIssue] = []
    ) {
        self.isReachable = isReachable
        self.responseTime = responseTime
        self.statusCode = statusCode
        self.sslValid = sslValid
        self.issues = issues
    }
}

// MARK: - Core URL Rewrite Rule

public struct URLRewriteRule: Codable, Sendable, Hashable, Equatable, Identifiable {
    public let id: UUID
    public var sourcePattern: String
    public var destination: String
    public var statusCode: Int
    public var flags: [String]
    public var conditions: [RewriteCondition]
    public var isEnabled: Bool
    public var order: Int
    public var notes: String?

    public init(
        id: UUID = UUID(),
        sourcePattern: String,
        destination: String,
        statusCode: Int = 301,
        flags: [String] = [],
        conditions: [RewriteCondition] = [],
        isEnabled: Bool = true,
        order: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.sourcePattern = sourcePattern
        self.destination = destination
        self.statusCode = statusCode
        self.flags = flags
        self.conditions = conditions
        self.isEnabled = isEnabled
        self.order = order
        self.notes = notes
    }
}

public struct RewriteCondition: Codable, Sendable, Hashable, Equatable, Identifiable {
    public let id: UUID
    public var test: String
    public var pattern: String
    public var flags: [String]

    public init(id: UUID = UUID(), test: String, pattern: String, flags: [String] = []) {
        self.id = id
        self.test = test
        self.pattern = pattern
        self.flags = flags
    }
}

public struct RewriteTestResult: Codable, Sendable {
    public var inputURL: String
    public var matchedRule: URLRewriteRule?
    public var finalURL: String
    public var wasRewritten: Bool
    public var statusCode: Int?
    public var executionTime: Double

    public init(inputURL: String, matchedRule: URLRewriteRule? = nil, finalURL: String, wasRewritten: Bool, statusCode: Int? = nil, executionTime: Double = 0) {
        self.inputURL = inputURL
        self.matchedRule = matchedRule
        self.finalURL = finalURL
        self.wasRewritten = wasRewritten
        self.statusCode = statusCode
        self.executionTime = executionTime
    }
}

// MARK: - Core SSL Certificate Details

public struct SSLCertificateDetails: Codable, Sendable, Identifiable {
    public let id: UUID
    public var issuer: String
    public var subject: String
    public var validFrom: Date
    public var validUntil: Date
    public var serialNumber: String
    public var sanDomains: [String]
    public var certificateChain: [String]
    public var signatureAlgorithm: String
    public var keySize: Int
    public var protocols: [String]
    public var certificateType: CoreCertificateType
    public var autoRenew: Bool
    public var brand: String

    public init(id: UUID = UUID(), issuer: String, subject: String, validFrom: Date, validUntil: Date, serialNumber: String, sanDomains: [String] = [], certificateChain: [String] = [], signatureAlgorithm: String, keySize: Int, protocols: [String] = [], certificateType: CoreCertificateType = .single, autoRenew: Bool = true, brand: String = "Unknown") {
        self.id = id
        self.issuer = issuer
        self.subject = subject
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.serialNumber = serialNumber
        self.sanDomains = sanDomains
        self.certificateChain = certificateChain
        self.signatureAlgorithm = signatureAlgorithm
        self.keySize = keySize
        self.protocols = protocols
        self.certificateType = certificateType
        self.autoRenew = autoRenew
        self.brand = brand
    }
}

// MARK: - SSL DNS Record (for DNS-01 challenge)

public struct SSLDNSRecord: Codable, Sendable, Identifiable {
    public let id: UUID
    public var domainName: String
    public var recordValue: String
    public var recordType: String  // "TXT" or "CAA"
    public var isRequired: Bool

    public init(id: UUID = UUID(), domainName: String, recordValue: String, recordType: String = "TXT", isRequired: Bool = true) {
        self.id = id
        self.domainName = domainName
        self.recordValue = recordValue
        self.recordType = recordType
        self.isRequired = isRequired
    }
}

// MARK: - SSL Certificate Content (PEM data)

public struct SSLCertificateContent: Codable, Sendable {
    public var certificate: String
    public var privateKey: String

    public init(certificate: String, privateKey: String) {
        self.certificate = certificate
        self.privateKey = privateKey
    }
}

// MARK: - Core Traffic Analytics

public enum TimeRange: String, Codable, Sendable {
    case lastHour = "Last Hour"
    case last24Hours = "Last 24 Hours"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case custom = "Custom Range"
}

public struct RequestStatistics: Codable, Sendable {
    public var totalRequests: Int
    public var requestsByMethod: [String: Int]
    public var requestsByStatus: [String: Int]
    public var averageResponseTime: Double
    public var errorRate: Double
    public var timeRange: TimeRange
    public var timestamp: Date

    public init(totalRequests: Int = 0, requestsByMethod: [String: Int] = [:], requestsByStatus: [String: Int] = [:], averageResponseTime: Double = 0, errorRate: Double = 0, timeRange: TimeRange = .lastHour, timestamp: Date = Date()) {
        self.totalRequests = totalRequests
        self.requestsByMethod = requestsByMethod
        self.requestsByStatus = requestsByStatus
        self.averageResponseTime = averageResponseTime
        self.errorRate = errorRate
        self.timeRange = timeRange
        self.timestamp = timestamp
    }
}

public struct BandwidthDataPoint: Codable, Sendable, Identifiable {
    public let id: UUID
    public var timestamp: Date
    public var bytesIn: Int
    public var bytesOut: Int

    public init(id: UUID = UUID(), timestamp: Date, bytesIn: Int, bytesOut: Int) {
        self.id = id
        self.timestamp = timestamp
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
    }
}

public struct EndpointStat: Codable, Sendable, Identifiable {
    public let id: UUID
    public var endpoint: String
    public var requestCount: Int
    public var averageResponseTime: Double
    public var errorCount: Int
    public var lastAccessed: Date?

    public init(id: UUID = UUID(), endpoint: String, requestCount: Int, averageResponseTime: Double, errorCount: Int, lastAccessed: Date? = nil) {
        self.id = id
        self.endpoint = endpoint
        self.requestCount = requestCount
        self.averageResponseTime = averageResponseTime
        self.errorCount = errorCount
        self.lastAccessed = lastAccessed
    }
}

// MARK: - Core Log Entries

public enum WebsiteLogLevel: String, Codable, Sendable {
    case debug = "debug"
    case info = "info"
    case notice = "notice"
    case warn = "warn"
    case error = "error"
    case crit = "crit"
    case alert = "alert"
    case emerg = "emerg"
}

public struct AccessLogEntry: Codable, Sendable, Identifiable {
    public let id: UUID
    public var timestamp: Date
    public var ip: String
    public var method: String
    public var url: String
    public var statusCode: Int
    public var responseSize: Int
    public var userAgent: String
    public var referrer: String?
    public var responseTime: Double?

    public init(id: UUID = UUID(), timestamp: Date, ip: String, method: String, url: String, statusCode: Int, responseSize: Int, userAgent: String, referrer: String? = nil, responseTime: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.ip = ip
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.responseSize = responseSize
        self.userAgent = userAgent
        self.referrer = referrer
        self.responseTime = responseTime
    }
}

public struct ErrorLogEntry: Codable, Sendable, Identifiable {
    public let id: UUID
    public var timestamp: Date
    public var level: WebsiteLogLevel
    public var message: String
    public var file: String?
    public var line: Int?
    public var context: String?

    public init(id: UUID = UUID(), timestamp: Date, level: WebsiteLogLevel, message: String, file: String? = nil, line: Int? = nil, context: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.file = file
        self.line = line
        self.context = context
    }
}

public struct LogFilters: Codable, Sendable {
    public var statusCodes: [Int]?
    public var ipAddresses: [String]?
    public var startDate: Date?
    public var endDate: Date?
    public var logLevels: [WebsiteLogLevel]?
    public var keyword: String?
    public var methods: [String]?
    public var minResponseTime: Double?
    public var maxResponseTime: Double?

    public init(statusCodes: [Int]? = nil, ipAddresses: [String]? = nil, startDate: Date? = nil, endDate: Date? = nil, logLevels: [WebsiteLogLevel]? = nil, keyword: String? = nil, methods: [String]? = nil, minResponseTime: Double? = nil, maxResponseTime: Double? = nil) {
        self.statusCodes = statusCodes
        self.ipAddresses = ipAddresses
        self.startDate = startDate
        self.endDate = endDate
        self.logLevels = logLevels
        self.keyword = keyword
        self.methods = methods
        self.minResponseTime = minResponseTime
        self.maxResponseTime = maxResponseTime
    }
}

// MARK: - Core Website Error

public enum CoreWebsiteError: LocalizedError {
    case notImplemented
    case operationFailed(String)
    case sshConnectionFailed
    case invalidConfiguration
    case websiteNotFound
    case sslOperationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This functionality is not yet implemented"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        case .sshConnectionFailed:
            return "SSH connection failed"
        case .invalidConfiguration:
            return "Invalid website configuration"
        case .websiteNotFound:
            return "Website not found"
        case .sslOperationFailed(let reason):
            return "SSL operation failed: \(reason)"
        }
    }
}
