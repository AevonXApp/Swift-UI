//
//  AIInstallErrorView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct AIInstallErrorView: View {
    let message: String
    let databaseType: DatabaseType
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axError)
            
            Text(L10n.Engine.analysisFailed)
                .font(AXTypography.headline)
                .foregroundColor(.axTextPrimary)
            
            Text(message)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            Button(L10n.Button.retry, action: onRetry)
                .font(AXTypography.subheadline)
                .foregroundColor(databaseType.brandColor)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(databaseType.brandColor.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
                .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
