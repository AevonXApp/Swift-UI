//
//  AXLaunchModels.swift
//  AevonXCoreBridge
//
//  Codable models matching Go AXLaunch JSON responses.
//

import Foundation

// MARK: - Project Detection

public struct AXProjectInfo: Codable, Sendable {
    public let type: String
    public let confidence: Double
    public let name: String
    public let version: String?
    public let phpVersion: String?
    public let nodeVersion: String?
    public let pythonVersion: String?
    public let goVersion: String?
    public let hasDocker: Bool
    public let hasDatabase: Bool
    public let requiresNode: Bool
    public let requiresRedis: Bool
    public let ignoreDefaults: [String]
    public let envSamplePath: String?
    public let databaseType: String?
    public let warnings: [String]

    private enum CodingKeys: String, CodingKey {
        case type, confidence, name, version
        case phpVersion = "php_version"
        case nodeVersion = "node_version"
        case pythonVersion = "python_version"
        case goVersion = "go_version"
        case hasDocker = "has_docker"
        case hasDatabase = "has_database"
        case requiresNode = "requires_node"
        case requiresRedis = "requires_redis"
        case ignoreDefaults = "ignore_defaults"
        case envSamplePath = "env_sample_path"
        case databaseType = "database_type"
        case warnings
    }
}

// MARK: - Launch Configuration

public struct AXLaunchConfig: Codable, Sendable {
    public var localPath: String
    public var remotePath: String
    public var framework: String
    public var domainName: String?
    public var createDomain: Bool
    public var useSSL: Bool
    public var forceHTTPS: Bool
    public var webServer: String?
    public var dbConfig: AXDatabaseConfig
    public var envValues: [String: String]?
    public var postSteps: AXPostStepConfig
    public var useDocker: Bool
    public var transferMode: String
    public var saveConfig: Bool

    private enum CodingKeys: String, CodingKey {
        case localPath = "local_path"
        case remotePath = "remote_path"
        case framework
        case domainName = "domain_name"
        case createDomain = "create_domain"
        case useSSL = "use_ssl"
        case forceHTTPS = "force_https"
        case webServer = "web_server"
        case dbConfig = "db_config"
        case envValues = "env_values"
        case postSteps = "post_steps"
        case useDocker = "use_docker"
        case transferMode = "transfer_mode"
        case saveConfig = "save_config"
    }

    public init(
        localPath: String, remotePath: String, framework: String,
        domainName: String? = nil, createDomain: Bool = false,
        useSSL: Bool = true, forceHTTPS: Bool = true,
        webServer: String? = nil, dbConfig: AXDatabaseConfig = .none,
        envValues: [String: String]? = nil, postSteps: AXPostStepConfig = .init(),
        useDocker: Bool = false, transferMode: String = "auto",
        saveConfig: Bool = false
    ) {
        self.localPath = localPath
        self.remotePath = remotePath
        self.framework = framework
        self.domainName = domainName
        self.createDomain = createDomain
        self.useSSL = useSSL
        self.forceHTTPS = forceHTTPS
        self.webServer = webServer
        self.dbConfig = dbConfig
        self.envValues = envValues
        self.postSteps = postSteps
        self.useDocker = useDocker
        self.transferMode = transferMode
        self.saveConfig = saveConfig
    }
}

// MARK: - Database

public struct AXDatabaseConfig: Codable, Sendable {
    public var mode: String
    public var engine: String
    public var host: String?
    public var port: Int?
    public var dbName: String
    public var dbUsername: String
    public var dbPassword: String
    public var autoGenCreds: Bool
    public var createIfNotExists: Bool?

    private enum CodingKeys: String, CodingKey {
        case mode, engine, host, port
        case dbName = "db_name"
        case dbUsername = "db_username"
        case dbPassword = "db_password"
        case autoGenCreds = "auto_gen_creds"
        case createIfNotExists = "create_if_not_exists"
    }

    public static let none = AXDatabaseConfig(
        mode: "none", engine: "", dbName: "", dbUsername: "", dbPassword: "",
        autoGenCreds: false
    )

    public init(
        mode: String = "none", engine: String = "", host: String? = nil,
        port: Int? = nil, dbName: String = "", dbUsername: String = "",
        dbPassword: String = "", autoGenCreds: Bool = false,
        createIfNotExists: Bool? = nil
    ) {
        self.mode = mode
        self.engine = engine
        self.host = host
        self.port = port
        self.dbName = dbName
        self.dbUsername = dbUsername
        self.dbPassword = dbPassword
        self.autoGenCreds = autoGenCreds
        self.createIfNotExists = createIfNotExists
    }
}

public struct AXDBTestResult: Codable, Sendable {
    public let success: Bool
    public let error: String?
}

// MARK: - Post Steps

public struct AXPostStepConfig: Codable, Sendable {
    public var runMigrations: Bool
    public var runSeeders: Bool
    public var runBuild: Bool
    public var clearCaches: Bool
    public var restartService: Bool
    public var installDeps: Bool

    private enum CodingKeys: String, CodingKey {
        case runMigrations = "run_migrations"
        case runSeeders = "run_seeders"
        case runBuild = "run_build"
        case clearCaches = "clear_caches"
        case restartService = "restart_service"
        case installDeps = "install_deps"
    }

    public init(
        runMigrations: Bool = true, runSeeders: Bool = false,
        runBuild: Bool = true, clearCaches: Bool = true,
        restartService: Bool = true, installDeps: Bool = true
    ) {
        self.runMigrations = runMigrations
        self.runSeeders = runSeeders
        self.runBuild = runBuild
        self.clearCaches = clearCaches
        self.restartService = restartService
        self.installDeps = installDeps
    }
}

// MARK: - Progress

public struct AXLaunchProgress: Codable, Sendable {
    public let launchID: String
    public let stepName: String
    public let stepIndex: Int
    public let totalSteps: Int
    public let percent: Double
    public let log: String
    public let logLevel: String
    public let status: String
    public let bytesSent: Int64
    public let totalBytes: Int64
    public let currentFile: String?
    public let filesCount: Int
    public let totalFiles: Int

    private enum CodingKeys: String, CodingKey {
        case launchID = "launch_id"
        case stepName = "step_name"
        case stepIndex = "step_index"
        case totalSteps = "total_steps"
        case percent, log
        case logLevel = "log_level"
        case status
        case bytesSent = "bytes_sent"
        case totalBytes = "total_bytes"
        case currentFile = "current_file"
        case filesCount = "files_count"
        case totalFiles = "total_files"
    }

    public static let idle = AXLaunchProgress(
        launchID: "", stepName: "", stepIndex: 0, totalSteps: 0,
        percent: 0, log: "", logLevel: "info", status: "idle",
        bytesSent: 0, totalBytes: 0, currentFile: nil, filesCount: 0, totalFiles: 0
    )
}

// MARK: - Start Response

public struct AXLaunchStartResponse: Codable, Sendable {
    public let launchID: String
    public let status: String

    private enum CodingKeys: String, CodingKey {
        case launchID = "launch_id"
        case status
    }
}

// MARK: - Logs

public struct AXLaunchLogLine: Codable, Sendable {
    public let index: Int
    public let time: String
    public let level: String
    public let message: String
}

public struct AXLaunchLogsResult: Codable, Sendable {
    public let lines: [AXLaunchLogLine]
    public let total: Int
}

// MARK: - Diff

public struct AXLaunchDiff: Codable, Sendable {
    public let changed: Int
    public let added: Int
    public let deleted: Int
    public let sizeDelta: String
    public let transferSize: String
    public let hasNewMigrations: Bool
    public let hasSeederChanges: Bool

    private enum CodingKeys: String, CodingKey {
        case changed, added, deleted
        case sizeDelta = "size_delta"
        case transferSize = "transfer_size"
        case hasNewMigrations = "has_new_migrations"
        case hasSeederChanges = "has_seeder_changes"
    }
}

// MARK: - AVX Check

public struct AXAVXCheckResult: Codable, Sendable {
    public let exists: Bool
    public let framework: String?
    public let lastLaunch: String?

    private enum CodingKeys: String, CodingKey {
        case exists, framework
        case lastLaunch = "last_launch"
    }
}

// MARK: - Channel Info

public struct AXLaunchChannelInfo: Codable, Sendable {
    public let launchID: String
    public let serverID: String
    public let phase: String
    public let startedAt: String
    public let sftpChannels: Int

    private enum CodingKeys: String, CodingKey {
        case launchID = "launch_id"
        case serverID = "server_id"
        case phase
        case startedAt = "started_at"
        case sftpChannels = "sftp_channels"
    }
}

// MARK: - History

public struct AXLaunchHistoryEntry: Codable, Sendable, Identifiable {
    public let id: String
    public let type: String
    public let at: String
    public let files: Int?
    public let changed: Int?
    public let added: Int?
    public let deleted: Int?
    public let status: String
    public let durationS: Int

    private enum CodingKeys: String, CodingKey {
        case id, type, at, files, changed, added, deleted, status
        case durationS = "duration_s"
    }
}
