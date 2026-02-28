//
//  AXFilterBar.swift
//  AevonX
//
//  Horizontal scrollable filter chips with optional counts.
//  Replaces inline filter implementations in BruteForce, Firewall, SSH.
//

import SwiftUI

// MARK: - Filter Item

struct AXFilterItem: Identifiable, Equatable {
    let id: String
    let label: String
    var icon: String? = nil
    var color: Color? = nil
    var count: Int? = nil
    
    static func == (lhs: AXFilterItem, rhs: AXFilterItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - AXFilterBar

struct AXFilterBar: View {
    let filters: [AXFilterItem]
    @Binding var selected: String?
    var showAllChip: Bool = true
    var allCount: Int? = nil
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AXSpacing.sm) {
                // "All" chip
                if showAllChip {
                    chip(
                        label: "All",
                        icon: nil,
                        color: .axAccentBlue,
                        count: allCount,
                        isSelected: selected == nil
                    ) {
                        selected = nil
                    }
                }
                
                ForEach(filters) { filter in
                    chip(
                        label: filter.label,
                        icon: filter.icon,
                        color: filter.color ?? .axAccentBlue,
                        count: filter.count,
                        isSelected: selected == filter.id
                    ) {
                        selected = selected == filter.id ? nil : filter.id
                    }
                }
            }
        }
    }
    
    // MARK: - Chip
    
    private func chip(
        label: String,
        icon: String?,
        color: Color,
        count: Int?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AXSpacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? .white : color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(isSelected ? color.opacity(0.5) : color.opacity(0.15))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .axTextSecondary)
            .padding(.horizontal, AXSpacing.md)
            .padding(.vertical, AXSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(isSelected ? color.opacity(0.2) : Color.axSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AXCornerRadius.md)
                            .stroke(isSelected ? color.opacity(0.4) : Color.axBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("AXFilterBar") {
    VStack(spacing: AXSpacing.lg) {
        AXFilterBar(
            filters: [
                AXFilterItem(id: "inbound", label: "Inbound", icon: "arrow.down", color: .axAccentBlue, count: 42),
                AXFilterItem(id: "outbound", label: "Outbound", icon: "arrow.up", color: .axSuccess, count: 58),
            ],
            selected: .constant(nil),
            allCount: 100
        )
        
        AXFilterBar(
            filters: [
                AXFilterItem(id: "success", label: "Success", color: .axSuccess, count: 230),
                AXFilterItem(id: "failure", label: "Failure", color: .axError, count: 14),
            ],
            selected: .constant("failure"),
            allCount: 244
        )
    }
    .padding()
    .background(Color.axBackground)
}
