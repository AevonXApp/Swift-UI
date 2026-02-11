//
//  ApacheMessageBanner.swift
//  AevonX
//
//  Message banner for Apache views
//

import SwiftUI

struct ApacheMessageBanner: View {
    let message: String
    let type: BannerType
    let onDismiss: () -> Void
    
    enum BannerType {
        case success
        case error
        case warning
        
        var color: Color {
            switch self {
            case .success: return .axSuccess
            case .error: return .axError
            case .warning: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.axTextTertiary)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.md)
        .background(type.color.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(type.color.opacity(0.2)),
            alignment: .bottom
        )
    }
}
