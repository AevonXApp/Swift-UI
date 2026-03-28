//
//  SystemSpecs.swift
//  AevonX
//
//  Completion specs for system tools: systemctl, apt, nginx, certbot, etc.
//

import Foundation

enum SystemSpecs {

    // MARK: - systemctl

    static let systemctl = ToolSpec(
        command: "systemctl",
        description: "System and service manager",
        subcommands: [
            SubcommandSpec(name: "start", description: "Start a unit", flags: []),
            SubcommandSpec(name: "stop", description: "Stop a unit", flags: []),
            SubcommandSpec(name: "restart", description: "Restart a unit", flags: []),
            SubcommandSpec(name: "reload", description: "Reload a unit", flags: []),
            SubcommandSpec(name: "status", description: "Show unit status", flags: []),
            SubcommandSpec(name: "enable", description: "Enable a unit", flags: [
                FlagSpec(long: "--now", description: "Also start the unit"),
            ]),
            SubcommandSpec(name: "disable", description: "Disable a unit", flags: [
                FlagSpec(long: "--now", description: "Also stop the unit"),
            ]),
            SubcommandSpec(name: "is-active", description: "Check if active", flags: []),
            SubcommandSpec(name: "is-enabled", description: "Check if enabled", flags: []),
            SubcommandSpec(name: "list-units", description: "List loaded units", flags: [
                FlagSpec(long: "--type", description: "Unit type", takesValue: true, values: ["service", "socket", "timer", "mount"]),
                FlagSpec(long: "--state", description: "Unit state", takesValue: true),
            ]),
            SubcommandSpec(name: "list-unit-files", description: "List installed units", flags: [
                FlagSpec(long: "--type", description: "Unit type", takesValue: true, values: ["service", "socket", "timer"]),
            ]),
            SubcommandSpec(name: "daemon-reload", description: "Reload systemd config", flags: []),
            SubcommandSpec(name: "mask", description: "Mask a unit (prevent start)", flags: []),
            SubcommandSpec(name: "unmask", description: "Unmask a unit", flags: []),
        ],
        globalFlags: [
            FlagSpec(long: "--no-pager", description: "No pager"),
            FlagSpec(long: "--no-legend", description: "No header/footer"),
        ]
    )

    // MARK: - journalctl

    static let journalctl = ToolSpec(
        command: "journalctl",
        description: "Query the systemd journal",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "--unit", short: "-u", description: "Filter by unit", takesValue: true),
            FlagSpec(long: "--follow", short: "-f", description: "Follow new entries"),
            FlagSpec(long: "--lines", short: "-n", description: "Number of lines", takesValue: true),
            FlagSpec(long: "--since", description: "Since time", takesValue: true),
            FlagSpec(long: "--until", description: "Until time", takesValue: true),
            FlagSpec(long: "--priority", short: "-p", description: "Priority level", takesValue: true, values: ["emerg", "alert", "crit", "err", "warning", "notice", "info", "debug"]),
            FlagSpec(long: "--no-pager", description: "No pager"),
            FlagSpec(long: "--output", short: "-o", description: "Output format", takesValue: true, values: ["short", "json", "cat", "verbose"]),
            FlagSpec(long: "--boot", short: "-b", description: "Current boot only"),
        ]
    )

    // MARK: - apt

    static let apt = ToolSpec(
        command: "apt",
        description: "Package manager (Debian/Ubuntu)",
        subcommands: [
            SubcommandSpec(name: "install", description: "Install packages", flags: [
                FlagSpec(long: "-y", description: "Auto yes"),
                FlagSpec(long: "--no-install-recommends", description: "Skip recommends"),
                FlagSpec(long: "--reinstall", description: "Reinstall"),
            ]),
            SubcommandSpec(name: "remove", description: "Remove packages", flags: [
                FlagSpec(long: "--purge", description: "Remove config files"),
                FlagSpec(long: "-y", description: "Auto yes"),
            ]),
            SubcommandSpec(name: "purge", description: "Remove packages and config", flags: [
                FlagSpec(long: "-y", description: "Auto yes"),
            ]),
            SubcommandSpec(name: "update", description: "Update package lists", flags: []),
            SubcommandSpec(name: "upgrade", description: "Upgrade packages", flags: [
                FlagSpec(long: "-y", description: "Auto yes"),
            ]),
            SubcommandSpec(name: "dist-upgrade", description: "Full system upgrade", flags: [
                FlagSpec(long: "-y", description: "Auto yes"),
            ]),
            SubcommandSpec(name: "autoremove", description: "Remove unused deps", flags: [
                FlagSpec(long: "-y", description: "Auto yes"),
            ]),
            SubcommandSpec(name: "search", description: "Search packages", flags: []),
            SubcommandSpec(name: "show", description: "Show package details", flags: []),
            SubcommandSpec(name: "list", description: "List packages", flags: [
                FlagSpec(long: "--installed", description: "Only installed"),
                FlagSpec(long: "--upgradable", description: "Only upgradable"),
            ]),
            SubcommandSpec(name: "clean", description: "Clear package cache", flags: []),
        ],
        globalFlags: []
    )

    // MARK: - nginx

    static let nginx = ToolSpec(
        command: "nginx",
        description: "Web server",
        subcommands: [],
        globalFlags: [
            FlagSpec(long: "-t", description: "Test configuration"),
            FlagSpec(long: "-T", description: "Test and dump config"),
            FlagSpec(long: "-s", description: "Send signal", takesValue: true, values: ["stop", "reload", "quit", "reopen"]),
            FlagSpec(long: "-c", description: "Config file path", takesValue: true),
            FlagSpec(long: "-v", description: "Show version"),
            FlagSpec(long: "-V", description: "Show version and config"),
        ]
    )

    // MARK: - certbot

    static let certbot = ToolSpec(
        command: "certbot",
        description: "Let's Encrypt SSL certificates",
        subcommands: [
            SubcommandSpec(name: "certonly", description: "Obtain a certificate", flags: [
                FlagSpec(long: "--nginx", description: "Use nginx plugin"),
                FlagSpec(long: "--apache", description: "Use apache plugin"),
                FlagSpec(long: "--standalone", description: "Standalone mode"),
                FlagSpec(long: "--webroot", description: "Webroot mode"),
                FlagSpec(long: "-d", description: "Domain name", takesValue: true),
                FlagSpec(long: "--agree-tos", description: "Agree to terms"),
                FlagSpec(long: "-m", description: "Email address", takesValue: true),
                FlagSpec(long: "--non-interactive", description: "No prompts"),
            ]),
            SubcommandSpec(name: "renew", description: "Renew certificates", flags: [
                FlagSpec(long: "--dry-run", description: "Test renewal"),
                FlagSpec(long: "--force-renewal", description: "Force renew"),
            ]),
            SubcommandSpec(name: "certificates", description: "List certificates", flags: []),
            SubcommandSpec(name: "delete", description: "Delete a certificate", flags: [
                FlagSpec(long: "--cert-name", description: "Certificate name", takesValue: true),
            ]),
            SubcommandSpec(name: "revoke", description: "Revoke a certificate", flags: [
                FlagSpec(long: "--cert-path", description: "Certificate path", takesValue: true),
            ]),
        ],
        globalFlags: []
    )

    /// Dynamic: fetch service names
    static let serviceListCommand = "systemctl list-unit-files --type=service --no-pager --no-legend 2>/dev/null | awk '{print $1}'"

    static var allSpecs: [ToolSpec] {
        [systemctl, journalctl, apt, nginx, certbot]
    }
}
