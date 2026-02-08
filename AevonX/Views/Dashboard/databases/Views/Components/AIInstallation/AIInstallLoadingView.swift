//
//  AIInstallLoadingView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct AIInstallLoadingView: View {
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing your server...")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextSecondary)
            
            Text("Our AI is determining the best database version and configuration for your system")
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
