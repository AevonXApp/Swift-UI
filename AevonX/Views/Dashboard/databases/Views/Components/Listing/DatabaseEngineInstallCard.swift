//
//  DatabaseEngineInstallCard.swift
//  AevonX
//
//  Card showing an installed database engine with manage button.
//  Only used for installed engines (uninstalled are hidden).
//

import SwiftUI
import AevonXCoreBridge

struct DatabaseEngineInstallCard: View {
    let type: DatabaseType
    @ObservedObject var viewModel: DatabaseManagementViewModel
    let onManage: (DatabaseType) -> Void
    
    var body: some View {
        let state = viewModel.installationState(for: type)
        
        return AXGlassCard(padding: AXSpacing.lg, accentColor: type.brandColor) {
            VStack(alignment: .leading, spacing: AXSpacing.md) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .fill(type.brandColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: type.iconName)
                            .font(AXTypography.title2)
                            .foregroundColor(type.brandColor)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    Circle()
                        .fill(state?.isRunning == true ? Color.axSuccess : Color.axTextMuted)
                        .frame(width: 8, height: 8)
                        .shadow(color: state?.isRunning == true ? .axSuccess.opacity(0.5) : .clear, radius: 3)
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.xxs) {
                    Text(type.displayName)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    if let version = state?.installedVersion {
                        Text("v\(version)")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    } else {
                        Text(type.category.displayName)
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                    }
                }
                
                Spacer()
                
                Button {
                    onManage(type)
                } label: {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "slider.horizontal.3")
                            .font(AXTypography.subheadline)
                        Text(L10n.Database.manage)
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
            }
            .frame(width: 140, height: 160)
        }
    }
}
