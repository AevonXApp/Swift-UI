//
//  PathResolverBridge.swift
//  AevonXCoreBridge
//
//  Thin wrapper around Go Core path resolver.
//  ALL logic lives in Go — this just calls CGo functions and decodes JSON.
//

import Foundation
import AevonXCoreLib

// MARK: - PathResolverBridge

/// Bridge for auto-detecting server paths via Go Core.
/// Zero logic — just calls Go CGo functions.
public final class PathResolverBridge: @unchecked Sendable {

    public static let shared = PathResolverBridge()
    private init() {}

    // MARK: - Server Paths Detection

    /// Returns the shell command to detect all server paths.
    public func detectCmd() -> String {
        extractCommand(PathResolverDetectCmd())
    }

    /// Parses detection command output into ServerPaths via Go Core.
    public func parse(output: String) -> ServerPaths {
        guard let ptr = withCArgs({ c in PathResolverParse(c.str(output)) }) else { return ServerPaths.defaults }
        defer { CoreFreeString(ptr) }
        let json = String(cString: ptr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              resp["success"] as? Bool == true,
              let pathsData = resp["data"] as? [String: Any] else {
            return ServerPaths.defaults
        }
        return ServerPaths(
            webRoot: pathsData["web_root"] as? String ?? "/var/www",
            nginxSitesAvailable: pathsData["nginx_sites_available"] as? String ?? "",
            nginxSitesEnabled: pathsData["nginx_sites_enabled"] as? String ?? "",
            nginxConfD: pathsData["nginx_conf_d"] as? String ?? "",
            nginxMainConf: pathsData["nginx_main_conf"] as? String ?? "/etc/nginx/nginx.conf",
            apacheSitesAvailable: pathsData["apache_sites_available"] as? String ?? "",
            apacheSitesEnabled: pathsData["apache_sites_enabled"] as? String ?? "",
            logDir: pathsData["log_dir"] as? String ?? "/var/log/nginx",
            backupDir: pathsData["backup_dir"] as? String ?? "/var/backups/aevonx",
            cacheDir: pathsData["cache_dir"] as? String ?? "/var/cache/nginx",
            letsEncryptDir: pathsData["letsencrypt_dir"] as? String ?? "/etc/letsencrypt/live",
            phpConfDir: pathsData["php_conf_dir"] as? String ?? "",
            webUser: pathsData["web_user"] as? String ?? "www-data",
            webGroup: pathsData["web_group"] as? String ?? "www-data",
            serverType: pathsData["server_type"] as? String ?? "standard",
            webServerType: pathsData["web_server_type"] as? String ?? "unknown",
            olsVHostDir: pathsData["ols_vhost_dir"] as? String ?? "",
            olsConfPath: pathsData["ols_conf_path"] as? String ?? "",
            olsLogDir: pathsData["ols_log_dir"] as? String ?? ""
        )
    }

    // MARK: - Per-Domain Document Root

    /// Returns the shell command to find the REAL document root for a domain.
    /// Reads actual nginx & Apache configs — never guesses.
    public func docRootCmd(domain: String) -> String {
        withCArgs { c in extractCommand(PathResolverDocRootCmd(c.str(domain))) }
    }

    /// Parses docroot detection output via Go Core.
    public func parseDocRoot(output: String) -> String {
        guard let ptr = withCArgs({ c in PathResolverParseDocRoot(c.str(output)) }) else { return "" }
        defer { CoreFreeString(ptr) }
        let json = String(cString: ptr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              resp["success"] as? Bool == true,
              let dataObj = resp["data"] as? [String: Any],
              let docRoot = dataObj["doc_root"] as? String else {
            return ""
        }
        return docRoot
    }

    // MARK: - Helpers

    private func extractCommand(_ cStr: UnsafeMutablePointer<CChar>?) -> String {
        guard let cStr = cStr else { return "" }
        defer { CoreFreeString(cStr) }
        let json = String(cString: cStr)
        guard let data = json.data(using: .utf8),
              let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              resp["success"] as? Bool == true,
              let innerData = resp["data"] as? [String: Any],
              let value = innerData["command"] as? String else { return "" }
        return value
    }
}

// MARK: - ServerPaths Model

/// Detected server filesystem paths — decoded from Go Core JSON.
public struct ServerPaths: Codable, Sendable {
    public let webRoot: String
    public let nginxSitesAvailable: String
    public let nginxSitesEnabled: String
    public let nginxConfD: String
    public let nginxMainConf: String
    public let apacheSitesAvailable: String
    public let apacheSitesEnabled: String
    public let logDir: String
    public let backupDir: String
    public let cacheDir: String
    public let letsEncryptDir: String
    public let phpConfDir: String
    public let webUser: String
    public let webGroup: String
    public let serverType: String
    public let webServerType: String
    public let olsVHostDir: String
    public let olsConfPath: String
    public let olsLogDir: String

    /// Convenience: "user:group" for chown commands.
    public var webOwnership: String { "\(webUser):\(webGroup)" }

    /// True if this is a BT Panel server.
    public var isBTPanel: Bool { serverType == "bt_panel" }

    /// True if nginx is available on this server.
    public var hasNginx: Bool {
        webServerType == "nginx" || webServerType == "both" || webServerType.contains("nginx")
    }

    /// True if Apache is available on this server.
    public var hasApache: Bool {
        webServerType == "apache" || webServerType == "both" || webServerType.contains("apache")
    }

    /// True if OpenLiteSpeed is available on this server.
    public var hasOLS: Bool {
        webServerType.contains("openlitespeed")
    }

    /// Returns the set of installed engine identifiers.
    public var installedEngines: Set<String> {
        var engines = Set<String>()
        if hasNginx { engines.insert("nginx") }
        if hasApache { engines.insert("apache") }
        if hasOLS { engines.insert("openlitespeed") }
        return engines
    }

    /// Safe defaults.
    public static let defaults = ServerPaths(
        webRoot: "/var/www",
        nginxSitesAvailable: "/etc/nginx/sites-available",
        nginxSitesEnabled: "/etc/nginx/sites-enabled",
        nginxConfD: "/etc/nginx/conf.d",
        nginxMainConf: "/etc/nginx/nginx.conf",
        apacheSitesAvailable: "/etc/apache2/sites-available",
        apacheSitesEnabled: "/etc/apache2/sites-enabled",
        logDir: "/var/log/nginx",
        backupDir: "/var/backups/aevonx",
        cacheDir: "/var/cache/nginx",
        letsEncryptDir: "/etc/letsencrypt/live",
        phpConfDir: "/etc/php",
        webUser: "www-data",
        webGroup: "www-data",
        serverType: "standard",
        webServerType: "unknown",
        olsVHostDir: "",
        olsConfPath: "",
        olsLogDir: ""
    )

    public init(
        webRoot: String = "/var/www",
        nginxSitesAvailable: String = "/etc/nginx/sites-available",
        nginxSitesEnabled: String = "/etc/nginx/sites-enabled",
        nginxConfD: String = "/etc/nginx/conf.d",
        nginxMainConf: String = "/etc/nginx/nginx.conf",
        apacheSitesAvailable: String = "/etc/apache2/sites-available",
        apacheSitesEnabled: String = "/etc/apache2/sites-enabled",
        logDir: String = "/var/log/nginx",
        backupDir: String = "/var/backups/aevonx",
        cacheDir: String = "/var/cache/nginx",
        letsEncryptDir: String = "/etc/letsencrypt/live",
        phpConfDir: String = "/etc/php",
        webUser: String = "www-data",
        webGroup: String = "www-data",
        serverType: String = "standard",
        webServerType: String = "unknown",
        olsVHostDir: String = "",
        olsConfPath: String = "",
        olsLogDir: String = ""
    ) {
        self.webRoot = webRoot
        self.nginxSitesAvailable = nginxSitesAvailable
        self.nginxSitesEnabled = nginxSitesEnabled
        self.nginxConfD = nginxConfD
        self.nginxMainConf = nginxMainConf
        self.apacheSitesAvailable = apacheSitesAvailable
        self.apacheSitesEnabled = apacheSitesEnabled
        self.logDir = logDir
        self.backupDir = backupDir
        self.cacheDir = cacheDir
        self.letsEncryptDir = letsEncryptDir
        self.phpConfDir = phpConfDir
        self.webUser = webUser
        self.webGroup = webGroup
        self.serverType = serverType
        self.webServerType = webServerType
        self.olsVHostDir = olsVHostDir
        self.olsConfPath = olsConfPath
        self.olsLogDir = olsLogDir
    }
}
