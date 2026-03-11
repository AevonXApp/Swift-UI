//
//  AXConnectionStatusBadge.swift
//  AevonX
//
//  Generic connection status indicator with glow effect.
//  Replaces AXConnectionStatus from Databases/Shared.
//  Reusable across Database, Docker, Websites, Terminal tabs.
//

import SwiftUI

// MARK: - AXConnectionStatusBadge

struct AXConnectionStatusBadge: View {
    let isConnected: Bool
    var connectedLabel: String = "Connected"
    var disconnectedLabel: String = "Disconnected"
    
    var body: some View {
        let statusColor: Color = isConnected ? .axSuccess : .axTextMuted
        let statusLabel = isConnected ? connectedLabel : disconnectedLabel
        
        HStack(spacing: AXSpacing.sm) {
            ZStack {
                if isConnected {
                    Circle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .blur(radius: 4)
                }
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            
            Text(statusLabel)
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(statusColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("AXConnectionStatusBadge") {
    VStack(spacing: AXSpacing.lg) {
        AXConnectionStatusBadge(isConnected: true)
        AXConnectionStatusBadge(isConnected: false)
        AXConnectionStatusBadge(isConnected: true, connectedLabel: "Live", disconnectedLabel: "Offline")
    }
    .padding()
    .background(Color.axBackground)
}
