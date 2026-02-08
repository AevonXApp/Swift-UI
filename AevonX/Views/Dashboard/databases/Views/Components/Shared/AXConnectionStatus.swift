//
//  AXConnectionStatus.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

public struct AXConnectionStatus: View {
    public let isConnected: Bool
    
    public init(isConnected: Bool) {
        self.isConnected = isConnected
    }
    
    public var body: some View {
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                // Outer glow - static, no animation
                if isConnected {
                    Circle()
                        .fill(Color.axSuccess.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .blur(radius: 4)
                }
                
                Circle()
                    .fill(isConnected ? Color.axSuccess : Color.axTextMuted)
                    .frame(width: 8, height: 8)
            }
            
            Text(isConnected ? "Connected" : "Disconnected")
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(isConnected ? .axSuccess : .axTextMuted)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill((isConnected ? Color.axSuccess : Color.axTextMuted).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke((isConnected ? Color.axSuccess : Color.axTextMuted).opacity(0.3), lineWidth: 1)
        )
    }
}
