//
//  AXWorkflow.swift
//  AevonX
//
//  Parametric snippet workflows — Warp-inspired command templates
//  with {{placeholder}} parameters that prompt the user before execution.
//
//  Usage: Workflows are saved snippets with named parameters.
//  Example: "docker logs --tail {{lines:100}} -f {{container}}"
//

import Foundation
import Combine
import AevonXCoreBridge

// MARK: - Workflow Parameter

struct AXWorkflowParameter: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let defaultValue: String?
    let description: String?

    init(name: String, defaultValue: String? = nil, description: String? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.defaultValue = defaultValue
        self.description = description
    }
}

// MARK: - Workflow

struct AXWorkflow: Identifiable, Equatable, Codable {
    let id: String
    var name: String
    var template: String
    var category: String
    var icon: String
    var description: String?
    var parameters: [AXWorkflowParameter]

    init(
        name: String,
        template: String,
        category: String = "General",
        icon: String = "terminal",
        description: String? = nil
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.template = template
        self.category = category
        self.icon = icon
        self.description = description
        self.parameters = Self.extractParameters(from: template)
    }

    /// Parse `{{name}}` or `{{name:default}}` placeholders from template.
    static func extractParameters(from template: String) -> [AXWorkflowParameter] {
        let pattern = "\\{\\{([^}]+)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        var seen = Set<String>()
        var params: [AXWorkflowParameter] = []

        for match in matches {
            guard let range = Range(match.range(at: 1), in: template) else { continue }
            let content = String(template[range])

            let parts = content.split(separator: ":", maxSplits: 1).map(String.init)
            let name = parts[0].trimmingCharacters(in: .whitespaces)
            let defaultVal = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil

            guard !seen.contains(name) else { continue }
            seen.insert(name)
            params.append(AXWorkflowParameter(name: name, defaultValue: defaultVal))
        }

        return params
    }

    /// Resolve template by substituting parameter values.
    func resolve(values: [String: String]) -> String {
        var result = template
        for param in parameters {
            let value = values[param.name] ?? param.defaultValue ?? ""
            // Replace all occurrences of {{name}} and {{name:default}}
            let patterns = ["{{" + param.name + "}}", "{{" + param.name + ":" + (param.defaultValue ?? "") + "}}"]
            for pattern in patterns {
                result = result.replacingOccurrences(of: pattern, with: value)
            }
        }
        return result
    }

    /// Convert to a plain CommandSnippet (for compatibility with existing snippet system).
    func toSnippet(values: [String: String]) -> CommandSnippet {
        CommandSnippet(
            name: name,
            command: resolve(values: values),
            category: category,
            icon: icon
        )
    }
}

// MARK: - Workflow Manager

@MainActor
final class AXWorkflowManager: ObservableObject {
    static let shared = AXWorkflowManager()

    @Published var workflows: [AXWorkflow] = []

    private let storageKey = "terminal.workflows"

    private init() {
        loadWorkflows()
        if workflows.isEmpty {
            workflows = Self.builtInWorkflows
            saveWorkflows()
        }
    }

    func addWorkflow(_ workflow: AXWorkflow) {
        workflows.append(workflow)
        saveWorkflows()
    }

    func deleteWorkflow(_ workflow: AXWorkflow) {
        workflows.removeAll { $0.id == workflow.id }
        saveWorkflows()
    }

    func updateWorkflow(_ workflow: AXWorkflow) {
        if let idx = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[idx] = workflow
            saveWorkflows()
        }
    }

    private func saveWorkflows() {
        if let data = try? JSONEncoder().encode(workflows) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadWorkflows() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loaded = try? JSONDecoder().decode([AXWorkflow].self, from: data) else { return }
        workflows = loaded
    }

    // MARK: - Built-in Workflows

    static let builtInWorkflows: [AXWorkflow] = [
        // Docker
        AXWorkflow(
            name: "Docker Logs (Follow)",
            template: "docker logs --tail {{lines:100}} -f {{container}}",
            category: "Docker",
            icon: "shippingbox",
            description: "Follow container logs with tail limit"
        ),
        AXWorkflow(
            name: "Docker Exec Shell",
            template: "docker exec -it {{container}} {{shell:/bin/bash}}",
            category: "Docker",
            icon: "shippingbox",
            description: "Open interactive shell in container"
        ),
        AXWorkflow(
            name: "Docker Compose Up",
            template: "docker compose -f {{file:docker-compose.yml}} up -d {{service}}",
            category: "Docker",
            icon: "shippingbox",
            description: "Start service with compose file"
        ),

        // Git
        AXWorkflow(
            name: "Git Checkout Branch",
            template: "git checkout -b {{branch}} {{base:main}}",
            category: "Git",
            icon: "arrow.triangle.branch",
            description: "Create and switch to new branch"
        ),
        AXWorkflow(
            name: "Git Interactive Rebase",
            template: "git rebase -i HEAD~{{commits:5}}",
            category: "Git",
            icon: "arrow.triangle.branch",
            description: "Interactive rebase last N commits"
        ),
        AXWorkflow(
            name: "Git Cherry-Pick",
            template: "git cherry-pick {{commit_hash}}",
            category: "Git",
            icon: "arrow.triangle.branch",
            description: "Cherry-pick a specific commit"
        ),

        // Laravel
        AXWorkflow(
            name: "Artisan Make Model",
            template: "php artisan make:model {{name}} -mcrf",
            category: "Laravel",
            icon: "chevron.left.forwardslash.chevron.right",
            description: "Create model with migration, controller, resource, factory"
        ),
        AXWorkflow(
            name: "Artisan Migrate Fresh Seed",
            template: "php artisan migrate:fresh --seed --seeder={{seeder:DatabaseSeeder}}",
            category: "Laravel",
            icon: "chevron.left.forwardslash.chevron.right",
            description: "Fresh migrate with specific seeder"
        ),

        // System
        AXWorkflow(
            name: "Find Large Files",
            template: "find {{path:/}} -type f -size +{{size:100M}} -exec ls -lh {} + | sort -k5 -rh | head -{{count:20}}",
            category: "System",
            icon: "internaldrive",
            description: "Find files larger than specified size"
        ),
        AXWorkflow(
            name: "Port Check",
            template: "ss -tlnp | grep :{{port}}",
            category: "Network",
            icon: "network",
            description: "Check what's listening on a port"
        ),
        AXWorkflow(
            name: "SSH Tunnel",
            template: "ssh -L {{local_port}}:{{remote_host:localhost}}:{{remote_port}} {{user}}@{{server}}",
            category: "Network",
            icon: "lock.shield",
            description: "Create SSH tunnel for port forwarding"
        ),

        // Database
        AXWorkflow(
            name: "MySQL Dump",
            template: "mysqldump -u {{user:root}} -p {{database}} > {{output:backup.sql}}",
            category: "Database",
            icon: "cylinder",
            description: "Export MySQL database to file"
        ),
        AXWorkflow(
            name: "Redis CLI Select DB",
            template: "redis-cli -n {{db:0}} -h {{host:localhost}} -p {{port:6379}}",
            category: "Database",
            icon: "cylinder",
            description: "Connect to specific Redis database"
        ),
    ]
}
