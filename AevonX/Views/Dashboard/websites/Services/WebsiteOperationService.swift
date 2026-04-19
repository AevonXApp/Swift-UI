//
//  WebsiteOperationService.swift
//  AevonX
//
//  UI Layer service for managing website operations
//  Coordinates between UI and Core layer for website lifecycle management
//
//  ARCHITECTURE: UI Layer Service
//  - Uses specialized core services from Core layer for all server operations
//  - NEVER executes SSH commands directly
//

import Foundation
import Combine
import SwiftUI
import AevonXCoreBridge

// MARK: - Website Operation Service

/// Service for managing website operations in the UI layer
/// Coordinates between UI and Core layer for website lifecycle
///
/// All server operations go through specialized core services in the Core layer.
@MainActor
public final class WebsiteOperationService: ObservableObject {

    // MARK: - Singleton

    public static let shared = WebsiteOperationService()

    // MARK: - Published State

    @Published public var currentOperation: OperationProgress?
    @Published public var isOperating = false
    @Published public var operationError: OperationError?

    // MARK: - Initialization

    private init() {}

    // MARK: - Operation Progress

    public struct OperationProgress {
        public let websiteId: String
        public let operationType: OperationType
        public var status: OperationStatus
        public var message: String
        public var progress: Double // 0.0 to 1.0

        public init(
            websiteId: String,
            operationType: OperationType,
            status: OperationStatus,
            message: String,
            progress: Double = 0.0
        ) {
            self.websiteId = websiteId
            self.operationType = operationType
            self.status = status
            self.message = message
            self.progress = progress
        }
    }

    public enum OperationType {
        case create
        case delete
        case start
        case stop
        case restart
        case deploy
        case sslEnable
        case sslRenew
    }

    public enum OperationStatus {
        case pending
        case inProgress
        case completed
        case failed(String)
    }

    public enum OperationError: LocalizedError {
        case alreadyInProgress
        case operationFailed(String)

        public var errorDescription: String? {
            switch self {
            case .alreadyInProgress:
                return "Another operation is already in progress"
            case .operationFailed(let reason):
                return "Operation failed: \(reason)"
            }
        }
    }

    // MARK: - Health Check

    /// Performs health check on a website via Core layer
    public func checkWebsiteHealth(
        websiteId: String,
        serverId: String
    ) async throws -> WebsiteHealthReport {
        CoreLogger.shared.info("Checking website health for \(websiteId)",
                              module: "WebsiteOperationService")

        let coreHealth = try await WebsiteAnalyticsService.shared.checkWebsiteHealth(
            websiteId: websiteId,
            serverId: serverId
        )

        return WebsiteHealthReport(
            isReachable: coreHealth.isReachable,
            responseTime: coreHealth.responseTime,
            statusCode: coreHealth.statusCode,
            sslValid: coreHealth.sslValid,
            issues: coreHealth.issues.map { coreIssue in
                WebsiteHealthIssue(
                    severity: HealthSeverity(rawValue: coreIssue.severity.rawValue) ?? .info,
                    title: coreIssue.title,
                    description: coreIssue.description,
                    recommendation: coreIssue.recommendation
                )
            }
        )
    }

    // MARK: - SSL Operations

    /// Renews SSL certificate via Core layer
    public func renewSSL(
        websiteId: String,
        serverId: String
    ) async throws {
        guard !isOperating else {
            throw OperationError.alreadyInProgress
        }

        isOperating = true
        currentOperation = OperationProgress(
            websiteId: websiteId,
            operationType: .sslRenew,
            status: .inProgress,
            message: "Renewing SSL certificate..."
        )

        do {
            try await WebsiteSSLService.shared.renewSSL(
                websiteId: websiteId,
                serverId: serverId
            )

            currentOperation?.status = .completed
            currentOperation?.message = "SSL certificate renewed successfully"
            currentOperation?.progress = 1.0

        } catch {
            currentOperation?.status = .failed(error.localizedDescription)
            operationError = .operationFailed(error.localizedDescription)
            throw error
        }

        isOperating = false
    }
}

// MARK: - Website Health Report

public struct WebsiteHealthReport {
    public var isReachable: Bool
    public var responseTime: Double?
    public var statusCode: Int?
    public var sslValid: Bool
    public var issues: [WebsiteHealthIssue]

    public var isHealthy: Bool {
        isReachable && sslValid && issues.isEmpty
    }
}
