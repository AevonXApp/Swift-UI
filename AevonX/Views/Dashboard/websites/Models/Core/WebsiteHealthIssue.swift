//
//  WebsiteHealthIssue.swift
//  AevonX
//
//  Website health monitoring model
//

import Foundation

// MARK: - Website Health Issue

/// Represents a health issue detected on a website
public struct WebsiteHealthIssue: Identifiable, Codable, Hashable {
    public let id: UUID
    public var severity: HealthSeverity
    public var title: String
    public var description: String
    public var recommendation: String?
    public var detectedAt: Date
    public var resolvedAt: Date?
    public var isResolved: Bool

    public init(
        id: UUID = UUID(),
        severity: HealthSeverity,
        title: String,
        description: String,
        recommendation: String? = nil,
        detectedAt: Date = Date(),
        resolvedAt: Date? = nil,
        isResolved: Bool = false
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.description = description
        self.recommendation = recommendation
        self.detectedAt = detectedAt
        self.resolvedAt = resolvedAt
        self.isResolved = isResolved
    }
}
