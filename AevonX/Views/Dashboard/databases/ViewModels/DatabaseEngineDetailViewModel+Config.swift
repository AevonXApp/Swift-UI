//
//  DatabaseEngineDetailViewModel+Config.swift
//  AevonX
//
//  Configuration, version management, and optimization for engine detail VM.
//

import Foundation
import AevonXCoreBridge

// MARK: - Configuration & Version Management

extension DatabaseEngineDetailViewModel {

    /// Load configuration
    public func loadConfiguration() async {
        guard let serverId = currentServerId else { return }

        do {
            configuration = try await DatabaseEngineService.shared.getConfiguration(type: databaseType, serverId: serverId)

            if databaseType == .redis {
                loadRedisPassword()
            }
        } catch {
            errorMessage = "\(L10n.Engine.loadConfigFailed): \(error.localizedDescription)"
        }
    }

    /// Load Redis password from configuration
    public func loadRedisPassword() {
        guard databaseType == .redis, let config = configuration else { return }
        if let pass = config.settings["requirepass"] {
            redisPassword = pass
        } else {
            let pattern = #"^requirepass\s+(.+)$"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) {
                let nsString = config.rawContent as NSString
                let results = regex.matches(in: config.rawContent, options: [], range: NSRange(location: 0, length: nsString.length))
                if let match = results.first {
                    redisPassword = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
    }

    /// Update Redis password
    public func updateRedisPassword(newPassword: String) async {
        guard let serverId = currentServerId, databaseType == .redis else { return }

        isPerformingServiceAction = true
        operationResult = .inProgress(message: "\(L10n.Status.loading)", progress: nil)

        do {
            let currentConfig = try await DatabaseEngineService.shared.getConfiguration(type: databaseType, serverId: serverId)
            var newContent = currentConfig.rawContent

            let pattern = #"^requirepass\s+(.+)$"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) {
                let nsString = newContent as NSString
                let results = regex.matches(in: newContent, options: [], range: NSRange(location: 0, length: nsString.length))

                if let match = results.first {
                    let range = match.range
                    newContent = (newContent as NSString).replacingCharacters(in: range, with: "requirepass \(newPassword)")
                } else {
                    newContent += "\nrequirepass \(newPassword)"
                }
            } else {
                newContent += "\nrequirepass \(newPassword)"
            }

            let updatedConfig = DatabaseConfiguration(
                engineType: .redis,
                settings: currentConfig.settings,
                rawContent: newContent
            )

            try await DatabaseEngineService.shared.updateConfiguration(updatedConfig, type: databaseType, serverId: serverId)
            redisPassword = newPassword
            await loadConfiguration()

            operationResult = .success(message: L10n.Success.passwordSaved)
            activeAlert = .operationSuccess(message: L10n.Success.passwordSaved)

        } catch {
            operationResult = .failure(message: "\(L10n.Engine.updatePasswordFailed): \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "\(L10n.Engine.updateRedisPasswordFailed): \(error.localizedDescription)")
        }

        isPerformingServiceAction = false
    }

    /// Save configuration from editor
    public func saveConfiguration() async {
        guard let serverId = currentServerId, let currentConfig = configuration else { return }

        isPerformingServiceAction = true
        operationResult = .inProgress(message: "\(L10n.Status.loading)", progress: nil)

        do {
            let newConfig = DatabaseConfiguration(
                engineType: databaseType,
                settings: currentConfig.settings,
                rawContent: configEditContent
            )

            try await DatabaseEngineService.shared.updateConfiguration(newConfig, type: databaseType, serverId: serverId)
            await loadConfiguration()

            operationResult = .success(message: L10n.Database.actionSuccessful(L10n.Button.saveChanges))
            activeAlert = .operationSuccess(message: L10n.Database.actionSuccessful(L10n.Button.saveChanges))
            showConfigEditor = false

        } catch {
            operationResult = .failure(message: "\(L10n.Engine.saveFailed): \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "\(L10n.Engine.saveConfigFailed): \(error.localizedDescription)")
        }

        isPerformingServiceAction = false
    }

    /// Save configuration content to the server
    public func saveConfiguration(content: String) async {
        await performOperation(
            progressMessage: "\(L10n.Status.loading)",
            successMessage: L10n.Database.actionSuccessful(L10n.Button.saveChanges),
            successAlert: L10n.Database.actionSuccessful(L10n.Button.saveChanges),
            failurePrefix: L10n.Engine.saveFailed,
            reloadAfterSuccess: false
        ) {
            let config = DatabaseConfiguration(engineType: databaseType, settings: [:], rawContent: content)
            try await DatabaseEngineService.shared.updateConfiguration(config, type: databaseType, serverId: currentServerId!)
            await loadConfiguration()
        }
    }

    // MARK: - Version Management

    /// Fetch available versions from Core
    public func fetchAvailableVersions() async {
        guard let serverId = currentServerId else { return }

        isFetchingVersions = true
        errorMessage = nil

        do {
            let versionStrings = try await DatabaseEngineService.shared.getAvailableVersions(type: databaseType, serverId: serverId)
            let normalized = versionStrings
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { versionStr in
                DatabaseVersion(
                    version: versionStr.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            availableVersions = normalized
        } catch {
            errorMessage = "\(L10n.Engine.fetchVersionsFailed): \(error.localizedDescription)"
            availableVersions = []
        }

        isFetchingVersions = false
    }

    /// Install a specific version
    public func installVersion(_ version: DatabaseVersion) async {
        guard let serverId = currentServerId else { return }

        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Installing \(databaseType.displayName) \(version.version)...", progress: 0.0)
        installationProgress = 0.0

        do {
            try await DatabaseEngineService.shared.installDatabase(
                type: databaseType,
                version: version.version,
                serverId: serverId
            )

            operationResult = .success(message: "\(databaseType.displayName) \(version.version) installed successfully!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) \(version.version) has been installed successfully.")

            await loadData()

        } catch {
            operationResult = .failure(message: "\(L10n.Engine.installFailed): \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "\(L10n.Engine.installVersionFailed(databaseType.displayName, version.version)): \(error.localizedDescription)")
        }

        isPerformingServiceAction = false
    }

    /// Update to latest version
    public func updateToLatestVersion() async {
        guard let serverId = currentServerId else { return }

        isPerformingServiceAction = true
        operationResult = .inProgress(message: "Updating \(databaseType.displayName)...", progress: nil)

        do {
            let targetVersion = try await resolveLatestVersion(serverId: serverId)
            try await DatabaseEngineService.shared.installDatabase(
                type: databaseType,
                version: targetVersion,
                serverId: serverId
            )

            operationResult = .success(message: "\(databaseType.displayName) updated to \(targetVersion) successfully!")
            activeAlert = .operationSuccess(message: "\(databaseType.displayName) has been updated to version \(targetVersion).")

            await loadData()

        } catch {
            operationResult = .failure(message: "\(L10n.Engine.updateFailed): \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "\(L10n.Engine.updateTypeFailed(databaseType.displayName)): \(error.localizedDescription)")
        }

        isPerformingServiceAction = false
    }

    // MARK: - Optimization

    /// Analyze performance by refreshing metrics and stats
    public func analyzePerformance() async {
        guard let serverId = currentServerId else { return }

        isAnalyzingPerformance = true
        operationResult = .inProgress(message: "\(L10n.Status.loading)", progress: nil)

        do {
            metrics = try await DatabaseMetricsService.shared.getMetrics(type: databaseType, serverId: serverId)
            performanceStats = try await DatabaseMetricsService.shared.getPerformanceStats(type: databaseType, serverId: serverId)

            updateHealthStatus()
            operationResult = .success(message: L10n.Database.actionSuccessful("Performance analysis"))
            activeAlert = .operationSuccess(message: L10n.Database.actionSuccessful("Performance analysis"))
        } catch {
            operationResult = .failure(message: "\(L10n.Engine.analysisFailed): \(error.localizedDescription)")
            activeAlert = .operationFailure(message: "\(L10n.Engine.analyzePerformanceFailed): \(error.localizedDescription)")
        }

        isAnalyzingPerformance = false
    }

    /// Apply an optimization preset to the configuration
    public func applyOptimizationPreset(_ preset: String) async {
        await performOperation(
            progressMessage: "Applying '\(preset)' preset...",
            successMessage: "'\(preset)' preset applied!",
            successAlert: "The '\(preset)' optimization preset has been applied. Restart the service for changes to take effect.",
            failurePrefix: L10n.Database.actionFailed(L10n.Button.apply),
            reloadAfterSuccess: false
        ) {
            let currentConfig = try await DatabaseEngineService.shared.getConfiguration(type: databaseType, serverId: currentServerId!)
            let presetSettings = optimizationPresetSettings(for: preset)
            var merged = currentConfig.settings
            for (key, value) in presetSettings { merged[key] = value }
            // Apply settings into rawContent so they actually reach the config file
            var updatedContent = currentConfig.rawContent
            for (key, value) in presetSettings {
                let pattern = "^\\s*#?\\s*\(NSRegularExpression.escapedPattern(for: key))\\s*=.*$"
                let replacement = "\(key) = \(value)"
                if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) {
                    let range = NSRange(updatedContent.startIndex..., in: updatedContent)
                    if regex.firstMatch(in: updatedContent, range: range) != nil {
                        updatedContent = regex.stringByReplacingMatches(in: updatedContent, range: range, withTemplate: replacement)
                    } else {
                        updatedContent += "\n\(replacement)"
                    }
                }
            }
            let updated = DatabaseConfiguration(engineType: databaseType, settings: merged, rawContent: updatedContent)
            try await DatabaseEngineService.shared.updateConfiguration(updated, type: databaseType, serverId: currentServerId!)
            await loadConfiguration()
        }
    }

    // MARK: - Preset Helpers

    /// Returns config key-value pairs for a given optimization preset
    func optimizationPresetSettings(for preset: String) -> [String: String] {
        switch preset.lowercased() {
        case "performance", "web application", "data warehouse":
            switch databaseType {
            case .mysql, .mariadb:
                return [
                    "innodb_buffer_pool_size": "1G",
                    "innodb_log_file_size": "256M",
                    "innodb_flush_log_at_trx_commit": "2",
                    "max_connections": "200",
                    "table_open_cache": "4000"
                ]
            case .postgresql:
                return [
                    "shared_buffers": "256MB",
                    "effective_cache_size": "1GB",
                    "work_mem": "16MB",
                    "maintenance_work_mem": "128MB"
                ]
            case .redis:
                return ["maxmemory-policy": "allkeys-lru", "save": "900 1 300 10"]
            default:
                return [:]
            }
        case "memory-efficient", "memory", "development":
            switch databaseType {
            case .mysql, .mariadb:
                return [
                    "innodb_buffer_pool_size": "128M",
                    "innodb_log_file_size": "48M",
                    "max_connections": "50",
                    "table_open_cache": "200"
                ]
            case .postgresql:
                return [
                    "shared_buffers": "64MB",
                    "effective_cache_size": "256MB",
                    "work_mem": "4MB",
                    "max_connections": "50"
                ]
            case .redis:
                return ["maxmemory": "128mb", "maxmemory-policy": "allkeys-lru"]
            default:
                return [:]
            }
        case "security":
            switch databaseType {
            case .mysql, .mariadb:
                return [
                    "local_infile": "OFF",
                    "skip_symbolic_links": "YES",
                    "log_error_verbosity": "3"
                ]
            case .postgresql:
                return [
                    "ssl": "on",
                    "log_connections": "on",
                    "log_disconnections": "on"
                ]
            default:
                return [:]
            }
        default: // balanced
            return [:]
        }
    }
}
