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

    // MARK: - Initialization

    public init(website: WebsiteInfo, serverId: String?) {
        self.website = website
        self.serverId = serverId
    }

    // MARK: - Data Loading

    public func load() async {
        guard let serverId = serverId else {
            error = "No server ID available"
            return
        }

        isLoading = true
        error = nil

        do {
            let cmd = bridge.getRewriteRulesCmd(domain: website.domain)
            let result = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            let parsedJSON = bridge.parseRewriteRules(output: result)

            if let data = parsedJSON.data(using: .utf8),
               let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               resp["success"] as? Bool == true,
               let rulesData = resp["data"] {
                // Guard: rulesData must be an Array or Dict for JSONSerialization
                if JSONSerialization.isValidJSONObject(rulesData),
                   let rulesJSON = try? JSONSerialization.data(withJSONObject: rulesData),
                   let decoded = try? JSONDecoder().decode([URLRewriteRule].self, from: rulesJSON) {
                    rules = decoded
                }
            }
        } catch {
            self.error = "Failed to load rewrite rules: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isLoading = false
    }

    // MARK: - Rule Management

    public func addRule(_ rule: URLRewriteRule) async {
        guard let serverId = serverId else { return }

        isLoading = true

        do {
            let cmd = bridge.addRewriteRuleCmd(domain: website.domain, source: rule.sourcePattern, destination: rule.destination, flags: rule.flags.joined(separator: ","))
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            await load()
            toastManager.showSuccess("Rewrite rule added successfully")
        } catch {
            self.error = "Failed to add rule: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isLoading = false
    }

    public func updateRule(_ ruleId: UUID, with newRule: URLRewriteRule) async {
        guard let serverId = serverId else { return }

        isLoading = true

        do {
            // Delete old and add new
            let deleteCmd = bridge.deleteRewriteRuleCmd(domain: website.domain, ruleIndex: rules.firstIndex(where: { $0.id == ruleId }) ?? 0)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: deleteCmd)
            let addCmd = bridge.addRewriteRuleCmd(domain: website.domain, source: newRule.sourcePattern, destination: newRule.destination, flags: newRule.flags.joined(separator: ","))
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: addCmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            await load()
            toastManager.showSuccess("Rewrite rule updated successfully")
        } catch {
            self.error = "Failed to update rule: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

        isLoading = false
    }

    public func deleteRule(_ ruleId: UUID) async {
        guard let serverId = serverId else { return }

        isLoading = true

        do {
            let idx = rules.firstIndex(where: { $0.id == ruleId }) ?? 0
            let cmd = bridge.deleteRewriteRuleCmd(domain: website.domain, ruleIndex: idx)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: cmd)
            _ = await SSHBridge.shared.executeAsync(serverID: serverId, command: bridge.restartNginxCmd())
            rules.removeAll { $0.id == ruleId }
            toastManager.showSuccess("Rewrite rule deleted successfully")
        } catch {
            self.error = "Failed to delete rule: \(error.localizedDescription)"
            toastManager.showError(self.error!)
        }

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

        do {
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
        } catch {
            self.error = "Failed to test rule: \(error.localizedDescription)"
            toastManager.showError(self.error!)
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
