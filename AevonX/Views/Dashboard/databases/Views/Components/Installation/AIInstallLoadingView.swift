//
//  AIInstallLoadingView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct AIInstallLoadingView: View {
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(L10n.Database.analyzingYourServer)
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
            
            Text(L10n.Database.ourAiIsDeterminingTheBestDatabaseVersionAndConfigurationForYourSystem)
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
