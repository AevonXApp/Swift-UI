//
//  HookCommandDispatcher.swift
//  AevonXCoreBridge
//
//  Dispatches hook commands to the SSH layer.
//  Handles template resolution, security validation, and data parsing.
//

import Foundation

public final class HookCommandDispatcher: Sendable {

    public static let shared = HookCommandDispatcher()
    private let validator = PluginPermissionValidator.shared

    private init() {}

    // MARK: - Command Dispatch

    /// Execute a plugin command and return raw output
    public func dispatch(
        command: HookPluginCommand,
        pluginId: String,
        serverId: String,
        context: [String: String],
        namespace: String? = nil
    ) async throws -> HookCommandResult {
        let start = Date()

        // Smart Auto-Detect: if type is core_cmd but we can resolve a namespace, auto-upgrade to plugin_cmd
        var effectiveType = command.type ?? .coreCmd
        if effectiveType == .coreCmd {
            if namespace != nil || resolveNamespace(from: command.action) != nil {
                effectiveType = .pluginCmd
            }
        }

        // Validate action — Smart Auto-Trust for plugin_cmd, safety check for all
        if effectiveType == .pluginCmd {
            let ns = namespace ?? resolveNamespace(from: command.action)
            guard let resolvedNS = ns else {
                throw PluginDispatchError.actionNotAllowed(command.action, reason: "Missing namespace for plugin_cmd")
            }
            let validation = validator.validatePluginAction(command.action, namespace: resolvedNS)
            guard validation.isAllowed else {
                throw PluginDispatchError.actionNotAllowed(command.action, reason: validation.rejectionReason)
            }
            // Apply rate limiting per namespace to prevent SSH flooding
            try await HookRateLimiter.shared.checkAndRecord(namespace: resolvedNS)
        } else {
            // Core commands — just check action name safety
            let validation = validator.validateActionSafety(command.action)
            guard validation.isAllowed else {
                throw PluginDispatchError.actionNotAllowed(command.action, reason: validation.rejectionReason)
            }
        }

        // Resolve template variables — auto-injects server.id, plugin.namespace, plugin.id
        let resolvedNS = namespace ?? resolveNamespace(from: command.action)
        let resolvedPayload = resolveTemplates(
            in: command.payload,
            context: context,
            serverId: serverId,
            namespace: resolvedNS,
            pluginId: pluginId
        )

        // Map action to SSH command
        let sshCommand = try await buildSSHCommand(action: command.action, payload: resolvedPayload, type: effectiveType, namespace: resolvedNS, serverId: serverId)

        // Execute via SSHService
        let output = try await executeSSH(
            command: sshCommand,
            serverId: serverId,
            type: effectiveType,
            timeout: command.timeout ?? 30
        )

        let duration = Date().timeIntervalSince(start)
        return HookCommandResult(
            pluginId: pluginId,
            action: command.action,
            success: true,
            output: output,
            duration: duration
        )
    }

    // MARK: - Data Fetching (for data_table / chart components)

    /// Fetch and parse data for a data_source definition
    public func fetchData(
        action: String,
        payload: [String: AnyCodable]?,
        format: HookDataFormat,
        rowsPath: String?,
        serverId: String,
        context: [String: String],
        type: HookCommandType? = nil,
        namespace: String? = nil,
        transform: String? = nil,
        keyColumn: String? = nil
    ) async throws -> [[String: String]] {
        // Smart Auto-Detect: if type is core_cmd but we can resolve a namespace, auto-upgrade to plugin_cmd
        var cmdType = type ?? .coreCmd
        if cmdType == .coreCmd {
            if namespace != nil || resolveNamespace(from: action) != nil {
                cmdType = .pluginCmd
            }
        }

        // Validate action — Smart Auto-Trust
        if cmdType == .pluginCmd {
            let ns = namespace ?? resolveNamespace(from: action)
            guard let resolvedNS = ns else {
                throw PluginDispatchError.actionNotAllowed(action, reason: "Missing namespace for plugin_cmd")
            }
            let validation = validator.validatePluginAction(action, namespace: resolvedNS)
            guard validation.isAllowed else {
                throw PluginDispatchError.actionNotAllowed(action, reason: validation.rejectionReason)
            }
            // Apply rate limiting per namespace to prevent SSH flooding
            try await HookRateLimiter.shared.checkAndRecord(namespace: resolvedNS)
        } else {
            // Core commands — just check action name safety
            let validation = validator.validateActionSafety(action)
            guard validation.isAllowed else {
                throw PluginDispatchError.actionNotAllowed(action, reason: validation.rejectionReason)
            }
        }

        // Resolve templates — inject full server + plugin context
        let resolvedNS = namespace ?? resolveNamespace(from: action)
        let resolvedPayload = resolveTemplates(
            in: payload,
            context: context,
            serverId: serverId,
            namespace: resolvedNS,
            pluginId: nil
        )

        // Build and execute SSH command
        let sshCommand = try await buildSSHCommand(action: action, payload: resolvedPayload, type: cmdType, namespace: resolvedNS, serverId: serverId)
        let rawOutput = try await executeSSH(command: sshCommand, serverId: serverId, type: cmdType, timeout: 30)

        // Parse output based on format
        return try parseOutput(rawOutput, format: format, rowsPath: rowsPath, transform: transform, keyColumn: keyColumn)
    }

    // MARK: - Output Parsing

    private func parseOutput(_ output: String, format: HookDataFormat, rowsPath: String?, transform: String? = nil, keyColumn: String? = nil) throws -> [[String: String]] {
        switch format {
        case .json:
            return try parseJSON(output, rowsPath: rowsPath, transform: transform, keyColumn: keyColumn)
        case .csv:
            return parseDelimited(output, delimiter: ",")
        case .tsv:
            return parseDelimited(output, delimiter: "\t")
        case .lines:
            return parseLines(output)
        case .keyValue:
            return [parseKeyValue(output)]
        case .nginx:
            return parseNginxLog(output)
        case .apache:
            return parseApacheLog(output)
        case .number:
            return [["value": output.trimmingCharacters(in: .whitespacesAndNewlines)]]
        case .raw:
            return [["value": output]]
        }
    }

    /// Safely convert any JSON value to a display string, handling null/NSNull
    private func safeStringValue(_ value: Any) -> String {
        if value is NSNull { return "—" }
        let str = String(describing: value)
        if str == "<null>" || str == "null" || str == "Optional(nil)" { return "—" }
        return str
    }

    private func parseJSON(_ output: String, rowsPath: String?, transform: String? = nil, keyColumn: String? = nil) throws -> [[String: String]] {
        guard let data = output.data(using: .utf8) else { return [] }

        // Allow fragments so that bare `null` (from Go nil slices) doesn't throw
        let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)

        // Handle null output gracefully (Go nil slice → JSON "null")
        if json is NSNull { return [] }

        // Navigate to rows path (e.g. "data.rows" or "items")
        var target: Any = json
        if let path = rowsPath {
            for key in path.split(separator: ".") {
                if let dict = target as? [String: Any], let next = dict[String(key)] {
                    target = next
                } else {
                    break
                }
            }
        }

        // Handle object_to_rows transform: convert {key: {props}} → [{keyColumn: key, ...props}]
        if transform == "object_to_rows", let dict = target as? [String: Any] {
            let col = keyColumn ?? "key"
            return dict.compactMap { key, value -> [String: String]? in
                if let props = value as? [String: Any] {
                    var row: [String: String] = [col: key]
                    for (k, v) in props {
                        row[k] = safeStringValue(v)
                    }
                    return row
                } else {
                    return [col: key, "value": safeStringValue(value)]
                }
            }
        }

        // Convert array of objects to [[String: String]]
        if let array = target as? [[String: Any]] {
            return array.map { dict in
                dict.reduce(into: [String: String]()) { result, pair in
                    result[pair.key] = safeStringValue(pair.value)
                }
            }
        }

        // Single object → single row
        if let dict = target as? [String: Any] {
            return [dict.reduce(into: [String: String]()) { result, pair in
                result[pair.key] = safeStringValue(pair.value)
            }]
        }

        return []
    }

    private func parseDelimited(_ output: String, delimiter: String) -> [[String: String]] {
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard let headerLine = lines.first else { return [] }

        let headers = headerLine.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: .whitespaces) }

        return lines.dropFirst().compactMap { line -> [String: String]? in
            let values = line.components(separatedBy: delimiter).map { $0.trimmingCharacters(in: .whitespaces) }
            guard values.count >= headers.count else { return nil }
            return Dictionary(uniqueKeysWithValues: zip(headers, values))
        }
    }

    private func parseLines(_ output: String) -> [[String: String]] {
        output.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { ["value": $0] }
    }

    private func parseKeyValue(_ output: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in output.components(separatedBy: "\n") {
            // Support KEY=VALUE and KEY: VALUE
            if let eqRange = line.range(of: "=") {
                let key = String(line[..<eqRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let value = String(line[eqRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                result[key] = value
            } else if let colonRange = line.range(of: ": ") {
                let key = String(line[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let value = String(line[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                result[key] = value
            }
        }
        return result
    }

    /// Parse Nginx combined log format
    private func parseNginxLog(_ output: String) -> [[String: String]] {
        // Pattern: IP - - [date] "METHOD /path HTTP/1.1" status bytes "referer" "ua"
        let pattern = #"^(\S+) \S+ \S+ \[([^\]]+)\] "(\S+) (\S+) \S+" (\d+) (\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return parseLines(output) }

        return output.components(separatedBy: "\n").compactMap { line -> [String: String]? in
            guard !line.isEmpty else { return nil }
            let range = NSRange(line.startIndex..., in: line)
            guard let match = regex.firstMatch(in: line, range: range) else { return nil }

            func group(_ i: Int) -> String {
                guard let r = Range(match.range(at: i), in: line) else { return "" }
                return String(line[r])
            }

            return [
                "ip":     group(1),
                "date":   group(2),
                "method": group(3),
                "path":   group(4),
                "status": group(5),
                "bytes":  group(6)
            ]
        }
    }

    /// Parse Apache combined log format (same as nginx)
    private func parseApacheLog(_ output: String) -> [[String: String]] {
        parseNginxLog(output)
    }

    // MARK: - Template Resolution

    private func resolveTemplates(
        in payload: [String: AnyCodable]?,
        context: [String: String],
        serverId: String? = nil,
        namespace: String? = nil,
        pluginId: String? = nil
    ) -> [String: String] {
        guard let payload else { return [:] }

        var enrichedContext = context
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        // Date / time
        enrichedContext["date.now"]       = ISO8601DateFormatter().string(from: now)
        enrichedContext["date.today"]     = dateFormatter.string(from: now)
        enrichedContext["date.time"]      = timeFormatter.string(from: now)
        enrichedContext["date.timestamp"] = String(Int(now.timeIntervalSince1970))

        // Server + plugin identity — lets plugins use {{server.id}}, {{plugin.namespace}}, {{plugin.id}}
        if let serverId  { enrichedContext["server.id"]        = serverId  }
        if let namespace { enrichedContext["plugin.namespace"] = namespace }
        if let pluginId  { enrichedContext["plugin.id"]        = pluginId  }

        // macOS user
        #if os(macOS)
        enrichedContext["user.name"]     = NSUserName()
        enrichedContext["user.fullname"] = NSFullUserName()
        #endif

        return payload.reduce(into: [String: String]()) { result, pair in
            var value = pair.value.stringValue
            for (key, contextValue) in enrichedContext {
                value = value.replacingOccurrences(of: "{{\(key)}}", with: contextValue)
            }
            result[pair.key] = value
        }
    }

    // MARK: - Namespace Resolution

    /// Resolve namespace from action name by matching the action prefix
    /// to installed plugin namespaces in ManifestStore.
    ///
    /// e.g. "waf.blocklist.add" → prefix "waf" → matches "aevonx-shield-waf"
    /// e.g. "phpscan.scan.full" → prefix "phpscan" → matches "aevonx-guardian-phpscan"
    private func resolveNamespace(from action: String) -> String? {
        let actionPrefix = action.components(separatedBy: ".").first ?? ""
        guard !actionPrefix.isEmpty else { return nil }

        // 1. Direct slug match — most reliable (e.g. "waf" → namespace "waf" if registered)
        if let ns = PluginManifestStore.shared.namespaceForSlug(actionPrefix) {
            return ns
        }

        // 2. Direct namespace match
        if PluginManifestStore.shared.manifest(for: actionPrefix) != nil {
            return actionPrefix
        }

        // 3. Fuzzy: check if any namespace contains the prefix
        let namespaces = PluginManifestStore.shared.allNamespaces()
        for namespace in namespaces {
            if namespace.contains(actionPrefix) {
                return namespace
            }
        }

        return nil
    }

    // MARK: - SSH Command Building

    private func buildSSHCommand(action: String, payload: [String: String], type: HookCommandType = .coreCmd, namespace: String? = nil, serverId: String) async throws -> String {
        // ── Dynamic plugin commands ──────────────────────────────────────
        if type == .pluginCmd, let ns = namespace {
            return try buildPluginCommand(action: action, payload: payload, namespace: ns)
        }

        // ── Core commands (hardcoded SSH mappings) ──────────────────────
        return try await buildCoreCommand(action: action, payload: payload, serverId: serverId)
    }

    // MARK: - Plugin Command (dynamic)

    /// Allowed directories for plugin binaries and command scripts
    private static let allowedBinaryPrefixes = [
        "/usr/local/bin/",
        "/opt/aevonx/plugins/",
        "/etc/aevonx/plugins/"
    ]

    private func buildPluginCommand(action: String, payload: [String: String], namespace: String) throws -> String {
        // Look up manifest from registry
        guard let manifest = PluginManifestStore.shared.manifest(for: namespace) else {
            throw PluginDispatchError.actionNotAllowed(action, reason: "No manifest found for namespace '\(namespace)'")
        }

        // Smart Auto-Trust: plugin is installed → action is trusted
        // Safety already validated at dispatch() entry point

        // Validate action name is safe (alphanumeric + underscore + hyphen + dot only)
        let safePattern = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-."))
        guard action.unicodeScalars.allSatisfy({ safePattern.contains($0) }) else {
            throw PluginDispatchError.actionNotAllowed(action, reason: "Action name contains unsafe characters")
        }

        // Determine argument-passing style — defaults to "positional" for backward compat
        let argStyle = manifest.argStyle ?? "positional"

        // ── Script-based dispatch (commands_path) ────────────────────────
        if let commandsPath = manifest.commandsPath, !commandsPath.isEmpty {
            guard Self.allowedBinaryPrefixes.contains(where: { commandsPath.hasPrefix($0) }) else {
                CoreLogger.shared.warning(
                    "SECURITY: Commands path '\(commandsPath)' is not in allowed directories — REJECTED",
                    module: "PluginCommandDispatcher"
                )
                throw PluginDispatchError.actionNotAllowed(action, reason: "Commands path not in allowed directories")
            }

            let base = "\(commandsPath)/\(action)"
            return base + buildArgs(payload: payload, argStyle: argStyle)
        }

        // ── Binary-based dispatch ────────────────────────────────────────
        guard let binary = manifest.binary, !binary.isEmpty else {
            throw PluginDispatchError.actionNotAllowed(action, reason: "No binary or commands_path defined in manifest for '\(namespace)'")
        }

        guard Self.allowedBinaryPrefixes.contains(where: { binary.hasPrefix($0) }) else {
            CoreLogger.shared.warning(
                "SECURITY: Plugin binary path '\(binary)' is not in allowed directories — REJECTED",
                module: "PluginCommandDispatcher"
            )
            throw PluginDispatchError.actionNotAllowed(action, reason: "Binary path not in allowed directories")
        }

        // json style pipes payload via stdin instead of command-line args
        if argStyle == "json" {
            let jsonArgs = payload.sorted(by: { $0.key < $1.key })
                .reduce(into: [String: String]()) { $0[$1.key] = $1.value }
            if let jsonData = try? JSONSerialization.data(withJSONObject: jsonArgs),
               let jsonStr = String(data: jsonData, encoding: .utf8) {
                let escaped = jsonStr.replacingOccurrences(of: "'", with: "'\\''")
                return "echo '\(escaped)' | \(binary) \(action)"
            }
        }

        return "\(binary) \(action)" + buildArgs(payload: payload, argStyle: argStyle)
    }

    /// Builds the argument string for a plugin command based on the manifest's arg_style.
    private func buildArgs(payload: [String: String], argStyle: String) -> String {
        guard !payload.isEmpty else { return "" }
        let sorted = payload.sorted(by: { $0.key < $1.key })
        switch argStyle {
        case "named":
            // --key value format — developer has full control over parameter names
            return sorted.map { " --\($0.key) \(shellEscape($0.value))" }.joined()
        default:
            // "positional" — alphabetical key order (backward-compatible)
            return sorted.map { " \(shellEscape($0.value))" }.joined()
        }
    }

    // validatePluginAction removed — validation now handled by PluginPermissionValidator.validatePluginAction()

    /// Shell-escape a string value for safe SSH command interpolation.
    /// Strips dangerous control characters then wraps in single-quotes.
    private func shellEscape(_ value: String) -> String {
        // Strip control characters that could break out of quoting
        let sanitized = value
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\0", with: "")
        // Single-quote wrap — the only character that must be escaped inside single quotes is the quote itself
        let escaped = sanitized.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    private func buildCoreCommand(action: String, payload: [String: String], serverId: String) async throws -> String {
        // Helper: sanitize identifiers (website_id, database_name, etc.)
        func sid(_ key: String, default def: String = "") -> String {
            ShellSanitizer.sanitizeIdentifier(payload[key] ?? def)
        }
        // Helper: sanitize paths
        func spath(_ key: String, default def: String) -> String {
            ShellSanitizer.escapePath(payload[key] ?? def)
        }
        // Helper: sanitize numeric values (count, limit)
        func snum(_ key: String, default def: String) -> String {
            let raw = payload[key] ?? def
            return raw.filter { $0.isNumber }
        }
        
        // Resolve dynamic server paths
        let webRoot = (try? await ServerPathResolver.shared.webRoot(serverId: serverId)) ?? "/var/www"
        let nginxLogDir = (try? await ServerPathResolver.shared.nginxLogDir(serverId: serverId)) ?? "/var/log/nginx"
        
        let logBase = (try? await ServerPathResolver.shared.logDir(serverId: serverId)) ?? "/var/log"
        
        let commands: [String: () throws -> String] = [
            // Websites
            "website.backup":       { "tar -czf /tmp/backup-\(sid("website_id", default: "site"))-$(date +%Y%m%d).tar.gz \(webRoot)/\(sid("website_id"))" },
            "website.ssl.renew":    { "certbot renew --cert-name \(sid("website_id")) --non-interactive" },
            "website.clone":        { "cp -r \(webRoot)/\(sid("website_id")) \(spath("destination", default: "/tmp/clone"))" },
            "website.status":       { "systemctl status nginx --no-pager -l" },
            "website.restart":      { "systemctl restart nginx" },
            "website.logs":         { "tail -n 100 \(nginxLogDir)/\(sid("website_id", default: "access")).log" },
            "website.access_stats": { "awk '{print $1, $7, $9}' \(nginxLogDir)/access.log | sort | uniq -c | sort -rn | head -50" },

            // Databases
            "database.optimize":    { "mysqlcheck -u root --optimize \(sid("database_name", default: "--all-databases"))" },
            "database.backup":      { "mysqldump -u root \(sid("database_name")) > /tmp/db-backup-$(date +%Y%m%d).sql" },
            "database.size":        { "mysql -u root -e \"SELECT table_schema, ROUND(SUM(data_length+index_length)/1024/1024,2) AS size_mb FROM information_schema.tables GROUP BY table_schema;\"" },

            // Monitoring
            "monitoring.metrics":   { "echo \"{\\\"cpu\\\": $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}'), \\\"mem\\\": $(free | grep Mem | awk '{print $3/$2 * 100.0}'), \\\"disk\\\": $(df / | tail -1 | awk '{print $5}' | tr -d '%')}\"" },
            "monitoring.processes": { "ps aux --sort=-%cpu | head -\(snum("count", default: "20"))" },
            "monitoring.disk.usage":{ "df -h" },
            "monitoring.network.stats": { "ss -tuln" },
            "monitoring.nginx.access_stats": {
                "echo 'ip,path,status,bytes' && awk '{print $1\",\"$7\",\"$9\",\"$10}' \(nginxLogDir)/access.log | sort | uniq -c | sort -rn | head -\(snum("limit", default: "100")) | awk '{print $2}'"
            },

            // Security
            "firewall.status":      { "ufw status verbose" },
            "security.fail2ban.status": { "fail2ban-client status" },
            "security.audit":       { "last -n 50" },
            "security.scan":        { "find \(spath("path", default: webRoot)) -name '*.php' -newer /tmp/.last_scan -exec grep -l 'eval\\|base64_decode\\|system(' {} \\;" },
            "security.open_ports":  { "ss -tlnp" },
            "security.failed_logins": { "grep 'Failed password' \(logBase)/auth.log 2>/dev/null || grep 'Failed password' \(logBase)/secure 2>/dev/null | tail -50" },

            // System
            "system.info":          { "uname -a && lsb_release -a 2>/dev/null" },
            "system.services":      { "systemctl list-units --type=service --state=running --no-pager" },
            "system.cron":          { "crontab -l 2>/dev/null || echo 'No crontab'" },
            "system.env":           { "printenv | sort" },
            "system.users":         { "getent passwd | awk -F: '$3>=1000 {print $1,$3,$4,$6,$7}'" },
        ]

        guard let builder = commands[action] else {
            throw PluginDispatchError.actionNotAllowed(action, reason: "No SSH mapping defined for core action")
        }

        return try builder()
    }

    // MARK: - SSH Execution

    private func executeSSH(command: String, serverId: String, type: HookCommandType, timeout: TimeInterval) async throws -> String {
        // Use executeAsyncJSON to get the Go-Core envelope
        // ({"success":true,"data":{"stdout":"...","stderr":"...","exit_code":0}}).
        // executeAsync returns ONLY stdout, which SSHResult.parse then misreads
        // as a failure — that was the "Command execution failed: { ...valid JSON... }"
        // spam users saw across every hook-driven tab.
        let envelope = await SSHBridge.shared.executeAsyncJSON(serverID: serverId, command: command)
        let result = SSHResult.parse(envelope)
        if !result.isSuccess {
            let errorInfo = result.stderr.isEmpty ? result.stdout : result.stderr
            throw PluginDispatchError.executionFailed(
                "Command failed: \(errorInfo.prefix(200))"
            )
        }
        return result.stdout
    }
}

// MARK: - Errors

public enum PluginDispatchError: LocalizedError {
    case actionNotAllowed(String, reason: String?)
    case templateResolutionFailed(String)
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .actionNotAllowed(let action, let reason):
            return "Action '\(action)' not allowed\(reason.map { ": \($0)" } ?? "")"
        case .templateResolutionFailed(let key):
            return "Failed to resolve template variable: \(key)"
        case .executionFailed(let msg):
            return "Command execution failed: \(msg)"
        }
    }
}

// MARK: - Backward Compatibility

public typealias PluginCommandDispatcher = HookCommandDispatcher
