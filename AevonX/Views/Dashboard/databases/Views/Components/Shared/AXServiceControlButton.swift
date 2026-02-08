//
//  AXServiceControlButton.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

public struct AXServiceControlButton: View {
    public let title: String?
    public let icon: String
    public let color: Color
    public let isEnabled: Bool
    public let action: () -> Void
    
    public init(title: String? = nil, icon: String, color: Color, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                if let title = title {
                    Text(title)
                        .font(AXTypography.subheadline)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(isEnabled ? color : .axTextMuted)
            .padding(.horizontal, title != nil ? AXSpacing.md : 0)
            .padding(.vertical, title != nil ? AXSpacing.sm : 0)
            .frame(minWidth: title == nil ? 32 : 0, minHeight: title == nil ? 32 : 0)
            .background(isEnabled ? color.opacity(0.1) : Color.axSurface)
            .cornerRadius(AXCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .stroke(isEnabled ? color.opacity(0.3) : Color.axBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
