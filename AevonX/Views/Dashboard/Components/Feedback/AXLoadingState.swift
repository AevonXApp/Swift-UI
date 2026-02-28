//
//  AXLoadingState.swift
//  AevonX
//
//  Centered loading indicator with customizable message.
//  Two styles: .full (for content areas) and .inline (compact, for inside cards).
//  Replaces identically duplicated loading views in 15+ files.
//

import SwiftUI

// MARK: - AXLoadingState

struct AXLoadingState: View {
    let message: String
    var style: Style = .full
    
    enum Style {
        case full    // centered with generous padding
        case inline  // compact, for inside cards
    }
    
    var body: some View {
        VStack(spacing: AXSpacing.md) {
            ProgressView()
                .scaleEffect(style == .inline ? 0.8 : 1.0)
            
            Text(message)
                .font(style == .inline ? AXTypography.caption : AXTypography.body)
                .foregroundColor(.axTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, style == .inline ? AXSpacing.xl : AXSpacing.xxxl)
    }
}

// MARK: - Preview

#Preview("AXLoadingState") {
    VStack(spacing: AXSpacing.xl) {
        AXCard {
            AXLoadingState(message: "Loading firewall rules…")
        }
        
        AXCard {
            AXLoadingState(message: "Scanning…", style: .inline)
        }
    }
    .padding()
    .background(Color.axBackground)
    .frame(width: 500)
}
