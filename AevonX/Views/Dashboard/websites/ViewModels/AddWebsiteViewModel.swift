//
//  AddWebsiteViewModel.swift
//  AevonX
//
//  ViewModel for adding new websites
//  Handles validation and creation via Core layer
//

import Foundation
import SwiftUI
import Combine
import AevonXCore

// MARK: - Add Website ViewModel

@MainActor
public final class AddWebsiteViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published public var domain = ""
    @Published public var name = ""
    @Published public var phpVersion = "8.2"
    @Published public var runtime: RuntimeType = .php
    @Published public var enableSSL = true
    @Published public var environment: EnvironmentType = .production
    @Published public var documentRoot = ""

    @Published public var isCreating = false
    @Published public var errorMessage: String?
    @Published public var validationErrors: [String: String] = [:]

    // MARK: - Properties

    private let serverId: String?

    // MARK: - Initialization

    public init(serverId: String?) {
        self.serverId = serverId
    }

    // MARK: - Validation

    /// Validates all form fields
    public func validate() -> Bool {
        validationErrors.removeAll()

        // Validate domain
        if domain.isEmpty {
            validationErrors["domain"] = "Domain is required"
        } else if !isValidDomain(domain) {
            validationErrors["domain"] = "Invalid domain format"
        }

        // Validate name
        if name.isEmpty {
            name = domain // Auto-generate from domain
        }

        return validationErrors.isEmpty
    }

    /// Validates domain format
    private func isValidDomain(_ domain: String) -> Bool {
        // Basic domain validation
        let domainRegex = "^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)
        return predicate.evaluate(with: domain)
    }

    // MARK: - Website Creation

    /// Creates website via Core layer
    public func createWebsite() async throws {
        guard validate() else {
            throw AddWebsiteError.validationFailed
        }

        guard let serverId = serverId else {
            throw AddWebsiteError.serverNotConfigured
        }

        isCreating = true
        errorMessage = nil

        do {
            try await CoreWebsiteService.shared.createWebsite(
                name: name,
                domain: domain,
                phpVersion: runtime == .php ? phpVersion : nil,
                runtime: CoreRuntimeType(rawValue: runtime.rawValue) ?? .php,
                enableSSL: enableSSL,
                documentRoot: documentRoot.isEmpty ? nil : documentRoot,
                serverId: serverId
            )

            CoreLogger.shared.info("Website '\(name)' created successfully",
                                  module: "AddWebsiteViewModel")

        } catch {
            CoreLogger.shared.error("Failed to create website: \(error.localizedDescription)",
                                   module: "AddWebsiteViewModel")
            errorMessage = error.localizedDescription
            throw error
        }

        isCreating = false
    }

    // MARK: - Available Options

    /// Available PHP versions
    public var availablePHPVersions: [String] {
        ["8.3", "8.2", "8.1", "8.0", "7.4"]
    }

    /// Available runtime types
    public var availableRuntimes: [RuntimeType] {
        RuntimeType.allCases
    }
}

// MARK: - Add Website Error

public enum AddWebsiteError: LocalizedError {
    case validationFailed
    case serverNotConfigured
    case creationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .validationFailed:
            return "Please fix validation errors"
        case .serverNotConfigured:
            return "Server not configured"
        case .creationFailed(let reason):
            return "Failed to create website: \(reason)"
        }
    }
}
