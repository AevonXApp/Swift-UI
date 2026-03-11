//
//  AIInstallLogView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct AIInstallLogView: View {
    let logs: [InstallationLog]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                ForEach(logs) { log in
                    HStack(spacing: AXSpacing.xs) {
                        let levelText = log.level.rawValue.uppercased()
                        Text("[") + Text(levelText) + Text("]")
                            .font(AXTypography.caption2)
                            .foregroundColor(logLevelColor(log.level))
                        
                        Text(log.message)
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AXSpacing.md)
        }
        .frame(width: 500, height: 200)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
    }

    private func logLevelColor(_ level: InstallationLogLevel) -> Color {
        switch level {
        case .debug:
            return .axTextMuted
        case .info:
            return .axInfo
        case .warning:
            return .axWarning
        case .error:
            return .axError
        case .success:
            return .axSuccess
        @unknown default:
            return .axTextMuted
        }
    }
}
