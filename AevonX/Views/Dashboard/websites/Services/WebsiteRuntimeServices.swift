//
//  WebsiteRuntimeServices.swift
//  AevonX
//
//  Service stubs for Node.js and Monitoring services.
//  These replace the AevonXCore services and use SSHBridge (Go Core) for SSH.
//

import Foundation
import AevonXCoreBridge

// MARK: - NodeJS Config Service

public actor NodeJSConfigService {
    public static let shared = NodeJSConfigService()
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false
    public init() {}

    private func detectPathsIfNeeded(serverId: String) async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }

    public func readPackageJSON(appPath: String, serverId: String) async throws -> PackageJSON? {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "cat \(appPath)/package.json 2>/dev/null")
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { return nil }
        return try JSONDecoder().decode(PackageJSON.self, from: data)
    }

    public func detectEntryFile(appPath: String, serverId: String) async throws -> String {
        if let pkg = try await readPackageJSON(appPath: appPath, serverId: serverId) {
            return pkg.entryFile
        }
        let commonFiles = ["server.js", "app.js", "index.js", "main.js", "src/index.js", "dist/index.js"]
        for file in commonFiles {
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: "test -f \(appPath)/\(file) && echo 'found'")
            if result.contains("found") { return file }
        }
        return "index.js"
    }

    public func readEnvFile(appPath: String, serverId: String) async throws -> [EnvironmentVariable] {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "cat \(appPath)/.env 2>/dev/null")
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let secretKeys = ["SECRET", "KEY", "PASSWORD", "TOKEN", "API_KEY", "PRIVATE", "CREDENTIALS"]
        return trimmed.split(separator: "\n").compactMap { line in
            let l = String(line).trimmingCharacters(in: .whitespaces)
            guard !l.isEmpty, !l.hasPrefix("#") else { return nil }
            let parts = l.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            var value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            let isSecret = secretKeys.contains { key.uppercased().contains($0) }
            return EnvironmentVariable(key: key, value: value, isSecret: isSecret)
        }
    }

    public func writeEnvFile(variables: [EnvironmentVariable], appPath: String, serverId: String) async throws {
        let content = variables.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
        let escaped = content.replacingOccurrences(of: "'", with: "'\\''")
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "printf '%s\\n' '\(escaped)' > \(appPath)/.env")
        _ = output
    }

    public func npmInstall(appPath: String, serverId: String) async throws -> String {
        await SSHBridge.shared.executeAsync(serverID: serverId, command: "cd \(appPath) && npm install 2>&1")
    }

    public func npmRun(script: String, appPath: String, serverId: String) async throws -> String {
        await SSHBridge.shared.executeAsync(serverID: serverId, command: "cd \(appPath) && npm run \(script) 2>&1")
    }

    // MARK: - Nginx Reverse Proxy

    public func generateNginxConfig(domain: String, port: Int, sslEnabled: Bool = false, sslBasePath: String = "/etc/letsencrypt/live") -> String {
        var config = """
        server {
            listen 80;
            server_name \(domain);
        
            location / {
                proxy_pass http://127.0.0.1:\(port);
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection 'upgrade';
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_cache_bypass $http_upgrade;
                proxy_read_timeout 86400;
            }
        }
        """
        if sslEnabled {
            config += """
            
            server {
                listen 443 ssl;
                server_name \(domain);
            
                ssl_certificate \(sslBasePath)/\(domain)/fullchain.pem;
                ssl_certificate_key \(sslBasePath)/\(domain)/privkey.pem;
            
                location / {
                    proxy_pass http://127.0.0.1:\(port);
                    proxy_http_version 1.1;
                    proxy_set_header Upgrade $http_upgrade;
                    proxy_set_header Connection 'upgrade';
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Proto $scheme;
                    proxy_cache_bypass $http_upgrade;
                    proxy_read_timeout 86400;
                }
            }
            """
        }
        return config
    }

    public func applyNginxReverseProxy(domain: String, port: Int, sslEnabled: Bool, serverId: String) async throws {
        await detectPathsIfNeeded(serverId: serverId)
        let config = generateNginxConfig(domain: domain, port: port, sslEnabled: sslEnabled)
        let escaped = config.replacingOccurrences(of: "'", with: "'\\''")
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "printf '%s\\n' '\(escaped)' | sudo tee \(serverPaths.nginxSitesAvailable)/\(domain) > /dev/null")
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo ln -sf \(serverPaths.nginxSitesAvailable)/\(domain) \(serverPaths.nginxSitesEnabled)/\(domain)")
        let testOutput = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo nginx -t 2>&1")
        guard testOutput.contains("successful") || testOutput.contains("ok") else {
            throw NSError(domain: "NodeJSConfig", code: 3, userInfo: [NSLocalizedDescriptionKey: "Nginx config test failed: \(testOutput)"])
        }
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo systemctl reload nginx")
    }
}

// MARK: - Website Analytics Service (stub)

public actor WebsiteAnalyticsService {
    public static let shared = WebsiteAnalyticsService()
    public init() {}

    public struct HealthResult {
        public let isReachable: Bool
        public let responseTime: Double
        public let statusCode: Int
        public let sslValid: Bool
        public let issues: [HealthIssue]
    }

    public struct HealthIssue {
        public let severity: HealthIssueSeverity
        public let title: String
        public let description: String
        public let recommendation: String
    }

    public enum HealthIssueSeverity: String {
        case info, warning, critical
    }

    public func checkWebsiteHealth(websiteId: String, serverId: String) async throws -> HealthResult {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "curl -sS -o /dev/null -w '%{http_code} %{time_total}' --max-time 15 https://\(websiteId) 2>/dev/null || curl -sS -o /dev/null -w '%{http_code} %{time_total}' --max-time 15 http://\(websiteId) 2>/dev/null")
        let parts = output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        let status = Int(parts.first ?? "") ?? 0
        let time = Double(parts.last ?? "") ?? 0
        return HealthResult(isReachable: (200...399).contains(status), responseTime: time, statusCode: status, sslValid: true, issues: [])
    }
}

// MARK: - Website SSL Service (stub)

public actor WebsiteSSLService {
    public static let shared = WebsiteSSLService()
    public init() {}

    public func renewSSL(websiteId: String, serverId: String) async throws {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo certbot renew --cert-name \(websiteId) --force-renewal 2>&1")
        if output.contains("FAILED") || output.contains("error") {
            throw NSError(domain: "SSL", code: 1, userInfo: [NSLocalizedDescriptionKey: "SSL renewal failed: \(output)"])
        }
    }
}

// MARK: - NodeJS Version Service

public actor NodeJSVersionService {
    public static let shared = NodeJSVersionService()
    public init() {}

    private let nvmPrefix = """
    export NVM_DIR="$HOME/.nvm"; \
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" 2>/dev/null; \
    export PATH="$HOME/.nvm/versions/node/$(ls -1 $HOME/.nvm/versions/node/ 2>/dev/null | tail -1)/bin:$PATH" 2>/dev/null;
    """

    public func getInstalledVersion(serverId: String) async -> String? {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) node -v 2>/dev/null")
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Alias used by NodeJSConfigTab
    public func detectCurrentVersion(serverId: String) async throws -> String? {
        return await getInstalledVersion(serverId: serverId)
    }

    public func getNPMVersion(serverId: String) async -> String? {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) npm -v 2>/dev/null")
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Alias used by NodeJSConfigTab
    public func detectNPMVersion(serverId: String) async throws -> String? {
        return await getNPMVersion(serverId: serverId)
    }

    public func getInstalledVersions(serverId: String) async throws -> [String] {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) nvm ls --no-colors 2>/dev/null | grep -oE 'v[0-9]+\\.[0-9]+\\.[0-9]+'")
        return output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "") }
            .filter { !$0.isEmpty }
    }

    public func isNvmInstalled(serverId: String) async throws -> Bool {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "[ -s \"$HOME/.nvm/nvm.sh\" ] && echo 'yes' || echo 'no'")
        return output.trimmingCharacters(in: .whitespacesAndNewlines) == "yes"
    }

    public func installNvm(serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash 2>&1")
    }

    public func installVersion(_ version: String, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) nvm install \(version) 2>&1")
    }

    public func switchVersion(_ version: String, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) nvm use \(version) && nvm alias default \(version) 2>&1")
    }

    public func getAvailableVersions(serverId: String) async throws -> [String] {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) nvm ls-remote --lts --no-colors 2>/dev/null | grep -oE 'v[0-9]+\\.[0-9]+\\.[0-9]+' | tail -20")
        return output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "") }
            .filter { !$0.isEmpty }
    }
}

// MARK: - NodeJS Process Service (PM2)

public actor NodeJSProcessService {
    public static let shared = NodeJSProcessService()
    public init() {}

    private let nvmPrefix = """
    export NVM_DIR="$HOME/.nvm"; \
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" 2>/dev/null; \
    export PATH="$HOME/.nvm/versions/node/$(ls -1 $HOME/.nvm/versions/node/ 2>/dev/null | tail -1)/bin:$PATH" 2>/dev/null;
    """

    public func isPM2Installed(serverId: String) async throws -> Bool {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) which pm2 2>/dev/null")
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func installPM2(serverId: String) async throws {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) npm install -g pm2 2>&1")
        if output.contains("ERR!") {
            throw NSError(domain: "PM2", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to install PM2: \(output)"])
        }
    }

    public func listProcesses(serverId: String) async throws -> [PM2Process] {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 jlist 2>/dev/null")
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.first == "[", let data = trimmed.data(using: .utf8) else { return [] }
        let raw = (try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]) ?? []
        return raw.compactMap { item -> PM2Process? in
            guard let pmId = item["pm_id"] as? Int, let name = item["name"] as? String,
                  let env = item["pm2_env"] as? [String: Any], let monit = item["monit"] as? [String: Any] else { return nil }
            return PM2Process(id: pmId, name: name, status: PM2Process.PM2Status(rawValue: env["status"] as? String ?? "unknown") ?? .unknown, cpu: monit["cpu"] as? Double ?? 0, memory: monit["memory"] as? Int64 ?? 0, uptime: env["pm_uptime"] as? Int64, restarts: env["restart_time"] as? Int ?? 0, pid: env["pid"] as? Int)
        }
    }

    public func startProcess(name: String, entryFile: String? = nil, cwd: String? = nil, serverId: String) async throws -> String {
        var cmd = "\(nvmPrefix) pm2 start"
        if let e = entryFile { cmd += " \(e) --name \"\(name)\"" } else { cmd += " \(name)" }
        if let c = cwd { cmd += " --cwd \"\(c)\"" }
        cmd += " 2>&1"
        return await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
    }

    public func stopProcess(name: String, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 stop \"\(name)\" 2>&1")
    }

    public func restartProcess(name: String, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 restart \"\(name)\" 2>&1")
    }

    public func deleteProcess(name: String, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 delete \"\(name)\" 2>&1")
    }

    public func getProcessLogs(name: String, lines: Int = 50, serverId: String) async throws -> String {
        await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 logs \"\(name)\" --lines \(lines) --nostream 2>&1")
    }

    public func saveProcessList(serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 save 2>&1")
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 startup 2>&1 | tail -1 | bash 2>/dev/null")
    }

    public func reloadProcess(name: String, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 reload \"\(name)\" 2>&1")
    }

    public func scaleProcess(name: String, instances: Int, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 scale \"\(name)\" \(instances) 2>&1")
    }

    public func startCluster(name: String, entryFile: String, instances: Int, cwd: String, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "\(nvmPrefix) pm2 start \(entryFile) --name \"\(name)\" -i \(instances) --cwd \"\(cwd)\" 2>&1")
    }

    public func generateEcosystemConfig(name: String, script: String, cwd: String, serverId: String) async throws {
        let config = """
        module.exports = {
          apps: [{
            name: '\(name)',
            script: '\(script)',
            cwd: '\(cwd)',
            instances: 'max',
            exec_mode: 'cluster',
            env: { NODE_ENV: 'production' }
          }]
        };
        """
        let escaped = config.replacingOccurrences(of: "'", with: "'\\''")
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "echo '\(escaped)' > \(cwd)/ecosystem.config.js")
    }
}

// MARK: - Site Monitoring Service

public actor SiteMonitoringService {
    public static let shared = SiteMonitoringService()
    public init() {}

    public func measureResponseTime(domain: String, serverId: String) async throws -> Double {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "curl -sS -o /dev/null -w '%{time_total}' --max-time 15 https://\(domain) 2>/dev/null || curl -sS -o /dev/null -w '%{time_total}' --max-time 15 http://\(domain) 2>/dev/null")
        return Double(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    public func analyzeDiskUsage(docRoot: String, serverId: String) async throws -> [CoreDiskEntry] {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "du -sh \(docRoot)/* 2>/dev/null | sort -rh | head -20")
        return output.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .compactMap { line -> CoreDiskEntry? in
                let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: "\t")
                guard parts.count >= 2 else { return nil }
                return CoreDiskEntry(size: parts[0], path: parts[1])
            }
    }

    public func findLargeFiles(docRoot: String, serverId: String) async throws -> [String] {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "find \(docRoot) -type f -size +10M -exec ls -lh {} \\; 2>/dev/null | awk '{print $5\" \"$NF}' | head -20")
        return output.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

public struct CoreDiskEntry: Sendable {
    public let size: String
    public let path: String
    nonisolated public init(size: String, path: String) {
        self.size = size; self.path = path
    }
}

// MARK: - Site Quick Actions Service

public actor SiteQuickActionsService {
    public static let shared = SiteQuickActionsService()
    public init() {}

    public func restartPHPFPM(version: String, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo systemctl restart php\(version)-fpm")
    }

    public func restartPM2(serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "pm2 restart all")
    }

    public func restartNginx(serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo systemctl restart nginx")
    }

    public func reloadNginx(serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo systemctl reload nginx")
    }

    public func fixOwnership(docRoot: String, serverId: String) async throws {
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo chown -R www-data:www-data \(docRoot)")
    }

    public func clearAppCache(docRoot: String, serverId: String) async throws -> String {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "cd \(docRoot) && php artisan cache:clear 2>/dev/null && php artisan config:clear 2>/dev/null && echo 'Laravel cache cleared' || wp cache flush 2>/dev/null && echo 'WP cache flushed' || echo 'No framework cache found'")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func getDiskUsage(docRoot: String, serverId: String) async throws -> String {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "du -sh \(docRoot) 2>/dev/null | awk '{print $1}'")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func testNginxConfig(serverId: String) async throws -> (passed: Bool, output: String) {
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo nginx -t 2>&1")
        let passed = output.contains("syntax is ok") || output.contains("test is successful")
        return (passed: passed, output: output)
    }
}

// MARK: - Website Lifecycle Service

public actor WebsiteLifecycleService {
    public static let shared = WebsiteLifecycleService()
    private var serverPaths: ServerPaths = .defaults
    private var pathsDetected = false
    public init() {}

    private func detectPathsIfNeeded(serverId: String) async {
        guard !pathsDetected else { return }
        let cmd = PathResolverBridge.shared.detectCmd()
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        serverPaths = PathResolverBridge.shared.parse(output: output)
        pathsDetected = true
    }

    public func deleteWebsite(websiteId: String, serverId: String) async throws {
        await detectPathsIfNeeded(serverId: serverId)
        CoreLogger.shared.info("Deleting website: \(websiteId)", module: "WebsiteLifecycleService")
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo rm -f \(serverPaths.nginxSitesEnabled)/\(websiteId)")
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo rm -f \(serverPaths.nginxSitesAvailable)/\(websiteId)")
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo nginx -t && sudo systemctl reload nginx")
        CoreLogger.shared.info("Website deleted successfully", module: "WebsiteLifecycleService")
    }

    public func startWebsite(websiteId: String, serverId: String) async throws {
        await detectPathsIfNeeded(serverId: serverId)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo ln -sf \(serverPaths.nginxSitesAvailable)/\(websiteId) \(serverPaths.nginxSitesEnabled)/\(websiteId)")
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo nginx -t && sudo systemctl reload nginx")
    }

    public func stopWebsite(websiteId: String, serverId: String) async throws {
        await detectPathsIfNeeded(serverId: serverId)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo rm -f \(serverPaths.nginxSitesEnabled)/\(websiteId)")
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: "sudo nginx -t && sudo systemctl reload nginx")
    }
}

// MARK: - Database Management Service (stub)


public struct CoreDatabaseInfo: Sendable {
    public let id: String
    public let name: String
    public let size: Double // MB
    public let tables: Int

    nonisolated public init(id: String = UUID().uuidString, name: String, size: Double, tables: Int) {
        self.id = id; self.name = name; self.size = size; self.tables = tables
    }
}

public actor DatabaseManagementService {
    public static let shared = DatabaseManagementService()
    public init() {}

    public func listDatabases(type: String, serverId: String) async throws -> [CoreDatabaseInfo] {
        let typeLower = type.lowercased()
        let systemMySQL = ["information_schema", "performance_schema", "mysql", "sys"]
        let systemPG = ["postgres"]
        
        if typeLower == "mysql" || typeLower == "mariadb" {
            // Use schemata LEFT JOIN tables so empty databases (0 tables) also appear
            let cmd = "mysql -NBe \"SELECT s.schema_name, COALESCE(ROUND(SUM(t.data_length + t.index_length)/1024/1024, 2), 0), COUNT(t.table_name) FROM information_schema.schemata s LEFT JOIN information_schema.tables t ON s.schema_name = t.table_schema GROUP BY s.schema_name\" 2>/dev/null"
            print("[DatabaseManagementService] MySQL cmd: \(cmd)")
            let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            print("[DatabaseManagementService] MySQL raw output: '\(output)'")
            return output.components(separatedBy: "\n").filter { !$0.isEmpty }.compactMap { line in
                let parts = line.split(separator: "\t")
                guard parts.count >= 3 else { return nil }
                let name = String(parts[0])
                guard !systemMySQL.contains(name) else { return nil }
                return CoreDatabaseInfo(name: name, size: Double(parts[1]) ?? 0, tables: Int(parts[2]) ?? 0)
            }
        } else if typeLower == "postgresql" {
            // Filter system databases in SQL for efficiency
            let cmd = "sudo -u postgres psql -tAc \"SELECT datname, pg_database_size(datname)/1024/1024 FROM pg_database WHERE datistemplate = false AND datname != 'postgres'\" 2>/dev/null"
            print("[DatabaseManagementService] PG cmd: \(cmd)")
            let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            print("[DatabaseManagementService] PG raw output: '\(output)'")
            return output.components(separatedBy: "\n").filter { !$0.isEmpty }.compactMap { line in
                let parts = line.split(separator: "|")
                guard parts.count >= 2 else { return nil }
                let name = String(parts[0]).trimmingCharacters(in: .whitespaces)
                guard !systemPG.contains(name) else { return nil }
                return CoreDatabaseInfo(name: name, size: Double(parts[1]) ?? 0, tables: 0)
            }
        } else {
            return []
        }
    }

    public func createDatabase(name: String, type: String, characterSet: String? = nil, collation: String? = nil, serverId: String) async throws {
        let typeLower = type.lowercased()
        var cmd: String
        if typeLower == "mysql" || typeLower == "mariadb" {
            cmd = "mysql -e \"CREATE DATABASE \(name)"
            if let cs = characterSet { cmd += " CHARACTER SET \(cs)" }
            if let co = collation { cmd += " COLLATE \(co)" }
            cmd += "\" 2>&1"
        } else if typeLower == "postgresql" {
            cmd = "sudo -u postgres createdb"
            if let cs = characterSet { cmd += " -E \(cs)" }
            if let co = collation { cmd += " --lc-collate=\(co)" }
            cmd += " \(name) 2>&1"
        } else {
            throw NSError(domain: "DatabaseManagementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported database type: \(type)"])
        }
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        if output.lowercased().contains("error") {
            throw NSError(domain: "DatabaseManagementService", code: -1, userInfo: [NSLocalizedDescriptionKey: output])
        }
    }

    public func deleteDatabase(name: String, type: String, serverId: String) async throws {
        let typeLower = type.lowercased()
        var cmd: String
        if typeLower == "mysql" || typeLower == "mariadb" {
            cmd = "mysql -e \"DROP DATABASE IF EXISTS \(name)\" 2>&1"
        } else if typeLower == "postgresql" {
            cmd = "sudo -u postgres dropdb --if-exists \(name) 2>&1"
        } else {
            throw NSError(domain: "DatabaseManagementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported database type: \(type)"])
        }
        let output = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        if output.lowercased().contains("error") {
            throw NSError(domain: "DatabaseManagementService", code: -1, userInfo: [NSLocalizedDescriptionKey: output])
        }
    }
}
