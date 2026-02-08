//
//  AIInstallHeader.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct AIInstallHeader: View {
    let databaseType: DatabaseType
    var onDismiss: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Install \(databaseType.displayName)")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                
                Text("AI-assisted installation with optimal configuration")
                    .font(AXTypography.subheadline)
                    .foregroundColor(.axTextSecondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AXSpacing.xl)
    }
}
