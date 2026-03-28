//
//  DockerSpecs.swift
//  AevonX
//
//  Completion specs for Docker and Docker Compose.
//

import Foundation

enum DockerSpecs {

    // MARK: - Docker

    static let docker = ToolSpec(
        command: "docker",
        description: "Container platform",
        subcommands: [
            // Container
            SubcommandSpec(name: "ps", description: "List containers", flags: [
                FlagSpec(long: "--all", short: "-a", description: "Show all containers"),
                FlagSpec(long: "--format", description: "Output format", takesValue: true),
                FlagSpec(long: "--filter", short: "-f", description: "Filter", takesValue: true),
                FlagSpec(long: "--quiet", short: "-q", description: "Only show IDs"),
            ]),
            SubcommandSpec(name: "run", description: "Create and start a container", flags: [
                FlagSpec(long: "--name", description: "Container name", takesValue: true),
                FlagSpec(long: "-d", description: "Detached mode"),
                FlagSpec(long: "-it", description: "Interactive terminal"),
                FlagSpec(long: "-p", description: "Port mapping", takesValue: true),
                FlagSpec(long: "-v", description: "Volume mount", takesValue: true),
                FlagSpec(long: "-e", description: "Environment variable", takesValue: true),
                FlagSpec(long: "--rm", description: "Remove on exit"),
                FlagSpec(long: "--network", description: "Network", takesValue: true),
                FlagSpec(long: "--restart", description: "Restart policy", takesValue: true, values: ["no", "always", "unless-stopped", "on-failure"]),
                FlagSpec(long: "-w", description: "Working directory", takesValue: true),
            ]),
            SubcommandSpec(name: "exec", description: "Execute command in container", flags: [
                FlagSpec(long: "-it", description: "Interactive terminal"),
                FlagSpec(long: "-T", description: "Disable pseudo-TTY"),
                FlagSpec(long: "-u", description: "User", takesValue: true),
                FlagSpec(long: "-w", description: "Working directory", takesValue: true),
            ]),
            SubcommandSpec(name: "logs", description: "View container logs", flags: [
                FlagSpec(long: "--follow", short: "-f", description: "Follow log output"),
                FlagSpec(long: "--tail", description: "Number of lines", takesValue: true),
                FlagSpec(long: "--timestamps", short: "-t", description: "Show timestamps"),
                FlagSpec(long: "--since", description: "Since timestamp", takesValue: true),
            ]),
            SubcommandSpec(name: "stop", description: "Stop a container", flags: [
                FlagSpec(long: "--time", short: "-t", description: "Timeout seconds", takesValue: true),
            ]),
            SubcommandSpec(name: "start", description: "Start a stopped container", flags: []),
            SubcommandSpec(name: "restart", description: "Restart a container", flags: [
                FlagSpec(long: "--time", short: "-t", description: "Timeout seconds", takesValue: true),
            ]),
            SubcommandSpec(name: "rm", description: "Remove a container", flags: [
                FlagSpec(long: "--force", short: "-f", description: "Force remove"),
                FlagSpec(long: "--volumes", short: "-v", description: "Remove volumes"),
            ]),
            SubcommandSpec(name: "inspect", description: "Inspect container/image", flags: [
                FlagSpec(long: "--format", short: "-f", description: "Output format", takesValue: true),
            ]),
            SubcommandSpec(name: "top", description: "Display running processes", flags: []),
            SubcommandSpec(name: "stats", description: "Resource usage statistics", flags: [
                FlagSpec(long: "--no-stream", description: "Disable streaming"),
            ]),
            SubcommandSpec(name: "cp", description: "Copy files between container and host", flags: []),
            SubcommandSpec(name: "kill", description: "Kill a container", flags: [
                FlagSpec(long: "--signal", short: "-s", description: "Signal to send", takesValue: true),
            ]),

            // Image
            SubcommandSpec(name: "images", description: "List images", flags: [
                FlagSpec(long: "--all", short: "-a", description: "Show all images"),
                FlagSpec(long: "--quiet", short: "-q", description: "Only show IDs"),
            ]),
            SubcommandSpec(name: "pull", description: "Pull an image", flags: []),
            SubcommandSpec(name: "push", description: "Push an image", flags: []),
            SubcommandSpec(name: "build", description: "Build an image", flags: [
                FlagSpec(long: "--tag", short: "-t", description: "Image tag", takesValue: true),
                FlagSpec(long: "--file", short: "-f", description: "Dockerfile path", takesValue: true),
                FlagSpec(long: "--no-cache", description: "No build cache"),
                FlagSpec(long: "--target", description: "Build stage", takesValue: true),
            ]),
            SubcommandSpec(name: "rmi", description: "Remove an image", flags: [
                FlagSpec(long: "--force", short: "-f", description: "Force remove"),
            ]),
            SubcommandSpec(name: "tag", description: "Tag an image", flags: []),

            // Volume
            SubcommandSpec(name: "volume create", description: "Create a volume", flags: []),
            SubcommandSpec(name: "volume ls", description: "List volumes", flags: []),
            SubcommandSpec(name: "volume rm", description: "Remove a volume", flags: []),
            SubcommandSpec(name: "volume inspect", description: "Inspect a volume", flags: []),
            SubcommandSpec(name: "volume prune", description: "Remove unused volumes", flags: []),

            // Network
            SubcommandSpec(name: "network create", description: "Create a network", flags: []),
            SubcommandSpec(name: "network ls", description: "List networks", flags: []),
            SubcommandSpec(name: "network rm", description: "Remove a network", flags: []),
            SubcommandSpec(name: "network inspect", description: "Inspect a network", flags: []),

            // System
            SubcommandSpec(name: "system prune", description: "Remove unused data", flags: [
                FlagSpec(long: "--all", short: "-a", description: "Remove all unused images"),
                FlagSpec(long: "--volumes", description: "Remove volumes too"),
                FlagSpec(long: "--force", short: "-f", description: "Skip confirmation"),
            ]),
            SubcommandSpec(name: "system df", description: "Show disk usage", flags: []),
            SubcommandSpec(name: "info", description: "System-wide information", flags: []),
            SubcommandSpec(name: "version", description: "Show version", flags: []),
        ],
        globalFlags: [
            FlagSpec(long: "--help", description: "Show help"),
        ]
    )

    // MARK: - Docker Compose

    static let dockerCompose = ToolSpec(
        command: "docker compose",
        description: "Multi-container orchestration",
        subcommands: [
            SubcommandSpec(name: "up", description: "Create and start services", flags: [
                FlagSpec(long: "-d", description: "Detached mode"),
                FlagSpec(long: "--build", description: "Build images"),
                FlagSpec(long: "--force-recreate", description: "Recreate containers"),
                FlagSpec(long: "--no-deps", description: "Don't start dependencies"),
                FlagSpec(long: "--remove-orphans", description: "Remove orphans"),
                FlagSpec(long: "--scale", description: "Scale service", takesValue: true),
            ]),
            SubcommandSpec(name: "down", description: "Stop and remove containers", flags: [
                FlagSpec(long: "--volumes", short: "-v", description: "Remove volumes"),
                FlagSpec(long: "--rmi", description: "Remove images", takesValue: true, values: ["all", "local"]),
                FlagSpec(long: "--remove-orphans", description: "Remove orphans"),
            ]),
            SubcommandSpec(name: "build", description: "Build or rebuild services", flags: [
                FlagSpec(long: "--no-cache", description: "No build cache"),
                FlagSpec(long: "--pull", description: "Pull base images"),
            ]),
            SubcommandSpec(name: "logs", description: "View service logs", flags: [
                FlagSpec(long: "-f", description: "Follow output"),
                FlagSpec(long: "--tail", description: "Number of lines", takesValue: true),
                FlagSpec(long: "--timestamps", short: "-t", description: "Show timestamps"),
            ]),
            SubcommandSpec(name: "exec", description: "Execute command in service", flags: [
                FlagSpec(long: "-T", description: "Disable pseudo-TTY"),
                FlagSpec(long: "-u", description: "User", takesValue: true),
            ]),
            SubcommandSpec(name: "ps", description: "List containers", flags: []),
            SubcommandSpec(name: "pull", description: "Pull service images", flags: []),
            SubcommandSpec(name: "restart", description: "Restart services", flags: []),
            SubcommandSpec(name: "stop", description: "Stop services", flags: []),
            SubcommandSpec(name: "start", description: "Start services", flags: []),
            SubcommandSpec(name: "config", description: "Validate and view config", flags: []),
            SubcommandSpec(name: "run", description: "Run a one-off command", flags: [
                FlagSpec(long: "--rm", description: "Remove container after"),
                FlagSpec(long: "-T", description: "Disable pseudo-TTY"),
            ]),
        ],
        globalFlags: [
            FlagSpec(long: "--file", short: "-f", description: "Compose file", takesValue: true),
            FlagSpec(long: "--project-name", short: "-p", description: "Project name", takesValue: true),
        ]
    )

    /// Dynamic commands for fetching container names
    static let containerNamesCommand = "docker ps --format '{{.Names}}' 2>/dev/null"
    static let imageNamesCommand = "docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null"

    static var allSpecs: [ToolSpec] { [docker, dockerCompose] }
}
