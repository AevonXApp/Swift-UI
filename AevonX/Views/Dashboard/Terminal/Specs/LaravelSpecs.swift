//
//  LaravelSpecs.swift
//  AevonX
//
//  Deep completion specs for PHP/Laravel tools:
//  php artisan, composer
//

import Foundation

enum LaravelSpecs {

    // MARK: - PHP Artisan

    static let artisan = ToolSpec(
        command: "artisan",
        description: "Laravel Artisan CLI",
        subcommands: [
            // Make
            SubcommandSpec(name: "make:model", description: "Create a new Eloquent model", flags: [
                FlagSpec(long: "--migration", short: "-m", description: "Create a migration file"),
                FlagSpec(long: "--controller", short: "-c", description: "Create a controller"),
                FlagSpec(long: "--factory", short: "-f", description: "Create a factory"),
                FlagSpec(long: "--seed", short: "-s", description: "Create a seeder"),
                FlagSpec(long: "--all", short: "-a", description: "Generate all"),
                FlagSpec(long: "--resource", short: "-r", description: "Resource controller"),
                FlagSpec(long: "--api", description: "API resource controller"),
                FlagSpec(long: "--pivot", description: "Pivot model"),
            ]),
            SubcommandSpec(name: "make:controller", description: "Create a new controller", flags: [
                FlagSpec(long: "--model", short: "-m", description: "Model class", takesValue: true),
                FlagSpec(long: "--resource", short: "-r", description: "Resource controller"),
                FlagSpec(long: "--api", description: "API resource"),
                FlagSpec(long: "--invokable", short: "-i", description: "Single action"),
                FlagSpec(long: "--singleton", description: "Singleton resource"),
            ]),
            SubcommandSpec(name: "make:migration", description: "Create a new migration", flags: [
                FlagSpec(long: "--create", description: "Table to create", takesValue: true),
                FlagSpec(long: "--table", description: "Table to modify", takesValue: true),
                FlagSpec(long: "--path", description: "Custom path", takesValue: true),
            ]),
            SubcommandSpec(name: "make:seeder", description: "Create a new seeder", flags: []),
            SubcommandSpec(name: "make:factory", description: "Create a new factory", flags: [
                FlagSpec(long: "--model", short: "-m", description: "Model class", takesValue: true),
            ]),
            SubcommandSpec(name: "make:middleware", description: "Create a new middleware", flags: []),
            SubcommandSpec(name: "make:request", description: "Create a new form request", flags: []),
            SubcommandSpec(name: "make:resource", description: "Create a new resource", flags: [
                FlagSpec(long: "--collection", short: "-c", description: "Resource collection"),
            ]),
            SubcommandSpec(name: "make:command", description: "Create a new Artisan command", flags: [
                FlagSpec(long: "--command", description: "Terminal command name", takesValue: true),
            ]),
            SubcommandSpec(name: "make:event", description: "Create a new event", flags: []),
            SubcommandSpec(name: "make:listener", description: "Create a new listener", flags: [
                FlagSpec(long: "--event", short: "-e", description: "Event class", takesValue: true),
            ]),
            SubcommandSpec(name: "make:job", description: "Create a new job", flags: [
                FlagSpec(long: "--sync", description: "Synchronous job"),
            ]),
            SubcommandSpec(name: "make:mail", description: "Create a new email", flags: [
                FlagSpec(long: "--markdown", short: "-m", description: "Markdown template", takesValue: true),
            ]),
            SubcommandSpec(name: "make:notification", description: "Create a notification", flags: [
                FlagSpec(long: "--markdown", short: "-m", description: "Markdown template", takesValue: true),
            ]),
            SubcommandSpec(name: "make:policy", description: "Create a new policy", flags: [
                FlagSpec(long: "--model", short: "-m", description: "Model class", takesValue: true),
            ]),
            SubcommandSpec(name: "make:provider", description: "Create a new service provider", flags: []),
            SubcommandSpec(name: "make:rule", description: "Create a new validation rule", flags: [
                FlagSpec(long: "--implicit", short: "-i", description: "Implicit rule"),
            ]),
            SubcommandSpec(name: "make:test", description: "Create a new test", flags: [
                FlagSpec(long: "--unit", description: "Unit test"),
                FlagSpec(long: "--pest", description: "Pest test"),
            ]),
            SubcommandSpec(name: "make:component", description: "Create a new view component", flags: [
                FlagSpec(long: "--inline", description: "Inline component"),
            ]),

            // Database
            SubcommandSpec(name: "migrate", description: "Run database migrations", flags: [
                FlagSpec(long: "--force", description: "Force in production"),
                FlagSpec(long: "--seed", description: "Run seeders after"),
                FlagSpec(long: "--step", description: "Migrations to run", takesValue: true),
                FlagSpec(long: "--pretend", description: "Dump SQL queries"),
                FlagSpec(long: "--path", description: "Migration path", takesValue: true),
                FlagSpec(long: "--database", description: "Database connection", takesValue: true),
            ]),
            SubcommandSpec(name: "migrate:fresh", description: "Drop all tables and re-run migrations", flags: [
                FlagSpec(long: "--seed", description: "Run seeders after"),
                FlagSpec(long: "--force", description: "Force in production"),
            ]),
            SubcommandSpec(name: "migrate:rollback", description: "Rollback the last migration", flags: [
                FlagSpec(long: "--step", description: "Steps to rollback", takesValue: true),
                FlagSpec(long: "--force", description: "Force in production"),
            ]),
            SubcommandSpec(name: "migrate:reset", description: "Rollback all migrations", flags: [
                FlagSpec(long: "--force", description: "Force in production"),
            ]),
            SubcommandSpec(name: "migrate:refresh", description: "Reset and re-run all migrations", flags: [
                FlagSpec(long: "--seed", description: "Run seeders after"),
                FlagSpec(long: "--step", description: "Steps to refresh", takesValue: true),
            ]),
            SubcommandSpec(name: "migrate:status", description: "Show migration status", flags: []),
            SubcommandSpec(name: "db:seed", description: "Seed the database", flags: [
                FlagSpec(long: "--class", description: "Seeder class", takesValue: true),
                FlagSpec(long: "--force", description: "Force in production"),
            ]),
            SubcommandSpec(name: "db:wipe", description: "Drop all tables, views, and types", flags: [
                FlagSpec(long: "--force", description: "Force in production"),
            ]),

            // Cache & Config
            SubcommandSpec(name: "cache:clear", description: "Flush the application cache", flags: []),
            SubcommandSpec(name: "config:cache", description: "Cache the configuration", flags: []),
            SubcommandSpec(name: "config:clear", description: "Remove cached config", flags: []),
            SubcommandSpec(name: "route:cache", description: "Cache the routes", flags: []),
            SubcommandSpec(name: "route:clear", description: "Remove cached routes", flags: []),
            SubcommandSpec(name: "route:list", description: "List all routes", flags: [
                FlagSpec(long: "--method", description: "Filter by method", takesValue: true),
                FlagSpec(long: "--path", description: "Filter by path", takesValue: true),
                FlagSpec(long: "--name", description: "Filter by name", takesValue: true),
            ]),
            SubcommandSpec(name: "view:cache", description: "Compile all Blade templates", flags: []),
            SubcommandSpec(name: "view:clear", description: "Clear compiled views", flags: []),
            SubcommandSpec(name: "optimize", description: "Cache config, routes, views", flags: []),
            SubcommandSpec(name: "optimize:clear", description: "Clear all cached files", flags: []),

            // Queue
            SubcommandSpec(name: "queue:work", description: "Start processing jobs", flags: [
                FlagSpec(long: "--queue", description: "Queue name", takesValue: true),
                FlagSpec(long: "--once", description: "Process one job"),
                FlagSpec(long: "--stop-when-empty", description: "Stop when queue is empty"),
                FlagSpec(long: "--timeout", description: "Job timeout seconds", takesValue: true),
                FlagSpec(long: "--tries", description: "Max attempts", takesValue: true),
                FlagSpec(long: "--memory", description: "Memory limit MB", takesValue: true),
            ]),
            SubcommandSpec(name: "queue:restart", description: "Restart queue workers", flags: []),
            SubcommandSpec(name: "queue:failed", description: "List failed jobs", flags: []),
            SubcommandSpec(name: "queue:retry", description: "Retry a failed job", flags: []),

            // Other
            SubcommandSpec(name: "serve", description: "Start development server", flags: [
                FlagSpec(long: "--host", description: "Host address", takesValue: true),
                FlagSpec(long: "--port", description: "Port number", takesValue: true),
            ]),
            SubcommandSpec(name: "tinker", description: "Interactive REPL", flags: []),
            SubcommandSpec(name: "test", description: "Run tests", flags: [
                FlagSpec(long: "--filter", description: "Filter tests", takesValue: true),
                FlagSpec(long: "--parallel", description: "Run in parallel"),
                FlagSpec(long: "--coverage", description: "Code coverage"),
            ]),
            SubcommandSpec(name: "storage:link", description: "Create storage symlink", flags: []),
            SubcommandSpec(name: "key:generate", description: "Set the application key", flags: [
                FlagSpec(long: "--force", description: "Force in production"),
            ]),
            SubcommandSpec(name: "schedule:run", description: "Run the scheduler", flags: []),
            SubcommandSpec(name: "schedule:list", description: "List scheduled tasks", flags: []),
            SubcommandSpec(name: "vendor:publish", description: "Publish vendor assets", flags: [
                FlagSpec(long: "--tag", description: "Tag to publish", takesValue: true),
                FlagSpec(long: "--force", description: "Overwrite existing"),
            ]),
            SubcommandSpec(name: "about", description: "Display application info", flags: []),
        ],
        globalFlags: [
            FlagSpec(long: "--env", description: "Environment", takesValue: true),
            FlagSpec(long: "--verbose", short: "-v", description: "Verbose output"),
            FlagSpec(long: "--no-interaction", short: "-n", description: "No prompts"),
        ]
    )

    // MARK: - Composer

    static let composer = ToolSpec(
        command: "composer",
        description: "PHP dependency manager",
        subcommands: [
            SubcommandSpec(name: "install", description: "Install dependencies", flags: [
                FlagSpec(long: "--no-dev", description: "Skip dev dependencies"),
                FlagSpec(long: "--optimize-autoloader", short: "-o", description: "Optimize autoloader"),
                FlagSpec(long: "--no-scripts", description: "Skip scripts"),
                FlagSpec(long: "--prefer-dist", description: "Prefer dist packages"),
            ]),
            SubcommandSpec(name: "require", description: "Add a package", flags: [
                FlagSpec(long: "--dev", description: "Add as dev dependency"),
                FlagSpec(long: "--no-update", description: "Skip update"),
                FlagSpec(long: "--with-all-dependencies", description: "Update all deps"),
            ]),
            SubcommandSpec(name: "update", description: "Update dependencies", flags: [
                FlagSpec(long: "--no-dev", description: "Skip dev dependencies"),
                FlagSpec(long: "--lock", description: "Only update lock file"),
                FlagSpec(long: "--with", description: "Temporary version constraint", takesValue: true),
            ]),
            SubcommandSpec(name: "remove", description: "Remove a package", flags: [
                FlagSpec(long: "--dev", description: "Remove from dev"),
            ]),
            SubcommandSpec(name: "dump-autoload", description: "Regenerate autoloader", flags: [
                FlagSpec(long: "--optimize", short: "-o", description: "Optimize"),
            ]),
            SubcommandSpec(name: "show", description: "Show package info", flags: []),
            SubcommandSpec(name: "outdated", description: "Show outdated packages", flags: []),
            SubcommandSpec(name: "validate", description: "Validate composer.json", flags: []),
        ],
        globalFlags: [
            FlagSpec(long: "--verbose", short: "-v", description: "Verbose output"),
            FlagSpec(long: "--no-interaction", short: "-n", description: "No prompts"),
        ]
    )

    static let php = ToolSpec(
        command: "php",
        description: "PHP interpreter",
        subcommands: [
            SubcommandSpec(name: "artisan", description: "Laravel Artisan CLI", flags: []),
        ],
        globalFlags: [
            FlagSpec(long: "-v", description: "Show version"),
            FlagSpec(long: "-i", description: "PHP info"),
            FlagSpec(long: "-m", description: "Show modules"),
            FlagSpec(long: "-r", description: "Run code", takesValue: true),
            FlagSpec(long: "-S", description: "Built-in server", takesValue: true),
        ]
    )

    static var allSpecs: [ToolSpec] { [artisan, composer, php] }
}
