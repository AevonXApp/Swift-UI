//
//  AXDatabaseTabButton.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

public struct AXDatabaseTabButton: View {
    public let title: String
    public let icon: String
    public let isSelected: Bool
    public let action: () -> Void
    
    public init(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: AXSpacing.xs) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                    Text(title)
                        .font(AXTypography.subheadline)
                        .fontWeight(isSelected ? .semibold : .medium)
                }
                .foregroundColor(isSelected ? .axPrimary : .axTextSecondary)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(isSelected ? Color.axPrimary.opacity(0.1) : Color.clear)
                .cornerRadius(AXCornerRadius.md)
                
                // Active indicator line
                Rectangle()
                    .fill(isSelected ? Color.axPrimary : Color.clear)
                    .frame(height: 2)
                    .padding(.horizontal, AXSpacing.md)
                    .opacity(isSelected ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
    }
}
