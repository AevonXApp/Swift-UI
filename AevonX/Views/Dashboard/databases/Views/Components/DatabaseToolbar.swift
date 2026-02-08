//
//  DatabaseToolbar.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DatabaseToolbar: View {
    @ObservedObject var viewModel: DatabaseManagementViewModel
    
    var body: some View {
        HStack(spacing: AXSpacing.md) {
            SearchField(text: $viewModel.searchText, placeholder: "Search...", accentColor: .axAccentBlue)
                .frame(width: 220)

            // View Mode Toggle
            HStack(spacing: 0) {
                ForEach(DatabaseManagementViewModel.DatabaseViewMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.databaseViewMode = mode
                        }
                    } label: {
                        Image(systemName: mode == .grid ? "square.grid.2x2.fill" : "list.bullet")
                            .font(.system(size: 12))
                            .foregroundColor(viewModel.databaseViewMode == mode ? .axTextPrimary : .axTextMuted)
                            .frame(width: 32, height: 32)
                            .background(viewModel.databaseViewMode == mode ? Color.axSurfaceHover : Color.clear)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.axSurface.opacity(0.5))
            .cornerRadius(AXCornerRadius.md)
            .padding(.leading, AXSpacing.sm)

            Spacer()

            // Show "New Database" only if at least one engine is installed
            if viewModel.installedDatabaseTypesCount > 0 {
                AXPrimaryButton(title: "New Database", icon: "plus", action: { viewModel.showAddDatabase = true })
                    .frame(width: 160)
            }

            Button(action: { Task { await viewModel.loadData() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(.axTextSecondary)
                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                    .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                    .frame(width: 36, height: 36)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.bottom, AXSpacing.lg)
    }
}
