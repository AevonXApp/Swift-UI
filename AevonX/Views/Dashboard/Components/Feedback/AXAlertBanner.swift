//
//  AXAlertBanner.swift
//  AevonX
//
//  Dismissable alert/notification banner with 4 types.
//  Replaces ServiceMessageBanner, ApacheMessageBanner,
//  NginxMessageBanner, PHPMessageBanner, and inline error/warning
//  banners in 49+ files.
//

import SwiftUI

// MARK: - Alert Type

enum AXAlertType {
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

// MARK: - AXAlertBanner

struct AXAlertBanner: View {
    let message: String
    var type: AXAlertType = .info
    var isDismissable: Bool = true
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: type.icon)
                .font(.system(size: 16))
                .foregroundColor(type.color)
            
            Text(message)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .lineLimit(3)
            
            Spacer()
            
            if isDismissable {
                Button(action: { onDismiss?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AXSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(type.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(type.color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("AXAlertBanner") {
    VStack(spacing: AXSpacing.md) {
        AXAlertBanner(
            message: "Service started successfully",
            type: .success
        )
        AXAlertBanner(
            message: "Failed to update configuration: permission denied",
            type: .error
        )
        AXAlertBanner(
            message: "SSL certificate expires in 7 days",
            type: .warning
        )
        AXAlertBanner(
            message: "Service is currently being updated",
            type: .info,
            isDismissable: false
        )
    }
    .padding()
    .background(Color.axBackground)
    .frame(width: 600)
}
