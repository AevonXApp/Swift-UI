//
//  CommandTemplates.swift
//  AevonX
//
//  Command allow-list for SSH operations
//  UI Layer - No raw command execution allowed
//
//  Security: This file defines the ONLY commands that can be executed.
//  Any command not in this list is rejected by the Core layer.
//

import Foundation

// MARK: - Command Template

/// Represents a predefined, allow-listed command
/// 
/// Security: The UI layer NEVER constructs raw commands.
/// All commands are predefined templates that the Core layer validates.
public enum CommandTemplate {
    
    // MARK: - Overview Commands
    
    case overview(OverviewCommand)
    
    // MARK: - Database Commands

    case databases(DatabaseCommand)

    // MARK: - Service Commands

    case services(ServiceCommand)

    // MARK: - File Commands

    case files(FileCommand)
    
    // MARK: - Build Command
    
    /// Builds the actual command string for execution
    /// This is called by the Core layer after validation
    public func build() -> String {
        switch self {
        case .overview(let cmd):
            return cmd.command
        case .databases(let cmd):
            return cmd.command
        case .services(let cmd):
            return cmd.command
        case .files(let cmd):
            return cmd.command
        }
    }

    /// Returns the command category for logging/auditing
    public var category: String {
        switch self {
        case .overview:
            return "overview"
        case .databases:
            return "databases"
        case .services:
            return "services"
        case .files:
            return "files"
        }
    }

    /// Returns a human-readable description
    public var description: String {
        switch self {
        case .overview(let cmd):
            return cmd.description
        case .databases(let cmd):
            return cmd.description
        case .services(let cmd):
            return cmd.description
        case .files(let cmd):
            return cmd.description
        }
    }
}

// MARK: - Overview Commands

/// System overview and monitoring commands
/// These commands provide system vitals without exposing sensitive data
public enum OverviewCommand {
    
    /// CPU usage percentage
    case cpuUsage
    
    /// Memory usage percentage
    case memoryUsage
    
    /// Disk usage percentage
    case diskUsage
    
    /// System uptime
    case uptime
    
    /// Load average (1, 5, 15 minutes)
    case loadAverage
    
    /// CPU temperature (if available)
    case cpuTemperature
    
    /// Count of websites (nginx/apache vhosts)
    case websiteCount
    
    /// Count of active services
    case serviceCount
    
    /// The actual command string
    public var command: String {
        switch self {
        case .cpuUsage:
            // Get CPU usage percentage (100 - idle)
            return "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1"
            
        case .memoryUsage:
            // Get memory usage percentage
            return "free | grep Mem | awk '{printf \"%.1f\", $3/$2 * 100.0}'"
            
        case .diskUsage:
            // Get root partition usage percentage
            return "df -h / | tail -1 | awk '{print $5}' | sed 's/%//'"
            
        case .uptime:
            // Get system uptime in readable format
            return "uptime -p 2>/dev/null || uptime | awk -F',' '{print $1}' | sed 's/^.*up //'"
            
        case .loadAverage:
            // Get load average
            return "cat /proc/loadavg | awk '{print $1, $2, $3}'"
            
        case .cpuTemperature:
            // Try to get CPU temperature (varies by system)
            return "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1 | awk '{print $1/1000}' || sensors 2>/dev/null | grep 'Core 0' | awk '{print $3}' | sed 's/+//;s/°C//' || echo 'N/A'"
            
        case .websiteCount:
            // Count nginx/apache vhosts
            return "(ls /etc/nginx/sites-enabled/ 2>/dev/null; ls /etc/apache2/sites-enabled/ 2>/dev/null; ls /etc/httpd/conf.d/ 2>/dev/null) | wc -l"
            
        case .serviceCount:
            // Count active systemd services
            return "systemctl list-units --type=service --state=active 2>/dev/null | grep -c '.service' || echo '0'"
        }
    }
    
    /// Human-readable description
    public var description: String {
        switch self {
        case .cpuUsage:
            return "Get CPU usage percentage"
        case .memoryUsage:
            return "Get memory usage percentage"
        case .diskUsage:
            return "Get disk usage percentage"
        case .uptime:
            return "Get system uptime"
        case .loadAverage:
            return "Get system load average"
        case .cpuTemperature:
            return "Get CPU temperature"
        case .websiteCount:
            return "Count configured websites"
        case .serviceCount:
            return "Count active services"
        }
    }
}

// MARK: - Database Commands

/// Database management and monitoring commands
/// These commands provide database information without administrative access
public enum DatabaseCommand {
    
    /// List MySQL databases
    case listMySQL
    
    /// List PostgreSQL databases
    case listPostgreSQL
    
    /// List Redis databases/info
    case listRedis
    
    /// Get MySQL process list
    case mysqlProcesses
    
    /// Get PostgreSQL connections
    case postgresConnections
    
    /// Get MySQL database sizes
    case mysqlDatabaseSizes
    
    /// List MySQL users (limited info)
    case listMySQLUsers
    
    /// Get PostgreSQL database sizes
    case postgresDatabaseSizes
    
    /// Check if MySQL is running
    case checkMySQLStatus
    
    /// Check if PostgreSQL is running
    case checkPostgresStatus
    
    /// Check if Redis is running
    case checkRedisStatus
    
    /// The actual command string
    public var command: String {
        switch self {
        case .listMySQL:
            // List MySQL databases (requires mysql client access)
            return "mysql -e 'SHOW DATABASES;' 2>/dev/null || echo 'MySQL not available'"
            
        case .listPostgreSQL:
            // List PostgreSQL databases
            return "psql -l 2>/dev/null || echo 'PostgreSQL not available'"
            
        case .listRedis:
            // Get Redis info
            return "redis-cli INFO 2>/dev/null || echo 'Redis not available'"
            
        case .mysqlProcesses:
            // Show MySQL process list
            return "mysql -e 'SHOW PROCESSLIST;' 2>/dev/null || echo 'MySQL not available'"
            
        case .postgresConnections:
            // Show PostgreSQL connections
            return "psql -c 'SELECT count(*) FROM pg_stat_activity;' 2>/dev/null || echo 'PostgreSQL not available'"
            
        case .mysqlDatabaseSizes:
            // Get MySQL database sizes
            return """
            mysql -e "SELECT table_schema AS 'Database', 
            ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' 
            FROM information_schema.tables 
            GROUP BY table_schema;" 2>/dev/null || echo 'MySQL not available'
            """
            
        case .listMySQLUsers:
            // List MySQL users (limited columns for security)
            return "mysql -e 'SELECT User, Host FROM mysql.user;' 2>/dev/null || echo 'MySQL not available'"
            
        case .postgresDatabaseSizes:
            // Get PostgreSQL database sizes
            return """
            psql -c "SELECT datname AS database, 
            pg_size_pretty(pg_database_size(datname)) AS size 
            FROM pg_database WHERE datistemplate = false;" 2>/dev/null || echo 'PostgreSQL not available'
            """
            
        case .checkMySQLStatus:
            // Check MySQL service status
            return "systemctl is-active mysql 2>/dev/null || systemctl is-active mysqld 2>/dev/null || service mysql status 2>/dev/null | grep -q 'running' && echo 'active' || echo 'inactive'"
            
        case .checkPostgresStatus:
            // Check PostgreSQL service status
            return "systemctl is-active postgresql 2>/dev/null || service postgresql status 2>/dev/null | grep -q 'online' && echo 'active' || echo 'inactive'"
            
        case .checkRedisStatus:
            // Check Redis service status
            return "systemctl is-active redis 2>/dev/null || systemctl is-active redis-server 2>/dev/null || redis-cli ping 2>/dev/null | grep -q 'PONG' && echo 'active' || echo 'inactive'"
        }
    }
    
    /// Human-readable description
    public var description: String {
        switch self {
        case .listMySQL:
            return "List MySQL databases"
        case .listPostgreSQL:
            return "List PostgreSQL databases"
        case .listRedis:
            return "Get Redis server info"
        case .mysqlProcesses:
            return "List MySQL processes"
        case .postgresConnections:
            return "Count PostgreSQL connections"
        case .mysqlDatabaseSizes:
            return "Get MySQL database sizes"
        case .listMySQLUsers:
            return "List MySQL users"
        case .postgresDatabaseSizes:
            return "Get PostgreSQL database sizes"
        case .checkMySQLStatus:
            return "Check MySQL service status"
        case .checkPostgresStatus:
            return "Check PostgreSQL service status"
        case .checkRedisStatus:
            return "Check Redis service status"
        }
    }
}

// MARK: - Service Commands

/// Service management commands
/// These commands manage system services like nginx, mysql, php-fpm
public enum ServiceCommand {

    /// Restart nginx service
    case restartNginx

    /// Restart MySQL service
    case restartMySQL

    /// Restart PHP-FPM service
    case restartPHPFPM

    /// Restart Apache service
    case restartApache

    /// Restart Redis service
    case restartRedis

    /// Restart PostgreSQL service
    case restartPostgreSQL

    /// Check nginx status
    case statusNginx

    /// Check MySQL status
    case statusMySQL

    /// Check PHP-FPM status
    case statusPHPFPM

    /// The actual command string
    public var command: String {
        switch self {
        case .restartNginx:
            return "sudo systemctl restart nginx 2>/dev/null || sudo service nginx restart 2>/dev/null || echo 'Failed to restart nginx'"

        case .restartMySQL:
            return "sudo systemctl restart mysql 2>/dev/null || sudo systemctl restart mysqld 2>/dev/null || sudo service mysql restart 2>/dev/null || echo 'Failed to restart MySQL'"

        case .restartPHPFPM:
            return "sudo systemctl restart php-fpm 2>/dev/null || sudo systemctl restart php8.2-fpm 2>/dev/null || sudo systemctl restart php8.1-fpm 2>/dev/null || sudo service php-fpm restart 2>/dev/null || echo 'Failed to restart PHP-FPM'"

        case .restartApache:
            return "sudo systemctl restart apache2 2>/dev/null || sudo systemctl restart httpd 2>/dev/null || sudo service apache2 restart 2>/dev/null || echo 'Failed to restart Apache'"

        case .restartRedis:
            return "sudo systemctl restart redis 2>/dev/null || sudo systemctl restart redis-server 2>/dev/null || sudo service redis restart 2>/dev/null || echo 'Failed to restart Redis'"

        case .restartPostgreSQL:
            return "sudo systemctl restart postgresql 2>/dev/null || sudo service postgresql restart 2>/dev/null || echo 'Failed to restart PostgreSQL'"

        case .statusNginx:
            return "systemctl is-active nginx 2>/dev/null || service nginx status 2>/dev/null | grep -q 'running' && echo 'active' || echo 'inactive'"

        case .statusMySQL:
            return "systemctl is-active mysql 2>/dev/null || systemctl is-active mysqld 2>/dev/null || service mysql status 2>/dev/null | grep -q 'running' && echo 'active' || echo 'inactive'"

        case .statusPHPFPM:
            return "systemctl is-active php-fpm 2>/dev/null || systemctl is-active php8.2-fpm 2>/dev/null || systemctl is-active php8.1-fpm 2>/dev/null || echo 'inactive'"
        }
    }

    /// Human-readable description
    public var description: String {
        switch self {
        case .restartNginx:
            return "Restart nginx web server"
        case .restartMySQL:
            return "Restart MySQL database"
        case .restartPHPFPM:
            return "Restart PHP-FPM service"
        case .restartApache:
            return "Restart Apache web server"
        case .restartRedis:
            return "Restart Redis server"
        case .restartPostgreSQL:
            return "Restart PostgreSQL database"
        case .statusNginx:
            return "Check nginx status"
        case .statusMySQL:
            return "Check MySQL status"
        case .statusPHPFPM:
            return "Check PHP-FPM status"
        }
    }
}

// MARK: - File Commands

/// File system commands with path sanitization
/// These commands provide file information without exposing full filesystem access
public enum FileCommand {
    
    /// List directory contents
    case listDirectory(path: String)
    
    /// Get file information
    case fileInfo(path: String)
    
    /// Get directory size
    case directorySize(path: String)
    
    /// Find files by pattern
    case findFiles(directory: String, pattern: String)
    
    /// Read file contents (limited size)
    case readFile(path: String, maxLines: Int)
    
    /// The actual command string
    public var command: String {
        switch self {
        case .listDirectory(let path):
            // List directory with details, sanitized path
            let sanitized = sanitizePath(path)
            return "ls -la '\(sanitized)' 2>/dev/null || echo 'Directory not accessible'"
            
        case .fileInfo(let path):
            // Get file information, sanitized path
            let sanitized = sanitizePath(path)
            return "stat '\(sanitized)' 2>/dev/null || echo 'File not found'"
            
        case .directorySize(let path):
            // Get directory size, sanitized path
            let sanitized = sanitizePath(path)
            return "du -sh '\(sanitized)' 2>/dev/null || echo 'Directory not accessible'"
            
        case .findFiles(let directory, let pattern):
            // Find files, sanitized inputs
            let sanitizedDir = sanitizePath(directory)
            let sanitizedPattern = sanitizePattern(pattern)
            return "find '\(sanitizedDir)' -maxdepth 2 -name '\(sanitizedPattern)' -type f 2>/dev/null | head -20"
            
        case .readFile(let path, let maxLines):
            // Read file with line limit, sanitized path
            let sanitized = sanitizePath(path)
            let lines = max(1, min(maxLines, 1000)) // Limit to 1-1000 lines
            return "head -n \(lines) '\(sanitized)' 2>/dev/null || echo 'File not readable'"
        }
    }
    
    /// Human-readable description
    public var description: String {
        switch self {
        case .listDirectory(let path):
            return "List directory: \(path)"
        case .fileInfo(let path):
            return "Get file info: \(path)"
        case .directorySize(let path):
            return "Get directory size: \(path)"
        case .findFiles(let directory, let pattern):
            return "Find files in \(directory) matching \(pattern)"
        case .readFile(let path, let maxLines):
            return "Read \(maxLines) lines from \(path)"
        }
    }
}

// MARK: - Path Sanitization

/// Sanitizes a file path to prevent command injection
/// - Parameter path: The raw path input
/// - Returns: Sanitized path safe for command execution
private func sanitizePath(_ path: String) -> String {
    // Remove null bytes
    var sanitized = path.replacingOccurrences(of: "\0", with: "")
    
    // Remove shell special characters
    let forbiddenChars = CharacterSet(charactersIn: ";|&$`{}[]\\'\"")
    sanitized = sanitized.components(separatedBy: forbiddenChars).joined()
    
    // Normalize path - remove .. sequences
    while sanitized.contains("../") {
        sanitized = sanitized.replacingOccurrences(of: "../", with: "")
    }
    while sanitized.contains("/..") {
        sanitized = sanitized.replacingOccurrences(of: "/..", with: "")
    }
    
    // Remove leading ~ (home directory expansion)
    if sanitized.hasPrefix("~") {
        sanitized = String(sanitized.dropFirst())
    }
    
    // Ensure path doesn't start with //
    while sanitized.hasPrefix("//") {
        sanitized = String(sanitized.dropFirst())
    }
    
    // Limit path length
    if sanitized.count > 4096 {
        sanitized = String(sanitized.prefix(4096))
    }
    
    return sanitized
}

/// Sanitizes a file pattern for find commands
/// - Parameter pattern: The raw pattern input
/// - Returns: Sanitized pattern safe for command execution
private func sanitizePattern(_ pattern: String) -> String {
    // Remove null bytes and shell special characters
    var sanitized = pattern.replacingOccurrences(of: "\0", with: "")
    
    // Allow only safe glob characters: * ? . - _ [ ]
    let allowedChars = CharacterSet.alphanumerics
        .union(CharacterSet(charactersIn: "*?.-_[]"))
    
    sanitized = sanitized.unicodeScalars
        .filter { allowedChars.contains($0) }
        .map { String($0) }
        .joined()
    
    // Limit pattern length
    if sanitized.count > 256 {
        sanitized = String(sanitized.prefix(256))
    }
    
    return sanitized
}

// MARK: - Command Validation

/// Validates that a command string is in the allow-list
/// This is used by the Core layer to reject unauthorized commands
public struct CommandValidator {
    
    /// Validates a command against the allow-list
    /// - Parameter command: The command string to validate
    /// - Returns: Whether the command is allowed
    public static func isAllowed(_ command: String) -> Bool {
        // Get all allowed command strings
        let allowedCommands = getAllAllowedCommands()
        
        // Check if command matches any allowed command
        // Note: This is a simplified check - production would use more sophisticated matching
        return allowedCommands.contains { allowed in
            command.hasPrefix(allowed) || normalize(command) == normalize(allowed)
        }
    }
    
    /// Gets all allowed command strings
    private static func getAllAllowedCommands() -> [String] {
        var commands: [String] = []
        
        // Overview commands
        OverviewCommand.allCases.forEach { cmd in
            commands.append(cmd.command)
        }
        
        // Database commands
        DatabaseCommand.allCases.forEach { cmd in
            commands.append(cmd.command)
        }
        
        return commands
    }
    
    /// Normalizes a command string for comparison
    private static func normalize(_ command: String) -> String {
        return command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }
}

// MARK: - CaseIterable Conformance

extension OverviewCommand: CaseIterable {
    public static var allCases: [OverviewCommand] = [
        .cpuUsage,
        .memoryUsage,
        .diskUsage,
        .uptime,
        .loadAverage,
        .cpuTemperature,
        .websiteCount,
        .serviceCount
    ]
}

extension DatabaseCommand: CaseIterable {
    public static var allCases: [DatabaseCommand] = [
        .listMySQL,
        .listPostgreSQL,
        .listRedis,
        .mysqlProcesses,
        .postgresConnections,
        .mysqlDatabaseSizes,
        .listMySQLUsers,
        .postgresDatabaseSizes,
        .checkMySQLStatus,
        .checkPostgresStatus,
        .checkRedisStatus
    ]
}

extension ServiceCommand: CaseIterable {
    public static var allCases: [ServiceCommand] = [
        .restartNginx,
        .restartMySQL,
        .restartPHPFPM,
        .restartApache,
        .restartRedis,
        .restartPostgreSQL,
        .statusNginx,
        .statusMySQL,
        .statusPHPFPM
    ]
}
