//
//  RemoteFleetControls.swift
//  AevonX
//

import SwiftUI
import AevonXCore

struct RemoteFleetFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: ServerStatusFilter?
    @Binding var sortOption: ServerSortOption
    @Binding var viewMode: ServerViewMode
    @ObservedObject var viewModel: ServerListViewModel
    let filteredCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                // Search
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.axTextMuted)

                    TextField("Search by name, host, or tags...", text: $searchText)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .textFieldStyle(PlainTextFieldStyle())

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.axTextMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(searchText.isEmpty ? Color.axBorder : Color.axAccentBlue.opacity(0.5), lineWidth: searchText.isEmpty ? 1 : 1.5)
                )
                .cornerRadius(AXCornerRadius.md)
                .frame(minWidth: 280)

                Spacer()

                // Sort Menu
                Menu {
                    ForEach([ServerSortOption.nameAsc, .nameDesc, .dateAdded, .status], id: \.self) { option in
                        Button(action: { sortOption = option }) {
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.label)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.axAccentBlue)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: sortOption.icon)
                            .font(.system(size: 12))
                        Text(sortOption.label)
                            .font(AXTypography.caption)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.md)
                    .padding(.vertical, AXSpacing.sm)
                    .background(Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(Color.axBorder, lineWidth: 1)
                    )
                    .cornerRadius(AXCornerRadius.md)
                }

                // View Mode Toggle
                HStack(spacing: 2) {
                    Button(action: { viewMode = .grid }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 13))
                            .foregroundColor(viewMode == .grid ? .white : .axTextSecondary)
                            .frame(width: 34, height: 34)
                            .background(viewMode == .grid ? Color.axAccentBlue : Color.clear)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { viewMode = .list }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 13))
                            .foregroundColor(viewMode == .list ? .white : .axTextSecondary)
                            .frame(width: 34, height: 34)
                            .background(viewMode == .list ? Color.axAccentBlue : Color.clear)
                            .cornerRadius(AXCornerRadius.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(2)
                .background(Color.axSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .cornerRadius(AXCornerRadius.md)

                // Refresh Button
                Button(action: {
                    Task {
                        await viewModel.refresh()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(viewModel.isLoading ? .axAccentBlue : .axTextSecondary)
                        .frame(width: 38, height: 38)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading)
            }

            // Status Filter Pills
            HStack(spacing: AXSpacing.sm) {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.axTextMuted)
                    // Removed "Environment:" label as requested implicitly by saying "filters should be on the left"
                }

                FilterPill(title: "All", isSelected: selectedFilter == nil, action: { withAnimation { selectedFilter = nil } })
                FilterPill(title: "Online", isSelected: selectedFilter == .online, action: { withAnimation { selectedFilter = .online } })
                FilterPill(title: "Offline", isSelected: selectedFilter == .offline, action: { withAnimation { selectedFilter = .offline } })

                if selectedFilter != nil || !searchText.isEmpty {
                    Divider().frame(height: 16).background(Color.axBorder)
                    HStack(spacing: AXSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 10)).foregroundColor(.axAccentBlue)
                        Text("\(filteredCount) of \(viewModel.decryptedServers.count)")
                            .font(AXTypography.caption).fontWeight(.medium).foregroundColor(.axTextPrimary)
                    }
                    .padding(.horizontal, AXSpacing.sm).padding(.vertical, AXSpacing.xxs)
                    .background(Color.axAccentBlue.opacity(0.1)).cornerRadius(AXCornerRadius.full)
                }
            }
        }
    }
}
