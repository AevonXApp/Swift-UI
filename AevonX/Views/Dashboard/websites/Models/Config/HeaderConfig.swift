//
//  HeaderConfig.swift
//  AevonX
//
//  Models for per-site HTTP response headers management
//  (CORS, CSP, X-Frame-Options, Referrer-Policy, etc.)
//

import Foundation
import SwiftUI

// MARK: - HTTP Header Type

enum HTTPHeaderType: String, CaseIterable, Identifiable {
    case cors = "CORS"
    case csp = "Content-Security-Policy"
    case xFrameOptions = "X-Frame-Options"
    case referrerPolicy = "Referrer-Policy"
    case permissionsPolicy = "Permissions-Policy"
    case hsts = "Strict-Transport-Security"
    case contentTypeOptions = "X-Content-Type-Options"
    case custom = "Custom Header"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cors: return "globe"
        case .csp: return "shield.lefthalf.filled"
        case .xFrameOptions: return "rectangle.inset.filled"
        case .referrerPolicy: return "arrow.uturn.backward"
        case .permissionsPolicy: return "hand.raised.fill"
        case .hsts: return "lock.shield.fill"
        case .contentTypeOptions: return "doc.badge.gearshape"
        case .custom: return "text.badge.plus"
        }
    }

    var color: Color {
        switch self {
        case .cors: return .blue
        case .csp: return .purple
        case .xFrameOptions: return .orange
        case .referrerPolicy: return .green
        case .permissionsPolicy: return .cyan
        case .hsts: return .red
        case .contentTypeOptions: return .axWarning
        case .custom: return .axTextSecondary
        }
    }

    var headerName: String {
        switch self {
        case .cors: return "Access-Control-Allow-Origin"
        case .csp: return "Content-Security-Policy"
        case .xFrameOptions: return "X-Frame-Options"
        case .referrerPolicy: return "Referrer-Policy"
        case .permissionsPolicy: return "Permissions-Policy"
        case .hsts: return "Strict-Transport-Security"
        case .contentTypeOptions: return "X-Content-Type-Options"
        case .custom: return ""
        }
    }

    var description: String {
        switch self {
        case .cors: return "Control which domains can access your resources"
        case .csp: return "Define allowed sources for scripts, styles, and media"
        case .xFrameOptions: return "Prevent clickjacking by controlling iframe embedding"
        case .referrerPolicy: return "Control how much referrer info is sent"
        case .permissionsPolicy: return "Control browser features (camera, microphone, etc.)"
        case .hsts: return "Force HTTPS connections for a set duration"
        case .contentTypeOptions: return "Prevent MIME type sniffing attacks"
        case .custom: return "Add any custom HTTP response header"
        }
    }
}

// MARK: - Header Entry

struct SiteHeaderEntry: Identifiable, Hashable {
    let id = UUID()
    var type: HTTPHeaderType
    var headerName: String
    var headerValue: String
    var enabled: Bool

    var nginxDirective: String {
        "add_header \(headerName) \"\(headerValue)\" always;"
    }
}

// MARK: - CORS Config

struct CORSConfig: Hashable {
    var allowOrigin: String = "*"
    var allowMethods: [String] = ["GET", "POST", "OPTIONS"]
    var allowHeaders: [String] = ["Content-Type", "Authorization"]
    var maxAge: Int = 86400
    var allowCredentials: Bool = false

    var nginxDirectives: String {
        var lines: [String] = []
        lines.append("add_header Access-Control-Allow-Origin \"\(allowOrigin)\" always;")
        lines.append("add_header Access-Control-Allow-Methods \"\(allowMethods.joined(separator: ", "))\" always;")
        lines.append("add_header Access-Control-Allow-Headers \"\(allowHeaders.joined(separator: ", "))\" always;")
        lines.append("add_header Access-Control-Max-Age \(maxAge) always;")
        if allowCredentials {
            lines.append("add_header Access-Control-Allow-Credentials true always;")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - X-Frame-Options Value

enum XFrameOptionsValue: String, CaseIterable, Identifiable {
    case deny = "DENY"
    case sameorigin = "SAMEORIGIN"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .deny: return "Prevent all iframe embedding"
        case .sameorigin: return "Allow embedding from same domain only"
        }
    }
}

// MARK: - Referrer Policy Value

enum ReferrerPolicyValue: String, CaseIterable, Identifiable {
    case noReferrer = "no-referrer"
    case noReferrerWhenDowngrade = "no-referrer-when-downgrade"
    case origin = "origin"
    case originWhenCrossOrigin = "origin-when-cross-origin"
    case sameOrigin = "same-origin"
    case strictOrigin = "strict-origin"
    case strictOriginWhenCrossOrigin = "strict-origin-when-cross-origin"
    case unsafeUrl = "unsafe-url"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .noReferrer: return "Never send referrer"
        case .noReferrerWhenDowngrade: return "No referrer on HTTPS→HTTP"
        case .origin: return "Send only the origin (domain)"
        case .originWhenCrossOrigin: return "Full URL for same-origin, origin for cross-origin"
        case .sameOrigin: return "Send only for same-origin requests"
        case .strictOrigin: return "Origin only, no downgrade"
        case .strictOriginWhenCrossOrigin: return "Full for same-origin, origin for cross, none for downgrade"
        case .unsafeUrl: return "Always send full URL (not recommended)"
        }
    }
}

// MARK: - Security Headers Audit Result

struct SecurityHeadersAudit: Identifiable {
    let id = UUID()
    let headerName: String
    var isPresent: Bool
    var value: String?
    var grade: HeaderGrade

    enum HeaderGrade: String {
        case good = "Good"
        case warning = "Warning"
        case missing = "Missing"

        var color: Color {
            switch self {
            case .good: return .axSuccess
            case .warning: return .axWarning
            case .missing: return .axError
            }
        }

        var icon: String {
            switch self {
            case .good: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .missing: return "xmark.circle.fill"
            }
        }
    }
}
