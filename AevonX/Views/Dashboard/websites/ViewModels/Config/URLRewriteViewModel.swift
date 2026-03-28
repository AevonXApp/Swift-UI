//
//  URLRewriteViewModel.swift
//  AevonX
//
//  ViewModel for URL Rewrite management section — uses Go Core bridge
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
public final class URLRewriteViewModel: ObservableObject {
    // MARK: - Properties

    @Published public var rules: [URLRewriteRule] = []
    @Published public var isLoading: Bool = false
    @Published public var error: String?

    // Rule editing
    @Published public var isEditingRule: Bool = false
    @Published public var selectedRule: URLRewriteRule?
    @Published public var showTemplateSheet: Bool = false

    // Testing
    @Published public var testURL: String = ""
    @Published public var testResult: RewriteTestResult?
    @Published public var isTesting: Bool = false

    private let website: WebsiteInfo
    private let serverId: String?
    private let bridge = WebsitesBridge.shared
    private let toastManager = GlobalToastManager.shared
    private var engine: String { website.webServerEngine ?? "nginx" }

    // MARK: - Initialization

    public init(website: WebsiteInfo, serverId: String?) {
        self.website = website
        self.serverId = serverId
    }

    // MARK: - Go Bridge Model

    /// Matches Go's RewriteRule JSON: id, pattern, target, type, is_active
    private struct GoRewriteRule: Decodable {
        let id: String
        let pattern: String?
        let target: String
        let type: String
        let is_active: Bool // swiftlint:disable:this identifier_name

        func toLocal(order: Int) -> URLRewriteRule {
            let statusCode: Int
            switch type {
            case "301": statusCode = 301
            case "302": statusCode = 302
            default: statusCode = 200
            }
            return URLRewriteRule(
                sourcePattern: pattern ?? "",
                destination: target,
                statusCode: statusCode,
                isEnabled: is_active,
                order: order
            )
        }
    }

    // MARK: - Data Loading

    public func load() async {
        guard let serverId = serverId else {
            error = "No server ID available"
            return
        }

        isLoading = true
        error = nil

        let cmd = bridge.getRewriteRulesCmd(domain: website.domain)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseRewriteRules(output: result)

        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let rulesData = resp["data"] {
            if JSONSerialization.isValidJSONObject(rulesData),
               let rulesJSON = try? JSONSerialization.data(withJSONObject: rulesData),
               let goRules = try? JSONDecoder().decode([GoRewriteRule].self, from: rulesJSON) {
                rules = goRules.enumerated().map { $1.toLocal(order: $0) }
            }
        }

        isLoading = false
    }

    // MARK: - Rule Management

    public func addRule(_ rule: URLRewriteRule) async {
        guard let serverId = serverId else { return }

        isLoading = true

        let ruleType: String
        switch rule.statusCode {
        case 301: ruleType = "301"
        case 302: ruleType = "302"
        default: ruleType = "rewrite"
        }

        let cmd = bridge.addRewriteRuleCmd(domain: website.domain, source: rule.sourcePattern, destination: rule.destination, flags: ruleType)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.reloadEngineCmd(engine: engine, serverID: serverId ?? ""))
        await load()
        toastManager.showSuccess("Rewrite rule added successfully")

        isLoading = false
    }

    public func updateRule(_ ruleId: UUID, with newRule: URLRewriteRule) async {
        guard let serverId = serverId else { return }
        guard let idx = rules.firstIndex(where: { $0.id == ruleId }) else {
            toastManager.showError("Rule not found")
            return
        }

        isLoading = true

        // Delete old and add new
        let deleteCmd = bridge.deleteRewriteRuleCmd(domain: website.domain, ruleIndex: idx)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: deleteCmd)
        let addCmd = bridge.addRewriteRuleCmd(domain: website.domain, source: newRule.sourcePattern, destination: newRule.destination, flags: newRule.flags.joined(separator: ","))
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: addCmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.reloadEngineCmd(engine: engine, serverID: serverId ?? ""))
        await load()
        toastManager.showSuccess("Rewrite rule updated successfully")

        isLoading = false
    }

    public func deleteRule(_ ruleId: UUID) async {
        guard let serverId = serverId else { return }
        guard let idx = rules.firstIndex(where: { $0.id == ruleId }) else {
            toastManager.showError("Rule not found")
            return
        }

        isLoading = true

        let cmd = bridge.deleteRewriteRuleCmd(domain: website.domain, ruleIndex: idx)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.reloadEngineCmd(engine: engine, serverID: serverId ?? ""))
        rules.removeAll { $0.id == ruleId }
        toastManager.showSuccess("Rewrite rule deleted successfully")

        isLoading = false
    }

    public func toggleRule(_ ruleId: UUID) async {
        guard let index = rules.firstIndex(where: { $0.id == ruleId }) else { return }

        var rule = rules[index]
        rule.isEnabled.toggle()

        await updateRule(ruleId, with: rule)
    }

    // MARK: - Templates

    public func applyTemplate(_ template: RewriteRuleTemplate) async {
        let rule = template.createRule(domain: website.domain)
        await addRule(rule)
    }

    // MARK: - Testing

    public func testRewrite() async {
        guard let serverId = serverId else { return }
        guard !testURL.isEmpty else {
            error = "Please enter a URL to test"
            return
        }

        isTesting = true
        testResult = nil

        let cmd = bridge.testRewriteCmd(domain: website.domain, testURL: testURL)
        let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
        let parsedJSON = bridge.parseTestRewrite(output: result)

        if let data = parsedJSON.data(using: .utf8),
           let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           resp["success"] as? Bool == true,
           let testData = resp["data"] as? [String: Any] {
            let wasRewritten = testData["was_rewritten"] as? Bool ?? false
            let resultURL = testData["result_url"] as? String
            testResult = RewriteTestResult(inputURL: testURL, finalURL: resultURL ?? testURL, wasRewritten: wasRewritten)
            toastManager.showSuccess(wasRewritten ? "URL was rewritten" : "URL was not rewritten")
        }

        isTesting = false
    }

    // MARK: - Helpers

    public func clearError() {
        error = nil
    }

    public func clearTestResult() {
        testResult = nil
        testURL = ""
    }
}
