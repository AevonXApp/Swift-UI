//
//  AXSearchBar.swift
//  AevonX
//
//  Global search input field with focus highlight and clear button.
//  Replaces databases/SearchField.swift and 5+ inline search bars.
//

import SwiftUI

// MARK: - AXSearchBar

struct AXSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search…"
    var accentColor: Color = .axAccentBlue
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(isFocused ? accentColor : .axTextMuted)
            
            TextField(placeholder, text: $text)
                .font(AXTypography.body)
                .foregroundColor(.axTextPrimary)
                .textFieldStyle(.plain)
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
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(Color.axBackgroundTertiary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(isFocused ? accentColor.opacity(0.5) : Color.axBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Preview

#Preview("AXSearchBar") {
    VStack(spacing: AXSpacing.lg) {
        AXSearchBar(text: .constant(""), placeholder: "Search containers…")
        AXSearchBar(text: .constant("192.168"), placeholder: "Search by IP…", accentColor: .axError)
    }
    .padding()
    .frame(width: 400)
    .background(Color.axBackground)
}
