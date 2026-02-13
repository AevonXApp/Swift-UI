//
//  RemoteFleetComponents.swift
//  AevonX
//

import SwiftUI
import AevonXCore

// MARK: - Loading View
struct LoadingServersView: View {
    var body: some View {
        VStack(spacing: AXSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading servers...")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }
}

// MARK: - Empty State View
struct RemoteFleetEmptyStateView: View {
    @Binding var showAddServer: Bool
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)
            
            Text("No Servers Yet")
                .font(AXTypography.title2)
                .foregroundColor(.axTextPrimary)
            
            Text("Add your first server to get started")
                .font(AXTypography.body)
                .foregroundColor(.axTextSecondary)
            
            Button(action: {
                showAddServer = true
            }) {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Server")
                }
                .font(AXTypography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.axBackground)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.md)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }
}

// MARK: - Helper Components

/// Detail chip for displaying server metadata
struct DetailChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: AXSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color.opacity(0.7))
            Text(text)
                .font(AXTypography.caption2)
                .foregroundColor(color)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
        .background(color.opacity(0.08))
        .cornerRadius(AXCornerRadius.sm)
    }
}

/// Tag chip for displaying server tags
struct TagChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AXTypography.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, AXSpacing.xxs)
                .background(
                    RoundedRectangle(cornerRadius: AXCornerRadius.full)
                        .fill(color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.full)
                                .stroke(color.opacity(0.25), lineWidth: 0.5)
                        )
                )
        }
    }


// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AXTypography.caption)
                .fontWeight(.medium)
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.xxs + 2)
                .background(isSelected ? Color.axAccentBlue : Color.axSurface)
                .foregroundColor(isSelected ? .white : .axTextSecondary)
                .cornerRadius(AXCornerRadius.full)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.full)
                        .stroke(isSelected ? Color.axAccentBlue : Color.axBorder, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
