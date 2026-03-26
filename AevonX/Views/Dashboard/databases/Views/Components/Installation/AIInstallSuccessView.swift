//
//  AIInstallSuccessView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct AIInstallSuccessView: View {
    let databaseType: DatabaseType
    let stepDescription: String
    let logs: [InstallationLog]
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axSuccess)
            
            VStack(spacing: AXSpacing.md) {
                Text("Installation Successful!")
                    .font(AXTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                
                Text(stepDescription)
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            AIInstallLogView(logs: logs)
            
            Button(L10n.Button.done, action: onDone)
                .font(AXTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xxl)
                .padding(.vertical, AXSpacing.md)
                .background(databaseType.brandColor)
                .cornerRadius(AXCornerRadius.md)
                .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
