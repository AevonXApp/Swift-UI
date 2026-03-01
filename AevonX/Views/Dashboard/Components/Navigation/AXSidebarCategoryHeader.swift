//
//  AXSidebarCategoryHeader.swift
//  AevonX
//
//  Section category header for grouped sidebar navigation.
//  Replaces: SidebarCategoryHeader in WebsitePanelComponents.
//

import SwiftUI

struct AXSidebarCategoryHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.axTextMuted)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.axTextMuted)
                .tracking(0.8)
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.top, AXSpacing.lg)
        .padding(.bottom, AXSpacing.xxs)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        AXSidebarCategoryHeader(title: "Tools", icon: "wrench.and.screwdriver.fill")
        AXSidebarCategoryHeader(title: "Firewall", icon: "flame.fill")
        AXSidebarCategoryHeader(title: "Access Control", icon: "key.fill")
    }
    .padding()
    .frame(width: 240)
    .background(Color.axSurface.opacity(0.6))
}
