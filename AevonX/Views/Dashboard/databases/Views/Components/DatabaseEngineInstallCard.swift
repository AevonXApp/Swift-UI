//
//  DatabaseEngineInstallCard.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DatabaseEngineInstallCard: View {
    let type: DatabaseType
    @ObservedObject var viewModel: DatabaseManagementViewModel
    let onManage: (DatabaseType) -> Void
    
    var body: some View {
        let isInstalled = viewModel.isEngineInstalled(type)
        
        return AXGlassCard(padding: AXSpacing.lg, accentColor: type.brandColor) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(type.brandColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: type.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(type.brandColor)
                    }
                    
                    Spacer()
                    
                    if isInstalled {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.axSuccess)
                            .font(.system(size: 14))
                    }
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(type.displayName)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    Text(type.category.displayName)
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                }
                
                Spacer()
                
                if isInstalled {
                    Button {
                        onManage(type)
                    } label: {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12))
                            Text("Manage")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        viewModel.openInstallation(for: type)
                    } label: {
                        HStack(spacing: AXSpacing.sm) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 12))
                            Text("Install")
                                .font(AXTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.axBackground)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(type.brandColor)
                        .cornerRadius(AXCornerRadius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 140, height: 160)
        }
    }
}
