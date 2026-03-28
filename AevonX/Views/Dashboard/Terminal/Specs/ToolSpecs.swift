//
//  ToolSpecs.swift
//  AevonX
//
//  Completion specs for common CLI tools: npm, curl, ssh, file utils, etc.
//  Also serves as the spec registry entry point.
//

import Foundation

// MARK: - Tool Specs Registry

enum ToolSpecsRegistry {

    /// All tool specs combined from all spec files.
    static var allSpecs: [ToolSpec] {
        LaravelSpecs.allSpecs
        + GitSpecs.allSpecs
        + DockerSpecs.allSpecs
        + SystemSpecs.allSpecs
        + CommonToolSpecs.allSpecs
    }
}

// MARK: - Common Tool Specs

enum CommonToolSpecs {

    // MARK: - npm

    static let npm = ToolSpec(
        command: "npm",
        description: "Node.js package manager",
        subcommands: [
            SubcommandSpec(name: "install", description: "Install packages", flags: [
                FlagSpec(long: "--save-dev", short: "-D", description: "Save as dev dep"),
                FlagSpec(long: "--global", short: "-g", description: "Install globally"),
                FlagSpec(long: "--save-exact", short: "-E", description: "Exact version"),
                FlagSpec(long: "--legacy-peer-deps", description: "Ignore peer deps"),
            ]),
            SubcommandSpec(name: "uninstall", description: "Remove a package", flags: [
                FlagSpec(long: "--save-dev", short: "-D", description: "Remove from dev"),
                FlagSpec(long: "--global", short: "-g", description: "Remove globally"),
            ]),
            SubcommandSpec(name: "run", description: "Run a script", flags: []),
            SubcommandSpec(name: "start", description: "Start the application", flags: []),
            SubcommandSpec(name: "test", description: "Run tests", flags: []),
            SubcommandSpec(name: "build", description: "Build the project", flags: []),
            SubcommandSpec(name: "init", description: "Initialize package.json", flags: [
                FlagSpec(long: "-y", description: "Accept defaults"),
            ]),
            SubcommandSpec(name: "update", description: "Update packages", flags: []),
            SubcommandSpec(name: "outdated", description: "Show outdated packages", flags: []),
            SubcommandSpec(name: "audit", description: "Security audit", flags: [
                FlagSpec(long: "--fix", description: "Auto-fix vulnerabilities"),
                FlagSpec(long: "--json", description: "JSON output"),
            ]),
            SubcommandSpec(name: "ci", description: "Clean install (CI)", flags: []),
            SubcommandSpec(name: "cache clean", description: "Clear cache", flags: [
                FlagSpec(long: "--force", description: "Force clean"),
            ]),
            SubcommandSpec(name: "ls", description: "List installed packages", flags: [
                FlagSpec(long: "--depth", description: "Depth level", takesValue: true),
            ]),
            SubcommandSpec(name: "exec", description: "Execute binary", flags: []),
        ],
        globalFlags: []
    )

    // MARK: - yarn

    static let yarn = ToolSpec(
        command: "yarn",
        description: "Fast, reliable package manager",
        subcommands: [
            SubcommandSpec(name: "add", description: "Add a package", flags: [
                FlagSpec(long: "--dev", short: "-D", description: "Add as dev dep"),
                FlagSpec(long: "--exact", short: "-E", description: "Exact version"),
            ]),
            SubcommandSpec(name: "remove", description: "Remove a package", flags: []),
            SubcommandSpec(name: "install", description: "Install dependencies", flags: [
                FlagSpec(long: "--frozen-lockfile", description: "Don't update lockfile"),
            ]),
            SubcommandSpec(name: "build", description: "Build the project", flags: []),
            SubcommandSpec(name: "dev", description: "Start dev server", flags: []),
            SubcommandSpec(name: "start", description: "Start application", flags: []),
            SubcommandSpec(name: "test", description: "Run tests", flags: []),
        ],
        globalFlags: []
    )

    // MARK: - curl

    static let curl = ToolSpec(
        command: "curl",
        description: "Transfer data with URLs",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-X", description: "HTTP method", takesValue: true, values: ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]),
            FlagSpec(long: "-H", description: "Header", takesValue: true),
            FlagSpec(long: "-d", description: "Request body data", takesValue: true),
            FlagSpec(long: "-o", description: "Output file", takesValue: true),
            FlagSpec(long: "-O", description: "Save with remote filename"),
            FlagSpec(long: "-L", description: "Follow redirects"),
            FlagSpec(long: "-s", description: "Silent mode"),
            FlagSpec(long: "-S", description: "Show errors"),
            FlagSpec(long: "-v", description: "Verbose"),
            FlagSpec(long: "-k", description: "Allow insecure connections"),
            FlagSpec(long: "--connect-timeout", description: "Connection timeout", takesValue: true),
            FlagSpec(long: "--max-time", description: "Maximum time", takesValue: true),
            FlagSpec(long: "-u", description: "User:password", takesValue: true),
            FlagSpec(long: "--data-raw", description: "Raw body data", takesValue: true),
            FlagSpec(long: "-F", description: "Form data", takesValue: true),
            FlagSpec(long: "-I", description: "Head request"),
        ]
    )

    // MARK: - wget

    static let wget = ToolSpec(
        command: "wget",
        description: "Network downloader",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-O", description: "Output file", takesValue: true),
            FlagSpec(long: "-P", description: "Output directory", takesValue: true),
            FlagSpec(long: "-q", description: "Quiet mode"),
            FlagSpec(long: "-c", description: "Continue download"),
            FlagSpec(long: "--no-check-certificate", description: "Skip SSL check"),
            FlagSpec(long: "-r", description: "Recursive download"),
            FlagSpec(long: "--tries", description: "Number of retries", takesValue: true),
        ]
    )

    // MARK: - ssh / scp / rsync

    static let ssh = ToolSpec(
        command: "ssh",
        description: "Secure shell client",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-p", description: "Port number", takesValue: true),
            FlagSpec(long: "-i", description: "Identity file", takesValue: true),
            FlagSpec(long: "-L", description: "Local port forward", takesValue: true),
            FlagSpec(long: "-R", description: "Remote port forward", takesValue: true),
            FlagSpec(long: "-N", description: "No remote command"),
            FlagSpec(long: "-f", description: "Background"),
            FlagSpec(long: "-v", description: "Verbose"),
            FlagSpec(long: "-o", description: "SSH option", takesValue: true),
        ]
    )

    static let scp = ToolSpec(
        command: "scp",
        description: "Secure copy",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-r", description: "Recursive copy"),
            FlagSpec(long: "-P", description: "Port number", takesValue: true),
            FlagSpec(long: "-i", description: "Identity file", takesValue: true),
            FlagSpec(long: "-v", description: "Verbose"),
        ]
    )

    static let rsync = ToolSpec(
        command: "rsync",
        description: "Fast incremental file transfer",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "--archive", short: "-a", description: "Archive mode"),
            FlagSpec(long: "--verbose", short: "-v", description: "Verbose"),
            FlagSpec(long: "--compress", short: "-z", description: "Compress during transfer"),
            FlagSpec(long: "--progress", description: "Show progress"),
            FlagSpec(long: "--delete", description: "Delete extra files at destination"),
            FlagSpec(long: "--exclude", description: "Exclude pattern", takesValue: true),
            FlagSpec(long: "--dry-run", short: "-n", description: "Show what would be done"),
            FlagSpec(long: "-e", description: "Remote shell command", takesValue: true),
        ]
    )

    // MARK: - File Utilities

    static let tar = ToolSpec(
        command: "tar",
        description: "Archive utility",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-c", description: "Create archive"),
            FlagSpec(long: "-x", description: "Extract archive"),
            FlagSpec(long: "-t", description: "List contents"),
            FlagSpec(long: "-z", description: "Gzip compression"),
            FlagSpec(long: "-j", description: "Bzip2 compression"),
            FlagSpec(long: "-v", description: "Verbose"),
            FlagSpec(long: "-f", description: "Archive file", takesValue: true),
            FlagSpec(long: "-C", description: "Change directory", takesValue: true),
            FlagSpec(long: "--exclude", description: "Exclude pattern", takesValue: true),
        ]
    )

    static let chmod = ToolSpec(
        command: "chmod",
        description: "Change file permissions",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-R", description: "Recursive"),
            FlagSpec(long: "-v", description: "Verbose"),
        ]
    )

    static let chown = ToolSpec(
        command: "chown",
        description: "Change file owner",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-R", description: "Recursive"),
            FlagSpec(long: "-v", description: "Verbose"),
        ]
    )

    // MARK: - Database CLIs

    static let mysql = ToolSpec(
        command: "mysql",
        description: "MySQL client",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-u", description: "Username", takesValue: true),
            FlagSpec(long: "-p", description: "Password (prompt)"),
            FlagSpec(long: "-h", description: "Host", takesValue: true),
            FlagSpec(long: "-P", description: "Port", takesValue: true),
            FlagSpec(long: "-D", description: "Database", takesValue: true),
            FlagSpec(long: "-e", description: "Execute SQL", takesValue: true),
        ]
    )

    static let psql = ToolSpec(
        command: "psql",
        description: "PostgreSQL client",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-U", description: "Username", takesValue: true),
            FlagSpec(long: "-h", description: "Host", takesValue: true),
            FlagSpec(long: "-p", description: "Port", takesValue: true),
            FlagSpec(long: "-d", description: "Database", takesValue: true),
            FlagSpec(long: "-c", description: "Execute SQL", takesValue: true),
            FlagSpec(long: "-f", description: "Execute file", takesValue: true),
        ]
    )

    static let redisCli = ToolSpec(
        command: "redis-cli",
        description: "Redis command-line interface",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-h", description: "Host", takesValue: true),
            FlagSpec(long: "-p", description: "Port", takesValue: true),
            FlagSpec(long: "-a", description: "Password", takesValue: true),
            FlagSpec(long: "-n", description: "Database number", takesValue: true),
        ]
    )

    // MARK: - Python

    static let python = ToolSpec(
        command: "python3",
        description: "Python interpreter",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-m", description: "Run module", takesValue: true),
            FlagSpec(long: "-c", description: "Execute code", takesValue: true),
            FlagSpec(long: "--version", description: "Show version"),
        ]
    )

    static let pip = ToolSpec(
        command: "pip",
        description: "Python package manager",
        subcommands: [
            SubcommandSpec(name: "install", description: "Install packages", flags: [
                FlagSpec(long: "-r", description: "Requirements file", takesValue: true),
                FlagSpec(long: "--upgrade", short: "-U", description: "Upgrade package"),
                FlagSpec(long: "--user", description: "Install for user"),
            ]),
            SubcommandSpec(name: "uninstall", description: "Uninstall packages", flags: [
                FlagSpec(long: "-y", description: "Auto yes"),
            ]),
            SubcommandSpec(name: "freeze", description: "Output installed packages", flags: []),
            SubcommandSpec(name: "list", description: "List installed packages", flags: [
                FlagSpec(long: "--outdated", description: "Show outdated"),
            ]),
            SubcommandSpec(name: "show", description: "Show package info", flags: []),
        ],
        globalFlags: []
    )

    // MARK: - grep / find

    static let grep = ToolSpec(
        command: "grep",
        description: "Search text patterns",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "--recursive", short: "-r", description: "Recursive search"),
            FlagSpec(long: "--ignore-case", short: "-i", description: "Case insensitive"),
            FlagSpec(long: "--line-number", short: "-n", description: "Show line numbers"),
            FlagSpec(long: "--count", short: "-c", description: "Count matches"),
            FlagSpec(long: "--files-with-matches", short: "-l", description: "Files with matches"),
            FlagSpec(long: "--invert-match", short: "-v", description: "Invert match"),
            FlagSpec(long: "--extended-regexp", short: "-E", description: "Extended regex"),
            FlagSpec(long: "--color", description: "Colorize output", takesValue: true, values: ["auto", "always", "never"]),
            FlagSpec(long: "--include", description: "File pattern", takesValue: true),
            FlagSpec(long: "--exclude", description: "Exclude pattern", takesValue: true),
            FlagSpec(long: "--context", short: "-C", description: "Context lines", takesValue: true),
        ]
    )

    static let find = ToolSpec(
        command: "find",
        description: "Search for files",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-name", description: "File name pattern", takesValue: true),
            FlagSpec(long: "-iname", description: "Case-insensitive name", takesValue: true),
            FlagSpec(long: "-type", description: "File type", takesValue: true, values: ["f", "d", "l"]),
            FlagSpec(long: "-size", description: "File size", takesValue: true),
            FlagSpec(long: "-mtime", description: "Modified time (days)", takesValue: true),
            FlagSpec(long: "-maxdepth", description: "Max directory depth", takesValue: true),
            FlagSpec(long: "-exec", description: "Execute command"),
            FlagSpec(long: "-delete", description: "Delete matched files"),
            FlagSpec(long: "-not", description: "Negate next expression"),
        ]
    )

    // MARK: - All Specs

    static var allSpecs: [ToolSpec] {
        [npm, yarn, curl, wget, ssh, scp, rsync,
         tar, chmod, chown,
         mysql, psql, redisCli,
         python, pip,
         grep, find]
    }
}
