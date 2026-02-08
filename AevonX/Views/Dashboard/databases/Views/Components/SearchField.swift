//
//  SearchField.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isFocused ? accentColor : .axTextMuted)
            
            TextField(placeholder, text: $text)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(isFocused ? accentColor.opacity(0.5) : Color.axBorder, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
