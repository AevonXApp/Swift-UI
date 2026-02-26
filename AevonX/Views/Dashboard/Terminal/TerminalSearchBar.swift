//
//  TerminalSearchBar.swift
//  AevonX
//
//  Search bar for finding text in terminal output
//

import SwiftUI

// MARK: - Terminal Search Bar

struct TerminalSearchBar: View {
    @ObservedObject var viewModel: TerminalViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(.axTextMuted)
            
            TextField("Search in terminal...", text: $viewModel.searchQuery)
                .font(.system(size: 12))
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    // Use Cmd+G for next result
                }
            
            if viewModel.searchResultCount > 0 {
                Text("\(viewModel.currentSearchIndex + 1)/\(viewModel.searchResultCount)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.axBackgroundTertiary)
                    .cornerRadius(AXCornerRadius.xs)
            }
            
            Button(action: { viewModel.toggleSearch() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.axTextMuted)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axSurface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.axBorder),
            alignment: .bottom
        )
    }
}
