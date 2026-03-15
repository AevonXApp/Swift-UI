//
//  URLRewriteRule.swift
//  AevonX
//
//  UI layer extensions for URL rewrite rules
//  Core types are defined in AevonXCore
//

import Foundation

// MARK: - URL Rewrite Rule (local definition)

public struct URLRewriteRule: Codable, Sendable, Hashable, Equatable, Identifiable {
    public let id: UUID
    public var sourcePattern: String
    public var destination: String
    public var statusCode: Int
    public var flags: [String]
    public var conditions: [RewriteCondition]
    public var isEnabled: Bool
    public var order: Int
    public var notes: String?

    public init(
        id: UUID = UUID(),
        sourcePattern: String,
        destination: String,
        statusCode: Int = 301,
        flags: [String] = [],
        conditions: [RewriteCondition] = [],
        isEnabled: Bool = true,
        order: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.sourcePattern = sourcePattern
        self.destination = destination
        self.statusCode = statusCode
        self.flags = flags
        self.conditions = conditions
        self.isEnabled = isEnabled
        self.order = order
        self.notes = notes
    }
}

public struct RewriteCondition: Codable, Sendable, Hashable, Equatable, Identifiable {
    public let id: UUID
    public var test: String
    public var pattern: String
    public var flags: [String]

    public init(id: UUID = UUID(), test: String, pattern: String, flags: [String] = []) {
        self.id = id
        self.test = test
        self.pattern = pattern
        self.flags = flags
    }
}

public struct RewriteTestResult: Codable, Sendable {
    public var inputURL: String
    public var matchedRule: URLRewriteRule?
    public var finalURL: String
    public var wasRewritten: Bool
    public var statusCode: Int?
    public var executionTime: Double

    public init(inputURL: String, matchedRule: URLRewriteRule? = nil, finalURL: String, wasRewritten: Bool, statusCode: Int? = nil, executionTime: Double = 0) {
        self.inputURL = inputURL
        self.matchedRule = matchedRule
        self.finalURL = finalURL
        self.wasRewritten = wasRewritten
        self.statusCode = statusCode
        self.executionTime = executionTime
    }
}

// MARK: - UI Layer Extensions

extension URLRewriteRule {
    /// Whether this is a permanent redirect
    public var isPermanent: Bool {
        return statusCode == 301 || statusCode == 308
    }

    /// Whether this uses regex pattern
    public var isRegex: Bool {
        return sourcePattern.contains("^") || sourcePattern.contains("$") || sourcePattern.contains(".*")
    }

    /// Formatted rule type
    public var ruleType: String {
        let code = statusCode
        if code >= 300 && code < 400 {
            let permanent = (code == 301 || code == 308)
            return permanent ? "Permanent Redirect" : "Temporary Redirect"
        } else {
            return "Rewrite"
        }
    }
}

extension RewriteCondition {}

// MARK: - Rewrite Rule Template

/// Pre-built templates for common rewrite scenarios
public enum RewriteRuleTemplate: String, CaseIterable {
    // Framework Templates
    case laravel = "Laravel"
    case thinkphp = "ThinkPHP"
    case wordpress = "WordPress"
    case drupal = "Drupal"
    case codeigniter = "CodeIgniter"
    case yii = "Yii Framework"

    // Common Redirects
    case httpToHttps = "Force HTTPS"
    case wwwToNonWWW = "WWW → Non-WWW"
    case nonWWWToWWW = "Non-WWW → WWW"
    case trailingSlash = "Add Trailing Slash"
    case removeTrailingSlash = "Remove Trailing Slash"

    // Custom
    case customRedirect = "Custom Redirect"

    /// Category for organizing templates
    public var category: String {
        switch self {
        case .laravel, .thinkphp, .wordpress, .drupal, .codeigniter, .yii:
            return "Frameworks"
        case .httpToHttps, .wwwToNonWWW, .nonWWWToWWW, .trailingSlash, .removeTrailingSlash:
            return "Common"
        case .customRedirect:
            return "Custom"
        }
    }

    /// Description of what this template does
    public var description: String {
        switch self {
        case .laravel:
            return "Remove index.php and route all requests through Laravel"
        case .thinkphp:
            return "Remove index.php and route requests through ThinkPHP"
        case .wordpress:
            return "WordPress permalink structure with pretty URLs"
        case .drupal:
            return "Clean URLs for Drupal without query strings"
        case .codeigniter:
            return "Remove index.php from CodeIgniter URLs"
        case .yii:
            return "Clean URLs for Yii framework applications"
        case .httpToHttps:
            return "Force all HTTP traffic to use HTTPS protocol"
        case .wwwToNonWWW:
            return "Redirect www.example.com → example.com"
        case .nonWWWToWWW:
            return "Redirect example.com → www.example.com"
        case .trailingSlash:
            return "Add trailing slash to all URLs for consistency"
        case .removeTrailingSlash:
            return "Remove trailing slash from URLs"
        case .customRedirect:
            return "Create your own custom redirect rule"
        }
    }

    /// The actual rewrite rule code (Apache/Nginx format)
    public func getRuleCode(domain: String) -> String {
        switch self {
        case .laravel:
            return """
            # Laravel - Remove index.php
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^(.*)$ index.php/$1 [L]
            """

        case .thinkphp:
            return """
            # ThinkPHP - Remove index.php
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^(.*)$ index.php?s=/$1 [QSA,PT,L]
            """

        case .wordpress:
            return """
            # WordPress - Pretty Permalinks
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule . /index.php [L]
            """

        case .drupal:
            return """
            # Drupal - Clean URLs
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteCond %{REQUEST_URI} !=/favicon.ico
            RewriteRule ^ index.php [L]
            """

        case .codeigniter:
            return """
            # CodeIgniter - Remove index.php
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^(.*)$ index.php/$1 [L]
            """

        case .yii:
            return """
            # Yii Framework - Clean URLs
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule . index.php
            """

        case .httpToHttps:
            return """
            # Force HTTPS
            RewriteCond %{HTTPS} off
            RewriteRule ^(.*)$ https://\(domain)/$1 [R=301,L]
            """

        case .wwwToNonWWW:
            return """
            # Redirect WWW to Non-WWW
            RewriteCond %{HTTP_HOST} ^www\\.(.*)$ [NC]
            RewriteRule ^(.*)$ https://%1/$1 [R=301,L]
            """

        case .nonWWWToWWW:
            return """
            # Redirect Non-WWW to WWW
            RewriteCond %{HTTP_HOST} !^www\\. [NC]
            RewriteRule ^(.*)$ https://www.%{HTTP_HOST}/$1 [R=301,L]
            """

        case .trailingSlash:
            return """
            # Add Trailing Slash
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_URI} !(.*)/$
            RewriteRule ^(.*)$ $1/ [R=301,L]
            """

        case .removeTrailingSlash:
            return """
            # Remove Trailing Slash
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^(.*)/$ $1 [R=301,L]
            """

        case .customRedirect:
            return """
            # Custom Redirect
            RewriteRule ^old-path$ /new-path [R=301,L]
            """
        }
    }

    /// Get a pre-configured rule for this template
    public func createRule(domain: String) -> URLRewriteRule {
        switch self {
        case .laravel:
            return URLRewriteRule(
                sourcePattern: "^(.*)$",
                destination: "index.php/$1",
                statusCode: 200,
                flags: ["L"],
                conditions: [
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-f"),
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-d")
                ],
                notes: "Laravel - Remove index.php"
            )

        case .thinkphp:
            return URLRewriteRule(
                sourcePattern: "^(.*)$",
                destination: "index.php?s=/$1",
                statusCode: 200,
                flags: ["QSA", "PT", "L"],
                conditions: [
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-f"),
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-d")
                ],
                notes: "ThinkPHP - Clean URLs"
            )

        case .wordpress:
            return URLRewriteRule(
                sourcePattern: ".",
                destination: "/index.php",
                statusCode: 200,
                flags: ["L"],
                conditions: [
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-f"),
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-d")
                ],
                notes: "WordPress - Pretty Permalinks"
            )

        case .drupal:
            return URLRewriteRule(
                sourcePattern: "^",
                destination: "index.php",
                statusCode: 200,
                flags: ["L"],
                conditions: [
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-f"),
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-d"),
                    RewriteCondition(test: "%{REQUEST_URI}", pattern: "!=/favicon.ico")
                ],
                notes: "Drupal - Clean URLs"
            )

        case .codeigniter:
            return URLRewriteRule(
                sourcePattern: "^(.*)$",
                destination: "index.php/$1",
                statusCode: 200,
                flags: ["L"],
                conditions: [
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-f"),
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-d")
                ],
                notes: "CodeIgniter - Remove index.php"
            )

        case .yii:
            return URLRewriteRule(
                sourcePattern: ".",
                destination: "index.php",
                statusCode: 200,
                flags: ["L"],
                conditions: [
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-f"),
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-d")
                ],
                notes: "Yii Framework - Clean URLs"
            )

        case .httpToHttps:
            return URLRewriteRule(
                sourcePattern: "^(.*)$",
                destination: "https://\(domain)/$1",
                statusCode: 301,
                flags: ["R", "L"],
                conditions: [
                    RewriteCondition(test: "%{HTTPS}", pattern: "off")
                ],
                notes: "Force HTTPS"
            )

        case .wwwToNonWWW:
            return URLRewriteRule(
                sourcePattern: "^(.*)$",
                destination: "https://%1/$1",
                statusCode: 301,
                flags: ["R", "L"],
                conditions: [
                    RewriteCondition(test: "%{HTTP_HOST}", pattern: "^www\\.(.*)$ [NC]")
                ],
                notes: "Redirect WWW to Non-WWW"
            )

        case .nonWWWToWWW:
            return URLRewriteRule(
                sourcePattern: "^(.*)$",
                destination: "https://www.%{HTTP_HOST}/$1",
                statusCode: 301,
                flags: ["R", "L"],
                conditions: [
                    RewriteCondition(test: "%{HTTP_HOST}", pattern: "!^www\\. [NC]")
                ],
                notes: "Redirect Non-WWW to WWW"
            )

        case .trailingSlash:
            return URLRewriteRule(
                sourcePattern: "^(.*)$",
                destination: "$1/",
                statusCode: 301,
                flags: ["R", "L"],
                conditions: [
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-f"),
                    RewriteCondition(test: "%{REQUEST_URI}", pattern: "!(.*)/$")
                ],
                notes: "Add trailing slash to URLs"
            )

        case .removeTrailingSlash:
            return URLRewriteRule(
                sourcePattern: "^(.*)/$ ",
                destination: "$1",
                statusCode: 301,
                flags: ["R", "L"],
                conditions: [
                    RewriteCondition(test: "%{REQUEST_FILENAME}", pattern: "!-d")
                ],
                notes: "Remove trailing slash from URLs"
            )

        case .customRedirect:
            return URLRewriteRule(
                sourcePattern: "^old-path$",
                destination: "/new-path",
                statusCode: 301,
                flags: ["R", "L"],
                notes: "Custom redirect rule"
            )
        }
    }

    /// Icon for this template
    public var icon: String {
        switch self {
        case .laravel:
            return "l.square.fill"
        case .thinkphp:
            return "t.square.fill"
        case .wordpress:
            return "w.square.fill"
        case .drupal:
            return "d.square.fill"
        case .codeigniter:
            return "c.square.fill"
        case .yii:
            return "y.square.fill"
        case .httpToHttps:
            return "lock.shield.fill"
        case .wwwToNonWWW, .nonWWWToWWW:
            return "link.circle.fill"
        case .trailingSlash, .removeTrailingSlash:
            return "slash.circle.fill"
        case .customRedirect:
            return "arrow.turn.up.right"
        }
    }

    /// Color for template category
    public var color: String {
        switch category {
        case "Frameworks":
            return "purple"
        case "Common":
            return "blue"
        case "Custom":
            return "gray"
        default:
            return "gray"
        }
    }
}
