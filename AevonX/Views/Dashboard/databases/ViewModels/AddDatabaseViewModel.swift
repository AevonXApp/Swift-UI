//
//  AddDatabaseViewModel.swift
//  AevonX
//
//  ViewModel for the Add Database form
//  Handles validation, password generation, and multi-step creation
//

import Foundation
import SwiftUI
import AevonXCore
import Combine

@MainActor
public final class AddDatabaseViewModel: ObservableObject {

    // MARK: - Form Fields

    @Published public var databaseName = ""
    @Published public var username = ""
    @Published public var password = ""
    @Published public var host = "localhost"
    @Published public var selectedType: DatabaseType?
    @Published public var selectedCharset = "utf8mb4"
    @Published public var selectedCollation = "utf8mb4_unicode_ci"
    @Published public var forceSSL = false
    @Published public var shouldCreateUser = true
    @Published public var grantAllPrivileges = true
    @Published public var showPassword = false

    // MARK: - Validation Errors

    @Published public var nameError: String?
    @Published public var usernameError: String?
    @Published public var passwordError: String?

    // MARK: - State

    @Published public var installedEngines: [DatabaseInstallationState] = []
    @Published public var operationResult: OperationResult = .idle
    @Published public var isSubmitting = false
    @Published public var didSucceed = false

    // MARK: - Server

    private let serverId: String?

    // MARK: - Init

    public init(serverId: String?, installationStates: [DatabaseInstallationState]) {
        self.serverId = serverId
        loadInstalledEngines(from: installationStates)
        generatePassword()
    }

    // MARK: - Engine Loading

    private func loadInstalledEngines(from states: [DatabaseInstallationState]) {
        installedEngines = states.filter { $0.isInstalled && $0.type.supportsMultipleDatabases }
        if selectedType == nil, let first = installedEngines.first {
            selectedType = first.type
            updateDefaultsForEngine(first.type)
        }
    }

    public func selectEngine(_ type: DatabaseType) {
        selectedType = type
        updateDefaultsForEngine(type)
    }

    private func updateDefaultsForEngine(_ type: DatabaseType) {
        let charsets = charsetOptions(for: type)
        if !charsets.contains(selectedCharset) {
            selectedCharset = charsets.first ?? "utf8"
        }
        let collations = collationOptions(for: type, charset: selectedCharset)
        if !collations.contains(selectedCollation) {
            selectedCollation = collations.first ?? "default"
        }
    }

    // MARK: - Charset / Collation Options

    public func charsetOptions(for type: DatabaseType) -> [String] {
        switch type {
        case .mysql, .mariadb:
            return ["utf8mb4", "utf8", "latin1", "ascii", "binary", "utf16", "utf32"]
        case .postgresql:
            return ["UTF8", "LATIN1", "SQL_ASCII", "WIN1252"]
        case .cockroachdb:
            return ["UTF8"]
        case .mongodb, .redis, .cassandra, .elasticsearch:
            return ["UTF-8"]
        case .sqlite:
            return ["UTF-8", "UTF-16"]
        case .unknown:
            return ["utf8"]
        }
    }

    public func collationOptions(for type: DatabaseType, charset: String) -> [String] {
        switch type {
        case .mysql, .mariadb:
            switch charset {
            case "utf8mb4":
                return ["utf8mb4_unicode_ci", "utf8mb4_general_ci", "utf8mb4_bin", "utf8mb4_unicode_520_ci"]
            case "utf8":
                return ["utf8_unicode_ci", "utf8_general_ci", "utf8_bin"]
            case "latin1":
                return ["latin1_swedish_ci", "latin1_general_ci", "latin1_bin"]
            default:
                return ["default"]
            }
        case .postgresql:
            switch charset {
            case "UTF8":
                return ["en_US.UTF-8", "C", "POSIX", "C.UTF-8"]
            default:
                return ["default"]
            }
        default:
            return ["default"]
        }
    }

    public var availableCharsets: [String] {
        guard let type = selectedType else { return ["utf8mb4"] }
        return charsetOptions(for: type)
    }

    public var availableCollations: [String] {
        guard let type = selectedType else { return ["utf8mb4_unicode_ci"] }
        return collationOptions(for: type, charset: selectedCharset)
    }

    // MARK: - Host Options

    public let hostOptions = ["localhost", "%", "127.0.0.1"]

    // MARK: - Password Generation

    public func generatePassword() {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        password = String((0..<20).map { _ in chars.randomElement()! })
        passwordError = nil
    }

    // MARK: - Validation

    public func validateDatabaseName() {
        let name = databaseName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            nameError = nil
            return
        }

        // Redis specific validation
        if selectedType == .redis {
            // Check if it's a number 0-15 or db0-db15
            let numStr = name.hasPrefix("db") ? String(name.dropFirst(2)) : name
            if let num = Int(numStr), num >= 0 && num <= 15 {
                nameError = nil
            } else {
                nameError = "Redis databases must be numbered 0-15 (e.g. '0' or 'db0')"
            }
            return
        }

        if name.count > 64 {
            nameError = "Name must be 64 characters or fewer"
            return
        }
        let pattern = "^[a-zA-Z_][a-zA-Z0-9_]*$"
        if name.range(of: pattern, options: .regularExpression) == nil {
            nameError = "Only letters, numbers, and underscores allowed. Must start with a letter or underscore."
            return
        }
        let reserved = ["mysql", "information_schema", "performance_schema", "sys", "postgres", "template0", "template1"]
        if reserved.contains(name.lowercased()) {
            nameError = "'\(name)' is a reserved database name"
            return
        }
        nameError = nil
    }

    public func validateUsername() {
        let user = username.trimmingCharacters(in: .whitespaces)
        if user.isEmpty {
            usernameError = nil
            return
        }
        if user.count > 32 {
            usernameError = "Username must be 32 characters or fewer"
            return
        }
        let pattern = "^[a-zA-Z_][a-zA-Z0-9_]*$"
        if user.range(of: pattern, options: .regularExpression) == nil {
            usernameError = "Only letters, numbers, and underscores allowed"
            return
        }
        let reserved = ["root", "admin", "mysql", "postgres", "dba"]
        if reserved.contains(user.lowercased()) {
            usernameError = "'\(user)' is a reserved username"
            return
        }
        usernameError = nil
    }

    public func validatePassword() {
        if password.isEmpty {
            passwordError = nil
            return
        }
        if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
            return
        }
        passwordError = nil
    }

    public var isFormValid: Bool {
        let nameOk = !databaseName.trimmingCharacters(in: .whitespaces).isEmpty && nameError == nil
        if !shouldCreateUser {
            return nameOk && selectedType != nil
        }
        let userOk = !username.trimmingCharacters(in: .whitespaces).isEmpty && usernameError == nil
        let passOk = !password.isEmpty && passwordError == nil
        return nameOk && userOk && passOk && selectedType != nil
    }

    // MARK: - Submit

    public func submitForm() async {
        guard let serverId = serverId, let type = selectedType else { return }

        isSubmitting = true
        operationResult = .inProgress(message: "Creating database '\(databaseName)'...", progress: nil)

        do {
            // Step 1: Create the database
            try await DatabaseManagementService.shared.createDatabase(
                name: databaseName,
                type: type.rawValue,
                characterSet: selectedCharset == "default" ? nil : selectedCharset,
                collation: selectedCollation == "default" ? nil : selectedCollation,
                serverId: serverId
            )

            // Step 2: Create user if requested
            if shouldCreateUser {
                operationResult = .inProgress(message: "Creating user '\(username)'...", progress: nil)

                try await DatabaseUserService.shared.createUser(
                    username: username,
                    password: password,
                    host: host,
                    databaseType: type,
                    serverId: serverId
                )

                // Step 3: Grant privileges
                if grantAllPrivileges {
                    operationResult = .inProgress(message: "Granting privileges...", progress: nil)

                    try await DatabaseUserService.shared.grantPrivileges(
                        username: username,
                        host: host,
                        database: databaseName,
                        privileges: ["ALL PRIVILEGES"],
                        databaseType: type,
                        serverId: serverId
                    )
                }
            }

            operationResult = .success(message: "Database '\(databaseName)' created successfully!")
            didSucceed = true

        } catch {
            operationResult = .failure(message: error.localizedDescription)
            didSucceed = false
        }

        isSubmitting = false
    }
}
