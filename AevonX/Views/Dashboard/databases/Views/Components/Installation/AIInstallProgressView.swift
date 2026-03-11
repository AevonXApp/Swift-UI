//
//  AIInstallProgressView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct AIInstallProgressView: View {
    let databaseType: DatabaseType
    let progress: Double
    let stepTitle: String
    let stepDescription: String
    let logs: [InstallationLog]
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            // Progress indicator
            VStack(spacing: AXSpacing.lg) {
                ProgressView(value: progress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 400)
                
                HStack {
                    Text("\(Int(progress))%")
                        .font(AXTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(databaseType.brandColor)
                    
                    Spacer()
                    
                    Text(stepTitle)
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextSecondary)
                }
                .frame(width: 400)
            }
            
            // Current step description
            Text(stepDescription)
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            // Log output
            AIInstallLogView(logs: logs)
            
            Spacer()
            
            // Cancel button
            Button("Cancel Installation", action: onCancel)
                .font(AXTypography.subheadline)
                .foregroundColor(.axError)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axError.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
                .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
