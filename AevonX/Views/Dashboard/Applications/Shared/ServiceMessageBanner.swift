//
//  ServiceMessageBanner.swift
//  AevonX
//
//  Unified message banner component for all service engines
//  Replaces PHPMessageBanner, NginxMessageBanner, and database-specific banners
//

import SwiftUI
import AevonXCore

/// Unified message banner for all service engines (PHP, Nginx, databases, etc.)
struct ServiceMessageBanner: View {
    let message: String
    let type: MessageType
    let onDismiss: () -> Void

    enum MessageType {
        case success
        case error
        case warning
        case info

        var color: Color {
            switch self {
            case .success: return .axSuccess
            case .error: return .axError
            case .warning: return .orange
            case .info: return .axAccentBlue
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: type.icon)
                .font(.system(size: 16))
                .foregroundColor(type.color)

            Text(message)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.axTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.md)
        .background(type.color.opacity(0.1))
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, AXSpacing.xl)
        .padding(.top, AXSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AXSpacing.lg) {
        ServiceMessageBanner(
            message: "Service started successfully",
            type: .success,
            onDismiss: {}
        )

        ServiceMessageBanner(
            message: "Failed to update configuration",
            type: .error,
            onDismiss: {}
        )

        ServiceMessageBanner(
            message: "Configuration validation warning",
            type: .warning,
            onDismiss: {}
        )

        ServiceMessageBanner(
            message: "Service is currently being updated",
            type: .info,
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.axBackground)
}
