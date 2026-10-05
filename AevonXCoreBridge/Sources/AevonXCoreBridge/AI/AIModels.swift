//
//  AIModels.swift
//  AevonXCoreBridge
//
//  Codable models for AI error resolution matching Go Core JSON output.
//

import Foundation

// MARK: - AI Error Resolution

/// AI error analysis result from Go Core.
public struct BridgeAIErrorResolution: Codable, Sendable {
    public let errorId: String
    public let analysis: String
    public let rootCause: String
    public let severity: String
    public let solutions: [BridgeAIErrorSolution]
    public let canRetry: Bool

    private enum CodingKeys: String, CodingKey {
        case analysis, severity, solutions
        case errorId = "error_id"
        case rootCause = "root_cause"
        case canRetry = "can_retry"
    }
}

/// AI error solution.
public struct BridgeAIErrorSolution: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let command: String?
    public let isAutomated: Bool
    public let estimatedFixTime: Int
    public let riskLevel: String

    private enum CodingKeys: String, CodingKey {
        case id, title, description, command
        case isAutomated = "is_automated"
        case estimatedFixTime = "estimated_fix_time"
        case riskLevel = "risk_level"
    }
}

// MARK: - AI Installation

/// AI installation progress from Go Core.
public struct BridgeInstallProgress: Codable, Sendable {
    public let installationId: String
    public let databaseType: String
    public let selectedVersion: String
    public let currentStep: Int
    public let totalSteps: Int
    public let status: String
    public let currentStepTitle: String
    public let progressPercentage: Double

    private enum CodingKeys: String, CodingKey {
        case databaseType, selectedVersion, currentStep
        case totalSteps, status, progressPercentage
        case installationId = "installation_id"
        case currentStepTitle = "current_step_title"
    }
}
