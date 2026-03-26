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
                Text(L10n.Fleet.noResults)
                    .font(AXTypography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)

                if let filter = selectedFilter {
                    Text(L10n.Fleet.noFilterResults(filter.rawValue.lowercased()))
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                        .multilineTextAlignment(.center)
                } else if !searchText.isEmpty {
                    Text(L10n.Fleet.noSearchResults(searchText))
                        .font(AXTypography.body)
                        .foregroundColor(.axTextSecondary)
                }

                Text(L10n.Fleet.adjustFilters)
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextTertiary)
            }

            HStack(spacing: AXSpacing.md) {
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        HStack(spacing: AXSpacing.xs) {
                            Image(systemName: "xmark.circle")
                            Text(L10n.Fleet.clearSearch)
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
                            Text(L10n.Fleet.clearFilter)
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
