//
//  RemoteFleetNoResultsView.swift
//  AevonX
//

import SwiftUI
import AevonXCoreBridge

struct RemoteFleetNoResultsView: View {
    @Binding var searchText: String
    @Binding var selectedFilter: ServerStatusFilter?
    
    var body: some View {
        VStack(spacing: AXSpacing.xl) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.axTextMuted)

            VStack(spacing: AXSpacing.sm) {
                Text("No Servers Found")
                    .font(AXTypography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)

                if let filter = selectedFilter {
                    Text("No \(filter.rawValue.lowercased()) servers match your criteria")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                        .multilineTextAlignment(.center)
                } else if !searchText.isEmpty {
                    Text("No servers match '\(searchText)'")
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                }

                Text("Try adjusting your filters or search criteria")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }

            HStack(spacing: AXSpacing.md) {
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "xmark.circle")
                            Text("Clear Search")
                        }
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                if selectedFilter != nil {
                    Button(action: { selectedFilter = nil }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Clear Filter")
                        }
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axTextPrimary)
                        .padding(.horizontal, AXSpacing.md)
                        .padding(.vertical, AXSpacing.sm)
                        .background(Color.axSurface)
                        .cornerRadius(AXCornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }
}
