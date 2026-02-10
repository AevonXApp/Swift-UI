//
//  URLRewriteViewModel.swift
//  AevonX
//
//  ViewModel for URL Rewrite management section
//

import SwiftUI
import Combine
import AevonXCore

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
    private let coreService = CoreWebsiteService.shared
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
            rules = try await coreService.getRewriteRules(domain: website.domain, serverId: serverId)
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
            try await coreService.addRewriteRule(domain: website.domain, rule: rule, serverId: serverId)
            await load() // Reload rules
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
            try await coreService.updateRewriteRule(domain: website.domain, ruleId: ruleId, rule: newRule, serverId: serverId)
            await load() // Reload rules
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
            try await coreService.deleteRewriteRule(domain: website.domain, ruleId: ruleId, serverId: serverId)
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
            testResult = try await coreService.testRewriteRule(domain: website.domain, testURL: testURL, serverId: serverId)

            if testResult?.wasRewritten == true {
                toastManager.showSuccess("URL was rewritten")
            } else {
                toastManager.showInfo("URL was not rewritten")
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
