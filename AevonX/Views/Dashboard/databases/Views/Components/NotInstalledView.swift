//
//  NotInstalledView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct NotInstalledView: View {
    let type: DatabaseType
    @ObservedObject var viewModel: DatabaseManagementViewModel
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Spacer()
            
            Image(systemName: type.iconName)
                .font(.system(size: 64))
                .foregroundColor(type.brandColor.opacity(0.5))
            
            VStack(spacing: AXSpacing.md) {
                Text("\(type.displayName) Not Installed")
                    .font(AXTypography.title)
                    .foregroundColor(.axTextPrimary)
                
                Text("This database engine is not installed on your server. Use our AI-assisted installation to set it up with optimal configuration for your system.")
                    .font(AXTypography.body)
                    .foregroundColor(.axTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            Button(action: {
                viewModel.openInstallation(for: type)
            }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 16))
                    Text("Install Now")
                        .font(AXTypography.headline)
                }
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.xl)
                .padding(.vertical, AXSpacing.md)
                .background(type.brandColor)
                .cornerRadius(AXCornerRadius.lg)
                .shadow(color: type.brandColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(AXSpacing.xl)
    }
}
