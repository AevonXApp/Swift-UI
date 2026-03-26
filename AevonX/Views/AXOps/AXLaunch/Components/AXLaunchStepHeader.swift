//
//  AXLaunchStepHeader.swift
//  AevonX
//
//  Step header showing "Step N of M — Title".
//

import SwiftUI
import AevonXCoreBridge

struct AXLaunchStepHeader: View {
    let stepIndex: Int
    let totalSteps: Int
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            Text(L10n.AXLaunch.stepOf(stepIndex, totalSteps))
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)

            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.axTextPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, AXSpacing.md)
    }
}
