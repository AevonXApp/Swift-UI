//
//  AXConfirmationDialog.swift
//  AevonX
//
//  Created on 2026-02-16.
//  Reusable confirmation dialog following AX design system
//

import SwiftUI

struct AXConfirmationDialog: View {
    let title: String
    let message: String
    let icon: String
    let iconColor: Color
    let actionTitle: String
    let actionColor: Color
    let note: String?
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { onCancel() }
            
            // Dialog Card
            VStack(spacing: 0) {
                // Header
                HStack(spacing: AXSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                            .fill(iconColor.opacity(0.15))
                        
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(iconColor)
                    }
                    .frame(width: 36, height: 36)
                    
                    Text(title)
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, AXSpacing.xl)
                .padding(.top, AXSpacing.xl)
                .padding(.bottom, AXSpacing.md)
                
                // Content
                VStack(alignment: .leading, spacing: AXSpacing.md) {
                    Text(message)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let note = note {
                        HStack(alignment: .top, spacing: AXSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.axWarning)
                                .padding(.top, 2)
                            
                            Text(note)
                                .font(AXTypography.caption)
                                .foregroundColor(.axWarning)
                                .italic()
                        }
                        .padding(AXSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.axWarning.opacity(0.05))
                        .cornerRadius(AXCornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .stroke(Color.axWarning.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, AXSpacing.xl)
                .padding(.bottom, AXSpacing.xl)
                
                Divider()
                    .background(Color.axBorder)
                
                // Actions
                HStack(spacing: AXSpacing.md) {
                    Button(action: onCancel) {
                        Text(L10n.Button.cancel)
                            .font(AXTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.axTextSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onConfirm) {
                        Text(actionTitle)
                            .font(AXTypography.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(actionColor)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
                .padding(AXSpacing.xl)
                .background(Color.axBackgroundTertiary.opacity(0.5))
            }
            .frame(width: 360)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
