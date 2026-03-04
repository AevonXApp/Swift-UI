//
//  AXSidebarContainer.swift
//  AevonX
//
//  Generic sidebar layout container with header, scrollable items, and footer.
//  Handles the full sidebar chrome (background, dividers, width).
//

import SwiftUI

struct AXSidebarContainer<Header: View, Items: View, Footer: View>: View {
    let width: CGFloat
    @ViewBuilder let header: () -> Header
    @ViewBuilder let items: () -> Items
    @ViewBuilder let footer: () -> Footer

    init(
        width: CGFloat = 240,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder items: @escaping () -> Items,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.width = width
        self.header = header
        self.items = items
        self.footer = footer
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header()

            Rectangle()
                .fill(Color.axBorder.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, AXSpacing.sm)

            // Scrollable Items
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 3) {
                    items()
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.md)
            }

            Spacer()

            // Footer
            footer()
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(
            Color.axSurface.opacity(0.6)
                .overlay(
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.axBorder.opacity(0.2))
                            .frame(width: 1)
                    }
                )
        )
    }
}

// MARK: - Convenience: No Footer

extension AXSidebarContainer where Footer == EmptyView {
    init(
        width: CGFloat = 240,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder items: @escaping () -> Items
    ) {
        self.width = width
        self.header = header
        self.items = items
        self.footer = { EmptyView() }
    }
}

// MARK: - Convenience: No Header, No Footer

extension AXSidebarContainer where Header == EmptyView, Footer == EmptyView {
    init(
        width: CGFloat = 240,
        @ViewBuilder items: @escaping () -> Items
    ) {
        self.width = width
        self.header = { EmptyView() }
        self.items = items
        self.footer = { EmptyView() }
    }
}

#Preview {
    AXSidebarContainer(
        width: 220,
        header: {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.axAccentBlue)
                Text("TOOLS")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.axTextMuted)
                    .tracking(1.5)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)
        },
        items: {
            AXSidebarRow(icon: "clock.badge.checkmark", title: "Scheduler", color: .indigo, isSelected: true, action: {})
            AXSidebarRow(icon: "key.fill", title: "Secrets", color: .yellow, isSelected: false, action: {})
            AXSidebarRow(icon: "network", title: "Traffic", color: .mint, isSelected: false, action: {})
        },
        footer: {
            Rectangle()
                .fill(Color.axBorder.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, 10)
            Text("Docker Tools v1.0")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.axTextMuted.opacity(0.5))
                .padding(.vertical, 10)
        }
    )
    .frame(height: 500)
    .background(Color.axBackground)
}
